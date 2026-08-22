extends SceneTree
## Genereaza un GLB de teren care JOACA ROLUL unui export Marble (World Labs):
## un mesh necunoscut, denivelat, fara drum si fara metadate — ca sa putem
## proba lantul "GLB de pe disc -> GlbWorld -> masina conduce pe el" inainte
## sa avem credite de API. Cand soseste un export real, acelasi lant primeste
## fisierul lui in loc de al nostru.
##
## Teren: camp de dune din sinusuri suprapuse, deterministe (fara seed — doua
## rulari dau acelasi fisier). Pantele raman sub ~25°, adica sub floor_max_angle
## (45°) al lui CharacterBody3D — terenul e abrupt, dar condusibil.
##
## Rulare (ca --script; nu are nevoie de autoload-uri):
##   godot --headless --path . --script res://tools/make_standin_glb.gd \
##       -- --out=C:/cale/absoluta/teren.glb

const SIZE: float = 240.0
const CELLS: int = 96

func _init() -> void:
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	if out.is_empty():
		push_error("make_standin_glb: lipseste --out=<cale absoluta .glb>")
		quit(1)
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := SIZE / float(CELLS)
	var half := SIZE * 0.5
	for iz in CELLS:
		for ix in CELLS:
			var x0 := -half + float(ix) * step
			var z0 := -half + float(iz) * step
			var x1 := x0 + step
			var z1 := z0 + step
			var v00 := Vector3(x0, _height(x0, z0), z0)
			var v10 := Vector3(x1, _height(x1, z0), z0)
			var v01 := Vector3(x0, _height(x0, z1), z1)
			var v11 := Vector3(x1, _height(x1, z1), z1)
			for v: Vector3 in [v00, v11, v10, v00, v01, v11]:
				st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()

	var root := Node3D.new()
	root.name = "StandinTerrain"
	var inst := MeshInstance3D.new()
	inst.name = "terrain"
	inst.mesh = mesh
	root.add_child(inst)
	inst.owner = root

	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, out)
	if err != OK:
		push_error("make_standin_glb: export esuat (%d) spre '%s'" % [err, out])
		quit(1)
		return
	print("make_standin_glb: %d triunghiuri, %s x %s m -> %s" % [
		mesh.get_faces().size() / 3, SIZE, SIZE, out])
	quit(0)


## Trei octave de relief: dune mari (~3 m / ~40 m lungime de unda), valuri
## medii si maruntis. Derivata maxima ~0.45 => panta maxima ~24°.
func _height(x: float, z: float) -> float:
	return 2.6 * sin(x / 23.0) * cos(z / 31.0) \
		+ 1.2 * sin(x / 9.0 + 1.7) * sin(z / 11.0 - 0.4) \
		+ 0.35 * sin(x / 3.1) * cos(z / 2.7)
