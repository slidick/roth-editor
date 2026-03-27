#include "roth_ext.hpp"
#include "frame_decoder.hpp"
#include "godot_cpp/variant/callable.hpp"
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/image_texture.hpp>

using namespace godot;


void RothExt::_bind_methods() {
  ClassDB::bind_static_method("RothExt", D_METHOD("get_video_by_path", "gdv_video_path", "status_callback"), &RothExt::get_video_by_path);
  ClassDB::bind_static_method("RothExt", D_METHOD("stop_video_loading"), &RothExt::stop_video_loading);
  ClassDB::bind_static_method("RothExt", D_METHOD("get_video_by_file", "gdv_video_fileaccess", "status_callback"), &RothExt::get_video_by_file, Callable());
}


RothExt::RothExt() {
  // Initialize
}


RothExt::~RothExt() {
  // Cleanup
}


bool RothExt::stop_loading_requested = false;


int RothExt::get_length_of_audio_data(Dictionary& header) {
  int amount = 0;
  if ( (static_cast<int>(header["sound_flags"]) & AUDIO_PRESENT) == 0 ) return 0;
	amount = static_cast<int>(header["playback_frequency"]) / static_cast<int>(header["framerate"]);
  if ( (static_cast<int>(header["sound_flags"]) & AUDIO_CHANNELS_STEREO) > 0 ) amount *= 2;
  if ( (static_cast<int>(header["sound_flags"]) & SAMPLE_WIDTH_16) > 0 ) amount *= 2;
  if ( (static_cast<int>(header["sound_flags"]) & AUDIO_CODING_DPCM) > 0 ) amount = amount >> 1;
	return amount;
}


Array RothExt::initialize_delta_table() {
  Array delta_table = Array();
  delta_table.resize(256);
  delta_table[0] = 0;
	int delta = 0;
	int code = 64;
	int step = 45;
	for ( int i=1; i<254; i+=2) {
		delta += (code >> 5);
		code += step;
		step += 2;
		delta_table[i] = delta;
		delta_table[i+1] = -delta;
  }
	delta_table[255] = delta + (code >> 5);
  return delta_table;
}


Dictionary RothExt::get_video_by_path(String p_gdv_video_path, Callable p_callback) {

  Ref<FileAccess> file = FileAccess::open(p_gdv_video_path, FileAccess::READ);

  Dictionary dict = get_video_by_file(file, p_callback);
  dict.set("name", p_gdv_video_path.get_file().get_basename());
  return dict;

}


Dictionary RothExt::get_video_by_file(Ref<FileAccess> file, Callable p_callback) {
  stop_loading_requested = false;
  Dictionary dict = Dictionary();

  // Header
  Dictionary header = Dictionary();
  header.set("signature", file->get_32());
  header.set("size_id", file->get_16());
  header.set("nb_frames", file->get_16());
  header.set("framerate", file->get_16());
  header.set("sound_flags", file->get_16());
  header.set("playback_frequency", file->get_16());
  header.set("image_type", file->get_16());
  header.set("frame_size", file->get_16());
  header.set("unk_byte_00", file->get_8());
  header.set("lossyness", file->get_8());
  header.set("frame_width", file->get_16());
  header.set("frame_height", file->get_16());
  dict.set("header", header);

  // Palette
  Array palette = Array();
  if ( (static_cast<int>(header["image_type"]) & PIXEL_8_BITS) > 0 ) {
    PackedByteArray raw_palette = file->get_buffer(256*3);
    for (int i = 0; i < raw_palette.size(); i+=3) {
      // Convert 6bit to 8bit
      palette.append(Array::make((raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ));
    }
  } else {
    dict.set("error", "Unsupported file->");
    return dict;
  }
  dict.set("palette", palette);
  
  // Audio Init
  Array delta_table = initialize_delta_table();
  Array audio = Array();
  int left_state = 0;
  int right_state = 0;
  const double power = std::pow(2,15);
  dict.set("power", power);
  dict.set("divide", 12941/power);

  // Video Init
  Array video = Array();
  PackedByteArray previous_frame = PackedByteArray();

  for ( int i=0; i < static_cast<int>(header["nb_frames"]); i++ ) {
    // Audio
      if ( (static_cast<int>(header["sound_flags"]) & AUDIO_PRESENT) > 0 ) {
        PackedByteArray raw_audio = file->get_buffer(get_length_of_audio_data(header));
        Array audio_frame = Array();
        if ( (static_cast<int>(header["sound_flags"]) & AUDIO_CODING_DPCM) > 0 ) {
          // DPCM
          for ( int j=0; j<raw_audio.size(); j+=2 ) {
            left_state += static_cast<int>(delta_table[raw_audio[j]]);
            if ( left_state > 32767 ) left_state -= 65536;
            if ( left_state < -32768 ) left_state += 65536;
            right_state += static_cast<int>(delta_table[raw_audio[j+1]]);
            if ( right_state > 32767 ) right_state -= 65536;
            if ( right_state < -32768 ) right_state += 65536;
            audio_frame.append(Vector2(left_state/power, right_state/power));
          }
        } else {
          // PCM
          for ( int j=0; j<raw_audio.size(); j+=4 ) {
            double left_frame = raw_audio[j] + (raw_audio[j+1] << 8);
            left_frame = unsigned16_to_signed(left_frame);
            double right_frame = raw_audio[j+2] + (raw_audio[j+3] << 8);
            right_frame = unsigned16_to_signed(right_frame);
            audio_frame.append(Vector2(left_frame/power, right_frame/power));
          }
        }

        audio.append_array(audio_frame);
      }

    // Video
    if ( static_cast<int>(header["frame_size"]) != 0 ) {
      // Header
      Dictionary frame_header = Dictionary();
      frame_header.set("signature", file->get_16());
      frame_header.set("length", file->get_16());
      frame_header.set("type_flags", file->get_32());

      // Data
      PackedByteArray data = file->get_buffer(static_cast<int>(frame_header["length"]));
      FrameDecoder* frame = new FrameDecoder(static_cast<int>(header["frame_width"]), static_cast<int>(header["frame_height"]), frame_header.duplicate(), data.duplicate(), &palette, previous_frame);
      previous_frame = frame->get_frame();
      delete frame;
      
      // Palettize the frame
      Array paletted_data = Array();
      for ( int j=0; j<previous_frame.size(); j++) {
        paletted_data.append_array(palette[previous_frame[j]]);
      }

      video.append(Image::create_from_data(static_cast<int>(header["frame_width"]), static_cast<int>(header["frame_height"]), false, Image::FORMAT_RGB8, paletted_data));
    }
    

    // Callback status function
    p_callback.call_deferred(i/static_cast<double>(header["nb_frames"]));

	if (stop_loading_requested == true) {
		stop_loading_requested = false;
		return Dictionary();
	}
    
  }
  

  dict.set("audio", audio);
  dict.set("video", video);

  return dict;
}


void RothExt::stop_video_loading() {
	stop_loading_requested = true;
}
