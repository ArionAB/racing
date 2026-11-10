class_name TutorialInvite
extends Control
## Invitatia la turul ghidat (#678), peste meniul principal, la prima pornire:
## TEST DRIVE porneste turul, SKIP il marcheaza facut (nu mai intreaba; se
## reia din SETTINGS). Apare o singura data pe sesiune, si numai cat turul n-a
## fost facut sau sarit — un jucator iesit din tur prin MENU nu e intrebat iar
## pana la urmatoarea pornire.

## O data pe sesiune (static: supravietuieste schimbarilor de scena).
static var offered: bool = false

var config: TutorialConfig = TutorialDirector.DEFAULT_CONFIG
var _play: Button
var _skip: Button


## Chemat de MainMenu la sfarsitul lui `_ready`. Intoarce invitatia, sau null.
static func offer_if_needed(menu: Control) -> TutorialInvite:
	if GameState.tutorial_done or offered:
		return null
	offered = true
	var invite := TutorialInvite.new()
	menu.add_child(invite)
	return invite


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Voalul opreste atingerile: meniul de dedesubt nu se apasa prin invitatie.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.0, 0.0, 0.0, 0.6)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var panel := PanelContainer.new()
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 30)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var title := Label.new()
	title.text = config.invite_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)
	var body := Label.new()
	body.text = config.invite_body
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 26)
	body.modulate = Color(1, 1, 1, 0.8)
	box.add_child(body)

	# Ca butoanele meniului: mari, tinte de deget.
	_play = Button.new()
	_play.text = config.invite_play
	_play.custom_minimum_size = Vector2(360, 66)
	_play.add_theme_font_size_override("font_size", 30)
	_play.pressed.connect(_on_play)
	box.add_child(_play)
	_skip = Button.new()
	_skip.text = config.invite_skip
	_skip.custom_minimum_size = Vector2(360, 54)
	_skip.add_theme_font_size_override("font_size", 24)
	_skip.pressed.connect(_on_skip)
	box.add_child(_skip)

	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH


func play_button() -> Button:
	return _play


func skip_button() -> Button:
	return _skip


func _on_play() -> void:
	queue_free()
	TutorialDirector.start()


func _on_skip() -> void:
	GameState.tutorial_done = true
	GameState.save_settings()
	queue_free()
