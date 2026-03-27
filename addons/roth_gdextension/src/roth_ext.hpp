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
    static bool stop_loading_requested;

protected:
    static void _bind_methods();

public:
    RothExt();
    ~RothExt();

    static Dictionary get_video_by_path(String p_gdv_video_path, Callable p_callable);
    static void stop_video_loading();
    static Dictionary get_video_by_file(Ref<FileAccess> p_file, Callable p_callable = Callable());
};


}

