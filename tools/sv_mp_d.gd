extends Node
## Ce parte a drumului e "in jos" pe intervalul teraselor (0.42-0.53), ca o
## rapa noua sa cada pe partea potrivita. Brief-ul cere 10 terase de 2,5 m,
## adica ~25 m de cadere, si scurtatura "drept in jos" cu 8 sarituri.
## Masoara, pe fiecare fractie: cota axului, si cota terenului la 20/40/70 m in
## ambele parti — partea care e deja mai jos e cea pe care cade versantul.
const TRACK := "res://scenes/tracks/Track15.tscn"
func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var mi := t.find_child("Terrain", true, false) as MeshInstance3D
	var arr := mi.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n := t.baked.size()
	print("frac   idx   ax_y  | teren mediu pe stanga/dreapta, la 20/40/70 m (din mesh)")
	var f := 0.42
	while f <= 0.545:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = t.baked[i]
		var nx: Vector3 = t.baked[(i + 1) % n]
		var d := (nx - bp); d.y = 0.0
		if d.length() < 0.001: f += 0.01; continue
		d = d.normalized()
		var lat := Vector3(-d.z, 0.0, d.x)
		var row := "%.3f %4d %+6.1f |" % [f, i, bp.y]
		for sgn: float in [-1.0, 1.0]:
			for off: float in [20.0, 40.0, 70.0]:
				var p := bp + lat * (off * sgn)
				# cel mai apropiat vertex de mesh, in plan
				var best := 1e9
				var by := 0.0
				for k in vs.size():
					var v := vs[k]
					var dd: float = (v.x - p.x) * (v.x - p.x) + (v.z - p.z) * (v.z - p.z)
					if dd < best: best = dd; by = v.y
				row += " %+6.1f" % by
			row += " |"
		print(row)
		f += 0.015
	get_tree().quit(0)
