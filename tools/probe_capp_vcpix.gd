extends SceneTree

## Ajunge vertex color-ul in PIXELI?
##
## Mesh-ul are culori perfect plate pe fata (verificat cu `probe_capp_vcol`:
## 0 fete neplate), dar captura nu s-a miscat. Inainte de a mai regla o cifra se
## verifica lantul, nu capetele lui: se citeste vertex color-ul unei fete si se
## compara cu ce ar trebui sa iasa. Daca ALBEDO nu depinde de COLOR, orice
## umbrire scrisa in vertecsi e munca aruncata.

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var best: MeshInstance3D = null
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null and String(n.name).to_lower().contains("chimney"):
			best = mi
			break
	if best == null:
		print("niciun horn")
		quit()
		return
	var mat := best.material_override
	print("material_override: ", mat)
	if mat is ShaderMaterial:
		var sm: ShaderMaterial = mat
		print("shader: ", sm.shader.resource_path)
		var code: String = sm.shader.code
		print("codul foloseste COLOR: ", code.contains("COLOR"))
		print("vertex_color_use_as_albedo irelevant (shader custom)")
	elif mat is StandardMaterial3D:
		var st: StandardMaterial3D = mat
		print("vertex_color_use_as_albedo: ", st.vertex_color_use_as_albedo)
	# Si materialul de suprafata, daca override-ul nu acopera tot
	for sf in best.mesh.get_surface_count():
		print("  suprafata %d material: %s" % [sf, best.mesh.surface_get_material(sf)])
	quit()
