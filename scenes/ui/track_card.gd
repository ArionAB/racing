class_name TrackCard
extends Button
## Cartonasul unei piste in "CURSA RAPIDA": imagine sus, nume + regiune +
## best lap jos. E un Button intreg (tinta mare de touch, focus cu tastatura/
## gamepad); copiii doar deseneaza si lasa click-ul sa treaca.
##
## Fara imagine in `TrackInfo.THUMB_DIR`, zona de sus e un placeholder in
## culoarea pistei care arata si calea unde trebuie pusa poza.

const FOOTER_COLOR := Color(0.09, 0.12, 0.19)
const OUTLINE_IDLE := Color(0.20, 0.27, 0.40)
const OUTLINE_HOVER := Color(0.45, 0.55, 0.72)
const OUTLINE_FOCUS := Color(0.95, 0.83, 0.48)
const TEXT_DIM := Color(0.62, 0.68, 0.78)
const RADIUS := 8

var track_index: int = 0
var _outline_box: StyleBoxFlat


func setup(index: int) -> TrackCard:
	track_index = index
	return self


func _ready() -> void:
	var info := TrackInfo.for_track(track_index)
	custom_minimum_size = Vector2(300, 250)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Butonul in sine e invizibil: forma si conturul le deseneaza copiii.
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(state, empty)

	# Panoul cu colturi rotunde decupeaza imaginea (clip_children foloseste
	# forma desenata de parinte ca masca).
	var clip := Panel.new()
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var bg := StyleBoxFlat.new()
	bg.bg_color = FOOTER_COLOR
	bg.set_corner_radius_all(RADIUS)
	clip.add_theme_stylebox_override("panel", bg)
	add_child(clip)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	clip.add_child(column)
	column.add_child(_build_thumb(info))
	column.add_child(_build_footer(info))

	# Conturul, peste tot restul; isi schimba culoarea cu hover/focus.
	var outline := Panel.new()
	outline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline_box = StyleBoxFlat.new()
	_outline_box.draw_center = false
	_outline_box.set_corner_radius_all(RADIUS)
	outline.add_theme_stylebox_override("panel", _outline_box)
	add_child(outline)

	mouse_entered.connect(_refresh_outline)
	mouse_exited.connect(_refresh_outline)
	focus_entered.connect(_refresh_outline)
	focus_exited.connect(_refresh_outline)
	_refresh_outline()


func _refresh_outline() -> void:
	if has_focus():
		_outline_box.border_color = OUTLINE_FOCUS
		_outline_box.set_border_width_all(3)
	elif is_hovered():
		_outline_box.border_color = OUTLINE_HOVER
		_outline_box.set_border_width_all(2)
	else:
		_outline_box.border_color = OUTLINE_IDLE
		_outline_box.set_border_width_all(2)


func _build_thumb(info: TrackInfo) -> Control:
	var thumb := TextureRect.new()
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var texture := TrackInfo.thumbnail(track_index)
	if texture != null:
		thumb.texture = texture
		return thumb

	# Placeholder: gradient diagonal in culoarea pistei + calea asteptata.
	var gradient := Gradient.new()
	gradient.set_color(0, info.accent.darkened(0.55))
	gradient.set_color(1, info.accent.darkened(0.1))
	var fill := GradientTexture2D.new()
	fill.gradient = gradient
	fill.fill_from = Vector2(0, 1)
	fill.fill_to = Vector2(1, 0)
	thumb.texture = fill

	var hint := VBoxContainer.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_child(hint)
	var big := _label(info.display_name.to_upper(), 30, Color(1, 1, 1, 0.22))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_child(big)
	var path := _label(TrackInfo.thumb_path(track_index).trim_prefix("res://"),
		13, Color(1, 1, 1, 0.45))
	path.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_child(path)
	return thumb


func _build_footer(info: TrackInfo) -> Control:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 12)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 2)
	row.add_child(names)
	var title := _label(info.display_name.to_upper(), 22, Color.WHITE)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(title)
	var region_row := HBoxContainer.new()
	region_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_row.add_theme_constant_override("separation", 6)
	names.add_child(region_row)
	var dot := _Dot.new()
	dot.color = info.accent
	region_row.add_child(dot)
	region_row.add_child(_label(info.region, 14, TEXT_DIM))

	var clock := _Clock.new()
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(clock)
	# Doua recorduri: cel mai bun tur si cea mai buna cursa intreaga (#498).
	_add_record(row, "LAP", GameState.best_lap(track_index))
	_add_record(row, "RACE", GameState.best_race(track_index))
	return margin


func _add_record(row: HBoxContainer, caption: String, ms: int) -> void:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	box.add_child(_label(caption, 12, TEXT_DIM))
	box.add_child(_label(_format_ms(ms), 18, Color.WHITE))


static func _format_ms(ms: int) -> String:
	if ms <= 0:
		return "--:--.-"
	@warning_ignore("integer_division")
	return "%d:%02d.%d" % [ms / 60000, (ms % 60000) / 1000, (ms % 1000) / 100]


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


## Bulina de regiune (in locul iconitelor din macheta, pana avem un set).
class _Dot extends Control:
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(10, 10)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(size * 0.5, 4.5, color)


## Ceasul de langa BEST, desenat — fara textura, fara font de iconite.
class _Clock extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(22, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var col := Color(0.85, 0.89, 0.95)
		draw_arc(c, 9.0, 0.0, TAU, 32, col, 2.0, true)
		draw_line(c, c + Vector2(0, -5.5), col, 2.0, true)
		draw_line(c, c + Vector2(4.0, 0), col, 2.0, true)
