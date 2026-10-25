extends "res://scenes/local_lobby/scripts/local_lobby_player_controls.gd"

const MOD_ID := "cosmeticsMod"

var new_hats: Array[String] = []


func _ready() -> void:
	super._ready()
	print("\nlocal_lobby_player_controls override script ready")
	for cosmetic in customization_assigner.custom_cosmetics:
		if cosmetic.type == "hat":
			new_hats.append(cosmetic.id)
	new_hats.append_array(hats)
	print("new_hats:")
	print(new_hats)


func change_hat(direction: int) -> void:
	var current_hat_name: String = customization_assigner.get_assigned_hat()
	var current_hat_index: int = new_hats.find(current_hat_name)

	if current_hat_index < 0:
		current_hat_index = 0

	var new_hat_name: String = new_hats[wrapi(current_hat_index + direction, 0, new_hats.size())]

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
