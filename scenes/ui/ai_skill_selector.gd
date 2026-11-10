class_name AiSkillSelector
extends HBoxContainer
## Selectorul de nivel al adversarilor (issue #682): BRONZE / SILVER / GOLD,
## trei butoane mari, unul apasat. Il folosesc QUICK RACE si WORLD CUP; cariera
## nu (ramane pe profilul implicit — decizia deschisa #676).
##
## Alegerea se scrie in `GameState.ai_level` si se persista in setari imediat,
## ca sa ramana si dupa repornirea jocului. Cursa o citeste abia la pornire
## (`GameState.start_quick_race` / `start_championship`).
##
## Touch-first: butoane de 56 px inaltime (ca BACK si START), fara focus de
## tastatura, ca sa nu fure navigarea cu sageti de pe cartonasele de pista.

## Culoarea fiecarui nivel, ca medaliile.
const LEVEL_COLORS: Array[Color] = [
	Color(0.80, 0.52, 0.28), Color(0.76, 0.80, 0.86), Color(0.96, 0.79, 0.30),
]
## Ce inseamna nivelul, pe un rand, in limba jocului.
const LEVEL_HINTS: Array[String] = [
	"Relaxed rivals: they brake early and make mistakes.",
	"Solid rivals: clean lines, the occasional slip.",
	"Flat out: they use every bit of their car.",
]
const BUTTON_SIZE := Vector2(150, 56)
## Doar pentru sonde: `false` = alegerea nu se scrie in user://settings.cfg
## (setarile reale ale dezvoltatorului, pe masina de lucru).
static var persist: bool = true

var buttons: Array[Button] = []
var _hint: Label


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 12)
	var caption := Label.new()
	caption.text = "RIVALS"
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_color", TrackSelectPanel.SUBTITLE_COLOR)
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(caption)
	var group := ButtonGroup.new()
	for i in AiSkill.LEVEL_NAMES.size():
		var b := _make_button(i, group)
		add_child(b)
		buttons.append(b)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 16)
	_hint.add_theme_color_override("font_color", TrackCard.TEXT_DIM)
	_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint.custom_minimum_size.x = 420
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hint)
	_select(GameState.ai_level, false)
	visibility_changed.connect(func() -> void:
		if visible:
			_select(GameState.ai_level, false))


func _make_button(level: int, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.name = "Level_%s" % AiSkill.LEVEL_NAMES[level]
	b.text = AiSkill.LEVEL_NAMES[level]
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = BUTTON_SIZE
	b.add_theme_font_size_override("font_size", 22)
	var c := LEVEL_COLORS[level]
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.09, 0.12, 0.19)
	normal.border_color = c.darkened(0.45)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = c.darkened(0.15)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = c.darkened(0.55)
	pressed.border_color = c
	pressed.set_border_width_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_color_override("font_color", c.darkened(0.1))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	b.pressed.connect(func() -> void: _select(level, true))
	return b


func _select(level: int, save: bool) -> void:
	level = clampi(level, 0, buttons.size() - 1)
	for i in buttons.size():
		buttons[i].set_pressed_no_signal(i == level)
	_hint.text = LEVEL_HINTS[level]
	if save and GameState.ai_level != level:
		GameState.ai_level = level
		if persist:
			GameState.save_settings()
