@tool # vizibil si in preview-ul din editor (fara simulare fizica acolo)
class_name BowlingPin
extends RigidBody3D
## Popica de jucarie — delimitator de pista FIZIC: sta cuminte (adormita)
## pana o lovesti, apoi zboara. RigidBody adormit costa aproape nimic.

var model_scene: PackedScene
var model_scale: float = 0.53

func _ready() -> void:
	add_to_group("pins")
	mass = 0.4
	sleeping = true
	# Cotele de coliziune se MASOARA din model, nu se scriu de mana. Erau
	# `radius 0.3 / height 1.55 / centru 0.78`, potrivite pe popica de 3.00 m
	# inmultita cu 0.53 — corecte azi, dar mute daca modelul se schimba. Prop-ul
	# asta e primul care se inlocuieste din lotul de assets (marker_post), si e
	# instantiat de pana la 110 ori: o coliziune nepotrivita se vede peste tot.
	var aabb := AABB(Vector3(-0.3, 0.0, -0.3), Vector3(0.6, 1.55, 0.6))
	if model_scene != null:
		var model := model_scene.instantiate() as Node3D
		model.scale = Vector3.ONE * model_scale
		add_child(model)
		var measured := Track.model_aabb(model)
		if measured.size.y > 0.01:
			aabb = measured
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	# Raza din amprenta, nu din diagonala: popica e mai inalta decat lata si un
	# cilindru care sa cuprinda coltul ar fi un obstacol mai gras decat vizualul.
	cyl.radius = maxf(aabb.size.x, aabb.size.z) * 0.5
	cyl.height = aabb.size.y
	shape.shape = cyl
	shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
	add_child(shape)
