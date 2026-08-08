extends AudioStreamPlayer

const SAMPLE_RATE: int = 22050
const MAX_LENGTH: int = 100

var playback: AudioStreamGeneratorPlayback 


@warning_ignore("native_method_override")
func stop() -> void:
	if playback:
		playback.stop()
	playback = null
	stream = null


func play_buffer(_buffer: PackedVector2Array, sample_rate: int = SAMPLE_RATE) -> void:
	if playback:
		playback.stop()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = MAX_LENGTH
	stream = generator
	play()
	playback = self.get_stream_playback()
	for frame: Vector2 in _buffer:
		playback.push_frame(frame)


func append_buffer(_buffer: PackedVector2Array, sample_rate: int = SAMPLE_RATE) -> void:
	if not stream or stream.mix_rate != sample_rate:
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = sample_rate
		generator.buffer_length = MAX_LENGTH
		stream = generator
	if not playing:
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
