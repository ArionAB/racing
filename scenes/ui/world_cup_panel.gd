class_name WorldCupPanel
extends Control
## "WORLD CUP": o cutie per cupa (GameState.WORLD_CUPS) cu pistele ei in
## ordinea curselor si butonul START. Pistele sunt doar afis — o cupa se
## joaca intreaga, de la prima cursa, deci singura tinta de apasat e START.
## Pe ecran intreg, cu antet fix; doar continutul deruleaza. Acelasi tipar ca
## TrackSelectPanel si CareerPanel, al caror antet si cutii le refoloseste.

signal back_pressed

## Inaltimea placutei de pista ca fractie din latime.
const TILE_ASPECT := 0.56

var _start_buttons: Array[Button] = []


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
	visibility_changed.connect(_on_visibility_changed)


func _build_cup(cup: WorldCup) -> Control:
	var box := PanelContainer.new()
	box.name = "Cup_%s" % cup.id
	var style := StyleBoxFlat.new()
	style.bg_color = CareerPanel.BOX_COLOR
	# Conturul in culoarea cupei, cu banda lata in stanga: cele trei cutii se
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
	var start := _make_start_button(cup.accent)
	start.pressed.connect(func() -> void: GameState.start_championship(cup))
	title_row.add_child(start)
	_start_buttons.append(start)

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
	button.text = "START"
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


## Focus pe cupa jucata ultima (sau pe prima) — navigare cu tastatura/gamepad.
func _on_visibility_changed() -> void:
	if not visible or _start_buttons.is_empty():
		return
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
