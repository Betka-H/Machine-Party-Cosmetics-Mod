extends "res://scripts/components/character customization/customization_selection_instance.gd"

const MOD_ID := "cosmeticsMod"


func _ready() -> void:
	super._ready()
	# print("customization selection instance override active")


# hide every cosmetic in the slot except for the assigned cosmetic
func setup_cosmetic(assigned_cosmetic_name: String):
	for child in cosmetic_holder_parent.get_children():
		if child.name == assigned_cosmetic_name:
			child.visible = true
		else:
			child.visible = false
