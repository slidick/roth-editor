extends BaseWindow

signal done(new_entry: Dictionary)


var original_audio_entry: Dictionary = {}
var audio_entry: Dictionary = {}
var play_position: float = 0
var end_position: float = 0
var start_index: int = 0
var end_index: int = 0


func edit_audio(p_audio_entry: Dictionary) -> Dictionary:
	var i: int = 0
	%DeviceOption.clear()
	for device: String in AudioServer.get_input_device_list():
		%DeviceOption.add_item(device)
		if AudioServer.input_device == device:
			%DeviceOption.select(i)
		i += 1
	
	%StartMarker.initialize()
	%EndMarker.initialize()
	%NameLabel.text = "%s: %s" % [p_audio_entry.name, p_audio_entry.desc]
	play_position = 0
	end_position = 0
	start_index = 0
	end_index = 0
	original_audio_entry = p_audio_entry
	audio_entry = p_audio_entry.duplicate(true)
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry), true)
	toggle(true)
	await get_tree().process_frame
	update_length()
	
	var new_entry: Dictionary = await done
	toggle(false)
	return new_entry


func update_length() -> void:
	var sample_rate: float = 22050.0
	if audio_entry.type == 1:
		sample_rate = 11025.0
	elif audio_entry.type == 3:
		pass
	elif audio_entry.type == 0:
		pass
	else:
		print(audio_entry.type)
		assert(false)
	var start_percent: float = (%StartMarker.position.x+%StartMarker.size.x/2) / %Waveform.size.x
	var end_percent: float = (%EndMarker.position.x+%EndMarker.size.x/2) / %Waveform.size.x
	start_index = int(len(audio_entry.raw_data)/2.0*start_percent)
	end_index = int(len(audio_entry.raw_data)/2.0*end_percent)
	%LengthLabel.text = "Length: %.2fs" % ((end_index - start_index)/ sample_rate)


func _on_stop_button_pressed() -> void:
	var idx := AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	if effect.is_recording_active():
		stop_recording()
	else:
		Roth.stop_audio_buffer()
		%Timer.stop()
		play_position = 0
		%Waveform.update_position((play_position / end_position) if not is_equal_approx(end_position, 0.0) else 0.0)


func _on_play_button_pressed() -> void:
	Roth.play_audio_entry(FXScript.convert_to_playable_entry(audio_entry, start_index, end_index))
	var sample_rate: float = 22050.0
	if audio_entry.type == 1:
		sample_rate = 11025.0
	elif audio_entry.type == 3:
		pass
	else:
		return
	play_position = start_index / sample_rate
	end_position = end_index / sample_rate
	%Timer.start()
	%Waveform.update_position(play_position / end_position)


func _on_browse_filesystem_button_pressed() -> void:
	_on_stop_button_pressed()
	%FileDialog.popup_centered()


func _on_cancel_button_pressed() -> void:
	done.emit({})


func _on_reset_button_pressed() -> void:
	audio_entry = original_audio_entry.duplicate(true)
	%StartMarker.initialize()
	%EndMarker.initialize()
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry), true)
	update_length()
	


func _on_save_button_pressed() -> void:
	audio_entry.raw_data = audio_entry.raw_data.slice(start_index*2, end_index*2)
	done.emit(audio_entry)


func _on_file_dialog_file_selected(path: String) -> void:
	if path.get_extension().to_lower() != "wav":
		return
	
	var file := AudioStreamWAV.load_from_file(path, {
		"compress/mode": 0,
		"force/max_rate": true,
		"force/max_rate_hz": 22050,
		"force/mono": true,
	})
	
	if not file:
		return
	
	if file.format != AudioStreamWAV.FORMAT_16_BITS:
		Console.print("ERROR: File must be 16 bit")
		return
	
	if file.mix_rate == 22050:
		audio_entry.type = 3
	elif file.mix_rate == 11025:
		audio_entry.type = 1
	else:
		Console.print("ERROR: File must be at least 11025 Hz")
		return
	audio_entry.raw_data = file.data
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry), true)
	%StartMarker.initialize()
	%EndMarker.initialize()
	update_length()


func _on_timer_timeout() -> void:
	var idx := AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	if not effect.is_recording_active():
		play_position += 0.1
		if play_position > end_position:
			%Timer.stop()
			play_position = 0
		%Waveform.update_position(play_position / end_position)


func _on_record_timer_timeout() -> void:
	var idx := AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	if effect.is_recording_active():
		var recording: AudioStreamWAV = effect.get_recording()
		if recording.format != 1:
			return
		var data: PackedByteArray = recording.data
		var length_data: float = len(data)
		if recording.stereo:
			recording.stereo = false
			data = convert_to_mono(data)
			length_data *= 0.5
		if recording.mix_rate != 22050:
			length_data *= 22050.0/recording.mix_rate
			#data = downsample(data, recording.mix_rate, 22050)
		audio_entry.raw_data = data
		audio_entry.type = 3
		%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry))
		var length: float = (length_data / 2.0 / 22050)
		%LengthLabel.text = "Length: %.2fs" % length
		%RecordTimer.wait_time = (length / 100) + 0.1


func _on_amp_down_button_pressed() -> void:
	var new_data := PackedByteArray()
	new_data.resize(len(audio_entry.raw_data))
	for i in range(0, len(audio_entry.raw_data), 2):
		var frame: float = (audio_entry.raw_data[i]) + (audio_entry.raw_data[i+1] << 8)
		frame = Parser.unsigned16_to_signed(int(frame))
		frame /= 1.10
		new_data[i+1] = (int(frame) >> 8)
		new_data[i] = (int(frame) & 0xFF)
	
	audio_entry.raw_data = new_data
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry))


func _on_amp_up_button_pressed() -> void:
	var new_data := PackedByteArray()
	new_data.resize(len(audio_entry.raw_data))
	for i in range(0, len(audio_entry.raw_data), 2):
		var frame: float = (audio_entry.raw_data[i]) + (audio_entry.raw_data[i+1] << 8)
		frame = Parser.unsigned16_to_signed(int(frame))
		frame *= 1.10
		if frame > 32767 or frame < -32768:
			return
		new_data[i+1] = (int(frame) >> 8)
		new_data[i] = (int(frame) & 0xFF)
	
	audio_entry.raw_data = new_data
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry))


func _on_reverse_button_pressed() -> void:
	var new_data := []
	for i in range(0, len(audio_entry.raw_data), 2):
		var frame: float = (audio_entry.raw_data[i]) + (audio_entry.raw_data[i+1] << 8)
		new_data.append(int(frame))
	new_data.reverse()
	var j: int = 0
	for i in range(0, len(new_data)):
		audio_entry.raw_data[j] = new_data[i] & 0xFF
		audio_entry.raw_data[j+1] = new_data[i] >> 8
		j += 2
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry))


func _on_browse_existing_button_pressed() -> void:
	var sfx: Dictionary = await owner.select_sfx()
	if sfx.is_empty():
		return
	audio_entry = sfx.duplicate(true)
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry), true)
	%StartMarker.initialize()
	%EndMarker.initialize()
	update_length()


func _on_start_marker_moved() -> void:
	%Waveform.update_start_marker(%StartMarker.position.x+%StartMarker.size.x/2)
	update_length()


func _on_end_marker_moved() -> void:
	%Waveform.update_end_marker(%EndMarker.position.x+%EndMarker.size.x/2)
	update_length()


func stop_recording() -> void:
	var idx := AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	effect.set_recording_active(false)
	var recording: AudioStreamWAV = effect.get_recording()
	if recording.format != 1:
		Console.print("ERROR: Can only record at 16bit")
		return
	var data: Array = recording.data
	if recording.stereo:
		data = convert_to_mono(data)
	if recording.mix_rate > 22050:
		data = downsample_audio(data, recording.mix_rate, 22050)
	if recording.mix_rate == 11025:
		audio_entry.type = 1
	else:
		audio_entry.type = 3
	audio_entry.raw_data = data
	%Waveform.setup(FXScript.convert_to_playable_entry(audio_entry))
	%PlayButton.disabled = false
	%AmpDownButton.disabled = false
	%AmpUpButton.disabled = false
	%ReverseButton.disabled = false
	%RecordButton.disabled = false
	%BrowseFilesystemButton.disabled = false
	%BrowseExistingButton.disabled = false
	%CancelButton.disabled = false
	%ResetButton.disabled = false
	%SaveButton.disabled = false
	%DeviceOption.disabled = false
	%RecordTimer.stop()
	%AudioStreamRecorder.stop()
	update_length()


func _on_record_button_pressed() -> void:
	var idx := AudioServer.get_bus_index("Record")
	var effect: AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
	if effect.is_recording_active():
		stop_recording()
	else:
		%StartMarker.initialize()
		%EndMarker.initialize()
		%Waveform.setup({"data": [Vector2.ZERO,Vector2.ZERO]}, true)
		%AudioStreamRecorder.play()
		effect.set_recording_active(true)
		%PlayButton.disabled = true
		%AmpDownButton.disabled = true
		%AmpUpButton.disabled = true
		%ReverseButton.disabled = true
		%RecordButton.disabled = true
		%BrowseFilesystemButton.disabled = true
		%BrowseExistingButton.disabled = true
		%CancelButton.disabled = true
		%ResetButton.disabled = true
		%SaveButton.disabled = true
		%DeviceOption.disabled = true
		%RecordTimer.wait_time = 0.1
		%RecordTimer.start()


func convert_to_mono(stereo_audio: PackedByteArray) -> PackedByteArray:
	var mono_audio := PackedByteArray()
	assert(len(stereo_audio) % 4 == 0)
	mono_audio.resize(roundi(len(stereo_audio)/2.0))
	for i in range(0, len(stereo_audio), 4):
		var left: int = stereo_audio.decode_s16(i)
		var right: int = stereo_audio.decode_s16(i+2)
		var average: int = roundi((left + right) / 2.0)
		mono_audio.encode_u16(roundi(i/2.0), average)
	return mono_audio


func downsample_audio(input_data: PackedByteArray, src_rate: int, dst_rate: int) -> PackedByteArray:
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


func _on_device_option_item_selected(index: int) -> void:
	AudioServer.input_device = AudioServer.get_input_device_list()[index]
