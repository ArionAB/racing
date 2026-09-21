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
##
## Export, ca zona sa se poata declara si direct in scena pistei (cuva
## craterului de pe Stromboli), nu doar construita din cod.
@export var backoff_m: float = 14.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var car := body as Car
	if car != null:
		# Runda 3 (Fiordland), diagnostic optional (AI_UNSTICK_TRACE=1) —
		# simetric cu cel din AIController._begin_unstick(): semnalul
		# `respawned` nu spune CINE a chemat repunerea (zona vs paznicul de
		# progres al AI-ului), iar distinctia asta era exact intrebarea de la
		# runda 3 punctul 2 pentru repunerile de langa semafor.
		if OS.get_environment("AI_UNSTICK_TRACE") == "1":
			print("[zone-respawn] %s zona=%s pos=(%.0f,%.0f,%.0f)" % [
				car.pilot_name, name, car.global_position.x,
				car.global_position.y, car.global_position.z])
		car.respawn(backoff_m)
