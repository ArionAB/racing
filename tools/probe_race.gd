extends Node
## Sonda de TUNARE: masoara ce simti pe pista, dar in cifre. Doua moduri, ambele
## headless, ca sa poti compara "inainte / dupa" la fiecare schimbare de fizica
## sau de AI (CLAUDE.md: verificare cu sonde inainte de commit).
##
##   race  — o cursa cu 4 AI pe o pista: tururi, timp in afara soselei, timp
##           mers incet, marsarier de anti-blocaj, repuneri, izbituri in pereti,
##           imbranceli si lovituri de la obstacolele mobile.
##   bump  — matricea de imbranceli intre masini: cine pe cine arunca si cu cat.
##           Aici se vede daca "grea impinge, usoara zboara" e adevarat.
##   cliff — arunca masini in unghi in peretii de canion, in mai multe puncte de
##           pe traseu, si raporteaza daca vreuna ramane intepenita. Peretii sunt
##           ~130 de forme convexe puse cap la cap; imbinarile dintre ele sunt
##           exact locul unde o masina se poate agata.
##
## Rulare (ca SCENA, nu ca --script: avem nevoie de autoload-urile GameState /
## AudioManager, iar acelea nu exista in modul --script):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn
##   ... -- --mode=bump
##   ... -- --mode=race --track=0 --seconds=150 [--car=0] [--traffic=N]
##   ... -- --mode=cliff --track=0
##
## `--traffic=N` (Jodhpur, brief §4(c)): suprascrie `Track.traffic_count`
## INAINTE de constructia pistei — vezi GameState.traffic_override. Pe orice
## pista in afara de Jodhpur (Track17), traficul e doar corpuri `Car` in plus
## pe traseul EI (nu are gimmick-ul de banda stanga), util strict pentru
## harnasul sintetic de comparatie A/B, nu pentru verdictul final (memoria
## `harnas-sintetic-comportament-emergent`: verdictul real se da pe Jodhpur).
##   ... -- --mode=race --track=11 --ai=7 --seed=3 --seconds=260 [--no-tub]
##                             KYOTO (Track18, brief §7 pasul 3): 8 masini, cifre
##                             pe TUR (minim/mediu), saritura de pe scena (C2:
##                             treceri/caderi), banda E' si tubul shishi-odoshi.
##                             `--no-tub` scoate tubul din scena INAINTE de
##                             prima fizica: A/B-ul costului tubului (memoria
##                             `proberace-nedeterminism`: se compara
##                             DISTRIBUTII pe 16 seed-uri, nu o rulare).
##   ... -- --mode=race --track=4 --dusk=1.0
##                             CEASUL DE LUMINA (DuskCycle, Jodhpur) fortat la
##                             fractia data, vezi `_force_dusk` mai jos. Fara
##                             el, `GameState.total_laps = 99` din modul race
##                             tine progresul (deci `dusk` din `Race`) mereu
##                             aproape de 0.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
## `--slice=a,b`: felia de traseu (fractii) raportata separat. (-1,-1) = fara.
var _slice: Vector2 = Vector2(-1.0, -1.0)
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Seed fix: fixeaza ZARURILE (rocket start, variatia de viteza, linia
## fiecarui AI), ca "inainte / dupa" sa porneasca din aceeasi cursa.
##
## [b]NU fixeaza si fizica, si asta trebuie stiut inainte de a citi o cifra ca
## pe o regresie.[/b] Jolt ruleaza pe mai multe fire, iar ordinea in care
## rezolva insulele de contact depinde de cum arata arborele de broadphase —
## deci de cate corpuri si cate triunghiuri de coliziune sunt in lume. Doua
## rulari ale ACELUIASI cod, cu ACELASI seed, pot da rezultate diferite, si
## masurat chiar dau: pe Track12 seed 3 a dat 2 repuneri intr-o rulare si
## 0/0/0 in urmatoarele trei, fara nicio schimbare de cod intre ele.
##
## Consecinta practica, verificata pe pasajul rotativ din Chongqing: orice
## schimbare care taie sau adauga geometrie de coliziune rearanjeaza arborele
## si perturba contactele pe TOATA pista, inclusiv la 366 m de locul schimbat
## si la 20 s inainte ca vreo masina sa ajunga acolo. Gaura din carosabilul de
## sub tronson scoate 304 triunghiuri din corpul soselei (76108 -> 75804), si
## atat a fost de ajuns ca pe seed 2 pilotul sa fie imbrancit de pe cornisa la
## frac 0.30 in fiecare rulare — desi lumea de la cornisa e IDENTICA bit cu bit
## (amprenta de raycast 32719.8205 in ambele variante).
##
## [b]„Determinist + se comuta dintr-un steag” NU inseamna cauzal[/b] — si
## asta nu e o opinie, e masurat. Tentatia e mare: doua repuneri care apar la
## ACEEASI milisecunda si in ACEEASI pozitie in fiecare rulare, si care dispar
## cand stingi un steag, arata exact ca o relatie cauzala. Trei runde la rand
## au tras concluzia asta despre gaura din carosabilul pasajului rotativ.
##
## [b]Cat de mica e perturbatia care ajunge.[/b] Doua apeluri `print` adaugate
## in `race.gd`, pe ramuri care nu se executa NICIODATA in rularea masurata
## (nu s-a tiparit nimic), au mutat repunerile de pe seed 2 de la t=30.8/37.6 s
## la t=42.2/59.4 s, si numarul de la 2,2,2 la 2,2,3. Cod mort, zero schimbari
## in lume, alt rezultat.
##
## [b]De UNDE pleaca diferenta.[/b] Cu trasoare IDENTICE pe amandoua partile
## (acelasi seed, acelasi numar de print-uri, deci acelasi cost), pozitia
## fiecarei masini comparata cadru cu cadru se despica asa:
##
##   t =  6.70 s   prima diferenta: 1 CENTIMETRU, pe car2 (un AI), la frac
##                 0.018 — dreapta de start, y 65, ruta 0, viteza constanta,
##                 fara niciun hazard, la un sfert de tur de cornisa
##   t =  8.05 s   1.25 m          t =  9.05 s    9.7 m
##   t = 10.05 s     31 m          t = 13.05 s     68 m
##   t = 29.40 s   ~50 m           <- abia ACUM masina cade de pe cornisa
##
## Adica la momentul caderii cele doua rulari au masinile la zeci de metri una
## de alta: nu se compara acelasi eveniment in doua variante, se compara doua
## curse diferite. Nici cauza caderii nu e o imbranceala — masina intra pe
## cornisa cu 5 m mai la stanga (x -250.9 fata de -246.0 la acelasi index) si
## deja incetinind (24.8 fata de 31.4 m/s).
##
## [b]Izolarea care inchide subiectul.[/b] Pe ramura INTREAGA — rutele noi,
## testul de etaj din `resolve_route`, ocolul, codul nou de AI, tot — cu
## `PROBE_NO_ROAD_HOLE=1`, adica singura variabila stinsa fiind gaura din
## carosabil, seed 2 da 0, 0, 0. Deci cele 261 de linii noi din `track.gd`
## (indexare, progres, `closest_index_global`, ordinea rutelor) NU sunt cauza:
## sunt toate active cand cifra e 0. Ce misca seed 2 e strict inventarul de
## triunghiuri de coliziune al soselei (304 scoase, 76108 -> 75804), prin
## ordinea in care Jolt isi imparte arborele de broadphase.
##
## Acelasi comutator da si perechea cea mai stransa care se poate face —
## acelasi binar, acelasi cod, un singur steag — pe 16 seed-uri x 150 s:
##
##   seed:        1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
##   cu gaura:    0  2  0  0  0  0  0  0  0  0  0  0  0  0  0  0
##   fara gaura:  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
##
## Un singur seed din 16 se misca, si acela e chiar cel pe care s-a construit
## acuzatia. Restul de 15 sunt identici cu gaura pornita.
##
## [b]Si cat de „determinist" e seed 2 de fapt.[/b] Pe starea finala, cu ZERO
## linii de cod runtime schimbate (`scenes/` neatins, doar comentarii aici),
## noua rulari consecutive au dat 2, 2, 3, 2, 2, 2, 2, 2, 2. Chiar si cifra
## „stabila" fluctueaza intre rulari ale aceluiasi binar.
##
## [b]Regula care ramane in picioare.[/b] O repunere pe o muchie expusa e o
## proprietate a MUCHIEI, nu a schimbarii care a reasezat zarurile. Ca sa
## acuzi o schimbare de o regresie iti trebuie ori (a) o cauza care se poate
## urmari in lume — geometrie mutata, o cota schimbata, o linie de AI care
## chiar ajunge acolo — ori (b) o diferenta care supravietuieste MEDIERII pe
## multe seed-uri. Un singur seed nu e o masuratoare, oricat de repetabil ar
## fi: e o realizare a zarurilor, si zarurile se schimba de la orice.
##
## Tot pe 16 seed-uri, dar comparand cu `origin/main` — deci o pereche mai
## slaba decat cea de mai sus, fiindca difera mai multe lucruri deodata:
##
##   seed:      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16   TOTAL
##   baseline:  0  0  1  0  0  0  0  0  0  0  0  1  0  0  0  0   2
##   ramura:    0  2  1  0  0  0  0  0  0  0  0  0  0  0  0  0   3
##
## Se citeste cu grija: e o singura rulare per seed, iar seed 3 — trecut cu 1
## aici — a dat 2,0,0,2 pe patru rulari ale ACELUIASI cod. Totalurile 2 si 3
## stau amandoua in zgomotul metodei; perechea cu un singur steag de mai sus e
## cea care spune ceva.
##
## Toate caderile de pe cornisa, pe ambele parti, cad intre frac 0.301 si 0.316,
## la aceeasi pozitie (-250..-237, y 34).
##
## [b]Pentru „e cornisa mai periculoasa acum?" nu se mai foloseste sonda asta.[/b]
## `tools/ProbeCornice.tscn` masoara GEOMETRIA marginii — latimea politei,
## pragul lateral, panta de dupa buza — deci nu depinde nici de seed, nici de
## ordinea contactelor. Pe ramura si pe `origin/main` da acelasi rezultat pana
## la a treia zecimala: polita 6.75 m, prag 2.438 m, panta 2.59 m/m. Cornisa e
## neatinsa de ramura; ce s-a schimbat e care seed o nimereste.
##
## Deci: se compara DISTRIBUTII pe mai multe seed-uri si mai multe rulari, nu o
## cifra cu alta, iar pentru o proprietate a LUMII se cauta o sonda de lume.
## Vezi memoria `proberace-nedeterminism`.
const SEED: int = 20260729
## Suprascris cu --seed=N: acelasi cod, seed-uri diferite = mai multe curse
## independente. Un blocaj care apare la 1 din 5 seed-uri e tot un blocaj.
var _seed: int = SEED
## Masina jucatorului, index in GameState.CAR_DATA. Suprascris cu --car=N.
## 0 = Muscle, masina de referinta a proiectului.
var _player_car: int = 0
## Numarul de adversari AI. -1 = nu se atinge GameState.ai_count (implicitul
## de joc, 5 -> 6 masini pe grila). Suprascris cu --ai=N — Fiordland cere 8
## masini pe grila (brief §7 pasul 3: 8 masini, fara decor, pe tunelul cu
## semafor), peste implicitul de 6.
var _ai_count: int = -1
## Viteza de sosire a atacatorului in modul bump (m/s).
const BUMP_ENTRY_SPEED: float = 26.0

# --- modul cliff ---
## Cu ce viteza se arunca masina in perete.
const CLIFF_ENTRY_SPEED: float = 20.0
## Unghiul fata de directia drumului: 0 = paralel, 90 = perpendicular pe perete.
## 35° e cazul rau realist — o iesire larga din viraj, nu un impact frontal.
const CLIFF_ANGLE_DEG: float = 35.0
## Cat timp se urmareste fiecare caz. Generos: AI-ul are anti-blocaj cu marsarier,
## si vrem sa-i dam sansa sa-l foloseasca inainte sa-l declaram blocat.
const CLIFF_CASE_SECONDS: float = 8.0
## Sub viteza asta masina e considerata "oprita".
const CLIFF_STUCK_SPEED: float = 2.0
## Cat timp trebuie sa stea oprita ca sa fie declarata INTEPENITA. Peste durata
## manevrei de desprindere (frana + marsarier + reluare), ca sa nu confundam o
## recuperare reusita cu un blocaj.
const CLIFF_STUCK_SECONDS: float = 3.5
## Fractiile de traseu testate. Alese sa acopere: doua drepte, doua viraje, si
## doua zone unde sectiunile de faleza se imbina in unghi.
const CLIFF_FRACS: Array[float] = [0.12, 0.31, 0.44, 0.58, 0.73, 0.91]

var _mode: String = "race"
var _track_index: int = 0
var _seconds: float = 150.0
## `--rain=1`: fortata ploaia peste orice `RainCycle` de pe pista, prin
## `force_factor(1.0)` (Fiordland, docs/track_briefs/fiordland.md §7 pasul
## de verdict "o rulare cu ploaia fortata"). `--rain=0`: fortat USCAT (opreste
## ceasul cu `force_factor(0.0)`), pentru izolarea A/B — FARA steag, o cursa de
## 150s cu `RainCycle` implicit (period 95s) trece oricum printr-o fereastra de
## ploaie in jurul t=95-125s, deci nu era o linie de baza "mereu uscata" (runda
## 2, diagnosticul coordonatorului). -1 (implicit) = neatins, ciclul normal.
## Pistele fara `RainCycle` ignora ambele steaguri.
var _force_rain: int = -1
## `--traffic=N`: seteaza `track.traffic_count` INAINTE de constructia pistei
## (brief §4(c), Jodhpur) — cate tuk-tuk-uri circula pe traseu, in afara
## masinilor de cursa. -1 (implicit) = neatins, orice pista foloseste
## `traffic_count` propriu (0 pe toate in afara de Jodhpur).
var _traffic: int = -1

## `--dusk=0.5`: forteaza DuskCycle.force_value() la fractia data (0 = turul 1
## auriu, 1 = turul 3 noapte cu artificii -- docs/track_briefs/jodhpur.md
## §3/§4). -1 (implicit) = neatins: pe modul "race", GameState.total_laps se
## forteaza la 99 mai jos (cursa nu se termina singura), deci progresul
## jucatorului ramane mereu aproape de 0 si DuskCycle n-ar avansa niciodata
## fara acest steag -- e mecanismul de test, nu un bug de ignorat. Daca pista
## n-are niciun DuskCycle, se adauga unul TEMPORAR (acelasi tipar ca in
## snapshot.gd), ca sondele sa poata verifica ceasul pe piste existente
## inainte ca Track17 sa existe.
var _force_dusk: float = -1.0
## `--no-torii`: scoate `ToriiTunnel` (portile, peretii colizori, padurea) din scena
## INAINTE de prima fizica: A/B-ul costului tunelului de torii (banda E' goala).
var _no_torii: bool = false
## `--no-tub`: scoate `ShishiOdoshiHazard` din scena (A/B-ul tubului, Kyoto).
var _no_tub: bool = false
## `--no-daruma`: scoate `DarumaOtoshiHazard` din scena (A/B-ul turnului, Kyoto).
var _no_daruma: bool = false
## `--no-leaves`: scoate covorul de frunze si frunzele care cad (A/B-ul covorului, Kyoto).
var _no_leaves: bool = false
## Hazardurile daruma-otoshi gasite in scena (goale cu --no-daruma).
var _daruma: Array[DarumaOtoshiHazard] = []
var _daruma_throws: int = 0
## `--no-kogarashi`: scoate `DustDevilHazard` din scena (A/B-ul vartejului de frunze, Kyoto).
var _no_kogarashi: bool = false
## Vartejurile gasite in scena (goale cu --no-kogarashi); `spins` = trecerile masinilor.
var _devils: Array[DustDevilHazard] = []
## `--blind`: AI-ul IGNORA tubul (`reads_shishi = false`). Martorul garzii: cu el
## contactele AI-tub trebuie sa fie > 0, altfel garda nu e armata (memoria
## `garda-fara-linie-de-baza-iese-zero`).
var _blind: bool = false
## `--no-turbo`: bara de turbo nu se mai incarca la nicio masina (turbo_fill_time
## enorm). Pentru intrebarea „Autobuzul trece saritura FARA turbo?" (brief
## Kyoto §3): altfel AI-ul arde turbo pe dreapta scenei si cifra se amesteca.
var _no_turbo: bool = false
## Hazardurile shishi-odoshi gasite in scena (goale cu --no-tub).
var _shishi: Array[ShishiOdoshiHazard] = []
var _tub_throws: int = 0
## Saritura de pe scena (TrackChannel jump): fractiile buzelor, calculate din
## `Track._channels` (indicii copti ai buzei de desprindere / de aterizare).
var _jump_near: float = -1.0
var _jump_far: float = -1.0
## Momentul (s) in care a inceput cursa, ca timpii pe tur sa nu includa
## numaratoarea inversa.
var _run_t0: float = -1.0

var _race: Node = null
var _elapsed: float = 0.0
var _stats: Array[Dictionary] = []
var _done: bool = false

## Fiordland (Track16), verdictul de flotă pentru TunnelSignalHazard (brief
## `docs/track_briefs/fiordland.md` §3 „Semaforul tunelului"): evenimente
## DISCRETE, nu cadre de contact — `bus_hits` de mai sus numără CADRE cu
## coliziunea activă (un singur ghiont poate ține 20-40 de cadre), ceea ce
## suprapune „un contact" cu „un contact lung". Aici agățăm direct semnalele
## proprii ale hazardului (`bus_hit`, `signal_changed`) pentru cifre pe
## EVENIMENT, comparabile cu criteriile din brief (contacte pe verde ≤ 1/seed
## etc.). No-op pe orice altă pistă (grupul e gol).
var _signal_bus_hits: int = 0
var _signal_ran_red_clear: int = 0
var _signal_max_queue: int = 0
## Cate masini erau "asteapta la semafor" (viteza mica, in raza semaforului)
## in ultimul tick verificat — pentru coada maxima simultana.
var _signal_hazards: Array[TunnelSignalHazard] = []
var _signal_bus_hits_green: int = 0
var _signal_bus_hits_red: int = 0
## Runda 2 a benzii: contacte impartite si pe BANDA masinii la impact (nu doar
## rosu/verde) — coordonator: "contacte autocar-AI (rosu/verde, banda)".
var _signal_bus_hits_left: int = 0
var _signal_bus_hits_right: int = 0
## Ultimul local.z (fata de semafor) vazut per masina, pentru detectia
## trecerii liniei (semnul lui local.z schimba de la - la +).
var _signal_last_z: Dictionary = {}

## Reproiectare banda-autocar (brief §3 „optiunea 0"): masini-cadre cu
## lateral SEMNAT < 0 (banda STANGA) in interiorul tunelului CAT semaforul e
## rosu — veto „AI onest" al noului contract (trebuie 0). Verificat DOAR pe
## masinile CONDUSE DE AI (jucatorul nu conteaza in sonda, dar nici n-are
## controller AI). Distinct de `_signal_bus_hits_red` (contact fizic): asta
## numara SIMPLA PREZENTA pe banda gresita, indiferent daca s-a lovit ceva.
var _signal_left_lane_frames: int = 0
## Lat maxim observat in interiorul tunelului (m, fara semn) — criteriul
## "lat maxim in tunel <= 4.0".
var _signal_lat_max: float = 0.0

## Runda 3 (coordonator): "lateralul PRE-impact" — inchide intrebarea daca
## mașinile lovite de autocar erau deja pe dreapta (regula functiona, contact
## fizic din marja prea mica) sau inca pe axa/stanga (regula n-a apucat).
## Buffer circular de 3 cadre pe masina (cheie: instance id), actualizat in
## FIECARE tick din `_watch_signal_fleet` (nu doar pe rosu — o masina poate fi
## lovita chiar la tranzitia verde->rosu). Fiecare intrare: lateral SEMNAT
## (side_at), acelasi tipar ca `_signal_lat_max`.
var _lateral_history: Dictionary = {}
const LATERAL_HISTORY_LEN: int = 3

## Pista taiata in felii egale, ca sa vezi UNDE se scurge viteza.
const BUCKETS: int = 20
var _bucket_speed: PackedFloat32Array = PackedFloat32Array()
var _bucket_samples: PackedInt32Array = PackedInt32Array()
var _bucket_slow: PackedInt32Array = PackedInt32Array()
var _bucket_walls: PackedInt32Array = PackedInt32Array()

# --- mod cliff ---
var _cliff_cases: Array[Dictionary] = []
var _cliff_case: int = -1
var _cliff_car: Car = null
var _cliff_track: Track = null
var _cliff_time: float = 0.0
var _cliff_slow_time: float = 0.0
var _cliff_rows: Array[Dictionary] = []

# --- mod bump ---
var _bump_cases: Array[Dictionary] = []
var _bump_case: int = -1
var _bump_frames: int = 0
var _bump_attacker: Car = null
var _bump_victim: Car = null
var _bump_rows: Array[Dictionary] = []
var _bump_peak: float = 0.0
var _bump_attacker_loss: float = 0.0
## Directia initiala a victimei — diferenta finala e rotatia PRIMITA din lovitura.
var _bump_victim_yaw0: float = 0.0
## Cea mai mica viteza a atacatorului dupa contact: "zidul" se vede aici — pe
## modelul vechi cobora la ~0 chiar si intre mase egale, desi fizica cerea ca
## amandoua masinile sa-si continue drumul.
var _bump_attacker_floor: float = 0.0
var _bump_impulses_att: int = 0
var _bump_impulses_vic: int = 0
var _bump_impulse_peak_att: float = 0.0
var _bump_impulse_peak_vic: float = 0.0

## Controller de laborator: comenzi fixe, fara "creier".
class ScriptedController extends CarController:
	var throttle: float = 1.0
	var steer: float = 0.0

	func get_throttle() -> float:
		return throttle

	func get_steer() -> float:
		return steer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="):
			_mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--car="):
			_player_car = int(arg.trim_prefix("--car="))
		elif arg.begins_with("--ai="):
			_ai_count = int(arg.trim_prefix("--ai="))
		elif arg.begins_with("--slice="):
			var ab := arg.trim_prefix("--slice=").split(",")
			_slice = Vector2(float(ab[0]), float(ab[1]))
		elif arg.begins_with("--rain="):
			_force_rain = int(arg.trim_prefix("--rain="))
		elif arg.begins_with("--traffic="):
			_traffic = int(arg.trim_prefix("--traffic="))
		elif arg.begins_with("--dusk="):
			_force_dusk = float(arg.trim_prefix("--dusk="))
		elif arg == "--no-tub":
			_no_tub = true
		elif arg == "--no-daruma":
			_no_daruma = true
		elif arg == "--no-kogarashi":
			_no_kogarashi = true
		elif arg == "--no-leaves":
			_no_leaves = true
		elif arg == "--blind":
			_blind = true
		elif arg == "--no-turbo":
			_no_turbo = true
		elif arg == "--no-torii":
			_no_torii = true
	# Masina jucatorului se FIXEAZA, nu se mosteneste.
	#
	# `GameState.selected_car` se salveaza in `user://settings.cfg`, deci sonda
	# rula pe orice masina ai ales ultima data cand ai deschis jocul. Doua rulari
	# ale aceluiasi cod dadeau 3.96 si 3.57 tururi si arata ca o regresie de la
	# assets — de fapt se schimbase masina sub noi. Aceeasi capcana ca la
	# --mode=cliff, care nu-si seta `car.track` si masura altceva decat credea.
	GameState.selected_car = clampi(_player_car, 0, GameState.CAR_DATA.size() - 1)
	if _ai_count >= 0:
		GameState.ai_count = _ai_count
	# `--track=` ia POZITIA din lista (Stromboli = 4), dar accepta si numarul
	# scenei (--track=11). Fara verificarea asta, un index gresit nu se plangea
	# aici, ci pica mai tarziu cu "Out of bounds" si turna zeci de mii de erori
	# derivate, in care cauza nu se mai vedea.
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_race: --track=%d nu e nici pozitie in lista (0..%d), nici numar de pista din lista."
			% [_track_index, GameState.TRACK_SCENES.size() - 1])
		get_tree().quit(1)
		return
	_track_index = resolved
	print("probe_race: pista %s" % GameState.track_label(_track_index))
	match _mode:
		"race":
			_start_race()
		"bump":
			_start_bump()
		"cliff":
			_start_cliff()
		_:
			push_error("probe_race: mod necunoscut '%s'" % _mode)
			get_tree().quit(1)


func _physics_process(delta: float) -> void:
	if _done:
		return
	match _mode:
		"bump":
			_tick_bump()
		"cliff":
			_tick_cliff(delta)
		_:
			_tick_race(delta)


func _finish() -> void:
	_done = true
	get_tree().quit(0)


# --------------------------------------------------------------- mod cursa

func _start_race() -> void:
	GameState.selected_track = _track_index
	GameState.champ_active = false
	GameState.total_laps = 99 # cursa nu se termina singura; o oprim pe timp
	GameState.traffic_override = _traffic
	_bucket_speed.resize(BUCKETS)
	_bucket_samples.resize(BUCKETS)
	_bucket_slow.resize(BUCKETS)
	_bucket_walls.resize(BUCKETS)
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	# Si rocket start-ul AI-ului trage la zaruri; fara seed fix, doua rulari ale
	# ACELUIASI cod pornesc diferit si "inainte / dupa" nu mai compara nimic.
	(_race._rng as RandomNumberGenerator).seed = _seed
	# Jucatorul primeste tot un creier AI: masuram pista, nu reflexele mele.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			# `_race.traffic` (tuk-tuk-urile, brief §4(c)): fara ele aici, AI-ul
			# care inlocuieste jucatorul n-ar vedea traficul deloc — restul
			# masinilor AI il vad (controller-ele lor originale au fost
			# configurate de Race cu _ai_visible, care le include).
			var visible: Array[Car] = cars.duplicate()
			visible.append_array(_race.traffic)
			ai.configure(_race.track, rng, visible)
		else:
			(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
		# Variatie onesta, dar determinista — altfel cifrele danseaza intre rulari.
		car.speed_scale = 1.0 if car == player else rng.randf_range(0.88, 0.97)
		_stats.append({
			"name": "%s (%s)" % [car.pilot_name, car.car_name],
			"offroad_s": 0.0, "slow_s": 0.0, "reverse_s": 0.0,
			"respawns": 0, "walls": 0, "wall_impact": 0.0,
			"ejects_wall": 0, "ejects_land": 0, "land_max": 0.0,
			"bumps": 0, "bump_peak": 0.0,
			"slide_hits": 0, "carousel_hits": 0, "deflector_hits": 0,
			"bus_hits": 0,
			"sl_speed": 0.0, "sl_samples": 0, "sl_slow": 0.0, "sl_walls": 0, "sl_bus": 0,
			"speed_sum": 0.0, "samples": 0,
			"stuck_t": 0.0, "stuck_reports": 0,
			"branch_laps": 0, "branch_s": 0.0, "last_route": 0,
			"lap_t": [], "last_total": 0.0,
			"jump_armed": false, "jump_ok": 0, "jump_fail": 0, "tub_hits": 0, "daruma_hits": 0,
			"jump_v": [], "jump_v_taken": false,
		})
		car.respawned.connect(_on_respawn.bind(i))
		car.wall_hit.connect(_on_wall.bind(i))
		# Ejectarile soferului (masini deschise): cauza si marimea, ca pragurile
		# din Car (eject_wall_dv / eject_land_speed) sa se tuneze pe cifre, nu pe
		# impresii. Aterizarea maxima FARA ejectare spune cat de aproape e o
		# saritura proiectata de prag.
		car.ejected.connect(_on_eject.bind(i))
		# `landed` se emite INAINTE de decizia de ejectare, deci se compara cu
		# pragul, nu cu starea masinii.
		car.landed.connect(func(c: Car, fall: float) -> void:
			if fall < c.eject_land_speed:
				_stats[i].land_max = maxf(float(_stats[i].land_max), fall))
		# Delta-v-ul REAL al imbrancelii, direct din model. Masurat ca diferenta
		# de viteza intre cadre ar aduna si gravitatia, aterizarile si turbo.
		# Conditionat: pe versiunile de dinaintea modelului de masa semnalul nu
		# exista, iar sonda trebuie sa poata masura si acele rulari (coloana
		# "bump/dv" ramane goala acolo, restul cifrelor sunt comparabile).
		if car.has_signal(&"bumped"):
			car.bumped.connect(_on_bumped.bind(i))
	_setup_signal_hazards()
	_setup_kyoto()
	if _no_turbo:
		for car in cars:
			car.turbo_fill_time = 1.0e9
	if _blind:
		for car in cars:
			var ai_c := car.controller as AIController
			if ai_c != null:
				ai_c.reads_shishi = false
				ai_c.reads_daruma = false
	if _force_rain >= 0:
		_force_rain_cycle_deferred(float(_force_rain))
	if _force_dusk >= 0.0:
		_force_dusk_cycle_deferred(_force_dusk)


## Kyoto: tubul shishi-odoshi (numarat sau scos cu `--no-tub`) si buzele
## sariturii de pe scena (fractiile din `Track._channels`). No-op pe orice
## pista fara ele (`_jump_near` ramane -1).
func _setup_kyoto() -> void:
	var track: Track = _race.track
	if _no_leaves:
		for nm in ["CovorFrunze", "FrunzeCazatoare"]:
			var ln := track.get_node_or_null(nm)
			if ln != null:
				track.wear_sinks.erase(ln)
				ln.get_parent().remove_child(ln)
				ln.free()
		print("--no-leaves: covorul de frunze si frunzele scoase din scena")
	if _no_torii:
		var tt := track.get_node_or_null("ToriiTunel")
		if tt != null:
			tt.get_parent().remove_child(tt)
			tt.free()
	for n in get_tree().get_nodes_in_group(ShishiOdoshiHazard.AI_GROUP):
		var hz := n as ShishiOdoshiHazard
		if hz == null:
			continue
		if _no_tub:
			# Scos din grup INAINTE sa-l citeasca AI-ul (grupul e cautat lazy) si
			# eliberat: fara corp, fara zona, fara petec ud.
			hz.remove_from_group(ShishiOdoshiHazard.AI_GROUP)
			hz.get_parent().remove_child(hz)
			hz.free()
			print("--no-tub: ShishiOdoshi scos din scena")
		else:
			_shishi.append(hz)
			hz.car_thrown.connect(func(_c: Car, _strike: bool) -> void: _tub_throws += 1)
	for n in get_tree().get_nodes_in_group(DarumaOtoshiHazard.AI_GROUP):
		var dz := n as DarumaOtoshiHazard
		if dz == null:
			continue
		if _no_daruma:
			dz.remove_from_group(DarumaOtoshiHazard.AI_GROUP)
			dz.get_parent().remove_child(dz)
			dz.free()
			print("--no-daruma: DarumaOtoshi scos din scena")
		else:
			_daruma.append(dz)
			dz.car_thrown.connect(func(_c: Car) -> void: _daruma_throws += 1)
	for dv in track.find_children("*", "Node3D", true, false):
		var devil := dv as DustDevilHazard
		if devil == null:
			continue
		if _no_kogarashi:
			devil.get_parent().remove_child(devil)
			devil.free()
			print("--no-kogarashi: vartejul scos din scena")
		else:
			_devils.append(devil)
	for ch in track._channels:
		if bool(ch.get("jump", false)) and not bool(ch.get("ford", false)):
			_jump_near = track.frac_at(int(ch["near"]))
			_jump_far = track.frac_at(int(ch["far"]))
			print("saritura %s: buza %.4f -> aterizare %.4f" % [
				String(ch.get("label", "?")), _jump_near, _jump_far])
			break


## Per tur si per saritura, pentru raportul Kyoto.
func _watch_laps_and_jump(car: Car, st: Dictionary, idx: int) -> void:
	if _race.state != Race.State.RUNNING:
		return
	if _run_t0 < 0.0:
		_run_t0 = _elapsed
	var total := float(_race._progress[idx].total)
	var last := float(st.last_total)
	if int(floor(total)) > int(floor(last)) and total > 0.0:
		(st.lap_t as Array).append(_elapsed - _run_t0)
	st.last_total = total
	if _jump_near < 0.0:
		return
	var f: float = _race.track.frac_at(car.road_index, car.route)
	if car.route == 0 and f >= _jump_near - 0.03 and f < _jump_near:
		st.jump_armed = true
		# Viteza la buza: cat de repede ajunge de fapt fiecare masina la gol
		# (pragul de trecere din ProbeJump se compara cu ASTA, nu cu plafonul).
		if not bool(st.jump_v_taken) and f >= _jump_near - 0.0025:
			(st.jump_v as Array).append(car.horizontal_speed())
			st.jump_v_taken = true
	elif bool(st.jump_armed) and f > _jump_far + 0.003 and f < _jump_far + 0.05:
		st.jump_ok = int(st.jump_ok) + 1
		st.jump_armed = false
	elif f > _jump_far + 0.05 or f < _jump_near - 0.05:
		st.jump_armed = false
		st.jump_v_taken = false


## `--rain=1`/`--rain=0`: gaseste orice `RainCycle` prin grupul lui
## (`rain_cycle`, vezi RainCycle._ready) si il fixeaza la `factor` (1.0 = ploaie
## plina, 0.0 = uscat fortat, ceasul oprit in ambele cazuri) — acelasi apel pe
## care il foloseste sonda A/B a ploii (`ProbeFiordPloaie`). Pista ramane
## astfel la starea ceruta din primul cadru pana la ultimul, in loc sa astepte
## ~5-30s din ciclul de 95s pana la prima fereastra, SAU (la 0) sa treaca oricum
## printr-o fereastra de ploaie in cursul unei rulari de 150s (period 95s —
## fara steag, o cursa "de control" nu era de fapt mereu uscata). Gol pe orice
## pista fara `RainCycle`.
##
## Runda 3, punctul 1: BUG gasit prin diagnostic (`_rain_diag`) — apelul
## SINCRON, direct din `_start_race()`, ateriza `rain_factor=1.0` pe nodul
## `RainCycle` insusi, dar `track.rain_wet` ramanea `false`: `RainCycle._ready`
## isi programeaza `_collect()` (care rezolva `_track`) prin `call_deferred`,
## deci in cadrul in care `_start_race()` ruleaza, `_track` e INCA null cand
## `force_factor()` incearca sa scrie `_track.rain_wet` — vezi garda
## `if _track != null` din `RainCycle._apply()`, care a esuat tacut. Si mai
## rau: `force_factor()` cheama `set_process(false)`, deci nodul ramanea
## INGHETAT cu `rain_factor` setat corect pe el insusi, dar fara sa mai
## apuce vreodata sa-l aplice pe pista — de-aici "identic la bit" intre
## --rain=0 si --rain=1 (ambele lasau `track.rain_wet=false` tot timpul).
## `ProbeFiordPloaie` (sonda existenta, A/B pe ploaie) evita exact asta cu
## DOUA `await get_tree().process_frame` inainte de `force_factor()` —
## acelasi leac aici, prin `call_deferred` dublu (echivalent, fara sa fac
## `_start_race` async).
func _force_rain_cycle_deferred(factor: float) -> void:
	call_deferred(&"_force_rain_cycle_step2", factor)


func _force_rain_cycle_step2(factor: float) -> void:
	# Un singur `call_deferred` ajunge dupa `RainCycle._collect.call_deferred()`
	# programat in ACELASI cadru (ambele intra in coada de deferred calls a
	# cadrului curent, in ordinea in care au fost programate — `RainCycle`
	# insusi a fost instantiat, deci `_ready()`-ul lui a rulat, INAINTE ca
	# `_force_rain_cycle_deferred` sa fie apelat din `_start_race()`). Al
	# doilea pas ramane totusi separat (nu un singur `_force_rain_cycle` cu
	# `call_deferred` in interior) ca sa se poata verifica direct, cu
	# `_rain_diag`, ca `_track` chiar nu mai e null cand scriem.
	_force_rain_cycle(factor)


func _force_rain_cycle(factor: float) -> void:
	for node in get_tree().get_nodes_in_group(&"rain_cycle"):
		if node.has_method("force_factor"):
			node.call("force_factor", factor)


## `--dusk=x` (Jodhpur, DuskCycle): acelasi leac in doi pasi ca ploaia de mai
## sus (`_force_rain_cycle_deferred`), fiindca DuskCycle._collect e la fel
## amanat cu `call_deferred`. DACA pista n-are niciun DuskCycle (orice pista
## in afara de Jodhpur), se adauga unul TEMPORAR pe `_race.track` -- fara
## asta n-ar exista nicio pista pe care sa se verifice ceasul inainte ca
## Track17 sa existe (memoria `sonda-masura-alt-obiect`).
func _force_dusk_cycle_deferred(value: float) -> void:
	call_deferred(&"_force_dusk_cycle_step2", value)


func _force_dusk_cycle_step2(value: float) -> void:
	var cycles := get_tree().get_nodes_in_group(&"dusk_cycle")
	if cycles.is_empty():
		var dc: Node = (preload("res://scenes/hazards/dusk_cycle.gd") as GDScript).new()
		_race.track.add_child(dc)
		call_deferred(&"_force_dusk_cycle_step3", value)
		return
	_force_dusk_cycle(value)


## Al treilea pas, doar cand pista n-avea DuskCycle: nodul proaspat adaugat
## isi programeaza si EL `_collect` prin `call_deferred`, deci mai e nevoie
## de un tur de coada inainte sa aiba `_env`/`_sun` gasite.
func _force_dusk_cycle_step3(value: float) -> void:
	_force_dusk_cycle(value)
	print("--dusk=%.2f: pista fara DuskCycle propriu, adaugat unul temporar" % value)


func _force_dusk_cycle(value: float) -> void:
	for node in get_tree().get_nodes_in_group(&"dusk_cycle"):
		if node.has_method("force_value"):
			node.call("force_value", value)


## Fiordland: agata contorul de evenimente pe orice TunnelSignalHazard din
## grupul lui (vezi TunnelSignalHazard.AI_GROUP). Gol pe orice alta pista.
func _setup_signal_hazards() -> void:
	for node in get_tree().get_nodes_in_group(TunnelSignalHazard.AI_GROUP):
		var sig := node as TunnelSignalHazard
		if sig == null:
			continue
		_signal_hazards.append(sig)
		sig.bus_hit.connect(_on_signal_bus_hit)


## Runda 3, punctul 1: „identic la bit" intre --rain=0 si --rain=1 e exact
## semnul de mecanism NECONECTAT (memoria `sonda-masura-alt-obiect`) — de
## verificat direct, nu presupus. La t=10s si t=60s (o data fiecare, marcate
## in `_rain_diag_done`) se tipareste starea REALA: `RainCycle.rain_factor`,
## `track.rain_wet` (campul citit de `Car.is_wet_at`/`_physics_process`) si
## `slip_time` al fiecarei masini — daca oricare ramane 0/false pe --rain=1,
## flagul nu ajunge la pista, indiferent ce spune codul lui `force_factor`.
var _rain_diag_done: Dictionary = {}
func _rain_diag(t_mark: float) -> void:
	if _elapsed < t_mark or _rain_diag_done.get(t_mark, false):
		return
	_rain_diag_done[t_mark] = true
	var cycles := get_tree().get_nodes_in_group(&"rain_cycle")
	var rf := -1.0
	if not cycles.is_empty():
		rf = float(cycles[0].get("rain_factor"))
	print("[rain-diag] t=%.1f rain_factor=%s track.rain_wet=%s" % [
		_elapsed, str(rf), str(_race.track.rain_wet)])
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var c := cars[i]
		print("    slip_time car%d (%s) = %.3f" % [i, c.pilot_name, c.slip_time])


func _tick_race(delta: float) -> void:
	_elapsed += delta
	_rain_diag(10.0)
	_rain_diag(60.0)
	var cars: Array[Car] = _race.cars
	# PROBE_RACE_TRACE=2: acelasi tabel, dar la 0,1 s si doar intr-o fereastra
	# ingusta — diagnostic ad-hoc pentru un respawn reproductibil la un frac
	# fix, fara sa umple logul pe toata cursa. Implicit 60-70s; suprascrisa cu
	# PROBE_RACE_TRACE_WINDOW=inceput,sfarsit (runda 3: 115,140 pentru
	# repunerile de langa semafor, care apar mult mai tarziu in cursa).
	var trace_env := OS.get_environment("PROBE_RACE_TRACE")
	var trace_window := Vector2(60.0, 70.0)
	var trace_window_env := OS.get_environment("PROBE_RACE_TRACE_WINDOW")
	if not trace_window_env.is_empty():
		var parts := trace_window_env.split(",")
		if parts.size() == 2:
			trace_window = Vector2(float(parts[0]), float(parts[1]))
	if trace_env == "2" and _elapsed >= trace_window.x and _elapsed <= trace_window.y \
			and int(_elapsed * 60.0) % 6 == 0:
		for i in cars.size():
			var c := cars[i]
			print("FTRACE t=%6.2f car%d frac=%.4f on_road=%s v=%5.1f pos=(%.1f,%.2f,%.1f) vel=%s"
				% [_elapsed, i, _race.track.frac_at(c.road_index, c.route),
					_race.track.is_on_road(c.road_index, c.global_position, c.route),
					c.horizontal_speed(), c.global_position.x, c.global_position.y,
					c.global_position.z, c.linear_velocity])
	if trace_env == "1" \
			and int(_elapsed * 60.0) % 120 == 0:
		for i in cars.size():
			var c := cars[i]
			print("TRACE t=%5.1f car%d frac=%.3f on_road=%s v=%4.1f pos=(%.0f,%.1f,%.0f)" % [
				_elapsed, i,
				_race.track.frac_at(c.road_index, c.route),
				_race.track.is_on_road(c.road_index, c.global_position,
					c.route), c.horizontal_speed(),
				c.global_position.x, c.global_position.y, c.global_position.z])
	for i in cars.size():
		var car := cars[i]
		var st := _stats[i]
		var speed := car.horizontal_speed()
		st.speed_sum = float(st.speed_sum) + speed
		st.samples = int(st.samples) + 1
		if not _race.track.is_on_road(car.road_index, car.global_position,
				car.route):
			st.offroad_s = float(st.offroad_s) + delta
		if speed < 4.0:
			st.slow_s = float(st.slow_s) + delta
		# Banda secundara: cine si cat o foloseste. Fara cifra asta, "AI-ul ia
		# ocolul" ramane o presupunere — pe gatul cu piatra din Cappadocia
		# bifurcatia exista doar daca macar un pilot chiar trece pe ea.
		if car.route > 0:
			st.branch_s = float(st.branch_s) + delta
			if int(st.last_route) == 0:
				st.branch_laps = int(st.branch_laps) + 1
		st.last_route = car.route
		if car.controller != null and car.controller.get_throttle() < -0.5:
			st.reverse_s = float(st.reverse_s) + delta
		# Pe fizica intreaga contactele vin de la solver (contact_monitor e
		# pornit in Car._ready), nu din move_and_slide.
		for hit in car.get_colliding_bodies():
			if hit is SlidingHazard:
				st.slide_hits = int(st.slide_hits) + 1
			elif _is_under(hit as Node, "CarouselHazard"):
				# Rotorul caruselului e COPIL al hazardului, deci colizionerul
				# nu e niciodata hazardul insusi.
				st.carousel_hits = int(st.carousel_hits) + 1
			elif _is_under(hit as Node, "DeflectorHazard"):
				st.deflector_hits = int(st.deflector_hits) + 1
			elif _is_under(hit as Node, "ShishiOdoshiHazard"):
				st.tub_hits = int(st.tub_hits) + 1
			elif _is_under(hit as Node, "DarumaOtoshiHazard"):
				st.daruma_hits = int(st.daruma_hits) + 1
			elif _is_under(hit as Node, "BusHazard"):
				# Autobuzul de pe serpentine (Machu Picchu): corp cinematic
				# pe traseu; contactul se numara ca la minge/deviator.
				st.bus_hits = int(st.bus_hits) + 1
				if _in_slice(_race.track.frac_at(car.road_index, car.route)):
					st.sl_bus = int(st.sl_bus) + 1
		# FELIA ceruta cu --slice=a,b: aceleasi cifre, doar pe portiunea aia —
		# pentru un hazard local (autobuzul de pe serpentine) media pe tot turul
		# ascunde tot ce conteaza.
		var fr_here: float = _race.track.frac_at(car.road_index, car.route)
		if _in_slice(fr_here):
			st.sl_speed = float(st.sl_speed) + speed
			st.sl_samples = int(st.sl_samples) + 1
			if speed < 4.0:
				st.sl_slow = float(st.sl_slow) + delta
		# Harta pistei: unde anume se scurge viteza. Fara ea nu stii daca AI-ul
		# pierde in acelasi viraj de fiecare data sau imprastiat peste tot.
		var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
			0, BUCKETS - 1)
		_bucket_speed[b] += speed
		_bucket_samples[b] += 1
		if speed < 4.0:
			_bucket_slow[b] += 1
		_watch_stuck(car, st, speed, delta)
		_watch_laps_and_jump(car, st, i)
	if not _signal_hazards.is_empty():
		_watch_signal_fleet(cars)
	if _elapsed >= _seconds:
		_report_race()


## Fiordland: treceri pe rosu (masina trece de linia semaforului CAT e rosu)
## si coada maxima simultana (masini oprite in raza semaforului). Distinct de
## `_watch_stuck` (generic, orb la asteptarea legitima): aici stim EXACT ce
## inseamna "asteapta la semafor" — acelasi test ca AIController.SIGNAL_BRAKE_M.
func _watch_signal_fleet(cars: Array[Car]) -> void:
	var sig := _signal_hazards[0]
	var red := sig.is_red()
	var queued := 0
	for car in cars:
		# Pozitia masinii in coordonatele semaforului: local +Z e spre tunel (vezi
		# antetul TunnelSignalHazard), deci local.z < 0 e pe apropiere, > 0 in tunel.
		var local_pos: Vector3 = sig.to_local(car.global_position)
		var id := car.get_instance_id()
		var prev_z: float = _signal_last_z.get(id, local_pos.z)
		# Trecere de linie: local.z trece de la negativ la pozitiv, aproape de axa
		# (nu departe pe o nisa), CU VITEZA REALA de inaintare (nu jitter de coada
		# la 0 m/s) -- daca semaforul e rosu chiar atunci, e o trecere pe rosu
		# clara. Fara pragul de viteza, o masina oprita chiar langa linie (jitter
		# de contact intre masini in coada) oscileaza peste z=0 la viteza ~0 si
		# se numara gresit ca "a trecut pe rosu" -- masurat: toate cele 11
		# raportari initiale erau la poz aproape identica (~2-5m de linie),
		# semn de jitter de coada, nu de traversare reala a tunelului.
		var speed := car.horizontal_speed()
		if prev_z < 0.0 and local_pos.z >= 0.0 and absf(local_pos.x) < 4.0 \
				and red and speed > 4.0:
			_signal_ran_red_clear += 1
			print("[trecere-pe-rosu] t=%5.1fs  v=%4.1f  poz=(%.0f,%.0f,%.0f)  rosu_ramas=%.1fs" % [
				_elapsed, speed, car.global_position.x, car.global_position.y,
				car.global_position.z, sig.red_seconds_left()])
		_signal_last_z[id] = local_pos.z
		# Coada: aproape de linie (in raza de decizie AI), viteza mica, inca de
		# partea de apropiere (nu deja in tunel).
		if local_pos.z < 5.0 and local_pos.z > -TunnelSignalHazard.AI_REACH_M \
				and speed < 2.0:
			queued += 1
		# Reproiectare banda-autocar: masina IN TUNEL CAT e rosu, pe banda
		# STANGA — veto „AI onest", trebuie 0.
		#
		# BUG GASIT (prima versiune folosea doar `local_pos.z/x`, coordonatele
		# FIXE ale nodului semafor): `to_local` e un transform AFIN NECLIPIT —
		# orice masina de pe cei 2162 m ai pistei a carei pozitie se intampla
		# sa cada in cutia (z in [0,169], oriunde in planul XY local) e prinsa,
		# chiar daca e la sute de metri de tunel pe alta parte a buclei.
		# Masurat: lat_max_tunel iesea 398 m, evident absurd pentru un tunel de
		# 8 m. Fix: se cere IN PLUS ca masina sa fie efectiv APROAPE de tunel
		# pe INDEXUL de traseu (acelasi tipar ca `ai_controller.gd`, distanta
		# pe axa drumului, nu pe coordonate locale ale hazardului).
		var track2: Track = _race.track
		if track2 != null:
			var r2 := track2.route_at(car.route)
			if r2 != null and not r2.baked.is_empty():
				var n2 := r2.count()
				var bake2: float = track2.curve.bake_interval
				var line_idx2: int = track2.closest_index_global(
					sig.ai_decision_point(), car.route)
				var bidx2: int = track2.closest_index_global(car.global_position, car.route)
				var d_idx2 := line_idx2 - bidx2
				if d_idx2 < -n2 / 2:
					d_idx2 += n2
				elif d_idx2 > n2 / 2:
					d_idx2 -= n2
				var along2 := float(d_idx2) * bake2
				# along2 > 0: masina inca nu a ajuns la linie. along2 < 0: masina
				# a trecut de linie, spre tunel. "In tunel" = intre linie si
				# capatul opus (0 .. -tunnel_length).
				if along2 <= 0.0 and along2 >= -sig.tunnel_length:
					var side2: Vector3 = r2.side_at(bidx2)
					var lateral2: float = side2.dot(
						car.global_position - r2.baked[r2.wrap_index(bidx2)])
					# Runda 3: buffer-ul de istoric se tine INDIFERENT de rosu —
					# vezi doc la `_lateral_history`.
					var hid := car.get_instance_id()
					var hist: Array = _lateral_history.get(hid, [])
					hist.append(lateral2)
					if hist.size() > LATERAL_HISTORY_LEN:
						hist.pop_front()
					_lateral_history[hid] = hist
					if red:
						if lateral2 < 0.0:
							_signal_left_lane_frames += 1
						_signal_lat_max = maxf(_signal_lat_max, absf(lateral2))
	_signal_max_queue = maxi(_signal_max_queue, queued)


func _in_slice(frac: float) -> bool:
	if _slice.x < 0.0:
		return false
	var f := fposmod(frac, 1.0)
	if _slice.x <= _slice.y:
		return f >= _slice.x and f <= _slice.y
	return f >= _slice.x or f <= _slice.y


func _is_under(node: Node, type_name: String) -> bool:
	var walker := node
	while walker != null:
		if walker.is_class(type_name) or (walker.get_script() != null
				and (walker.get_script() as Script).get_global_name() == type_name):
			return true
		walker = walker.get_parent()
	return false


## Un blocaj adevarat nu e "o clipa de incetinire", e o masina care nu mai
## progreseaza. Il raportam cu loc si vinovat — altfel tunezi in orb.
func _watch_stuck(car: Car, st: Dictionary, speed: float, delta: float) -> void:
	if _race.state != Race.State.RUNNING or speed > 6.0:
		st.stuck_t = 0.0
		return
	st.stuck_t = float(st.stuck_t) + delta
	if float(st.stuck_t) < 3.0 or int(st.stuck_reports) >= 6:
		return
	st.stuck_t = 0.0
	st.stuck_reports = int(st.stuck_reports) + 1
	var touching: Array[String] = []
	for body in car.get_colliding_bodies():
		var hit := body as Node3D
		if hit != null:
			touching.append("%s@(%.0f,%.0f,%.0f)" % [_describe(hit),
				hit.global_position.x, hit.global_position.y, hit.global_position.z])
	print("[blocaj] t=%5.1fs  %-18s frac=%.3f  v=%4.1f  lat=%4.1f  poz=(%.0f,%.0f,%.0f)  atinge: %s" % [
		_elapsed, st.name, _race.track.frac_at(car.road_index, car.route), speed,
		_race.track.lateral_distance(car.road_index, car.global_position,
			car.route),
		car.global_position.x, car.global_position.y, car.global_position.z,
		", ".join(touching) if not touching.is_empty() else "-"])


## Numele unui corp generat procedural nu spune nimic (@StaticBody3D@31);
## mesh-ul copil si culoarea lui spun exact ce bucata de pista e.
func _describe(body: Node3D) -> String:
	if not body.name.begins_with("@"):
		return String(body.name)
	for child in body.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var mat := mi.material_override as StandardMaterial3D
		var tint := "?" if mat == null else "#%s" % mat.albedo_color.to_html(false)
		return "%s[%s]" % [body.get_class(), tint]
	return String(body.name)


func _on_bumped(_car: Car, _other: Car, delta_v: float, index: int) -> void:
	_stats[index].bumps = int(_stats[index].bumps) + 1
	_stats[index].bump_peak = maxf(float(_stats[index].bump_peak), delta_v)


## Runda 2 a benzii (coordonator): "ejectarile in tunel = veto real" — pentru
## fiecare ejectare/repunere in felia 0.58-0.70, diagnostic complet: cu ce s-a
## lovit, viteza, banda pe care era, daca era rosu, daca regula de banda era
## activa pe ea. Gol ("") daca masina nu e in felia tunelului sau nu exista
## semafor pe pista (no-op pe orice alta pista).
func _tunnel_zone_diag(car: Car) -> String:
	if _signal_hazards.is_empty() or _race.track == null:
		return ""
	var frac: float = _race.track.frac_at(car.road_index, car.route)
	if frac < 0.58 or frac > 0.70:
		return ""
	var sig := _signal_hazards[0]
	var track: Track = _race.track
	var r := track.route_at(car.route)
	var lateral := 0.0
	var side_txt := "?"
	if r != null and not r.baked.is_empty():
		var bidx: int = track.closest_index_global(car.global_position, car.route)
		var side: Vector3 = r.side_at(bidx)
		lateral = side.dot(car.global_position - r.baked[r.wrap_index(bidx)])
		side_txt = "DREAPTA" if lateral > 0.0 else ("STANGA" if lateral < 0.0 else "AXA")
	var speed := car.horizontal_speed()
	var red := sig.is_red()
	# Regula de banda activa pe ea ACUM: acelasi test ca AIController -- rosu
	# curent SAU va prinde-o inauntru (blocks_in cu eta pana la portalul de
	# vest). Aproximam distanta pana la portal cu `local_pos.z` (coordonatele
	# hazardului, +Z spre capatul opus) fata de `tunnel_length`.
	var local_pos: Vector3 = sig.to_local(car.global_position)
	var dist_to_west: float = sig.tunnel_length - local_pos.z
	var eta_west: float = dist_to_west / maxf(speed, 10.0)
	var rule_active := red or sig.blocks_in(eta_west)
	# Ce a lovit-o: corpurile cu care era in contact (acelasi tipar ca
	# _watch_stuck), clasificate pe nume/pozitie ca perete stanga/dreapta sau
	# autocar.
	var touching: Array[String] = []
	for body in car.get_colliding_bodies():
		var hit := body as Node3D
		if hit == null:
			continue
		var label := _describe(hit)
		if hit is BusHazard or (hit.get_parent() is BusHazard):
			label = "AUTOCAR"
		touching.append(label)
	# Runda 3 (coordonator): lateralul PRE-impact — cea mai VECHE valoare din
	# buffer-ul circular de `LATERAL_HISTORY_LEN` cadre (vezi `_lateral_history`),
	# adica pozitia laterala de CATEVA cadre INAINTE de acest eveniment, nu cea
	# curenta (care poate fi deja deplasata de ghiontul autocarului). Raspunde
	# direct la "era pe dreapta la >= +1.5 sau pe axa/stanga chiar inainte?".
	var hid := car.get_instance_id()
	var hist: Array = _lateral_history.get(hid, [])
	var pre_lat_txt := "n/a"
	if not hist.is_empty():
		var pre_lat: float = hist[0]
		var pre_side := "DREAPTA" if pre_lat > 0.0 else ("STANGA" if pre_lat < 0.0 else "AXA")
		pre_lat_txt = "%.2f(%s)" % [pre_lat, pre_side]
	return "  banda=%s red=%s regula_activa=%s v=%.1f pre_impact_lat=%s atinge:%s" % [
		side_txt, red, rule_active, speed, pre_lat_txt,
		", ".join(touching) if not touching.is_empty() else "-"]


func _on_respawn(car: Car, index: int) -> void:
	_stats[index].respawns = int(_stats[index].respawns) + 1
	if _jump_near >= 0.0:
		var fr: float = _race.track.frac_at(car.road_index, car.route)
		if bool(_stats[index].jump_armed) or (fr >= _jump_near - 0.01 and fr <= _jump_far + 0.02):
			_stats[index].jump_fail = int(_stats[index].jump_fail) + 1
			_stats[index].jump_armed = false
	# Unde a fost repusa: o repunere in acelasi loc, tur de tur, e o bucla
	# (masina cade, e repusa fara elan, cade iar) — vezi CHANNEL_FALL_BACKOFF.
	print("[repunere] t=%5.1fs  %-18s frac=%.3f  poz=(%.0f,%.0f,%.0f)%s" % [
		_elapsed, _stats[index].name,
		_race.track.frac_at(car.road_index, car.route),
		car.global_position.x, car.global_position.y, car.global_position.z,
		_tunnel_zone_diag(car)])


func _on_eject(car: Car, _ragdoll: Node3D, index: int) -> void:
	if car.last_eject_cause == "perete":
		_stats[index].ejects_wall = int(_stats[index].ejects_wall) + 1
	else:
		_stats[index].ejects_land = int(_stats[index].ejects_land) + 1
	print("[ejectare] t=%5.1fs  %-18s frac=%.3f  %s %.1f m/s  poz=(%.0f,%.0f,%.0f)%s" % [
		_elapsed, _stats[index].name,
		_race.track.frac_at(car.road_index, car.route),
		car.last_eject_cause, car.last_eject_value,
		car.global_position.x, car.global_position.y, car.global_position.z,
		_tunnel_zone_diag(car)])


## Fiordland: contact DISCRET cu autocarul (un eveniment per ghiont, nu cadre
## de coliziune continua — vezi comentariul de la `_signal_bus_hits` mai sus).
## Clasificat verde/rosu dupa STAREA semaforului chiar in clipa impactului:
## un contact nu poate exista decat cat masina e in tunel, iar `is_red()`
## acolo distinge intre "a intrat legitim pe verde si autocarul a pornit cat
## inca era in tunel" (nu ar trebui sa se intample - vezi criteriul de verdict)
## si "a intrat/ramas pe rosu, deci risc asumat".
func _on_signal_bus_hit(car: Car) -> void:
	_signal_bus_hits += 1
	var cars: Array[Car] = _race.cars
	var idx: int = cars.find(car)
	var car_name: String = String(_stats[idx].name) if idx >= 0 else "?"
	var red: bool = not _signal_hazards.is_empty() and _signal_hazards[0].is_red()
	if red:
		_signal_bus_hits_red += 1
	else:
		_signal_bus_hits_green += 1
	# Banda pe care STATEA masina la impact (reproiectare banda-autocar):
	# lateral SEMNAT fata de axa, acelasi tipar ca ai_controller.gd
	# (_side_at.dot(pos - baked), + = dreapta sensului de mers). O masina
	# lovita in banda DREAPTA (lateral > 0) a fost impinsa in ea de autocar
	# insusi (geometrie/coliziune), nu de o eroare de AI; una lovita in banda
	# STANGA (lateral < 0) e exact defectul "AI pe banda stanga pe rosu".
	var lateral := 0.0
	var track: Track = _race.track
	if idx >= 0 and track != null:
		var r: TrackRoute = track.route_at(car.route)
		if r != null and not r.baked.is_empty():
			var bidx: int = track.closest_index_global(car.global_position, car.route)
			var side: Vector3 = r.side_at(bidx)
			lateral = side.dot(car.global_position - r.baked[r.wrap_index(bidx)])
	if lateral < 0.0:
		_signal_bus_hits_left += 1
	else:
		_signal_bus_hits_right += 1
	# Runda 3: lateralul PRE-impact (vezi doc la `_lateral_history`) — cel mai
	# vechi esantion din bufferul circular, cateva cadre INAINTE de acest
	# contact, ca sa se vada daca masina era deja pe dreapta cand a lovit-o
	# autocarul (marja prea mica) sau inca pe axa/stanga (regula n-a apucat).
	var hid := car.get_instance_id()
	var hist: Array = _lateral_history.get(hid, [])
	var pre_lat_txt := "n/a"
	if not hist.is_empty():
		var pre_lat: float = hist[0]
		var pre_side := "DREAPTA" if pre_lat > 0.0 else ("STANGA" if pre_lat < 0.0 else "AXA")
		pre_lat_txt = "%.2f(%s)" % [pre_lat, pre_side]
	print("[bus-hit] t=%5.1fs  %-18s intrata_pe=%s  banda=%s  lat=%5.2f  pre_impact_lat=%s  poz=(%.0f,%.0f,%.0f)" % [
		_elapsed, car_name, "ROSU" if red else "VERDE",
		"STANGA" if lateral < 0.0 else "DREAPTA", lateral, pre_lat_txt,
		car.global_position.x, car.global_position.y, car.global_position.z])


func _on_wall(car: Car, impact: float, index: int) -> void:
	_stats[index].walls = int(_stats[index].walls) + 1
	if _in_slice(_race.track.frac_at(car.road_index, car.route)):
		_stats[index].sl_walls = int(_stats[index].sl_walls) + 1
	_stats[index].wall_impact = maxf(float(_stats[index].wall_impact), impact)
	var b := clampi(int(_race.track.frac_at(car.road_index, car.route)
			* float(BUCKETS)),
		0, BUCKETS - 1)
	_bucket_walls[b] += 1


func _report_race() -> void:
	var track: Track = _race.track
	var cars: Array[Car] = _race.cars
	print("\n=== CURSA: %s — %.0fs, %d masini ===" % [
		track.track_name, _elapsed, cars.size()])
	print("%-20s %6s %6s %8s %7s %7s %5s %7s %6s %9s %6s %6s %6s" % [
		"masina", "tururi", "v_med", "offroad", "lent", "invers",
		"resp", "ejec p/a", "pereti", "bump/dv", "minge", "carus", "deviat"])
	var total_ej_wall := 0
	var total_ej_land := 0
	var land_max := 0.0
	var worst_offroad := 0.0
	var total_respawns := 0
	var laps: Array[float] = []
	for i in cars.size():
		var st := _stats[i]
		var done := float(_race._progress[i].total)
		laps.append(done)
		var avg := float(st.speed_sum) / maxf(float(st.samples), 1.0)
		var off_pct := float(st.offroad_s) / _elapsed * 100.0
		worst_offroad = maxf(worst_offroad, off_pct)
		total_respawns += int(st.respawns)
		total_ej_wall += int(st.ejects_wall)
		total_ej_land += int(st.ejects_land)
		land_max = maxf(land_max, float(st.land_max))
		print("%-20s %6.2f %6.1f %7.1f%% %6.1fs %6.1fs %5d %4d/%-2d %6d %4d/%4.1f %6d %6d %6d" % [
			st.name, done, avg, off_pct, float(st.slow_s), float(st.reverse_s),
			int(st.respawns), int(st.ejects_wall), int(st.ejects_land),
			int(st.walls), int(st.bumps), float(st.bump_peak),
			int(st.slide_hits), int(st.carousel_hits), int(st.deflector_hits)])
	laps.sort()
	print("--- ritm: cel mai rapid %.2f tururi, cel mai lent %.2f (ecart %.2f)" % [
		laps[laps.size() - 1], laps[0], laps[laps.size() - 1] - laps[0]])
	print("--- repuneri totale: %d · cel mai mult in afara soselei: %.1f%%" % [
		total_respawns, worst_offroad])
	print("--- ejectari: %d (perete %d, aterizare %d) · cea mai dura aterizare FARA ejectare: %.1f m/s" % [
		total_ej_wall + total_ej_land, total_ej_wall, total_ej_land, land_max])
	var branch_total := 0
	var branch_line := ""
	for i in cars.size():
		var st := _stats[i]
		if int(st.branch_laps) > 0:
			branch_total += int(st.branch_laps)
			branch_line += "  %s: %d treceri (%.1fs)" % [
				st.name, int(st.branch_laps), float(st.branch_s)]
	print("--- banda secundara: %d treceri%s" % [branch_total,
		branch_line if branch_total > 0 else " (nimeni n-a luat-o)"])
	_report_kyoto(cars)
	var bus_total := 0
	for i in cars.size():
		bus_total += int(_stats[i].bus_hits)
	if bus_total > 0 or _slice.x >= 0.0:
		print("--- contacte cu autobuzul (BusHazard): %d cadre" % bus_total)
	if not _signal_hazards.is_empty():
		print("--- semafor tunel: contacte-autocar=%d (verde: %d, rosu: %d)  treceri-pe-rosu-clare=%d  coada-maxima-simultana=%d"
			% [_signal_bus_hits, _signal_bus_hits_green, _signal_bus_hits_red,
				_signal_ran_red_clear, _signal_max_queue])
		# Runda 2: si pe BANDA masinii la impact, nu doar rosu/verde.
		print("--- contacte-autocar pe banda: stanga=%d  dreapta=%d"
			% [_signal_bus_hits_left, _signal_bus_hits_right])
		# Reproiectare banda-autocar: veto "AI onest" (0 masini-cadre pe banda
		# stanga pe rosu) si lat maxim in tunel (criteriu <= 4.0 m).
		print("--- banda-autocar: masini-cadre pe STANGA cat e rosu=%d  lat_max_tunel=%.2f m"
			% [_signal_left_lane_frames, _signal_lat_max])
	if _slice.x >= 0.0:
		print("--- felia %.3f-%.3f: %-20s %6s %6s %7s %8s" % [_slice.x, _slice.y,
			"masina", "v_med", "lent", "pereti", "autobuz"])
		var sl_speed := 0.0
		var sl_samples := 0
		var sl_slow := 0.0
		var sl_walls := 0
		var sl_bus := 0
		for i in cars.size():
			var st := _stats[i]
			var ns := maxi(int(st.sl_samples), 1)
			print("    %-32s %6.1f %5.1f%% %7d %8d" % [st.name,
				float(st.sl_speed) / float(ns),
				float(st.sl_slow) / maxf(float(st.sl_samples) / 60.0, 0.001) * 100.0,
				int(st.sl_walls), int(st.sl_bus)])
			sl_speed += float(st.sl_speed)
			sl_samples += int(st.sl_samples)
			sl_slow += float(st.sl_slow)
			sl_walls += int(st.sl_walls)
			sl_bus += int(st.sl_bus)
		print("    %-32s %6.1f %5.1f%% %7d %8d" % ["TOTAL",
			sl_speed / float(maxi(sl_samples, 1)),
			sl_slow / maxf(float(sl_samples) / 60.0, 0.001) * 100.0, sl_walls, sl_bus])
	print("\n--- unde se scurge viteza (felie de pista -> v_med, %% lent, pereti)")
	for b in BUCKETS:
		var samples := maxi(_bucket_samples[b], 1)
		var avg := _bucket_speed[b] / float(samples)
		var slow_pct := float(_bucket_slow[b]) / float(samples) * 100.0
		var bar := "#".repeat(int(avg / 2.0))
		print("  %.2f-%.2f  %5.1f m/s %5.1f%% lent %3d pereti  %s" % [
			float(b) / float(BUCKETS), float(b + 1) / float(BUCKETS),
			avg, slow_pct, _bucket_walls[b], bar])
	_finish()


## Kyoto (brief §7 pasul 3): timpi pe tur, saritura C2, banda E', tubul.
func _report_kyoto(cars: Array[Car]) -> void:
	var carpet := _race.track.get_node_or_null("CovorFrunze") as LeafCarpet
	if carpet != null:
		# Stampilele reale ale rotilor din cursa, pe benzi laterale de 1 m: o linie
		# de cursa formata = varfuri, nu o distributie plata.
		print("--- covor de frunze: %d stampile de la masini · lateral (m, ecart 1 m): %s" % [
			carpet.stamps_received, carpet.lateral_hist])
	var all_laps: Array[float] = []
	print("--- ture (s): masina | ture complete | minim | mediu")
	for i in cars.size():
		var st := _stats[i]
		var t: Array = st.lap_t
		var laps_s: Array[float] = []
		var prev := 0.0
		for k in t.size():
			laps_s.append(float(t[k]) - prev)
			prev = float(t[k])
		var mn := 0.0
		var avg := 0.0
		if not laps_s.is_empty():
			mn = laps_s.min()
			for v in laps_s:
				avg += v
			avg /= float(laps_s.size())
			all_laps.append_array(laps_s)
		print("    %-30s %2d  min %6.2f  med %6.2f" % [st.name, laps_s.size(), mn, avg])
	if not all_laps.is_empty():
		var tot := 0.0
		for v in all_laps:
			tot += v
		print("--- TUR global: %d ture, minim %.2f s, mediu %.2f s" % [
			all_laps.size(), all_laps.min(), tot / float(all_laps.size())])
	if _jump_near >= 0.0:
		var ok := 0
		var fail := 0
		var line := ""
		for i in cars.size():
			ok += int(_stats[i].jump_ok)
			fail += int(_stats[i].jump_fail)
			var vs: Array = _stats[i].jump_v
			var vtxt := ""
			if not vs.is_empty():
				var vmin := 1e9
				var vsum := 0.0
				for v in vs:
					vmin = minf(vmin, float(v))
					vsum += float(v)
				vtxt = "(v buza %.0f..%.0f)" % [vmin, vsum / float(vs.size())]
			line += "  %s:%d/%d%s" % [String(_stats[i].name).get_slice("(", 1).trim_suffix(")"),
				int(_stats[i].jump_ok), int(_stats[i].jump_fail), vtxt]
		print("--- saritura C2: treceri=%d caderi/repuneri-in-fereastra=%d  (masina:ok/cazut)%s" % [ok, fail, line])
	var tub_hits := 0
	for i in cars.size():
		tub_hits += int(_stats[i].tub_hits)
	if not _shishi.is_empty():
		print("--- tub shishi-odoshi: aruncari=%d contact-cadre=%d" % [_tub_throws, tub_hits])
	elif _no_tub:
		print("--- tub shishi-odoshi: DEZACTIVAT (--no-tub)")
	var daruma_hits := 0
	for i in cars.size():
		daruma_hits += int(_stats[i].daruma_hits)
	if not _daruma.is_empty():
		print("--- daruma-otoshi: aruncari=%d contact-cadre (turn/ciocan/disc solid)=%d" % [_daruma_throws, daruma_hits])
	elif _no_daruma:
		print("--- daruma-otoshi: DEZACTIVAT (--no-daruma)")
	if not _devils.is_empty():
		var spins := 0
		for dv in _devils:
			spins += dv.spins
		print("--- vartej (kogarashi/praf): treceri de masini=%d" % spins)
	elif _no_kogarashi:
		print("--- vartej: DEZACTIVAT (--no-kogarashi)")


# ---------------------------------------------------------------- mod bump

## Fiecare caz: atacatorul intra din spate in victima oprita, la aceeasi viteza.
## Daca modelul de masa e corect, dv-ul victimei creste cu raportul de mase, iar
## atacatorul greu isi pierde mult mai putina viteza decat cel usor.
func _start_bump() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 2, 400)
	shape.shape = box
	shape.position = Vector3(0, -1, 0)
	ground.add_child(shape)
	add_child(ground)
	var garage := GameState.CAR_DATA
	# (atacator, victima) — perechile care conteaza pentru principiul de design.
	for pair: Array in [[3, 0], [0, 3], [0, 1], [1, 0], [4, 2], [2, 4], [0, 0]]:
		_bump_cases.append({
			"attacker": garage[pair[0]] as CarData,
			"victim": garage[pair[1]] as CarData,
			"kind": "spate",
		})
	# Loviturile DIRECTIONALE: acelasi contact, alt loc pe caroserie.
	#   colt    — din spate, dar prins pe coltul victimei (PIT): trebuie sa o
	#             roteasca vizibil, in timp ce lovitura centrata de mai sus nu.
	#   lateral — in plin, perpendicular (T-bone): victima impinsa si sucita.
	for c: Array in [[0, 0, "colt"], [0, 0, "lateral"], [3, 1, "lateral"]]:
		_bump_cases.append({
			"attacker": garage[c[0]] as CarData,
			"victim": garage[c[1]] as CarData,
			"kind": c[2],
		})
	_next_bump_case()


func _next_bump_case() -> void:
	if _bump_attacker != null:
		_bump_attacker.queue_free()
		_bump_victim.queue_free()
		_bump_attacker = null
	_bump_case += 1
	if _bump_case >= _bump_cases.size():
		_report_bump()
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Victima sta pe loc, cu botul spre -Z; atacatorul soseste deja lansat:
	# masuram impactul, nu accelerarea. Amandoua in liber — O SINGURA izbitura.
	_bump_victim = _spawn_bump_car(vic, Vector3(0, 0.6, 0), 0.0)
	match kind:
		"lateral":
			# T-bone: atacatorul vine perpendicular, dinspre +X, tintit putin
			# spre spatele victimei ca sa existe brat de parghie (in realitate
			# lovitura in dreptul centrului de masa doar impinge).
			var gap_x: float = (att.body_length + vic.body_width) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(gap_x, 0.6, vic.body_length * 0.25), 0.0)
			_bump_attacker.rotate_y(PI / 2.0) # cu botul spre -X, incotro merge
			_bump_attacker.velocity = Vector3(-BUMP_ENTRY_SPEED, 0, 0)
		"colt":
			# PIT: din spate, dar decalat lateral — contactul prinde coltul.
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att,
				Vector3(vic.body_width * 0.45, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
		_:
			var gap: float = (att.body_length + vic.body_length) * 0.5 + 4.0
			_bump_attacker = _spawn_bump_car(att, Vector3(0, 0.6, gap), 0.0)
			_bump_attacker.velocity = Vector3(0, 0, -BUMP_ENTRY_SPEED)
	_bump_victim_yaw0 = _bump_victim.rotation.y
	_bump_frames = 0
	_bump_peak = 0.0
	_bump_attacker_loss = 0.0
	_bump_attacker_floor = BUMP_ENTRY_SPEED
	_bump_impulses_att = 0
	_bump_impulses_vic = 0
	_bump_impulse_peak_att = 0.0
	_bump_impulse_peak_vic = 0.0


# ----------------------------------------------------- mod cliff (anti-blocaj)

## Peretii de canion sunt ~130 de forme convexe puse cap la cap, cu suprapunere
## de 1m. Suprapunerea exista tocmai ca sa nu ramana fisuri intre ele — dar
## "fara fisuri" e o afirmatie care trebuie verificata, nu presupusa: o masina
## intepenita intr-o imbinare inseamna cursa terminata pentru jucator.
##
## Testul: arunca masina in unghi in perete, la viteza, in mai multe puncte de pe
## traseu, si urmareste daca ramane oprita. Deliberat FARA repunere automata —
## plasa de siguranta din race.gd ar ascunde exact problema pe care o cautam.
func _start_cliff() -> void:
	GameState.selected_track = _track_index
	_cliff_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_cliff_track)
	var n := _cliff_track.baked.size()
	for frac in CLIFF_FRACS:
		var idx := int(frac * float(n)) % n
		# Ambele laturi: peretele interior si cel exterior au offseturi diferite,
		# deci si imbinari diferite.
		for side: float in [-1.0, 1.0]:
			_cliff_cases.append({"idx": idx, "side": side, "frac": frac})
	_next_cliff_case()


func _next_cliff_case() -> void:
	if _cliff_car != null:
		_cliff_car.queue_free()
		_cliff_car = null
	_cliff_case += 1
	if _cliff_case >= _cliff_cases.size():
		_report_cliff()
		return
	var c := _cliff_cases[_cliff_case]
	var idx: int = c["idx"]
	var side: float = c["side"]
	var n := _cliff_track.baked.size()
	var p: Vector3 = _cliff_track.baked[idx]
	var fwd: Vector3 = (_cliff_track.baked[(idx + 1) % n] - p).normalized()
	var lat := fwd.cross(Vector3.UP).normalized() * side

	# Pornim de pe banda dinspre perete, indreptati spre el sub CLIFF_ANGLE_DEG.
	var start := p + lat * (_cliff_track.half_width * 0.5) + Vector3.UP * 0.6
	var dir := fwd.rotated(Vector3.UP, deg_to_rad(CLIFF_ANGLE_DEG) * -side) \
		.normalized()

	_cliff_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_cliff_car)
	_cliff_car.apply_data(GameState.CAR_DATA[0] as CarData)
	# FARA linia asta sonda masoara cu totul altceva decat crede.
	#
	# Car._physics_process sare peste actualizarea lui road_index cand track e
	# null, deci indexul ramane 0 pe veci; AIController vireaza atunci spre
	# lookahead_point(0, ...), adica spre LINIA DE START, indiferent unde e
	# masina; iar supapa lui de scapare, car.respawn(), iese imediat pentru ca
	# respawn() cere track != null. Rezultatul: masuram "tine manevra de
	# marsarier a AI-ului peste 2 m/s", nu "te prinde geometria falezei".
	_cliff_car.track = _cliff_track
	_cliff_car.road_index = _cliff_track.closest_index_global(start)
	_cliff_car.last_safe_index = _cliff_car.road_index
	_cliff_car.global_position = start
	_cliff_car.look_at(start + dir, Vector3.UP)
	_cliff_car.race_active = true
	# Un AI adevarat la volan, nu comenzi fixe.
	#
	# Prima versiune folosea ScriptedController cu volanul drept: masina intra in
	# perete si impingea in el la infinit, deci iesea "intepenita" oriunde —
	# inclusiv pe forest, care n-are faleze, doar gardul rosu de dinainte (3 din
	# 12, apoi 9 din 12 cand am adaugat un viraj fix). Masura lipsa de reactie, nu
	# geometria.
	#
	# AIController stie sa dea marsarier si sa reia linia, adica exact ce ar face
	# un jucator. Daca NICI EL nu scapa, atunci chiar e o capcana de geometrie.
	var ai := AIController.new()
	_cliff_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + _cliff_case
	ai.configure(_cliff_track, rng)
	_cliff_car.velocity = dir * CLIFF_ENTRY_SPEED
	_cliff_time = 0.0
	_cliff_slow_time = 0.0


func _tick_cliff(delta: float) -> void:
	if _cliff_car == null:
		return
	_cliff_time += delta
	var speed := Vector2(_cliff_car.velocity.x, _cliff_car.velocity.z).length()
	# Primele 0.4s sunt zborul pana la perete; nu conteaza pentru "intepenit".
	if _cliff_time > 0.4 and speed < CLIFF_STUCK_SPEED:
		_cliff_slow_time += delta
	else:
		_cliff_slow_time = 0.0
	if _cliff_time >= CLIFF_CASE_SECONDS \
			or _cliff_slow_time >= CLIFF_STUCK_SECONDS:
		var c := _cliff_cases[_cliff_case]
		_cliff_rows.append({
			"frac": c["frac"],
			"side": c["side"],
			"stuck": _cliff_slow_time >= CLIFF_STUCK_SECONDS,
			"exit_speed": speed,
			"stuck_time": _cliff_slow_time,
		})
		_next_cliff_case()


func _report_cliff() -> void:
	print("\n=== ANTI-BLOCAJ IN PERETII DE CANION (%s) ==="
		% GameState.TRACK_NAMES[_track_index])
	print("intrare %.0f m/s la %.0f°, intepenit = sub %.1f m/s mai mult de %.1fs"
		% [CLIFF_ENTRY_SPEED, CLIFF_ANGLE_DEG, CLIFF_STUCK_SPEED,
			CLIFF_STUCK_SECONDS])
	print("%8s %6s %12s %10s" % ["fractie", "parte", "viteza iesire", "stare"])
	print("-".repeat(40))
	var stuck := 0
	for row in _cliff_rows:
		if row["stuck"]:
			stuck += 1
		print("%8.2f %6s %9.1f m/s %10s" % [
			row["frac"], "st" if float(row["side"]) < 0.0 else "dr",
			row["exit_speed"], "INTEPENIT" if row["stuck"] else "ok"])
	print("\n%d cazuri, %d intepenite" % [_cliff_rows.size(), stuck])
	print("VERDICT: %s" % ("PROBLEMA" if stuck > 0 else "OK"))
	_done = true
	get_tree().quit(1 if stuck > 0 else 0)


func _spawn_bump_car(data: CarData, pos: Vector3, throttle: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	# Pozitia INAINTE de add_child: corpul intra in serverul de fizica direct
	# la locul lui. Setata dupa, exista un cadru in care ambele masini stau
	# suprapuse la origine — depenetrarea o arunca pe victima pe ACOPERISUL
	# atacatorului, unde platforma mobila o cara cu viteza proprie zero si
	# cazul masoara o plimbare, nu o izbitura (primul rand din matrice iesea
	# cu 0 impulsuri si victima "impinsa" 21 m).
	car.position = pos
	add_child(car)
	car.apply_data(data)
	car.race_active = true
	var ctrl := ScriptedController.new()
	ctrl.throttle = throttle
	car.set_controller(ctrl)
	car.bumped.connect(_on_bump_impulse)
	return car


## Numaram impulsurile REALE emise de Car._resolve_bump: daca dv-ul masurat e
## zero dar impulsurile curg, inseamna ca move_and_slide le anuleaza (masina e
## intrepatrunsa), nu ca modelul de imbranceala tace.
func _on_bump_impulse(car: Car, _other: Car, delta_v: float) -> void:
	if car == _bump_attacker:
		_bump_impulses_att += 1
		_bump_impulse_peak_att = maxf(_bump_impulse_peak_att, delta_v)
	else:
		_bump_impulses_vic += 1
		_bump_impulse_peak_vic = maxf(_bump_impulse_peak_vic, delta_v)


func _tick_bump() -> void:
	if _bump_attacker == null:
		return
	_bump_frames += 1
	if _bump_frames > 3: # dupa ce au coborat pe sol
		_bump_peak = maxf(_bump_peak, _bump_victim.horizontal_speed())
		_bump_attacker_loss = maxf(_bump_attacker_loss,
			BUMP_ENTRY_SPEED - _bump_attacker.horizontal_speed())
		# Podeaua de viteza abia DUPA ce izbitura a avut loc — inainte de
		# contact atacatorul merge cu viteza de intrare si cifra n-ar spune nimic.
		if _bump_impulses_att + _bump_impulses_vic > 0:
			_bump_attacker_floor = minf(_bump_attacker_floor,
				_bump_attacker.horizontal_speed())
	if _bump_frames < 90:
		return
	var c := _bump_cases[_bump_case]
	var att := c.attacker as CarData
	var vic := c.victim as CarData
	var kind := String(c.kind)
	# Distanta dintre centre la final vs. suma semi-gabaritelor pe directia
	# loviturii: sub 1.0 inseamna ca atacatorul a "inghitit" victima si o cara
	# in el, nu a imbrancit-o.
	var touching := (att.body_length + vic.body_length) * 0.5 \
		if kind != "lateral" else (att.body_length + vic.body_width) * 0.5
	var apart := _bump_attacker.global_position - _bump_victim.global_position
	apart.y = 0.0
	var pushed := _bump_victim.global_position
	pushed.y = 0.0
	_bump_rows.append({
		"attacker": att.display_name, "victim": vic.display_name,
		"kind": kind,
		"ratio": att.mass_factor / vic.mass_factor,
		"victim_dv": _bump_peak, "attacker_loss": _bump_attacker_loss,
		"attacker_floor": _bump_attacker_floor,
		"pushed": pushed.length(), "sep": apart.length() / touching,
		"yaw_deg": absf(rad_to_deg(wrapf(
			_bump_victim.rotation.y - _bump_victim_yaw0, -PI, PI))),
		"impulses": _bump_impulses_att + _bump_impulses_vic,
		"impulse_peak": maxf(_bump_impulse_peak_att, _bump_impulse_peak_vic),
	})
	_next_bump_case()


func _report_bump() -> void:
	print("\n=== IMBRANCELI (atac la %.0f m/s in masina oprita) ===" % [
		BUMP_ENTRY_SPEED])
	print("frana atac = varful de viteza pierduta; v_min atac = podeaua de dupa")
	print("contact (aproape de zero inseamna \"zid\", nu transfer de impuls)")
	print("%-12s %-12s %-7s %8s %11s %11s %10s %8s %7s %6s %8s %6s" % [
		"atacator", "victima", "tip", "m_a/m_v", "dv victima", "frana atac",
		"v_min atac", "impinsa", "separ", "rotita", "impuls", "dv_max"])
	for row in _bump_rows:
		print("%-12s %-12s %-7s %8.2f %10.1f %10.1f %10.1f %8.1f %7.2f %5.0f° %6d %8.1f" % [
			row.attacker, row.victim, row.kind, row.ratio,
			row.victim_dv, row.attacker_loss, row.attacker_floor,
			row.pushed, row.sep, row.yaw_deg,
			row.impulses, row.impulse_peak])
	_finish()
