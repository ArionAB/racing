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
	# Touch: auto-accelerate — orice deget pe ecran inseamna gaz (standardul
	# mobile, nu exista pedala). Pe tastatura accelerezi explicit cu W/Sus.
	if GameState.touch_active:
		return 1.0
	return 0.0

func is_drift_pressed() -> bool:
	return Input.is_action_pressed("drift") or GameState.touch_drift

func is_turbo_pressed() -> bool:
	return Input.is_action_pressed("turbo") or GameState.touch_turbo
