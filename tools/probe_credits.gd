extends Node
## Garda ecranului CREDITS (#691). Merge HEADLESS.
##
## Ce pazeste, in ordinea in care se strica de obicei:
##   1. sursa ajunge in build: `assets/CREDITS.md` e acoperit de include_filter
##      in FIECARE preset de export (un .md nu e resursa — fara filtru, pe
##      telefon ecranul ar fi gol, iar in editor totul ar parea in regula);
##   2. inventarul: fiecare addon din `addons/`, fiecare `LICENSE_*.txt` din
##      `assets/` si fiecare font din proiect au intrare in sursa — deci o
##      intrare stearsa din CREDITS.md pica aici, nu doar una neafisata;
##   3. fiecare intrare din sursa apare pe ecran cu titlu, autor si licenta
##      (toate campurile vizibile, de fapt), iar licenta are text integral;
##   4. motorul: textul licentei Godot si toate componentele terte din API;
##   5. layout la 1280x720 si la un telefon 2532x1170 (landscape): totul in
##      viewport, continutul lung chiar se deruleaza;
##   6. drumul real: SETTINGS -> CREDITS & LICENSES -> BACK / ESC -> SETTINGS.
##
## Sursa e citita aici cu un parser PROPRIU, nu cu CreditsPanel.parse_credits:
## un parser stricat in panou n-are voie sa ascunda intrari si de garda.
##
## Rulare:
##   Godot --headless --path . res://tools/ProbeCredits.tscn
##
## Memoria `garda-verde-pe-zero-masuratori`: sub MIN_CHECKS verdictul pica.

const SOURCE := "res://assets/CREDITS.md"
const MIN_CHECKS := 150
## Rezolutiile verificate: desktop-ul de referinta si un iPhone in landscape
## (canvas_items + expand => 1558x720 logic).
const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(2532, 1170)]

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	var entries := _parse_source()
	_check_export_filter()
	_check_inventory(entries)
	_check_licenses(entries)
	for s in SIZES:
		await _check_panel(entries, s)
	await _check_flow()
	_report()


func _expect(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


# ------------------------------------------------------------------ sursa

## Intrarile (`### ` sub un `## `), fiecare {group, title, fields: {cheie: valoare}}.
func _parse_source() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_expect(FileAccess.file_exists(SOURCE), "lipseste " + SOURCE)
	if not FileAccess.file_exists(SOURCE):
		return out
	var group := ""
	var cur: Dictionary = {}
	var last_key := ""
	var re := RegEx.create_from_string("^- \\*\\*([^*]+?):\\*\\*\\s*(.*)$")
	for raw in FileAccess.get_file_as_string(SOURCE).split("\n"):
		var line := raw.strip_edges(false, true)
		if line.begins_with("## "):
			group = line.substr(3).strip_edges()
			cur = {}
		elif line.begins_with("### ") and group != "":
			cur = {"group": group, "title": line.substr(4).strip_edges(), "fields": {}}
			out.append(cur)
			last_key = ""
		elif line.begins_with("#") or line.begins_with("---"):
			cur = {}
		elif not cur.is_empty():
			var m := re.search(line)
			if m:
				last_key = m.get_string(1).strip_edges()
				(cur["fields"] as Dictionary)[last_key] = m.get_string(2).strip_edges()
			elif last_key != "" and line.strip_edges() != "" and raw.begins_with(" "):
				var f := cur["fields"] as Dictionary
				f[last_key] = (String(f[last_key]) + " " + line.strip_edges()).strip_edges()
			else:
				last_key = ""
	_expect(out.size() >= 5, "prea putine intrari in sursa: %d" % out.size())
	print("probe_credits: %d intrari in %s" % [out.size(), SOURCE])
	return out


func _check_export_filter() -> void:
	var cfg := ConfigFile.new()
	_expect(cfg.load("res://export_presets.cfg") == OK, "export_presets.cfg nu se incarca")
	var rel := SOURCE.trim_prefix("res://")
	var presets := 0
	for sec in cfg.get_sections():
		if not sec.begins_with("preset.") or sec.ends_with(".options"):
			continue
		presets += 1
		var name := String(cfg.get_value(sec, "name", sec))
		var inc := _matches(String(cfg.get_value(sec, "include_filter", "")), rel)
		var exc := _matches(String(cfg.get_value(sec, "exclude_filter", "")), rel)
		_expect(inc and not exc,
			"presetul '%s' nu exporta %s (include=%s exclude=%s): pe device ecranul ar fi gol"
			% [name, rel, inc, exc])
	_expect(presets > 0, "niciun preset de export")


func _matches(filter: String, path: String) -> bool:
	for pat in filter.split(",", false):
		var p := pat.strip_edges()
		if p != "" and (path.match(p) or ("res://" + path).match(p)):
			return true
	return false


## Inventarul se deduce din repo, independent de sursa.
func _check_inventory(entries: Array[Dictionary]) -> void:
	# Addon-uri: intrare cu Path, iar copyright-ul din LICENSE e cel din sursa.
	var addons := 0
	for dir in DirAccess.get_directories_at("res://addons"):
		addons += 1
		var entry := {}
		for e in entries:
			if String((e["fields"] as Dictionary).get("Path", "")) == "addons/" + dir:
				entry = e
		_expect(not entry.is_empty(), "addon fara credit in sursa: addons/" + dir)
		var lic_path := "res://addons/%s/LICENSE" % dir
		if entry.is_empty() or not FileAccess.file_exists(lic_path):
			continue
		var holder := ""
		for l in FileAccess.get_file_as_string(lic_path).split("\n"):
			if l.strip_edges().begins_with("Copyright"):
				holder = l.strip_edges().trim_prefix("Copyright").strip_edges() \
					.trim_prefix("(c)").trim_prefix("©").strip_edges()
				break
		_expect(holder == String((entry["fields"] as Dictionary).get("Copyright", "")),
			"addons/%s: copyright din LICENSE '%s' != sursa '%s'" % [
				dir, holder, (entry["fields"] as Dictionary).get("Copyright", "")])
	_expect(addons > 0, "niciun addon gasit: garda e oarba")

	# Fisiere LICENSE_<sursa>*.txt din assets: sursa numita trebuie creditata.
	var lic_files: Array[String] = []
	_walk("res://assets", lic_files, func(f: String) -> bool:
		return f.get_file().begins_with("LICENSE_") and f.ends_with(".txt"))
	for f in lic_files:
		var token := f.get_file().trim_prefix("LICENSE_").get_basename().get_slice("_", 0)
		_expect(_credited(entries, token), "%s fara intrare in sursa (cautat '%s')" % [f, token])
	_expect(lic_files.size() >= 3, "doar %d fisiere LICENSE_ in assets" % lic_files.size())

	# Fonturi: familia din numele fisierului (BarlowCondensed-Medium.ttf).
	var fonts: Array[String] = []
	for root in ["res://assets", "res://scenes"]:
		_walk(root, fonts, func(f: String) -> bool:
			return f.get_extension().to_lower() in ["ttf", "otf", "woff", "woff2"])
	for f in fonts:
		var family := f.get_file().get_basename().get_slice("-", 0)
		_expect(_credited(entries, family), "font fara intrare in sursa: " + f)
	_expect(fonts.size() >= 1, "niciun font gasit: garda e oarba")


func _credited(entries: Array[Dictionary], token: String) -> bool:
	var t := token.to_lower().replace(" ", "")
	for e in entries:
		var hay := (String(e["title"]) + " " + String((e["fields"] as Dictionary)
			.get("Author", ""))).to_lower().replace(" ", "")
		if t in hay:
			return true
	return false


func _walk(dir: String, out: Array[String], pred: Callable) -> void:
	for f in DirAccess.get_files_at(dir):
		if pred.call(dir + "/" + f):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with("."):
			_walk(dir + "/" + d, out, pred)


## Orice intrare cu licenta are autor, iar licenta are text integral in motor.
func _check_licenses(entries: Array[Dictionary]) -> void:
	var info := Engine.get_license_info()
	for e in entries:
		var f := e["fields"] as Dictionary
		_expect(not f.is_empty(), "intrarea '%s' n-are niciun camp" % e["title"])
		if not f.has("License"):
			continue
		_expect(String(f.get("Author", "")) != "",
			"intrarea '%s' are licenta, dar n-are Author" % e["title"])
		var id := String(f["License"]).get_slice(" ", 0)
		id = "Expat" if id == "MIT" else id
		_expect(info.has(id), "intrarea '%s': licenta '%s' n-are text in motor" % [
			e["title"], id])


# ------------------------------------------------------------------ panoul

func _check_panel(entries: Array[Dictionary], win: Vector2i) -> void:
	get_window().size = win
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var panel := CreditsPanel.new()
	host.add_child(panel)
	for i in 4:
		await get_tree().process_frame
	var vp := get_viewport().get_visible_rect()
	var tag := "%dx%d" % [win.x, win.y]
	print("probe_credits: %s -> viewport logic %s" % [tag, vp.size])
	if win.x > 2000:
		# canvas_items + expand: inaltimea ramane 720, latimea creste.
		_expect(vp.size.x > 1500.0 and absf(vp.size.y - 720.0) < 1.0,
			"%s: viewportul logic nu e cel de telefon (%s)" % [tag, vp.size])

	var text := _norm(_all_text(panel))
	# 3. fiecare intrare, cu toate campurile vizibile
	for e in entries:
		_expect(_norm(String(e["title"])) in text,
			"%s: titlul '%s' lipseste de pe ecran" % [tag, e["title"]])
		var f := e["fields"] as Dictionary
		for key in f:
			if key == "Path":
				continue
			_expect(_norm("%s: %s" % [key, f[key]]) in text,
				"%s: '%s' / %s lipseste de pe ecran" % [tag, e["title"], key])
	# 4. motorul
	var lt := Engine.get_license_text()
	_expect(lt.length() > 500 and _norm(lt) in text, "%s: licenta Godot lipseste" % tag)
	var comps := 0
	for c in Engine.get_copyright_info():
		comps += 1
		_expect(_norm(String((c as Dictionary)["name"])) in text,
			"%s: componenta '%s' lipseste" % [tag, (c as Dictionary)["name"]])
	_expect(comps >= 50, "%s: doar %d componente in motor" % [tag, comps])

	# Textele de licenta: cate un buton; Expat se desface cu textul MIT.
	var expat: Button = null
	var lic_buttons := 0
	for b in panel.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.text.begins_with("SHOW  "):
			lic_buttons += 1
			if btn.text == "SHOW  Expat":
				expat = btn
	_expect(lic_buttons >= 10, "%s: doar %d butoane de licenta" % [tag, lic_buttons])
	_expect(expat != null, "%s: lipseste textul MIT (Expat)" % tag)
	if expat != null:
		expat.button_pressed = true
		await get_tree().process_frame
		_expect("permission is hereby granted" in _all_text(panel).to_lower(),
			"%s: Expat apasat nu arata textul" % tag)

	# 5. layout
	await get_tree().process_frame
	var full := Rect2(Vector2.ZERO, vp.size).grow(1.0)
	_expect(full.encloses(panel.get_global_rect()) and
		panel.get_global_rect().size.distance_to(vp.size) < 2.0,
		"%s: panoul %s nu acopera viewportul %s" % [tag, panel.get_global_rect(), vp.size])
	var back := _find_button(panel, "<  BACK")
	_expect(back != null and full.encloses(back.get_global_rect()),
		"%s: BACK in afara ecranului" % tag)
	_expect(back != null and back.size.y >= 48.0, "%s: BACK sub tinta de deget" % tag)
	var scroll := panel._scroll
	var sr := scroll.get_global_rect()
	_expect(full.encloses(sr), "%s: lista %s iese din ecran" % [tag, sr])
	_expect(sr.size.y > 300.0, "%s: lista prea scunda (%.0f)" % [tag, sr.size.y])
	var content_h := panel._content.size.y
	_expect(content_h > sr.size.y * 3.0,
		"%s: continutul (%.0f) nu e lung — nimic de derulat?" % [tag, content_h])
	var wide := 0
	for l in panel._content.find_children("*", "Label", true, false):
		var lr := (l as Label).get_global_rect()
		if lr.end.x > sr.end.x + 1.0:
			wide += 1
	_expect(wide == 0, "%s: %d etichete ies pe dreapta listei" % [tag, wide])
	# Derularea: la capat, ultimul element ajunge in fereastra listei.
	scroll.scroll_vertical = int(content_h)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(scroll.scroll_vertical > int(sr.size.y),
		"%s: lista nu deruleaza (scroll %d)" % [tag, scroll.scroll_vertical])
	var last: Control = null
	for c in panel._content.get_children():
		if (c as Control).visible:
			last = c
	_expect(last != null and sr.grow(1.0).intersects(last.get_global_rect()),
		"%s: ultimul element nu ajunge in vedere la capatul derularii" % tag)

	host.queue_free()
	await get_tree().process_frame


## 6. Drumul real, din SETTINGS, ca in meniu si in pauza.
func _check_flow() -> void:
	get_window().size = SIZES[0]
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var settings := SettingsPanel.new()
	host.add_child(settings)
	for i in 3:
		await get_tree().process_frame
	var btn := _find_button(settings, "CREDITS & LICENSES")
	_expect(btn != null, "SETTINGS n-are butonul CREDITS & LICENSES")
	if btn == null:
		host.queue_free()
		return
	_expect(btn.size.y >= 44.0, "butonul de credite sub tinta de deget")
	var full := get_viewport().get_visible_rect().grow(1.0)
	_expect(full.encloses(settings.get_global_rect()), "SETTINGS iese din ecran")

	for how in ["BACK", "ESC"]:
		btn.pressed.emit()
		await get_tree().process_frame
		var credits := _find_credits(host)
		_expect(credits != null, "%s: CREDITS nu s-a deschis" % how)
		_expect(not settings.visible, "%s: SETTINGS ramane vizibil sub credite" % how)
		if credits == null:
			continue
		if how == "BACK":
			_find_button(credits, "<  BACK").pressed.emit()
		else:
			var ev := InputEventAction.new()
			ev.action = &"ui_cancel"
			ev.pressed = true
			get_viewport().push_input(ev)
		await get_tree().process_frame
		await get_tree().process_frame
		_expect(_find_credits(host) == null, "%s: CREDITS nu s-a inchis" % how)
		_expect(settings.visible, "%s: SETTINGS nu revine dupa credite" % how)
	host.queue_free()
	await get_tree().process_frame


func _find_credits(host: Node) -> CreditsPanel:
	for c in host.get_children():
		if c is CreditsPanel and not c.is_queued_for_deletion():
			return c
	return null


func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func _all_text(root: Node) -> String:
	var parts: PackedStringArray = []
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree():
			parts.append((n as Label).text)
	return "\n".join(parts)


## Spatiile si randurile nu conteaza (autowrap, continuari in .md).
func _norm(s: String) -> String:
	var re := RegEx.create_from_string("\\s+")
	return re.sub(s, " ", true).strip_edges()


func _report() -> void:
	if _checks < MIN_CHECKS:
		_fails.append("doar %d verificari au rulat (minim %d) — garda e oarba" % [
			_checks, MIN_CHECKS])
	for f in _fails:
		printerr("probe_credits: ", f)
	print("probe_credits: %d verificari" % _checks)
	if _fails.is_empty():
		print("VERDICT: OK")
		get_tree().quit()
		return
	print("VERDICT: PROBLEMA (%d)" % _fails.size())
	get_tree().quit(1)
