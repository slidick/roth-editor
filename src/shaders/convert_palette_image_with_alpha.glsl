#[compute]
#version 450

layout(local_size_x = 32, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict readonly buffer InputBuffer {
  uint data[];
} input_buffer;

layout(set = 0, binding = 1, std430) restrict readonly buffer PaletteBuffer {
  uint data[];
} palette_buffer;

layout(set = 0, binding = 2, std430) restrict writeonly buffer OutputBuffer {
  uint data[];
} output_buffer;

void main() {
  uint pixel = input_buffer.data[gl_GlobalInvocationID.x];
  output_buffer.data[4*gl_GlobalInvocationID.x+0] = ((palette_buffer.data[3*pixel+0] * 259 + 33) >> 6);
  output_buffer.data[4*gl_GlobalInvocationID.x+1] = ((palette_buffer.data[3*pixel+1] * 259 + 33) >> 6);
  output_buffer.data[4*gl_GlobalInvocationID.x+2] = ((palette_buffer.data[3*pixel+2] * 259 + 33) >> 6);
  if (pixel == 0)
    output_buffer.data[4*gl_GlobalInvocationID.x+3] = 0;
  else if (pixel > 0 && pixel < 128)
    output_buffer.data[4*gl_GlobalInvocationID.x+3] = 255;
  else
    output_buffer.data[4*gl_GlobalInvocationID.x+3] = 128;
}

