#include "roth_ext.hpp"
#include "frame_decoder.hpp"
#include "godot_cpp/variant/callable.hpp"
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/image.hpp>

using namespace godot;

void RothExt::_bind_methods() {
  ClassDB::bind_static_method("RothExt", D_METHOD("get_video_by_path", "gdv_video_path", "status_callback"), &RothExt::get_video_by_path);
  ClassDB::bind_static_method("RothExt", D_METHOD("load_das", "das_filepath", "status_callback", "palette_override"), &RothExt::load_das);
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


Dictionary RothExt::load_das(String p_das_path, Callable p_callback, Array p_palette) {
  	// File
	Ref<FileAccess> file = FileAccess::open(p_das_path, FileAccess::READ);
  
  	// Name
	Dictionary das = Dictionary();
	das["name"] = p_das_path.get_file().get_basename();
  
  	// Header
	das["header"] = Dictionary();
	das["header"].set("DAS_id_str", String::chr(file->get_8()) + String::chr(file->get_8()) + String::chr(file->get_8()) + String::chr(file->get_8()));  
	das["header"].set("DAS_id_num", file->get_16());
	das["header"].set("size_FAT", file->get_16());
	das["header"].set("imgFATOffset", file->get_32());
	das["header"].set("paletteOffset", file->get_32());
	das["header"].set("unk_0x10", file->get_32());
	das["header"].set("fileNamesBlockOffset", file->get_32());
	das["header"].set("fileNamesBlockSize", file->get_16());
	das["header"].set("unk_0x1C_size", file->get_16());
	das["header"].set("unk_0x1C", file->get_32());
	das["header"].set("unk_0X20", file->get_32());
	das["header"].set("unk_0x24", file->get_32());
	das["header"].set("unk_0x28", file->get_32());
	das["header"].set("unk_0x28_size", file->get_32());
	das["header"].set("unk_0x30", file->get_32());
	das["header"].set("imgFAT_numEntries", file->get_16());
	das["header"].set("imgFAT_numEntries2", file->get_16());
	das["header"].set("unk_0x38", file->get_32());
	das["header"].set("unk_0x38_size", file->get_16());
	das["header"].set("unk_0x40_size", file->get_16());
	das["header"].set("unk_0x40", file->get_32());

	// Palette
	if (p_palette.is_empty()) {
		file->seek(das["header"].get("paletteOffset"));
		das["palette"] = Array();
		PackedByteArray raw_palette = file->get_buffer(256*3);
		for ( int i=0; i<raw_palette.size(); i+=3 ) {
			// Convert 6bit to 8bit
			static_cast<Array>(das["palette"]).append(Array::make((raw_palette[i] * 259 + 33) >> 6, (raw_palette[i+1] * 259 + 33) >> 6, (raw_palette[i+2] * 259 + 33) >> 6 ));
		}
	} else {
		das["palette"] = p_palette;
	}

	// Other Initializations
	das["textures"] = Array();
	das["mapping"] = Dictionary();
	das["das_strings_header"] = Dictionary();
	das["loading_errors"] = Array();
	das["sky"] = 0;

	// Texture Names
	file->seek(das["header"].get("fileNamesBlockOffset"));
	das["das_strings_header"].set("nb_unk_00", file->get_16());
	das["das_strings_header"].set("nb_unk_01", file->get_16());
	while ( file->get_position() < file->get_length() ) {
		Dictionary entry = Dictionary();
		entry.set("sizeof", file->get_16());
		entry.set("index", file->get_16());
		entry.set("name", file->get_line());
		entry.set("desc", file->get_line());
		das["textures"].call("append", entry);
	}
	
	
	
	// Textures
 	for ( int i=0; i<static_cast<int>(das["textures"].call("size")); i++) {

		file->seek(static_cast<int>(das["header"].get("imgFATOffset")) + (static_cast<int>(das["textures"].get(i).get("index")) * 0x08));
		
		// Offset header
		das["textures"].get(i).set("offset_data", file->get_32());
		das["textures"].get(i).set("length_data_div_2", file->get_16());
		das["textures"].get(i).set("unk_byte_00", file->get_8());
		das["textures"].get(i).set("unk_byte_01", file->get_8());
		if ( (static_cast<int>(das["textures"].get(i).get("unk_byte_00")) & 2) > 0 ) {
			das["textures"].get(i).set("is_sky", true);
		} else {
			das["textures"].get(i).set("is_sky", false);
		}
			

		// Texture header
		file->seek(das["textures"].get(i).get("offset_data"));
		das["textures"].get(i).set("unk", file->get_8());
		das["textures"].get(i).set("imageType", file->get_8());
		das["textures"].get(i).set("width", file->get_16());
		das["textures"].get(i).set("height", file->get_16());
    
		
		// Decode by type


   		// Plain Image
		if (static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_2 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_3 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_4 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_5 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_6 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_7 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_8 ||
			static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_9)
		{
			if (static_cast<int>(das["textures"].get(i).get("width")) == 0) {
				Array args = Array::make(das["textures"].get(i).get("index"), das["textures"].get(i).get("name"));
				das["loading_errors"].call("append", String("Image has zero width. Index: {0}, Name: {1}").format(args));
				continue;
      		}
			
			if (static_cast<int>(das["textures"].get(i).get("height")) == 0) {
				Array args = Array();
				args.append(das["textures"].get(i).get("index"));
				args.append(das["textures"].get(i).get("name"));
				das["loading_errors"].call("append", String("Image has zero height. Index: {0}, Name: {1}").format(args));
				continue;
      		}
			
			PackedByteArray raw_img = file->get_buffer(static_cast<int>(das["textures"].get(i).get("width")) * static_cast<int>(das["textures"].get(i).get("height")));
			
			if (raw_img.size() != static_cast<int>(das["textures"].get(i).get("width")) * static_cast<int>(das["textures"].get(i).get("height"))) {
				Array args = Array();
				args.append(static_cast<int>(das["textures"].get(i).get("width")) * static_cast<int>(das["textures"].get(i).get("height")));
				args.append(das["textures"].get(i).get("width"));
				args.append(das["textures"].get(i).get("height"));
				args.append(raw_img.size());
				args.append(das["textures"].get(i).get("index"));
				args.append(das["textures"].get(i).get("name"));
				args.append(das["textures"].get(i).get("unk"));
				das["loading_errors"].call("append", String("Expected image mismatch! (Read past end of file) Expected: {0} ({1}x{2}), Found: {3}, Index: {4}, Name: {5}, Unk: {6}").format(args));
				continue;
      		}

			Array data = Array();
			for ( int j=0; j<raw_img.size(); j++) {				
				data.append_array(das["palette"].get(raw_img[j]));
				if (raw_img[j] == 0) {
					data.append(0);
				} else {
					data.append(255);
				}
			}

			Ref<Image> img = Image::create_from_data(das["textures"].get(i).get("width"), das["textures"].get(i).get("height"), false, Image::FORMAT_RGBA8, data);
			
			das["textures"].get(i).set("image", img);
			das["textures"].get(i).set("flipped", false);
		
    	} else if (static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_FLIPPED ||
				static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_FLIPPED_2 ||
				static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_FLIPPED_3 ||
				static_cast<int>(das["textures"].get(i).get("imageType")) == PLAIN_DATA_FLIPPED_4 )
		{
			
			if (static_cast<int>(das["textures"].get(i).get("unk")) > 0xC0) {
				
				
				file->seek(static_cast<int>(das["textures"].get(i).get("offset_data")) + 32);
				
				int alignment = file->get_position() & 0xF;
				
				int img_reference = file->get_8();
				int _type = file->get_8();
				int width = file->get_16();
				int height = file->get_16();
				
				
				das["textures"].get(i).set("image", Array());
				while (true) {
					PackedByteArray raw_img = file->get_buffer(width * height);
					Array data = Array();
					for ( int i=0; i<raw_img.size(); i++) {				
						data.append_array(das["palette"].get(raw_img[i]));
						if (raw_img[i] == 0) {
							data.append(0);
						} else {
							data.append(255);
						}
					}
					Ref<Image> img = Image::create_from_data(width, height, false, Image::FORMAT_RGBA8, data);
					img->flip_y();
					img->rotate_90(CLOCKWISE);
					
					das["textures"].get(i).get("image").call("append", img);
					das["textures"].get(i).set("flipped", true);
					
					
					int lower_ptr_4_bits = file->get_position() & 0xF;
					int pos = file->get_position();
					if (lower_ptr_4_bits > alignment) {
						pos = pos + (alignment + 0x10 - lower_ptr_4_bits);
					} else {
						pos = pos + (alignment - lower_ptr_4_bits);
					}
					file->seek(pos);
					
					int img_reference_new = file->get_8();
					_type = file->get_8();
					width = file->get_16();
					height = file->get_16();
					if (img_reference != img_reference_new) {
						break;
					}
				}
				
				int tmp_width = das["textures"].get(i).get("width");
				int tmp_height = das["textures"].get(i).get("height");
				das["textures"].get(i).set("width", tmp_height);
				das["textures"].get(i).set("height", tmp_width);
				
				
				
			} else if (static_cast<int>(das["textures"].get(i).get("unk")) == 0x40) {
				int numImgs = 0;
				while (file->get_16() != 0) {
					numImgs += 1;
				}
				numImgs -= 1;
				
				while (file->get_8() == 0);
				file->seek(file->get_position() - 2);
				
				int alignment = file->get_position() & 0xF;
				int _img_reference = file->get_8();
				int _type = file->get_8();
				int width = file->get_16();
				int height = file->get_16();
				das["textures"].get(i).set("image", Array());
				for (int j=0; j<numImgs; j++) {
					PackedByteArray raw_img = file->get_buffer(width * height);
					Array data = Array();
					for ( int i=0; i<raw_img.size(); i++) {				
						data.append_array(das["palette"].get(raw_img[i]));
						if (raw_img[i] == 0) {
							data.append(0);
						} else {
							data.append(255);
						}
					}				

					if (width == 0) {
						Array args = Array();
						args.append(das["textures"].get(i).get("index"));
						args.append(das["textures"].get(i).get("name"));
						args.append(j);
						args.append(numImgs);
						das["loading_errors"].call("append", String("Image width is zero! Index: {0}, Name: {1}, Subimage: {2}, Of: {3}").format(args));
					} else {
						Ref<Image> img = Image::create_from_data(width, height, false, Image::FORMAT_RGBA8, data);
						img->flip_y();
						img->rotate_90(CLOCKWISE);
						
						das["textures"].get(i).get("image").call("append", img);
						das["textures"].get(i).set("flipped", true);
					}

					int lower_ptr_4_bits = file->get_position() & 0xF;
					int pos = file->get_position();
					if (lower_ptr_4_bits > alignment) {
						pos = pos + (alignment + 0x10 - lower_ptr_4_bits);
					} else {
						pos = pos + (alignment - lower_ptr_4_bits);
					}
					file->seek(pos);
					
					_img_reference = file->get_8();
					_type = file->get_8();
					width = file->get_16();
					height = file->get_16();
				}
					
				int tmp_width = das["textures"].get(i).get("width");
				int tmp_height = das["textures"].get(i).get("height");
				das["textures"].get(i).get("width") = tmp_height;
				das["textures"].get(i).get("height") = tmp_width;

			} else {

				PackedByteArray raw_img = file->get_buffer(static_cast<int>(das["textures"].get(i).get("width")) * static_cast<int>(das["textures"].get(i).get("height")));
				Array data = Array();
				for ( int i=0; i<raw_img.size(); i++) {				
					data.append_array(das["palette"].get(raw_img[i]));
					if (raw_img[i] == 0) {
						data.append(0);
					} else {
						data.append(255);
					}
				}		
				Ref<Image> img = Image::create_from_data(das["textures"].get(i).get("width"), das["textures"].get(i).get("height"), false, Image::FORMAT_RGBA8, data);
				img->flip_y();
				img->rotate_90(CLOCKWISE);
				int tmp_width = das["textures"].get(i).get("width");
				int tmp_height = das["textures"].get(i).get("height");
				das["textures"].get(i).set("width", tmp_height);
				das["textures"].get(i).set("height", tmp_width);
				
				das["textures"].get(i).set("image", img);
				das["textures"].get(i).set("flipped", true);
			}
		
		
    	} else if (static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED ||
					static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED_2 ||
					static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED_3 ||
					static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED_4 ||
					static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED_5 ||
					static_cast<int>(das["textures"].get(i).get("imageType")) == COMPRESSED_6
		) {
			int _block_size = file->get_16();
			int _unk = file->get_16();
			int firstImgOffset = file->get_16();
			int img_type_2 = file->get_16();
			if (img_type_2 != 0xFFFE) {
				file->seek(static_cast<int>(das["textures"].get(i).get("offset_data")) + firstImgOffset + 0x06);
				
				if (static_cast<int>(das["textures"].get(i).get("width")) == 0) {
					Array args = Array();
					args.append(das["textures"].get(i).get("index"));
					args.append(das["textures"].get(i).get("name"));
					das["loading_errors"].call("append", String("Image has zero width. Index: {0}, Name: {1}").format(args));
					continue;
				}
				if (static_cast<int>(das["textures"].get(i).get("height")) == 0) {
					Array args = Array();
					args.append(das["textures"].get(i).get("index"));
					args.append(das["textures"].get(i).get("name"));
					das["loading_errors"].call("append", String("Image has zero height. Index: {0}, Name: {1}").format(args));
					continue;
				}
				
				PackedByteArray raw_img = file->get_buffer(static_cast<int>(das["textures"].get(i).get("width")) * static_cast<int>(das["textures"].get(i).get("height")));
				Array data = Array();
				for ( int i=0; i<raw_img.size(); i++) {				
					data.append_array(das["palette"].get(raw_img[i]));
					if (raw_img[i] == 0) {
						data.append(0);
					} else {
						data.append(255);
					}
				}
				Ref<Image> img = Image::create_from_data(das["textures"].get(i).get("width"), das["textures"].get(i).get("height"), false, Image::FORMAT_RGBA8, data);
				
				if (static_cast<int>(das["textures"].get(i).get("imageType")) != 1) {
					img->flip_y();
					img->rotate_90(CLOCKWISE);
					das["textures"].get(i).set("flipped", true);
				}
				
				das["textures"].get(i).set("image", img);
				das["textures"].get(i).set("animation", Array());
				das["textures"].get(i).get("animation").call("append", img);
				for (int j=0; j<img_type_2; j++) {					
					bool finished = false;
					int pos = 0;
					while (true) {
						int code = file->get_8();
						if (code == 0) {
							code = file->get_8();
							if (code == 0) {
								finished = true;
								break;
							}
							int value = file->get_8();
							for (int k=0; k<code; k++) {
								raw_img[pos+k] = value;
							}
							pos += code;
						} else if (code > 0x80) {
							code &= 0x7F;
							pos += code;
						} else if (code < 0x80) {
							for (int k=0; k<code; k++) {
								raw_img[pos+k] = file->get_8();
							}
							pos += code;
						} else {
							int code_word = file->get_16();
							
							if (code_word == 0) {
								break;
							}
							
							if (code_word & 0x8000) {
								code_word &= 0x3FFF;
								int value = file->get_8();
								if (value == 0) {
									for (int k=0; k<code_word; k++) {
										raw_img[pos+k] = 0;
									}
								} else {
									break;
								}
							}
							
							pos += code_word;
						}
					}
					
					if (finished) {
						break;
					}
					
					Array data2 = Array();
					for ( int i=0; i<raw_img.size(); i++) {				
						data2.append_array(das["palette"].get(raw_img[i]));
						if (raw_img[i] == 0) {
							data2.append(0);
						} else {
							data2.append(255);
						}
					}
					Ref<Image> img2 = Image::create_from_data(das["textures"].get(i).get("width"), das["textures"].get(i).get("height"), false, Image::FORMAT_RGBA8, data2);
					img2->flip_y();
					img2->rotate_90(CLOCKWISE);
					
					das["textures"].get(i).get("animation").call("append", img2);
				}

				int tmp_width = das["textures"].get(i).get("width");
				int tmp_height = das["textures"].get(i).get("height");
				das["textures"].get(i).set("width", tmp_height);
				das["textures"].get(i).set("height", tmp_width);
				das["textures"].get(i).set("flipped", true);
			
			} else {
				
				file->seek(static_cast<int>(das["textures"].get(i).get("offset_data")) + 16);
				
				das["textures"].get(i).set("animation", Array());
				
				int starting_position = file->get_position();
				
				Dictionary sub_img_header = Dictionary();
				sub_img_header.set("subImgID", file->get_16());
				sub_img_header.set("unk", file->get_16());
				sub_img_header.set("bufWidth", file->get_16());
				sub_img_header.set("bufHeight", file->get_16());
				sub_img_header.set("numImgs", file->get_16());
				sub_img_header.set("currImgIdx", file->get_16());
				sub_img_header.set("currImgSize", file->get_32());
				sub_img_header.set("unk2", file->get_16());
				sub_img_header.set("width", file->get_16());
				sub_img_header.set("unk4", file->get_16());
				sub_img_header.set("height", file->get_16());

				
				
				
				int num_imgs = sub_img_header["numImgs"];
				while (num_imgs == static_cast<int>(sub_img_header["numImgs"])) {
					int img_size = static_cast<int>(sub_img_header["width"]) * static_cast<int>(sub_img_header["height"]);
					Array img_buffer = Array();
					img_buffer.resize(img_size);
					int pos = 0;
					
					while (pos < img_size) {
						int byte = file->get_8();
						if (byte > 0xF0) {
							int count = byte & 0x0F;
							int next_byte = file->get_8();
							for (int j=0; j<count; j++) {
								img_buffer[pos+j] = next_byte;
							}
							pos += count;
						} else {
							img_buffer[pos] = byte;
							pos += 1;
						}
					}
					
					Array data = Array();
					for ( int i=0; i<img_buffer.size(); i++) {				
						data.append_array(das["palette"].get(img_buffer[i]));
						if (static_cast<int>(img_buffer[i]) == 0) {
							data.append(0);
						} else {
							data.append(255);
						}
					}
					
					Ref<Image> image = Image::create_from_data(sub_img_header["width"], sub_img_header["height"], false, Image::FORMAT_RGBA8, data);
					image->flip_y();
					image->rotate_90(CLOCKWISE);
					
					das["textures"].get(i).get("animation").call("append", image);
					
					file->seek(starting_position + static_cast<int>(sub_img_header["currImgSize"]));
					starting_position = file->get_position();
					
					sub_img_header.set("subImgID", file->get_16());
					sub_img_header.set("unk", file->get_16());
					sub_img_header.set("bufWidth", file->get_16());
					sub_img_header.set("bufHeight", file->get_16());
					sub_img_header.set("numImgs", file->get_16());
					sub_img_header.set("currImgIdx", file->get_16());
					sub_img_header.set("currImgSize", file->get_32());
					sub_img_header.set("unk2", file->get_16());
					sub_img_header.set("width", file->get_16());
					sub_img_header.set("unk4", file->get_16());
					sub_img_header.set("height", file->get_16());
				}
				das["textures"].get(i).set("flipped", true);
				if (static_cast<int>(das["textures"].get(i).get("animation").call("size")) > 0) {
					das["textures"].get(i).set("image", das["textures"].get(i).get("animation").get(0));
				}
				int tmp_width  = das["textures"].get(i).get("width");
				int tmp_height = das["textures"].get(i).get("height");
				das["textures"].get(i).set("width", tmp_height);
				das["textures"].get(i).set("height", tmp_width);
			}
		
    } else if (static_cast<int>(das["textures"].get(i).get("imageType")) == 0x80) {
		Array args = Array();
		args.append(das["textures"].get(i).get("name"));
		args.append(das["textures"].get(i).get("desc"));
		args.append(das["textures"].get(i).get("index"));
		das["loading_errors"].call("append", String("Object not loaded: {0}, Desc: {1}, Index: {2}").format(args));
			
    } else {
		Array args = Array();
		args.append(das["textures"].get(i).get("imageType"));
		args.append(das["textures"].get(i).get("name"));
		args.append(das["textures"].get(i).get("index"));
		das["loading_errors"].call("append", String("Unknown Type: {0}, Name: {1}, Index: {2}").format(args));
    }
	int current_index = das["textures"].get(i).get("index");
	das["mapping"].set(current_index, das["textures"].get(i));
	
	p_callback.call_deferred(float(i) / static_cast<int>(das["textures"].call("size")));

  }

  return das;
}