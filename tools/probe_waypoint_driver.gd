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
## Aderenta laterala cu care soferul CITESTE curba care vine (m/s^2).
## 0 = stins, adica soferul de pana acum: gaz pana cand unghiul catre punctul
## urmator il sperie.
##
## Cu ea aprinsa, soferul isi masoara raza traseului din punctele din fata si
## isi limiteaza viteza la `sqrt(corner_grip * R)` — adica ridica piciorul
## INAINTE de viraj, ca un om. Nu e o indulgire pentru hazard, e opusul: fara
## ea sonda nu masoara geometria, ci ciocnirile. Masurat pe pasajul rotativ,
## cu soferul orb: un ocol de 18 m lateral a costat +3.12 s, unul de 20 m
## +2.28 s, iar unul de 23 m +5.65 s — cifra sarea dupa cum masina prindea sau
## nu parapetul, deci nu spunea nimic despre forma rampei. Masina chiar POATE
## lua acele curbe (are ~2 g); soferul orb nu incerca.
##
## Valoarea se pune sub aderenta reala a masinii, ca marja: soferul trebuie sa
## treaca, nu sa fie la limita.
var corner_grip: float = 0.0
## Cati metri de traseu in fata se citesc pentru raza. Cam distanta de franare
## de la viteza de croaziera la viteza de viraj.
var corner_lookahead: float = 22.0
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
	# Cat de departe se uita: fix (`reach`) pentru soferul orb, proportional cu
	# viteza pentru cel care citeste curbele. Urmarirea unui punct de la 4.5 m
	# e destula pe drum drept si prea scurta pe un arc de 13 m: masina intra in
	# viraj cu volanul in urma, iese pe exterior si freaca parapetul — asa a
	# ratat sonda pasajului rotativ, nu din vina geometriei. Un metru de privire
	# la fiecare doi metri pe secunda e regula clasica de urmarire pura.
	var look := reach
	if corner_grip > 0.0:
		look = clampf(car.horizontal_speed() * 0.5, reach, 9.0)
	while index < waypoints.size():
		var p := waypoints[index]
		var d := Vector2(p.x - car.global_position.x, p.z - car.global_position.z)
		if d.length() > look:
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
	var cap := target_speed
	if corner_grip > 0.0:
		cap = minf(cap, _corner_speed())
	if unstick_after > 0.0:
		if speed < 1.5:
			_stall += delta
			if _stall > unstick_after:
				_stall = 0.0
				_reverse = unstick_for
		else:
			_stall = 0.0
	if speed > cap:
		_throttle = -0.3
	elif absf(err) > brake_angle and speed > brake_floor:
		_throttle = -0.2
	else:
		_throttle = 1.0


## Viteza pe care o ingaduie curba din fata (m/s). Se ia raza cercului prin
## trei puncte de pe traseu — acum, la jumatatea privirii si la capatul ei —
## si se intoarce `sqrt(corner_grip * R)`. `INF` daca traseul e drept sau daca
## nu mai sunt puncte destule.
func _corner_speed() -> float:
	if car == null or index >= waypoints.size():
		return INF
	var a := Vector2(car.global_position.x, car.global_position.z)
	var b := _point_at(corner_lookahead * 0.5)
	var c := _point_at(corner_lookahead)
	if not b.is_finite() or not c.is_finite():
		return INF
	# Raza cercului circumscris: R = |ab|*|bc|*|ca| / (4*arie).
	var area := absf((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) * 0.5
	if area < 0.05:
		return INF # trei puncte in linie: drum drept
	var r := a.distance_to(b) * b.distance_to(c) * c.distance_to(a) / (4.0 * area)
	return sqrt(corner_grip * r)


## Punctul de pe polilinia ramasa aflat la `dist` metri in fata (2D). Intoarce
## un punct infinit daca traseul se termina inainte.
func _point_at(dist: float) -> Vector2:
	var prev := Vector2(car.global_position.x, car.global_position.z)
	var left := dist
	for i in range(index, waypoints.size()):
		var p := Vector2(waypoints[i].x, waypoints[i].z)
		var seg := prev.distance_to(p)
		if seg >= left:
			return prev.lerp(p, left / maxf(seg, 0.001))
		left -= seg
		prev = p
	return Vector2.INF


func get_steer() -> float:
	return _steer


func get_throttle() -> float:
	return _throttle


func done() -> bool:
	return index >= waypoints.size()
