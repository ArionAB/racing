class_name CareerChallenge
extends Resource
## Provocarea gimmick-ului unei piste (brief §4.3): O singura conditie, scrisa cu
## numele gimmick-ului, verificata pe o cursa normala. Nu cere si locul 1 — poti
## reusi provocarea sosind ultimul; asta o face o proba separata, nu un duplicat
## al medaliei de cursa. Continut nou = un .tres nou in `data/challenges/` +
## o linie in `career_config.tres`, zero cod.

## Regula de evaluare (`ChallengeTracker.evaluate`):
##  ZERO_EVENTS — reusit daca niciun eveniment al jucatorului (primul pica pe loc).
##  AT_LEAST    — reusit daca la final `events >= count` si `fail_event` nu
##                s-a intamplat niciodata (pica pe loc la `fail_event`).
##  EVERY_LAP   — fiecare tur incheiat trebuie sa aiba >= 1 eveniment; un tur
##                incheiat cu 0 pica provocarea pe loc.
##  CLEAN_LAP   — reusit daca exista cel putin un tur incheiat cu 0 evenimente;
##                nu pica pe loc, se decide la final.
enum Rule { ZERO_EVENTS, AT_LEAST, EVERY_LAP, CLEAN_LAP }

## Evenimentele pe care `ChallengeTracker` stie sa le asculte.
const KNOWN_EVENTS: Array[StringName] = [
	&"thrown", &"fireball", &"animal", &"splash", &"crush", &"shove",
	&"traffic_bump", &"red_run", &"boarded", &"plate_broken", &"wall_hit",
	&"branch",
]

## Evenimente acceptate si ca `fail_event` (pe langa `KNOWN_EVENTS`).
const FAIL_EVENTS: Array[StringName] = [&"bus_hit"]

## `TrackInfo.id` al pistei.
@export var track: StringName = &""
## Scurt, pe foaia pistei si in HUD.
@export var title: String = ""
## O propozitie: ce trebuie facut, cu numele gimmick-ului.
@export var hint: String = ""
@export var rule: Rule = Rule.ZERO_EVENTS
## Unul din `KNOWN_EVENTS`.
@export var event: StringName = &""
## Doar pentru `splash`: puterea minima care conteaza (0 = orice). Valul din
## Okinawa da 0.22 cand esti in apa si 0.75 cand te loveste creasta: pragul 0.5
## le desparte, ca stropirea sa nu pice provocarea.
@export var threshold: float = 0.0
## Doar pentru `wall_hit`: impactul orizontal minim (dv, m/s) care conteaza.
## Car emite `wall_hit` de la dv > 8; asta e frecare de perete. Provocarea
## numara de la un prag mai sus, ca o atingere usoara sa nu pice proba.
## (`threshold` e refolosit: splash = puterea valului, wall_hit = dv.)

## Doar pentru `AT_LEAST`: cate evenimente trebuie numarate.
@export var count: int = 0
## Optional: primul eveniment de acest fel al jucatorului pica provocarea,
## indiferent de regula (ex. `bus_hit` la Transfagarasan).
@export var fail_event: StringName = &""
## Optional: numele nodului-zona din pista (`track.find_child`) in care
## evenimentul conteaza (ex. `StancaSpirala`). Lipsa zonei nu se vede in
## `validate()` (zona e in scena): o verifica sonda pe pista reala.
@export var zone: StringName = &""
