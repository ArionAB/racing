class_name WorldCupSave
extends RefCounted
## Cupa WORLD CUP in desfasurare, pe disc (19 nov 2026, cererea dezvoltatorului:
## „un buton de continue si unul de reset"). Un fisier, `world_cup.cfg`, cu
## cate o sectiune per cupa (`[cup:<WorldCup.id>]`): fiecare cutie din panou isi
## are propria cupa de continuat.
##
## CAND se scrie (vezi `GameState.champ_save_progress`):
##   - la inregistrarea rezultatelor unei curse de cupa, cu `next_race` = cursa
##     de dupa ea: o aplicatie omorata pe ecranul de rezultate nu pierde si nu
##     rejoaca cursa;
##   - NIMIC inainte de prima cursa terminata a cupei;
##   - la ultima cursa sectiunea cupei se STERGE (cupa terminata = nimic de
##     continuat).
## Iesirea in mijlocul cursei (MENU din pauza, aplicatia omorata) nu scrie
## nimic: cursa in curs nu conteaza, save-ul arata tot spre ea.
##
## Tot pe ID STABIL (regula din `SaveSchema`): adversarii si masina jucatorului
## pe `CarData.id`, nivelul AI pe numele fisierului de nivel (`bronz` / `argint`
## / `aur`, din `AiSkill.LEVEL_PATHS`), cupa pe `WorldCup.id`. Un save care nu
## se mai potriveste cu jocul (cupa, masina sau nivel necunoscut, alt numar de
## adversari, cursa in afara cupei) e ca si ABSENT: fara CONTINUE, fara crash.
## Sectiunea ramane pe disc, dormanta, pana la urmatorul RESET/final al cupei.
## Un fisier cu versiune mai mare decat stim nu se citeste si nu se suprascrie
## (aceeasi regula ca `career.cfg`): cupele se joaca, doar nu se salveaza.
##
## Exemplu (o cupa la a treia cursa, 5 adversari):
##   [meta]
##   version=1
##   [cup:asia_cup]
##   next_race=2
##   points=[11, 7, 6, 3, 2, 1]
##   rivals=["bus", "taxi", "monster", "hotrod", "buggy"]
##   car="muscle"
##   ai_level="aur"

const VERSION := 1
const FILE_NAME := "world_cup.cfg"
const SECTION_PREFIX := "cup:"

## Calea fisierului pentru sonde (gol = `TOY_RACER_SAVE_DIR` sau `user://`).
static var path_override: String = ""


## O cupa salvata, deja rezolvata pe jocul curent (indici valizi in CAR_DATA,
## nivel valid). `load_entry` nu intoarce niciodata una stricata.
class Entry:
	extends RefCounted
	var cup: WorldCup
	## Cursa care urmeaza (0-based); intre 1 si `cup.tracks.size() - 1`.
	var next_race: int = 0
	## Un slot per masina din cursa; 0 = jucatorul.
	var points: Array[int] = []
	## Indici in `GameState.CAR_DATA`, unul per slot AI.
	var ai_cars: Array[int] = []
	var player_car: int = 0
	## Index in `AiSkill.LEVEL_PATHS`.
	var ai_level: int = 0

	## Locul jucatorului dupa puncte: 1 + sloturile cu STRICT mai multe puncte.
	func player_rank() -> int:
		var rank := 1
		for i in range(1, points.size()):
			if points[i] > points[0]:
				rank += 1
		return rank


static func path() -> String:
	if path_override != "":
		return path_override
	var dir := SaveSchema.dir_override()
	return (dir if dir != "" else "user://") + FILE_NAME


## Fisierul e de la un build mai nou: nu-l citim si nu scriem peste el.
static func is_read_only() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(path()) == OK and SaveSchema.file_version(cfg) > VERSION


## Cupa salvata, sau null (lipsa, fisier mai nou / stricat, sau save care nu
## se mai potriveste cu jocul).
static func load_entry(cup: WorldCup) -> Entry:
	if cup == null:
		return null
	var cfg := ConfigFile.new()
	if cfg.load(path()) != OK or SaveSchema.file_version(cfg) > VERSION:
		return null
	return _parse(cfg, cup)


static func has_entry(cup: WorldCup) -> bool:
	return load_entry(cup) != null


## Scrie cupa dupa o cursa terminata. False daca n-a scris (fisier mai nou,
## nivel necunoscut, eroare de disc).
static func store(cup: WorldCup, next_race: int, points: Array[int],
		ai_cars: Array[int], player_car: int, ai_level: int) -> bool:
	var level := level_id(ai_level)
	if cup == null or cup.id == &"" or level == "":
		return false
	var cfg := _open_for_write()
	if cfg == null:
		return false
	# Liste NETIPATE: pe disc ies `[11, 7]` / `["bus", "taxi"]`, nu
	# `Array[int]([...])` — mai usor de citit si de reparat de mana.
	var rivals: Array = []
	for index in ai_cars:
		rivals.append(String(SaveSchema.id_at(GameState.CAR_DATA, index)))
	var plain_points: Array = []
	plain_points.assign(points)
	var section := SECTION_PREFIX + String(cup.id)
	if cfg.has_section(section):
		cfg.erase_section(section)
	cfg.set_value(section, "next_race", next_race)
	cfg.set_value(section, "points", plain_points)
	cfg.set_value(section, "rivals", rivals)
	cfg.set_value(section, "car", String(SaveSchema.id_at(GameState.CAR_DATA, player_car)))
	cfg.set_value(section, "ai_level", level)
	return cfg.save(path()) == OK


## Sterge cupa `cup_id` (RESET, sau cupa terminata). Celelalte cupe raman.
static func erase(cup_id: StringName) -> bool:
	var section := SECTION_PREFIX + String(cup_id)
	var cfg := _open_for_write()
	if cfg == null:
		return false
	if not cfg.has_section(section):
		return true
	cfg.erase_section(section)
	return cfg.save(path()) == OK


## Id-ul stabil al nivelului (`aur` din `.../aur.tres`), sau "" in afara listei.
static func level_id(level: int) -> String:
	if level < 0 or level >= AiSkill.LEVEL_PATHS.size():
		return ""
	return AiSkill.LEVEL_PATHS[level].get_file().get_basename()


static func level_of_id(id: String) -> int:
	if id == "":
		return -1
	for i in AiSkill.LEVEL_PATHS.size():
		if level_id(i) == id:
			return i
	return -1


## Fisierul existent (ca celelalte cupe sa ramana), sau unul gol; null daca e
## de la un build mai nou. Un fisier care nu se parseaza se scrie de la zero,
## ca la `career.cfg`.
static func _open_for_write() -> ConfigFile:
	var cfg := ConfigFile.new()
	if cfg.load(path()) == OK:
		if SaveSchema.file_version(cfg) > VERSION:
			push_warning("WorldCupSave: %s are versiunea %d (> %d); il las neatins"
				% [path(), SaveSchema.file_version(cfg), VERSION])
			return null
	else:
		cfg.clear()
	cfg.set_value(SaveSchema.META_SECTION, SaveSchema.VERSION_KEY, VERSION)
	return cfg


## Sectiunea cupei, validata camp cu camp. Orice nepotrivire -> null.
static func _parse(cfg: ConfigFile, cup: WorldCup) -> Entry:
	var section := SECTION_PREFIX + String(cup.id)
	if not cfg.has_section(section):
		return null
	var slots := GameState.ai_count + 1
	var entry := Entry.new()
	entry.cup = cup
	var next: Variant = cfg.get_value(section, "next_race", null)
	if typeof(next) != TYPE_INT or int(next) < 1 or cup.track_index(int(next)) < 0:
		return null
	entry.next_race = int(next)
	var points: Variant = cfg.get_value(section, "points", null)
	if not points is Array or (points as Array).size() != slots:
		return null
	for p: Variant in points:
		if typeof(p) != TYPE_INT or int(p) < 0:
			return null
		entry.points.append(int(p))
	# Adversarii: fiecare id trebuie sa existe in garaj. Un id gol (masina
	# disparuta la scriere) sau necunoscut invalideaza cupa.
	var rivals: Variant = cfg.get_value(section, "rivals", null)
	if not rivals is Array or (rivals as Array).size() != slots - 1:
		return null
	for id: Variant in rivals:
		if typeof(id) != TYPE_STRING and typeof(id) != TYPE_STRING_NAME:
			return null
		var index := SaveSchema.index_of(GameState.CAR_DATA, StringName(id))
		if index < 0:
			return null
		entry.ai_cars.append(index)
	var car: Variant = cfg.get_value(section, "car", null)
	if typeof(car) != TYPE_STRING and typeof(car) != TYPE_STRING_NAME:
		return null
	entry.player_car = SaveSchema.index_of(GameState.CAR_DATA, StringName(car))
	if entry.player_car < 0:
		return null
	var level: Variant = cfg.get_value(section, "ai_level", null)
	if typeof(level) != TYPE_STRING and typeof(level) != TYPE_STRING_NAME:
		return null
	entry.ai_level = level_of_id(String(level))
	if entry.ai_level < 0:
		return null
	return entry
