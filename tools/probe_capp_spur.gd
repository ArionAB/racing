extends Node
## PINTENII (`far_wall`): talpa lor sta pe teren, sau atarna peste vale?
##
## Sonda de cadru (ProbeCappSlab) a numit vinovatul lespezii plutitoare de la
## fractia 0.235: `Faleza pinten TaieturaSerpentinei`, AABB y=18.3..42.6, la 85 m
## de ochi. Terenul de sub el e la ~26-36 m, deci talpa masei e cu metri SUB
## cota locului — de aia se vede cer pe sub ea.
##
## Suspectul din cod e `_far_column` cu `far_bank`: talpa se ia
## `minf(surface_y(base), surface_y(toe))`, iar `toe` sta cu `far_depth_m` mai
## departe, adica DEJA peste rapa. Cand malul coboara, minimul apuca fundul vaii
## si trage talpa acolo, desi masa sta pe creasta.
##
## Sonda tipareste, pentru fiecare pas: cota bazei, cota degetului, ce s-a ales
## si cat de mult atarna sub teren.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var faces: Array[CliffFace] = []
	_collect(_track, faces)
	var sampler := _track._sampler as TrackSideSampler
	print("=== PINTENI: mesh-ul construit fata de teren ===")
	var root := _track.find_child("CliffFaces", true, false)
	for c in root.get_children():
		var mi := c as MeshInstance3D
		if mi == null or not str(mi.name).begins_with("Faleza pinten"):
			continue
		var arr := (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		# TALPA fiecarei coloane (vertexul cel mai de jos dintr-un grup), fata de
		# terenul de sub ea. Ce cautam e AER SUB masa: talpa DEASUPRA solului.
		# Vertecsii ingropati sunt normali (foot_bite ii infige dinadins).
		var worst := 0.0
		var worst_p := Vector3.ZERO
		var n_air := 0
		# Se grupeaza pe coloane de ~1 m in plan, si se ia minimul din fiecare.
		var feet: Dictionary = {}
		for v: Vector3 in vs:
			var key := "%d_%d" % [int(round(v.x)), int(round(v.z))]
			if not feet.has(key) or v.y < float(feet[key]):
				feet[key] = v.y
		for key: String in feet:
			var parts := key.split("_")
			var fx := float(parts[0])
			var fz := float(parts[1])
			var fy := float(feet[key])
			var gy: float = _track._terrain_mesh_y(fx, fz)
			var air := fy - gy
			if air > 1.0:
				n_air += 1
			if air > worst:
				worst = air
				worst_p = Vector3(fx, fy, fz)
		# La punctul cel mai suspect: TOATE cotele din acea coloana, ca sa se
		# vada daca e o talpa care pluteste sau doar randuri de fata aflate
		# normal deasupra solului.
		if worst > 1.0:
			var col: Array = []
			for v: Vector3 in vs:
				if absf(v.x - worst_p.x) < 1.5 and absf(v.z - worst_p.z) < 1.5:
					col.append(v.y)
			col.sort()
			var gy2: float = _track._terrain_mesh_y(worst_p.x, worst_p.z)
			var txt := PackedStringArray()
			for yv: float in col:
				txt.append("%.1f" % yv)
			print("     teren %.1f | cote in coloana: %s" % [gy2, " ".join(txt)])
		print("  %s: %d vertecsi, %d talpi cu AER sub ele (>1 m), cel mai sus %.1f m la (%.0f,%.0f,%.0f)"
			% [mi.name, feet.size(), n_air, worst, worst_p.x, worst_p.y, worst_p.z])
	get_tree().quit(0)


static func _collect(node: Node, out: Array[CliffFace]) -> void:
	for child in node.get_children():
		if child is CliffFace:
			out.append(child as CliffFace)
		_collect(child, out)
