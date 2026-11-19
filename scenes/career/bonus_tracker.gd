class_name BonusTracker
extends Node
## Bonusul carierei, acelasi pe fiecare pista: „NO RETRY" (decizia
## dezvoltatorului, 19 nov 2026). +1 daca termini cursa de cariera fara sa fii
## ARUNCAT din masina si fara sa ceri o repunere (butonul RESET din HUD sau
## actiunea `reset`).
##
## Ce NU costa bonusul: izbiturile de perete si de masini fara aruncare,
## hazardele (aruncat, strivit, stropit, ars) si orice repunere AUTOMATA pe
## care jucatorul n-a cerut-o (cazut de pe harta, masina rasturnata sau
## impotmolita, ceasul de off-road, hazardele cu repunerea lor). Toate se
## termina in `Car.respawned`, de aceea regula NU sta pe `respawned`: sta pe
## `Car.ejected` (ascultat aici) si pe `note_reset()`, chemat de `Race` doar
## cand o apasare chiar a pornit o repunere.
##
## Copil al lui `Race`: moare cu cursa, abonarea la `ejected` cu el.

## Prima pierdere (o singura data pe cursa). `cause` = &"eject" sau &"reset".
signal lost_changed(cause: StringName)

var player: Car
var lost: bool = false
## Ce a costat bonusul (&"" cat timp e intreg).
var lost_cause: StringName = &""
## Pierderea inca neanuntata pe ecran; `take_announcement` o consuma.
var _unannounced: bool = false


## Abonarea la `ejected` se face AICI, la setup — iar `Race` cheama setup-ul
## inainte sa-si lege propriul handler de `ejected`. Semnalele Godot suna in
## ordinea conectarii, deci cand handler-ul cursei scrie „EJECTED!", pierderea
## e deja notata si mesajul o poate spune in acelasi cadru.
func setup(p_player: Car) -> void:
	player = p_player
	player.ejected.connect(_on_ejected)


## Race: o apasare pe RESET / tasta R a pornit chiar acum o repunere.
func note_reset() -> void:
	_lose(&"reset")


## true = bonusul ramane (nicio aruncare, nicio repunere ceruta).
func evaluate() -> bool:
	return not lost


## true o singura data, dupa prima pierdere: cine o anunta pe ecran o ia.
## Pierderile de dupa (a doua aruncare, alt RESET) nu mai anunta nimic.
func take_announcement() -> bool:
	if not _unannounced:
		return false
	_unannounced = false
	return true


func _on_ejected(_car: Car, _ragdoll: Node3D) -> void:
	_lose(&"eject")


func _lose(cause: StringName) -> void:
	if lost:
		return
	lost = true
	lost_cause = cause
	_unannounced = true
	lost_changed.emit(cause)
