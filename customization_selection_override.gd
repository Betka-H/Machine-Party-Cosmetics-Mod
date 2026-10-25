extends "res://scripts/components/character customization/customization_selection.gd"

const MOD_ID := "cosmeticsMod"

const REFRESH_CUSTOM_COSMETICS_KEY := KEY_R
const PAGE_UP_KEY := KEY_E
const PAGE_DOWN_KEY := KEY_Q

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

var current_page := 0
var total_pages := 1


func _ready() -> void:
	super._ready()
	print("\ncustomization selection override script ready")


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey && event.pressed && !event.echo):
		#print(OS.get_keycode_string(event.keycode) + " is pressed")
		if (event.keycode == PAGE_UP_KEY):
			refresh_cosmetics_grid(true)
		if (event.keycode == PAGE_DOWN_KEY):
			refresh_cosmetics_grid(false)
		if (event.keycode == REFRESH_CUSTOM_COSMETICS_KEY):
			customization_assigner.refresh_custom_cosmetics()
			customization_assigner.print_custom_cosmetics()
			_restore_vanilla_grid()

		# get_viewport().set_input_as_handled()
		return


func refresh_cosmetics_grid(up: bool) -> void:
	# Page 0 is the vanilla page; remaining pages contain custom cosmetics.
	total_pages = 1 + ceili(customization_assigner.custom_cosmetics.size() / 9.0)

	if up:
		current_page += 1
		if current_page >= total_pages:
			current_page = 0
	else:
		current_page -= 1
		if current_page < 0:
			current_page = total_pages - 1

	print("refreshing cosmetics grid, page ", current_page, "/", total_pages)

	if current_page == 0:
		_restore_vanilla_grid()
		return

	_clear_all_slots()

	var start_index: int = (current_page - 1) * 9

	for i in range(9):
		var item_index: int = start_index + i

		if item_index < customization_assigner.custom_cosmetics.size():
			print("placing item ", item_index)
			_assign_slot_item(i, customization_assigner.custom_cosmetics[item_index], false)


func _restore_vanilla_grid() -> void:
	print("restoring vanilla cosmetics grid")

	for i in range(9):
		_assign_slot_item(i, { "id": VANILLA_COSMETICS[i] }, true)


func select_cosmetic(cosmetic_name: String) -> void:
	var cosmetic_type := _get_cosmetic_type(cosmetic_name)

	if cosmetic_type == "":
		push_warning("Unknown cosmetic type: " + cosmetic_name)
		return

	# Clicking the currently equipped cosmetic toggles it off.
	if cosmetic_type == "glasses":
		if cosmetic_name == Globals.active_cosmetic_glasses:
			customization_assigner.remove_glasses()
			Globals.active_cosmetic_glasses = ""
			return
	elif cosmetic_type == "hat":
		if cosmetic_name == Globals.active_cosmetic_hat:
			customization_assigner.remove_hat()
			Globals.active_cosmetic_hat = ""
			return

	# Equip the selected cosmetic.
	if cosmetic_type == "glasses":
		if not is_compatible_with_glasses(Globals.active_cosmetic_hat):
			return

		customization_assigner.assign_glasses(cosmetic_name)
		Globals.active_cosmetic_glasses = cosmetic_name

	elif cosmetic_type == "hat":
		customization_assigner.assign_hat(cosmetic_name)
		Globals.active_cosmetic_hat = cosmetic_name

		if not is_compatible_with_glasses(cosmetic_name):
			customization_assigner.remove_glasses()
			Globals.active_cosmetic_glasses = ""


func is_compatible_with_glasses(cosmetic_name_to_check) -> bool:
	if cosmetic_name_to_check == null:
		return false

	# Find custom cosmetic metadata first.
	for cosmetic in customization_assigner.custom_cosmetics:
		if cosmetic["id"] == cosmetic_name_to_check:
			return bool(cosmetic.get("compatible_with_glasses", true))

	# Preserve vanilla compatibility rules.
	match cosmetic_name_to_check:
		"":
			return true
		"beer_hat", "cap_blade", "sunglasses", "reading_glasses":
			return true
		"rubiks_cube", "maska_helmet":
			return false
		"tophat", "traffic_cone", "hard_hat", "drill_sgt_hat":
			return true

	# Unknown cosmetics default to compatible.
	return true


func _get_cosmetic_type(cosmetic_id: String) -> String:
	# Look up custom cosmetics using their metadata.
	for cosmetic in customization_assigner.custom_cosmetics:
		if cosmetic["id"] == cosmetic_id:
			return str(cosmetic.get("type", ""))

	# Handle vanilla cosmetics.
	if cosmetic_id in ["sunglasses", "reading_glasses"]:
		return "glasses"

	if cosmetic_id in [
		"beer_hat",
		"cap_blade",
		"tophat",
		"traffic_cone",
		"maska_helmet",
		"drill_sgt_hat",
		"hard_hat",
	]:
		return "hat"

	return ""


func _clear_all_slots():
	print("clearing cosmetics grid")
	for i in range(9):
		selection_rect_array[i].get_parent().hide()


func _assign_slot_item(slot: int, cosmetic: Dictionary, is_vanilla: bool):
	if (cosmetic.id == ""):
		print("emptying slot ", slot)
	else:
		print("assigning item " + cosmetic.id + " to slot ", slot)
	var preview: Customization_SelectionInstance = cosmetic_selection_parent.get_child(slot)
	if (is_vanilla):
		preview.setup_cosmetic(VANILLA_COSMETICS[slot])
	else:
		customization_assigner.add_custom_model(preview.cosmetic_holder_parent, cosmetic)
		preview.setup_cosmetic(cosmetic.id)
	selection_rect_array[slot].texture = preview.assigned_viewport.get_texture()
	selection_rect_array[slot].get_parent().show()

	selection_rect_array[slot] \
			.get_parent() \
			.get_node("customization selection branch") \
			.assigned_cosmetic = cosmetic.id


func get_gibberish_name(_str: String):
	for cosmetic in customization_assigner.custom_cosmetics:
		if (cosmetic.id == _str):
			return cosmetic.gibberish_name

	match _str:
		"none":
			return "none"
		"beer_hat":
			return "0010043"
		"cap_blade":
			return "0010045"
		"sunglasses":
			return "0010046"
		"reading_glasses":
			return "0010047"
		"tophat":
			return "0010048"
		"traffic_cone":
			return "0010049"
		"maska_helmet":
			return "0010050"
		"drill_sgt_hat":
			return "0010051"
		"hard_hat":
			return "0010052"
		"red":
			return "0010053"
		"blue":
			return "0010054"
		"green":
			return "0010055"
		"yellow":
			return "0010056"
		"purple":
			return "0010057"
	return "--"
