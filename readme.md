# Machine Party custom cosmetics mod
this mod provides the means to add custom cosmetics to the hit game™ machine party.
it works in online multiplayer, as long as everyone has the mod and the same cosmetics available
	* "same cosmetics available" as in, you obviously won't see other people's cosmetics unless you have these same cosmetics present in your mod. you do not need to have a 100% matching cosmetics list
see section "known bugs" below for the current limitations of the mod!
	* tldr; visual bug in online lobby, cosmetics work correctly inside minigames. local lobby unable to be started

# LLM AI usage disclaimer
i have utilised the free ChatGPT model GPT-5.6 Luna in the creation of this mod for the purposes of learning how to mod a godot engine game and for general assistance with code (especially since i am no python/gdscript expert). all of the generated code has been revised and/or modified by me, some of the code has been written from scratch by me.
this readme was written by me also.

# mod loader
this mod is made to work with the following modloader, which you will need to get first before being able to use this mod:
https://github.com/Krunk-theduck/MachinePartyModLoader/

# adding new cosmetics
to add a custom cosmetic into the game, put the model (.glb format) and a .json describing the cosmetic into the cosmetics folder (cosmeticsMod/assets/cosmetics)

.json example:
cool_hat.json:
```json
{
	"type": "hat",
	"display_name": "Very Cool Hat",
	"gibberish_name": "0020069",
	"transform_values": {
		"position": [
			0.0,
			0.0,
			0.0
		],
		"rotation_degrees": [
			0.0,
			0.0,
			0.0
		],
		"scale": [
			1.0,
			1.0,
			1.0
		]
	}
}
```

cool_hat - internal id of the cosmetic
"type" (string) - can be either "hat" or "glasses"
"display_name" (string) - for displaying the name of the cosmetic in menus and stuff instead of the id
"gibberish_name" (string) - displayed in the cosmetic selection menu when you hover/select the cosmetic
					* 00200xx is my suggested custom cosmetic gibberish naming convention, but you can make it any string you like. just bear in mind the location it is displayed in.
"transform_values" - self explanatory. these get applied directly to the model ingame.
					- can contain "position", "rotation_degrees" and "scale". these can be either a single number (int or float) (for example - "scale": 1) or an array of up to 3 numbers, corresponding to the x, y and z coordinates of the transform.
					* (not yet implemented) you can use the editor in the cosmetics menu to adjust the cosmetic's transform values

the .json can be missing any of the fields. this will result in default values being assigned for the missing fields:
	"type": "hat"
	"display_name": the cosmetic's id
	"gibberish_name": default gibberish value
	"transform_values": Vector3.ZERO for "position" and "rotation_degrees" and Vector3.ONE for "scale"
		* "transform_values" will not be defaulted right away when loading the cosmetic, instead later, when attempting to apply the transforms

-----

the mod will also search for cosmetics in folders within the root cosmetics folder. the folder path to the cosmetic will be appended before the cosmetic's id to avoid common duplicate ids.

example setup:
cosmeticsMod/assets/cosmetics/
├── cool_hat.json
├── cool_hat.glb
├── cool/
│   ├── hat.json
│   └── hat.glb
├── epic/
│   ├── hat.json
│   └── hat.glb
└── hats/
    └── silly/
        ├── banana.json
        └── banana.glb

this would result in cosmetics:
	cool_hat (from cosmetics root)
	cool_hat (from cosmetics/cool)
	epic_hat (from cosmetics/epic)
	hats_silly_banana (from cosmetics/hats/silly)

as you can see, there are now two cosmetics with the same id (cool_hat). this will produce a warning, and only the cosmetic that's the "least deep" within the cosmetics folder will be loaded, so cool_hat (from cosmetics root) stays, while cool_hat (from cosmetics/cool) will be discarded

# navigating the new cosmetics menu
there is no clickable ui, YET
for now, you can switch pages by pressing "Q" or "E" to navigate left and right
you can also press "R" to reload the available cosmetics (see section "known bugs" for a minor bug with the reload)

# known bugs
there are known bugs in both online and local lobbies/waiting rooms:
	online lobby: everyone will be wearing the same outfit, dictated by each client's selected cosmetics. this is only the case inside the lobby, and the cosmetics are displayed correctly inside minigames (or at least they should be - i did not test every minigame (yet))
	local lobby: for some reason unknown and very mysterious to me, the name and cosmetics selection in the local lobby is skipped completely, and the game cannot be started at all. remove this mod if you wish to play local
minor bug when hot-reloading cosmetics inside the cosmetics menu
	it like replaces the grid but incorrectly or idfk. leaving and re-entering the menu fixes it

# to do list
TODO: cosmetics menu UI
TODO: implement cosmetic transform editor
TODO: add in-game debug messages for cosmetics errors
TODO: fix online lobby cosmetics bug
TODO: fix local lobby being unplayable
TODO: fix hot-reloading cosmetics inside the cosmetics menu
TODO: allow the vanilla rubiks_cube hat to be set from the cosmetics menu