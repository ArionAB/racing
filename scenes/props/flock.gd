extends MultiMeshInstance3D
class_name FlockProp
## Un STOL de piese identice, desenate cu un singur draw call.
##
## Nascut pe POI E (Serengeti): bordura lacului Magadi cere ~150 de flamingi
## la 100-180 m de sosea. Ca noduri `WorldProp` ar fi 150 de instante de scena
## si 150 de corpuri; ca MultiMesh e un desen si zero fizica — exact ce vrea
## un tiv de pasari care nu opreste nimic.
##
## Pozitiile si yaw-urile vin din generator (`gen_decor_ser_e.gd`) ca liste
## paralele, in COORDONATE DE LUME; nodul sta la origine, deci nu e nevoie de
## `top_level` (spre deosebire de turma, care isi muta nodul — vezi
## HerdHazard._make_lot).
##
## Mesh-ul se ia din primul MeshInstance3D al GLB-ului, cu transformul nodului
## COPT in varfuri (un MultiMesh nu stie de ierarhia din care vine mesh-ul), si
## primeste materialul comun de lume, ca orice prop din atlas.

@export var model: PackedScene = null
@export var positions: PackedVector3Array = PackedVector3Array()
@export var yaws: PackedFloat32Array = PackedFloat32Array()
## Variatie de scara per instanta, ca stolul sa nu fie o stampila repetata.
@export var scale_min: float = 0.9
@export var scale_max: float = 1.15
@export var seed_value: int = 20260907
## Scalare NEUNIFORMA per instanta (optional). Cand nu e goala, inlocuieste
## `scale_min`/`scale_max`: fiecare element e (x, y, z) in loc de un scalar.
## Nascut pe creasta de granit a POI E — coame de stanca intinse pe verticala
## si turtite orizontal, ca sa citeasca drept creste care urmeaza caderea, nu
## bulgari rotunzi (vezi `tools/gen_decor_ser_e.gd`).
@export var scale3_list: Array[Vector3] = []
## Clasa triplanara de folosit ca material (ex. "granite"), in loc de
## `Palette.world_material()` (atlas plat). Gol = comportament vechi
## (flamingi, crusta): niciun MultiMesh existent nu foloseste asta, deci
## implicitul pastreaza exact aspectul de dinainte.
@export var tri_class: String = ""
## AO-ul copt in COLOR_0 al modelului, neutralizat partial.
##
## Masurat pe flamingo.glb: COLOR_0 are luminanta mediana 0.760 si minim
## 0.240, iar `vertex_color_use_as_albedo` o inmulteste peste albedo. Slotul
## 31 e roz pal (V=0.94), dar inelul iesea rgb(105,61,60) V=0.41 pe cadrul
## erou, fata de rgb(188,129,131) V=0.74 in referinta: la 100-150 m un
## flamingo e cativa pixeli, deci AO-ul propriu nu se citeste ca volum, doar
## innegreste. Umbra placilor de crusta a fost exclusa prin A/B (cast_shadow
## off pe crusta: V 0.41 -> 0.42, adica nimic).
##
## 1.0 = culorile din GLB neatinse; 0.0 = alb curat. Se aplica DOAR aici,
## deci nu atinge niciun alt prop din atlas.
@export_range(0.0, 1.0) var ao_keep: float = 1.0
## CRUSTA: cand `model` e null si `disc_slot >= 0`, mesh-ul nu vine dintr-un
## GLB ci e o PLACA plata de 12 laturi asezata pe slotul cerut din atlas.
##
## De ce exista: masurata pe referinta, bordura alba de sare a lacului Magadi
## ocupa 20,8 % din sfertul din dreapta-jos al cadrului, iar la noi 0,2 %.
## Fara ea inelul de flamingi sta pe turcoaz si nu se citeste (roz pe alb =
## banda; roz pe apa = zgomot). Terenul nu o poate da — `_lagoon_mix` sapa
## doar inaltimea, nu vopseste — si o textura noua ar fi un material in plus,
## de aceea crusta e geometrie pe un slot care exista deja (22 FOAM_WHITE).
## Placile se suprapun deliberat: 12 laturi x cateva sute = o suprafata, nu
## niste discuri.
@export var disc_slot: int = -1
## Raza placii, in metri (scalata apoi de scale_min/scale_max).
@export var disc_radius: float = 6.0


func _ready() -> void:
	if positions.is_empty():
		return
	if model == null and disc_slot < 0:
		return
	var mesh: Mesh = _disc_mesh(disc_slot, disc_radius) if model == null and disc_slot >= 0 else _mesh_of(model)
	if mesh != null and model != null and ao_keep < 1.0:
		mesh = _lift_ao(mesh, ao_keep)
	if mesh == null:
		push_warning("FlockProp: %s nu are mesh" % model.resource_path)
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var use_scale3 := scale3_list.size() == positions.size()
	for i in positions.size():
		var yaw: float = yaws[i] if i < yaws.size() else 0.0
		# ATENTIE: niciodata scale.x negativ pentru oglindire — Godot culleste
		# instantele MultiMesh cu determinant negativ (compenseaza doar pe
		# noduri). Oglindirea se face din yaw, nu din scara.
		var sc: Vector3
		if use_scale3:
			sc = scale3_list[i]
		else:
			var s := rng.randf_range(scale_min, scale_max)
			sc = Vector3.ONE * s
		mm.set_instance_transform(i, Transform3D(
			Basis(Vector3.UP, yaw) * Basis.from_scale(sc),
			positions[i]))
	multimesh = mm
	material_override = Palette.triplanar_class_material(tri_class) if tri_class != "" else Palette.world_material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


static func _mesh_of(ps: PackedScene) -> Mesh:
	var root := ps.instantiate()
	var found: MeshInstance3D = null
	var stack: Array[Node] = [root]
	while not stack.is_empty() and found == null:
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			found = n as MeshInstance3D
	var mesh: Mesh = null
	if found != null and found.mesh != null:
		var xf := Transform3D.IDENTITY
		var cur: Node = found
		while cur != null and cur != root:
			if cur is Node3D:
				xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		if xf.is_equal_approx(Transform3D.IDENTITY):
			mesh = found.mesh
		else:
			var out: ArrayMesh = null
			for si in found.mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.append_from(found.mesh, si, xf)
				out = st.commit(out)
			mesh = out
	root.free()
	return mesh


## Placa plata de crusta: 12 laturi, un singur triunghi-evantai, toate
## varfurile pe UV-ul slotului cerut. Normala in sus, deci primeste soarele
## plin — crusta de sare din referinta e cea mai LUMINOASA suprafata din cadru,
## nu doar cea mai putin saturata.
static func _disc_mesh(slot: int, radius: float) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv := Palette.uv(slot)
	var segs := 12
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		# ORDINEA VARFURILOR conteaza: cu fata in sus, Godot deseneaza doar
		# triunghiurile parcurse invers acelor de ceas privite dinspre +Y.
		# Scrise ca (centru, a1, a0) placile erau BACK-FACING si crusta nu se
		# randa deloc — masurat cu slotul 30 (portocaliu de lava) pe cadrul
		# hero: zero pixeli, si la +3 m deasupra terenului. Nimic nu semnala
		# defectul: nodul exista, MultiMesh-ul avea 241 de instante, sondele
		# de mesh-uri sunt oarbe la MultiMesh.
		for v in [Vector3.ZERO,
				Vector3(cos(a0) * radius, 0.0, sin(a0) * radius),
				Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)]:
			st.set_uv(uv)
			st.set_normal(Vector3.UP)
			st.set_color(Color.WHITE)
			st.add_vertex(v)
	return st.commit()


## Ridica AO-ul copt spre alb: fiecare canal se muta cu (1 - keep) catre 1.
## Pe mesh, nu pe material, fiindca materialul e cel comun de lume (o singura
## instanta pentru toata pista) — nu poate purta o corectie de model.
static func _lift_ao(src: Mesh, keep: float) -> Mesh:
	var out := ArrayMesh.new()
	for si in src.get_surface_count():
		var arr := src.surface_get_arrays(si)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var raw: Variant = arr[Mesh.ARRAY_COLOR]
		var cols := PackedColorArray()
		if raw is PackedColorArray:
			cols = raw
		if cols.size() != verts.size():
			cols = PackedColorArray()
			cols.resize(verts.size())
			cols.fill(Color.WHITE)
		for i in cols.size():
			var c := cols[i]
			cols[i] = Color(
				1.0 - (1.0 - c.r) * keep,
				1.0 - (1.0 - c.g) * keep,
				1.0 - (1.0 - c.b) * keep,
				c.a)
		arr[Mesh.ARRAY_COLOR] = cols
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out
