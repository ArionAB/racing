@tool
class_name WaterfallVisual
extends Node3D
## Vizualul PARTAJAT al unei perdele de apa (Fiordland, brief §5.1 clasa
## `waterfall`): il folosesc `WaterfallHazard` (Stirling, cele 5 cascade de
## ploaie) si, mai tarziu, Bowen. O singura clasa vizuala, un singur material
## de shader si un singur material de spray, oricate perdele sunt pe pista.
##
## Ce construieste, in reperul local (X = grosime, Y = inaltime, Z = lungime,
## acelasi cu forma de coliziune a hazardului, ca ce vezi sa fie exact ce
## simti):
##   - PANZE VERTICALE incrucisate cu `waterfall.gdshader`: 2 panze „in lung"
##     (normala pe X, intinse pe Z, la ±grosime/4) si 1-3 panze „de-a latul"
##     (normala pe Z, intinse pe X, la pas de ~10 m pe lungime). Incrucisarea
##     e ce face perdeaua sa se citeasca la fel din orice directie — de pe
##     drum, de pe malul opus, si oricum ar fi asezat nodul fata de drum — cu
##     costul a 2 triunghiuri pe panza. Nu e o cutie: panzele sunt
##     `cull_disabled`, fara depth write, cu marginile topite in alpha.
##   - o PLACA DE SPUMA la sol (evantai de 8 triunghiuri cu alpha 1 in centru
##     si 0 pe margine — cadere liniara, fara treapta), acelasi material: banda
##     alba de la contactul cu drumul, ce se vede de la 100 m (brief §2.0).
##   - SPRAY: un `GPUParticles3D` cu QuadMesh billboard si textura moale
##     `smoke_puff.png` (profil radial cu 0 trepte, verificat cu PIL —
##     memoria `particule-muchia-nu-numarul`), aruncat in sus din baza,
##     tras la sol. `count` e al chematorului: 48 la Stirling, 16 la o
##     cascada de ploaie (brief §6, overdraw-ul e bugetul real).
##
## Nu are logica de joc: primeste `build(size, spray_count)` si
## `set_intensity(a)` (fade-ul fazei de ploaie, prin `modulate` pe hazard).

const SHADER_PATH: String = "res://assets/shaders/waterfall.gdshader"
const SPRAY_TEX: String = "res://assets/textures/smoke_puff.png"
## Cat coboara panzele sub cota drumului, ca muchia lor de jos sa fie mereu
## ascunsa in asfalt/teren, nu o linie dreapta in aer. Trebuie sa fie egal cu
## `sink_m` din shader, care topeste continuu portiunea scufundata (unde
## terenul de langa drum e mai jos decat drumul, muchia ar fi iesit in aer).
const SINK_M: float = 2.0
## Pasul intre panzele de-a latul (m) si plafonul lor.
const CROSS_STEP_M: float = 10.0
const CROSS_MAX: int = 3
## Culoarea spray-ului, in sRGB (memoria `strop-apa-particule`: materialul
## citeste sRGB, o culoare liniara ar iesi murdara).
const SPRAY_COLOR: Color = Color(0.90, 0.95, 0.98)

static var _sheet_material: ShaderMaterial = null
static var _spray_material: StandardMaterial3D = null

var _sheets: Array[MeshInstance3D] = []
var _spray: GPUParticles3D = null
var _intensity: float = 1.0


## Materialul de shader, UNUL pentru toata pista (static): garda de materiale
## (`probe_decor`) numara instantele, deci fiecare perdea trebuie sa arate
## spre acelasi obiect.
static func sheet_material() -> ShaderMaterial:
	if _sheet_material == null:
		var m := ShaderMaterial.new()
		m.shader = load(SHADER_PATH) as Shader
		_sheet_material = m
	return _sheet_material


## Materialul stropilor, la fel static. Billboard MOALE, unshaded: spray-ul
## e abur, nu bile — muchia continua a texturii e tot rostul lui.
static func spray_material() -> StandardMaterial3D:
	if _spray_material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.albedo_texture = load(SPRAY_TEX) as Texture2D
		m.disable_fog = false
		_spray_material = m
	return _spray_material


## Construieste (sau reconstruieste) tot vizualul pentru o zona de `size`
## metri (x grosime, y inaltime, z lungime), cu `spray_count` stropi.
func build(size: Vector3, spray_count: int) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sheets.clear()
	_spray = null
	var mat := sheet_material()
	var h := size.y
	# Panzele in lung: normala pe X, intinse pe Z.
	var along := _sheet_mesh(size.z, h)
	for sx in [-0.25, 0.25]:
		var mi := _sheet_instance(along, mat, Vector2(size.z, h), false)
		mi.name = "PanzaLung" + ("A" if sx < 0.0 else "B")
		mi.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(size.x * sx, 0.0, 0.0))
		add_child(mi)
		_sheets.append(mi)
	# Panzele de-a latul: normala pe Z, intinse pe X, la pas pe lungime.
	var n_cross := clampi(int(ceil(size.z / CROSS_STEP_M)), 1, CROSS_MAX)
	var across := _sheet_mesh(size.x, h)
	for i in n_cross:
		var mi2 := _sheet_instance(across, mat, Vector2(size.x, h), false)
		mi2.name = "PanzaLat%d" % i
		var z := 0.0 if n_cross == 1 else lerpf(-size.z * 0.5, size.z * 0.5, (i + 0.5) / n_cross)
		mi2.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, z))
		add_child(mi2)
		_sheets.append(mi2)
	# Placa de spuma la sol.
	var pad := _sheet_instance(
		_pad_mesh(size.x * 0.5 + 1.5, size.z * 0.5 + 1.5, h), mat, Vector2(size.x + 3.0, h), true)
	pad.name = "Spuma"
	pad.position = Vector3(0.0, 0.35, 0.0)
	add_child(pad)
	_sheets.append(pad)
	# Spray-ul.
	if spray_count > 0:
		_spray = _spray_node(size, spray_count)
		add_child(_spray)
	set_intensity(_intensity)


## Fade-ul fazei de ploaie: 0 = stins, 1 = plin. Trece prin instance uniform
## (acelasi material) si prin `amount_ratio` pe stropi.
func set_intensity(a: float) -> void:
	_intensity = clampf(a, 0.0, 1.0)
	for mi in _sheets:
		if is_instance_valid(mi):
			mi.set_instance_shader_parameter(&"intensity", _intensity)
	if _spray != null and is_instance_valid(_spray):
		_spray.amount_ratio = maxf(_intensity, 0.001)
		_spray.emitting = _intensity > 0.01


func intensity() -> float:
	return _intensity


## Panzele si placa, pentru sonde.
func sheets() -> Array[MeshInstance3D]:
	return _sheets


func spray() -> GPUParticles3D:
	return _spray


## Dimensiunile panzei merg ca INSTANCE UNIFORMS (acelasi material pentru
## toate): SurfaceTool taie vertex color-ul la [0,1] (memoria
## `surfacetool-clamp-vertex-color`), deci metrii nu pot calatori prin COLOR.
func _sheet_instance(mesh: Mesh, mat: Material, sheet_m: Vector2, is_pad: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.set_instance_shader_parameter(&"sheet_m", sheet_m)
	mi.set_instance_shader_parameter(&"pad", 1.0 if is_pad else 0.0)
	return mi


## O panza verticala in planul XY local (normala +Z), de `width` pe X,
## centrata pe X, de la `-SINK_M` pana la `height` pe Y. UV: v = 0 la varf,
## 1 la baza; UV2 in metri (y in jos de la varf); COLOR.a = 1.
func _sheet_mesh(width: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := width * 0.5
	var y_top := height
	var y_bot := -SINK_M
	var total := height + SINK_M
	var col := Color(1.0, 1.0, 1.0, 1.0)
	var corners := [
		Vector3(-hw, y_top, 0.0), Vector3(hw, y_top, 0.0),
		Vector3(hw, y_bot, 0.0), Vector3(-hw, y_bot, 0.0)]
	var uvs := [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]
	var uv2s := [Vector2(0.0, 0.0), Vector2(width, 0.0),
		Vector2(width, total), Vector2(0.0, total)]
	for i in 4:
		st.set_color(col)
		st.set_uv(uvs[i])
		st.set_uv2(uv2s[i])
		st.set_normal(Vector3.BACK)
		st.add_vertex(corners[i])
	st.add_index(0); st.add_index(1); st.add_index(2)
	st.add_index(0); st.add_index(2); st.add_index(3)
	return st.commit()


## Placa de spuma: evantai eliptic de 8 triunghiuri in planul XZ, alpha 1 in
## centru si 0 pe margine (cadere liniara, continua). Instance uniform-ul
## `pad` = 1 spune shaderului „placa": mereu spuma, fara fade-urile de perdea.
func _pad_mesh(rx: float, rz: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEG := 8
	st.set_color(Color(1.0, 1.0, 1.0, 1.0))
	st.set_uv(Vector2(0.5, 1.0))
	st.set_uv2(Vector2(rx, height))
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3.ZERO)
	for i in SEG:
		var a := TAU * float(i) / SEG
		var p := Vector3(cos(a) * rx, 0.0, sin(a) * rz)
		st.set_color(Color(1.0, 1.0, 1.0, 0.0))
		st.set_uv(Vector2(0.5 + 0.5 * cos(a), 1.0))
		st.set_uv2(Vector2(rx + p.x, height + p.z * 0.4))
		st.set_normal(Vector3.UP)
		st.add_vertex(p)
	for i in SEG:
		st.add_index(0)
		st.add_index(1 + i)
		st.add_index(1 + (i + 1) % SEG)
	return st.commit()


## Stropii: emisi dintr-o cutie cat baza perdelei, in sus cu imprastiere,
## trasi la sol; lifetime scurt, fara coliziune. `preprocess` ca norul sa
## existe din primul cadru (capturi, intrarea in raza camerei).
func _spray_node(size: Vector3, count: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Spray"
	p.amount = count
	p.lifetime = 1.0
	p.preprocess = 1.0
	p.explosiveness = 0.0
	p.randomness = 0.4
	p.fixed_fps = 30
	p.position = Vector3(0.0, 0.4, 0.0)
	p.visibility_aabb = AABB(
		Vector3(-size.x * 0.5 - 4.0, -1.0, -size.z * 0.5 - 4.0),
		Vector3(size.x + 8.0, 9.0, size.z + 8.0))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(size.x * 0.5, 0.3, size.z * 0.5)
	pm.direction = Vector3(0.0, 1.0, 0.0)
	pm.spread = 55.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.5
	pm.gravity = Vector3(0.0, -7.0, 0.0)
	pm.damping_min = 0.8
	pm.damping_max = 1.6
	pm.scale_min = 1.4
	pm.scale_max = 2.6
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -30.0
	pm.angular_velocity_max = 30.0
	pm.color = SPRAY_COLOR
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.18, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)]))
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = spray_material()
	p.draw_pass_1 = quad
	return p
