#pragma once

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

namespace godot {

class FrameDecoder {
private:
    Array bytes;
    int pos;
    int size;
    unsigned int queue;

    int frame_width;
    int frame_height;
    Dictionary frame_header;
    PackedByteArray pixels;
    Array* palette;
    int encoding_type;
    bool horizontal_scaling;
    bool vertical_scaling;
    bool intraframe;
    bool unknown;
    int pixel_skip;
    int current_position;

    void decode_method_00();
    void decode_method_01();
    void decode_method_02();
    void decode_method_03();
    void decode_method_04();
    void decode_method_05();
    void decode_method_06();
    void decode_method_07();
    void decode_method_08();
    
    bool method_08_tag_00();
    bool method_08_tag_01();
    bool method_08_tag_02();
    bool method_08_tag_03();

    int get_bits(int p_num);
    int get_byte();
    void copy_pixels(int p_offset, int p_length);
    int get_pixel(int p_offset);

protected:
    static void _bind_methods();

public:
    FrameDecoder();
    FrameDecoder(int p_frame_width, int p_frame_height, Dictionary p_frame_header, PackedByteArray p_data, Array* p_palette, PackedByteArray p_previous_frame);
    ~FrameDecoder();

    PackedByteArray get_frame();

};

}
