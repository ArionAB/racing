extends Node
## Are BoxMesh vertex colors? Materialul clasei are
## `vertex_color_use_as_albedo = true`, deci mesh-urile FARA culori de vertex
## primesc ce vrea driverul acolo — de-aia treptele si grohotisul ies cu grile
## de puncte negre chiar si cu umbrele stinse.
func _ready() -> void:
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	var arr := bm.surface_get_arrays(0)
	print("BoxMesh: vertecsi=", (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	print("BoxMesh COLOR = ", "LIPSA" if arr[Mesh.ARRAY_COLOR] == null else "exista")
	# Comparatie: mesh-ul modulului de faleza, care arata corect.
	var ps := load("res://assets/models/cappadocia/rocks/cliff_band_module.glb") as PackedScene
	var inst := ps.instantiate()
	get_tree().root.add_child.call_deferred(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var a2 := mm.surface_get_arrays(0)
		print("GLB %s COLOR = %s" % [mi.name,
			"LIPSA" if a2[Mesh.ARRAY_COLOR] == null else "exista"])
		break
	get_tree().quit(0)
