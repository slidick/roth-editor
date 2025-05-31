extends AudioStreamPlayer
class_name RothAudioPlayer

const SAMPLE_RATE: int = 22050
const MAX_LENGTH: int = 100

var playback: AudioStreamGeneratorPlayback 


func stop_buffer() -> void:
	if playback:
		playback.stop()


func play_buffer(_buffer: PackedVector2Array) -> void:
	if playback:
		playback.stop()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = MAX_LENGTH
	stream = generator
	play()
	playback = self.get_stream_playback()
	for frame: Vector2 in _buffer:
		playback.push_frame(frame)


func play_entry(entry: Dictionary) -> void:
	if playback:
		playback.stop()
	var generator := AudioStreamGenerator.new()
	match entry.type:
		1:
			generator.mix_rate = 11025
		3:
			generator.mix_rate = 22050
		_:
			return
	generator.buffer_length = MAX_LENGTH
	stream = generator
	play()
	playback = self.get_stream_playback()
	for frame: Vector2 in entry.data:
		playback.push_frame(frame)
