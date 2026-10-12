class_name PlayerController
extends CarController
## Tastatura (dezvoltare desktop) + starea touch din GameState.

func get_steer() -> float:
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
	if GameState.touch_handbrake:
		return _handbrake_throttle()
	# Touch: sageata sus (sau TURBO) = gaz.
	return GameState.touch_throttle

## Sub viteza asta (m/s, inainte) masina e "pe loc": frana de mana da marsarier.
const HANDBRAKE_REVERSE_SPEED: float = 1.0

## Frana de mana pe touch, dupa viteza:
## - pe loc sau deja inapoi: marsarier (inlocuieste fosta sageata jos);
## - in drift: gazul ramane al lui ^ — frana de mana doar tine spatele liber;
## - inainte, fara drift (linie dreapta sau prea incet): franeaza.
## Din viteza, tinuta, franeaza pana la oprire si apoi trece in marsarier,
## exact ca fosta sageata jos.
func _handbrake_throttle() -> float:
	if car == null:
		return -1.0
	var fwd := -car.global_transform.basis.z
	if car.linear_velocity.dot(fwd) < HANDBRAKE_REVERSE_SPEED:
		return -1.0
	if car.is_drifting:
		return GameState.touch_throttle
	return -1.0

func is_drift_pressed() -> bool:
	# Frana de mana de pe touch e drift-ul (handbrake pur, ca tasta).
	return Input.is_action_pressed("drift") or GameState.touch_handbrake

func is_turbo_pressed() -> bool:
	return Input.is_action_pressed("turbo") or GameState.touch_turbo
