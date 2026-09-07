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


func _ready() -> void:
	if model == null or positions.is_empty():
		return
	var mesh := _mesh_of(model)
	if mesh == null:
		push_warning("FlockProp: %s nu are mesh" % model.resource_path)
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = positions.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in positions.size():
		var yaw: float = yaws[i] if i < yaws.size() else 0.0
		var s := rng.randf_range(scale_min, scale_max)
		mm.set_instance_transform(i, Transform3D(
			Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * s),
			positions[i]))
	multimesh = mm
	material_override = Palette.world_material()
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
