extends Node
## Sunetul rocket start-ului (docs/feel_checklist.md: toy-sound-palette), DOAR
## pentru jucator.
##
## Doua momente, amandoua din jucaria cu arc:
##   - cat tii TURBO apasat in fereastra de rocket start a numaratorii, un clichet
##     de cheie de intors (`rocket_ratchet`) se reia la `ratchet_interval_s`, cu
##     pitch-ul urcand cu cat tii mai mult — arcul se incarca. Daca tii prea mult
##     (peste `window_s`, „Too early..."), clichetul se opreste: lipsa lui e
##     avertismentul;
##   - la GO, DOAR daca startul a fost rocket, arcul tras se descarca intr-un
##     „zrrrt" (`rocket_spring`). Un start obisnuit nu-l scoate.
##
## Nu hotaraste el cand e rocket: `Race._go()` cunoaste regula (`hold` intre 0.05 si
## 1.05 s) si cheama `on_go(true)`; `window_s` de aici trebuie sa ramana egal cu
## limita de acolo (o singura cifra de tinut sincronizata, verificata de sonda).

## Cat de mult poate tine TURBO-ul (s) ca startul sa ramana rocket (ca in Race).
@export var window_s: float = 1.05
## Sub atata (s) de apasare nu se aude nimic (un tap scapat nu incarca arcul).
@export var min_hold_s: float = 0.05
## Pauza dintre doua clichete, cat tii apasat (s).
@export var ratchet_interval_s: float = 0.30
## Pitch-ul clichetului la inceputul apasarii si la capatul ferestrei.
@export var ratchet_pitch: Vector2 = Vector2(0.95, 1.5)
@export var ratchet_db: float = -12.0
@export var spring_db: float = -5.0

## Pentru sonde: cate clichete si cate descarcari de arc au sunat.
var ratchets: int = 0
var springs: int = 0

var _next_ratchet: float = 0.0


## Cheama-l la fiecare tick al numaratorii cu cat timp (s) tine jucatorul TURBO.
func tick(delta: float, hold_s: float) -> void:
	if hold_s < min_hold_s or hold_s > window_s:
		_next_ratchet = 0.0
		return
	_next_ratchet -= delta
	if _next_ratchet > 0.0:
		return
	_next_ratchet = ratchet_interval_s
	ratchets += 1
	AudioManager.play_sfx(&"rocket_ratchet",
		lerpf(ratchet_pitch.x, ratchet_pitch.y, clampf(hold_s / window_s, 0.0, 1.0)),
		ratchet_db)


## Cheama-l la GO. `rocket` = startul jucatorului e rocket (decis de Race).
func on_go(rocket: bool) -> void:
	_next_ratchet = 0.0
	if not rocket:
		return
	springs += 1
	AudioManager.play_sfx(&"rocket_spring", 1.0, spring_db)
