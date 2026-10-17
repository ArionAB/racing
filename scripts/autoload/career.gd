extends Node
## Singleton (autoload, dupa GameState): modul cariera. Tine config-ul
## (rafturile, din `career_config.tres`), progresul (`user://career.cfg`) si
## starea cursei de cariera in curs. Ce se vede pe ecran (raftul) citeste de aici.
##
## DOUA reguli care tin tot restul:
##  1. Progresul e pe PISTA si pe RIVAL, niciodata pe lume. Gruparea pistelor in
##     lumi e DATE (config) si se poate schimba; daca medaliile ar sta sub
##     lume, o regrupare le-ar pierde. Singura cheie pe lume e cupa.
##  2. Stampilele se CALCULEAZA din progres, nu se stocheaza. Un total salvat
##     separat se poate desincroniza de medalii; unul derivat nu.

signal progress_changed

enum Mode { RACE, TIME_TRIAL }

const CONFIG_PATH := "res://scenes/career/data/career_config.tres"
## Versiunea schemei din `career.cfg`. Un fisier cu versiune mai mare vine de la
## un build mai nou: il lasam neatins (vezi `_read_only`).
const SAVE_VERSION := 1
const MEDAL_NONE := 0
const MEDAL_BRONZE := 1
const MEDAL_SILVER := 2
const MEDAL_GOLD := 3

var config: CareerConfig
## Suprascris de sonda cu o cale temporara, ca sa nu atinga salvarea reala.
var save_path: String = "user://career.cfg"
## Fantomele contratimpului, cate un fisier per pista (nu in career.cfg: un
## fisier de ~100 KB n-are ce cauta intr-un ConfigFile citit la fiecare start).
## Sondele il suprascriu, ca sa nu atinga fantomele reale.
var ghost_dir: String = "user://ghosts/"

## True cat timp jucatorul e intr-o cursa pornita din raft.
var active: bool = false
var active_track: StringName = &""
## Cine porneste efectiv cursa. Implicit GameState.start_race; sonda il
## inlocuieste ca sa testeze `start_track` fara sa schimbe scena.
var race_starter: Callable = Callable()
## Modul cursei de cariera curente (contratimp = singur, rezervor sigilat).
var active_mode: Mode = Mode.RACE
## `GameState.ai_count` dinaintea contratimpului; -1 = nu l-am schimbat.
var _saved_ai_count: int = -1

var _tracks: Dictionary = {} # id -> {race_medal, tt_medal, tt_best_ms, challenge}
var _rivals: Dictionary = {} # id -> true cand e batut
var _cups: Dictionary = {} # id lume -> true cand e castigata
var _garage_unlocked: Array[String] = []
## Fisierul de pe disc e de la o versiune mai noua: nu incarcam nimic si nu
## salvam peste el, ca sa nu-l corupem.
var _read_only: bool = false


func _ready() -> void:
	config = load(CONFIG_PATH) as CareerConfig
	if config == null:
		push_error("Career: nu pot incarca %s" % CONFIG_PATH)
		config = CareerConfig.new()
	# Probleme de config nu opresc jocul: se vad in log si atat.
	for problem in validate():
		push_error("Career: " + problem)
	load_progress()


# ------------------------------------------------------------------ config

func worlds() -> Array[CareerWorld]:
	return config.worlds


## Lista problemelor din config (goala = sanatos). Primeste un config
## explicit ca sonda sa-l poata sabota in memorie.
func validate(cfg: CareerConfig = null) -> PackedStringArray:
	var target := cfg if cfg != null else config
	var problems := PackedStringArray()
	var free_count := 0
	var seen: Dictionary = {} # id pista -> id lume
	for world in target.worlds:
		if world.free:
			free_count += 1
		for track_id in world.tracks:
			if seen.has(track_id):
				problems.append("pista %s e in doua lumi (%s si %s)" % [
					track_id, seen[track_id], world.id])
			seen[track_id] = world.id
			if TrackInfo.index_of_id(track_id) < 0:
				problems.append("pista %s din %s nu exista in TRACK_SCENES" % [
					track_id, world.id])
		if world.rival_track != &"" and not world.tracks.has(world.rival_track):
			problems.append("rival_track %s nu e in lumea %s" % [
				world.rival_track, world.id])
	if free_count != 1:
		problems.append("trebuie exact o lume free, sunt %d" % free_count)
	return problems


# ------------------------------------------------------------- progres

func track_state(id: StringName) -> Dictionary:
	if _tracks.has(id):
		return (_tracks[id] as Dictionary).duplicate()
	return {"race_medal": 0, "tt_medal": 0, "tt_best_ms": 0, "challenge": false}


## Pastreaza MAXIMUL: o cursa mai slaba nu strica medalia deja castigata.
func set_race_medal(id: StringName, medal: int) -> void:
	var state := _state_for(id)
	state.race_medal = maxi(int(state.race_medal), clampi(medal, 0, MEDAL_GOLD))
	_changed()


## Medalia maxima, timpul minim (0 = niciun timp inca).
func set_time_trial(id: StringName, medal: int, ms: int) -> void:
	var state := _state_for(id)
	state.tt_medal = maxi(int(state.tt_medal), clampi(medal, 0, MEDAL_GOLD))
	var best := int(state.tt_best_ms)
	if ms > 0 and (best <= 0 or ms < best):
		state.tt_best_ms = ms
	_changed()


func set_challenge(id: StringName) -> void:
	_state_for(id).challenge = true
	_changed()


func set_rival_beaten(id: StringName) -> void:
	_rivals[id] = true
	_changed()


func set_cup_won(world_id: StringName) -> void:
	_cups[world_id] = true
	_changed()


func is_cup_won(world_id: StringName) -> bool:
	return bool(_cups.get(world_id, false))


## 1 -> aur, 2 -> argint, 3 -> bronz, restul nimic.
static func medal_for_position(position: int) -> int:
	match position:
		1: return MEDAL_GOLD
		2: return MEDAL_SILVER
		3: return MEDAL_BRONZE
	return MEDAL_NONE


## Stampile castigate: pe piesele din lumi (o pista fara lume nu conteaza),
## +1 pentru fiecare dintre medalia de cursa, medalia de contratimp si
## provocare, plus +1 per rival batut.
func stamps() -> int:
	var total := 0
	for world in config.worlds:
		for track_id in world.tracks:
			var state := track_state(track_id)
			total += int(int(state.race_medal) > 0) + int(int(state.tt_medal) > 0) \
				+ int(bool(state.challenge))
		if world.rival != &"" and bool(_rivals.get(world.rival, false)):
			total += 1
	return total


func max_stamps() -> int:
	var total := 0
	for world in config.worlds:
		total += 3 * world.tracks.size()
		if world.rival != &"":
			total += 1
	return total


func progress_fraction() -> float:
	var maximum := max_stamps()
	return float(stamps()) / float(maximum) if maximum > 0 else 0.0


func is_world_unlocked(world: CareerWorld) -> bool:
	return world.free or stamps() >= world.stamps_to_unlock


func stamps_missing(world: CareerWorld) -> int:
	if world.free:
		return 0
	return maxi(0, world.stamps_to_unlock - stamps())


## Cate medalii de fiecare culoare (cursa + contratimp) are jucatorul in
## total: {3: aur, 2: argint, 1: bronz}. Pentru pasaportul din raft.
func medal_counts() -> Dictionary:
	var counts := {MEDAL_GOLD: 0, MEDAL_SILVER: 0, MEDAL_BRONZE: 0}
	for world in config.worlds:
		for track_id in world.tracks:
			var state := track_state(track_id)
			for key in ["race_medal", "tt_medal"]:
				var medal := int(state[key])
				if medal > 0:
					counts[medal] += 1
	return counts


func garage_unlocked() -> Array[String]:
	return _garage_unlocked


func _state_for(id: StringName) -> Dictionary:
	if not _tracks.has(id):
		_tracks[id] = {"race_medal": 0, "tt_medal": 0, "tt_best_ms": 0,
			"challenge": false}
	return _tracks[id]


func _changed() -> void:
	save_progress()
	progress_changed.emit()


# ----------------------------------------------------- cursa de cariera

func start_track(id: StringName, mode: Mode = Mode.RACE) -> void:
	var index := TrackInfo.index_of_id(id)
	if index < 0:
		push_error("Career: pista %s nu exista" % id)
		return
	# Un start nou peste un contratimp neinchis nu are voie sa piarda valoarea
	# originala a lui ai_count: restauram inainte sa re-salvam.
	_restore_ai_count()
	active = true
	active_track = id
	active_mode = mode
	if mode == Mode.TIME_TRIAL:
		# `ai_count` e global si Race il citeste la spawn; contratimpul e singur.
		# `leave()` il readuce, ca o cursa rapida dupa un contratimp parasit
		# prin MENU sa nu ramana fara adversari.
		_saved_ai_count = GameState.ai_count
		GameState.ai_count = 0
	GameState.champ_active = false
	GameState.selected_track = index
	if race_starter.is_valid():
		race_starter.call()
	else:
		GameState.start_race()


## Inregistreaza rezultatul cursei de cariera. Returneaza medalia castigata
## acum (0 si daca nu e cursa de cariera). `active` ramane true pana la
## `leave()`: ecranul de rezultate inca apartine cursei.
func finish_active(position: int) -> int:
	if not active:
		return MEDAL_NONE
	var medal := medal_for_position(position)
	set_race_medal(active_track, medal)
	return medal


func is_time_trial() -> bool:
	return active and active_mode == Mode.TIME_TRIAL


## Medalia unui timp de contratimp fata de tintele pistei `id`. Functie pura:
## o tinta 0 = "fara tinta inca" si nu da medalie.
static func time_trial_medal(id: StringName, ms: int) -> int:
	var index := TrackInfo.index_of_id(id)
	if index < 0:
		return MEDAL_NONE
	return medal_for_time(TrackInfo.for_track(index), ms)


static func medal_for_time(info: TrackInfo, ms: int) -> int:
	if info.tt_gold_ms > 0 and ms <= info.tt_gold_ms:
		return MEDAL_GOLD
	if info.tt_silver_ms > 0 and ms <= info.tt_silver_ms:
		return MEDAL_SILVER
	if info.tt_bronze_ms > 0 and ms <= info.tt_bronze_ms:
		return MEDAL_BRONZE
	return MEDAL_NONE


## Rezultatul unui contratimp: salveaza timpul minim si medalia maxima,
## returneaza medalia castigata acum.
func finish_time_trial(race_ms: int) -> int:
	if not is_time_trial():
		return MEDAL_NONE
	var medal := time_trial_medal(active_track, race_ms)
	set_time_trial(active_track, medal, race_ms)
	return medal


# ------------------------------------------------------------- fantome

func ghost_path(track_id: StringName) -> String:
	return ghost_dir.path_join("%s.bin" % track_id)


## Scrie fantoma DOAR daca `race_ms` bate `previous_best_ms` (best-ul de DINAINTE
## de `finish_time_trial`; 0 = nicio cursa inca). Un fisier cu versiune mai noua
## decat stim nu se suprascrie (aceeasi regula ca la career.cfg). Intoarce true
## daca a scris.
func save_ghost_if_best(track_id: StringName, data: GhostData, race_ms: int,
		previous_best_ms: int) -> bool:
	if data == null or race_ms <= 0:
		return false
	if previous_best_ms > 0 and race_ms >= previous_best_ms:
		return false
	var path := ghost_path(track_id)
	if FileAccess.file_exists(path):
		var old := FileAccess.get_file_as_bytes(path)
		if GhostData.file_version(old) > GhostData.VERSION:
			push_warning("Career: fantoma %s e dintr-o versiune mai noua, nu o suprascriu" % path)
			return false
	DirAccess.make_dir_recursive_absolute(ghost_dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Career: nu pot scrie fantoma %s" % path)
		return false
	file.store_buffer(data.to_bytes())
	file.close()
	return true


## Null daca lipseste, e corupta sau e dintr-o versiune mai noua.
func load_ghost(track_id: StringName) -> GhostData:
	var path := ghost_path(track_id)
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	var data := GhostData.from_bytes(bytes)
	if data == null:
		push_warning("Career: fantoma %s ignorata (versiune %d, corupta sau necunoscuta)"
			% [path, GhostData.file_version(bytes)])
	return data


func leave() -> void:
	active = false
	active_mode = Mode.RACE
	_restore_ai_count()


func _restore_ai_count() -> void:
	if _saved_ai_count >= 0:
		GameState.ai_count = _saved_ai_count
		_saved_ai_count = -1


# ----------------------------------------------------------- persistenta

func load_progress() -> void:
	_tracks.clear()
	_rivals.clear()
	_cups.clear()
	_garage_unlocked.clear()
	_read_only = false
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return # primul start: nimic de incarcat
	var version := int(cfg.get_value("meta", "version", 1))
	if version > SAVE_VERSION:
		push_warning("Career: %s are versiunea %d (> %d); il las neatins" % [
			save_path, version, SAVE_VERSION])
		_read_only = true
		return
	for section in cfg.get_sections():
		if section.begins_with("track:"):
			var state := _state_for(StringName(section.trim_prefix("track:")))
			state.race_medal = clampi(int(cfg.get_value(section, "race_medal", 0)), 0, 3)
			state.tt_medal = clampi(int(cfg.get_value(section, "tt_medal", 0)), 0, 3)
			state.tt_best_ms = maxi(0, int(cfg.get_value(section, "tt_best_ms", 0)))
			state.challenge = bool(cfg.get_value(section, "challenge", false))
		elif section.begins_with("rival:"):
			if bool(cfg.get_value(section, "beaten", false)):
				_rivals[StringName(section.trim_prefix("rival:"))] = true
		elif section.begins_with("cup:"):
			if bool(cfg.get_value(section, "won", false)):
				_cups[StringName(section.trim_prefix("cup:"))] = true
	for entry in cfg.get_value("garage", "unlocked", []):
		_garage_unlocked.append(String(entry))


func save_progress() -> void:
	if _read_only:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SAVE_VERSION)
	for id in _tracks:
		var section := "track:%s" % id
		var state: Dictionary = _tracks[id]
		cfg.set_value(section, "race_medal", state.race_medal)
		cfg.set_value(section, "tt_medal", state.tt_medal)
		cfg.set_value(section, "tt_best_ms", state.tt_best_ms)
		cfg.set_value(section, "challenge", state.challenge)
	for id in _rivals:
		cfg.set_value("rival:%s" % id, "beaten", true)
	for id in _cups:
		cfg.set_value("cup:%s" % id, "won", true)
	cfg.set_value("garage", "unlocked", _garage_unlocked)
	cfg.save(save_path)
