class_name CareerChallenge
extends Resource
## Provocarea gimmick-ului unei piste (brief §4.3): O singura conditie, scrisa cu
## numele gimmick-ului, verificata pe o cursa normala. Nu cere si locul 1 — poti
## reusi provocarea sosind ultimul; asta o face o proba separata, nu un duplicat
## al medaliei de cursa. Continut nou = un .tres nou in `data/challenges/` +
## o linie in `career_config.tres`, zero cod.

## Regula de evaluare. In 4a exista doar ZERO_EVENTS (esti picat la primul
## eveniment); regulile pe tur / pe zona vin in 4b.
enum Rule { ZERO_EVENTS }

## Evenimentele pe care `ChallengeTracker` stie sa le asculte.
const KNOWN_EVENTS: Array[StringName] = [
	&"thrown", &"fireball", &"animal", &"splash", &"crush", &"shove",
	&"traffic_bump",
]

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
