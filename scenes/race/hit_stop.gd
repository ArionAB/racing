extends Node
## Hit-stop: inghetare scurta a lumii la o izbitura mare, ca creierul sa
## inregistreze greutatea ("cel mai ieftin truc de greutate din jocuri").
##
## Mecanismul e `Engine.time_scale` coborat la `frozen_scale`. Durata se
## masoara in timp REAL: cat tine inghetul, `delta` din `_process` e deja
## inmultit cu time_scale, deci timpul real al cadrului e `delta / time_scale`
## (in jocul real e timpul de perete; sub `--fixed-fps` e chiar 1/fps, deci
## sondele sunt deterministe). NU numaram cadre de fizica: la 0.05x fizica
## face ~3 pasi pe secunda si inghetul n-ar mai iesi niciodata.
##
## IMPOSIBIL SA RAMAI BLOCAT, din patru directii:
##   1. durata e plafonata la MAX_SECONDS, oricat ceri;
##   2. nodul ruleaza si cu arborele pe pauza (PROCESS_MODE_ALWAYS) si, daca
##      vede pauza, restaureaza pe loc;
##   3. `_exit_tree` restaureaza 1.0 (schimbare de scena, cursa inchisa,
##      nodul sters);
##   4. `cancel()` public, pentru repunere / aruncare / final de cursa.
## Restaurarea scrie EXACT 1.0, nu "valoarea veche": nimeni altcineva din
## joc nu atinge time_scale.

## Plafon absolut al unui inghet (secunde reale), peste orice cere apelantul.
const MAX_SECONDS: float = 0.15

## Viteza lumii cat tine inghetul. Nu 0: un 0 exact opreste si `_process`-ul
## celorlalte noduri intr-un mod greu de depanat, iar o lume la 5% se vede
## inca "tremurand" — exact senzatia dorita.
@export var frozen_scale: float = 0.05
## Timp real minim intre doua inghetari (s), masurat de la inceputul primei.
## Un cuib de ciocniri nu inlantuie inghetari.
@export var cooldown: float = 0.6

var _left: float = 0.0
var _cool: float = 0.0
var _active: bool = false
## time_scale cu care a fost calculat `delta` al cadrului curent: cel de la
## sfarsitul cadrului trecut. NU `Engine.time_scale` de acum: `trigger` se cheama
## din fizica, in mijlocul unui cadru al carui delta e deja calculat cu scara
## veche — impartit la 0.05, primul cadru ar numara 20x prea mult si inghetul
## s-ar termina pe loc.
var _delta_scale: float = 1.0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_frozen() -> bool:
	return _active


## Cere un inghet de `seconds` reale. Intoarce false daca e refuzat (in
## cooldown, deja inghetat, pauza, nod in afara arborelui).
func trigger(seconds: float) -> bool:
	if _active or _cool > 0.0 or seconds <= 0.0:
		return false
	if not is_inside_tree() or get_tree().paused:
		return false
	_left = minf(seconds, MAX_SECONDS)
	_cool = maxf(cooldown, _left)
	_active = true
	Engine.time_scale = frozen_scale
	return true


## Opreste inghetul acum si readuce lumea la 1.0 exact. Sigur de chemat oricand.
func cancel() -> void:
	if _active:
		_active = false
		_left = 0.0
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	# Timp real: in inghet delta e scalat, deci il desfacem.
	var real := delta / _delta_scale
	_cool = maxf(_cool - real, 0.0)
	if _active:
		if get_tree().paused:
			cancel()
		else:
			_left -= real
			if _left <= 0.0:
				cancel()
	_delta_scale = maxf(Engine.time_scale, 0.001)


func _exit_tree() -> void:
	# Doar daca noi am inghetat: sa nu calcam un time_scale setat de altcineva
	# (ex. o sonda). Cand suntem activi, e al nostru.
	if _active:
		cancel()
