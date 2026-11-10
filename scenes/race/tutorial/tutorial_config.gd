class_name TutorialConfig
extends Resource
## Textele si pragurile turului ghidat (#678). Verdictul pe ele e al
## dezvoltatorului, la volan si pe telefon: formularea, ritmul, pista, cat
## drift si cata bara. De aceea stau aici, intr-o resursa editabila din
## inspector (`tutorial_default.tres`), nu in cod.
##
## In textele de tastatura, `{steer_left}`, `{steer_right}`, `{accelerate}`,
## `{brake}`, `{drift}`, `{turbo}` se inlocuiesc cu tasta din InputMap, ca
## indiciul sa ramana corect daca se remapeaza tastele.

## Pista turului, dupa `TrackInfo.id` (nu index: lista de piste se schimba).
## Monument Valley: deschide Lumea 1 a carierei si FRONTIER CUP, pornirea e pe
## asfalt, pe un platou cu un viraj larg si apoi o dreapta de 150 m.
@export var track_id: StringName = &"monument_valley"
## Ordinea indiciilor. Pasii cunoscuti: steer, gas, drift, turbo. Un pas scos
## din lista nu se mai cere (de ex. gas, cand gazul automat (#679) e pornit).
@export var steps: Array[StringName] = [&"steer", &"gas", &"drift", &"turbo"]

@export_group("Praguri")
## Bara de turbo la GO. In cursa normala pleci cu ce s-a strans in
## numaratoare (~0.36); in tur pleci cu ea goala, ca jucatorul sa vada ca se
## umple din mers. Negativ = bara nu se atinge.
@export var start_bar: float = 0.0
## Cat de mult trebuie tinut volanul (comanda netezita a PlayerController,
## 0..1) ca sa conteze drept viraj.
@export var steer_threshold: float = 0.6
## Cat timp (s) trebuie tinut virajul, pe fiecare parte.
@export var steer_hold_s: float = 0.35
## Ambele sensuri (stanga SI dreapta), ca jucatorul sa gaseasca ambele butoane.
@export var steer_both_sides: bool = true
## Viteza la care pasul de gaz e facut (km/h), cu gazul apasat.
@export var gas_speed_kmh: float = 30.0
## Cat drift ADEVARAT (Car.is_drifting, nu butonul) se aduna, in secunde.
## 1.5 s de drift umplu ~0.37 din bara (turbo_drift_multiplier 2.5).
@export var drift_required_s: float = 1.5
## Bara la intrarea in pasul de drift, ca umplerea sa porneasca de jos si sa
## se vada. Negativ = bara nu se atinge.
@export var drift_bar_reset: float = 0.0
## Cata bara trebuie ARSA (0..1) ca turbo-ul sa conteze. Arderea gratuita a
## rocket start-ului nu goleste bara, deci nu conteaza.
@export var turbo_burn_required: float = 0.2
## Dupa cate secunde fara gest butonul vizat incepe sa pulseze (doar touch).
@export var nudge_after_s: float = 2.5
## Cat sta cartonasul final pe ecran (s) inainte sa se ascunda singur.
@export var done_card_s: float = 10.0

@export_group("Texte")
@export var intro_title: String = "TUTORIAL"
@export var intro_body: String = "Follow the hints.\nEach one goes away once you've done it."
@export var steer_title: String = "STEER"
@export var steer_touch: String = "Hold the LEFT and the RIGHT arrow"
@export var steer_keys: String = "Hold {steer_left} and {steer_right} to steer"
@export var gas_title: String = "GAS"
@export var gas_touch: String = "Hold the green arrow to drive"
@export var gas_keys: String = "Hold {accelerate} to drive"
@export var drift_title: String = "DRIFT"
@export var drift_touch: String = "Hold DRIFT while you turn.\nDrifting fills the turbo bar fast!"
@export var drift_keys: String = "Hold {drift} while you turn.\nDrifting fills the turbo bar fast!"
@export var drift_sub_speed: String = "Faster! You need speed to drift"
@export var drift_sub_turn: String = "Now turn while you hold it"
@export var turbo_title: String = "TURBO"
@export var turbo_touch: String = "Hold TURBO (the flame) to burn the bar"
@export var turbo_keys: String = "Hold {turbo} to burn the bar"
@export var turbo_sub_empty: String = "Bar empty: drift to fill it"
@export var done_title: String = "YOU'RE READY!"
@export var done_body: String = "Drift fills the bar. TURBO burns it, you pick the moment.\nTIP: hold TURBO as the countdown ends for a ROCKET START."
@export var skip_label: String = "SKIP TUTORIAL"
@export var continue_label: String = "CONTINUE"

@export_group("Invitatia de la prima pornire")
@export var invite_title: String = "FIRST TIME HERE?"
@export var invite_body: String = "Take a one-minute test drive:\nsteering, gas, drift and turbo."
@export var invite_play: String = "TEST DRIVE"
@export var invite_skip: String = "SKIP"
