class_name CarController
extends Node
## Interfata dintre "creier" si masina (pattern-ul din racing 2D): Car citeste
## comenzile de aici fara sa stie daca vin de la touch, tastatura sau AI.

var car: Car

func setup(owner_car: Car) -> void:
	car = owner_car

## Apelat de masina la fiecare tick de fizica, inainte de citirea comenzilor.
func update(_delta: float) -> void:
	pass

## +1 = stanga, -1 = dreapta (conventia rotate_y: pozitiv = viraj la stanga).
func get_steer() -> float:
	return 0.0

## -1 frana/marsarier .. +1 acceleratie.
func get_throttle() -> float:
	return 1.0 # auto-accelerate: standardul mobile

func is_drift_pressed() -> bool:
	return false
