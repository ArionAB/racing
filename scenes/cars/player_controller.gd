class_name PlayerController
extends CarController
## Tastatura (dezvoltare desktop) + starea touch din GameState.

func get_steer() -> float:
	# get_axis(negativ, pozitiv): steer_left da +1 = viraj stanga.
	var steer := Input.get_axis("steer_right", "steer_left")
	if absf(GameState.touch_steer) > 0.0:
		# Pe ecran -1 inseamna stanga; in fizica stanga e +1 — inversam.
		steer = -GameState.touch_steer
	return clampf(steer, -1.0, 1.0)

func get_throttle() -> float:
	# Auto-accelerate: masina merge singura, franezi doar explicit.
	if Input.is_action_pressed("brake"):
		return -1.0
	return 1.0

func is_drift_pressed() -> bool:
	return Input.is_action_pressed("drift") or GameState.touch_drift
