extends Node
## Are `cliff_band_module.glb` triunghiuri DUPLICATE/coincidente in el?
##
## Ultima ipoteza care mai sta in picioare pentru petele negre: nu e umbra, nu
## e textura, nu e culoarea de vertex, nu e suprapunerea cu peretele, nu e
## marimea, nu e triplanarul (toate excluse prin masuratoare sau captura).
## Petele stau in RANDURI REGULATE pe fetele in trepte ale piesei — deci se
## uita in mesh: doua triunghiuri in acelasi plan, la distanta zero, se bat pe
## adancime, iar strangerea la scara mica le apropie si mai tare in Z-buffer.

const P := "res://assets/models/cappadocia/rocks/cliff_band_module.glb"

func _ready() -> void:
	var inst := (load(P) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null:
			continue
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var tris := idx.size() / 3
			# centroizi, rotunjiti la 1 mm
			var seen := {}
			var dup := 0
			for t in tris:
				var a := v[idx[t * 3]]
				var b := v[idx[t * 3 + 1]]
				var c := v[idx[t * 3 + 2]]
				var ctr := (a + b + c) / 3.0
				var key := "%.3f_%.3f_%.3f" % [ctr.x, ctr.y, ctr.z]
				if seen.has(key):
					dup += 1
				else:
					seen[key] = true
			print("%s surf %d: %d triunghiuri, %d cu centroid DUPLICAT"
				% [mi.name, s, tris, dup])
	get_tree().quit(0)
