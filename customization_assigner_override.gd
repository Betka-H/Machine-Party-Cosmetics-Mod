extends "res://scripts/components/character customization/customization_assigner.gd"

const MOD_ID := "cosmeticsMod"
const REFRESH_CUSTOM_COSMETICS_KEY := KEY_R

var custom_cosmetics: Array[Dictionary] = []
var _valid_cosmetic_types: Array[String] = ["hat", "glasses"]


func _full_loader_path(local_path: String) -> String:
	return ModLoader.dir_of(MOD_ID).path_join(local_path)


func print_custom_cosmetics() -> void:
	print(
		"available custom cosmetics: "
		+ ", ".join(
			custom_cosmetics.map(
				func(cosmetic):
					return cosmetic.id,
			)
		)
	)


func _ready() -> void:
	# refresh first so that the new cosmetics are added to the bones before attempting to assign them
	refresh_custom_cosmetics_on_head_bones()
	super._ready()


"""

adding models ingame

"""


func refresh_custom_cosmetics_on_head_bones() -> void:
	custom_cosmetics = _discover_cosmetics()

	for cosmetic in custom_cosmetics:
		var target_bone: Node3D

		match (cosmetic["type"]):
			"hat":
				target_bone = bone_attachment_hat
			"glasses":
				target_bone = bone_attachment_glasses
			_:
				push_warning("no bone")
				continue

		add_cosmetic_to_node3d(cosmetic, target_bone)

	print_custom_cosmetics()


func add_cosmetic_to_node3d(cosmetic_dictionary: Dictionary, parent_node: Node3D) -> void:
	print(parent_node.name)
	# don't add duplicates
	if parent_node.has_node(NodePath(cosmetic_dictionary.id)):
		return

	var model: Node3D = _generate_glb_model_scene(cosmetic_dictionary["absolute_model_path"])
	if model == null:
		return

	model.name = cosmetic_dictionary.id
	_apply_node3d_transform(model, cosmetic_dictionary["transform_values"], true)
	parent_node.add_child(model)
	model.visible = false

	print("added cosmetic " + cosmetic_dictionary.id + " to parent " + parent_node.name)


func _generate_glb_model_scene(absolute_model_path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()

	var error := document.append_from_file(absolute_model_path, state)
	if error != OK:
		push_warning("could not load model: " + absolute_model_path)
		return null

	return document.generate_scene(state)


"""

cosmetics discovery

"""


# dictionary array of cosmetics found in the assets/cosmetics directory and its subdirectories
# discovered_cosmetics is a dictionary of:
# "id": the cosmetic's internal id
# "absolute_model_path": the absolute path to the cosmetic's model
# "type": "hat" or "glasses"
# "transform_values", if the cosmetic's .json specifies any
# "display_name", "gibberish_name", "compatible_with_glasses": self explanatory
func _discover_cosmetics() -> Array[Dictionary]:
	var discovered_cosmetics: Array[Dictionary] = []
	# saves discovered ids and the path to their json (to determine priority on duplicate ids)
	var discovered_ids: Dictionary = { }

	# all of the .json files located in the directory and its subdirectories
	# it is a dictionary of:
	# "absolute_json_path": the json's full path from the root of the mod
	# "relative_json_path": the json's path from the assets/cosmetics root
	# "depth": how many folders deep is the json
	var collected_jsons := _collect_cosmetic_jsons(_full_loader_path("assets/cosmetics"))

	# sort the collected_jsons by depth, then path, so shallower cosmetics take priority
	collected_jsons.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if a.depth != b.depth:
				return a.depth < b.depth
			return a.absolute_json_path < b.absolute_json_path,
	)

	# go through all the files, locate jsons and parse the required cosmetic data from them
	for json_file_info in collected_jsons:
		var absolute_json_path: String = json_file_info.absolute_json_path
		var relative_json_path: String = json_file_info.relative_json_path
		var current_file_basename: String = absolute_json_path.get_file().get_basename()

		# access the json file and get the parsed parsed_json_metadata: Dictionary from it
		# skip if cannot access or parse the json
		var json_fileaccess := FileAccess.open(absolute_json_path, FileAccess.READ)
		if json_fileaccess == null:
			push_warning("could not access json at: " + absolute_json_path)
			continue
		var parsed_json_metadata: Variant = JSON.parse_string(json_fileaccess.get_as_text())
		json_fileaccess.close()
		if not parsed_json_metadata is Dictionary:
			push_warning("could not parse json: " + absolute_json_path)
			continue

		# set cosmetic id to the json filename, prefixed with its parent folders
		var cosmetic_id: String
		if (relative_json_path.is_empty()):
			cosmetic_id = current_file_basename
		else:
			cosmetic_id = relative_json_path.replace("/", "_") + "_" + current_file_basename

		# cosmetic_dictionary will contain:
		# "id": the cosmetic's internal id
		# "absolute_model_path": the absolute path to the cosmetic's model
		# "type": "hat" or "glasses"
		# "transform_values", if the cosmetic's .json specifies any
		# "display_name", "gibberish_name", "compatible_with_glasses": self explanatory
		var cosmetic_dictionary: Dictionary = { }
		cosmetic_dictionary.merge(parsed_json_metadata)
		cosmetic_dictionary["id"] = cosmetic_id

		# validate the cosmetic type
		# skip if invalid
		var cosmetic_type := str(cosmetic_dictionary.get("type", "")).to_lower()
		if (cosmetic_type not in _valid_cosmetic_types):
			push_warning(
				"invalid cosmetic type \"" + cosmetic_type + "\" in: " + absolute_json_path
				+ ". available cosmetic types are: " + ", ".join(_valid_cosmetic_types)
			)
			print("defaulting to " + _valid_cosmetic_types[0])
			cosmetic_type = _valid_cosmetic_types[0]

		# locate cosmetic model by id
		# skip if not found
		var c_absolute_model_path := absolute_json_path.get_base_dir().path_join(current_file_basename + ".glb")
		if (!FileAccess.file_exists(c_absolute_model_path)):
			push_warning("cosmetic model not found: " + c_absolute_model_path)
			continue
		cosmetic_dictionary["absolute_model_path"] = c_absolute_model_path

		# set missing fields defaults
		if (cosmetic_dictionary.get("display_name") == null):
			print("\"display_name\" missing for cosmetic " + cosmetic_id + ". defaulting to cosmetic id; (" + cosmetic_id + ")")
			cosmetic_dictionary["display_name"] = cosmetic_id

		if (cosmetic_dictionary.get("gibberish_name") == null):
			print("\"gibberish_name\" missing for cosmetic " + cosmetic_id + ". defaulting to 0020404")
			cosmetic_dictionary["gibberish_name"] = "0020404"

		if (cosmetic_dictionary.get("compatible_with_glasses") == null):
			# print("cosmetic field \"compatible_with_glasses\" is null. defaulting to \"true\" for cosmetic " + cosmetic_id)
			cosmetic_dictionary["compatible_with_glasses"] = true

		# skip duplicate ids, keeping the shallowest cosmetic
		if (discovered_ids.has(cosmetic_id)):
			push_warning(
				"duplicate cosmetic id \"" + cosmetic_id + "\" at: " + absolute_json_path
				+ ". already discovered at: " + discovered_ids[cosmetic_id] + ". skipping duplicate."
			)
			continue

		# will only be added if the current .json wasnt skipped due to errors with itself or the model or if a valid cosmetic of the same name has not already been discovered
		discovered_ids[cosmetic_id] = absolute_json_path

		# save entry to discovered cosmetics
		discovered_cosmetics.append(cosmetic_dictionary)

	return discovered_cosmetics


# recursively locate all .json files in the cosmetics directory and its subdirectories
# found_json_files is a dictionary of:
# "absolute_json_path": the json's full path from the root of the mod
# "relative_json_path": the json's path from the assets/cosmetics root
# "depth": how many folders deep is the json
#     - this is used for sorting the cosmetics later to determine the order in which they will be discovered
func _collect_cosmetic_jsons(dir_to_search: String, relative_json_path: String = "", depth: int = 0) -> Array[Dictionary]:
	var found_json_files: Array[Dictionary] = []

	# skip if requested directory is inaccessible
	var dir_being_searched := DirAccess.open(dir_to_search)
	if (dir_being_searched == null):
		push_warning("could not access directory: " + dir_to_search)
		return []

	# sniff out .json files in the opened directory and add their info to the found files dictionary
	var files_in_dir := dir_being_searched.get_files()
	files_in_dir.sort()
	for file in files_in_dir:
		if (file.get_extension().to_lower() != "json"):
			continue
		found_json_files.append({ "absolute_json_path": dir_to_search.path_join(file), "relative_json_path": relative_json_path, "depth": depth })

	# recursively search subdirectories in the current directory for jsons and add the info from them too
	var subdirectories := dir_being_searched.get_directories()
	subdirectories.sort()

	for subdirectory in subdirectories:
		var absolute_subdirectory_path := dir_to_search.path_join(subdirectory)
		var relative_subdirectory_path := subdirectory if relative_json_path.is_empty() \
				else relative_json_path.path_join(subdirectory)
		# recursively add found jsons from all the deeper folders
		found_json_files.append_array(_collect_cosmetic_jsons(absolute_subdirectory_path, relative_subdirectory_path, depth + 1))

	return found_json_files


"""

applying node3d transforms

"""


# set a Node3D's transform values (position, rotation, scale)
# "absolute" specifies how to set the object's transform
# - true: set the object's transform directly to the new values
# - false: add the new values to the object's current transform
func _apply_node3d_transform(model_node3d: Node3D, transform_values: Dictionary, absolute: bool) -> void:
	"""
	cases of applying a transform:

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

	# attempt to get Vector3s from "transform_values" Dicionary: "position", "rotation_degrees", "scale"
	# if that fails, default to Vector3.ZERO (or .ONE for absolute scale)
	var new_position: Vector3 = _get_vector3(transform_values.get("position", null), Vector3.ZERO)
	var new_rotation: Vector3 = _get_vector3(transform_values.get("rotation_degrees", null), Vector3.ZERO)
	var new_scale: Vector3
	if (absolute):
		new_scale = _get_vector3(transform_values.get("scale", null), Vector3.ONE)
	else:
		new_scale = _get_vector3(transform_values.get("scale", null), Vector3.ZERO)

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

	# whatever doesnt get replaced will be the default value
	var result := [default_transform.x, default_transform.y, default_transform.z]

	# go through all the values in "transform_values" (capped at 3) and set the result as those values
	for i in range(min(transform_values.size(), 3)):
		result[i] = transform_values[i]

	return Vector3(result[0], result[1], result[2])


"""

cosmetic assign/remove functions

"""


func assign_hat(name: String):
	super.assign_hat(name)
	print("assigning cosmetic hat: " + name)


func remove_hat():
	super.remove_hat()
	print("removing hat")


func assign_glasses(name: String):
	super.assign_glasses(name)
	print("assigning cosmetic glasses: " + name)


func remove_glasses():
	super.remove_glasses()
	print("removing glasses")
