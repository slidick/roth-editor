#pragma once

#include <cstddef>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/callable.hpp>
#include <godot_cpp/classes/file_access.hpp>

namespace godot {
    
const int PIXEL_8_BITS = 1 << 0;
const int PIXEL_15_BITS = 1 << 1;
const int PIXEL_16_BITS = 1 << 2;
const int PIXEL_24_BITS = 1 << 3;

const int AUDIO_PRESENT = 1 << 0;
const int AUDIO_CHANNELS_STEREO = 1 << 1;
const int SAMPLE_WIDTH_16 = 1 << 2;
const int AUDIO_CODING_DPCM = 1 << 3;

class RothExt : public Node {
    GDCLASS(RothExt, Node)

private:
    static int get_length_of_audio_data(Dictionary& header);
    static Array initialize_delta_table();
    static int unsigned16_to_signed(int p_unsigned) {
	    return (p_unsigned + (1 << 15)) % (1 << 16) - (1 << 15);
    }
    static Array decode_frame(int p_frame_width, int p_frame_height, Dictionary p_frame_header, PackedByteArray p_data, Array* p_palette, PackedByteArray p_previous_frame);
    static bool stop_loading_requested;

    enum imgBasicTypes {
        PLAIN_DATA =            0x02,
        PLAIN_DATA_2 =          0x1A,
        PLAIN_DATA_3 =          0x18,
        PLAIN_DATA_4 =          0x04,
        PLAIN_DATA_5 =          0x1C,
        PLAIN_DATA_6 =          0x06,
        PLAIN_DATA_7 =          0x0A,
        PLAIN_DATA_8 =          0x0C,
        PLAIN_DATA_9 =          0x00,
        
        PLAIN_DATA_FLIPPED =    0x10,
        PLAIN_DATA_FLIPPED_2 =  0x12,
        PLAIN_DATA_FLIPPED_3 =  0x14,
        PLAIN_DATA_FLIPPED_4 =  0x30,
        
        COMPRESSED =            0x11,
        COMPRESSED_2 =          0x13,
        COMPRESSED_3 =          0x31,
        COMPRESSED_4 =          0x17,
        COMPRESSED_5 =          0x33,
        COMPRESSED_6 =          0x03
    };

protected:
    static void _bind_methods();

public:
    RothExt();
    ~RothExt();

    static Dictionary get_video_by_path(String p_gdv_video_path, Callable p_callable);
    static void stop_video_loading();
    static Dictionary get_video_by_file(Ref<FileAccess> p_file, Callable p_callable = Callable());
    static Dictionary load_das(String p_das_name, String p_das_path, Callable p_callable, Array p_palette = Array());
    
};


}

