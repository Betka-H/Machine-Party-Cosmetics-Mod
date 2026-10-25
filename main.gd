extends Node

var _loader

const MOD_ID := "cosmeticsMod"


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
