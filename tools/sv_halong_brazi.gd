## De unde vin coniferele de pe nisip?
##
## Tema `halong` are "props": "" si "decor": "", deci NU din scatterul de tema.
## Sonda listeaza TOT ce e in scena si nu e pus de mine, grupat pe sursa de
## mesh, ca sa se vada cine le produce. Masurat, nu presupus.
extends Node


func _ready() -> void:
	var scene := load("res://scenes/tracks/Track22.tscn") as PackedScene
	var track := scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var pe_sursa := {}
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		var mm := n as MultiMeshInstance3D
		var key := ""
		var cnt := 0
		if mi != null and mi.mesh != null:
			key = "MESH %s" % _sursa(mi.mesh)
			cnt = 1
		elif mm != null and mm.multimesh != null and mm.multimesh.mesh != null:
			key = "MULTIMESH %s" % _sursa(mm.multimesh.mesh)
			cnt = mm.multimesh.instance_count
		if key == "":
			continue
		# calea de parinti, ca sa se vada CINE il tine
		var p := n.get_parent()
		var lant := ""
		var k := 0
		while p != null and p != track and k < 3:
			lant = String(p.name) + "/" + lant
			p = p.get_parent()
			k += 1
		var full := "%-46s  sub %s" % [key, lant]
		pe_sursa[full] = int(pe_sursa.get(full, 0)) + cnt

	# Detaliu pe nodul `Decor`: cine il umple?
	var dec := track.get_node_or_null("Decor")
	if dec != null:
		print("=== nodul Decor ===")
		print("  script: ", dec.get_script())
		for c in dec.get_children():
			print("  copil: %s (%s)" % [c.name, c.get_class()])
			if c.name == "Batched":
				for g in c.get_children():
					var mm2 := g as MultiMeshInstance3D
					if mm2 != null and mm2.multimesh != null:
						var mh := mm2.multimesh.mesh
						var sz := "?"
						if mh != null:
							sz = str(mh.get_aabb().size)
						print("     %s: %d instante, mesh %s, aabb %s"
							% [g.name, mm2.multimesh.instance_count,
							   mh.get_class() if mh != null else "null", sz])
		print("")

	var chei := pe_sursa.keys()
	chei.sort()
	print("=== ce e in scena, pe sursa de mesh ===")
	for k2 in chei:
		print("  %6d x  %s" % [pe_sursa[k2], k2])
	get_tree().quit(0)


func _sursa(m: Mesh) -> String:
	var rp := m.resource_path
	if rp != "":
		return rp.get_file()
	if m.resource_name != "":
		return "(gen) " + m.resource_name
	return "(generat in cod: %s)" % m.get_class()
