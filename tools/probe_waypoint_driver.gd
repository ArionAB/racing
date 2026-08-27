extends CarController
## Sofer de sonda care urmeaza o lista de puncte, cu masina REALA.
##
## Sondele de hazard aveau pana acum un singur sofer posibil: gaz tinut si
## volan zero (`ProbeCableway.ProbeDriver`). Ajungea cat timp intrebarea era
## „poate masina sa stea pe o platforma", dar nu ajunge cand intrebarea e
## „cat costa ocolul": ocolul e un TRASEU, deci cineva trebuie sa-l conduca.
## AI-ul jocului nu poate: el urmareste axa pistei, iar rampa de serviciu a
## unui hazard nu e (inca) o ruta declarata.
##
## Nu incearca sa fie un pilot bun. Frana in viraje pe unghiul catre punctul
## urmator, si atat — daca hazardul cere mai mult decat atat ca sa fie
## trecut, aia e chiar informatia pe care o cauta sonda.

## Punctele de urmat, in coordonate globale.
var waypoints: Array[Vector3] = []
## Cat de aproape trebuie sa ajunga (orizontal) ca sa treaca la urmatorul.
var reach: float = 7.0
## Peste viteza asta ridica piciorul.
var target_speed: float = 30.0
## Cat de tare vireaza pe unitate de eroare de unghi.
var steer_gain: float = 2.2
## Peste unghiul asta franeaza in loc sa accelereze.
var brake_angle: float = 0.45
## Sub viteza asta nu mai franeaza in viraj (altfel nu mai porneste din loc).
var brake_floor: float = 9.0
## Ce face dupa ultimul punct. 1 = gaz (soferul care iese din hazard si merge
## mai departe), 0 = nimic (masina parcata din testul portii cu senzor — fara
## ea, „parcata" insemna gaz pana in decor).
var throttle_when_done: float = 1.0
## Cat sta oprita in ceva inainte sa dea inapoi (s). 0 = niciodata.
##
## Fara asta, soferul de sonda nu poate raspunde la singura intrebare care
## conteaza dupa o ciocnire: se DESCURCA masina de acolo? Blocata cu botul in
## bariere, cu punctul urmator in lateral sau in spate, formula de directie
## satura (`-local.z` se opreste la 0.5) si masina se invarte pe loc cu gazul
## in podea — asta a raportat prima rulare drept „intepenita", desi orice om
## ar fi bagat o secunda de marsarier. Marsarierul e deci parte din sofer, nu
## o indulgire a verdictului: costa timp, si timpul se vede in cifra finala.
var unstick_after: float = 0.8
## Cat tine o repriza de marsarier (s).
var unstick_for: float = 1.1

var _stall: float = 0.0
var _reverse: float = 0.0

var index: int = 0
var _steer: float = 0.0
var _throttle: float = 1.0


func update(delta: float) -> void:
	if car == null:
		return
	if _reverse > 0.0:
		_reverse -= delta
		_throttle = -1.0
		# Volanul invers fata de ce cerea inainte: iesi din bariere pe unde ai
		# intrat, nu si mai adanc.
		_steer = -_steer
		return
	while index < waypoints.size():
		var p := waypoints[index]
		var d := Vector2(p.x - car.global_position.x, p.z - car.global_position.z)
		if d.length() > reach:
			break
		index += 1
	if index >= waypoints.size():
		_steer = 0.0
		_throttle = throttle_when_done
		return
	var target := waypoints[index]
	var local := car.global_transform.basis.inverse() * (target - car.global_position)
	# Masina priveste pe -Z; +steer = stanga (vezi CarController).
	var err := atan2(-local.x, maxf(-local.z, 0.5))
	_steer = clampf(err * steer_gain, -1.0, 1.0)
	var speed := car.horizontal_speed()
	if unstick_after > 0.0:
		if speed < 1.5:
			_stall += delta
			if _stall > unstick_after:
				_stall = 0.0
				_reverse = unstick_for
		else:
			_stall = 0.0
	if speed > target_speed:
		_throttle = -0.3
	elif absf(err) > brake_angle and speed > brake_floor:
		_throttle = -0.2
	else:
		_throttle = 1.0


func get_steer() -> float:
	return _steer


func get_throttle() -> float:
	return _throttle


func done() -> bool:
	return index >= waypoints.size()
