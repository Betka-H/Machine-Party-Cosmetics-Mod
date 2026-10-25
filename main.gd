extends Node

var _loader

const GREEN_TOGGLE_KEY := KEY_G
const MOD_ID := "cosmeticsMod"

var _amongus_text: Label
var _green: TextureRect


func _full_loader_path(local_path: String) -> String:
	return _loader.dir_of(MOD_ID).path_join(local_path)


func _mod_init(loader) -> void:
	_loader = loader
	loader.override_script_rel(
		MOD_ID,
		"res://scripts/components/character customization/customization_assigner.gd",
		"customization_assigner_override.gd",
	)
	loader.override_script_rel(
		MOD_ID,
		"res://scripts/components/character customization/customization_selection.gd",
		"customization_selection_override.gd",
	)
	loader.override_script_rel(
		MOD_ID,
		"res://scripts/components/character customization/customization_selection_instance.gd",
		"customization_selection_instance_override.gd",
	)
	loader.override_script_rel(MOD_ID, "res://scenes/local_lobby/scripts/local_lobby_player_controls.gd", "local_lobby_player_controls_override.gd")
	loader.note("cosmetics mod initialised. scripts overriden")


func _mod_ready(loader) -> void:
	loader.note("cosmetics mod ready")
	_create_amongus()


"""


"""
# its just among us  v v v v v


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey && event.pressed && !event.echo && event.keycode == GREEN_TOGGLE_KEY:
		_toggle_amongus()
		# get_viewport().set_input_as_handled()
		return


func _create_amongus() -> void:
	# canvas
	var canvas := CanvasLayer.new()
	canvas.layer = 50
	get_tree().root.add_child.call_deferred(canvas)

	# 'Among Us' text
	_amongus_text = Label.new()
	_amongus_text.text = "Among us"
	_amongus_text.position = Vector2(825, 475)
	_amongus_text.add_theme_font_size_override("font_size", 24)
	canvas.add_child(_amongus_text)

	# getting the image for the green impostor from the hit friday night funkin mod vs impostor v4
	var image_path := _full_loader_path("assets/images/green.png")
	var image_data := Image.load_from_file(image_path)
	if image_data == null:
		_loader.note("couldnt locate image: " + image_path)
		return

	# green impostor from the hit friday night funkin mod vs impostor v4
	_green = TextureRect.new()
	_green.texture = ImageTexture.create_from_image(image_data)

	_green.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_green.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_green.size = Vector2(100, 100)

	_green.position = Vector2(_amongus_text.position.x - _green.size.x, _amongus_text.position.y + (_amongus_text.size.y - _green.size.y) / 2)

	canvas.add_child(_green)

	# hide at the start
	_toggle_amongus()


func _toggle_amongus() -> void:
	_amongus_text.visible = !_amongus_text.visible
	_green.visible = _amongus_text.visible # sync
