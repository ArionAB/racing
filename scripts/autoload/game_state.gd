extends Node
## Singleton (autoload): stare globala intre scene, puntea touch, setari
## persistate, garaj (masina si soferul alese) si starea campionatului.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const MENU_SCENE: String = "res://scenes/main_menu/MainMenu.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const RECORDS_PATH: String = "user://records.cfg"

## Garajul: toate masinile jucabile. O masina noua = un .tres nou aici.
## Modele: Free Low Poly Vehicles Pack de RgsDev (CC0).
const CAR_DATA: Array[Resource] = [
	preload("res://scenes/cars/data/muscle.tres"),
	preload("res://scenes/cars/data/police_sports.tres"),
	preload("res://scenes/cars/data/taxi.tres"),
	preload("res://scenes/cars/data/bus.tres"),
	preload("res://scenes/cars/data/firetruck.tres"),
	preload("res://scenes/cars/data/buggy.tres"),
	# Garajul v2 (oct 2026): masinile noi stau la COADA, ca indicii de mai sus
	# (Race.AI_CARS, fantomele din cariera, selected_car salvat) sa nu se mute.
	preload("res://scenes/cars/data/ambulance.tres"),
	preload("res://scenes/cars/data/hotrod.tres"),
	preload("res://scenes/cars/data/tow_truck.tres"),
	preload("res://scenes/cars/data/monster.tres"),
]
## Traficul de tuk-tuk-uri (Jodhpur): NU e in garaj (nu se poate alege ca
## masina de jucator/AI de cursa) — separat de CAR_DATA ca sa nu apara din
## greseala in lineup-ul AI_CARS sau la selectia de masina.
const CAR_DATA_TUKTUK: CarData = preload("res://scenes/cars/data/tuktuk.tres")

## Soferii: skinurile figurinei, alese in garaj SEPARAT de masina (decizia
## dezvoltatorului, 17 oct 2026). Un skin nou = un .tres nou aici. Primul e
## implicitul — albastrul, ca pana acum pe masina implicita (Muscle). Perechea
## din `CarData.driver_model` ramane doar pentru AI.
const DRIVER_DATA: Array[Resource] = [
	preload("res://scenes/cars/data/drivers/driver_blue.tres"),
	preload("res://scenes/cars/data/drivers/driver_red.tres"),
	preload("res://scenes/cars/data/drivers/driver_yellow.tres"),
	preload("res://scenes/cars/data/drivers/driver_green.tres"),
]

## Pistele. Primele CHAMP_ROUNDS intra in campionat; restul doar in cursa rapida.
##
## `CHAMP_ROUNDS` a ramas 3 de cand erau trei piste, iar lista a crescut la
## PAISPREZECE — deci campionatul e Dunele + Okinawa manual + Transfagarasan
## (indicii 0-2), si restul sunt doar cursa rapida. Nu e o scapare de reparat
## in graba: lungimea campionatului e decizie de design (3 curse = burst play,
## 14 = alt ritm), si se schimba deliberat, cu `CHAMP_ROUNDS`, nu din reflex.
##
## Pe indexul 2 a stat Alpii (Track09) pana la swap-ul din 14 oct 2026. Deci
## un swap pe primele CHAMP_ROUNDS pozitii schimba si campionatul: aici a fost
## vrut explicit (Transfagarasanul ia runda 3), nu incasat din greseala.
const TRACK_SCENES: Array[String] = [
	"res://scenes/tracks/Track01.tscn",
	"res://scenes/tracks/Track08.tscn",
	# Track21 = INDEXUL 2 (Transfagarasan). PRIMUL SWAP din proiect: pana acum
	# Monument Valley, Okinawa si Transfagarasanul doar se ADAUGASERA la coada,
	# cu nota "pana la swap". Aici Alpii (Track09) IES din lista de joc si
	# Transfagarasanul le ia locul, inclusiv runda 3 de campionat
	# (indexul 2 < CHAMP_ROUNDS): decizia dezvoltatorului, 14 oct 2026, nu
	# un efect secundar — brief transfagarasan.md §8.
	# Track09 RAMANE IN REPO ca banc de test: probe_track09_fracs,
	# probe_alpine_terrain si verify_all_tracks_load il incarca PE CALE
	# ("res://scenes/tracks/Track09.tscn"), nu prin index, deci swap-ul nu le
	# atinge. Uneltele cer Transfagarasanul cu --track=2 SAU --track=21
	# (resolve_track_index il gaseste si dupa numarul scenei).
	"res://scenes/tracks/Track21.tscn", # Transfagarasan = INDEXUL 2
	"res://scenes/tracks/Track10.tscn",
	"res://scenes/tracks/Track11.tscn",
	"res://scenes/tracks/Track12.tscn",
	# Track13 = INDEXUL 6, nu 13. Cele doua conventii traiesc alaturi si
	# `resolve_track_index` de mai jos le impaca; nota e aici fiindca de aici
	# se citeste lista, si fiindca de fiecare data cand s-a adaugat o pista
	# cineva a scris --track= cu numarul scenei (memoria
	# `indici-de-pista-intre-unelte`). `snapshot`/`probe_race` vor 6,
	# `probe_decor`/`survey_terrain` vor 13.
	"res://scenes/tracks/Track13.tscn",
	"res://scenes/tracks/Track14.tscn", # Serengeti = INDEXUL 7
	"res://scenes/tracks/Track15.tscn", # Machu Picchu = INDEXUL 8
	"res://scenes/tracks/Track16.tscn", # Fiordland = INDEXUL 9
	"res://scenes/tracks/Track17.tscn", # Jodhpur = INDEXUL 10
	# Track18 = INDEXUL 11, nu 18 (aceeasi capcana ca la Track13/Track17):
	# `snapshot`/`probe_race`/`probe_layout` vor 11, `probe_decor`/`probe_manual`
	# vor 18 (memoria `probe-decor-numar-de-scena`).
	"res://scenes/tracks/Track18.tscn", # Kyoto = INDEXUL 11
	# Track19 = INDEXUL 12 (Monument Valley, brief monument_valley.md §7): la
	# COADA listei; Dunele (Track01) ramane pe indexul 0 pana la swap — care
	# N-A FOST FACUT inca, desi nota e aici de la inceputul lui oct 2026.
	# Tiparul e swap-ul Transfagarasanului de mai sus: se scrie PE POZITIE,
	# peste Track01, nu se sterge intrarea veche (lista nu are voie sa se
	# taseze — vezi comentariul de pe indexul 2). Indexul 0 e in campionat.
	# Uneltele o adreseaza cu --track=19 (resolve_track_index o gaseste dupa
	# numarul scenei).
	"res://scenes/tracks/Track19.tscn", # Monument Valley = INDEXUL 12
	# Track20 = INDEXUL 13 (Okinawa, brief okinawa.md §7): la COADA listei;
	# Okinawa manual (Track08) ramane pe indexul 1 pana la swap — care, ca la
	# Monument Valley, N-A FOST FACUT inca. Acelasi tipar: PE POZITIE, peste
	# Track08. Indexul 1 e in campionat. Uneltele o
	# adreseaza cu --track=20 (resolve_track_index o gaseste dupa numarul scenei;
	# probe_decor/probe_manual vor 20, snapshot/probe_race/probe_layout vor 13 SAU 20).
	"res://scenes/tracks/Track20.tscn", # Okinawa = INDEXUL 13
	# Track22 = INDEXUL 14 (Ha Long, brief halong.md §7). Prima pista care se
	# ADAUGA fara sa inlocuiasca nimic: Monument Valley, Okinawa si
	# Transfagarasanul luaseră locul Dunelor, Okinawei manuale si Alpilor, deci
	# aici NU urmeaza un swap.
	#
	# INDEXUL 14, nu 15: la integrarea cu main, swap-ul Transfagarasanului (care
	# l-a mutat pe INDEXUL 2, peste Alpii) a scos intrarea lui de la coada, deci
	# Ha Long urca cu o poziţie. Pe ramura de fundatie era 15, cand Track21 era
	# inca la coada.
	#
	# Uneltele o adreseaza cu --track=22 (resolve_track_index o gaseste dupa
	# numarul scenei); probe_decor/probe_manual vor 22, snapshot/probe_race/
	# probe_layout vor 14 SAU 22 (memoria probe-decor-numar-de-scena).
	"res://scenes/tracks/Track22.tscn", # Ha Long = INDEXUL 14
	# Track23 = INDEXUL 15 (Carrara, brief carrara.md): la COADA listei, fara swap. Uneltele o
	# adreseaza cu --track=15 (snapshot / probe_race / probe_layout / probe_buried) SAU --track=23
	# (resolve_track_index o gaseste dupa numarul scenei); probe_decor / probe_manual iau DOAR
	# numarul scenei, 23 (memoria `probe-decor-numar-de-scena`).
	"res://scenes/tracks/Track23.tscn", # Carrara = INDEXUL 15
]
const TRACK_NAMES: Array[String] = [
	"Dunele", "Okinawa manual", "Transfagarasan", "Baikal", "Stromboli",
	"Chongqing", "Cappadocia", "Serengeti", "Machu Picchu", "Fiordland",
	"Jodhpur", "Kyoto", "Monument Valley", "Okinawa", "Ha Long", "Carrara",
]
const CHAMP_ROUNDS: int = 3


## Traduce un `--track=N` de pe linia de comanda in POZITIE din TRACK_SCENES.
##
## Uneltele din tools/ folosesc doua conventii, si amandoua sunt legitime:
## `snapshot`/`probe_race` iau POZITIA din lista asta (Stromboli = 4), fiindca
## pornesc o cursa prin GameState.selected_track; `probe_decor`/`survey_terrain`
## iau NUMARUL SCENEI (Track11 = 11), fiindca baleiaza fisierele direct de pe
## disc, inclusiv piste care nu sunt in lista.
##
## Pana acum `snapshot` facea `clampi()` pe numar: un `--track=11` dat din
## reflex devenea TACUT indexul 4. Pe Stromboli a nimerit pista buna din pur
## noroc, dar `--track=8` pentru Okinawa ar fi randat tot Stromboli si ar fi
## trecut drept dovada ca "Okinawa e neschimbata". O verificare care nu poate
## da gres nu verifica nimic.
##
## Deci: indexul CASTIGA (orice comanda veche merge la fel), iar un numar care
## nu e index valid dar e numar de scena din lista se rezolva ca numar de scena,
## in loc sa fie retezat. Ce nu e nici una, nici alta -> -1, adica eroare la
## apelant. Singurul numar ambiguu e 1 (index -> Track08, scena -> Track01) si
## se rezolva ca index, ca sa nu se schimbe sub picioare comenzile existente.
static func resolve_track_index(n: int) -> int:
	if n >= 0 and n < TRACK_SCENES.size():
		return n
	var wanted := "res://scenes/tracks/Track%02d.tscn" % n
	return TRACK_SCENES.find(wanted)


## Numele lizibil pentru un index deja rezolvat — pentru mesajele uneltelor.
static func track_label(index: int) -> String:
	if index < 0 or index >= TRACK_SCENES.size():
		return "?"
	return "%s (%s)" % [TRACK_NAMES[index],
		String(TRACK_SCENES[index]).get_file().get_basename()]

## Scena pistei curente: suprascrierea sondei, altfel din lista de joc.
func current_track_scene() -> String:
	if not track_scene_override.is_empty():
		return track_scene_override
	return TRACK_SCENES[selected_track]


## Puncte pe pozitie (locul 1..6). Lista TREBUIE sa aiba cel putin atatea
## intrari cate masini sunt in cursa: `record_results` indexeaza cu rangul.
const CHAMP_POINTS: Array[int] = [10, 8, 6, 4, 2, 1]

# Config cursa.
var total_laps: int = 3
## Adversarii. 5 AI + jucatorul = 6 masini pe grila.
var ai_count: int = 5
## Suprascrie `Track.traffic_count` la constructie — vezi `Race._ready`
## (`track.traffic_count = traffic_override` cand >= 0). -1 (implicit) =
## neatins, fiecare pista foloseste `traffic_count` propriu (0 pe toate in
## afara de Jodhpur). Acelasi tipar ca `ai_count`: singurul punct din care
## `tools/probe_race.gd` poate injecta `--traffic=N` INAINTE ca `Race._ready`
## sa apuce sa cheme `_spawn_traffic()` — `Race` isi construieste pista si isi
## cheama proprul `_ready` sincron, in interiorul lui `add_child`, deci nu
## exista alt moment in care sonda sa apuce sa scrie pe `track` direct.
var traffic_override: int = -1
## Lineup-ul AI pentru sonde (`tools/car_balance.sh` prin `ProbeRace
## --ai-cars=`): indecsi in `CAR_DATA`, unul per adversar, in ordinea
## sloturilor. Gol (implicit) = `Race.AI_CARS`, lineup-ul jocului. Acelasi
## tipar ca `traffic_override`: singurul punct din care o sonda poate schimba
## grila INAINTE ca `Race._spawn_cars` sa ruleze. O lista mai scurta decat
## `ai_count` se repeta ciclic, ca si `AI_CARS`. Matricea de echilibru pune
## toate cele 6 masini din garaj pe aceeasi grila (docs/cariera §2.1, §11 pas 0).
var ai_cars_override: Array[int] = []
## Scena de pista folosita IN LOC de `TRACK_SCENES[selected_track]` (sonde:
## piste sintetice care nu trebuie sa intre in lista de joc, ex. tools/
## SondaCarraraB.tscn). Gol (implicit) = lista. Acelasi tipar ca
## `traffic_override`: singurul punct din care o sonda poate schimba pista
## INAINTE ca `Race._ready` sa o incarce. Vezi `current_track_scene()`.
var track_scene_override: String = ""

# Selectii (masina si soferul alese se persista).
var selected_car: int = 0
## Index in DRIVER_DATA. Se aplica DOAR masinii jucatorului, pe orice caroserie
## deschisa; AI-ul isi tine figurina din .tres.
var selected_driver: int = 0
var selected_track: int = 0
## Panoul pe care MainMenu il deschide direct la intrare (&"career" dupa o
## cursa de cariera). Citit o singura data si golit.
var menu_open_panel: StringName = &""


## Figurina aleasa in garaj, gata de dat lui `Car.apply_data` ca override.
func selected_driver_model() -> PackedScene:
	return (DRIVER_DATA[selected_driver] as DriverData).model

# Campionat: 3 curse, punctaj cumulat per "slot" (0 = jucatorul, 1.. = AI).
var champ_active: bool = false
var champ_round: int = 0
## Un slot per masina din cursa; se dimensioneaza din `ai_count`, nu cu o lista
## scrisa de mana — altfel adaugarea unui adversar iese in afara tabloului.
## Se reface la fiecare `start_championship`; valoarea de aici e doar ca tabloul
## sa nu fie gol daca il citeste cineva inainte de prima cursa.
var champ_points: Array[int] = [0, 0, 0, 0, 0, 0]

# Setari utilizator (persistate).
var steer_sensitivity: float = 1.0
var sfx_volume: float = 1.0
var engine_volume: float = 1.0

# Camera: FACTORI peste valorile din ChaseCamera, nu cote absolute.
#
# Asa reglajul jucatorului supravietuieste unei schimbari a camerei de baza (si
# invers: cand tunam camera in cod, nu calcam peste preferinta lui), iar
# scalarea per vehicul — autobuzul sta mai departe decat muscle car-ul — ramane
# intacta: se inmulteste, nu se inlocuieste.
var cam_distance_scale: float = 1.0
var cam_height_scale: float = 1.0
var cam_fov_scale: float = 1.0
## Cat de repede se aseaza camera in spatele masinii. Sub 1.0 = mai lenesa.
var cam_follow_scale: float = 1.0

## Contorul de performanta din HUD (FPS, desene, triunghiuri, timp GPU).
## E prima unealta pe care o pornesti pe telefon: fara ea, "merge prost" nu
## are cifra, iar cifra e singura care spune DACA sunt umbrele, ceata sau
## particulele. Persistat ca sa nu-l repornesti la fiecare build.
var show_perf: bool = false

## TEST (optiunea D din oct 2026): un SpotLight3D adevarat pe farurile
## masinii jucatorului, pe pistele de noapte, in locul baltii de lumina false.
## Setare ca sa se poata compara la volan, din pauza; prima de stins daca
## device-ul nu tine 60 fps (vezi CarLights).
var real_headlight: bool = true
## Vibratie la impacturi, aterizari dure si pornirea turbo-ului (telefon si
## manete). Doar jucatorul; implicit pornita. Vezi HapticsFeed.
var haptics_enabled: bool = true
## NIVELUL GRAFIC — comutatorul de device din planul de grafica pe mobil.
##   0 = ECONOMIC: fara umbre dinamice, fara glow, randare 3D la ~720 px
##       inaltime pe telefon. Ce ramane e AO-ul copt + blob-ul masinii.
##   1 = NORMAL (implicit): umbre + glow; pe telefon randarea 3D la ~864 px
##       inaltime si MSAA 4x (pe un GPU cu placi 4x la 0.75 e mai ieftin si
##       mai curat decat 2x la nativ); pe desktop rezolutie nativa.
##       Pe telefon umbra e in PROFILUL IEFTIN (vezi SHADOW_DISTANCE_MOBILE).
##   2 = MAXIM: totul, la rezolutie nativa, MSAA 4x, umbra cum o cere tema.
## Umbrele si glow-ul se citesc la construirea pistei (Track.gfx_tier), deci
## schimbarea lor se vede la urmatoarea cursa; scala si MSAA se aplica pe loc.
const GFX_TIER_NAMES: Array[String] = ["Low", "Normal", "High"]
var gfx_tier: int = 1

## PROFILUL IEFTIN DE UMBRA al telefonului pe Normal (26 oct 2026). Pe iPhone
## 12 Pro, Kyoto si Jodhpur cadeau pe Normal cu umbre „chiar si cu 1 felie".
## Masurat cu ProbePerf --mobile: 2 felii -> 1 felie taie ~10% din costul
## umbrei, umbra stinsa taie ~30% din cadru. Deci costul NU e in cascade, e in
## pixelii care PRIMESC umbra: fiecare pixel luminat pana la `shadow_distance`
## (90 m) citeste harta de umbra cu filtrul moale (soft_shadow_filter_quality
## 2 = 4 esantioane; implicitul Godot pe mobil e 0 = Hard, 1 esantion).
## Profilul schimba exact asta: filtru Hard, plafon de distanta (pixelii de
## dincolo sar peste citire; harta de 2048 ajunge la 37 texeli/m, deci muchia
## dura ramane mica) si o singura cascada (fara banda de amestec intre felii,
## care citeste ambele harti). Nivelul MAXIM pastreaza reglajele temei; pe
## desktop nu se aplica (bugetul de acolo nu e cel de pe telefon).
const SHADOW_DISTANCE_MOBILE: float = 55.0
## Pragul de LOD al mesh-urilor importate (px pe ecran sub care se trece la
## nivelul mai grosier), per nivel, pe telefon: Economic / Normal / Maxim.
## Masurat pe Jodhpur: 8 px taie ~23% din triunghiuri; pe desktop ramane 1.
const MESH_LOD_PX_MOBILE: Array[float] = [8.0, 4.0, 1.0]
## Starea EFECTIVA a filtrului de umbra (RenderingServer n-are getter), citita
## de HUD pentru linia de optiuni.
var shadow_filter_hard: bool = false
var _shadow_atlas_px: int = 0

# Puntea touch. Conventia ecranului: -1 = stanga, +1 = dreapta.
var touch_steer: float = 0.0
var touch_drift: bool = false
var touch_turbo: bool = false
## Gazul, de cand acceleratia e explicita (oct 2026): butonul ^ din
## dreapta-jos. Inainte orice deget pe ecran insemna gaz (auto-accelerate).
var touch_gas: bool = false
## Frana / marsarierul (butonul v). Aceeasi comanda: `throttle < 0` franeaza
## cat mergi inainte, si devine marsarier cand aproape ai oprit.
var touch_brake: bool = false
## Cel putin un deget pe ecran. NU mai comanda gazul (auto-accelerate a fost
## scos in oct 2026) — a ramas doar informativ, pentru sonde.
var touch_active: bool = false

# Best lap per pista (nume pista -> milisecunde), persistat. Cheia e numele,
# nu indexul: la stergerea sau reordonarea unei piste, indexul ramas liber era
# mostenit de alta pista si-i afisa recordul altcuiva.
var records: Dictionary = {}
## Recordul pe toata cursa (#498), separat de cel pe tur: cheie
## `race_record_key` (pista + numarul de ture — un record pe 3 ture nu se
## compara cu unul pe 5), valoare in ms.
var race_records: Dictionary = {}

func _ready() -> void:
	load_settings()
	load_records()
	apply_gfx_tier()


## Aplica nivelul grafic pe ce se poate schimba PE LOC: scala de randare 3D
## si MSAA pe viewport-ul radacina, plus steagul static pe care il citeste
## Track la construirea pistei (umbre, glow). Track e @tool si nu poate
## atinge un autoload din editor, de aceea nu citeste GameState direct.
##
## Scala se da ca INALTIME-TINTA, nu ca factor: un iPhone are 1170-1290 px
## pe inaltime in landscape, un iPad 1640+, un desktop 720-1440 — acelasi
## 0.75 ar insemna altceva pe fiecare. Pe desktop ramane nativ la orice
## nivel: dezvoltatorul trebuie sa vada cadrul intreg, iar bugetul de acolo
## nu e cel de pe telefon.
func apply_gfx_tier() -> void:
	Track.gfx_tier = gfx_tier
	var vp := get_viewport()
	if vp == null:
		return
	var mobile := OS.has_feature("mobile")
	# Profilul ieftin de umbra (vezi SHADOW_DISTANCE_MOBILE): plafonul si
	# cascada unica le citeste Track la construirea soarelui, filtrul se
	# aplica pe loc, global.
	var cheap_shadows := mobile and gfx_tier == 1
	Track.shadow_distance_cap = SHADOW_DISTANCE_MOBILE if cheap_shadows else 0.0
	Track.shadow_single_split = cheap_shadows
	_set_shadow_filter(cheap_shadows or _project_shadow_filter() == RenderingServer.SHADOW_QUALITY_HARD)
	_set_shadow_atlas(_project_shadow_size())
	vp.mesh_lod_threshold = MESH_LOD_PX_MOBILE[gfx_tier] if mobile else 1.0
	if mobile:
		var target_h: float = [720.0, 864.0, 100000.0][gfx_tier]
		# Inaltimea in PIXELI FIZICI, nu `get_visible_rect()`: cu
		# `stretch/mode = canvas_items` rect-ul vizibil e in coordonatele de
		# baza (720 de inaltime pe orice ecran), deci 864/720 iesea peste 1 si
		# scala ramanea mereu nativa — pe iPhone 12 Pro (1170 px) nici
		# Economic, nici Normal nu coborau rezolutia.
		var h := float(DisplayServer.window_get_size().y)
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = clampf(target_h / maxf(h, 1.0), 0.5, 1.0)
		# MSAA 4x doar la MAXIM (27 oct 2026). Pe iPhone 12 Pro limita e costul
		# pe pixel (testele v2/v3 pe Jodhpur: Economic cu 2x tine 58 fps la
		# acelasi continut la care Normal cu 4x tinea 44), iar dezvoltatorul
		# cere 60 fps constant. 2x pe 864p e compromisul; comutatorul de test
		# „MSAA" din SETARI il poate intoarce la 4x pentru comparatie.
		vp.msaa_3d = Viewport.MSAA_4X if gfx_tier == 2 else Viewport.MSAA_2X
	else:
		# Pe desktop valorile se scriu explicit (nu doar la Maxim), ca un
		# comutator de test intors pe „Nivel" sa revina la ele.
		vp.msaa_3d = Viewport.MSAA_4X if gfx_tier == 2 else Viewport.MSAA_2X
		vp.scaling_3d_scale = 1.0
	apply_debug_gfx()


## COMUTATOARELE DE TEST PE DEVICE (oct 2026). Primele teste pe iPhone 12 Pro
## au aratat ca limita e costul per PIXEL: pe Jodhpur, Economic tine 58 fps
## in medie, iar Normal 44 fps la acelasi continut. Economic schimba insa patru
## lucruri deodata (rezolutie, MSAA, umbre, glow). Comutatoarele astea le despart:
## se schimba din SETARI, in pauza, si se aplica pe loc. HUD-ul (care ruleaza si
## in pauza) arata fps-ul si optiunile efectiv active.
##
## Doar pe sesiune, NU se salveaza: un test uitat pe „Off" nu trebuie sa ramana
## in jocul normal. Indexul 0 = „Nivel", adica ce da nivelul grafic ales.
## Testele pornesc de pe Normal si STING lucruri; aprinderea unei umbre sau a
## unui glow pe care nivelul nu l-a construit foloseste reglajele implicite
## ale Godot, nu pe cele ale temei.
const DBG_MSAA_NAMES: Array[String] = ["Tier", "Off", "2x", "4x"]
const DBG_SCALE_NAMES: Array[String] = ["Tier", "540p", "648p", "720p", "864p", "Native"]
const DBG_SCALE_H: Array[float] = [0.0, 540.0, 648.0, 720.0, 864.0, 100000.0]
const DBG_SHADOW_NAMES: Array[String] = ["Tier", "Off", "1 split", "2 splits"]
const DBG_GLOW_NAMES: Array[String] = ["Tier", "Off", "On"]
## Comutatoarele de umbra pe PIXEL (26 oct 2026): filtrul, distanta si harta.
## Astea despart costul pe care „Off / 1 felie / 2 felii" nu-l despartea:
## cat platesc pixelii care primesc umbra, nu cati casteri intra in pasa.
const DBG_SHADOW_FILTER_NAMES: Array[String] = ["Tier", "Hard", "Soft"]
const DBG_SHADOW_DIST_NAMES: Array[String] = ["Tier", "40 m", "55 m", "70 m", "90 m"]
const DBG_SHADOW_DIST_M: Array[float] = [0.0, 40.0, 55.0, 70.0, 90.0]
const DBG_SHADOW_SIZE_NAMES: Array[String] = ["Tier", "1024", "2048", "4096"]
const DBG_SHADOW_SIZE_PX: Array[int] = [0, 1024, 2048, 4096]
const DBG_LOD_NAMES: Array[String] = ["Tier", "1 px", "4 px", "8 px"]
const DBG_LOD_PX: Array[float] = [0.0, 1.0, 4.0, 8.0]
var dbg_msaa: int = 0
var dbg_scale: int = 0
var dbg_shadows: int = 0
var dbg_glow: int = 0
var dbg_shadow_filter: int = 0
var dbg_shadow_dist: int = 0
var dbg_shadow_size: int = 0
var dbg_lod: int = 0

## Aplica comutatoarele de test peste nivelul grafic. Se cheama la sfarsitul
## lui `apply_gfx_tier`, la pornirea cursei (pista abia si-a construit soarele)
## si la fiecare schimbare din SETARI.
func apply_debug_gfx() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if dbg_msaa > 0:
		vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X,
			Viewport.MSAA_4X][dbg_msaa - 1]
	if dbg_scale > 0:
		var h := float(DisplayServer.window_get_size().y)
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = clampf(DBG_SCALE_H[dbg_scale] / maxf(h, 1.0), 0.25, 1.0)
	if dbg_lod > 0:
		vp.mesh_lod_threshold = DBG_LOD_PX[dbg_lod]
	# Filtrul si harta de umbra sunt globale (RenderingServer); valoarea de
	# nivel a fost scrisa de `apply_gfx_tier` chiar inainte, deci aici doar
	# suprascriem cand comutatorul nu e pe „Nivel".
	if dbg_shadow_filter > 0:
		_set_shadow_filter(dbg_shadow_filter == 1)
	if dbg_shadow_size > 0:
		_set_shadow_atlas(DBG_SHADOW_SIZE_PX[dbg_shadow_size])
	# Soarele si mediul pistei: valorile date de nivel se tin in metadata la
	# prima atingere, ca „Nivel" sa le poata pune inapoi exact.
	for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		var sun := n as DirectionalLight3D
		if not sun.has_meta(&"dbg_orig"):
			sun.set_meta(&"dbg_orig", [sun.shadow_enabled, sun.directional_shadow_mode,
				sun.directional_shadow_max_distance])
		var orig: Array = sun.get_meta(&"dbg_orig")
		match dbg_shadows:
			0:
				sun.shadow_enabled = orig[0]
				sun.directional_shadow_mode = orig[1]
			1:
				sun.shadow_enabled = false
			2:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			3:
				sun.shadow_enabled = true
				sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
		sun.directional_shadow_max_distance = DBG_SHADOW_DIST_M[dbg_shadow_dist] \
			if dbg_shadow_dist > 0 else float(orig[2])
	for n in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		var we := n as WorldEnvironment
		if we.environment == null:
			continue
		if not we.has_meta(&"dbg_orig"):
			we.set_meta(&"dbg_orig", we.environment.glow_enabled)
		if dbg_glow == 0:
			we.environment.glow_enabled = bool(we.get_meta(&"dbg_orig"))
		else:
			we.environment.glow_enabled = dbg_glow == 2


## Filtrul hartii de umbra directionale, global. Hard = un esantion per pixel
## (hardware compare); Soft = cel din project.godot (`soft_shadow_filter_quality`,
## cu sufixul .mobile pe telefon). In Forward Mobile numarul de esantioane e o
## constanta de specializare, deci prima schimbare recompileaza pipeline-urile:
## un sughit la comutare, nimic pe cadru dupa.
func _set_shadow_filter(hard: bool) -> void:
	shadow_filter_hard = hard
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_HARD if hard else _project_shadow_filter())


## Harta de umbra directionala (atlasul), global; se realoca doar cand se
## schimba marimea.
func _set_shadow_atlas(px: int) -> void:
	if px == _shadow_atlas_px:
		return
	_shadow_atlas_px = px
	var bits16 := bool(ProjectSettings.get_setting_with_override(
		&"rendering/lights_and_shadows/directional_shadow/16_bits"))
	RenderingServer.directional_shadow_atlas_set_size(px, bits16)


## Marimea efectiva a hartii de umbra (px), pentru linia de optiuni din HUD.
func shadow_atlas_px() -> int:
	return _shadow_atlas_px


func _project_shadow_filter() -> RenderingServer.ShadowQuality:
	return int(ProjectSettings.get_setting_with_override(
		&"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality")) \
		as RenderingServer.ShadowQuality


func _project_shadow_size() -> int:
	return int(ProjectSettings.get_setting_with_override(
		&"rendering/lights_and_shadows/directional_shadow/size"))


## Returneaza true daca timpul e record nou pe pista respectiva.
func try_record(track_index: int, lap_ms: int) -> bool:
	var key := TRACK_NAMES[track_index]
	var best := int(records.get(key, 0))
	if best > 0 and lap_ms >= best:
		return false
	records[key] = lap_ms
	save_records()
	return true

func best_lap(track_index: int) -> int:
	return int(records.get(TRACK_NAMES[track_index], 0)) # 0 = niciun record inca

## Cheia recordului de cursa: aceeasi pista pe alt numar de ture e alta proba.
static func race_record_key(track_index: int, laps: int) -> String:
	return "%s@%d" % [TRACK_NAMES[track_index], laps]

## Ca `try_record`, pentru timpul TOTAL al cursei, pe numarul curent de ture.
func try_race_record(track_index: int, race_ms: int) -> bool:
	var key := race_record_key(track_index, total_laps)
	var best := int(race_records.get(key, 0))
	if best > 0 and race_ms >= best:
		return false
	race_records[key] = race_ms
	save_records()
	return true

## 0 = niciun record de cursa inca (pe numarul curent de ture).
func best_race(track_index: int) -> int:
	return int(race_records.get(race_record_key(track_index, total_laps), 0))

func load_records() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RECORDS_PATH) != OK:
		return
	for track_name in TRACK_NAMES:
		var ms := int(cfg.get_value("records", track_name, 0))
		if ms > 0:
			records[track_name] = ms
	if cfg.has_section("race_records"):
		for key in cfg.get_section_keys("race_records"):
			var ms := int(cfg.get_value("race_records", key, 0))
			if ms > 0:
				race_records[key] = ms

func save_records() -> void:
	var cfg := ConfigFile.new()
	for track_name in records:
		cfg.set_value("records", track_name, records[track_name])
	for key in race_records:
		cfg.set_value("race_records", key, race_records[key])
	cfg.save(RECORDS_PATH)

# ------------------------------------------------------------------ flux

func start_quick_race(track_index: int) -> void:
	champ_active = false
	Career.leave()
	selected_track = track_index
	start_race()

func start_championship() -> void:
	Career.leave()
	champ_active = true
	champ_round = 0
	champ_points.clear()
	champ_points.resize(ai_count + 1) # un slot per masina, jucatorul inclus
	selected_track = 0
	start_race()

## order_slots[rank] = slotul de pe locul rank (0 = jucator).
func record_results(order_slots: Array) -> void:
	# Grila poate fi mai mare decat baremul de puncte: sub ultima pozitie
	# punctata nu se mai da nimic, in loc sa iasa din tablou.
	for rank in order_slots.size():
		if rank >= CHAMP_POINTS.size():
			break
		champ_points[int(order_slots[rank])] += CHAMP_POINTS[rank]

func champ_is_last_round() -> bool:
	return champ_round >= CHAMP_ROUNDS - 1

func champ_next_race() -> void:
	champ_round += 1
	selected_track = champ_round
	start_race()

func start_race() -> void:
	reset_touch()
	_loading_screen = true
	get_tree().change_scene_to_file(RACE_SCENE)

## Cursa pornita din joc trece prin ecranul de incarcare. Race citeste flagul
## o singura data, in _ready, si il sterge; sondele care instantiaza Race
## direct nu trec pe aici, deci raman pe drumul sincron.
var _loading_screen: bool = false

func take_loading_screen() -> bool:
	var v := _loading_screen
	_loading_screen = false
	return v

func go_to_menu() -> void:
	champ_active = false
	Career.leave() # iesirea prin MENU inchide si cursa de cariera
	reset_touch()
	get_tree().change_scene_to_file(MENU_SCENE)

func reset_touch() -> void:
	touch_steer = 0.0
	touch_drift = false
	touch_turbo = false
	touch_gas = false
	touch_brake = false
	touch_active = false

# ---------------------------------------------------------------- setari

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	steer_sensitivity = float(cfg.get_value("input", "steer_sensitivity", 1.0))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", 1.0))
	engine_volume = float(cfg.get_value("audio", "engine_volume", 1.0))
	selected_car = clampi(int(cfg.get_value("game", "selected_car", 0)),
		0, CAR_DATA.size() - 1)
	selected_driver = clampi(int(cfg.get_value("game", "selected_driver", 0)),
		0, DRIVER_DATA.size() - 1)
	# Limitele sunt cele ale sliderelor din SettingsPanel: un fisier de setari
	# stricat de mana n-are voie sa scoata camera in alta galaxie.
	cam_distance_scale = clampf(
		float(cfg.get_value("camera", "distance_scale", 1.0)), 0.5, 2.0)
	cam_height_scale = clampf(
		float(cfg.get_value("camera", "height_scale", 1.0)), 0.4, 2.0)
	cam_fov_scale = clampf(
		float(cfg.get_value("camera", "fov_scale", 1.0)), 0.7, 1.3)
	cam_follow_scale = clampf(
		float(cfg.get_value("camera", "follow_scale", 1.0)), 0.4, 2.5)
	show_perf = bool(cfg.get_value("debug", "show_perf", false))
	real_headlight = bool(cfg.get_value("debug", "real_headlight", true))
	gfx_tier = clampi(int(cfg.get_value("video", "gfx_tier", 1)), 0, 2)
	haptics_enabled = bool(cfg.get_value("input", "haptics", true))

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "steer_sensitivity", steer_sensitivity)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "engine_volume", engine_volume)
	cfg.set_value("game", "selected_car", selected_car)
	cfg.set_value("game", "selected_driver", selected_driver)
	cfg.set_value("camera", "distance_scale", cam_distance_scale)
	cfg.set_value("camera", "height_scale", cam_height_scale)
	cfg.set_value("camera", "fov_scale", cam_fov_scale)
	cfg.set_value("camera", "follow_scale", cam_follow_scale)
	cfg.set_value("debug", "show_perf", show_perf)
	cfg.set_value("debug", "real_headlight", real_headlight)
	cfg.set_value("video", "gfx_tier", gfx_tier)
	cfg.set_value("input", "haptics", haptics_enabled)
	cfg.save(SETTINGS_PATH)


## Readuce camera la valorile din cod (ChaseCamera), fara sa atinga restul
## setarilor. Exista ca sa se poata iesi dintr-un reglaj gresit fara stergerea
## fisierului de setari.
func reset_camera_settings() -> void:
	cam_distance_scale = 1.0
	cam_height_scale = 1.0
	cam_fov_scale = 1.0
	cam_follow_scale = 1.0
	save_settings()
