class_name LampHalo
extends RefCounted
## Halourile false ale surselor de lumina (Jodhpur): UN MultiMesh de patrate
## billboard, aditive, pe `assets/shaders/lamp_halo.gdshader`. Vezi antetul
## shaderului pentru ce poarta fiecare instanta si de ce nu exista glow in
## Environment (decizia dezvoltatorului, 30 sep 2026).
##
## UN material pentru toate halourile (`material()`, cache static): garda de
## materiale numara +1 pentru candele, becuri, felinare si lampile fortului
## laolalta. Diferentele sunt per instanta (culoare, raza, alungire, faza).
##
## Opt-in: nimic din afara Jodhpur-ului nu cheama clasa asta.

static var _mat: ShaderMaterial = null
static var _quad: ArrayMesh = null

## Numaratoarea pentru sonde (tools/probe_halo.gd): fiecare MultiMesh construit.
static var built: Array = []


static func material() -> ShaderMaterial:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://assets/shaders/lamp_halo.gdshader")
		# Dupa transparente opace; ordinea intre halouri nu conteaza (ADD e
		# comutativ).
		_mat.render_priority = 1
	return _mat


## Patratul [-1,1]^2 in XY, 2 triunghiuri. Fara UV: shaderul lucreaza pe VERTEX.
static func quad() -> ArrayMesh:
	if _quad == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p: Vector3 in [Vector3(-1, -1, 0), Vector3(1, -1, 0), Vector3(1, 1, 0),
				Vector3(-1, -1, 0), Vector3(1, 1, 0), Vector3(-1, 1, 0)]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(p)
		_quad = st.commit()
	return _quad


## Construieste haloul pentru o lista de surse (coordonate de LUME) si il
## adauga sub `parent`. `core`/`halo`/`stretch` sunt scalare comune sau liste
## paralele (PackedFloat32Array) per sursa. `flicker` > 0 da faze aleatoare
## (flacari); 0 = lumina electrica, fixa.
static func build(parent: Node3D, label: String, positions: PackedVector3Array,
		color: Color, intensity: float, core: Variant, halo: Variant,
		stretch: Variant = 1.0, flicker: bool = false,
		seed_value: int = 1) -> MultiMeshInstance3D:
	if positions.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad()
	mm.instance_count = positions.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var inv := parent.global_transform.affine_inverse() if parent.is_inside_tree() \
		else Transform3D.IDENTITY
	var aabb := AABB()
	var rmax := 0.0
	for k in positions.size():
		var p: Vector3 = inv * positions[k]
		mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, p))
		var c := _pick(core, k)
		var h := _pick(halo, k)
		var s := _pick(stretch, k)
		rmax = maxf(rmax, maxf(h, c * s))
		var ph := rng.randf_range(0.05, 1.0) if flicker else 0.0
		mm.set_instance_custom_data(k, Color(c, h, s, ph))
		mm.set_instance_color(k, Color(color.r, color.g, color.b, intensity))
		aabb = AABB(p, Vector3.ZERO) if k == 0 else aabb.expand(p)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = label
	mmi.multimesh = mm
	mmi.material_override = material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Shaderul umfla patratul pana la raza haloului, deci AABB-ul calculat din
	# patratul unitar ar taia halourile de pe marginea cadrului.
	mmi.custom_aabb = aabb.grow(rmax + 1.5)
	parent.add_child(mmi)
	built.append(mmi)
	return mmi


static func _pick(v: Variant, k: int) -> float:
	if v is PackedFloat32Array:
		var a: PackedFloat32Array = v
		return a[k] if k < a.size() else (a[a.size() - 1] if a.size() > 0 else 0.0)
	return float(v)
