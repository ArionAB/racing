class_name DustDevilHazard
extends Node3D
## VARTEJUL DE PRAF (Serengeti, docs/track_briefs/serengeti.md §3).
##
## Clasa de hazard „sabotaj de control" din ref_notes/sisteme.md §3 — cea pe
## care Ignition o facea cu bolovanii (comenzi inversate) si pe care nicio
## pista de-a noastra n-o avea. Aici: o coloana de praf care rataceste pe un
## camp deschis; cine trece prin ea e ROTIT cu 180° in 0,8 s. Nu-ti ia
## viteza, nu te ridica (asta e TyphoonHazard, global, pe Okinawa): iti ia
## orientarea. Mergi mai departe cu spatele, cu viteza intreaga, si trebuie
## sa te aduni singur — singura pedeapsa care nu se absoarbe prin skill de
## condus, doar prin adaptare.
##
## Cinstit fiindca se vede de departe (12 m de praf pe camp gol, mereu in
## frustum) si fiindca rataceste LENT (4 m/s) pe o figura Lissajous: nu te
## vaneaza, doar e in drum.

signal spun(car: Car)

@export_group("Ratacire")
## Semiaxele figurii Lissajous (m), pe X si pe Z ale nodului.
@export var amplitude: Vector2 = Vector2(15.0, 30.0)
## Frecventele (Hz) pe cele doua axe; raportul lor iregular = nu se repeta vizibil.
@export var frequency: Vector2 = Vector2(0.041, 0.027)
@export_range(0.0, TAU, 0.01) var phase_z: float = 1.2

@export_group("Sabotaj")
@export_range(30.0, 360.0, 5.0) var spin_deg: float = 180.0
@export_range(0.2, 3.0, 0.05) var spin_time: float = 0.8
## Praf pe ecran (Car.blind), secunde.
@export_range(0.0, 2.0, 0.05) var blind_time: float = 0.6
@export_range(0.5, 10.0, 0.1) var cooldown: float = 3.0

@export_group("Forma")
@export_range(0.5, 5.0, 0.1) var radius: float = 1.5
@export_range(3.0, 30.0, 0.5) var height: float = 12.0

var _area: Area3D
var _cone: MeshInstance3D
var _time: float = 0.0
var _origin: Vector3
var _cooldown: Dictionary = {}
var spins: int = 0


func _ready() -> void:
	_origin = global_position
	_area = Area3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position = Vector3.UP * height * 0.5
	_area.add_child(shape)
	add_child(_area)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 2.2
	mesh.bottom_radius = radius * 0.4
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 3
	_cone = MeshInstance3D.new()
	_cone.mesh = mesh
	_cone.position = Vector3.UP * height * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.66, 0.46, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# ALPHA PE INALTIME, nu alpha uniform. Cu 0.55 peste tot, conul are o
	# MUCHIE de poligon la fel de tare ca un obiect solid: pe captura de joc
	# (G_r3_context.png) vartejul citea ca un triunghi de hartie decupat, nu ca
	# o coloana de praf — aceeasi capcana ca la praful de sub roti (memoria
	# `particule-muchia-nu-numarul`): ce se vede nu e numarul, e marginea.
	# Gradientul face praful DES jos (unde ridica nisipul) si il stinge complet
	# sus, deci silueta nu se mai termina intr-o linie dreapta.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.72), Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = 64
	tex.fill_from = Vector2(0.0, 1.0)
	tex.fill_to = Vector2(0.0, 0.0)
	mat.albedo_texture = tex
	_cone.material_override = mat
	_cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cone)


func _physics_process(delta: float) -> void:
	_time += delta
	for key: Variant in _cooldown.keys():
		_cooldown[key] = maxf(float(_cooldown[key]) - delta, 0.0)
	global_position = _origin + Vector3(
		amplitude.x * sin(TAU * frequency.x * _time), 0.0,
		amplitude.y * sin(TAU * frequency.y * _time + phase_z))
	_cone.rotate_y(delta * 6.0)
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null or float(_cooldown.get(car, 0.0)) > 0.0:
			continue
		_cooldown[car] = cooldown
		var dir_sign := 1.0 if (spins % 2 == 0) else -1.0
		car.apply_yaw_kick(dir_sign * deg_to_rad(spin_deg) / spin_time, spin_time)
		if blind_time > 0.0:
			car.blind(blind_time)
		spins += 1
		spun.emit(car)
