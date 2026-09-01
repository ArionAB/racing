extends Node
## Face cutia de treapta ca ArrayMesh CU CULORI DE VERTEX, si o salveaza ca
## resursa.
##
## De ce nu `BoxMesh`: materialul clasei (`triplanar_class_material`) are
## `vertex_color_use_as_albedo = true`, iar `BoxMesh` NU aduce canalul de
## culoare (verificat cu ProbeBoxVC: BoxMesh COLOR = LIPSA, mesh-ul GLB-ului
## COLOR = exista). Fara canal, albedo-ul se inmulteste cu ce nimereste acolo si
## pe captura ies grile de puncte negre pe fiecare treapta si pe fiecare bloc de
## grohotis — vizibile si cu umbrele STINSE, deci nu era shadow acne.
##
## Culoarea e alba: vertex color-ul poate doar sa INTUNECE (memoria
## `surfacetool-clamp-vertex-color`), deci alb inseamna „lasa albedo-ul in
## pace" si cutia se aseaza exact pe tenta peretelui.

const OUT := "res://assets/models/cappadocia/rocks/strat_box.res"

func _ready() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [
		[Vector3(0, 0, 1), Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5),
			Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)],
		[Vector3(0, 0, -1), Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5),
			Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)],
		[Vector3(1, 0, 0), Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5),
			Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)],
		[Vector3(-1, 0, 0), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5),
			Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)],
		[Vector3(0, 1, 0), Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5),
			Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5)],
		[Vector3(0, -1, 0), Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5),
			Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)],
	]
	for f in faces:
		var nrm: Vector3 = f[0]
		var quad := [f[1], f[2], f[3], f[4]]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			for k in tri:
				st.set_normal(nrm)
				st.set_color(Color.WHITE)
				st.set_uv(Vector2.ZERO)
				st.add_vertex(quad[k])
	st.generate_tangents()
	var mesh := st.commit()
	var err := ResourceSaver.save(mesh, OUT)
	print("salvat ", OUT, " err=", err,
		"  suprafete=", mesh.get_surface_count())
	var a := mesh.surface_get_arrays(0)
	print("COLOR = ", "LIPSA" if a[Mesh.ARRAY_COLOR] == null else "exista")
	get_tree().quit(0)
