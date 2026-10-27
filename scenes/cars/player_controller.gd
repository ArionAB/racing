class_name PlayerController
extends CarController
## Tastatura (dezvoltare desktop) + starea touch din GameState.

## Cat dureaza pana volanul ajunge de la 0 la 1 cand apesi (tasta/buton).
## Un buton da -1/0/+1: fara netezire, o atingere smuceste masina.
@export var steer_ramp_in: float = 0.10
## Cat dureaza eliberarea (0 sau spre centru): putin mai repede decat intrarea.
@export var steer_ramp_out: float = 0.06
## Dezactivat = volanul brut (sondele si comparatiile A/B).
@export var steer_smoothing: bool = true

var _steer_out: float = 0.0

## Netezeste volanul DIGITAL (butoane/taste dau -1/0/+1): intra in ~0.1 s,
## iese putin mai repede, iar la inversarea sensului trece prin zero IMEDIAT
## (altfel ar fi inertie: ai da dreapta si masina ar mai vira stanga o clipa).
func update(delta: float) -> void:
	var target := _raw_steer()
	if not steer_smoothing:
		_steer_out = target
		return
	if target != 0.0 and _steer_out != 0.0 and signf(target) != signf(_steer_out):
		_steer_out = 0.0
	var rate := 1.0 / maxf(steer_ramp_in, 0.001)
	if absf(target) < absf(_steer_out):
		rate = 1.0 / maxf(steer_ramp_out, 0.001)
	_steer_out = move_toward(_steer_out, target, rate * delta)

func get_steer() -> float:
	return _steer_out

func _raw_steer() -> float:
	# get_axis(negativ, pozitiv): steer_left da +1 = viraj stanga.
	var steer := Input.get_axis("steer_right", "steer_left")
	if absf(GameState.touch_steer) > 0.0:
		# Pe ecran -1 inseamna stanga; in fizica stanga e +1 — inversam.
		steer = -GameState.touch_steer
	# Sensibilitatea imblanzeste raspunsul "totul sau nimic" de pe touch.
	return clampf(steer * GameState.steer_sensitivity, -1.0, 1.0)

func get_throttle() -> float:
	if Input.is_action_pressed("brake"):
		return -1.0
	if Input.is_action_pressed("accelerate"):
		return 1.0
	# Touch: acceleratie EXPLICITA, pe butonul ^ din dreapta-jos (decizia
	# dezvoltatorului, oct 2026, dupa primul test pe iPhone). Inainte mergea pe
	# auto-accelerate — orice deget pe ecran insemna gaz — dar atunci butonul
	# din mockup n-ar fi facut nimic: mergeai la fel si fara sa-l atingi.
	# Frana BATE gazul: daca tii amandoua (degetul mare pe granita), vrei sa
	# incetinesti. `throttle < 0` franeaza cat mergi inainte si devine
	# marsarier cand aproape ai oprit — o singura comanda pentru amandoua.
	if GameState.touch_brake:
		return -1.0
	if GameState.touch_gas:
		return 1.0
	# TURBO implica gaz: altfel ai arde bara stand pe loc, iar TURBO si ^ nu
	# pot fi tinute simultan cu acelasi deget mare.
	if GameState.touch_turbo:
		return 1.0
	# DRIFT implica gaz, din acelasi motiv ca TURBO: pe touch toate butoanele
	# de actiune stau sub degetul mare drept, deci DRIFT nu poate fi tinut
	# odata cu ^. Istoric (oct 2026): implica gaz (#552) -> nu implica, ca sa
	# poti frana in drift (#559) -> DRIFT singur = frana de mana (#578) ->
	# inapoi la gaz (26 oct). Ce s-a schimbat intre timp: driftul tine viteza
	# doar cu gaz (`drift_momentum_keep`, #579), iar AI-ul drifteaza mereu
	# cu gazul apasat. Masurat in ProbeDriftEntry --drift-throttle=, la 85%
	# din vmax dupa 1 s de drift: cu gaz 99% din viteza, pe inertie 27%, cu
	# frana 9% si masina intoarsa cu spatele. Adica pe telefon fiecare drift
	# era o oprire de urgenta cu piruieta, iar AI-ul parea ca „n-are
	# problema". Virajul strans vine acum din maparea CTR (arcul strans), nu
	# din frana; iar cine vrea totusi sa franeze derapand tine v (sau S pe
	# tastatura): frana bate gazul, vezi mai sus. Si pe tastatura la fel, ca
	# testul de pe desktop sa simta exact ce simte telefonul.
	if is_drift_pressed():
		return 1.0
	return 0.0

func is_drift_pressed() -> bool:
	return Input.is_action_pressed("drift") or GameState.touch_drift

func is_turbo_pressed() -> bool:
	return Input.is_action_pressed("turbo") or GameState.touch_turbo
