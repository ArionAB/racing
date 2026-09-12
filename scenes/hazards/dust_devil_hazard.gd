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
@export_range(0.5, 5.0, 0.1) var radius: float = 2.4
@export_range(3.0, 30.0, 0.5) var height: float = 14.0

@export_group("Ridicare")
## Cat te ridica trecerea prin vartej (m). 0 = deloc (comportamentul vechi).
##
## NU e tromba de pe Okinawa si nu are voie sa devina: aia te scoate din joc
## 1,5-2,5 s si iti garanteaza aterizarea pe sosea (LIFT 5-15 m). Aici
## ridicarea e DECOR PENTRU PEDEAPSA: 2,5 m inseamna 11,8 m/s si ~0,85 s de
## aer (g = 28), adica exact cat sa simti ca te-a luat pe sus in timp ce te
## intoarce cu 180°. Pedeapsa ramane orientarea, nu timpul.
@export_range(0.0, 6.0, 0.1) var lift_m: float = 2.5
## Cat pastrezi din viteza orizontala cand te ridica.
@export_range(0.3, 1.0, 0.01) var speed_keep: float = 0.82

var _area: Area3D
var _cone: MeshInstance3D
var _dust: CPUParticles3D
var _debris: CPUParticles3D
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
	# PALNIA, si de ce era „un con transparent" (verdictul de la volan).
	#
	# Doua greseli, amandoua de silueta: (1) varful de 5.3 m peste o zona de
	# prindere de 2.4 m facea o pana lata si plata, nu o coloana — ochiul citea
	# triunghi de hartie; (2) un singur cilindru cu alpha mic n-are DENSITATE:
	# praful adevarat e opac jos si se destrama sus.
	# Acum: varf mai stramt (x1.5), talpa mai groasa, si DOUA invelisuri
	# concentrice care se rotesc in sens contrar (vezi _cone2) — suprapunerea
	# lor da variatia care spune „se invarte".
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 1.5
	mesh.bottom_radius = radius * 0.55
	mesh.height = height
	mesh.radial_segments = 14
	mesh.rings = 3
	_cone = MeshInstance3D.new()
	_cone.mesh = mesh
	_cone.position = Vector3.UP * height * 0.5
	var mat := StandardMaterial3D.new()
	# Mai INCHISA decat savana din spate (masurat pe captura: iarba iese
	# ~(205,178,91), iar o coloana la 0.78/0.66/0.46 cadea peste ea fara
	# contrast). Praful in suspensie e cenusiu-brun, nu nisip luminat.
	mat.albedo_color = Color(0.52, 0.44, 0.34, 1.0)
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
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.0)])
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
	_build_particles()


## PRAFUL, si de ce conul singur nu ajungea.
##
## Verdictul de la volan: „arata ca un con transparent". Asa si era — un singur
## cilindru unshaded cu un gradient de alpha, adica o siluetă, nu un vartej. Ce
## face diferenta e acelasi lucru ca la tromba de pe Okinawa: `radial_accel`
## NEGATIV (trage bucatile spre axa) plus `tangential_accel` pozitiv (le da
## imbrancitura perpendiculara). Fara ele, oricate particule ai emite, iese o
## fantana. Cu ele, ochiul vede ca materialul se INVARTE.
##
## Doua straturi, la scari diferite, fiindca un singur strat citeste ca un
## obiect: nisipul jos (mult, mic, repede) e corpul coloanei, iar bucatile mari
## si lenese care urca pe langa palnie spun ca vartejul RIDICA lucruri.
func _build_particles() -> void:
	_dust = _spin_emitter(46, Palette.color(Palette.SAND_MID),
		1.6, 1.5, 9.0, 0.3, radius * 1.1)
	_debris = _spin_emitter(16, Palette.color(Palette.DRY_VEGETATION),
		2.4, 2.2, 6.5, 0.8, radius * 1.5)


func _spin_emitter(count: int, tint: Color, life: float, size: float,
		rise: float, from_y: float, r: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = count
	p.lifetime = life
	p.position = Vector3.UP * from_y
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = r
	p.direction = Vector3.UP
	p.spread = 20.0
	p.initial_velocity_min = rise * 0.5
	p.initial_velocity_max = rise
	p.radial_accel_min = -8.0
	p.radial_accel_max = -3.5
	p.tangential_accel_min = 6.0
	p.tangential_accel_max = 13.0
	# Gravitatie slaba: praful ridicat nu recade ca o piatra.
	p.gravity = Vector3(0.0, -2.5, 0.0)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var fade := Gradient.new()
	fade.set_color(0, Color(tint.r, tint.g, tint.b, 0.0))
	fade.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	fade.add_point(0.18, Color(tint.r, tint.g, tint.b, 0.72))
	fade.add_point(0.70, Color(tint.r, tint.g, tint.b, 0.45))
	p.color_ramp = fade
	var bit := SphereMesh.new()
	bit.radius = 0.30
	bit.height = 0.60
	# Rezolutia implicita a unei sfere Godot e 64x32 = 4224 de triunghiuri
	# (CLAUDE.md): cu 46 de particule ar fi 194.000 de triunghiuri de praf.
	bit.radial_segments = 5
	bit.rings = 3
	var dm := StandardMaterial3D.new()
	dm.vertex_color_use_as_albedo = true
	# Culorile proiectului sunt sRGB; fara steag ies cu ~1.5 trepte mai deschise.
	dm.vertex_color_is_srgb = true
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	bit.material = dm
	p.mesh = bit
	add_child(p)
	return p


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
		# Ridicarea: inaltimea ceruta se traduce in viteza verticala, nu invers
		# (aceeasi aritmetica ca la tromba: v = sqrt(2*g*h)). Cifra pe care o
		# reglezi e inaltimea, fiindca aia se vede.
		if lift_m > 0.0:
			car.launch(sqrt(2.0 * car.gravity * lift_m))
			car.velocity.x *= speed_keep
			car.velocity.z *= speed_keep
			# Caroseria se invarte si vizual cat e in aer: fara asta, o masina
			# ridicata drept arata ca un lift, nu ca un vartej.
			car.spin_body(dir_sign * 5.0, spin_time)
		if blind_time > 0.0:
			car.blind(blind_time)
		spins += 1
		spun.emit(car)
