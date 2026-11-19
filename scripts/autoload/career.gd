extends Node
## Singleton (autoload, dupa GameState): modul cariera. Tine config-ul
## (rafturile, din `career_config.tres`), progresul (`user://career.cfg`) si
## starea cursei de cariera in curs. Ce se vede pe ecran (raftul) citeste de aici.
##
## DOUA reguli care tin tot restul:
##  1. Progresul e pe PISTA si pe RIVAL, niciodata pe lume. Gruparea pistelor in
##     lumi e DATE (config) si se poate schimba; daca medaliile ar sta sub
##     lume, o regrupare le-ar pierde. Singura cheie pe lume e cupa.
##  2. Punctele se CALCULEAZA din progres, nu se stocheaza. Un total salvat
##     separat se poate desincroniza de medalii; unul derivat nu.
##     EXCEPTIA deliberata: masinile castigate (19 nov 2026). Pragurile lor sunt
##     date de tuning care se vor muta (cariera trece la 4 lumi, #704), iar un
##     prag ridicat sau o regrupare ar putea lasa punctele calculate sub prag. O
##     masina castigata nu se ia inapoi: cand punctele ating pragul, id-ul ei se
##     ZAVORASTE in `_garage_unlocked` (salvat in `[garage] unlocked`) si de
##     acolo nu mai iese. Vezi `_latch_cars`.
##
## Punctajul (decizia dezvoltatorului, 25 oct 2026, dupa sesiunea la volan):
## locul 1/2/3 = 3/2/1 puncte (= valoarea medaliei), plus +1 bonus castigat in
## ACEEASI cursa. Nicio „stampila" plata: locul mai bun plateste mai mult.
## Contratimpul nu da puncte pana nu are tinte (brief §4.2).
##
## Bonusul (19 nov 2026, inlocuieste provocarile per pista): acelasi pe FIECARE
## pista, „NO RETRY" — termini cursa fara sa fii aruncat din masina si fara sa
## apesi RESET. Regula o tine `BonusTracker`; aici stau doar bifa si punctul.

signal progress_changed
## O masina tocmai castigata (zavorata de `_changed`, nu de incarcarea unui save).
signal car_unlocked(car_id: StringName)

## RACE poarta bonusul NO RETRY (+1, vezi `bonus_active`); contratimpul nu.
enum Mode { RACE, TIME_TRIAL }

const CONFIG_PATH := "res://scenes/career/data/career_config.tres"
## Versiunea schemei din `career.cfg`. Un fisier cu versiune mai mare vine de la
## un build mai nou: il lasam neatins (vezi `_read_only`).
const SAVE_VERSION := 1
const MEDAL_NONE := 0
const MEDAL_BRONZE := 1
const MEDAL_SILVER := 2
const MEDAL_GOLD := 3
## Bonusul NO RETRY pastrat in cursa; un rival batut = cat o victorie
## (implicit, rivalii nu sunt construiti — brief §12).
const BONUS_POINTS := 1
const RIVAL_POINTS := 3
## Maximul pe ORICE pista: locul 1 + bonusul (bonusul exista pe toate).
const MAX_TRACK_POINTS := MEDAL_GOLD + BONUS_POINTS

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

## id -> {race_medal, tt_medal, tt_best_ms, challenge}. `challenge` e bifa
## BONUSULUI: cheia si-a pastrat numele de pe vremea provocarilor per pista,
## si in memorie si pe disc (`career.cfg`, schema 1), ca o bifa veche sa ramana
## bonusul pistei fara migrare.
var _tracks: Dictionary = {}
var _rivals: Dictionary = {} # id -> true cand e batut
var _cups: Dictionary = {} # id lume -> true cand e castigata
## Masinile castigate, pe `CarData.id` (niciodata pe index in CAR_DATA). Doar
## cresc: vezi regula 2 din antet si `_latch_cars`.
var _garage_unlocked: Array[String] = []
## Masinile castigate de cel mai recent `finish_active` (golita la `start_track`
## si la inceputul lui `finish_active`). Ecranul de rezultate o citeste.
var last_unlocked_cars: Array[StringName] = []
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
	# Sondele / verify_local: acelasi director ca GameState (SaveSchema).
	var save_dir := SaveSchema.dir_override()
	if save_dir != "":
		save_path = save_dir + save_path.get_file()
		ghost_dir = save_dir + "ghosts/"
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
	_validate_cars(target, problems)
	return problems


## Garajul de start si masinile castigate. O masina din CAR_DATA care lipseste
## din ambele liste e deschisa — nu e o problema (vezi `CareerConfig`).
func _validate_cars(target: CareerConfig, problems: PackedStringArray) -> void:
	var garage: Dictionary = {}
	for res in GameState.CAR_DATA:
		garage[(res as CarData).id] = true
	for car_id in target.starting_cars:
		if not garage.has(car_id):
			problems.append("masina de start %s nu exista in CAR_DATA" % car_id)
	var rewarded: Dictionary = {}
	for reward in target.car_rewards:
		if reward == null:
			problems.append("o recompensa de masina e goala")
			continue
		if not garage.has(reward.car):
			problems.append("recompensa %s: masina nu exista in CAR_DATA" % reward.car)
		if target.starting_cars.has(reward.car):
			problems.append("masina %s e si de start si recompensa" % reward.car)
		if rewarded.has(reward.car):
			problems.append("doua recompense pentru masina %s" % reward.car)
		rewarded[reward.car] = true
		if reward.points < 1:
			problems.append("recompensa %s: points trebuie >= 1, e %d" % [
				reward.car, reward.points])
	if not target.car_rewards.is_empty() and target.starting_cars.is_empty():
		problems.append("exista masini de castigat, dar starting_cars e gol")


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


## Pune bifa bonusului pe pista (nu se mai ia inapoi).
func set_bonus(id: StringName) -> void:
	_state_for(id).challenge = true
	_changed()


## Bifa bonusului pe pista `id`, din orice cursa de pana acum.
func has_bonus(id: StringName) -> bool:
	return bool(track_state(id).challenge)


func set_rival_beaten(id: StringName) -> void:
	_rivals[id] = true
	_changed()


func set_cup_won(world_id: StringName) -> void:
	_cups[world_id] = true
	_changed()


func is_cup_won(world_id: StringName) -> bool:
	return bool(_cups.get(world_id, false))


## 1 -> aur, 2 -> argint, 3 -> bronz, restul nimic. Valoarea medaliei E
## punctajul locului (3/2/1), de aceea nu exista o functie separata de puncte.
static func medal_for_position(position: int) -> int:
	match position:
		1: return MEDAL_GOLD
		2: return MEDAL_SILVER
		3: return MEDAL_BRONZE
	return MEDAL_NONE


## Punctele unei piste: locul (3/2/1) + bonusul. Fiecare componenta isi tine
## maximul separat: locul 1 cu bonusul pierdut intr-o cursa si locul 3 cu
## bonusul pastrat in alta dau impreuna 3 + 1 — bonusul se poate vana si
## intr-o cursa ulterioara, nu doar in cea cu locul cel mai bun. Bonusul exista
## pe orice pista, deci o bifa veche (de la o provocare per pista) sau una
## ramasa pe o pista din lumea 4 conteaza; punctele tot nu trec de
## `MAX_TRACK_POINTS`.
func track_points(id: StringName) -> int:
	var state := track_state(id)
	return int(state.race_medal) + (BONUS_POINTS if bool(state.challenge) else 0)


## Punctele castigate: pe pistele din lumi (o pista fara lume nu conteaza),
## plus RIVAL_POINTS per rival batut. Contratimpul nu intra: fara tinte, o
## medalie de contratimp nu exista inca (brief §4.2).
func points() -> int:
	var total := 0
	for world in config.worlds:
		for track_id in world.tracks:
			total += track_points(track_id)
		if world.rival != &"" and bool(_rivals.get(world.rival, false)):
			total += RIVAL_POINTS
	return total


## Maximul carierei: `MAX_TRACK_POINTS` pe fiecare pista din lumi (bonusul e
## pe toate) + RIVAL_POINTS per rival. Cu 4 lumi x 4 piste, fara rivali: 64.
func max_points() -> int:
	var total := 0
	for world in config.worlds:
		total += MAX_TRACK_POINTS * world.tracks.size()
		if world.rival != &"":
			total += RIVAL_POINTS
	return total


func progress_fraction() -> float:
	var maximum := max_points()
	return float(points()) / float(maximum) if maximum > 0 else 0.0


func is_world_unlocked(world: CareerWorld) -> bool:
	return world.free or points() >= world.points_to_unlock


func points_missing(world: CareerWorld) -> int:
	if world.free:
		return 0
	return maxi(0, world.points_to_unlock - points())


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


# ------------------------------------------------------------ masinile

## SINGURA verificare de lacat a unei masini: garajul, selectia si orice alt
## ecran trec pe aici. Comutatorul de dezvoltator deschide tot fara sa scrie
## nimic; restul regulilor (start, recompensa, zavor — si mai tarziu cumparare
## sau rivali) stau in `is_car_earned`.
func is_car_unlocked(car_id: StringName) -> bool:
	return GameState.dev_unlock_all_cars or is_car_earned(car_id)


## Masina e a jucatorului fara comutatorul de dezvoltator: e de start, n-are
## recompensa (continut nou, inca neasezat = deschis) sau a fost castigata.
## Pasaportul numara pe asta, ca sa arate progresul real si cu comutatorul aprins.
func is_car_earned(car_id: StringName) -> bool:
	if config.starting_cars.has(car_id):
		return true
	if car_reward_for(car_id) == null:
		return true
	return _garage_unlocked.has(String(car_id))


## Recompensa masinii `car_id`, sau null daca nu se castiga in cariera.
func car_reward_for(car_id: StringName) -> CareerCarReward:
	for reward in config.car_rewards:
		if reward != null and reward.car == car_id:
			return reward
	return null


## Cate puncte de cariera mai lipsesc pana la masina (0 = deschisa).
func points_missing_for_car(car_id: StringName) -> int:
	if is_car_unlocked(car_id):
		return 0
	var reward := car_reward_for(car_id)
	return maxi(0, reward.points - points()) if reward != null else 0


## Urmatoarea masina de castigat: pragul cel mai mic inca necastigat (null =
## toate castigate). Pe progresul real, nu pe comutatorul de dezvoltator.
func next_car_reward() -> CareerCarReward:
	var best: CareerCarReward = null
	for reward in config.car_rewards:
		if reward == null or is_car_earned(reward.car):
			continue
		if best == null or reward.points < best.points:
			best = reward
	return best


## Masinile din garaj castigate (sau deschise), pentru pasaport.
func earned_car_count() -> int:
	var count := 0
	for res in GameState.CAR_DATA:
		if is_car_earned((res as CarData).id):
			count += 1
	return count


func garage_size() -> int:
	return GameState.CAR_DATA.size()


## Numele de afis al masinii `car_id` (id-ul brut daca nu e in garaj).
static func car_display_name(car_id: StringName) -> String:
	var index := SaveSchema.index_of(GameState.CAR_DATA, car_id)
	if index < 0:
		return String(car_id)
	return (GameState.CAR_DATA[index] as CarData).display_name


## Daca masina selectata e incuiata, selectia trece pe prima masina de start
## din garaj — DOAR IN MEMORIE. Se cheama DOAR din `MainMenu._ready()` (si din
## garaj, la stingerea comutatorului): nu din `_ready()`-ul carierei si nici din
## `race.gd`, fiindca zeci de sonde incarca `Race.tscn` direct cu
## `selected_car = 0` (Muscle, incuiata pe un save gol) si liniile lor de baza
## nu au voie sa se mute.
##
## NU salveaza setarile, si nu din economie: prima varianta salva, iar primul
## pas din verify_local.sh (porneste scena principala = meniul) a scris
## `car="taxi"` in save-ul comun al sondelor — toate cursele de dupa au rulat cu
## Taxi in loc de Muscle si `ProbeTfHazards` a picat pe pragul oilor (19 nov
## 2026). Corectia e derivata: meniul o reface la fiecare pornire, deci pe disc
## n-are ce cauta. Ajunge acolo cand jucatorul salveaza el ceva (SELECT, o
## setare), ca orice alta selectie. De aceea nici id-ul dormant (masina dintr-un
## build mai nou) nu se pierde aici.
func ensure_selected_car() -> void:
	var current := SaveSchema.id_at(GameState.CAR_DATA, GameState.selected_car)
	if current != &"" and is_car_unlocked(current):
		return
	for car_id in config.starting_cars:
		var index := SaveSchema.index_of(GameState.CAR_DATA, car_id)
		if index >= 0:
			GameState.selected_car = index
			return


## Zavorul: fiecare recompensa al carei prag e atins si inca nezavorata intra in
## `_garage_unlocked`. Intoarce masinile zavorate ACUM, in ordinea pragurilor.
## Doar adauga — nimic nu scoate o masina castigata (regula 2 din antet).
func _latch_cars() -> Array[StringName]:
	var latched: Array[StringName] = []
	var rewards: Array[CareerCarReward] = []
	for reward in config.car_rewards:
		if reward != null:
			rewards.append(reward)
	if rewards.is_empty():
		return latched
	rewards.sort_custom(func(a: CareerCarReward, b: CareerCarReward) -> bool:
		return a.points < b.points)
	var total := points()
	for reward in rewards:
		if total >= reward.points and not _garage_unlocked.has(String(reward.car)):
			_garage_unlocked.append(String(reward.car))
			latched.append(reward.car)
	return latched


func _state_for(id: StringName) -> Dictionary:
	if not _tracks.has(id):
		_tracks[id] = {"race_medal": 0, "tt_medal": 0, "tt_best_ms": 0,
			"challenge": false}
	return _tracks[id]


func _changed() -> void:
	var latched := _latch_cars()
	last_unlocked_cars.append_array(latched)
	save_progress()
	progress_changed.emit()
	for car_id in latched:
		car_unlocked.emit(car_id)


# ----------------------------------------------------- cursa de cariera

func start_track(id: StringName, mode: Mode = Mode.RACE) -> void:
	var index := TrackInfo.index_of_id(id)
	if index < 0:
		push_error("Career: pista %s nu exista" % id)
		return
	# Un start nou peste un contratimp neinchis nu are voie sa piarda valoarea
	# originala a lui ai_count: restauram inainte sa re-salvam.
	_restore_ai_count()
	last_unlocked_cars.clear()
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


## Inregistreaza rezultatul cursei de cariera: locul da medalia (= punctele
## locului), `bonus_kept` pune bifa bonusului (+BONUS_POINTS; doar intr-o
## cursa RACE, vezi `bonus_active`). Returneaza punctele facute ACUM de cursa
## asta (0 si daca nu e cursa de cariera) — nu diferenta fata de ce era salvat:
## ecranul de rezultate spune ce ai facut, raftul spune ce ai strans. Bifa si
## medalia nu se pierd la o cursa mai slaba sau cu bonusul pierdut (pastram
## maximul). `active` ramane true pana la `leave()`: ecranul de rezultate inca
## apartine cursei.
func finish_active(position: int, bonus_kept: bool = false) -> int:
	if not active:
		return 0
	var with_bonus := bonus_kept and bonus_active()
	last_unlocked_cars.clear()
	var medal := medal_for_position(position)
	set_race_medal(active_track, medal)
	var bonus := 0
	if with_bonus:
		set_bonus(active_track)
		bonus = BONUS_POINTS
	return medal + bonus


## Cursa curenta poarta bonusul NO RETRY: doar o cursa RACE de cariera (cu
## adversari). Nu in contratimp; Quick Race, World Cup si turul ghidat nu sunt
## cariera (`active` e fals).
func bonus_active() -> bool:
	return active and active_mode == Mode.RACE


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
		if not _garage_unlocked.has(String(entry)):
			_garage_unlocked.append(String(entry))
	# Un save cu puncte de dinainte de masinile castigate (sau un prag coborat
	# intre timp) isi primeste masinile aici, in tacere: fara anunt, si scris
	# pe disc doar daca s-a zavorat ceva. Un fisier read-only a iesit mai sus.
	if not _latch_cars().is_empty():
		save_progress()


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
