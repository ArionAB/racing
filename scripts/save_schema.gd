class_name SaveSchema
extends RefCounted
## Schema fisierelor de save din `user://` si migrarile lor (issue #690).
##
## REGULA: tot ce ajunge pe disc se cheiaza pe ID STABIL, niciodata pe pozitia
## dintr-o lista (`CAR_DATA`, `TRACK_SCENES`) si niciodata pe un nume de afis
## (`TRACK_NAMES`, `display_name`). Id-urile: `TrackInfo.id`, `CarData.id`,
## `DriverData.id`. Asa o redenumire sau o reordonare dupa lansare nu atinge
## nimic salvat, si nu e nevoie de nicio tabela de alias-uri.
##
## Fiecare fisier are `[meta] version=N`. Un fisier fara cheie e v0 (formatul
## de dinainte de #690). La incarcare (`open`):
##   - v0 -> se face INTAI o copie neatinsa, apoi se traduce (index -> id,
##     nume -> id) si se rescrie cu versiunea curenta. A doua rulare gaseste
##     versiunea curenta si nu mai scrie nimic.
##     Copiile, cel mult DOUA per versiune de plecare:
##       `<fisier>.bak-v0`       PRIMA migrare de la v0 — nu se mai scrie NICIODATA
##       `<fisier>.bak-v0.last`  orice migrare ulterioara de la v0 — se suprascrie
##     De ce: un build vechi (worktree fara #690) citeste 0 recorduri din v1 si,
##     la primul record nou, rescrie fisierul ca v0 cu un singur record. Migrarea
##     acelui v0 sarac nu are voie sa calce copia cu recordurile adevarate.
##   - versiune MAI MARE decat stim (un build mai nou a scris-o) -> nu se
##     incarca si nu se suprascrie: aceeasi regula ca `career.cfg`.
##   - fisier care nu se parseaza -> copie in `<fisier>.corrupt`, jocul porneste
##     cu valorile implicite.
## Un id necunoscut (pista sau masina scoasa din joc) nu se sterge: ramane
## DORMANT in fisier si revine daca revine continutul.
##
## Inventarul scrierilor in `user://` (nov 2026), ca nimic sa nu scape:
##   settings.cfg  GameState  — setari + masina/soferul alese (pe id)  -> v1 aici
##   records.cfg   GameState  — best lap / best race (pe id de pista)  -> v1 aici
##   career.cfg    Career     — progresul carierei, `[meta] version=1` si chei
##                              `track:<TrackInfo.id>` de la inceput; garajul
##                              deblocat (`[garage] unlocked`) poarta CarData.id
##   ghosts/<id>.bin Career   — fantomele contratimpului, GhostData v2 (masina pe
##                              id; v1 tinea indexul si se citeste prin V0_CAR_ORDER)
##   incarcare.cfg LoadingScreen — cache de durate pe numele scenei; nu e save
##                              (pierderea lui doar reface estimarea barei)
##   load_trace.txt GameState — urma ultimei incarcari (diagnostic)
##   location_pins.txt LocationTelemetry — unealta de dezvoltare (F5)
## Starea WORLD CUP traieste doar in memorie (iesirea in MENU abandoneaza cupa).

const SETTINGS_VERSION := 1
const RECORDS_VERSION := 1
const META_SECTION := "meta"
const VERSION_KEY := "version"
## Copia fisierului dinaintea PRIMEI migrari de la versiunea %d. Odata scrisa,
## nu se mai atinge: e originalul, oricate migrari ar urma.
const BACKUP_SUFFIX := ".bak-v%d"
## Copia dinaintea unei migrari ULTERIOARE de la aceeasi versiune (adaugat dupa
## BACKUP_SUFFIX). Se suprascrie: tine doar ultimul fisier migrat, ca numarul de
## copii sa ramana doua.
const BACKUP_LAST_SUFFIX := ".last"
const CORRUPT_SUFFIX := ".corrupt"

## Recordurile v0 sub un nume care nu mai e in nicio tabela (piste sterse
## inainte de #690: Stramtoarea, Okinawa v2...). Nu se afiseaza, nu se sterg.
const LEGACY_RECORDS_SECTION := "legacy_records"
const LEGACY_RACE_RECORDS_SECTION := "legacy_race_records"

## Directorul save-urilor pentru sonde si `verify_local.sh`: cu variabila de
## mediu asta setata (doar in build de debug), GameState si Career citesc si
## scriu acolo in loc de `user://`, inclusiv la `_ready` — singurul fel in care
## o rulare headless nu atinge save-ul real al dezvoltatorului.
const DIR_OVERRIDE_ENV := "TOY_RACER_SAVE_DIR"

## Ordinea lui `GameState.CAR_DATA` in formatul v0, unde `selected_car` (si
## fantoma v1) tineau INDEXUL. INGHETATA: traduce doar fisiere vechi, deci nu se
## actualizeaza cand garajul se schimba.
const V0_CAR_ORDER: Array[StringName] = [
	&"muscle", &"police_sports", &"taxi", &"bus", &"firetruck", &"buggy",
	&"ambulance", &"hotrod", &"tow_truck", &"monster",
]
## Ordinea lui `GameState.DRIVER_DATA` in formatul v0. INGHETATA.
const V0_DRIVER_ORDER: Array[StringName] = [&"blue", &"red", &"yellow", &"green"]
## Numele din `TRACK_NAMES` sub care v0 tinea recordurile -> `TrackInfo.id`.
## INGHETATA: o redenumire de acum incolo (#673) NU se adauga aici, fiindcă
## recordurile noi stau deja pe id. "Alpii" (Track09) a iesit din joc in oct 2026: recordul ramane dormant pe id.
const V0_TRACK_IDS: Dictionary = {
	"Dunele": "dunele",
	"Okinawa manual": "okinawa_manual",
	"Transfagarasan": "transfagarasan",
	"Baikal": "baikal",
	"Stromboli": "stromboli",
	"Chongqing": "chongqing",
	"Cappadocia": "cappadocia",
	"Serengeti": "serengeti",
	"Machu Picchu": "machu_picchu",
	"Fiordland": "fiordland",
	"Jodhpur": "jodhpur",
	"Kyoto": "kyoto",
	"Monument Valley": "monument_valley",
	"Okinawa": "okinawa",
	"Ha Long": "halong",
	"Carrara": "carrara",
	"Angkor": "angkor",
	"Alpii": "alpi",
}

enum Status {
	MISSING, ## fisierul nu exista (primul start)
	CURRENT, ## versiunea curenta, incarcat ca atare
	MIGRATED, ## era mai vechi: copie facuta, tradus, rescris
	READ_ONLY, ## versiune mai noua, sau migrarea n-a putut fi scrisa: nu se salveaza peste
	CORRUPT, ## nu se parseaza: copiat in .corrupt, pornim de la implicite
}


## Directorul din `TOY_RACER_SAVE_DIR` (creat daca lipseste), sau "" = `user://`.
static func dir_override() -> String:
	if not OS.is_debug_build():
		return ""
	var dir := OS.get_environment(DIR_OVERRIDE_ENV).strip_edges()
	if dir == "":
		return ""
	if not dir.ends_with("/"):
		dir += "/"
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


static func file_version(cfg: ConfigFile) -> int:
	return int(cfg.get_value(META_SECTION, VERSION_KEY, 0))


## Incarca `path` in `cfg` si il aduce la versiunea curenta a tipului `kind`
## (&"settings" / &"records"). Dupa MIGRATED/CURRENT, `cfg` tine formatul nou;
## dupa MISSING/CORRUPT/READ_ONLY-mai-nou, `cfg` e gol.
static func open(path: String, kind: StringName, cfg: ConfigFile) -> Status:
	cfg.clear()
	if not FileAccess.file_exists(path):
		return Status.MISSING
	if cfg.load(path) != OK:
		cfg.clear()
		_copy(path, path + CORRUPT_SUFFIX)
		push_warning("SaveSchema: %s nu se poate citi; copiat in %s, pornesc de la implicite"
			% [path, path + CORRUPT_SUFFIX])
		return Status.CORRUPT
	var current := current_version(kind)
	var version := file_version(cfg)
	if version > current:
		push_warning("SaveSchema: %s are versiunea %d (> %d); il las neatins"
			% [path, version, current])
		cfg.clear()
		return Status.READ_ONLY
	if version == current:
		return Status.CURRENT
	# Copia INAINTE de orice schimbare: o migrare gresita nu distruge nimic.
	if not _copy(path, backup_path(path, version)):
		push_warning("SaveSchema: nu pot face copia lui %s; migrez doar in memorie" % path)
		migrate(cfg, kind)
		return Status.READ_ONLY
	migrate(cfg, kind)
	if cfg.save(path) != OK:
		push_warning("SaveSchema: nu pot rescrie %s dupa migrare" % path)
		return Status.READ_ONLY
	return Status.MIGRATED


## Unde merge copia dinaintea migrarii de la `version`: prima copie daca nu
## exista inca, altfel `.last` (prima nu se suprascrie niciodata).
static func backup_path(path: String, version: int) -> String:
	var first := path + BACKUP_SUFFIX % version
	return first + BACKUP_LAST_SUFFIX if FileAccess.file_exists(first) else first


static func current_version(kind: StringName) -> int:
	return SETTINGS_VERSION if kind == &"settings" else RECORDS_VERSION


## Aduce `cfg` (in memorie) de la versiunea lui la cea curenta, pas cu pas.
## Pe un cfg deja curent nu schimba nimic. Un v2 viitor = un `if version < 2`.
static func migrate(cfg: ConfigFile, kind: StringName) -> void:
	var version := file_version(cfg)
	if version < 1:
		if kind == &"settings":
			_settings_v0_to_v1(cfg)
		else:
			_records_v0_to_v1(cfg)
	cfg.set_value(META_SECTION, VERSION_KEY, current_version(kind))


# ------------------------------------------------------------ migrari v0 -> v1

## `[game] selected_car / selected_driver` (indici) -> `[game] car / driver`
## (id-uri). Indicii in afara listei se strang ca la loader-ul v0 (clampi), ca
## jucatorul sa ramana cu exact masina pe care o vedea.
static func _settings_v0_to_v1(cfg: ConfigFile) -> void:
	if cfg.has_section_key("game", "selected_car"):
		var i := int(cfg.get_value("game", "selected_car", 0))
		cfg.set_value("game", "car",
			String(V0_CAR_ORDER[clampi(i, 0, V0_CAR_ORDER.size() - 1)]))
		cfg.erase_section_key("game", "selected_car")
	if cfg.has_section_key("game", "selected_driver"):
		var i := int(cfg.get_value("game", "selected_driver", 0))
		cfg.set_value("game", "driver",
			String(V0_DRIVER_ORDER[clampi(i, 0, V0_DRIVER_ORDER.size() - 1)]))
		cfg.erase_section_key("game", "selected_driver")


## `[records] <nume>=ms` -> `[records] <id>=ms`, `[race_records] <nume>@N` ->
## `<id>@N`. Valorile se copiaza neatinse; un nume necunoscut trece in
## sectiunile `legacy_*`, cu cheia originala.
static func _records_v0_to_v1(cfg: ConfigFile) -> void:
	var laps: Dictionary = {}
	var races: Dictionary = {}
	if cfg.has_section("records"):
		for key: String in cfg.get_section_keys("records"):
			var value: Variant = cfg.get_value("records", key)
			if V0_TRACK_IDS.has(key):
				_keep_best(laps, V0_TRACK_IDS[key], value)
			else:
				cfg.set_value(LEGACY_RECORDS_SECTION, key, value)
		cfg.erase_section("records")
	if cfg.has_section("race_records"):
		for key: String in cfg.get_section_keys("race_records"):
			var value: Variant = cfg.get_value("race_records", key)
			var at := key.rfind("@")
			var track_name := key.substr(0, at) if at >= 0 else key
			if at >= 0 and V0_TRACK_IDS.has(track_name):
				_keep_best(races, "%s@%s" % [V0_TRACK_IDS[track_name], key.substr(at + 1)], value)
			else:
				cfg.set_value(LEGACY_RACE_RECORDS_SECTION, key, value)
		cfg.erase_section("race_records")
	for key in laps:
		cfg.set_value("records", key, laps[key])
	for key in races:
		cfg.set_value("race_records", key, races[key])


## Doua chei vechi pe acelasi id (n-ar trebui sa existe): castiga timpul mai bun.
static func _keep_best(into: Dictionary, key: String, value: Variant) -> void:
	if into.has(key) and int(into[key]) > 0 and (int(value) <= 0 or int(into[key]) <= int(value)):
		return
	into[key] = value


# ------------------------------------------------------------- id <-> index

## Id-ul resursei de pe pozitia `index` din `list` (CarData / DriverData), sau
## &"" in afara listei.
static func id_at(list: Array, index: int) -> StringName:
	if index < 0 or index >= list.size() or list[index] == null:
		return &""
	return StringName(list[index].get(&"id"))


## Pozitia resursei cu `id` in `list`, sau -1.
static func index_of(list: Array, id: StringName) -> int:
	if id == &"":
		return -1
	for i in list.size():
		if list[i] != null and StringName(list[i].get(&"id")) == id:
			return i
	return -1


## Id-ul de scris pentru selectia `index`. O selectie DORMANTA (id-ul din fisier
## nu mai exista in joc, iar loader-ul a cazut pe implicitul 0) se scrie inapoi
## neatinsa cat timp jucatorul n-a ales altceva: masina scoasa revine daca
## revine in garaj.
static func selection_id(list: Array, index: int, dormant: StringName) -> StringName:
	if dormant != &"" and index == 0:
		return dormant
	return id_at(list, index)


# ---------------------------------------------------------------- utilitare

static func _copy(from: String, to: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(from)
	if bytes.is_empty() and FileAccess.get_open_error() != OK:
		return false
	var f := FileAccess.open(to, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	return true
