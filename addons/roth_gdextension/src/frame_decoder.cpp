#include "frame_decoder.hpp"
#include <godot_cpp/variant/variant.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

using namespace godot;


FrameDecoder::FrameDecoder() {}
FrameDecoder::~FrameDecoder() {}
FrameDecoder::FrameDecoder(int p_frame_width, int p_frame_height, Dictionary p_frame_header, PackedByteArray p_data, Array* p_palette, PackedByteArray p_previous_frame) {
  // Initialize bit reader
  bytes = p_data;
  if (bytes.size() > 0) {
    pos = 0;
    queue = (static_cast<unsigned int>(bytes[pos])) + (static_cast<unsigned int>(bytes[pos+1]) << 8) + (static_cast<unsigned int>(bytes[pos+2]) << 16) + (static_cast<unsigned int>(bytes[pos+3]) << 24);
    pos += 4;
    size = 16;
  }

  // Initialize values
  frame_width = p_frame_width;
  frame_height = p_frame_height;
  frame_header = p_frame_header;
  palette = p_palette;
  encoding_type = static_cast<int>(frame_header["type_flags"]) & 0x0F;
  horizontal_scaling = static_cast<int>(frame_header["type_flags"]) & 0b00010000;
  vertical_scaling = static_cast<int>(frame_header["type_flags"]) & 0b00100000;
  intraframe = static_cast<int>(frame_header["type_flags"]) & 0b01000000;
  unknown = static_cast<int>(frame_header["type_flags"]) & 0b10000000;
  pixel_skip = static_cast<int>(frame_header["type_flags"]) >> 8;
  current_position = 4096 + pixel_skip;
  
  // Initialize prefill area of pixels
  pixels = Array();
  for ( int i=0; i<2; i++ ) {
    for ( int j=0; j<256; j++ ) {
      for ( int k=0; k<8; k++ ) {
        pixels.append(j);
      }
    }
  }
  // Initialize rest of frame
  if ( p_previous_frame.is_empty() ) {
    for ( int i=0; i<frame_width; i++ ) {
      for ( int j=0; j<frame_height; j++ ) {
        pixels.append(0);
      }
    }
  } else {
    pixels.append_array(p_previous_frame);
  }

  // Pre vertical scaling adjustment
  if ( vertical_scaling ) {
    for ( int y=0; y<frame_height/2; y++ ) {
      for ( int x=0; x<frame_width; x++ ) {
        pixels[4096 + x + y * frame_width] = pixels[4096 + x + y*2 * frame_width];
      }
    }
  }

  // Decode frame
  // 1 - New palette, clear frame
  // 3 - No Video
  // 8 - Advanced decode method
  // Others unimplemented
  if ( encoding_type == 1 ) {
      decode_method_01();

  } else if (encoding_type == 8) {
      decode_method_08();
  
  }
  
  // Post vertical scaling adjustment
  if ( vertical_scaling ) {
    Array new_pixels = Array();
    new_pixels.resize(4096 + frame_width * frame_height);
    int sidx = 4096;
    int didx = 4096;
    for ( int y=0; y<frame_height; y++ ) {
      for ( int x=0; x<frame_width; x++ ) {
        new_pixels[didx + x] = pixels[sidx + x];
      }
      if ((y & 1) == 1) {
        sidx += frame_width;
      }
      didx += frame_width;
    }
    pixels = new_pixels;
  }

}

PackedByteArray FrameDecoder::get_frame() {
  return pixels.slice(4096);
}

int FrameDecoder::get_bits(int num) {
  int val = (queue & ((1 << num) - 1));
  queue = (queue >> num);
  size -= num;
  if ( size <= 0 ) {
    size += 16;
    queue = (queue | (((static_cast<int>(bytes[pos])) + (static_cast<int>(bytes[pos+1]) << 8)) << size));
    pos += 2;
  }
  return val;
}

int FrameDecoder::get_byte() {
  int val = bytes[pos];
  pos += 1;
  return static_cast<int>(val);
}

void FrameDecoder::copy_pixels(int p_offset, int p_length) {
  PackedByteArray copied_data = pixels.slice(current_position + p_offset, current_position + p_offset + p_length);
  for ( int i=0; i<copied_data.size(); i++ ) {
    pixels[current_position] = static_cast<int>(copied_data[i]);
    current_position += 1;
  }
}

int FrameDecoder::get_pixel(int p_offset) {
  return static_cast<int>(pixels[current_position + p_offset]);
}

void FrameDecoder::decode_method_01() {
  PackedByteArray raw_palette = bytes;
  palette->clear();
  for ( int i=0; i<raw_palette.size(); i+=3) {
    palette->append(Array::make((raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ));
  }
  if ( pixel_skip == 0 ) {
    pixels.fill(0);
  } else {
    pixels.fill(255);
  }
}

void FrameDecoder::decode_method_08() {
  while (true) {
    int tag = get_bits(2);
    bool ret = false;
    switch (tag) {
      case 0:
        ret = method_08_tag_00();
        break;
      case 1:
        ret = method_08_tag_01();
        break;
      case 2:
        ret = method_08_tag_02();
        break;
      case 3:
        ret = method_08_tag_03();
        break;
    }
    if ( ret == false ) {
      break;
    }
    if ( current_position >= pixels.size() ) {
      break;
    }
  }
}

bool FrameDecoder::method_08_tag_00() {
  if ( get_bits(1) == 0 ) {
    pixels[current_position] = get_byte();
    current_position += 1;
    return true;
  }
  int length = 2;
  int count = 0;
  while ( true ) {
    count += 1;
    int step = get_bits(count);
    length += step;
    if ( step != ((1 << count) - 1)) {
      break;
    }
  }
  for ( int i=0; i<length; i++) {
    if ( current_position >= pixels.size() ) {
      return false;
    }
    pixels[current_position] = get_byte();
    current_position += 1;
  }
  return true;
}

bool FrameDecoder::method_08_tag_01() {
  if ( get_bits(1) == 0 ) {
    current_position += get_bits(4) + 2;
    return true;
  }
  int length = get_byte();
  if ( (length & 0x80) == 0 ) {
    current_position += length + 18;
    return true;
  }
  current_position += ((((length & 0x7F) << 8) | get_byte()) + 146);
  return true;
}

bool FrameDecoder::method_08_tag_02() {
  int sub_tag = get_bits(2);
  int offset;
  int length;
  if ( sub_tag == 3 ) {
    offset = get_byte();
    length = 2 + static_cast<int>((offset & 0x80) == 0x80);
    offset = offset & 0x7F;
    if ( offset == 0 ) {
      for ( int i=0; i<length; i++ ) {
        if ( current_position == 0 ) {
          pixels[current_position] = 255;
        } else {
          pixels[current_position] = get_pixel(-1);
        }
        current_position += 1;
      }
      return true;
    } else {
      offset += 1;
      copy_pixels(-offset, length);
      return true;
    }
  }
  int next_4 = get_bits(4);
  int next_byte = get_byte();
  offset = (next_4 << 8) | next_byte;
  if ( sub_tag==0 && offset==0xFFF ) {
    return false;
  }
  if ( sub_tag==0 && offset>0xF80 ) {
    length = (offset & 0x0F) + 2;
    offset = (offset >> 4) & 7;
    int px1 = get_pixel(-(offset + 1));
    int px2 = get_pixel(-offset);
    for ( int i=0; i<length; i++) {
      pixels[current_position] = px1;
      pixels[current_position+1] = px2;
      current_position += 2;
    }
    return true;
  }
  length = sub_tag + 3;
  if ( offset == 0xFFF ) {
    for ( int i=0; i<length; i++ ) {
      if ( current_position == 0 ) {
        pixels[current_position] = 255;
      } else {
        pixels[current_position] = get_pixel(-1);
      }
      current_position += 1;
    }
    return true;
  }
  offset = 4096 - offset;
  copy_pixels(-offset, length);
  return true;
}

bool FrameDecoder::method_08_tag_03() {
  int first_byte = get_byte();
  int length;
  int offset;
  if ( (first_byte & 0xC0) == 0xC0 ) {
    int top_4 = get_bits(4);
    int next_byte = get_byte();
    length = (first_byte & 0x3F) + 8;
    offset = (top_4 << 8) | next_byte;
    copy_pixels(offset+1, length);
    return true;
  }
  if ( (first_byte & 0x80) == 0 ) {
    int bits_6_to_4 = first_byte >> 4;
    int bits_3_to_0 = first_byte & 0x0F;
    int next_byte = get_byte();
    length = bits_6_to_4 + 6;
    offset = (bits_3_to_0 << 8) | next_byte;
  } else {
    int top_4 = get_bits(4);
    int next_byte = get_byte();
    length = 14 + (first_byte & 0x3F);
    offset = (top_4 << 8) | next_byte;
  }
  if ( offset == 0xFFF ) {
    for ( int i=0; i<length; i++) {
      if ( current_position == 0 ) {
        pixels[current_position] = 255;
      } else {
        if (current_position >= pixels.size()) {
          return false;
        }
        pixels[current_position] = get_pixel(-1);
      }
      current_position += 1;
    }
    return true;
  }
  offset = 4096 - offset;
  copy_pixels(-offset, length);
  return true;
}



