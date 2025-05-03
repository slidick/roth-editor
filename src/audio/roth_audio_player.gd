extends AudioStreamPlayer
class_name RothAudioPlayer

const SAMPLE_RATE: int = 22050
const MAX_LENGTH: int = 100

var playback: AudioStreamGeneratorPlayback 

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = MAX_LENGTH
	stream = generator

func stop_buffer() -> void:
	if playback:
		playback.stop()

func play_buffer(_buffer: PackedVector2Array) -> void:
	if playback:
		playback.stop()
	#playback.clear_buffer()
	play()
	playback = self.get_stream_playback()
	for frame: Vector2 in _buffer:
		playback.push_frame(frame)
