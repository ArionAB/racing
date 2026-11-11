extends Node
## Garda #692: pe mobil (iOS, Android) meniul principal NU are buton de iesire
## din aplicatie; pe desktop il are. Apple respinge la review aplicatiile cu
## buton explicit de QUIT, iar pe Android iesirea e gestul „inapoi” al
## sistemului.
##
## `OS.has_feature` nu se poate falsifica, asa ca meniul intreaba prin
## `_has_platform_feature(tag)`, iar sonda o suprascrie (clasa interna de mai
## jos) cu etichetele fiecarei platforme. Masoara meniul REAL construit de
## `_ready`, nu o copie a conditiei.
##
## Contracte:
##   1. QUIT: pe mobil niciun buton cu QUIT/EXIT in tot meniul (si in panourile
##      ascunse, si butoane ascunse cu `visible = false` — butonul nu trebuie sa
##      EXISTE); pe desktop exact unul, in coloana principala.
##   2. RESTUL MENIULUI: pe mobil coloana are aceleasi butoane ca pe desktop,
##      minus QUIT (nu pierdem altceva odata cu el).
##   3. FARA GOL: coloana se termina cu un buton, distantele dintre elemente
##      sunt toate egale cu separarea, iar coloana incape in ecran — la 1280x720
##      si la iPhone 2532x1170 (1558x720 dupa stretch canvas_items/expand).
##   4. FOCUS: niciun focus_neighbor nu arata spre un nod lipsa, iar lantul de
##      focus pornit din primul buton trece prin toate butoanele coloanei.
##   5. SURSE: in scenes/ si scripts/ singurul `quit(` e cel din main_menu.gd
##      (pazit de 1). O iesire noua din UI (pauza, rezultate) pica aici.
##
## Rulare:
##   Godot --headless --path . res://tools/ProbeMainMenuQuit.tscn

const QUIT_WORDS: Array[String] = ["QUIT", "EXIT"]
const ALLOWED_QUIT_SOURCES: Array[String] = ["res://scenes/main_menu/main_menu.gd"]
const SOURCE_ROOTS: Array[String] = ["res://scenes", "res://scripts"]

class FakePlatformMenu extends "res://scenes/main_menu/main_menu.gd":
	var fake_tags: PackedStringArray = PackedStringArray()

	func _has_platform_feature(tag: String) -> bool:
		return fake_tags.has(tag)

var _fail := 0
var _desktop_texts: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	# [nume, etichete Godot, are voie la QUIT]. Desktop intai: lista lui de
	# butoane e referinta pentru contractul 2.
	var platforms: Array = [
		["Windows", PackedStringArray(["pc", "windows"]), true],
		["macOS", PackedStringArray(["pc", "macos"]), true],
		["Linux", PackedStringArray(["pc", "linux", "linuxbsd"]), true],
		["iOS", PackedStringArray(["mobile", "ios"]), false],
		["Android", PackedStringArray(["mobile", "android"]), false],
	]
	var sizes: Array[Vector2] = [Vector2(1280, 720), Vector2(1558, 720)]
	for p in platforms:
		for sz in sizes:
			await _check_menu(p[0], p[1], p[2], sz)
	print("")
	_check_sources()
	print("")
	print("VERDICT: %s (%d esecuri)" % ["OK" if _fail == 0 else "PROBLEMA", _fail])
	get_tree().quit(1 if _fail > 0 else 0)

func _expect(ok: bool, what: String) -> void:
	if not ok:
		_fail += 1
	print("  %-62s %s" % [what, "OK" if ok else "<<< PICA"])

func _is_quit(b: Button) -> bool:
	var t := b.text.to_upper()
	for w in QUIT_WORDS:
		if t.contains(w):
			return true
	return false

func _buttons_in(n: Node, out: Array[Button]) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_buttons_in(c, out)

func _check_menu(label: String, tags: PackedStringArray, want_quit: bool,
		sz: Vector2) -> void:
	print("%s %dx%d (%s)" % [label, sz.x, sz.y, ", ".join(tags)])
	var host := Control.new()
	host.size = sz
	add_child(host)
	var menu := FakePlatformMenu.new()
	menu.fake_tags = tags
	# Ca radacina din MainMenu.tscn: ancore pe tot ecranul, offset-uri zero
	# (`_ready` pune doar ancorele, offset-urile vin din scena).
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. QUIT, cautat in tot arborele meniului, vizibil sau nu.
	var all_buttons: Array[Button] = []
	_buttons_in(menu, all_buttons)
	var quits := all_buttons.filter(_is_quit)
	var box: VBoxContainer = menu.get("_main_box")
	if want_quit:
		_expect(quits.size() == 1 and quits[0].get_parent() == box,
			"desktop: exact un QUIT, in coloana (gasite %d)" % quits.size())
	else:
		_expect(quits.is_empty(), "mobil: niciun buton QUIT/EXIT (gasite %d)" % quits.size())

	# 2. Butoanele coloanei.
	var col: Array[Button] = []
	var texts: Array[String] = []
	for c in box.get_children():
		if c is Button and (c as Button).visible:
			col.append(c)
			texts.append((c as Button).text)
	if want_quit:
		if _desktop_texts.is_empty():
			_desktop_texts = texts.duplicate()
	else:
		var want: Array[String] = []
		for t in _desktop_texts:
			if not t.to_upper().contains("QUIT"):
				want.append(t)
		_expect(texts == want, "mobil: coloana = desktop fara QUIT %s" % str(texts))

	# 3. Fara gol, in ecran.
	var sep := box.get_theme_constant("separation")
	var visible_kids: Array[Control] = []
	for c in box.get_children():
		if c is Control and (c as Control).visible:
			visible_kids.append(c)
	var worst_gap := 0.0
	for i in range(1, visible_kids.size()):
		var prev := visible_kids[i - 1]
		var gap := visible_kids[i].position.y - (prev.position.y + prev.size.y)
		worst_gap = maxf(worst_gap, absf(gap - sep))
	_expect(worst_gap < 1.0, "distante egale cu separarea %d (abatere max %.1f)" % [sep, worst_gap])
	var last := visible_kids[visible_kids.size() - 1]
	_expect(last is Button and is_equal_approx(last.position.y + last.size.y, box.size.y),
		"coloana se termina cu un buton (%s)" % (last as Button).text if last is Button
		else "coloana se termina cu un buton (ultimul e %s)" % last.get_class())
	var screen := Rect2(Vector2.ZERO, sz)
	var r := box.get_global_rect()
	_expect(screen.encloses(r), "coloana in ecran %s" % str(r))

	# 4. Focus.
	var dangling := 0
	for b in col:
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			var np: NodePath = b.get_focus_neighbor(side)
			if not np.is_empty() and b.get_node_or_null(np) == null:
				dangling += 1
		var np2: NodePath = b.focus_next
		if not np2.is_empty() and b.get_node_or_null(np2) == null:
			dangling += 1
	_expect(dangling == 0, "niciun focus_neighbor spre nod lipsa (%d)" % dangling)
	var seen := {}
	var cur: Control = col[0]
	for i in range(col.size() * 2):
		if cur == null:
			break
		seen[cur] = true
		cur = cur.find_next_valid_focus()
	var missed := 0
	for b in col:
		if not seen.has(b):
			missed += 1
	_expect(missed == 0, "lantul de focus trece prin toate cele %d butoane (lipsa %d)"
		% [col.size(), missed])

	host.queue_free()
	await get_tree().process_frame

## 5. Singurul `quit(` din codul jocului e cel din meniul principal.
func _check_sources() -> void:
	print("Surse: apeluri quit( in scenes/ si scripts/")
	var files: Array[String] = []
	for root in SOURCE_ROOTS:
		_collect_gd(root, files)
	var re := RegEx.create_from_string("\\bquit\\s*\\(")
	var stray: Array[String] = []
	var allowed_hits := 0
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		var lines := text.split("\n")
		for i in lines.size():
			var line := lines[i].strip_edges()
			if line.begins_with("#"):
				continue
			if re.search(line) == null:
				continue
			if ALLOWED_QUIT_SOURCES.has(path):
				allowed_hits += 1
			else:
				stray.append("%s:%d" % [path, i + 1])
	_expect(files.size() > 50, "fisiere .gd citite: %d" % files.size())
	_expect(allowed_hits == 1, "main_menu.gd: un singur quit( (gasite %d)" % allowed_hits)
	_expect(stray.is_empty(), "nicio alta iesire din UI %s" % str(stray))

func _collect_gd(dir_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for sub in d.get_directories():
		_collect_gd(dir_path.path_join(sub), out)
