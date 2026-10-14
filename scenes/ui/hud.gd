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
## Contorul de performanta (setare `GameState.show_perf`). Sus, centrat, ca
## sa nu se bata cu pozitia/turul (stanga) si cu pauza/minimapa (dreapta).
var _perf: Label
var _perf_clock: float = 0.0
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
## Voalul tranzitiei de repunere (#495): se intuneca cat clipeste masina.
var _recover_veil: ColorRect
var _recover_tween: Tween
## Ceasul de offroad (#497): cifra mare deasupra centrului.
var _offroad_label: Label
## „WRONG WAY" (#499): mare, rosu, pulsand cat timp mergi pe contrasens.
var _wrong_way_label: Label
var _wrong_way_tween: Tween

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
	_respawn_button = _make_button("RESET")
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
	_recover_veil = ColorRect.new()
	_recover_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_recover_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recover_veil.color = Color(0.02, 0.02, 0.04, 1.0)
	_recover_veil.modulate.a = 0.0
	root.add_child(_recover_veil)

	_countdown = _make_label(110)
	_countdown.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_countdown.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_countdown.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(_countdown)

	_offroad_label = _make_label(64)
	_offroad_label.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_offroad_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_offroad_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_offroad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offroad_label.position += Vector2(0, -150)
	_offroad_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	_offroad_label.visible = false
	root.add_child(_offroad_label)
	_wrong_way_label = _make_label(72)
	_wrong_way_label.text = "WRONG WAY"
	_wrong_way_label.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_wrong_way_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_wrong_way_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_wrong_way_label.position += Vector2(0, -60)
	_wrong_way_label.add_theme_color_override("font_color", Color(1.0, 0.22, 0.18))
	_wrong_way_label.visible = false
	root.add_child(_wrong_way_label)

	_message = _make_label(38)
	_message.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.grow_vertical = Control.GROW_DIRECTION_BOTH
	_message.position += Vector2(0, 100)
	_message.modulate.a = 0.0
	root.add_child(_message)

	_perf = _make_label(18)
	_perf.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 10)
	_perf.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_perf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_perf.visible = false
	root.add_child(_perf)

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
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var resume := _make_button("RESUME")
	resume.pressed.connect(_close_pause)
	box.add_child(resume)
	var settings := _make_button("SETTINGS")
	settings.pressed.connect(func() -> void:
		_pause_panel.visible = false
		_settings.visible = true)
	box.add_child(settings)
	var restart := _make_button("RESTART")
	restart.pressed.connect(func() -> void:
		get_tree().paused = false
		restart_requested.emit())
	box.add_child(restart)
	var menu := _make_button("MENU")
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
	var menu := _make_button("MENU")
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

## Contorul de performanta se reimprospateaza de 4 ori pe secunda: destul ca
## sa vezi o cadere, prea rar ca sa palpaie. Cifrele sunt ale cadrului
## PRECEDENT (asa raporteaza RenderingServer), ceea ce nu conteaza la 60 Hz.
## Timpul GPU cere `viewport_set_measure_render_time`, altfel citeste 0.
func _process(delta: float) -> void:
	if not GameState.show_perf:
		if _perf.visible:
			_perf.visible = false
			RenderingServer.viewport_set_measure_render_time(
				get_viewport().get_viewport_rid(), false)
		return
	if not _perf.visible:
		_perf.visible = true
		RenderingServer.viewport_set_measure_render_time(
			get_viewport().get_viewport_rid(), true)
	_perf_clock += delta
	if _perf_clock < 0.25:
		return
	_perf_clock = 0.0
	var vp := get_viewport().get_viewport_rid()
	var t := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE
	var draws := RenderingServer.viewport_get_render_info(vp, t,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.viewport_get_render_info(vp, t,
		RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	# Pasa de UMBRA se numara separat (TYPE_SHADOW): pe Jodhpur adauga 260-1700
	# desene si pana la 1,3M tri peste cele vizibile, iar fara ea contorul
	# arata doar o parte din cadru.
	var ts := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW
	var sh_draws := RenderingServer.viewport_get_render_info(vp, ts,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var sh_prims := RenderingServer.viewport_get_render_info(vp, ts,
		RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	# A doua linie: optiunile grafice active, inclusiv inaltimea 3D efectiva.
	_perf.text = "%d fps  |  %d+%d draws  |  %dk+%dk tri  |  cpu %.1f ms  gpu %.1f ms\n%s" % [
		Engine.get_frames_per_second(), draws, sh_draws, prims / 1000,
		sh_prims / 1000,
		RenderingServer.viewport_get_measured_render_time_cpu(vp),
		RenderingServer.viewport_get_measured_render_time_gpu(vp),
		_gfx_line()]


## Soarele si mediul pistei, cautate o data pe cursa (nu la fiecare
## reimprospatare: un find_children pe tot arborele de 4 ori pe secunda ar
## costa chiar timpul de CPU pe care contorul il masoara).
var _perf_sun: DirectionalLight3D
var _perf_env: WorldEnvironment

## A doua linie a contorului: optiunile grafice EFECTIV active (citite de pe
## viewport, soare si mediu, nu din setari), cu „*" pe cele fortate de un
## comutator de test. Asa o captura de ecran spune singura in ce conditii s-a
## masurat fps-ul.
func _gfx_line() -> String:
	if not is_instance_valid(_perf_sun):
		var suns := get_tree().root.find_children("*", "DirectionalLight3D", true, false)
		_perf_sun = suns[0] as DirectionalLight3D if not suns.is_empty() else null
	if not is_instance_valid(_perf_env):
		var envs := get_tree().root.find_children("*", "WorldEnvironment", true, false)
		_perf_env = envs[0] as WorldEnvironment if not envs.is_empty() else null
	var vpn := get_viewport()
	var msaa := "off"
	match vpn.msaa_3d:
		Viewport.MSAA_2X: msaa = "2x"
		Viewport.MSAA_4X: msaa = "4x"
		Viewport.MSAA_8X: msaa = "8x"
	var h3d := int(DisplayServer.window_get_size().y * vpn.scaling_3d_scale)
	var shadows := "off"
	if _perf_sun != null and _perf_sun.shadow_enabled:
		var two := _perf_sun.directional_shadow_mode \
			== DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		shadows = "2 splits" if two else "1 split"
	var glow := "off"
	if _perf_env != null and _perf_env.environment != null \
			and _perf_env.environment.glow_enabled:
		glow = "on"
	var star := func(forced: bool) -> String: return "*" if forced else ""
	return "%s  |  MSAA %s%s  |  3D %dp%s  |  shadows %s%s  |  glow %s%s" % [
		GameState.GFX_TIER_NAMES[GameState.gfx_tier],
		msaa, star.call(GameState.dbg_msaa > 0),
		h3d, star.call(GameState.dbg_scale > 0),
		shadows, star.call(GameState.dbg_shadows > 0),
		glow, star.call(GameState.dbg_glow > 0)]


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


## Tranzitia de repunere (#495). Nu pana la negru: in ultima clipa inca vezi
## masina clipind acolo unde a ramas, ca sa stii DE CE esti mutat.
const RECOVER_VEIL_PEAK: float = 0.7

func recovery_fade_in(seconds: float) -> void:
	if _recover_tween != null and _recover_tween.is_valid():
		_recover_tween.kill()
	_recover_tween = create_tween()
	_recover_tween.tween_property(_recover_veil, "modulate:a", RECOVER_VEIL_PEAK,
		maxf(seconds, 0.1)).set_ease(Tween.EASE_IN)


## Dupa teleport: ecranul se limpezeste repede, pe masina deja asezata.
func recovery_fade_out() -> void:
	if _recover_tween != null and _recover_tween.is_valid():
		_recover_tween.kill()
	_recover_tween = create_tween()
	_recover_tween.tween_property(_recover_veil, "modulate:a", 0.0, 0.3)


## Negativ = ascuns. Zecimi, nu secunde intregi: la 3 s, „3, 2, 1" sare prea
## rar ca sa simti ca timpul curge; ultima secunda se inroseste.
func set_offroad_clock(seconds: float) -> void:
	if seconds < 0.0:
		_offroad_label.visible = false
		return
	_offroad_label.visible = true
	_offroad_label.text = "OFF ROAD\n%.1f" % maxf(seconds, 0.0)
	_offroad_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.2) if seconds < 1.0 else Color(1.0, 0.82, 0.25))


func set_wrong_way(on: bool) -> void:
	if _wrong_way_tween != null and _wrong_way_tween.is_valid():
		_wrong_way_tween.kill()
	_wrong_way_label.visible = on
	_wrong_way_label.modulate.a = 1.0
	if on:
		_wrong_way_tween = create_tween().set_loops()
		_wrong_way_tween.tween_property(_wrong_way_label, "modulate:a", 0.35, 0.35)
		_wrong_way_tween.tween_property(_wrong_way_label, "modulate:a", 1.0, 0.35)


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
