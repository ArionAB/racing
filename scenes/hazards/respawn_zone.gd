@tool
class_name RespawnZone
extends Area3D
## Plasa de siguranta a zonei de fly-off: volumul de nisip de SUB nivelul
## soselei, in jurul locului unde ateriseaza saritura. Cine intra aici a
## ratat aterizarea — il repunem pe ultimul checkpoint valid, cu spatiu de
## elan in fata. Pierzi timp, nu cursa: nimic nu se blocheaza.
##
## Plafonul volumului e calculat de generatorul de pista din cea mai joasa
## bucata de sosea din amprenta, ca sa nu se poata declansa din greseala pe
## cineva care conduce normal.

## Cati metri INAINTE de checkpoint e repusa masina (spatiu de elan).
var backoff_m: float = 14.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var car := body as Car
	if car != null:
		car.respawn(backoff_m)
