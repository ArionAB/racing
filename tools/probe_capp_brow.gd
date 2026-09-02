extends Node
## Ce se CONSTRUIESTE efectiv pe cornisa, si cat de sus ajunge fata de ochi.
##
## Sonda de sectiune a aratat ca terenul CHIAR cade langa drum. Deci daca in
## poza nu se vede muchie, intrebarea nu mai e „s-a sapat?", ci „ce panze exista
## si unde sunt ele fata de linia privirii?". Asta masoara sonda: pentru fiecare
## nod CliffFace se tipareste mesh-ul rezultat (vertecsi, AABB) si unghiul sub
## care se vede din ochiul soferului. Un perete la -30 grade nu intra in cadru
## oricat ar fi de mare — vezi nota `far_eye_rise_m` din cliff_face.gd.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const EYE_M: float = 1.5
const FRACS: Array[float] = [0.20, 0.26, 0.32, 0.38]

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== PANZE DE FALEZA (Track13) ===")
	var root := _track.find_child("CliffFaces", true, false)
	if root == null:
		print("  NICIUN nod CliffFaces — nu s-a construit nimic")
		get_tree().quit(0)
		return
	for c in root.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			print("  %s: FARA mesh" % c.name)
			continue
		var aabb := mi.mesh.get_aabb()
		print("  %s: %d vertecsi, AABB pos=(%.0f,%.0f,%.0f) size=(%.0f,%.0f,%.0f)"
			% [mi.name, mi.mesh.surface_get_array_count() if false else _vcount(mi),
			aabb.position.x, aabb.position.y, aabb.position.z,
			aabb.size.x, aabb.size.y, aabb.size.z])
	print("=== UNGHIUL BUZEI DIN OCHIUL SOFERULUI ===")
	for f in FRACS:
		_eye(f)
	get_tree().quit(0)


func _vcount(mi: MeshInstance3D) -> int:
	var arr := (mi.mesh as ArrayMesh).surface_get_arrays(0)
	return (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()


## Sub ce unghi vede soferul buza exterioara, si ce e efectiv acolo.
func _eye(frac: float) -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(frac * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var side := route.side_at(idx)
	var hw := _track.width_at(_track.frac_at(idx))
	var eye := c + Vector3.UP * EYE_M
	var sampler := _track._sampler as TrackSideSampler
	# Cea mai INALTA cota vazuta dincolo de buza, pe primii 40 m: daca nimic nu
	# urca peste linia ochiului, exteriorul nu are silueta.
	var best := -1e9
	var best_d := 0.0
	var d := hw
	while d <= hw + 40.0:
		var p: Vector3 = c + side * d
		var y := sampler.ground_y(p.x, p.z)
		var ang := rad_to_deg(atan2(y - eye.y, d))
		if ang > best:
			best = ang
			best_d = d
		d += 1.0
	print("  frac %.2f: buza la %.1f m, cel mai inalt punct exterior %+.1f grade (la %.0f m)"
		% [frac, hw, best, best_d])
