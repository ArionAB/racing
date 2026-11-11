class_name CreditsPanel
extends Control
## Ecranul CREDITS (#691): autorul, sursele externe cu licenta lor, addon-urile
## si motorul Godot cu tertii lui. Pe ecran intreg, cu antetul panourilor din
## meniu (TrackSelectPanel.build_header); doar continutul deruleaza, cu degetul.
##
## O SINGURA sursa pentru credite: `assets/CREDITS.md`, citit la rulare dupa
## gramatica descrisa in antetul lui. Aici nu exista nicio lista de nume. Fisierul
## ajunge in build prin `include_filter` din export_presets.cfg (un .md nu e
## resursa); ProbeCredits pica daca filtrul nu-l mai acopera.
##
## Motorul vine din API-ul lui (Engine.get_license_text / get_copyright_info /
## get_license_info), nu din text copiat. Tot de acolo vin si textele integrale
## ale licentelor folosite de intrarile noastre (MIT = "Expat" la Godot, OFL-1.1,
## CC0-1.0, CC-BY-4.0) — de aceea CREDITS.md poarta doar identificatorul.
##
## Se deschide din SETTINGS (ultima intrare din lista), deci si din pauza: se
## pune peste tot ecranul, cu fundal propriu, si se distruge la inchidere.

signal closed

const SOURCE_PATH := "res://assets/CREDITS.md"

## Identificatorul din CREDITS.md -> cheia din Engine.get_license_info().
## Godot numeste licenta MIT dupa numele ei SPDX vechi, "Expat".
const LICENSE_ALIASES := {"MIT": "Expat"}

## Campuri care leaga datele de repo si nu se afiseaza.
const HIDDEN_FIELDS: Array[String] = ["Path"]

const BG_COLOR := Color(0.10, 0.12, 0.18)
const GROUP_COLOR := Color(0.95, 0.83, 0.48)
const TEXT_DIM := Color(0.72, 0.77, 0.86)

## Marimi de font: tinta e telefonul in landscape (720 de pixeli logici in
## inaltime), unde 18 e inca lizibil la distanta de brat.
@export var group_font_size := 30
@export var entry_font_size := 24
@export var body_font_size := 18

var _scroll: TouchScrollContainer
var _content: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Opac si STOP: peste meniu sau peste cursa in pauza, nimic de dedesubt nu
	# trebuie sa primeasca atingerile.
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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

	root.add_child(TrackSelectPanel.build_header("CREDITS", "LICENSES & THANKS",
		close))

	_scroll = TouchScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 8)
	pad.add_theme_constant_override("margin_right", 16)
	_scroll.add_child(pad)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	pad.add_child(_content)

	var groups := parse_credits(_read_source())
	if groups.is_empty():
		# Nu tacem: un ecran de credite gol pe telefon e exact defectul de licenta
		# pe care ecranul il repara. Cauza tipica: fisierul scos din include_filter.
		push_error("CreditsPanel: %s lipseste sau e gol" % SOURCE_PATH)
		_content.add_child(_label("Credits file missing: " + SOURCE_PATH,
			body_font_size, Color(1.0, 0.6, 0.5)))
	var used_licenses: Array[String] = []
	for g in groups:
		_add_group(g, used_licenses)
	_add_engine(used_licenses)
	_add_license_texts(used_licenses)


## Inchiderea: BACK din antet sau ESC / inapoi. Panoul se distruge; cine l-a
## deschis afla prin `closed`.
func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Inaintea HUD-ului (care ar redeschide pauza peste noi): panoul e mai
		# jos in arbore, deci primeste evenimentul primul.
		get_viewport().set_input_as_handled()
		close()


# ------------------------------------------------------------------ date

## CREDITS.md -> [{title, entries: [{title, fields: [[cheie, valoare], ...]}]}].
## Doar `## `, `### ` si `- **Cheie:** valoare` (cu continuare indentata) conteaza;
## restul fisierului e nota pentru oameni si se ignora.
static func parse_credits(text: String) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var entry: Dictionary = {}
	var field_open := false
	for raw in text.split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with("### "):
			field_open = false
			if groups.is_empty():
				continue # intrare fara grup: nota, nu credit
			entry = {"title": line.substr(4).strip_edges(), "fields": []}
			(groups[-1]["entries"] as Array).append(entry)
		elif line.begins_with("## "):
			field_open = false
			entry = {}
			groups.append({"title": line.substr(3).strip_edges(), "entries": []})
		elif line.begins_with("# ") or line.begins_with("---"):
			field_open = false
			entry = {}
		elif line.begins_with("- **") and not entry.is_empty():
			var close_at := line.find(":**")
			if close_at < 0:
				field_open = false
				continue
			var key := line.substr(4, close_at - 4).strip_edges()
			var value := line.substr(close_at + 3).strip_edges()
			(entry["fields"] as Array).append([key, value])
			field_open = true
		elif field_open and line != "" and (raw.begins_with(" ") or raw.begins_with("\t")):
			var fields := entry["fields"] as Array
			var last := fields[-1] as Array
			last[1] = (String(last[1]) + " " + line.strip_edges()).strip_edges()
		else:
			field_open = false
	return groups


## Cheia din Engine.get_license_info() pentru valoarea campului License
## ("OFL-1.1 (SIL Open Font License 1.1)" -> "OFL-1.1"); "" daca nu e cunoscuta.
static func license_key(license_value: String) -> String:
	var id := license_value.strip_edges().get_slice(" ", 0)
	id = String(LICENSE_ALIASES.get(id, id))
	return id if Engine.get_license_info().has(id) else ""


static func _read_source() -> String:
	if not FileAccess.file_exists(SOURCE_PATH):
		return ""
	return FileAccess.get_file_as_string(SOURCE_PATH)


# ------------------------------------------------------------------ continut

func _add_group(group: Dictionary, used_licenses: Array[String]) -> void:
	_content.add_child(_group_header(String(group["title"])))
	for e in group["entries"]:
		var entry := e as Dictionary
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		box.add_child(_label(String(entry["title"]), entry_font_size, Color.WHITE))
		var lines: PackedStringArray = []
		for f in entry["fields"]:
			var key := String(f[0])
			if key in HIDDEN_FIELDS:
				continue
			lines.append("%s: %s" % [key, f[1]])
			if key == "License":
				var lic := license_key(String(f[1]))
				if lic != "" and not lic in used_licenses:
					used_licenses.append(lic)
		if not lines.is_empty():
			box.add_child(_label("\n".join(lines), body_font_size, TEXT_DIM))
		_content.add_child(box)


func _add_engine(used_licenses: Array[String]) -> void:
	_content.add_child(_group_header("Godot Engine"))
	_content.add_child(_label("This game uses Godot Engine (https://godotengine.org), "
		+ "available under the following license:", body_font_size, TEXT_DIM))
	_content.add_child(_label(Engine.get_license_text().strip_edges(),
		body_font_size, TEXT_DIM))
	if not "Expat" in used_licenses:
		used_licenses.append("Expat")

	_content.add_child(_group_header("Godot Engine: third-party components"))
	for comp in Engine.get_copyright_info():
		var c := comp as Dictionary
		var name_text := String(c.get("name", ""))
		if name_text == "Godot Engine":
			continue # e chiar textul de mai sus
		var lines: PackedStringArray = []
		for p in c.get("parts", []):
			var part := p as Dictionary
			var lic := String(part.get("license", ""))
			for holder in part.get("copyright", []):
				lines.append("© %s" % holder)
			lines.append("License: %s" % lic)
			# "MPL-2.0 or Apache-2.0", "Expat or Unlicense": fiecare text conteaza.
			for id in lic.replace("(", " ").replace(")", " ").split(" ", false):
				if Engine.get_license_info().has(id) and not id in used_licenses:
					used_licenses.append(id)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.add_child(_label(name_text, body_font_size + 2, Color.WHITE))
		box.add_child(_label("\n".join(lines), body_font_size - 2, TEXT_DIM))
		_content.add_child(box)


## Textele integrale, cate un buton per licenta: desfasurate toate ar fi ~77.000
## de caractere de asezat la deschidere, pentru un ecran pe care il citesc putini.
## Textul se construieste la prima apasare.
func _add_license_texts(used_licenses: Array[String]) -> void:
	_content.add_child(_group_header("License texts"))
	var info := Engine.get_license_info()
	for id in used_licenses:
		var btn := Button.new()
		btn.text = "SHOW  " + id
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.add_theme_font_size_override("font_size", body_font_size)
		_content.add_child(btn)
		var holder := VBoxContainer.new()
		holder.visible = false
		_content.add_child(holder)
		var text := String(info[id])
		btn.toggled.connect(func(on: bool) -> void:
			if holder.get_child_count() == 0:
				holder.add_child(_label(text.strip_edges(), body_font_size - 2, TEXT_DIM))
			holder.visible = on
			btn.text = ("HIDE  " if on else "SHOW  ") + id)


func _group_header(text: String) -> Label:
	var l := _label(text.to_upper(), group_font_size, GROUP_COLOR)
	l.custom_minimum_size.y = group_font_size + 24
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return l


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l
