extends "res://scripts/components/character customization/customization_selection.gd"

const MOD_ID := "cosmeticsMod"

const REFRESH_CUSTOM_COSMETICS_KEY := KEY_R
const PAGE_HOME_KEY := KEY_W
const PAGE_UP_KEY := KEY_Q
const PAGE_DOWN_KEY := KEY_A
const EDIT_MODE_KEY := KEY_E

var current_page := 1
var total_pages := 1

const VANILLA_COSMETICS: Array[String] = [
	"beer_hat",
	"cap_blade",
	"sunglasses",
	"reading_glasses",
	"tophat",
	"traffic_cone",
	"maska_helmet",
	"drill_sgt_hat",
	"hard_hat",
]

enum NavigationDirection {
	HOME,
	UP,
	DOWN,
	REFRESH_CURRENT,
}

var is_in_edit_mode: bool = false

# animation of the camera flying around the character
@onready var silly_ahh_camera_animation: AnimationPlayer = cam_parent.get_node("anim_camera movement")

# camera look_at pivot: a bit under the hat bone
@onready var pivot: Vector3 = customization_assigner.bone_attachment_hat.global_position + Vector3(0, -0.25, 0)

const MOUSE_SENSITIVITY := 0.005
var is_dragging_camera := false

const EDITOR_CAMERA_ZOOM_STEP := 0.5
const EDITOR_CAMERA_DEFAULT_ZOOM := 1.2
const EDITOR_CAMERA_MIN_ZOOM := 0.5
const EDITOR_CAMERA_MAX_ZOOM := 2.5
const EDITOR_CAMERA_MIN_PITCH := -75.0
const EDITOR_CAMERA_MAX_PITCH := 75.0

# starting offset of the camera when entering edit mode
@onready var editor_camera_start_offset: Vector3 = cam_parent.global_position - pivot


func _ready() -> void:
	super._ready()

	print("\ncustomization selection override active")

	customization_hovered("") # sets the "KL_RUID" to be "--" when first entering the cosmetics menu
	refresh_cosmetics_grid(NavigationDirection.HOME)


func _input(event: InputEvent) -> void:
	if (is_in_edit_mode):
		_handle_camera_rotation_and_zoom(event)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey && event.pressed && !event.echo):
		if (event.keycode == EDIT_MODE_KEY):
			_handle_toggling_edit_mode()

		# special case for refreshing the cosmetic while in edit mode (well, it also goes through outside of edit mode)
		if (event.keycode == REFRESH_CUSTOM_COSMETICS_KEY):
			customization_assigner.refresh_custom_cosmetics_on_head_bones()

		if (!is_in_edit_mode):
			_handle_page_navigation(event)

		# get_viewport().set_input_as_handled()
		return


func _handle_toggling_edit_mode():
	if (is_in_edit_mode):
		exit_edit_mode()
	else:
		enter_edit_mode()
	is_in_edit_mode = !is_in_edit_mode


"""

edit mode camera stuff

"""

var last_mouse_position := Vector2.ZERO


func _handle_camera_rotation_and_zoom(event: InputEvent):
	if (event is InputEventMouseButton):
		# if starting to hold down the left button; start dragging camera
		if (event.button_index == MOUSE_BUTTON_LEFT):
			is_dragging_camera = event.pressed
			last_mouse_position = event.position
		# if scrolling; zoom the camera in/out
		elif (event.button_index == MOUSE_BUTTON_WHEEL_UP && event.pressed):
			zoom_camera(-1.0)
		elif (event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.pressed):
			zoom_camera(1.0)
	# if dragging the camera; rotate the camera around the pivot
	elif (event is InputEventMouseMotion && is_dragging_camera):
		var mouse_event := event as InputEventMouseMotion
		rotate_camera_around_pivot(mouse_event.position - last_mouse_position as Vector2)
		last_mouse_position = mouse_event.position


func zoom_camera(direction: float) -> void:
	var offset := cam_parent.global_position - pivot

	cam_parent.global_position = pivot + offset.normalized() * clamp(
		offset.length() + direction * EDITOR_CAMERA_ZOOM_STEP,
		EDITOR_CAMERA_MIN_ZOOM,
		EDITOR_CAMERA_MAX_ZOOM,
	)

	cam_parent.look_at(pivot, Vector3.UP)


# holy shit i dont even know how to begin to dissect this one... sry homie (its me, im homie)
func rotate_camera_around_pivot(delta: Vector2) -> void:
	# Horizontal orbit around the world Y axis.
	var offset := (cam_parent.global_position - pivot).rotated(Vector3.UP, -delta.x * MOUSE_SENSITIVITY)

	# Vertical orbit with pitch limits.
	var horizontal_length := Vector2(offset.x, offset.z).length()
	var current_pitch := rad_to_deg(atan2(offset.y, horizontal_length))

	var new_pitch := clamp(current_pitch + delta.y * MOUSE_SENSITIVITY * 180.0 / PI, EDITOR_CAMERA_MIN_PITCH, EDITOR_CAMERA_MAX_PITCH)

	var right := Vector3.UP.cross(offset).normalized()

	if right.length_squared() > 0.001:
		var pitch_change := deg_to_rad(new_pitch - current_pitch)
		offset = offset.rotated(right, -pitch_change)

	cam_parent.global_position = pivot + offset
	cam_parent.look_at(pivot, Vector3.UP)


# hide item grid, pause camera animation and set the camera to the default editor position
func enter_edit_mode() -> void:
	print("entering cosmetic edit mode")
	_hide_all_slots()
	silly_ahh_camera_animation.pause()
	set_edit_camera_to_default_position()


# enable item grid again and continue camera animation
func exit_edit_mode() -> void:
	print("exiting cosmetic edit mode")
	refresh_cosmetics_grid(NavigationDirection.REFRESH_CURRENT)
	silly_ahh_camera_animation.play("move", 0.0, 1.0, false)


func set_edit_camera_to_default_position() -> void:
	cam_parent.global_position = pivot + editor_camera_start_offset.normalized() * EDITOR_CAMERA_DEFAULT_ZOOM
	cam_parent.look_at(pivot, Vector3.UP)


"""

the cosmetics grid + page navigation

"""


func _handle_page_navigation(event: InputEvent):
	if (event.keycode == PAGE_HOME_KEY):
		refresh_cosmetics_grid(NavigationDirection.HOME)
	if (event.keycode == PAGE_UP_KEY):
		refresh_cosmetics_grid(NavigationDirection.UP)
	if (event.keycode == PAGE_DOWN_KEY):
		refresh_cosmetics_grid(NavigationDirection.DOWN)
	if (event.keycode == REFRESH_CUSTOM_COSMETICS_KEY):
		refresh_cosmetics_grid(NavigationDirection.REFRESH_CURRENT)


func refresh_cosmetics_grid(direction: NavigationDirection) -> void:
	var grid_items: Array = customization_assigner.custom_cosmetics.duplicate()
	grid_items.append({ "id": "rubiks_cube", "type": "hat" })

	# page 1 is vanilla, other pages are custom + rubiks
	total_pages = 1 + ceili(grid_items.size() / 9.0)

	match direction:
		NavigationDirection.HOME:
			current_page = 1
		NavigationDirection.UP:
			current_page += 1
			if current_page > total_pages:
				current_page = 1
		NavigationDirection.DOWN:
			current_page -= 1
			if current_page < 1:
				current_page = total_pages
		NavigationDirection.REFRESH_CURRENT:
			pass

	# prevents the current page from being outside the valid range after a refresh (value, min, max)
	current_page = clampi(current_page, 1, total_pages)

	print("refreshing cosmetics grid, page ", current_page, "/", total_pages)

	_hide_all_slots()

	if current_page == 1:
		_restore_vanilla_grid()
		print("items: vanilla")
		return

	var start_index: int = (current_page - 2) * 9
	var debug_items: Array[String] = []

	for i in range(9):
		var item_index: int = start_index + i

		if item_index < grid_items.size():
			debug_items.append(grid_items[item_index].id)
			_assign_slot_item(i, grid_items[item_index], false)

	print("items: " + ", ".join(debug_items))


func _hide_all_slots():
	for i in range(9):
		selection_rect_array[i].get_parent().hide()


func _restore_vanilla_grid() -> void:
	for i in range(9):
		_assign_slot_item(i, { "id": VANILLA_COSMETICS[i] }, true)


# assigns cosmetic to grid slot
func _assign_slot_item(slot_index: int, cosmetic_dictionary: Dictionary, is_vanilla: bool):
	var preview: Customization_SelectionInstance = cosmetic_selection_parent.get_child(slot_index)

	# setup_cosmetic(): hides every but the selected model
	# if vanilla, just give it the id
	if (is_vanilla && slot_index < VANILLA_COSMETICS.size()):
		preview.setup_cosmetic(VANILLA_COSMETICS[slot_index])
	# if custom, add the 3d model to the slot first, then setup id
	else:
		customization_assigner.add_cosmetic_to_node3d(cosmetic_dictionary, preview.cosmetic_holder_parent)
		preview.setup_cosmetic(cosmetic_dictionary.id)

	# set up spinny model and slot visibility
	selection_rect_array[slot_index].texture = preview.assigned_viewport.get_texture()
	selection_rect_array[slot_index].get_parent().show()

	# assign the id
	selection_rect_array[slot_index] \
			.get_parent() \
			.get_node("customization selection branch") \
			.assigned_cosmetic = cosmetic_dictionary.id


"""

selecting cosmetics

"""


# when pressing an item in the grid. equips/un-equips cosmetics, handles glasses compatibility
func select_cosmetic(cosmetic_name: String) -> void:
	var cosmetic_type := _get_cosmetic_type(cosmetic_name)

	# de-selecting a cosmetic
	match cosmetic_type:
		"hat":
			if cosmetic_name == Globals.active_cosmetic_hat:
				deselect_hat()
				return
		"glasses":
			if cosmetic_name == Globals.active_cosmetic_glasses:
				deselect_glasses()
				return

	# equipping the selected cosmetic and handling glasses compatibility
	match cosmetic_type:
		"hat":
			if (Globals.active_cosmetic_glasses != "" && !is_compatible_with_glasses(cosmetic_name)):
				deselect_glasses()

			customization_assigner.assign_hat(cosmetic_name)
			Globals.active_cosmetic_hat = cosmetic_name
		"glasses":
			if (!is_compatible_with_glasses(Globals.active_cosmetic_hat)):
				deselect_hat()

			customization_assigner.assign_glasses(cosmetic_name)
			Globals.active_cosmetic_glasses = cosmetic_name


func deselect_hat():
	customization_assigner.remove_hat()
	Globals.active_cosmetic_hat = ""


func deselect_glasses():
	customization_assigner.remove_glasses()
	Globals.active_cosmetic_glasses = ""


func _get_cosmetic_type(cosmetic_id: String) -> String:
	# custom cosmetics
	for cosmetic in customization_assigner.custom_cosmetics:
		if (cosmetic.id == cosmetic_id):
			return cosmetic.type

	# vanilla cosmetics
	if cosmetic_id in ["beer_hat", "cap_blade", "tophat", "traffic_cone", "maska_helmet", "drill_sgt_hat", "hard_hat", "rubiks_cube"]:
		return "hat"
	if (cosmetic_id in ["sunglasses", "reading_glasses"]):
		return "glasses"

	# fallback.... idfk how it would get to this point, but like... Let's
	return "hat"


func is_compatible_with_glasses(cosmetic_name: String) -> bool:
	# custom: get compatibility info from dictionary by name
	for cosmetic in customization_assigner.custom_cosmetics:
		if (cosmetic.id == cosmetic_name):
			return cosmetic.compatible_with_glasses # is set when first discovering the cosmetic

	# vanilla: replicate vanilla rules
	match cosmetic_name:
		"beer_hat", "cap_blade", "tophat", "traffic_cone", "hard_hat", "drill_sgt_hat", "sunglasses", "reading_glasses":
			return true
		"rubiks_cube", "maska_helmet":
			return false
		"":
			return true

	# always remember, True...
	return true


"""

misc

"""


func get_gibberish_name(cosmetic_id: String) -> String:
	# custom cosmetics
	for cosmetic in customization_assigner.custom_cosmetics:
		if (cosmetic.id == cosmetic_id):
			return cosmetic.gibberish_name

	# special case for rubiks_cube
	if (cosmetic_id == "rubiks_cube"):
		return "0010ERR"

	# vanilla cosmetics
	return super.get_gibberish_name(cosmetic_id)
