extends Node
## Observa pozitia jucatorului si anunta schimbarile STABILE (docs/feel_checklist.md:
## position-change, partea vizuala).
##
## De ce un nod separat: clasamentul din `Race._update_positions` e recalculat in
## fiecare tick din progresul brut, deci doua masini care se depasesc de-a
## valma (alaturi, in viraj) schimba pozitia de zece ori pe secunda. Un popup la
## fiecare schimbare ar sclipi si ar minti ("ai depasit" cand abia ai atins linia).
## Aici o pozitie trebuie TINUTA `hold_s` secunde ca sa conteze.
##
## Reguli:
##   - Pozitia de referinta (`stable`) e ultima anuntata. O valoare diferita de ea
##     devine "candidat"; daca isi schimba valoarea, ceasul candidatului reporneste.
##   - Candidatul tinut `hold_s` => `announced(noua, veche)`, iar `stable` devine noua.
##   - Daca candidatul se intoarce la `stable` inainte de hold, nu se anunta nimic.
##   - Coalescare: 4 -> 3 -> 2 in sub `hold_s` ajunge UN anunt 4 -> 2.
##   - Dupa un anunt, `cooldown_s` pana la urmatorul (un schimb dus-intors nu
##     trebuie sa scoata doua popup-uri la rand).
##   - `active == false` (numaratoare, dupa final, repunere) reseteaza totul pe
##     pozitia curenta: nimic nu se anunta la reintrare.
##
## Fara sunet: stinger-ul vine separat si se leaga pe semnalul `announced`.

## Anuntul: pozitia noua, cea veche (mai mic = mai bine).
signal announced(new_pos: int, old_pos: int)

## Cat trebuie tinuta o pozitie noua ca sa fie anuntata (s).
@export var hold_s: float = 0.4
## Pauza minima dintre doua anunturi (s).
@export var cooldown_s: float = 0.8

var stable: int = 0
var announce_count: int = 0

var _candidate: int = 0
var _held: float = 0.0
var _cooldown: float = 0.0


## Un singur apel pe tick de fizica. `active` = cursa ruleaza si jucatorul nu a
## terminat.
func observe(pos: int, delta: float, active: bool) -> void:
	if not active or pos <= 0:
		reset(pos)
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if stable <= 0:
		stable = pos
		_candidate = pos
		return
	if pos == stable:
		_candidate = pos
		_held = 0.0
		return
	if pos != _candidate:
		_candidate = pos
		_held = 0.0
		return
	_held += delta
	if _held >= hold_s and _cooldown <= 0.0:
		var old := stable
		stable = pos
		_held = 0.0
		_cooldown = cooldown_s
		announce_count += 1
		announced.emit(pos, old)


## Pozitia de referinta devine `pos` fara anunt.
func reset(pos: int = 0) -> void:
	stable = pos
	_candidate = pos
	_held = 0.0
