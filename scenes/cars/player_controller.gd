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
	#
	if GameState.touch_turbo:
		return 1.0
	# DRIFT SINGUR e frana de mana adevarata: franeaza si, aproape oprit, da
	# MARSARIER — exact ca v (decizia dezvoltatorului, oct 2026). Inainte
	# implica gaz (nu puteai frana in drift), apoi lasa masina pe inertie, si
	# se simtea ca butonul te impinge inainte. Cu ^ sau TURBO tinute, cele de
	# mai sus castiga: ^ + DRIFT ramane drift accelerand.
	if is_drift_pressed():
		return -1.0
	return 0.0

func is_drift_pressed() -> bool:
	return Input.is_action_pressed("drift") or GameState.touch_drift

func is_turbo_pressed() -> bool:
	return Input.is_action_pressed("turbo") or GameState.touch_turbo
