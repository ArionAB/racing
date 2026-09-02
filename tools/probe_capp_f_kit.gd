extends Node
## Masoara AABB-ul REAL al pieselor de subteran, ca asezarea sa nu se faca pe
## cotele din docstring-ul scriptului de build (alea sunt intentia, nu rezultatul
## dupa bevel/AO/origine).
const MODELS := [
	"structures/cave_entrance", "structures/hall_column",
	"structures/hall_arch", "structures/hall_ceiling_module",
	"structures/hall_alcove", "structures/church_arch",
	"structures/millstone_door", "structures/millstone_slot",
	"structures/vent_shaft", "props/torch",
	"rocks/cliff_band_module",
]

func _ready() -> void:
	for m in MODELS:
		var path := "res://assets/models/cappadocia/%s.glb" % m
		var sc := load(path) as PackedScene
		if sc == null:
			print("%-38s LIPSA" % m)
			continue
		var inst := sc.instantiate()
		add_child(inst)
		var aabb := AABB()
		var first := true
		var tris := 0
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var mesh := (mi as MeshInstance3D).mesh
			if mesh == null:
				continue
			for s in mesh.get_surface_count():
				tris += mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size() / 3
			var a := (mi as MeshInstance3D).global_transform * mesh.get_aabb()
			aabb = a if first else aabb.merge(a)
			first = false
		print("%-38s  x[%+6.2f %+6.2f] y[%+6.2f %+6.2f] z[%+6.2f %+6.2f]  tris %d" % [
			m, aabb.position.x, aabb.end.x, aabb.position.y, aabb.end.y,
			aabb.position.z, aabb.end.z, tris])
		inst.queue_free()
	get_tree().quit()
