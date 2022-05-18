SproutTower7F_MapScripts:
	db 0 ; scene scripts

	db 0 ; callbacks

; scripts here

SproutTower7F_MapEvents:
	db 0, 0 ; filler

	db 9 ; warp events
	warp_event  1, 11, SPROUT_TOWER_6F, 5
	warp_event 13,  3, SPROUT_TOWER_6F, 6
	warp_event 19,  7, SPROUT_TOWER_6F, 7
	warp_event 19, 13, SPROUT_TOWER_6F, 8

	warp_event  3,  3, SPROUT_TOWER_8F, 1
	warp_event  7,  3, SPROUT_TOWER_8F, 2
	warp_event  7, 17, SPROUT_TOWER_8F, 3
	warp_event 13, 17, SPROUT_TOWER_8F, 4
	warp_event 19,  3, SPROUT_TOWER_8F, 5

	db 0 ; coord events

	db 0 ; bg events

	db 0 ; object events
