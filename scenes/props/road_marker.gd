@tool # vizibil si in preview-ul din editor (fara simulare fizica acolo)
class_name RoadMarker
extends RigidBody3D
## Stalp de marcaj la marginea drumului — delimitator FIZIC: sta cuminte
## (adormit) pana il lovesti, apoi zboara. RigidBody adormit costa aproape nimic.
##
## Se numea BowlingPin si chiar era o popica de bowling, ramasita din tema
## abandonata "jucarii in lada de nisip". In canionul de desert n-avea ce cauta,
## si era si cel mai scump prop din joc: 196 de triunghiuri × 110 instante =
## 21.560, adica 31% din toata pista Dunele. Stalpul face 76.
##
## Modelul vine gata ales (o varianta scoasa din marker_post.glb), nu ca scena:
## fisierul are trei siluete diferite si vrem sa alternam intre ele, altfel 110
## copii identice se citesc ca un gard.

## Nodul vizual, pregatit de apelant. Se pune INAINTE de add_child.
var model: Node3D
## Modelele noi sunt construite la scara lumii; a ramas pentru assets vechi.
var model_scale: float = 1.0

func _ready() -> void:
	add_to_group("markers")
	mass = 0.4
	sleeping = true
	# Cotele de coliziune se MASOARA din model, nu se scriu de mana. Erau
	# `radius 0.3 / height 1.55 / centru 0.78`, potrivite pe popica de 3.00 m
	# inmultita cu 0.53 — corecte atunci, mute la prima schimbare de model.
	var aabb := AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 1.2, 0.2))
	if model != null:
		model.scale = Vector3.ONE * model_scale
		add_child(model)
		var measured := Track.model_aabb(model)
		if measured.size.y > 0.01:
			aabb = measured
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	# Raza din amprenta, nu din diagonala: stalpul e mult mai inalt decat lat si
	# un cilindru care sa cuprinda coltul ar fi un obstacol mai gras decat
	# vizualul. Conteaza mai ales la varianta inclinata, care are amprenta de
	# 0.18 m fata de 0.07 la cea dreapta.
	cyl.radius = maxf(aabb.size.x, aabb.size.z) * 0.5
	cyl.height = aabb.size.y
	shape.shape = cyl
	shape.position = Vector3.UP * (aabb.position.y + aabb.size.y * 0.5)
	add_child(shape)
