extends Control

enum PlayerState {
	UNLOADED,
	STOPPED,
	PAUSED,
	PLAYING,
}

@export var hide_controls: bool = false

var gdv_data: Dictionary = {}
var length: int :
	get():
		if not gdv_data.is_empty():
			return roundi(len(gdv_data.video)/float(gdv_data.header.framerate))
		else:
			return 0
var current_frame: int = 0
var dragging_slider: bool = false
var is_playing: bool = false
var is_paused: bool = false
var player_state := PlayerState.UNLOADED
var accumulated_delta: float = 0.0
var stop_loading: bool = false
var loop: bool = false
var is_loading: bool = false
var load_next: Dictionary = {}
var thread: Thread

func _ready() -> void:
	if hide_controls:
		%ControlsContainer.hide()
		%TitleLabel.hide()
		%HSeparator.hide()


func _process(delta: float) -> void:
	if player_state == PlayerState.PLAYING:
		accumulated_delta += delta
		while accumulated_delta >= (1.0 / gdv_data.header.framerate):
			accumulated_delta -= (1.0 / gdv_data.header.framerate)
			_next_frame(false)


func load_gdv_data(p_gdv_data: Dictionary, p_autoplay: bool = false, p_loop: bool = false) -> void:
	if "video" not in p_gdv_data:
		if thread:
			thread.stop_loading = true
		reset()
		return
	if is_loading:
		load_next = p_gdv_data
		if thread:
			thread.stop_loading = true
		return
	is_loading = true
	reset()
	if "video" not in p_gdv_data:
		return
	gdv_data = p_gdv_data.duplicate(true)
	%SeekSlider.max_value = len(gdv_data.video)-1
	%SeekSlider.editable = true
	if "name" in gdv_data:
		if "subtitles" in gdv_data and "title" in gdv_data.subtitles:
			%TitleLabel.text = gdv_data.subtitles.title
		else:
			%TitleLabel.text = gdv_data.name
		%TitleLabel.show()
		%HSeparator.show()
		%ControlsContainer.show()
		%TimeLabel.text = "00:00/%s" % Utility.seconds_to_time(length)
	else:
		%CinematicButton.button_pressed = false
	
	loop = p_loop
	thread = GDV.GDVDecodeThread.new()
	thread.start(thread._decode_gdv_thread.bind(gdv_data, _on_loading_update))
	player_state = PlayerState.STOPPED
	if p_autoplay:
		player_state = PlayerState.PLAYING
	_update_texture(player_state == PlayerState.PLAYING)
	while thread.is_alive():
		await get_tree().process_frame
	var success: bool = thread.wait_to_finish()
	if not success:
		player_state = PlayerState.UNLOADED
	is_loading = false
	if not load_next.is_empty():
		var gdv: Dictionary = load_next
		load_next = {}
		load_gdv_data(gdv, p_autoplay, p_loop)


func unload() -> void:
	gdv_data.clear()


func reset() -> void:
	player_state = PlayerState.UNLOADED
	current_frame = 0
	accumulated_delta = 0.0
	%SeekSlider.percent = 0.0
	_load_frame(null)
	%SeekSlider.set_value_no_signal(0)
	%SubtitleLabel.text = ""
	dragging_slider = false
	%TitleLabel.hide()
	%HSeparator.hide()
	%ControlsContainer.hide()


func play() -> void:
	if player_state != PlayerState.UNLOADED:
		player_state = PlayerState.PLAYING
	elif not gdv_data.is_empty():
		load_gdv_data(gdv_data, true)


func pause() -> void:
	if player_state == PlayerState.PAUSED:
		player_state = PlayerState.PLAYING
	elif player_state == PlayerState.PLAYING:
		player_state = PlayerState.PAUSED


func _on_loading_update(percent: float) -> void:
	%SeekSlider.percent = percent


func _next_frame(clear_audio: bool) -> void:
	%TimeLabel.text = "%s/%s" % [Utility.seconds_to_time(roundi(float(current_frame)/gdv_data.header.framerate)), Utility.seconds_to_time(length)]
	if loop and current_frame >= len(gdv_data.video)-1:
		current_frame = 0
	if current_frame >= len(gdv_data.video)-1:
		player_state = PlayerState.STOPPED
		RothAudio.stop()
		current_frame = len(gdv_data.video)-1
		accumulated_delta = 0.0
		_update_texture(false)
	else:
		await _update_texture(player_state == PlayerState.PLAYING)
		if "video" not in gdv_data:
			return
		_update_subtitle()
		if player_state == PlayerState.PLAYING:
			if "audio" in gdv_data and len(gdv_data.audio) > current_frame:
				if clear_audio:
					RothAudio.play_buffer(gdv_data.audio[current_frame].decoded_audio, gdv_data.header.playback_frequency)
				else:
					RothAudio.append_buffer(gdv_data.audio[current_frame].decoded_audio, gdv_data.header.playback_frequency)
		current_frame += 1
	if not dragging_slider:
		%SeekSlider.value = current_frame


func _update_texture(continue_playing: bool) -> void:
	if "video" not in gdv_data:
		return
	while "decoded_video" not in gdv_data.video[current_frame]:
		player_state = PlayerState.PAUSED
		if not dragging_slider:
			%DragLabel.text = "Decoding..."
		await get_tree().process_frame
		if "video" not in gdv_data:
			return
	if not dragging_slider:
		%DragLabel.text = ""
	if continue_playing:
		player_state = PlayerState.PLAYING
	if not (gdv_data.video[current_frame].header.type_flags & 0b10000000):
		_load_frame(gdv_data.video[current_frame].decoded_video)


func _load_frame(image: Image) -> void:
	if image:
		if %CinematicButton.button_pressed:
			var dup_image: Image = image.duplicate()
			var canvas_image := Image.create_empty(dup_image.get_width(), dup_image.get_height(), false, dup_image.get_format())
			dup_image.resize(dup_image.get_width(), roundi(dup_image.get_height()/2.0), Image.INTERPOLATE_NEAREST)
			canvas_image.blit_rect(dup_image, Rect2i(Vector2i.ZERO, dup_image.get_size()), Vector2i(0, int(canvas_image.get_height()/4.0)))
			%VideoRect.texture = ImageTexture.create_from_image(canvas_image)
		else:
			%VideoRect.texture = ImageTexture.create_from_image(image)
	else:
		%VideoRect.texture = null


func _update_subtitle(p_frame: int = -1) -> void:
	if "subtitles" not in gdv_data:
		return
	var frame: int = current_frame
	if p_frame > -1:
		frame = p_frame
	var closest_subtitle: Dictionary = {}
	for subtitle: Dictionary in gdv_data.subtitles.entries:
		if subtitle.timestamp <= roundi(frame * (gdv_data.header.playback_frequency / 22050.0) * 10.0 / gdv_data.header.framerate):
			closest_subtitle = subtitle
	if closest_subtitle.is_empty():
		%SubtitleLabel.text = ""
	else:
		%SubtitleLabel.text = closest_subtitle.string
		var color := Color(Das.DEFAULT_PALETTE[closest_subtitle.font_color][0], Das.DEFAULT_PALETTE[closest_subtitle.font_color][1], Das.DEFAULT_PALETTE[closest_subtitle.font_color][2])
		%SubtitleLabel.add_theme_color_override("font_color", color)


func _on_play_button_pressed() -> void:
	play()


func _on_pause_button_pressed() -> void:
	pause()


func _on_stop_button_pressed() -> void:
	if gdv_data.is_empty():
		return
	RothAudio.stop()
	%SeekSlider.value = 0
	current_frame = 0
	accumulated_delta = 0.0
	%SubtitleLabel.text = ""
	%TimeLabel.text = "00:00/%s" % Utility.seconds_to_time(length)
	player_state = PlayerState.STOPPED
	_load_frame(gdv_data.video[0].decoded_video)

 
func _on_cinematic_button_pressed() -> void:
	_update_texture(false)


func _on_seek_slider_drag_started() -> void:
	dragging_slider = true


func _on_seek_slider_drag_ended(value_changed: bool) -> void:
	if gdv_data.is_empty():
		return
	dragging_slider = false
	%DragLabel.text = ""
	if value_changed:
		%SubtitleLabel.text = ""
		current_frame = %SeekSlider.value
		_next_frame(true)


func _on_seek_slider_value_changed(value: float) -> void:
	if gdv_data.is_empty():
		return
	if dragging_slider:
		%DragLabel.text = "%s" % Utility.seconds_to_time(roundi(float(value)/gdv_data.header.framerate))
		if player_state == PlayerState.PAUSED or player_state == PlayerState.STOPPED:
			_update_subtitle(int(value))
			if "decoded_video" in gdv_data.video[value]:
				while gdv_data.video[value].header.type_flags & 0b10000000:
					value -= 1
				_load_frame(gdv_data.video[value].decoded_video)
