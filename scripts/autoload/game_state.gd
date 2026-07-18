extends Node
## Singleton (autoload) cu stare globala intre scene + puntea de input touch.
## Starea touch e aici (nu in HUD) ca sa nu legam masina de UI prin
## referinte directe — TouchControls scrie, PlayerController citeste.

# Config cursa.
var total_laps: int = 3
var ai_count: int = 3

# Puntea touch. Conventia ecranului: -1 = stanga, +1 = dreapta.
var touch_steer: float = 0.0
var touch_drift: bool = false

func reset_touch() -> void:
	touch_steer = 0.0
	touch_drift = false
