extends Object
class_name AudioFunctions


static func convert_to_mono(stereo_audio: PackedByteArray) -> PackedByteArray:
	var mono_audio := PackedByteArray()
	assert(len(stereo_audio) % 4 == 0)
	mono_audio.resize(roundi(len(stereo_audio)/2.0))
	for i in range(0, len(stereo_audio), 4):
		var left: int = stereo_audio.decode_s16(i)
		var right: int = stereo_audio.decode_s16(i+2)
		var average: int = roundi((left + right) / 2.0)
		mono_audio.encode_u16(roundi(i/2.0), average)
	return mono_audio


static func downsample_audio(input_data: PackedByteArray, src_rate: int, dst_rate: int) -> PackedByteArray:
	# Decode PackedByteArray
	var original_samples: Array = []
	for i in range(0, len(input_data), 2):
		original_samples.append(input_data.decode_s16(i))
	
	# Simple downsampler
	var downsampled_data: Array = []
	var ratio: float = float(src_rate) / dst_rate
	var i: float = 0
	while i < len(original_samples):
		var index_1: int = int(i)
		var index_2: int = min(index_1 + 1, len(original_samples) - 1)
		var t: float = (i - index_1) / ratio
		var sample_1: int = original_samples[index_1]
		var sample_2: int = original_samples[index_2]
		var downsampled_value: int = int(sample_1 + (sample_2 - sample_1) * t)
		downsampled_data.append(downsampled_value)
		i += ratio
	
	# Encode output as PackedByteArray
	var output_data := PackedByteArray()
	output_data.resize(len(downsampled_data)*2)
	for j in range(len(downsampled_data)):
		output_data.encode_s16(j*2, downsampled_data[j])
	return output_data


static func convert_to_dpcm(input_data: PackedByteArray) -> PackedByteArray:
	if len(input_data) == 0:
		return input_data
	
	# Decode PackedByteArray
	var original_samples: Array = []
	for i in range(0, len(input_data), 2):
		original_samples.append(input_data.decode_s16(i))
	
	
	var delta_table: Array = Utility.init_delta_table()
	var dpcm_data: Array = []
	var last_sample: int = original_samples[0]
	dpcm_data.append(0)
	
	for i in range(1, len(original_samples), 1):
		var current_sample: int = original_samples[i]
		var min_diff: int = 1000000
		var best_index: int = 0
		
		for j in range(256):
			var new_sample: int = last_sample + delta_table[j]
			var diff: int = abs(current_sample - new_sample)
			if diff < min_diff:
				min_diff = diff
				best_index = j
		
		dpcm_data.append(best_index)
		last_sample = last_sample + delta_table[best_index]
	
	return dpcm_data


static func convert_to_pcm(input_data: PackedByteArray) -> PackedByteArray:
	if len(input_data) == 0:
		return input_data
	var delta_table: Array = Utility.init_delta_table()
	var dpcm_state: float = 0.0
	var data: Array = []
	data.resize(len(input_data))
	var i: int = 0
	for byte: int in input_data:
		dpcm_state += delta_table[byte]
		if dpcm_state > 32767:
			dpcm_state -= 65536
		if dpcm_state < -32768:
			dpcm_state += 65536
		data[i] = dpcm_state
		i += 1
	
	var pcm_data := PackedByteArray()
	pcm_data.resize(len(data)*2)
	i = 0
	for sample: int in data:
		pcm_data.encode_s16(i, sample)
		i += 2
	
	return pcm_data
