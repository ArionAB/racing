class_name HazardThrow
extends RefCounted
## Cum ARUNCA un hazard o masina pe fizica intreaga — si de ce `apply_sweep`
## nu poate s-o faca.
##
## [b]Lipsa gasita de critic (runda 1)[/b]: monorailul si macaraua isi
## adaugau componenta verticala cu `Car.apply_sweep(... + Vector3.UP * lift)`,
## iar cifra masurata era ca `throw_lift = 7.5` producea o urcare de 0.45 m in
## loc de 2.87 — adica doua @export-uri MOARTE din patru hazarde. Motivul e
## scris chiar in `Car.launch`: pe sol, componenta verticala adunata se pierde.
## Pe [RigidBody3D] cu suspensie pe raycast se pierde de doua ori:
##
##  1. amortizorul (`-c * spring_vel`, car.gd) lucreaza cat raza rotii mai
##     atinge solul si mananca exact viteza pe care tocmai ai adunat-o;
##  2. corpul solid al hazardului (garnitura, prefabricatul) e inca peste
##     masina, iar solverul rezolva patrunderea pe axa cea mai scurta —
##     lateral, la 30+ m/s. Asa a masurat criticul o masina „aruncata" 62.75 m
##     in afara lumii, sub cota soselei, unde a ramas nemiscata: nu zbor, ci
##     EJECTARE.
##
## De aceea aruncarea are trei parti, si toate trei sunt necesare:
##
##  - [b]orizontala se SCRIE, nu se aduna[/b]. Cine te loveste are masa mult
##     mai mare decat tine, deci viteza de dupa lovitura e a LUI, nu suma. O
##     adunare peste 30 m/s de mers da rezultante de 40+ m/s, adica tocmai
##     zborul in afara hartii;
##  - [b]verticala trece prin `Car.launch`[/b], care SETEAZA `velocity.y`.
##     Se cere in METRI (inaltimea la care vrei sa ajunga), nu in m/s: cifra
##     din inspector devine astfel chiar lucrul pe care sonda il masoara;
##  - [b]corpul care a lovit primeste o exceptie de coliziune[/b] cat tine
##     zborul. Fara ea, primul cadru de dupa lansare readuce masina in
##     acelasi contact si solverul o striveste inapoi la sol (masurat:
##     vy 7.02 -> 0 in 0.13 s).
##
## Nu e o indulgire: pedeapsa ramane intreaga (strivire, spin, viteza taiata,
## secundele de zbor). Doar ca e o pedeapsa pe care hazardul o DECIDE, nu una
## pe care o improvizeaza solverul.


## Arunca `car`: `horizontal` e viteza orizontala de DUPA lovitura (absoluta),
## `rise` inaltimea zborului in metri, `clear_seconds` cat timp `source` nu mai
## are voie sa atinga masina.
static func throw(car: Car, source: CollisionObject3D, horizontal: Vector3,
		rise: float, clear_seconds: float) -> void:
	if car == null or not is_instance_valid(car):
		return
	car.velocity = Vector3(horizontal.x, car.velocity.y, horizontal.z)
	if rise > 0.001:
		# v = sqrt(2*g*h) cu gravitatia MASINII (28 m/s2, nu 9.8): tot ce se
		# masoara in metri pe pista asta se masoara cu ea. Acelasi drum ca
		# `TyphoonHazard`, care cere si el lift-ul in metri.
		car.launch(sqrt(2.0 * car.gravity * rise))
	clear(car, source, clear_seconds)


## Exceptia de coliziune, cu ceasul ei. Publica fiindca un hazard poate avea
## nevoie sa deschida drumul INAINTE de lovitura (macaraua isi prinde masina
## cu o zona mai grasa decat sarcina, tocmai ca prefabricatul sa nu apuce sa
## fie un zid).
static func clear(car: Car, source: CollisionObject3D, seconds: float) -> void:
	if car == null or source == null or seconds <= 0.0:
		return
	if not is_instance_valid(car) or not is_instance_valid(source):
		return
	var tree := car.get_tree()
	if tree == null:
		return
	if car.get_collision_exceptions().has(source):
		return
	car.add_collision_exception_with(source)
	tree.create_timer(seconds, false).timeout.connect(
		func() -> void:
			if is_instance_valid(car) and is_instance_valid(source):
				car.remove_collision_exception_with(source))
