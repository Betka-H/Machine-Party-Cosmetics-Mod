extends "res://modules/prop_manager/scripts/hat_gib_prop.gd"

const SCRIPT_NAME: String = "hat_gib_prop_override"


func set_active_rpc(_active: bool, _arguments: Array = []) -> void:
	add_custom_cosmetic_model_to_hatgib_node(_arguments[0])
	super.set_active_rpc(_active, _arguments)


func add_custom_cosmetic_model_to_hatgib_node(cosmetic_name: String):
	var customization_assigner = get_tree().root.find_child("customization assigner", true, false)
	if (customization_assigner == null):
		push_warning(SCRIPT_NAME, ": could not get customization_assigner")
		return

	# skip duplicates
	if (hat_meshes.has(cosmetic_name)):
		return

	var model: Node3D

	# locate hatgib models node that the hats will be attached to
	var models_node: Node3D = get_node_or_null("Models")
	if (models_node == null):
		push_warning(SCRIPT_NAME, ": hatgib \"Models\" node null")
		return

	# check requested name against custom cosmetics list and add its model if found
	for cosmetic in customization_assigner.custom_cosmetics:
		if (cosmetic.id == cosmetic_name && cosmetic.type == "hat"):
			model = customization_assigner.generate_glb_model_scene(cosmetic["absolute_model_path"])
			if (model == null):
				print(SCRIPT_NAME, ": ", cosmetic.id + " hatgib model null")
				continue

			model.name = str(cosmetic.id)
			models_node.add_child(model)
			model.visible = false

			customization_assigner.apply_node3d_transform(model, cosmetic["transform_values"], true)

			hat_meshes[cosmetic.id] = model
			print(SCRIPT_NAME, ": added hat" + cosmetic.id + " to hatgib")
