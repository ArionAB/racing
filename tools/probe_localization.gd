extends Node
## ProbeLocalization — garda localizarii (nov 2026). Merge HEADLESS.
##
## Rulare (ca SCENA: autoload-urile nu se rezolva cu --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLocalization.tscn
##   ... -- --sabotaj=catalog     un .po stricat in memorie: trebuie sa pice A
##   ... -- --sabotaj=scurgere    „PAUSED" scos din ja.po: trebuie sa pice B
##   ... -- --sabotaj=glife       fara Noto Sans JP in coada fonturilor: pica C
##   ... -- --sabotaj=incadrare   o traducere germana prea lunga: pica D
##   ... -- --sabotaj=limba       alegerea nu ajunge pe disc: pica E
##
## Contractele:
##   A. CATALOGUL: fiecare .po are exact multimea de msgid-uri din
##      toy_racer.pot, fara msgstr gol, fara dubluri, cu aceleasi
##      substituenti (%d, %s, {steer_left}...) ca sursa; japoneza n-are litere
##      latine in afara substituentilor (si a exceptiilor listate); nicio
##      traducere nu e la randul ei msgid al ALTUI text (s-ar traduce de doua
##      ori, prin auto-translate); Godot a citit toate intrarile si
##      project.godot le inregistreaza pe toate sase.
##   B. FARA SCURGERI: in japoneza, pe ecranele reale (meniu, cursa rapida,
##      cupa, cariera + foaia unei piste, garaj, setari, antetul creditelor,
##      incarcare, invitatia, HUD-ul cu pauza, rezultate si mesaje, cartonasele
##      turului), nicio eticheta / buton vizibil nu are 2+ litere ASCII la rand
##      in afara listei LEAK_ALLOW (fiecare intrare cu motivul ei).
##   C. GLIFE: in fiecare limba, fiecare caracter al fiecarui text vizibil are
##      glifa in lantul de fonturi al Control-ului, asa cum e livrat
##      (`Font.get_rids()`: fontul + fallback-urile lui), nu in fonturile
##      sistemului. Se verifica pe textul MODELAT (TextServer): glifa trebuie
##      sa vina dintr-un RID al lantului. Noto Sans JP e in lantul fonturilor
##      de text doar in japoneza (altfel fiecare eticheta Barlow creste in
##      inaltime si in engleza), iar lista de limbi din SETTINGS il are mereu
##      („日本語" se vede in orice limba).
##   D. INCADRARE: in fiecare limba, la 1280x720 si 1280x960 (4:3 cu
##      `canvas_items` + `expand`), niciun text nu iese din viewport (pe
##      verticala, doar listele derulabile au voie sa continue sub ecran),
##      niciun text nu e taiat (de un parinte care decupeaza, de elipsa unei
##      etichete cu clip_text, de liniile ascunse ale unei etichete cu
##      autowrap), si niciun text nu se suprapune peste un alt text sau peste
##      un obstacol (butoanele touch, bara de turbo, minimapa, vitrina 3D)
##      peste care NU statea in engleza.
##   E. LIMBA: telefonul -> limba jocului; alegerea salvata bate telefonul; un
##      cod necunoscut ramane pe disc si cade pe telefon; alegerea supravietuieste
##      save/load; randul LANGUAGE din SETTINGS (meniul principal) schimba pe loc
##      tot ecranul, fara repornire; din pauza randul lipseste.
##
## Ce NU vede D (spus deschis): textul desenat cu draw_string (litera „P" de pe
## butonul DRIFT), Label3D-urile din lume, cerneala reala a literelor (masoara
## dreptunghiurile Control-urilor, nu pixelii), aglomerarea vizuala fara
## suprapunere, elementele din popup-uri nedeschise (lista OptionButton-ului),
## starile neconstruite aici (cariera cu toate medaliile luate nu e construita) si alte formate
## decat cele trei de mai jos. Pe langa 1280x720 si 1280x960 (4:3, iPad) se
## masoara si iPhone-ul in landscape (2532x1170 -> 1558x720): canvasul e mai
## LAT, dar grilele de piste trec acolo pe patru coloane, deci cartonasele sunt
## mai INGUSTE decat la 1280x720.
## Etichetele de dezvoltare (contorul de performanta, linia de detalii a
## HUD-ului din build-ul de debug, telemetria) nu intra in B si D.
##
## Nu atinge save-ul real: setarile merg in `user://probe_tmp/localizare_<pid>/`
## (ProbeTmp), cariera e cea din TOY_RACER_SAVE_DIR (verify_local.sh) si nu se
## scrie.

const ProbeTmp := preload("res://tools/probe_tmp.gd")
const RACE_SCENE := "res://scenes/race/Race.tscn"
const MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
## Banc usor, ca la ProbeWorldCup: pista nu conteaza, conteaza HUD-ul.
const BENCH := "res://scenes/tracks/Track01.tscn"
const POT := "res://localization/toy_racer.pot"
const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1280, 960),
	Vector2i(1558, 720)]
## Sub atatea verificari verdictul pica: o garda care n-a masurat nimic nu
## spune nimic (memoria `garda-verde-pe-zero-masuratori`).
const MIN_TEXTS_PER_LOCALE := 600

## B: cuvinte latine permise in japoneza, fiecare cu motivul.
const LEAK_ALLOW := {
	"II": "butonul de pauza: doua I majuscule desenate ca simbol, nu un cuvant",
	"km": "unitatea de viteza km/h: simbol SI, la fel in japoneza",
	"TOY": "titlul TOY RACER nu se traduce (numele jocului)",
	"RACER": "titlul TOY RACER nu se traduce (numele jocului)",
	"Language": "eticheta randului de limba e bilingva („言語 / Language”), ca sa-l gasesti din orice limba",
	"SHIFT": "numele tastei din InputMap (turul pe tastatura): e scris pe tasta",
	"SPACE": "numele tastei din InputMap (turul pe tastatura): e scris pe tasta",
}
## B: texte intregi scoase din garda, dupa tipar (RegEx), cu motivul.
const LEAK_ALLOW_PATTERNS := {
	"^assets/ui/track_thumbs/": "calea imaginii lipsa pe cartonasul-placeholder (indiciu de dezvoltare, dispare cand imaginea e in repo)",
}
## A: msgstr-uri japoneze care au voie sa contina litere latine.
const JA_LATIN_OK := {
	"%.0f km/h": "simbolul SI km/h",
}
## C: caractere care vin, de dinainte de localizare, din fontul de simboluri al
## sistemului — nu depind de limba; raman semnalate aici, nu ascunse.
const GLYPH_SYSTEM_OK := {
	"⚡": "fulgerul barii de turbo din HUD (RaceHUD._charge_bolt): nici Barlow, nici Noto Sans JP nu-l au",
	"↺": "sageata butonului RESET din HUD: nici Barlow, nici Noto Sans JP n-o au",
	"✓": "bifa „asta e masina mea\" din garaj: Barlow n-o are; in japoneza vine din Noto, in rest din sistem (ca inainte de localizare)",
}

var _sabotage: String = ""
var _fails: Dictionary = {"A": [], "B": [], "C": [], "D": [], "E": []}
var _checks: Dictionary = {"A": 0, "B": 0, "C": 0, "D": 0, "E": 0}
var _texts_seen: Dictionary = {}
## D: suprapunerile din engleza, pe (ecran/stare, rezolutie) -> {pereche: true}.
var _baseline: Dictionary = {}
var _glyph_cache: Dictionary = {}
var _locale: String = "en"
var _size_tag: String = ""
var _host: Control
var _race: Race
var _tmp_dir: String = ""
var _saved: Dictionary = {}
var _re_word := RegEx.create_from_string("[A-Za-z]{2,}")
var _re_ph := RegEx.create_from_string("%[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[a-zA-Z%]|\\{[a-z_]+\\}")
var _re_latin := RegEx.create_from_string("[A-Za-z]")
var _re_cjk := RegEx.create_from_string("[\\x{3000}-\\x{9fff}\\x{ff00}-\\x{ffef}]")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	if _sabotage != "":
		print("SABOTAJ: %s (verdictul TREBUIE sa fie PROBLEMA)" % _sabotage)
	_isolate()
	_apply_sabotage()

	print("== A. catalogul")
	_check_catalog()

	print("== B/C/D. ecranele, in fiecare limba si la fiecare rezolutie")
	# Engleza INTAI: ea da suprapunerile de baza pentru D. Cursa se incarca din
	# nou in fiecare limba: in joc limba nu se schimba in cursa, iar HUD-ul isi
	# aseaza unele randuri o data, la construire, dupa inaltimea fontului (in
	# japoneza, cu Noto in lant, randurile sunt mai inalte).
	for loc in Localization.LOCALES:
		_set_locale(loc)
		await _load_race()
		for s in SIZES:
			_size_tag = "%dx%d" % [s.x, s.y]
			get_window().size = s
			await _frames(3)
			var vp := get_viewport().get_visible_rect().size
			_expect("D", vp.is_equal_approx(Vector2(s)),
				"%s: viewportul logic e %s, nu %s — garda ar masura alt ecran" % [_size_tag, vp, s])
			await _check_screens()
		get_tree().paused = false
		_race.free()
		_race = null
		await _frames(2)
	_set_locale("en")
	print("== E. limba: telefon, alegere, save, schimbare pe loc")
	await _check_language()

	_restore()
	_report()


# ------------------------------------------------------------------ utilitare

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _expect(contract: String, ok: bool, msg: String) -> void:
	_checks[contract] += 1
	if not ok:
		(_fails[contract] as Array).append(msg)


func _set_locale(loc: String) -> void:
	_locale = loc
	Localization.set_locale(loc)
	if _sabotage == "glife":
		for f: Font in [Localization.FONT_BOLD, Localization.FONT_MEDIUM,
				ThemeDB.fallback_font]:
			f.fallbacks = []
	# Noto e in lantul fonturilor de text DOAR in japoneza: altfel fiecare
	# eticheta Barlow ar creste in inaltime si in engleza (Font.get_height ia
	# maximul pe tot lantul).
	if _sabotage != "glife":
		_expect("C", (Localization.FONT_JP in Localization.FONT_BOLD.fallbacks) == (loc == "ja"),
			"%s: Noto Sans JP %s in coada lui Barlow" % [loc, "lipseste" if loc == "ja" else "e (n-ar trebui)"])


func _isolate() -> void:
	_tmp_dir = ProbeTmp.make("localizare")
	_saved = {
		"settings_path": GameState.settings_path,
		"language": GameState.language,
		"locale": TranslationServer.get_locale(),
		"selected_car": GameState.selected_car,
		"selected_driver": GameState.selected_driver,
		"selected_track": GameState.selected_track,
		"last_load_trace": GameState.last_load_trace,
		"show_perf": GameState.show_perf,
		"show_location": GameState.show_location,
		"tutorial_done": GameState.tutorial_done,
		"offered": TutorialInvite.offered,
		"persist": AiSkillSelector.persist,
		"window": get_window().size,
	}
	GameState.settings_path = _tmp_dir + "settings.cfg"
	# Ecranele ca la un jucator: fara contorul de performanta, fara telemetrie,
	# fara urma ultimei incarcari (ar aparea ca eticheta de dezvoltare).
	GameState.show_perf = false
	GameState.show_location = false
	GameState.last_load_trace = ""
	TutorialInvite.offered = true
	AiSkillSelector.persist = false
	_host = Control.new()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_host)


func _restore() -> void:
	get_tree().paused = false
	if _race != null:
		_race.queue_free()
		_race = null
	GameState.track_scene_override = ""
	GameState.ai_cars_override = []
	GameState.champ_active = false
	GameState.settings_path = _saved["settings_path"]
	GameState.language = _saved["language"]
	GameState.selected_car = _saved["selected_car"]
	GameState.selected_driver = _saved["selected_driver"]
	GameState.selected_track = _saved["selected_track"]
	GameState.last_load_trace = _saved["last_load_trace"]
	GameState.show_perf = _saved["show_perf"]
	GameState.show_location = _saved["show_location"]
	GameState.tutorial_done = _saved["tutorial_done"]
	TutorialInvite.offered = _saved["offered"]
	AiSkillSelector.persist = _saved["persist"]
	Localization.set_locale(_saved["locale"])
	get_window().size = _saved["window"]
	ProbeTmp.remove(_tmp_dir)


func _exit_tree() -> void:
	if _tmp_dir != "":
		ProbeTmp.remove(_tmp_dir)


func _apply_sabotage() -> void:
	match _sabotage:
		"scurgere":
			TranslationServer.get_translation_object("ja").erase_message("PAUSED")
		"incadrare":
			TranslationServer.get_translation_object("de").add_message("Kyoto",
				"Kyoto, die alte Kaiserstadt am Kamo")


# ================================================================ A. catalogul

## Un .po/.pot citit cu un parser PROPRIU (nu cu al lui Godot: un parser stricat
## n-are voie sa ascunda intrari si de garda). Cheia = msgctxt + \u0004 + msgid.
func _parse_po(path: String) -> Dictionary:
	var out := {"entries": {}, "order": [], "dups": [], "header": ""}
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		out["missing"] = true
		return out
	var cur: Dictionary = {}
	var field := ""
	# Fara lambda pentru „inchide intrarea": lambda-urile GDScript prind
	# variabilele locale prin valoare, deci n-ar vedea `cur` reatribuit.
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		if line == "" or line.begins_with("#"):
			if line == "":
				_flush_po(out, cur)
				cur = {}
				field = ""
			continue
		var value := ""
		var q := line.find("\"")
		if q >= 0:
			value = _unescape(line.substr(q + 1, line.length() - q - 2))
		if line.begins_with("msgctxt "):
			_flush_po(out, cur)
			cur = {"ctx": value}
			field = "ctx"
		elif line.begins_with("msgid_plural "):
			cur["plural"] = value
			field = "plural"
		elif line.begins_with("msgid "):
			if cur.has("id"):
				_flush_po(out, cur)
				cur = {}
			cur["id"] = value
			field = "id"
		elif line.begins_with("msgstr["):
			var n := line.substr(7, line.find("]") - 7).to_int()
			if not cur.has("str"):
				cur["str"] = {}
			(cur["str"] as Dictionary)[n] = value
			field = "str%d" % n
		elif line.begins_with("msgstr "):
			cur["str"] = {0: value}
			field = "str0"
		elif line.begins_with("\""):
			if field == "id" or field == "plural" or field == "ctx":
				cur[field] = String(cur[field]) + value
			elif field.begins_with("str"):
				var k := field.substr(3).to_int()
				(cur["str"] as Dictionary)[k] = String((cur["str"] as Dictionary)[k]) + value
	_flush_po(out, cur)
	return out


func _flush_po(out: Dictionary, cur: Dictionary) -> void:
	if cur.is_empty():
		return
	var key := String(cur.get("ctx", "")) + "\u0004" + String(cur.get("id", ""))
	if String(cur.get("id", "")) == "" and not cur.has("ctx"):
		out["header"] = String((cur.get("str", {}) as Dictionary).get(0, ""))
	elif (out["entries"] as Dictionary).has(key):
		(out["dups"] as Array).append(String(cur.get("id", "")))
	else:
		(out["entries"] as Dictionary)[key] = cur
		(out["order"] as Array).append(key)


func _unescape(s: String) -> String:
	return s.replace("\\\\", "\u0001").replace("\\n", "\n").replace("\\t", "\t") \
		.replace("\\\"", "\"").replace("\u0001", "\\")


func _placeholders(s: String) -> Array:
	var out := []
	for m in _re_ph.search_all(s):
		out.append(m.get_string())
	out.sort()
	return out


func _nplurals(header: String) -> int:
	var i := header.find("nplurals=")
	return header.substr(i + 9, 2).to_int() if i >= 0 else 2


func _check_catalog() -> void:
	var pot := _parse_po(POT)
	_expect("A", not pot.has("missing"), "lipseste " + POT)
	var keys: Array = pot["order"]
	_expect("A", keys.size() >= 200, "POT-ul are doar %d intrari" % keys.size())
	_expect("A", (pot["dups"] as Array).is_empty(), "POT: dubluri %s" % [pot["dups"]])
	var pos := {}
	for loc in Localization.LOCALES:
		if loc == "en":
			continue
		pos[loc] = _parse_po("%s%s.po" % [Localization.PO_DIR, loc])
	if _sabotage == "catalog":
		var es: Dictionary = (pos["es"] as Dictionary)["entries"]
		(es[keys[0]]["str"] as Dictionary)[0] = ""
		var de: Dictionary = (pos["de"] as Dictionary)["entries"]
		var lap_key: String = "\u0004LAP %d/%d"
		(de[lap_key]["str"] as Dictionary)[0] = "RUNDE %s/%d"
		((pos["fr"] as Dictionary)["entries"] as Dictionary)["\u0004INTRUS"] = {"id": "INTRUS", "str": {0: "INTRUS"}}
		((pos["it"] as Dictionary)["dups"] as Array).append("GARAGE")
	var pot_entries: Dictionary = pot["entries"]
	var registered: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray())
	for loc: String in pos:
		var po: Dictionary = pos[loc]
		var path := "%s%s.po" % [Localization.PO_DIR, loc]
		_expect("A", not po.has("missing"), "lipseste " + path)
		_expect("A", path in registered, "%s nu e in project.godot (locale/translations)" % path)
		_expect("A", ("Language: %s" % loc) in String(po["header"]),
			"%s: antetul nu spune Language: %s" % [path, loc])
		var n := _nplurals(String(po["header"]))
		var entries: Dictionary = po["entries"]
		_expect("A", (po["dups"] as Array).is_empty(), "%s: dubluri %s" % [loc, po["dups"]])
		for k in keys:
			_expect("A", entries.has(k), "%s: lipseste msgid \"%s\"" % [loc, String(k).get_slice("\u0004", 1)])
		for k in entries:
			_expect("A", pot_entries.has(k), "%s: msgid \"%s\" nu e in POT" % [loc, String(k).get_slice("\u0004", 1)])
			if not pot_entries.has(k):
				continue
			var src: Dictionary = pot_entries[k]
			var e: Dictionary = entries[k]
			var plural := src.has("plural")
			_expect("A", plural == e.has("plural"), "%s: \"%s\" plural in POT=%s, in .po=%s" % [loc, src["id"], plural, e.has("plural")])
			var forms: Dictionary = e.get("str", {})
			var want := n if plural else 1
			_expect("A", forms.size() == want, "%s: \"%s\" are %d forme, nu %d" % [loc, src["id"], forms.size(), want])
			var ph := _placeholders(String(src["id"]))
			if plural:
				_expect("A", _placeholders(String(src["plural"])) == ph,
					"POT: \"%s\" si pluralul au substituenti diferiti" % src["id"])
			for f in forms:
				var s := String(forms[f])
				_expect("A", s.strip_edges() != "", "%s: \"%s\" n-are traducere (forma %d)" % [loc, src["id"], f])
				_expect("A", _placeholders(s) == ph, "%s: \"%s\" -> \"%s\": substituenti %s, sursa %s" % [
					loc, src["id"], s, _placeholders(s), ph])
				if loc == "ja" and not JA_LATIN_OK.has(String(src["id"])):
					var bare := _re_ph.sub(s, "", true)
					_expect("A", _re_latin.search(bare) == null,
						"ja: \"%s\" -> \"%s\" are litere latine" % [src["id"], s])
				elif loc != "ja":
					_expect("A", _re_cjk.search(s) == null,
						"%s: \"%s\" -> \"%s\" are caractere japoneze" % [loc, src["id"], s])
		# Dubla traducere: auto-translate-ul unui Control ar traduce din nou un
		# text deja tradus daca traducerea e, la randul ei, msgid al altui text.
		for k in entries:
			var e: Dictionary = entries[k]
			var s := String((e.get("str", {}) as Dictionary).get(0, ""))
			var other := "\u0004" + s
			if s != "" and other != k and entries.has(other):
				var s2 := String(((entries[other] as Dictionary).get("str", {}) as Dictionary).get(0, ""))
				_expect("A", s2 == s, "%s: \"%s\" -> \"%s\", care e msgid tradus \"%s\" (s-ar traduce de doua ori)" % [
					loc, String(e["id"]), s, s2])
		# Godot a citit tot (un escape gresit ar pierde intrari fara eroare).
		var tro := TranslationServer.get_translation_object(loc)
		_expect("A", tro != null and tro.locale == loc, "%s: TranslationServer nu are traducerea" % loc)
		if tro != null:
			_expect("A", tro.get_message_count() == keys.size(), "%s: Godot a citit %d mesaje, POT-ul are %d" % [
				loc, tro.get_message_count(), keys.size()])
	_expect("A", registered.size() == pos.size(), "project.godot inregistreaza %d traduceri, nu %d" % [
		registered.size(), pos.size()])
	print("  POT: %d msgid-uri; %d .po" % [keys.size(), pos.size()])


# ======================================================= B/C/D. ecranele

func _load_race() -> void:
	GameState.track_scene_override = BENCH
	GameState.champ_active = false
	GameState.tutorial_run = false
	GameState.selected_track = TrackInfo.index_of_id(&"kyoto")
	# Numele cele mai lungi pe grila (rezultatele): Tow Truck la jucator,
	# Ambulance, Monster, Fire Truck, Hot rod, Bus la adversari.
	GameState.selected_car = _car_index(&"tow_truck")
	GameState.ai_cars_override = [_car_index(&"ambulance"), _car_index(&"monster"),
		_car_index(&"firetruck"), _car_index(&"hotrod"), _car_index(&"bus")]
	var t0 := Time.get_ticks_msec()
	_race = (load(RACE_SCENE) as PackedScene).instantiate() as Race
	# Sonda e PROCESS_MODE_ALWAYS, iar copiii mostenesc: fara asta cursa ar
	# merge si „in pauza" (numaratoarea, ceasul de offroad) peste starile de aici.
	_race.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_race)
	# Pauza IMEDIAT: numaratoarea cursei nu are voie sa scrie peste starile
	# construite aici (HUD-ul merge si in pauza).
	get_tree().paused = true
	await _frames(3)
	print("  cursa incarcata in %.1f s (%s)" % [(Time.get_ticks_msec() - t0) / 1000.0, _locale])
	# Cursa sta pe loc (HUD-ul ruleaza si in pauza); urma incarcarii se inchide,
	# ca SETTINGS din joc sa nu arate o incarcare „neterminata".
	get_tree().paused = true
	GameState.load_trace_end()
	print("  cursa: %d masini, pista %s" % [_race.cars.size(), BENCH])


func _car_index(id: StringName) -> int:
	for i in GameState.CAR_DATA.size():
		if (GameState.CAR_DATA[i] as CarData).id == id:
			return i
	return 0


func _check_screens() -> void:
	var tag := "%s %s" % [_locale, _size_tag]
	var before := int(_texts_seen.get(_locale, 0))
	var t0 := Time.get_ticks_msec()

	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as Control
	_host.add_child(menu)
	await _inspect("meniu", menu)
	menu.free()

	var invite := TutorialInvite.new()
	_host.add_child(invite)
	await _inspect("invitatie", invite)
	invite.free()

	var quick := TrackSelectPanel.new()
	_host.add_child(quick)
	await _inspect("cursa_rapida", quick)
	quick.free()

	var cup := WorldCupPanel.new()
	_host.add_child(cup)
	await _inspect("cupa", cup)
	cup.free()

	var career := CareerPanel.new()
	_host.add_child(career)
	await _inspect("cariera", career)
	career.call("_open_sheet", &"monument_valley")
	await _inspect("cariera/foaie", career.get("_sheet") as Control)
	career.free()

	var garage := GaragePanel.new()
	_host.add_child(garage)
	var preview := garage.get("_preview") as Control
	for i in GameState.CAR_DATA.size():
		garage.call("_show", i)
		await _inspect("garaj/masina%d" % i, garage, [["vitrina", preview]])
	for d in GameState.DRIVER_DATA.size():
		garage.call("_show_driver", d)
		await _inspect("garaj/sofer%d" % d, garage, [["vitrina", preview]])
	garage.free()

	var settings := SettingsPanel.new()
	_host.add_child(settings)
	await _inspect("setari", settings)
	# Lista de limbi: fiecare nume in scrisul lui, in orice limba a jocului.
	var lang := settings.find_child("LanguageChoice", true, false) as OptionButton
	_expect("C", lang != null, "SETTINGS n-are randul LANGUAGE")
	if lang != null:
		for i in lang.item_count:
			for f: Font in [lang.get_theme_font("font"), lang.get_popup().get_theme_font("font")]:
				var miss := _missing_glyphs(f, 20, lang.get_item_text(i))
				_expect("C", miss == "", "%s %s: lista de limbi, \"%s\" fara glifa: %s" % [
					_locale, _size_tag, lang.get_item_text(i), miss])
	settings.free()

	var credits := CreditsPanel.new()
	_host.add_child(credits)
	await _inspect("credite", credits, [], [], [credits.get("_content")])
	credits.free()

	for idx in QuickRaceTracks.indices():
		var loading := LoadingScreen.new()
		loading.track_index = idx
		_host.add_child(loading)
		await _inspect("incarcare/%s" % TrackInfo.for_track(idx).id, loading)
		if idx == QuickRaceTracks.indices()[0]:
			var tip := _find_label_with(loading, LoadingScreen.TIPS)
			for k in LoadingScreen.TIPS.size():
				if tip != null:
					tip.text = LoadingScreen.TIPS[k]
				await _inspect("incarcare/sfat%d" % k, loading)
		loading.free()

	await _check_hud()

	var n := int(_texts_seen.get(_locale, 0)) - before
	print("  %s: %d texte verificate (%.1f s)" % [tag, n, (Time.get_ticks_msec() - t0) / 1000.0])


func _find_label_with(root: Node, texts: Array) -> Label:
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).text in texts:
			return l as Label
	return null


## HUD-ul cursei reale: telemetria, eticheta de mod, mesajele, pauza (si
## setarile din pauza), rezultatele in toate variantele, cartonasele turului.
func _check_hud() -> void:
	var hud := _race.hud
	var tc := hud.touch_controls()
	var obstacles := func() -> Array:
		var out := []
		for z in ["left", "right", "gas", "brake", "turbo", "drift"]:
			var r := tc.button_disc(z)
			out.append(["touch_" + z, Rect2(tc.global_position + r.position, r.size)])
		out.append(["bara_turbo", hud.turbo_bar_rect()])
		out.append(["minimapa", (hud.get("_minimap") as Control).get_global_rect()])
		return out
	var dev: Array = [hud.get("_perf"), hud.get("_detail_label")]
	# Telemetria + toate etichetele de mod odata (cel mai incarcat HUD).
	hud.set_info(6, 6, 3, 3, 188.0, "1:23.4", "1:21.9")
	hud.set_ghost_time(83456)
	hud.set_sealed_turbo(true)
	hud.set_bonus(Career.config.bonus_title)
	# Numaratoarea: cu ce se vede pe grila (telemetria, linia de mod), nu cu
	# ceasul de offroad sau contrasensul, care pe grila nu pot aparea.
	hud.show_countdown("READY?")
	await _inspect("hud/numaratoare", hud, obstacles.call(), dev)
	hud.show_countdown("GO!")
	await _inspect("hud/go", hud, obstacles.call(), dev)
	hud.show_countdown("")
	# In cursa: offroad + contrasens + popup-ul de depasire odata (cel mai
	# incarcat centru de ecran).
	hud.set_offroad_clock(2.5)
	hud.set_wrong_way(true)
	hud.position_popup.show_change(3, 4)
	await _inspect("hud/cursa", hud, obstacles.call(), dev)
	hud.set_wrong_way(false)
	hud.set_offroad_clock(-1.0)
	hud.set_sealed_turbo(false)
	hud.set_ghost_time(0)
	# Mesajele: cele legate de semnalele masinii trec prin codul real din Race.
	var player := _race.player
	var dummy := Node3D.new()
	_race.add_child(dummy)
	var flashes: Array[Callable] = [
		func() -> void: player.respawned.emit(player),
		func() -> void: player.steer_inverted.emit(1.0),
		func() -> void: player.ignited.emit(player, 1.0),
		func() -> void: player.ejected.emit(player, dummy),
		func() -> void: hud.flash_message("ROCKET START!"),
		func() -> void: hud.flash_message("Too early..."),
		func() -> void: hud.flash_message(Race.eject_flash_text(true)),
		func() -> void: hud.flash_message(Race.respawn_flash_text(true)),
		func() -> void: hud.flash_message(tr("NEW LAP RECORD! %s") % "1:21.9"),
	]
	for i in flashes.size():
		flashes[i].call()
		await _inspect("hud/mesaj%d" % i, hud, obstacles.call(), dev)
	dummy.queue_free()
	# Bonusul carierei (NO RETRY), pierdut: eticheta rosie de pe linia de
	# deasupra barii (cea verde e deja in toate starile de mai sus).
	hud.set_bonus_lost()
	await _inspect("hud/bonus_pierdut", hud, obstacles.call(), dev)

	# Pauza si setarile din pauza (fara randul de limba).
	# Mesajele de mai sus se sting in 1,7 s; aici starile vin la doua cadre,
	# deci ultimul mesaj s-ar vedea si peste pauza (in joc, nu).
	hud.flash_message("")
	hud.position_popup.hide_now()
	# Aceeasi cursa trece prin toate formatele, iar `_finish_race` (mai jos) o
	# incuie (RaceHUD.lock_pause, #757): fara deblocare, de la al doilea format
	# pauza nu se mai deschide si HUD-ul ramane sub setari.
	hud.set("_pause_locked", false)
	hud.call("_open_pause")
	await _inspect("hud/pauza", hud, [], dev)
	var pause_settings := hud.get("_settings") as SettingsPanel
	(hud.get("_pause_panel") as Control).visible = false
	pause_settings.visible = true
	await _inspect("hud/pauza_setari", hud, [], dev)
	if _locale == "en" and _size_tag == "1280x720":
		_expect("E", pause_settings.find_child("LanguageChoice", true, false) == null,
			"setarile din pauza au randul LANGUAGE (trebuia ascuns)")
	hud.call("_close_pause")
	get_tree().paused = true
	# Cadrul fara pauza a lasat numaratoarea cursei sa scrie o cifra.
	hud.show_countdown("")

	# Rezultatele: cursa rapida (cu sosirea reala si mesajul FINISH)...
	GameState.champ_active = false
	_race.call("_finish_race")
	await _inspect("hud/sosire", hud, obstacles.call(), dev)
	# In joc rezultatele vin la 1,5 s dupa mesajul de sosire, cand acesta deja
	# se stinge (dispare la 1,7 s); aici nu se asteapta, deci se sterge de mana.
	hud.flash_message("")
	_race.set("_race_record_new", true)
	_race.call("_show_results")
	await _inspect("hud/rezultate", hud, [], dev)
	# ...cupa (titlul cu cupa si cursa)...
	GameState.champ_active = true
	GameState.champ_cup = GameState.WORLD_CUPS[2] as WorldCup
	GameState.champ_round = 1
	GameState.champ_points.resize(_race.cars.size())
	for i in GameState.champ_points.size():
		GameState.champ_points[i] = 1 if i == 0 else 7 * i
	_race.call("_show_results")
	await _inspect("hud/rezultate_cupa", hud, [], dev)
	_race.call("_show_champion")
	await _inspect("hud/campion", hud, [], dev)
	_race.set("_champion_shown", false)
	GameState.champ_active = false
	# ...contratimpul (titlu + tintele) si cariera (locul, bonusul, punctele).
	_race.set("_career_medal", Career.MEDAL_SILVER)
	_race.set("_ghost_saved", true)
	var rows: Array[Dictionary] = []
	_race.call("_append_time_trial_targets", rows)
	hud.show_results(String(_race.call("_time_trial_title")), rows, "BACK TO CAREER")
	await _inspect("hud/contratimp", hud, [], dev)
	_race.set("_career_points", 4)
	var no_rows: Array[Dictionary] = []
	# Cu bonusul pastrat si pierdut (randul punctelor ia ambele forme).
	var bonus_stub := BonusTracker.new()
	_race.set("_bonus_tracker", bonus_stub)
	for kept in [true, false]:
		_race.set("_bonus_kept", kept)
		hud.show_results(tr("RESULTS — %s") % String(_race.call("_track_title")) + "\n"
			+ String(_race.call("_career_points_text")), no_rows, "BACK TO CAREER")
		await _inspect("hud/cariera_bonus_%s" % ("pastrat" if kept else "pierdut"),
			hud, [], dev)
	_race.set("_bonus_tracker", null)
	bonus_stub.free()
	# Cu masini castigate in cursa (randul NEW CAR, cele mai lungi nume).
	hud.show_results(String(_race.call("_career_points_text")), no_rows, "BACK TO CAREER",
		Race.new_cars_text([&"tow_truck", &"ambulance"]))
	await _inspect("hud/cariera_masina_noua", hud, [], dev)
	(hud.get("_results_panel") as Control).visible = false

	# Cartonasele turului, peste acelasi HUD, pe touch si pe tastatura.
	var cfg := TutorialDirector.DEFAULT_CONFIG
	var ov := TutorialOverlay.new()
	ov.config = cfg
	hud.add_tutorial_overlay(ov)
	ov.bind(tc, hud.turbo_bar_rect)
	var steps: Array[StringName] = [TutorialDirector.STEP_INTRO]
	steps.append_array(cfg.steps)
	steps.append(TutorialDirector.STEP_DONE)
	for mode in [true, false]:
		ov.touch_mode = mode
		for step in steps:
			if step == TutorialDirector.STEP_DONE:
				ov.show_done()
			else:
				var sub := cfg.drift_sub_speed if step == &"drift" \
					else (cfg.turbo_sub_empty if step == &"turbo" else "")
				ov.show_step(step, 1, cfg.steps.size(), 0.5, sub, false)
			await _inspect("tur/%s_%s" % [step, "touch" if mode else "taste"], hud,
				obstacles.call(), dev)
	ov.free()


## Toate verificarile pe un ecran deja construit. `obstacles`: [[nume, Rect2 |
## Control]]; `dev`: etichete de dezvoltare (scoase din B si D, nu si din C);
## `english_body`: textul care ramane in engleza in orice limba, cu buna stiinta
## (corpul creditelor: scos doar din B).
func _inspect(screen: String, root: Node, obstacles: Array = [], dev: Array = [],
		english_body: Array = []) -> void:
	await _frames(2)
	var all := _collect(root)
	var texts: Array[Control] = []
	for c in all:
		# --- C: pe tot ce se vede, inclusiv etichetele de dezvoltare.
		_check_glyphs("%s %s %s" % [_locale, _size_tag, screen], c, _shown(c))
		if not _is_under(c, dev):
			texts.append(c)
	_texts_seen[_locale] = int(_texts_seen.get(_locale, 0)) + all.size()
	var tag := "%s %s %s" % [_locale, _size_tag, screen]
	var view := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var rects: Array[Rect2] = []
	var paths: Array[String] = []
	for c in texts:
		rects.append(_ink_rect(c))
		paths.append(_index_path(root, c))
	for i in texts.size():
		var c := texts[i]
		var shown := _shown(c)
		# --- B
		if _locale == "ja" and not _is_under(c, english_body):
			_check_leak(tag, c, shown)
		# --- D: viewport si decupare
		var r := rects[i]
		var scroll := _scroll_ancestor(c)
		var inside_x := r.position.x >= view.position.x - 1.0 and r.end.x <= view.end.x + 1.0
		var inside_y := r.position.y >= view.position.y - 1.0 and r.end.y <= view.end.y + 1.0
		# Pe axa pe care lista se deruleaza, ce e in afara ecranului se aduce
		# cu degetul (cartonasele garajului: orizontal; restul: vertical).
		if scroll != null:
			inside_x = inside_x or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
			inside_y = inside_y or scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
		_expect("D", inside_x and inside_y,
			"%s: \"%s\" iese din ecran %s" % [tag, _short(shown), r])
		var cut := _cut_by(c, r)
		_expect("D", cut == "", "%s: \"%s\" e taiat (%s)" % [tag, _short(shown), cut])
	# --- D: suprapuneri noi fata de engleza
	# Cu partea care chiar se deseneaza: un rand de lista derulat sub fereastra
	# listei e decupat, nu acopera butonul de sub lista.
	var vis: Array[Rect2] = []
	for i in texts.size():
		vis.append(_visible_part(texts[i], rects[i]))
	var pairs := {}
	for i in texts.size():
		for j in range(i + 1, texts.size()):
			if texts[i].is_ancestor_of(texts[j]) or texts[j].is_ancestor_of(texts[i]):
				continue
			if vis[i].intersection(vis[j]).get_area() > 4.0:
				pairs["%s | %s" % [paths[i], paths[j]]] = [texts[i], texts[j]]
		for o in obstacles:
			var orect: Rect2 = o[1] if o[1] is Rect2 else (o[1] as Control).get_global_rect()
			if vis[i].intersection(orect).get_area() > 4.0:
				pairs["%s | %s" % [paths[i], o[0]]] = [texts[i], o[0]]
	var key := "%s@%s" % [screen, _size_tag]
	if _locale == "en":
		_baseline[key] = pairs
	else:
		var base: Dictionary = _baseline.get(key, {})
		for p in pairs:
			var a: Control = pairs[p][0]
			var b: Variant = pairs[p][1]
			var bname := _short(_shown(b)) if b is Control else String(b)
			_expect("D", base.has(p), "%s: \"%s\" se suprapune peste \"%s\" (in engleza nu)" % [
				tag, _short(_shown(a)), bname])


func _collect(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	var all: Array[Node] = [root]
	all.append_array(root.find_children("*", "", true, false))
	for n in all:
		var c := n as Control
		if c == null or not c.is_visible_in_tree() or _alpha(c) < 0.05:
			continue
		if (c is Label or c is Button) and _shown(c) != "":
			out.append(c)
	return out


## Unde se deseneaza textul. La o eticheta fara autowrap, dreptunghiul literelor
## (dupa aliniere), nu al Control-ului: un Control nu se mai strange cand textul
## i se scurteaza, deci eticheta de mesaj a HUD-ului poarta latimea celui mai
## lung mesaj de pana atunci — iar o suprapunere a acelui spatiu gol nu e o
## suprapunere de text. La butoane si la etichetele cu autowrap, tot Control-ul.
func _ink_rect(c: Control) -> Rect2:
	var r := c.get_global_rect()
	var l := c as Label
	if l == null or l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.clip_text:
		return r
	var font := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var lines := _shown(l).split("\n")
	var w := 0.0
	for line in lines:
		w = maxf(w, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var scale := r.size / l.size if l.size.x > 0.0 and l.size.y > 0.0 else Vector2.ONE
	w *= scale.x
	var h := (font.get_height(fs) * lines.size()
		+ l.get_theme_constant("line_spacing") * (lines.size() - 1)) * scale.y
	var ax := [0.0, 0.5, 1.0, 0.0][l.horizontal_alignment] as float
	var ay := [0.0, 0.5, 1.0, 0.0][l.vertical_alignment] as float
	return Rect2(r.position + Vector2((r.size.x - w) * ax, (r.size.y - h) * ay),
		Vector2(minf(w, r.size.x), minf(h, r.size.y)))


## `r` taiat de fiecare parinte care decupeaza (gol daca nu se vede deloc).
func _visible_part(c: Control, r: Rect2) -> Rect2:
	var n := c.get_parent()
	while n != null:
		var a := n as Control
		if a != null and (a.clip_contents or a.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED):
			r = r.intersection(a.get_global_rect())
		n = n.get_parent()
	return r


## Opacitatea efectiva: un mesaj stins de tween ramane `visible`, dar nu se vede.
func _alpha(c: CanvasItem) -> float:
	var a := c.self_modulate.a
	var n: Node = c
	while n != null:
		if n is CanvasItem:
			a *= (n as CanvasItem).modulate.a
		n = n.get_parent()
	return a


## Textul de pe ecran: cel tradus automat, daca Control-ul se traduce singur.
func _shown(c: Control) -> String:
	var raw := (c as Label).text if c is Label else (c as Button).text
	return c.atr(raw)


func _short(s: String) -> String:
	s = s.replace("\n", " / ")
	return s if s.length() <= 60 else s.left(57) + "..."


func _index_path(root: Node, n: Node) -> String:
	var parts: PackedStringArray = []
	while n != null and n != root:
		parts.append(str(n.get_index()))
		n = n.get_parent()
	parts.reverse()
	return "/".join(parts)


## `c` e unul din `nodes` sau sta sub unul din ele (telemetria e mereu unealta).
func _is_under(c: Node, nodes: Array) -> bool:
	var n := c
	while n != null:
		if n in nodes or n is LocationTelemetry:
			return true
		n = n.get_parent()
	return false


func _scroll_ancestor(c: Node) -> ScrollContainer:
	var n := c.get_parent()
	while n != null:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null


# ------------------------------------------------------------------ B
func _check_leak(tag: String, c: Control, shown: String) -> void:
	for pat in LEAK_ALLOW_PATTERNS:
		if RegEx.create_from_string(pat).search(shown) != null:
			return
	var bad: PackedStringArray = []
	for m in _re_word.search_all(shown):
		if not LEAK_ALLOW.has(m.get_string()):
			bad.append(m.get_string())
	_expect("B", bad.is_empty(), "%s: \"%s\" are text latin %s (%s)" % [
		tag, _short(shown), ",".join(bad), c.get_class()])


# ------------------------------------------------------------------ C
func _check_glyphs(tag: String, c: Control, shown: String) -> void:
	var font := c.get_theme_font("font")
	var size := c.get_theme_font_size("font_size")
	var ck := "%d|%d|%s" % [font.get_instance_id(), size, shown]
	var missing: String
	if _glyph_cache.has(ck):
		missing = _glyph_cache[ck]
	else:
		missing = _missing_glyphs(font, size, shown)
		_glyph_cache[ck] = missing
	_expect("C", missing == "", "%s: \"%s\" — fara glifa in lantul de fonturi: %s" % [
		tag, _short(shown), missing])


func _missing_glyphs(font: Font, size: int, text: String) -> String:
	var rids := font.get_rids()
	var ts := TextServerManager.get_primary_interface()
	var out := ""
	for line in text.split("\n"):
		if line == "":
			continue
		var tl := TextLine.new()
		tl.add_string(line, font, size)
		for g: Dictionary in ts.shaped_text_get_glyphs(tl.get_rid()):
			var ch := line.substr(int(g["start"]), int(g["end"]) - int(g["start"]))
			if ch.strip_edges() == "" or GLYPH_SYSTEM_OK.has(ch):
				continue
			if not rids.has(g["font_rid"]) and not (ch in out):
				out += ch
	return out


# ------------------------------------------------------------------ D
## De ce e taiat textul, sau "" daca nu e.
func _cut_by(c: Control, r: Rect2) -> String:
	var shown := _shown(c)
	var font := c.get_theme_font("font")
	var size := c.get_theme_font_size("font_size")
	if c is Label:
		var l := c as Label
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			if l.get_line_count() > l.get_visible_line_count():
				return "%d randuri, se vad %d" % [l.get_line_count(), l.get_visible_line_count()]
		elif l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			for line in shown.split("\n"):
				var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				if w > l.size.x + 0.5:
					return "latime %.0f > %.0f" % [w, l.size.x]
	elif c is Button:
		var b := c as Button
		if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
			var room := b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x
			for line in shown.split("\n"):
				var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				if w > room + 0.5:
					return "latime %.0f > %.0f" % [w, room]
	# Un parinte care decupeaza (clip_contents / clip_children). Listele
	# derulabile decupeaza doar pe orizontala: pe verticala, randurile de sub
	# fereastra se ajung derulind.
	var n := c.get_parent()
	while n != null:
		var a := n as Control
		if a != null and (a.clip_contents or a.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED):
			var ar := a.get_global_rect().grow(1.0)
			if a is ScrollContainer:
				var sc := a as ScrollContainer
				if sc.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
						and (r.position.x < ar.position.x or r.end.x > ar.end.x):
					return "iese lateral din lista %s" % ar
				if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED \
						and (r.position.y < ar.position.y or r.end.y > ar.end.y):
					return "iese pe verticala din lista %s" % ar
			elif not ar.encloses(r):
				return "decupat de %s %s" % [a.get_class(), ar]
		n = n.get_parent()
	return ""


# ======================================================== E. limba

func _check_language() -> void:
	# 1. Telefonul -> limba jocului.
	var device := {
		"es_ES": "es", "es_419": "es", "es": "es", "pt_BR": "pt_BR", "pt_PT": "pt_BR",
		"de_DE": "de", "de_AT": "de", "fr_FR": "fr", "fr_CA": "fr", "it_IT": "it",
		"ja_JP": "ja", "ja": "ja", "en_US": "en", "en_GB": "en", "ro_RO": "en",
		"zh_CN": "en", "ko_KR": "en", "": "en", "pt-BR": "pt_BR",
	}
	for d in device:
		var got := Localization.from_device(d)
		_expect("E", got == device[d], "telefon %s -> %s, trebuia %s" % [d, got, device[d]])
	# 2. Alegerea salvata bate telefonul; un cod necunoscut cade pe telefon.
	_expect("E", Localization.resolve("de", "ja_JP") == "de", "alegerea de bate telefonul ja_JP")
	_expect("E", Localization.resolve("", "ja_JP") == "ja", "AUTO + telefon ja_JP -> ja")
	_expect("E", Localization.resolve("ko", "fr_FR") == "fr", "cod necunoscut ko + telefon fr_FR -> fr")
	for loc in Localization.LOCALES:
		_expect("E", Localization.resolve(loc, "ro_RO") == loc, "alegerea %s se pastreaza" % loc)
		_expect("E", Localization.NATIVE_NAMES.has(loc), "%s n-are nume nativ" % loc)

	# 3. Save / load.
	for choice in ["it", "pt_BR", "", "ko"]:
		GameState.language = choice
		GameState.save_settings()
		if _sabotage == "limba":
			var cfg := ConfigFile.new()
			cfg.load(GameState.settings_path)
			cfg.erase_section_key("game", "language")
			cfg.save(GameState.settings_path)
		GameState.language = "xx_garbage"
		GameState.load_settings()
		_expect("E", GameState.language == choice,
			"alegerea \"%s\" dupa save/load e \"%s\"" % [choice, GameState.language])
		GameState.save_settings()
		var cfg2 := ConfigFile.new()
		cfg2.load(GameState.settings_path)
		_expect("E", String(cfg2.get_value("game", "language", "<lipsa>")) == choice,
			"pe disc [game] language = %s, nu %s" % [cfg2.get_value("game", "language", "<lipsa>"), choice])
	GameState.language = ""

	# 4. Schimbarea pe loc, din SETTINGS-ul meniului principal.
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as Control
	_host.add_child(menu)
	await _frames(2)
	var settings := _first(menu, "SettingsPanel") as SettingsPanel
	menu.call("_show_panel", settings)
	await _frames(2)
	var choice := settings.find_child("LanguageChoice", true, false) as OptionButton
	_expect("E", choice != null, "SETTINGS din meniu n-are randul LANGUAGE")
	if choice == null:
		menu.free()
		return
	_expect("E", choice.selected == 0 and choice.get_item_text(0) == "AUTO",
		"in engleza, cu alegerea goala, randul arata AUTO (%d, %s)" % [choice.selected, choice.get_item_text(0)])
	for i in Localization.LOCALES.size():
		_expect("E", choice.get_item_text(i + 1) == Localization.NATIVE_NAMES[Localization.LOCALES[i]],
			"elementul %d e \"%s\", nu numele nativ" % [i + 1, choice.get_item_text(i + 1)])
	var ja := Localization.LOCALES.find("ja") + 1
	choice.select(ja)
	choice.item_selected.emit(ja)
	await _frames(4)
	_expect("E", not is_instance_valid(menu) or menu.is_queued_for_deletion() or menu.get_parent() == null,
		"meniul vechi a ramas dupa schimbarea limbii")
	var fresh := _host.get_child(_host.get_child_count() - 1) as Control
	var fresh_settings := _first(fresh, "SettingsPanel") as SettingsPanel
	_expect("E", TranslationServer.get_locale() == "ja", "limba e %s, nu ja" % TranslationServer.get_locale())
	_expect("E", GameState.language == "ja", "GameState.language e %s" % GameState.language)
	var disk := ConfigFile.new()
	disk.load(GameState.settings_path)
	_expect("E", String(disk.get_value("game", "language", "")) == "ja", "alegerea ja nu e pe disc")
	_expect("E", fresh_settings != null and fresh_settings.visible,
		"dupa schimbare, meniul nou nu e pe SETTINGS")
	if fresh_settings != null:
		# Tot ce se vede acum e in japoneza (B, pe meniul reconstruit).
		_locale = "ja"
		_size_tag = "%dx%d" % [get_window().size.x, get_window().size.y]
		var leaks_before := (_fails["B"] as Array).size()
		for c in _collect(fresh):
			_check_leak("ja schimbare-pe-loc", c, _shown(c))
		_expect("E", (_fails["B"] as Array).size() == leaks_before,
			"dupa schimbarea pe loc au ramas texte in engleza (vezi B)")
		var back := fresh_settings.find_child("LanguageChoice", true, false) as OptionButton
		_expect("E", back != null and back.selected == ja and back.text == "日本語",
			"randul arata limba aleasa (%s)" % (back.text if back != null else "?"))
		var label := (back.get_parent() as Node).get_child(0) as Label if back != null else null
		_expect("E", label != null and label.text == "言語 / Language",
			"eticheta randului in japoneza e bilingva (%s)" % (label.text if label != null else "?"))
		# Inapoi la AUTO (telefonul probei nu e japonez => engleza sau alta).
		back.select(0)
		back.item_selected.emit(0)
		await _frames(4)
	_expect("E", GameState.language == "" and TranslationServer.get_locale() == Localization.from_device(OS.get_locale()),
		"AUTO readuce limba telefonului (%s), nu %s" % [Localization.from_device(OS.get_locale()), TranslationServer.get_locale()])
	for n in _host.get_children():
		n.free()
	_set_locale("en")


func _first(root: Node, cls: String) -> Node:
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and (n.get_script() as Script).get_global_name() == cls:
			return n
	return null


# ================================================================== verdict

func _report() -> void:
	print("")
	var total := 0
	# `--toate`: fiecare esec, nu doar primele 25 pe contract.
	var shown := 1000000 if "--toate" in OS.get_cmdline_user_args() else 25
	for k in ["A", "B", "C", "D", "E"]:
		var fails: Array = _fails[k]
		total += fails.size()
		print("%s: %d verificari, %d esecuri" % [k, _checks[k], fails.size()])
		for i in mini(fails.size(), shown):
			print("  PICA %s: %s" % [k, fails[i]])
		if fails.size() > shown:
			print("  ... si inca %d" % (fails.size() - shown))
	for loc in Localization.LOCALES:
		var n := int(_texts_seen.get(loc, 0))
		var ok := n >= MIN_TEXTS_PER_LOCALE
		if not ok:
			total += 1
		print("texte verificate in %s: %d%s" % [loc, n, "" if ok else " — PREA PUTINE (garda oarba?)"])
	print("")
	print("VERDICT: %s" % ("OK" if total == 0 else "PROBLEMA (%d esecuri)" % total))
	get_tree().quit(0 if total == 0 else 1)
