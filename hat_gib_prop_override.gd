extends "res://modules/prop_manager/scripts/hat_gib_prop.gd"

var model: Node3D

@onready var assigner = get_tree().root.find_child("customization assigner", true, false)


func _ready() -> void:
	print("hat gib prop override ready")


func add_custom_cosmetic_model_to_hatgib_node(cosmetic_name: String):
	# skip duplicates
	if (hat_meshes.has(cosmetic_name)):
		return

	if (assigner == null):
		push_warning("Could not find customization assigner")
		return

	# locate hatgib models node that the hats will be attached to
	var models_node: Node3D = get_node_or_null("Models")
	if (models_node == null):
		push_warning("hatgib models node null")
		return

	for cosmetic in assigner.custom_cosmetics:
		if (cosmetic.type == "hat" && cosmetic.id == cosmetic_name):
			model = assigner.generate_glb_model_scene(cosmetic["absolute_model_path"])
			if (model == null):
				print(cosmetic.id + " hatgib model null")
				continue

			model.name = str(cosmetic.id)
			models_node.add_child(model)
			model.visible = false

			assigner.apply_node3d_transform(model, cosmetic["transform_values"], true)

			hat_meshes[cosmetic.id] = model
			print("added hat" + cosmetic.id + " to hatgib")


func set_active_rpc(_active: bool, _arguments: Array = []) -> void:
	# add_custom_cosmetic_model_to_hatgib_node(_arguments[0])
	# super.set_active_rpc(_active, _arguments)
	add_custom_cosmetic_model_to_hatgib_node(&"mr-tenna")
	super.set_active_rpc(_active, [&"mr-tenna"])
