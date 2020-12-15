InitTitleScreen::
	call ClearBGPalettes
	call ClearSprites
	farcall ClearSpriteAnims
	call ClearTileMap

; Turn BG Map update off
	xor a
	ldh [hBGMapMode], a

; Reset timing variables
	ld hl, wJumptableIndex
	ld [hli], a ; wJumptableIndex
	ld [hli], a ; wIntroSceneFrameCounter
	ld [hli], a ; wTitleScreenTimer
	ld [hl], a  ; wTitleScreenTimer + 1

; Turn LCD off
	call DisableLCD


; title screen GFX
	ld hl, G98T
	ld de, vTiles1
	call Decompress

; copy hooh
	ld hl, TitleHoohGFX
	ld de, vTiles0
	call Decompress

; copy map
	debgcoord 0, 0
	ld hl, G98M
	ld bc, G98M_End - G98M
	call CopyBytes

	ld a, 1
	ldh [rVBK], a
; copy map
	debgcoord 0, 0
	ld hl, G98M_A
	ld bc, G98M_A_End - G98M_A
	call CopyBytes

; Restore WRAM bank
	xor a
	ldh [rVBK], a

; Save WRAM bank
	ldh a, [rSVBK]
	push af
; WRAM bank 5
	ld a, BANK(wBGPals1)
	ldh [rSVBK], a

; Update palette colors
	ld hl, TitleScreenPalettes
	ld de, wBGPals2
	ld bc, 7 palettes
	call CopyBytes

	ld hl, TitleScreenPalettes palette 5
	ld de, wOBPals2
	ld bc, 1 palettes
	call CopyBytes

; Restore WRAM bank
	pop af
	ldh [rSVBK], a

; Reset audio
	call ChannelsOff

	call EnableLCD
	ld hl, rLCDC
	set rLCDC_SPRITE_SIZE, [hl] ; 8x8

	ld a, $1
	ldh [hCGBPalUpdate], a

	ld a, LOW(rSCX)
	ld [hLCDCPointer], a

; Update BG Map 0 (bank 0)
	;ldh [hBGMapMode], a

	ld de, $7058
	ld a, SPRITE_ANIM_INDEX_GS_INTRO_HO_OH
	call _InitSpriteAnimStruct

	ld de, MUSIC_TITLE
	call PlayMusic

	ret

DrawTitleGraphic:
; input:
;   hl: draw location
;   b: height
;   c: width
;   d: tile to start drawing from
;   e: number of tiles to advance for each bgrows
.bgrows
	push de
	push bc
	push hl
.col
	ld a, d
	ld [hli], a
	inc d
	dec c
	jr nz, .col
	pop hl
	ld bc, SCREEN_WIDTH
	add hl, bc
	pop bc
	pop de
	ld a, e
	add d
	ld d, a
	dec b
	jr nz, .bgrows
	ret

RunTitleScreen::
	call ScrollTitleScreenClouds	; new

	ld a, [wJumptableIndex]
	bit 7, a
	jr nz, .done_title
	call TitleScreenScene

	farcall PlaySpriteAnimations

	call DelayFrame
	and a
	ret

.done_title
	scf
	ret

ScrollTitleScreenClouds:
	ldh a, [hVBlankCounter]
	and $7
	ret nz
	ld hl, wLYOverrides + $5f
	ld a, [hl]
	dec a
	ld bc, $28
	call ByteFill
	ret

TitleScreenScene:
	ld e, a
	ld d, 0
	ld hl, .scenes
	add hl, de
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.scenes
	dw TitleScreenTimer
	dw TitleScreenMain
	dw TitleScreenEnd

TitleScreenTimer:
; Next scene
	ld hl, wJumptableIndex
	inc [hl]

; Start a timer
	ld hl, wTitleScreenTimer
	ld de, 73 * 60 + 36
	ld [hl], e
	inc hl
	ld [hl], d
	ret

TitleScreenMain:
; Run the timer down.
	ld hl, wTitleScreenTimer
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, e
	or d
	jr z, .end

	dec de
	ld [hl], d
	dec hl
	ld [hl], e

; Save data can be deleted by pressing Up + B + Select.
	call GetJoypad
	ld hl, hJoyDown
	ld a, [hl]
	and D_UP + B_BUTTON + SELECT
	cp  D_UP + B_BUTTON + SELECT
	jr z, .delete_save_data

; To bring up the clock reset dialog:

; Hold Down + B + Select to initiate the sequence.
	ldh a, [hClockResetTrigger]
	cp $34
	jr z, .check_clock_reset

	ld a, [hl]
	and D_DOWN + B_BUTTON + SELECT
	cp  D_DOWN + B_BUTTON + SELECT
	jr nz, .check_start

	ld a, $34
	ldh [hClockResetTrigger], a
	jr .check_start

; Keep Select pressed, and hold Left + Up.
; Then let go of Select.
.check_clock_reset
	bit SELECT_F, [hl]
	jr nz, .check_start

	xor a
	ldh [hClockResetTrigger], a

	ld a, [hl]
	and D_LEFT + D_UP
	cp  D_LEFT + D_UP
	jr z, .clock_reset

; Press Start or A to start the game.
.check_start
	ld a, [hl]
	and START | A_BUTTON
	jr nz, .incave
	ret

.incave
	ld a, 0
	jr .done

.delete_save_data
	ld a, 1

.done
	ld [wIntroSceneFrameCounter], a

; Return to the intro sequence.
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

.end
; Next scene
	ld hl, wJumptableIndex
	inc [hl]

; Fade out the title screen music
	xor a
	ld [wMusicFadeID], a
	ld [wMusicFadeID + 1], a
	ld hl, wMusicFade
	ld [hl], 8 ; 1 second

	ld hl, wTitleScreenTimer
	inc [hl]
	ret

.clock_reset
	ld a, 4
	ld [wIntroSceneFrameCounter], a

; Return to the intro sequence.
	ld hl, wJumptableIndex
	set 7, [hl]
	ret

TitleScreenEnd:
; Wait until the music is done fading.

	ld hl, wTitleScreenTimer
	inc [hl]

	ld a, [wMusicFade]
	and a
	ret nz

	ld a, 2
	ld [wIntroSceneFrameCounter], a

; Back to the intro.
	ld hl, wJumptableIndex
	set 7, [hl]
	ret


G98T:
INCBIN "gfx/title/98/gold98title.2bpp.lz"

G98M:
INCBIN "gfx/title/98/g98title_english.tilemap"
G98M_End:

G98M_A:
INCBIN "gfx/title/98/g98title_english.attrmap"
G98M_A_End:

TitleHoohGFX:
INCLUDE "gfx/title/98/HOUOUOBJ.DAT"

TitleScreenPalettes:
INCLUDE "gfx/title/title.pal"
