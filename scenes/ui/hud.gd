class_name RaceHUD
extends CanvasLayer
## HUD-ul cursei: info (viteza/pozitie/tur/timpi), countdown, mesaje, bara
## de drift CTR, controalele touch si meniul de pauza cu setari. Construit
## in cod (placeholder pana la un design real, ca in racing 2D).

signal restart_requested
## Repunerea pe pista, cerut de jucator. Repornirea cursei e alt semnal:
## RESTART arunca tot turul, asta doar te scoate din nisip.
signal respawn_requested
signal menu_requested
signal results_primary # butonul principal din panoul de rezultate

var _info: Label
var _countdown: Label
var _message: Label
var _charge_bg: ColorRect
var _charge_fill: ColorRect
var _touch: TouchControls
var _pause_button: Button
var _respawn_button: Button
var _pause_panel: PanelContainer
var _settings: SettingsPanel
var _results_panel: PanelContainer
var _results_box: VBoxContainer
var _minimap: Minimap
## Voalul alb al rafalelor de abur (fumarolele de pe Stromboli). Sta SUB text
## si sub butoane: aburul iti ia vederea la drum, nu si HUD-ul — un jucator
## care nu-si mai vede pozitia sau bara de turbo ar citi asta ca bug, nu ca
## hazard.
var _blind_veil: ColorRect

func _ready() -> void:
	# ALWAYS: HUD-ul functioneaza si cu jocul pe pauza.
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_touch = TouchControls.new()
	root.add_child(_touch)

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(56, 56)
	_pause_button.add_theme_font_size_override("font_size", 22)
	_pause_button.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_pause_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pause_button.pressed.connect(_open_pause)
	root.add_child(_pause_button)

	_build_pause_panel(root)
	_build_results_panel(root)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.back_pressed.connect(func() -> void:
		_settings.visible = false
		_pause_panel.visible = true)
	root.add_child(_settings)

	_info = _make_label(24)
	_info.position = Vector2(20, 14)
	root.add_child(_info)

	# Minimapa sub butonul de pauza (dreapta-sus); populata de Race.
	_minimap = Minimap.new()
	_minimap.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_minimap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_minimap.position += Vector2(0, 76)
	root.add_child(_minimap)

	# Sub minimapa. Marginea din dreapta e singura zona libera: colturile de jos
	# sunt zonele de DRIFT si TURBO (raza de atingere 84 si 92 px), stanga-sus e
	# eticheta de informatii, iar centrul-jos e bara de turbo. Butonul se termina
	# la y=306, iar zona TURBO incepe la 498 — 192 px de margine.
	#
	# Un Button real cu mouse_filter STOP consuma evenimentul inaintea lui
	# TouchControls, deci nu mai vireaza in acelasi timp. Butonul de pauza
	# demonstreaza deja ca merge.
	_respawn_button = _make_button("REPUNE")
	_respawn_button.custom_minimum_size = Vector2(Minimap.MAP_SIZE, 52)
	_respawn_button.add_theme_font_size_override("font_size", 20)
	_respawn_button.set_anchors_and_offsets_preset(
		Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_respawn_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_respawn_button.position += Vector2(0, 76.0 + Minimap.MAP_SIZE + 12.0)
	_respawn_button.pressed.connect(func() -> void: respawn_requested.emit())
	root.add_child(_respawn_button)

	# Voalul de abur. Adaugat INAINTE de countdown/mesaje ca sa ramana sub ele.
	_blind_veil = ColorRect.new()
	_blind_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blind_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Alb usor albastrui: abur, nu blitz. Alfa pornit de la zero — se ridica
	# doar cat tine rafala.
	_blind_veil.color = Color(0.94, 0.96, 0.98, 1.0)
	_blind_veil.modulate.a = 0.0
	root.add_child(_blind_veil)

	_countdown = _make_label(110)
	_countdown.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_countdown.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_countdown.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(_countdown)

	_message = _make_label(38)
	_message.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.grow_vertical = Control.GROW_DIRECTION_BOTH
	_message.position += Vector2(0, 100)
	_message.modulate.a = 0.0
	root.add_child(_message)

	# Bara de TURBO (model Ignition): mereu vizibila, se umple din mers
	# (mai repede in drift); o arzi cand vrei tu cu butonul de turbo.
	_charge_bg = ColorRect.new()
	_charge_bg.custom_minimum_size = Vector2(260, 20)
	_charge_bg.color = Color(0, 0, 0, 0.45)
	_charge_bg.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 44)
	_charge_bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_charge_bg.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_charge_bg)
	_charge_fill = ColorRect.new()
	_charge_fill.position = Vector2(3, 3)
	_charge_fill.size = Vector2(0, 14)
	_charge_bg.add_child(_charge_fill)

func _build_pause_panel(root: Control) -> void:
	_pause_panel = PanelContainer.new()
	_pause_panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_panel.visible = false
	root.add_child(_pause_panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	_pause_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := _make_label(38)
	title.text = "PAUZA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var resume := _make_button("CONTINUA")
	resume.pressed.connect(_close_pause)
	box.add_child(resume)
	var settings := _make_button("SETARI")
	settings.pressed.connect(func() -> void:
		_pause_panel.visible = false
		_settings.visible = true)
	box.add_child(settings)
	var restart := _make_button("RESTART")
	restart.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit())
	box.add_child(restart)
	var menu := _make_button("MENIU")
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		menu_requested.emit())
	box.add_child(menu)

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 60)
	button.add_theme_font_size_override("font_size", 24)
	return button

func _build_results_panel(root: Control) -> void:
	_results_panel = PanelContainer.new()
	_results_panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_results_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_results_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_results_panel.visible = false
	root.add_child(_results_panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	_results_panel.add_child(margin)
	_results_box = VBoxContainer.new()
	_results_box.add_theme_constant_override("separation", 10)
	margin.add_child(_results_box)

## rows: {name, color, right, is_player} in ordinea afisarii.
func show_results(title: String, rows: Array[Dictionary], primary_label: String) -> void:
	for child in _results_box.get_children():
		child.free()
	var title_label := _make_label(34)
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_box.add_child(title_label)
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(24, 24)
		swatch.color = row.color
		line.add_child(swatch)
		var name_label := _make_label(24)
		name_label.text = str(row.name)
		if bool(row.is_player):
			name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		name_label.custom_minimum_size = Vector2(260, 0)
		line.add_child(name_label)
		var right_label := _make_label(24)
		right_label.text = str(row.right)
		line.add_child(right_label)
		_results_box.add_child(line)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_results_box.add_child(buttons)
	var primary := _make_button(primary_label)
	primary.pressed.connect(func() -> void:
		_results_panel.visible = false
		results_primary.emit())
	buttons.add_child(primary)
	var menu := _make_button("MENIU")
	menu.pressed.connect(func() -> void: menu_requested.emit())
	buttons.add_child(menu)
	_results_panel.visible = true
	_pause_button.visible = false
	_respawn_button.visible = false
	_touch.visible = false

func _open_pause() -> void:
	if _results_panel.visible:
		return
	get_tree().paused = true
	GameState.reset_touch() # altfel virajul "ramane apasat" peste pauza
	_touch.visible = false
	_pause_button.visible = false
	_respawn_button.visible = false
	_pause_panel.visible = true

func _close_pause() -> void:
	get_tree().paused = false
	_touch.visible = true
	_pause_button.visible = true
	_respawn_button.visible = true
	_pause_panel.visible = false
	_settings.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# ESC comuta pauza — util pe desktop in timpul dezvoltarii.
	if event.is_action_pressed("ui_cancel"):
		if _pause_panel.visible or _settings.visible:
			_close_pause()
		elif not _results_panel.visible:
			_open_pause()

func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 7)
	return label

func setup_minimap(track: Track, cars: Array[Car]) -> void:
	_minimap.setup(track, cars)

func set_info(text: String) -> void:
	_info.text = text

func show_countdown(text: String) -> void:
	_countdown.text = text
	_countdown.visible = text != ""

## Dezactiveaza butonul cat timp repunerea n-ar avea efect (cooldown, countdown,
## cursa terminata). Fara asta, apesi si nu se intampla nimic, fara explicatie.
func set_respawn_enabled(enabled: bool) -> void:
	_respawn_button.disabled = not enabled


## Rafala de abur peste parbriz: ecranul se albeste si se limpezeste la loc.
##
## Nu merge la opacitate 1: la alb complet nu se mai vede NIMIC, iar un hazard
## care iti ia complet vederea pe o dreapta de depasire nu mai e teatru, e
## pedeapsa — exact ce nu vrem aici (vezi FumaroleHazard). La ~0.55 vezi
## drumul prin el, dar te sperii.
##
## Urcarea e mai scurta decat coborarea: aburul te ACOPERA brusc si se
## risipeste lin, ca un nor real prin care ai trecut.
const BLIND_PEAK: float = 0.55

func blind_flash(seconds: float) -> void:
	if _blind_veil == null:
		return
	var hold := maxf(seconds, 0.1)
	var tw := create_tween()
	tw.tween_property(_blind_veil, "modulate:a", BLIND_PEAK, 0.12)
	tw.tween_interval(hold * 0.45)
	tw.tween_property(_blind_veil, "modulate:a", 0.0, hold * 0.75)


func flash_message(text: String) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_message, "modulate:a", 0.0, 0.5)

func set_turbo(charge: float, boosting: bool) -> void:
	_charge_fill.size.x = 254.0 * clampf(charge, 0.0, 1.0)
	if boosting:
		_charge_fill.color = Color(1.0, 0.55, 0.1) # arde
	elif charge >= 1.0:
		_charge_fill.color = Color(1.0, 0.9, 0.2)  # plina, gata de foc
	else:
		_charge_fill.color = Color(0.3, 0.8, 0.9)  # se incarca
