extends Node
## Unde sta FIECARE panza fata de axul drumului, pe rulaj lateral cu semn.
##
## Capturile arata un perete in banda pe STANGA, desi toate nodurile in cauza au
## side=+1 si masuratoarea spune ca +1 e dreapta. Deci intrebarea nu mai e "ce
## inseamna side", ci "unde a ajuns efectiv fiecare panza". Sonda proiecteaza
## vertecsii fiecarui mesh pe versorul lateral al celui mai apropiat punct de
## traseu si tipareste distributia rulajului cu semn: negativ = stanga.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var root := _track.find_child("CliffFaces", true, false)
	print("=== RULAJ LATERAL CU SEMN PE PANZE (negativ = stanga) ===")
	var route := _track.route_at(0)
	var n := route.count()
	for ch in root.get_children():
		var mi := ch as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var arrs: Array = (mi.mesh as ArrayMesh).surface_get_arrays(0)
		var vs: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
		var lo := 1e9
		var hi := -1e9
		var sum := 0.0
		var cnt := 0
		var step := maxi(vs.size() / 400, 1)
		var k := 0
		while k < vs.size():
			var v: Vector3 = mi.global_transform * vs[k]
			# cel mai apropiat punct de traseu
			var bi := 0
			var bd := 1e9
			for i in n:
				var p := _track.point_at(i)
				var d2 := (p.x - v.x) * (p.x - v.x) + (p.z - v.z) * (p.z - v.z)
				if d2 < bd:
					bd = d2
					bi = i
			var c := _track.point_at(bi)
			var sd: Vector3 = route.side_at(bi)
			var off := (v - c).dot(sd)
			lo = minf(lo, off)
			hi = maxf(hi, off)
			sum += off
			cnt += 1
			k += step
		print("  %-42s rulaj %+8.1f .. %+8.1f m, mediu %+7.1f  -> %s"
			% [mi.name, lo, hi, sum / float(cnt),
			"DREAPTA (valea)" if sum > 0.0 else "STANGA (interior)"])
	get_tree().quit(0)
