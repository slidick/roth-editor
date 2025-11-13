extends BaseWindow


signal finished(results: Array)


func _fade_out() -> void:
	super._fade_out()
	finished.emit([false])


func show_metadata(metadata: Dictionary) -> Array:
	%StartingPositionXEdit.text = "%d" % metadata.initPosX
	%StartingPositionYEdit.text = "%d" % metadata.initPosY
	%StartingPositionZEdit.text = "%d" % metadata.initPosZ
	%StartingRotationEdit.text = "%d" % metadata.rotation
	%MoveSpeedEdit.text = "%d" % metadata.moveSpeed
	%PlayerHeightEdit.text = "%d" % metadata.playerHeight
	%MaxClimbEdit.text = "%d" % metadata.maxClimb
	%MinimumFitEdit.text = "%d" % metadata.minFit
	%LightAmbienceEdit.text = "%d" % metadata.unk0x10
	%CandleGlowEdit.text = "%d" % metadata.candleGlow
	%CandleAmbienceEdit.text = "%d" % metadata.lightAmbience
	if metadata.unk0x16 == 255:
		%UseCandleShadeCheckBox.button_pressed = true
	else:
		%UseCandleShadeCheckBox.button_pressed = false
	%SkyTextureEdit.text = "%d" % metadata.skyTexture
	%unk0x1AEdit.text = "%d" % metadata.unk0x1A
	toggle(true)
	var results: Array = await finished
	toggle(false)
	return results


func _on_cancel_button_pressed() -> void:
	finished.emit([false])


func _on_save_button_pressed() -> void:
	var metadata := {}
	metadata.initPosX = int(%StartingPositionXEdit.text)
	metadata.initPosY = int(%StartingPositionYEdit.text)
	metadata.initPosZ = int(%StartingPositionZEdit.text)
	metadata.rotation = int(%StartingRotationEdit.text)
	metadata.moveSpeed = int(%MoveSpeedEdit.text)
	metadata.playerHeight = int(%PlayerHeightEdit.text)
	metadata.maxClimb = int(%MaxClimbEdit.text)
	metadata.minFit = int(%MinimumFitEdit.text)
	metadata.unk0x10 = int(%LightAmbienceEdit.text)
	metadata.candleGlow = int(%CandleGlowEdit.text)
	metadata.lightAmbience = int(%CandleAmbienceEdit.text)
	if %UseCandleShadeCheckBox.button_pressed:
		metadata.unk0x16 = 255
	else:
		metadata.unk0x16 = 0
	metadata.skyTexture = int(%SkyTextureEdit.text)
	metadata.unk0x1A = int(%unk0x1AEdit.text)
	finished.emit([true, metadata])


func _on_set_current_location_button_pressed() -> void:
	var player_position: Vector3 = %Camera3D.global_position
	player_position.y -= 1.2
	player_position *= Roth.SCALE_3D_WORLD
	%StartingPositionXEdit.text = "%d" % -player_position.x
	%StartingPositionYEdit.text = "%d" % player_position.z
	%StartingPositionZEdit.text = "%d" % player_position.y
	%StartingRotationEdit.text = "%d" % Roth.degrees_to_rotation(%Camera3D.global_rotation_degrees.y)
