extends "res://scripts/components/character customization/customization_assigner.gd"

const MOD_ID := "cosmeticsMod"
const REFRESH_CUSTOM_COSMETICS_KEY := KEY_R

var custom_cosmetics: Array[Dictionary] = []
var _valid_cosmetic_types: Array[String] = ["hat", "glasses"]


func _ready() -> void:
	super._ready()
	print("customization assigner override script ready")
	print("available cosmetic types are: " + ", ".join(_valid_cosmetic_types))

	refresh_custom_cosmetics()
	print_custom_cosmetics()
	_equip_currently_selected()


func print_custom_cosmetics() -> void:
	print("loaded custom cosmetics:")
	for cosmetic in custom_cosmetics:
		var entries: PackedStringArray = []
		for key in cosmetic:
			entries.append(str(key, ": ", cosmetic[key]))
		print(" | ".join(entries))
		print()


#for the preview head hat
func register_custom_cosmetics() -> void:
	for cosmetic in custom_cosmetics:
		var cosmetic_id: String = cosmetic["id"]
		var cosmetic_type: String = cosmetic["type"]

		var target_parent: Node3D

		if cosmetic_type == "hat":
			target_parent = bone_attachment_hat
		elif cosmetic_type == "glasses":
			target_parent = bone_attachment_glasses
		else:
			continue

		# Don't add a duplicate if this cosmetic is already registered.
		if target_parent.has_node(NodePath(cosmetic_id)):
			continue

		var model: Node3D = _load_glb_model(cosmetic["model_path"])
		if model == null:
			continue

		model.name = cosmetic_id
		_apply_node3d_transform(model, cosmetic.transform_values)
		target_parent.add_child(model)
		model.visible = false

		print("Registered custom cosmetic: ", cosmetic_id)


func _equip_currently_selected():
	print(Globals.active_cosmetic_hat)
	print(Globals.active_cosmetic_glasses)
	assign_hat(Globals.active_cosmetic_hat)
	assign_glasses(Globals.active_cosmetic_glasses)


# for the hat preview grid
func add_custom_model(parent: Node3D, cosmetic, make_visible: bool = false) -> Node3D:
	# Reuse an existing model if it has already been added.
	var existing_model := parent.get_node_or_null(NodePath(str(cosmetic.id)))

	if existing_model is Node3D:
		existing_model.visible = make_visible
		return existing_model

	# Load the model if it doesn't exist yet.
	var model: Node3D = _load_glb_model(cosmetic.model_path)

	if model == null:
		return null

	model.name = cosmetic.id
	# apply_cosmetic_transform(model, cosmetic)
	parent.add_child(model)
	model.visible = make_visible

	return model


func _load_glb_model(model_path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()

	var error := document.append_from_file(model_path, state)
	if error != OK:
		push_warning("could not load: " + model_path)
		return null

	return document.generate_scene(state)


func _path_in_mod(local_path: String) -> String:
	return ModLoader.dir_of(MOD_ID).path_join(local_path)


func refresh_custom_cosmetics() -> void:
	custom_cosmetics = discover_cosmetics()
	register_custom_cosmetics()


# dictionary array of cosmetics found in the [mod]/assets/cosmetics directory
func discover_cosmetics() -> Array[Dictionary]:
	var discovered_cosmetics: Array[Dictionary] = []

	# set up access to the cosmetics directory
	# skip if directory inaccessible
	var cosmetics_dir_path := _path_in_mod("assets/cosmetics")
	var cosmetics_dir := DirAccess.open(cosmetics_dir_path)
	if cosmetics_dir == null:
		push_warning("could not access directory: " + cosmetics_dir_path)
		return []

	# go through all the files, locate jsons and parse the required cosmetic data from them
	for current_file in cosmetics_dir.get_files():
		# skip non-json files
		if current_file.get_extension().to_lower() != "json":
			continue

		# access the json file and get the parsed metadata (cosmetic_dictionary) from it
		# skip if cannot access or parse the json
		var json_path := cosmetics_dir_path.path_join(current_file)
		var json_fileaccess := FileAccess.open(json_path, FileAccess.READ)
		if json_fileaccess == null:
			push_warning("could not access json at: " + json_path)
			continue
		var parsed_json_metadata: Variant = JSON.parse_string(json_fileaccess.get_as_text())
		json_fileaccess.close()
		if not parsed_json_metadata is Dictionary:
			push_warning("invalid cosmetic json: " + json_path)
			continue
		# set cosmetic id to the json filename
		var cosmetic_dictionary: Dictionary = { "id": current_file.get_basename() }
		cosmetic_dictionary.merge(parsed_json_metadata)

		# validate the cosmetic type
		# skip if invalid
		var cosmetic_type := str(cosmetic_dictionary.get("type", "")).to_lower()
		if cosmetic_type not in _valid_cosmetic_types:
			push_warning(
				"invalid cosmetic type \"" + cosmetic_type + "\" in: " + json_path
				+ ". available cosmetic types are: " + ", ".join(_valid_cosmetic_types)
			)
			continue

		# locate cosmetic model by id
		# skip if not found
		var c_model_path := cosmetics_dir_path.path_join(cosmetic_dictionary["id"] + ".glb")
		if not FileAccess.file_exists(c_model_path):
			push_warning("cosmetic model not found: " + c_model_path)
			continue
		cosmetic_dictionary["model_path"] = c_model_path

		# set missing fields defaults
		if (cosmetic_dictionary["display_name"] == null):
			print("\"display_name\" missing for cosmetic " + cosmetic_dictionary.id + ". defaulting to id; (" + cosmetic_dictionary.id + ")")
			cosmetic_dictionary["display_name"] = cosmetic_dictionary.id
		if (cosmetic_dictionary["gibberish_name"] == null):
			print("\"gibberish_name\" missing for cosmetic " + cosmetic_dictionary.id + ". defaulting to 0020404")
			cosmetic_dictionary["gibberish_name"] = "0020404"
		if (cosmetic_dictionary["compatible_with_glasses"] == null):
			print("cosmetic field \"compatible_with_glasses\" is null. defaulting to \"true\" for cosmetic " + cosmetic_dictionary["id"])
			cosmetic_dictionary["compatible_with_glasses"] = true

		# save entry to discovered cosmetics
		discovered_cosmetics.append(cosmetic_dictionary)

	return discovered_cosmetics


"""
cases:

- adding a new model and need to apply one specific transform to it
absolute==true:
_apply_node3d_transform(model, {"position": [1, 0.5], "rotation_degrees": [0, 90], "scale": 2}, true)
position:
	set directly.
	if a value is missing, substitue with 0
	if entire "position" key is missing, substitute with Vector3.ZERO
rotation:
	set drectly.
	if a value is missing, substitue with 0
	if entire "rotation_degrees" key is missing, substitute with Vector3.ZERO
scale:
	set directly.
	if a value is missing, substitute with 1
	if entire "scale" key is missing, substitute with Vector3.ONE

- editing the model in the cosmetics editor
absolute==false:
_apply_node3d_transform(model, {"position": [1, 0.5], "rotation_degrees": [0, 90], "scale": 2}, false)
position:
	add to existing position.
	if a value is missing, substitue with 0
	if entire "position" key is missing, substitute with Vector3.ZERO
rotation:
	add to existing rotation.
	if a value is missing, substitue with 0
	if entire "rotation_degrees" key is missing, substitute with Vector3.ZERO
scale:
	add to existing scale.
	if a value is missing, substitute with 0
	if entire "scale" key is missing, substitute with Vector3.ZERO

* if the value is only a single number (not an array or smth else), make all 3 dimensions of the vector that number
"""


# set a Node3D's transform values (position, rotation, scale)
# "absolute" specifies how to set the object's transform
# - true: set the object's transform directly to the new values
# - false: add the new values to the object's current transform
func _apply_node3d_transform(model_node3d: Node3D, transform_values: Dictionary, absolute: bool) -> void:
	# attempt to get Vector3s from "transform_values" Dicionary: "position", "rotation_degrees", "scale"
	# if that fails, default to Vector3.ZERO (or .ONE for absolute scale)
	var new_position: Vector3 = _get_vector3(transform_values.get("position", null), Vector3.ZERO)
	var new_rotation: Vector3 = _get_vector3(transform_values.get("rotation_degrees", null), Vector3.ZERO)
	if (absolute):
		var new_scale: Vector3 = _get_vector3(transform_values.get("scale", null), Vector3.ONE)
	else:
		var new_scale: Vector3 = _get_vector3(transform_values.get("scale", null), Vector3.ZERO)

	# apply the new transform values
	# absolute - set directly, not absolute - add to current transform
	if (absolute):
		model_node3d.position = new_position
		model_node3d.rotation_degrees = new_rotation
		model_node3d.scale = new_scale
	else:
		model_node3d.position += new_position
		model_node3d.rotation_degrees += new_rotation
		model_node3d.scale += new_scale


func _get_vector3(transform_values: Variant, default_transform: Vector3) -> Vector3:
	# if "transform_values" is already a Vector3, return that
	if (transform_values is Vector3):
		return transform_values
	# if the transform value is a single number (int or float), set all 3 dimensions of the vector to that
	if (transform_values is int || transform_values is float):
		return Vector3(transform_values, transform_values, transform_values)
	# if its some other weird junk, return the default
	if (transform_values == null || transform_values is not Array || transform_values.is_empty()):
		return default_transform

	# start from object's current transform
	var result := [default_transform.x, default_transform.y, default_transform.z]

	# go through all the values in "transform_values" (capped at 3) and set the result as those values
	for i in range(min(transform_values.size(), 3)):
		result[i] = transform_values[i]

	# if only one value is supplied for "scale", use that value for all 3 axes
	if (transform_values.size() == 1):
		result[1] = transform_values[0]
		result[2] = transform_values[0]

	return Vector3(result[0], result[1], result[2])
