extends Node
## ID-URILE PISTELOR SUNT INGHETATE (issue #720, nov 2026).
##
## Din #690 tot ce se salveaza despre o pista e cheiat pe `TrackInfo.id`:
## recordurile (`records.cfg`), cariera (`career.cfg`, sectiuni `track:<id>`) si
## fantomele contratimpului (`ghosts/<id>.bin`). O pista FARA `.tres` in
## `scenes/tracks/info/` primeste un id dedus din numele scenei (`track25`), iar
## cheia aceea ramane pe vecie in save-urile jucatorilor: `SaveSchema` nu are
## tabela de alias-uri (alegere deliberata), deci un id schimbat dupa lansare
## lasa tot ce era salvat sub cel vechi DORMANT — recordurile dispar din joc.
##
## Contractele:
##   1. fiecare intrare din `GameState.TRACK_SCENES` (deci si fiecare pista din
##      `QuickRaceTracks.indices()`) are `scenes/tracks/info/TrackNN.tres`, cu
##      `id` NEVID citit din resursa BRUTA — nu prin `TrackInfo.for_track()`,
##      care completeaza tacut id-ul dedus si ar ascunde exact lipsa asta;
##   2. id-urile sunt unice: intre toate `.tres`-urile din folder si intre
##      liniile tabelei de mai jos (o pista scoasa din joc isi pastreaza linia,
##      ca id-ul ei sa nu fie refolosit: recordurile dormante ar invia pe alta
##      pista);
##   3. fiecare id e cel din FROZEN_IDS: o pista noua fara linie pica, un id
##      schimbat pica;
##   4. tinta fiecarei migrari v0 (`SaveSchema.V0_TRACK_IDS`) e un id din tabela.
##
## O pista noua = `.tres` cu id ales O DATA (snake_case, ca `machu_picchu`) +
## o linie la coada lui FROZEN_IDS, in acelasi PR. O linie existenta nu se
## editeaza si nu se sterge niciodata.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTrackIds.tscn

## Numele scenei -> id-ul de save. INGHETAT: se adauga doar linii noi.
const FROZEN_IDS: Dictionary = {
	"Track01": &"dunele",
	"Track08": &"okinawa_manual",
	"Track09": &"alpi", # Alpii, scoasa din joc in oct 2026: id rezervat, recordul doarme
	"Track10": &"baikal",
	"Track11": &"stromboli",
	"Track12": &"chongqing",
	"Track13": &"cappadocia",
	"Track14": &"serengeti",
	"Track15": &"machu_picchu",
	"Track16": &"fiordland",
	"Track17": &"jodhpur",
	"Track18": &"kyoto",
	"Track19": &"monument_valley",
	"Track20": &"okinawa",
	"Track21": &"transfagarasan",
	"Track22": &"halong",
	"Track23": &"carrara",
	"Track24": &"angkor",
	"Track25": &"san_francisco",
}

const PROBE_PATH := "tools/probe_track_ids.gd"

var _failed: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	print("")
	print("=== Id-urile pistelor: explicite, unice, inghetate ===")
	var launch := QuickRaceTracks.indices()
	print("-- fiecare pista din registru (%d), dintre care %d de lansare"
		% [GameState.TRACK_SCENES.size(), launch.size()])
	for index in GameState.TRACK_SCENES.size():
		_check_track(index, launch.has(index))
	_check_unique()
	_check_migration_targets()
	print("")
	if _failed:
		_print_remedy()
	print("VERDICT: %s" % ("PROBLEMA" if _failed else "OK"))
	get_tree().quit(1 if _failed else 0)


# --------------------------------------------------- 1 + 3. per pista

func _check_track(index: int, is_launch: bool) -> void:
	var key := TrackInfo.scene_key(index)
	var label := "%s (%s%s)" % [key, GameState.TRACK_NAMES[index],
		", lansare" if is_launch else ", nu e in Quick Race"]
	var path := TrackInfo.INFO_DIR + key + ".tres"
	if not FileAccess.file_exists(path):
		_check(false, "%s: lipseste %s — fara el id-ul s-ar deduce ca '%s'"
			% [label, path, key.to_lower()])
		return
	var raw_id := _raw_id(path)
	if raw_id == &"":
		_check(false, "%s: `id` gol in %s — fara el id-ul s-ar deduce ca '%s'"
			% [label, path, key.to_lower()])
		return
	if not FROZEN_IDS.has(key):
		_check(false, "%s: id '%s' fara linie in FROZEN_IDS (%s)" % [label, raw_id, PROBE_PATH])
		return
	var frozen := StringName(FROZEN_IDS[key])
	_check(raw_id == frozen, "%s: id '%s'%s" % [label, raw_id,
		"" if raw_id == frozen else " — INGHETAT e '%s'" % frozen])


## Id-ul scris in fisier, citit pe o copie proaspata: `TrackInfo.for_track()`
## scrie id-ul dedus PESTE resursa din cache cand fisierul il are gol, asa ca
## o citire prin cache dupa `QuickRaceTracks.indices()` ar vedea `track25`.
func _raw_id(path: String) -> StringName:
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var info := res as TrackInfo
	if info == null:
		return &""
	return info.id


# ------------------------------------------------------------ 2. unice

func _check_unique() -> void:
	print("-- id-uri unice (fisierele din %s + FROZEN_IDS)" % TrackInfo.INFO_DIR)
	var owner_of: Dictionary = {} # id -> numele scenei
	var dupes: Array[String] = []
	for file in DirAccess.get_files_at(TrackInfo.INFO_DIR):
		if not file.ends_with(".tres"):
			continue
		var key := file.get_basename()
		var id := _raw_id(TrackInfo.INFO_DIR + file)
		if id == &"":
			continue # semnalat la contractul 1 daca pista e in registru
		if owner_of.has(id) and owner_of[id] != key:
			dupes.append("'%s' pe %s si %s" % [id, owner_of[id], key])
		owner_of[id] = key
	for key: String in FROZEN_IDS:
		var id := StringName(FROZEN_IDS[key])
		if owner_of.has(id) and owner_of[id] != key:
			dupes.append("'%s' pe %s si %s (FROZEN_IDS)" % [id, owner_of[id], key])
		owner_of[id] = key
	_check(dupes.is_empty(), "%d id-uri, nicio dublura %s" % [owner_of.size(),
		"" if dupes.is_empty() else "— " + "; ".join(dupes)])


# ------------------------------------------------- 4. migrarile v0 -> v1

func _check_migration_targets() -> void:
	print("-- migrarea v0 (SaveSchema.V0_TRACK_IDS) duce pe id-uri din tabela")
	var known: Array = FROZEN_IDS.values()
	var lost: Array[String] = []
	for track_name: String in SaveSchema.V0_TRACK_IDS:
		var id := StringName(SaveSchema.V0_TRACK_IDS[track_name])
		if not known.has(id):
			lost.append("%s -> %s" % [track_name, id])
	_check(lost.is_empty(), "%d nume vechi, toate pe id-uri inghetate %s"
		% [SaveSchema.V0_TRACK_IDS.size(), "" if lost.is_empty() else "— " + "; ".join(lost)])


func _print_remedy() -> void:
	print("CE FACI:")
	print("  - pista NOUA: scrie scenes/tracks/info/TrackNN.tres cu `id` explicit (ales")
	print("    o data, snake_case: machu_picchu, san_francisco) si adauga linia")
	print("    \"TrackNN\": &\"<id>\" la coada lui FROZEN_IDS din %s, in acelasi PR;" % PROBE_PATH)
	print("  - id SCHIMBAT sau DUBLAT: pune inapoi id-ul din FROZEN_IDS. Nu edita tabela.")
	print("DE CE nu se schimba un id dupa lansare: recordurile (records.cfg), cariera")
	print("  (career.cfg, `track:<id>`) si fantomele (ghosts/<id>.bin) jucatorilor sunt")
	print("  cheiate pe el, iar SaveSchema NU are tabela de alias-uri. Un id nou face tot")
	print("  ce era salvat sub cel vechi DORMANT: jucatorul isi pierde recordurile pe pista.")
	print("  O pista fara .tres primeste id-ul dedus (`track25`) si il ingheata ea, in save.")
	print("")
