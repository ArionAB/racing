class_name WorldCupPanel
extends Control
## "WORLD CUP": o cutie per cupa (GameState.WORLD_CUPS) cu pistele ei in
## ordinea curselor si butonul START. Pistele sunt doar afis — o cupa se
## joaca intreaga, in ordine, deci singura tinta de apasat e butonul cupei.
## Pe ecran intreg, cu antet fix; doar continutul deruleaza. Acelasi tipar ca
## TrackSelectPanel si CareerPanel, al caror antet si cutii le refoloseste.
##
## Save-urile (`WorldCupSave`, scrise dupa fiecare cursa terminata) sunt per
## cupa SI per nivel AI, iar SELECTORUL de nivel de sus alege pe care il arata
## fiecare cutie (20 nov 2026: o cupa inceputa pe BRONZE nu se termina pe GOLD).
## Cu save pe nivelul ales, butonul devine CONTINUE (acelasi loc, aceeasi
## marime), langa el un RESET mai mic, iar sub titlu un rand de stare —
## „RACE 3 / 4  ·  2ND  ·  11 PTS  ·  AUTOBUZUL" (nivelul il arata selectorul).
## Fara save pe nivelul ales: START, cupa noua pe nivelul acela, fara sa atinga
## save-urile celorlalte niveluri. Daca cupa are save pe ALTE niveluri, un rand
## stins o spune: „ALSO IN PROGRESS: GOLD" (doar informatie, nu buton).
## RESET cere DOUA atingeri: prima il face SURE? (rosu) pentru
## `RESET_CONFIRM_S`, a doua in fereastra sterge DOAR (cupa, nivelul ales), iar
## cutia se reface pe loc, fara dialog si fara reconstruirea panoului. Schimbarea
## nivelului dezarmeaza orice RESET armat: a doua atingere nu poate sterge alt
## save decat cel la care se uita jucatorul. Cutiile se reimprospateaza la
## schimbarea nivelului si de fiecare data cand panoul devine vizibil
## (intoarcerea din cursa arata CONTINUE).

signal back_pressed

## Inaltimea placutei de pista ca fractie din latime.
const TILE_ASPECT := 0.56
## Cat sta RESET armat (SURE?) asteptand a doua atingere.
const RESET_CONFIRM_S := 3.0
const START_TEXT := "START"
const CONTINUE_TEXT := "CONTINUE"
const RESET_TEXT := "RESET"
const RESET_CONFIRM_TEXT := "SURE?"
const OTHER_LEVELS_PREFIX := "ALSO IN PROGRESS: "
const RESET_ARMED_BG := Color(0.62, 0.13, 0.12)
const RESET_ARMED_BORDER := Color(1.0, 0.42, 0.36)

## Butonul principal al fiecarei cupe (START / CONTINUE), in ordinea WORLD_CUPS.
var _start_buttons: Array[Button] = []
## cup.id -> {"cup", "primary", "reset", "status", "others"}: nodurile care
## se schimba la reimprospatare, fara sa se reconstruiasca cutia.
var _boxes: Dictionary = {}
## cup.id -> generatia armarii RESET (0 = nearmat). Expirarea unei armari
## vechi nu are voie sa dezarmeze una noua.
var _reset_armed: Dictionary = {}
## cup.id -> nivelul pe care a fost armat RESET-ul. A doua atingere sterge doar
## daca selectorul arata tot nivelul acela (plasa sub dezarmarea la schimbare).
var _reset_level: Dictionary = {}
var _reset_generation: int = 0
var _selector: AiSkillSelector


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	root.add_child(TrackSelectPanel.build_header("WORLD CUP", "CHOOSE A CUP",
		back_pressed.emit))
	_selector = AiSkillSelector.new()
	_selector.level_changed.connect(_on_level_changed)
	root.add_child(_selector)

	var scroll := TouchScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 4)
	scroll.add_child(pad)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	pad.add_child(content)

	var rules := _label("POINTS PER RACE  6 · 5 · 4 · 3 · 2 · 1     ·     "
		+ "NEW RIVALS EVERY CUP, NEVER THE SAME CAR TWICE", 18,
		TrackCard.TEXT_DIM)
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(rules)

	for cup in GameState.WORLD_CUPS:
		content.add_child(_build_cup(cup as WorldCup))
	refresh()
	visibility_changed.connect(_on_visibility_changed)


func _build_cup(cup: WorldCup) -> Control:
	var box := PanelContainer.new()
	box.name = "Cup_%s" % cup.id
	var style := StyleBoxFlat.new()
	style.bg_color = CareerPanel.BOX_COLOR
	# Conturul in culoarea cupei, cu banda lata in stanga: cutiile se
	# deosebesc dintr-o privire, fara sa citesti titlul.
	style.border_color = cup.accent.darkened(0.15)
	style.set_border_width_all(2)
	style.border_width_left = 8
	style.set_corner_radius_all(TrackCard.RADIUS)
	box.add_theme_stylebox_override("panel", style)
	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(side, 18)
	box.add_child(inner)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	inner.add_child(column)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	column.add_child(title_row)
	var title := _label(cup.display_name, 30, Color.WHITE)
	title_row.add_child(title)
	var count := _label("%d RACES" % cup.tracks.size(), 18,
		TrackSelectPanel.SUBTITLE_COLOR)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(count)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	var reset := _make_reset_button(cup.accent)
	reset.name = "ResetButton"
	reset.pressed.connect(_on_reset_pressed.bind(cup))
	title_row.add_child(reset)
	var start := _make_start_button(cup.accent)
	start.name = "PrimaryButton"
	start.pressed.connect(_on_primary_pressed.bind(cup))
	title_row.add_child(start)
	_start_buttons.append(start)

	# Starea cupei salvate, pe un singur rand sub titlu (ascuns fara save).
	var status := _label("", 20, cup.accent.lightened(0.45))
	status.name = "StatusLabel"
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(status)
	# Save-urile cupei pe ALTE niveluri decat cel ales (ascuns cand nu sunt).
	var others := _label("", 18, TrackCard.TEXT_DIM)
	others.name = "OtherLevelsLabel"
	others.clip_text = true
	others.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(others)
	_boxes[cup.id] = {"cup": cup, "primary": start, "reset": reset, "status": status,
		"others": others}

	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 14)
	column.add_child(tiles)
	for i in cup.tracks.size():
		var index := cup.track_index(i)
		if index < 0:
			continue # id stricat: ProbeWorldCup il prinde inainte de merge
		tiles.add_child(_build_tile(i + 1, index, cup.accent))
	# Inaltimea urmeaza latimea, ca imaginile sa-si tina formatul pe orice ecran.
	tiles.resized.connect(func() -> void:
		var n := tiles.get_child_count()
		if n == 0:
			return
		var sep := float(tiles.get_theme_constant("separation"))
		var h := roundf((tiles.size.x - sep * (n - 1)) / n * TILE_ASPECT)
		for tile in tiles.get_children():
			var c := tile as Control
			if not is_equal_approx(c.custom_minimum_size.y, h):
				c.custom_minimum_size.y = h)
	return box


## Placuta unei piste: imaginea (sau gradientul in culoarea pistei) si, jos,
## numarul cursei + numele.
func _build_tile(race_no: int, track_index: int, accent: Color) -> Control:
	var info := TrackInfo.for_track(track_index)
	var clip := Panel.new()
	clip.name = "Race%d" % race_no
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var bg := StyleBoxFlat.new()
	bg.bg_color = TrackCard.FOOTER_COLOR
	bg.set_corner_radius_all(TrackCard.RADIUS)
	clip.add_theme_stylebox_override("panel", bg)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	clip.add_child(column)

	var thumb := TextureRect.new()
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var texture := TrackInfo.thumbnail(track_index)
	if texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, info.accent.darkened(0.55))
		gradient.set_color(1, info.accent.darkened(0.1))
		var fill := GradientTexture2D.new()
		fill.gradient = gradient
		fill.fill_from = Vector2(0, 1)
		fill.fill_to = Vector2(1, 0)
		texture = fill
	thumb.texture = texture
	column.add_child(thumb)

	var footer := MarginContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_constant_override("margin_left", 12)
	footer.add_theme_constant_override("margin_right", 12)
	footer.add_theme_constant_override("margin_top", 6)
	footer.add_theme_constant_override("margin_bottom", 8)
	column.add_child(footer)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	footer.add_child(row)
	row.add_child(_label(str(race_no), 20, accent.lightened(0.35)))
	var name_label := _label(info.display_name.to_upper(), 18, Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_label)
	return clip


func _make_start_button(accent: Color) -> Button:
	var button := Button.new()
	button.text = START_TEXT
	button.custom_minimum_size = Vector2(200, 56)
	button.add_theme_font_size_override("font_size", 24)
	var box := StyleBoxFlat.new()
	box.bg_color = accent.darkened(0.35)
	box.border_color = accent
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = accent.darkened(0.2)
	var focus := box.duplicate() as StyleBoxFlat
	focus.border_color = TrackCard.OUTLINE_FOCUS
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	return button


## RESET: mai ingust si cu text mai mic decat START, dar la fel de inalt
## (tinta de deget >= 48 px).
func _make_reset_button(accent: Color) -> Button:
	var button := Button.new()
	button.text = RESET_TEXT
	button.custom_minimum_size = Vector2(130, 56)
	button.add_theme_font_size_override("font_size", 20)
	_style_reset(button, accent, false)
	return button


## Stilul RESET-ului: neutru, sau rosu cat e armat (SURE?).
func _style_reset(button: Button, accent: Color, armed: bool) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = RESET_ARMED_BG if armed else CareerPanel.BOX_COLOR.lightened(0.08)
	box.border_color = RESET_ARMED_BORDER if armed else accent.darkened(0.15)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	var hover := box.duplicate() as StyleBoxFlat
	hover.bg_color = box.bg_color.lightened(0.1)
	var focus := box.duplicate() as StyleBoxFlat
	focus.border_color = TrackCard.OUTLINE_FOCUS
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)


## Cutiile dupa save-urile de pe disc, pe nivelul din selector: START, sau
## CONTINUE + RESET + starea; plus randul celorlalte niveluri.
func refresh() -> void:
	for id: StringName in _boxes:
		_refresh_box(_boxes[id])


func _refresh_box(box: Dictionary) -> void:
	var cup := box.cup as WorldCup
	var level := GameState.ai_level
	var entry := WorldCupSave.load_entry(cup, level)
	var primary := box.primary as Button
	var status := box.status as Label
	primary.text = CONTINUE_TEXT if entry != null else START_TEXT
	(box.reset as Button).visible = entry != null
	status.visible = entry != null
	status.text = status_text(entry) if entry != null else ""
	var others := box.others as Label
	others.text = other_levels_text(WorldCupSave.levels_in_progress(cup), level)
	others.visible = others.text != ""
	_disarm(cup)


## „RACE 3 / 4  ·  2ND  ·  11 PTS  ·  AUTOBUZUL": cursa care urmeaza, locul
## jucatorului dupa puncte, punctele lui, masina cupei. Nivelul nu: il arata
## selectorul, si cutia arata mereu save-ul nivelului ales.
static func status_text(entry: WorldCupSave.Entry) -> String:
	var car := GameState.CAR_DATA[entry.player_car] as CarData
	return "RACE %d / %d  ·  %s  ·  %d PTS  ·  %s" % [
		entry.next_race + 1, entry.cup.tracks.size(),
		Race._ordinal(entry.player_rank()).to_upper(), entry.points[0],
		car.display_name.to_upper()]


## „ALSO IN PROGRESS: BRONZE, GOLD" — nivelurile cu save in afara celui ales,
## in ordinea nivelurilor; "" cand nu e niciunul.
static func other_levels_text(levels: Array[int], selected: int) -> String:
	var names := PackedStringArray()
	for level in levels:
		if level != selected:
			names.append(AiSkill.LEVEL_NAMES[level])
	return OTHER_LEVELS_PREFIX + ", ".join(names) if not names.is_empty() else ""


## START porneste o cupa noua pe nivelul ales; CONTINUE o reia pe cea salvata
## pe nivelul ales. Starea se citeste la apasare, nu din eticheta: un save
## disparut intre timp porneste o cupa noua in loc sa nu faca nimic.
func _on_primary_pressed(cup: WorldCup) -> void:
	if not GameState.continue_championship(cup, GameState.ai_level):
		GameState.start_championship(cup)


## Alt nivel in selector: alte save-uri in cutii, iar orice RESET armat se
## dezarmeaza (`_refresh_box`).
func _on_level_changed(_level: int) -> void:
	refresh()


## Prima atingere armeaza (SURE? pentru `RESET_CONFIRM_S`), a doua sterge
## save-ul (cupa, nivelul ales) — doar pe el — si cutia se reface pe loc.
func _on_reset_pressed(cup: WorldCup) -> void:
	var box: Dictionary = _boxes.get(cup.id, {})
	if box.is_empty():
		return
	if is_reset_armed(cup) and int(_reset_level.get(cup.id, -1)) == GameState.ai_level:
		WorldCupSave.erase(cup.id, GameState.ai_level)
		_refresh_box(box)
		(box.primary as Button).grab_focus()
		return
	_reset_generation += 1
	var generation := _reset_generation
	_reset_armed[cup.id] = generation
	_reset_level[cup.id] = GameState.ai_level
	var reset := box.reset as Button
	reset.text = RESET_CONFIRM_TEXT
	_style_reset(reset, cup.accent, true)
	# Metoda, nu lambda: conexiunea moare odata cu panoul.
	get_tree().create_timer(RESET_CONFIRM_S).timeout.connect(
		_on_reset_window_over.bind(cup, generation))


func _on_reset_window_over(cup: WorldCup, generation: int) -> void:
	if int(_reset_armed.get(cup.id, 0)) == generation:
		_disarm(cup)


## True cat RESET-ul cupei asteapta a doua atingere.
func is_reset_armed(cup: WorldCup) -> bool:
	return int(_reset_armed.get(cup.id, 0)) != 0


func _disarm(cup: WorldCup) -> void:
	_reset_armed[cup.id] = 0
	var box: Dictionary = _boxes.get(cup.id, {})
	if box.is_empty():
		return
	var reset := box.reset as Button
	reset.text = RESET_TEXT
	_style_reset(reset, cup.accent, false)


## Cutiile se reimprospateaza (intoarcerea din cursa arata CONTINUE), apoi
## focus pe cupa jucata ultima (sau pe prima) — navigare cu tastatura/gamepad.
func _on_visibility_changed() -> void:
	if not visible or _start_buttons.is_empty():
		return
	refresh()
	var index := maxi(GameState.WORLD_CUPS.find(GameState.champ_cup), 0)
	_start_buttons[index].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
