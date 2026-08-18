@tool
class_name IceSlabHazard
extends Node3D
## PLACA DE GHEATA LIBERA (Baikal, docs/track_briefs/baikal.md §3): o placa
## desprinsa din camp, care se BALANSEAZA sub masini ca un basculant.
##
## Nu e o capcana cu ceas, e un obiect fizic: placa e articulata pe axa ei
## transversala (mijlocul, in lungul drumului) si se inclina proportional cu
## MOMENTUL incarcaturii — masa fiecarei masini de pe ea inmultita cu cat de
## departe e de mijloc. Intri pe capatul dinspre tine si el se lasa (capatul
## opus urca, o rampa mica); treci de mijloc si placa basculeaza inainte, sub
## tine, apoi se aseaza la loc dupa ce ai coborat. Cu doua masini pe ea nimic
## nu mai e previzibil, si asta e ce vrem: haosul din contact, nu din ceas.
##
## Cifrele care conteaza:
##   - LENGTH 14 m, MAX_TILT 6 grade: capatul coboara ~0.7 m. Destul cat sa se
##     vada din chase cam si sa arunce masina putin la iesire; nu destul cat sa
##     opreasca pe cineva. Placa e cinstita: o vezi de departe (rama de apa
##     neagra in jurul ei) si o simti sub roti inainte sa faca ceva.
##   - arcul e MOALE (STIFF 30, DAMP 7): raspunsul vine intr-un sfert de
##     secunda, nu ca o trapa. La 30 m/s traversezi placa in 0.5 s, deci
##     basculeaza EXACT cand esti pe mijloc.
##
## AnimatableBody3D cu sync_to_physics (ca traveea podului si trenul):
## masina de pe ea e purtata, nu strapunsa. Transformarea se scrie INTREAGA,
## o singura data pe cadru (nota despre Jolt: pozitie + rotatie scrise separat
## ingheata corpul in tacere).

const LENGTH: float = 14.0
const THICKNESS: float = 0.5
const MAX_TILT_DEG: float = 6.0
## Momentul (kg*m) la care se atinge inclinarea maxima: o masina de referinta
## (100 kg) la 4 m de mijloc.
const FULL_TORQUE: float = 100.0 * 4.0
const STIFF: float = 30.0
const DAMP: float = 7.0
## Cat sta fata de sus a placii peste cota drumului cand e orizontala.
const LIP: float = 0.05
## Rama de apa neagra din jurul placii (metri in afara conturului).
const RIM: float = 1.4

## Jumatatea latimii soselei — placa e cu 1 m mai lata pe fiecare parte.
var road_half_width: float = 7.0

var _plate: AnimatableBody3D
var _area: Area3D
var _angle: float = 0.0
var _ang_vel: float = 0.0


func _ready() -> void:
	_build()


func plate_width() -> float:
	return road_half_width * 2.0 + 2.0


func _build() -> void:
	var w := plate_width()
	# Rama de apa: un dreptunghi intunecat SUB placa, putin mai mare decat ea,
	# asezat cu un deget PESTE cota drumului (soseaua de gheata trece pe sub
	# placa; o rama pusa sub ea ar fi ingropata si nu s-ar vedea — asa a fost in
	# prima versiune, la -0.4). E semnalul de departe: o placa la fel de turcoaz
	# ca restul nu ar spune nimic pana nu ar fi prea tarziu.
	var water := MeshInstance3D.new()
	water.name = "Rim"
	var wm := PlaneMesh.new()
	wm.size = Vector2(w + RIM * 2.0, LENGTH + RIM * 2.0)
	water.mesh = wm
	var mat_water := StandardMaterial3D.new()
	mat_water.albedo_color = Color(0.05, 0.09, 0.12)
	mat_water.roughness = 0.6
	mat_water.metallic_specular = 0.3
	water.material_override = mat_water
	water.position = Vector3(0.0, 0.02, 0.0)
	add_child(water)

	_plate = AnimatableBody3D.new()
	_plate.name = "Plate"
	_plate.sync_to_physics = true
	add_child(_plate)
	var box := BoxMesh.new()
	box.size = Vector3(w, THICKNESS, LENGTH)
	var mi := MeshInstance3D.new()
	mi.mesh = box
	var mat_ice := StandardMaterial3D.new()
	# Mai palida decat banda de gheata (se citeste ca alta bucata) si MATA:
	# cu luciu, soarele jos al Baikalului punea o pata alba pe toata placa.
	mat_ice.albedo_color = Color(0.80, 0.92, 0.94)
	mat_ice.roughness = 0.75
	mat_ice.metallic_specular = 0.2
	mi.material_override = mat_ice
	_plate.add_child(mi)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	_plate.add_child(col)
	# Fata de sus la LIP peste drum, cand e orizontala.
	_plate.transform = Transform3D(Basis.IDENTITY,
		Vector3(0.0, LIP - THICKNESS * 0.5, 0.0))

	# Zona care numara masinile de pe placa (si unde sunt fata de mijloc).
	_area = Area3D.new()
	_area.name = "Load"
	_area.monitoring = true
	_area.monitorable = false
	var acol := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(w, 3.0, LENGTH)
	acol.shape = abox
	_area.add_child(acol)
	_area.position = Vector3(0.0, 1.5 + LIP, 0.0)
	add_child(_area)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _plate == null:
		return
	var torque := 0.0
	for body in _area.get_overlapping_bodies():
		var car := body as Car
		if car == null:
			continue
		var local := to_local(car.global_position)
		# -Z local = sensul de mers (conventia proiectului), deci "inainte de
		# mijloc" e z negativ. Momentul pozitiv = greutate in fata mijlocului.
		var along := -local.z
		torque += car.mass * clampf(along, -LENGTH * 0.5, LENGTH * 0.5)
	var target := clampf(torque / FULL_TORQUE, -1.0, 1.0) * deg_to_rad(MAX_TILT_DEG)
	_ang_vel += (STIFF * (target - _angle) - DAMP * _ang_vel) * delta
	_angle += _ang_vel * delta
	# Rotatie in jurul lui X local. Semnul e ales ca unghiul pozitiv sa
	# COBOARE capatul din fata (-Z): rotatia cu +a in jurul lui X duce -Z in
	# (0, +sin a, -cos a), adica il RIDICA, de aceea aici e -a. Verificat in
	# tools/ProbeIceSlab, nu doar din semne.
	_plate.transform = Transform3D(Basis(Vector3.RIGHT, -_angle),
		Vector3(0.0, LIP - THICKNESS * 0.5, 0.0))


## Unghiul curent, in grade (pozitiv = capatul din fata jos). Pentru sonde.
func tilt_deg() -> float:
	return rad_to_deg(_angle)
