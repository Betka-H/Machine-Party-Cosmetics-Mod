extends "res://scenes/local_lobby/scripts/local_lobby_player_controls.gd"

const REFRESH_CUSTOM_COSMETICS_KEY := KEY_R


func _ready() -> void:
	super._ready()
	print("local_lobby_player_controls override ready")


func _unhandled_input(event: InputEvent) -> void:
	if (event.keycode == REFRESH_CUSTOM_COSMETICS_KEY):
		customization_assigner.refresh_custom_cosmetics_on_head_bones()
		change_hat(0)


func change_hat(direction: int):
	var new_hats = hats.duplicate()
	new_hats.append("rubiks_cube")

	# add custom hats to the hats list
	for cosmetic in customization_assigner.custom_cosmetics:
		if (!new_hats.has(cosmetic.id) && cosmetic.type == "hat"):
			new_hats.append(cosmetic.id)

	# [modified] vanilla function, but with new_hats instead of that stupid fucking hats const list...
	var current_hat_name = customization_assigner.get_assigned_hat()
	var current_hat_index = new_hats.find(current_hat_name)
	if current_hat_index < 0:
		current_hat_index = 0

	# go to 0th hat when custom hats are reloaded
	if (direction == 0):
		current_hat_index = 0

	var new_hat_name = new_hats[wrapi(current_hat_index + direction, 0, new_hats.size())]

	if tween_buttons:
		tween_buttons.kill()
	tween_buttons = create_tween()
	match direction:
		-1:
			hat_prev.self_modulate.a = 1
			tween_buttons.tween_property(hat_prev, "self_modulate", tween_color_end, 0.1)
		1:
			hat_next.self_modulate.a = 1
			tween_buttons.tween_property(hat_next, "self_modulate", tween_color_end, 0.1)

	customization_assigner.assign_hat(new_hat_name)
