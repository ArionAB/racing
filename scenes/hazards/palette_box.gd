class_name PaletteBox
extends RefCounted
## Cutii pe ATLASUL de paleta: geometria procedurala a hazardelor, fara niciun
## material nou.
##
## De ce exista fisierul asta si nu inca o metoda privata intr-un hazard:
## `LiftBridgeHazard` si `TrainHazard` isi construiesc cutiile cu
## `StandardMaterial3D.new()` (cate un material per culoare), iar
## `CablewayHazard` a rezolvat-o corect — UV-uri colapsate pe centrul slotului
## si `Palette.world_material()` pentru tot — dar cu `_add_box`/`_box_mesh`
## private. Al doilea hazard care avea nevoie de ele le-ar fi copiat; al
## patrulea le-ar fi copiat divergent. Garda din `tools/probe_decor.gd` numara
## materialele per pista (max 38), deci „inca un StandardMaterial3D pentru un
## bec" e exact clasa de regresie pe care o vaneaza.
##
## Contractul atlasului: UV-ul unui vertex arata spre CENTRUL slotului
## (`Palette.uv(slot)`), deci orice cutie de aici e o culoare din paleta si
## toate impart acelasi material.


## O cutie orientata in SurfaceTool: 12 triunghiuri, toate UV-urile pe slot.
static func add(st: SurfaceTool, xf: Transform3D, size: Vector3, slot: int) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var faces := [
		[Vector3.UP, Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(-1, 1, -1)],
		[Vector3.DOWN, Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1)],
	]
	for f: Array in faces:
		var normal: Vector3 = (xf.basis * (f[0] as Vector3)).normalized()
		var pts: Array[Vector3] = []
		for k in range(1, 5):
			pts.append(xf * ((f[k] as Vector3) * h))
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(normal)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(pts[k])


## O prisma cu patru colturi de sus date explicit (podea de deck, pana de
## rampa, treapta de peron) si o talpa de grosime `thick` sub ele.
##
## Exista fiindca o CUTIE nu poate fi o rampa: lectia din `LiftBridgeHazard`
## (tabliera asezata ca AABB) si din memoria `suprafete-cu-goluri-si-praguri`
## — o suprafata inclinata construita din cutii orizontale lasa praguri
## verticale pe linia de rulare.
## `caps` = false lasa afara cele doua fete de CAPAT (a-b si c-d), pentru placi
## insirate cap la cap.
##
## [b]De ce e nevoie.[/b] O suprafata lunga taiata in bucati de doi metri —
## cum e tablierul care urmeaza o spirala — emitea pana acum peretele de capat
## al FIECAREI bucati. Pe o suprafata inclinata si curba, peretele unei bucati
## iese prin fata de sus a vecinei: masurat in captura de la frac 0.760, dungi
## la luminanta 0.037-0.05 pe un tablier de 0.18-0.26, adica de cinci ori mai
## intunecate decat suprafata pe care stau.
## `with_top = false` lasa fata de SUS afara: o folosesc suprafetele de rulare,
## care isi emit fata de deasupra pe materialul soselei (cu UV2), si pastreaza
## pe atlas doar flancurile si talpa. Vezi `RotatingSpanHazard._road_face`.
static func quad_slab(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, thick: float, slot: int, caps: bool = true,
		with_top: bool = true) -> void:
	var down := Vector3.DOWN * thick
	var top := [a, b, c, d]
	var bot := [a + down, b + down, c + down, d + down]
	var uv := Palette.uv(slot)
	var quads := []
	if with_top:
		quads.append([top[0], top[1], top[2], top[3]])
	quads.append_array([
		[bot[3], bot[2], bot[1], bot[0]],
		[top[0], top[3], bot[3], bot[0]],
		[top[2], top[1], bot[1], bot[2]],
	])
	if caps:
		quads.append([top[1], top[0], bot[0], bot[1]])
		quads.append([top[3], top[2], bot[2], bot[3]])
	for q: Array in quads:
		var n: Vector3 = ((q[1] as Vector3) - (q[0] as Vector3)).cross(
			(q[2] as Vector3) - (q[0] as Vector3))
		if n.length_squared() < 1e-9:
			continue
		n = n.normalized()
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(n)
				st.set_uv(uv)
				st.set_color(Color.WHITE)
				st.add_vertex(q[k])


## Mesh-ul unei cutii singure, gata cu materialul lumii pe el.
static func mesh(size: Vector3, slot: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	add(st, Transform3D.IDENTITY, size, slot)
	var m := st.commit()
	m.surface_set_material(0, Palette.world_material())
	return m


## O cutie gata de pus in arbore.
static func instance(size: Vector3, slot: int, at: Vector3 = Vector3.ZERO,
		basis: Basis = Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh(size, slot)
	mi.transform = Transform3D(basis, at)
	return mi


## Inchide un SurfaceTool intr-un MeshInstance3D pe materialul lumii.
## `null` daca n-a fost emis niciun triunghi (SurfaceTool.commit() da null).
static func emit(st: SurfaceTool, node_name: String) -> MeshInstance3D:
	var m := st.commit()
	if m == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = m
	mi.material_override = Palette.world_material()
	return mi
