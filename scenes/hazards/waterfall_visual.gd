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
## Cat de departe se intinde panza de ceata joasa fata de capatul perdelei
## (m), brief pasul 3c: "20 m in fata si in spate".
const MIST_REACH_M: float = 20.0
## Inaltimea vizuala a cetii joase (m), brief: "2 m".
const MIST_HEIGHT_M: float = 2.0

static var _sheet_material: ShaderMaterial = null
static var _spray_material: StandardMaterial3D = null

var _sheets: Array[MeshInstance3D] = []
var _spray: GPUParticles3D = null
## Explozia de spray la baza (brief pasul 3b): one-shot, separata de spray-ul
## continuu — pornita din `trigger_splash_burst()`, apelat de hazard cand o
## masina INTRA in perdea (nu la fiecare cadru cat timp e sub ea).
var _spray_burst: GPUParticles3D = null
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
	_spray_burst = null
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
	# INELUL de spuma animat (splash, brief pasul 3a): banda mai ingusta decat
	# placa de dedesubt, dar TURBULENTA (uniform `ring`), chiar pe linia de
	# contact — placa de mai sus da caderea radiala lina, inelul da bulboana.
	var ring := _ring_instance(_ring_mesh(size.x * 0.5 + 1.0, size.z * 0.5 + 1.0), mat)
	ring.name = "InelSpuma"
	ring.position = Vector3(0.0, 0.32, 0.0)
	add_child(ring)
	_sheets.append(ring)
	# CEATA JOASA (brief pasul 3c): doua fasii plate, 2 m inaltime, intinse
	# 20 m in fata si in spatele perdelei de-a lungul Z local (acelasi reper
	# ca forma de coliziune — Z e lungimea drumului aici).
	for sgn in [-1.0, 1.0]:
		var wisp := _mist_instance(_mist_mesh(size.x * 0.5 + 2.5, MIST_REACH_M, MIST_HEIGHT_M), mat)
		wisp.name = "CeataJoasa" + ("Spate" if sgn < 0.0 else "Fata")
		wisp.position = Vector3(0.0, MIST_HEIGHT_M * 0.5, sgn * (size.z * 0.5 + MIST_REACH_M * 0.5))
		add_child(wisp)
		_sheets.append(wisp)
	# Spray-ul continuu (stropii de la baza, cat timp perdeaua e activa).
	if spray_count > 0:
		_spray = _spray_node(size, spray_count)
		add_child(_spray)
		# Explozia (splash, brief pasul 3b): acelasi buget de `spray_count` ca
		# emitatorul continuu, chematorul decide (<=64 Stirling, <=24 ploaie).
		_spray_burst = _spray_burst_node(size, spray_count)
		add_child(_spray_burst)
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


## Inelul de spuma (`ring` uniform, vezi shader): acelasi material partajat,
## niciun uniform de dimensiune necesar (`v_m` e deja in metri, din UV2).
func _ring_instance(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.set_instance_shader_parameter(&"ring", 1.0)
	return mi


## Panza de ceata joasa (`mist` uniform, vezi shader).
func _mist_instance(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.set_instance_shader_parameter(&"mist", 1.0)
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


## Inelul de spuma animat (splash, brief pasul 3a): acelasi evantai eliptic
## ca placa de spuma, dar cu alpha de vertex care cade DIN AMANDOUA parti —
## 0 in centru SI 0 la margine, plin la o raza intermediara — ca sa citeasca
## drept INEL (bulboana la linia de contact), nu drept placa plina. UV2 aici
## e coordonata locala XZ in metri (nu (x,y) de panza): shaderul, in modul
## `ring`, foloseste `length(v_m)` pentru unda radiala si `v_m` direct pentru
## zgomotul de turbulenta.
func _ring_mesh(rx: float, rz: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEG := 12
	const RING_IN := 0.45 # raza interioara (fractie din rx/rz) unde alpha=0
	const RING_MID := 0.75 # raza plina
	var idx := 0
	for i in SEG:
		var a0 := TAU * float(i) / SEG
		var a1 := TAU * float(i + 1) / SEG
		# Trei cercuri concentrice (interior gol, mijloc plin, exterior gol),
		# esantionate pe aceleasi doua unghiuri — 4 triunghiuri pe felie.
		var alphas: Array[float] = [0.0, 1.0, 0.0]
		var fracs: Array[float] = [RING_IN, RING_MID, 1.0]
		for k in 2:
			var f0: float = fracs[k]
			var f1: float = fracs[k + 1]
			var al0: float = alphas[k]
			var al1: float = alphas[k + 1]
			var p00 := Vector3(cos(a0) * rx * f0, 0.0, sin(a0) * rz * f0)
			var p01 := Vector3(cos(a1) * rx * f0, 0.0, sin(a1) * rz * f0)
			var p10 := Vector3(cos(a0) * rx * f1, 0.0, sin(a0) * rz * f1)
			var p11 := Vector3(cos(a1) * rx * f1, 0.0, sin(a1) * rz * f1)
			var quad: Array[Vector3] = [p00, p01, p11, p10]
			var quad_a: Array[float] = [al0, al0, al1, al1]
			for qi in 4:
				st.set_color(Color(1.0, 1.0, 1.0, quad_a[qi]))
				st.set_uv(Vector2(0.5, 0.5))
				st.set_uv2(Vector2(quad[qi].x, quad[qi].z))
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[qi])
			st.add_index(idx); st.add_index(idx + 1); st.add_index(idx + 2)
			st.add_index(idx); st.add_index(idx + 2); st.add_index(idx + 3)
			idx += 4
	return st.commit()


## Panza de ceata joasa: NU doar un dreptunghi plat pe XZ — de la inaltimea
## camerei de urmarire (privire aproape razanta pe un drum plat), o placa
## orizontala prezinta o suprafata de ecran aproape nula si e practic
## invizibila din masina, desi s-ar vedea perfect de sus. Aici e o "cortina"
## joasa: placa orizontala (pentru privirea de sus/apropiata) PLUS doua panze
## verticale joase incrucisate pe lungime (acelasi truc ca panzele perdelei —
## `cull_disabled`, se citesc din orice unghi), inalte `height` metri, care
## dau volumul vizibil de pe sosea. `reach` metri pe Z (lungimea culoarului).
##
## Alpha cade CONTINUU la zero pe toate laturile deschise — nu doar pe Z (spre
## capatul indepartat) ci si pe X (lateral) si sus (top): o placa care se
## opreste brusc pe o latura are silueta dreptunghiulara dura, exact defectul
## masurat pe prima varianta (o "lespede" alba vizibila de la distanta, in loc
## de ceata). Se topeste continuu, plina doar langa perdea (z mic) si in
## centrul benzii (x mic).
func _mist_mesh(hw: float, reach: float, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const NX := 4 # segmente pe latime (X)
	const NZ := 6 # segmente pe lungime (Z)
	var idx := 0

	# Alpha la un punct (u,v) in [0,1]x[0,1]: u=0 centru latime, u=1 margine
	# laterala; v=0 langa perdea (z mic), v=1 capat indepartat. Cade continuu
	# pe toate cele trei laturi deschise (lateral stanga, lateral dreapta,
	# capat indepartat); ramane plina spre v=0 (langa perdea).
	#
	# INGUSTARE spre capatul indepartat: drumul se poate curba pana la ~15
	# grade fata de orientarea FIXA a perdelei pe 20 m (perdeaua e aliniata
	# local, dar traseul nu e mereu drept), deci o banda LATA la capatul
	# indepartat s-ar desprinde vizibil de carosabil (masurat: o "lespede"
	# alba pe teren, langa drum, nu pe el). O banda care se ingusteaza intr-un
	# fir subtire spre capat ascunde exact deriva asta — un fir putin
	# deplasat lateral citeste ca abur, o placa lata deplasata citeste ca bug.
	var alpha_at = func(u: float, v: float) -> float:
		var lat_extent := lerpf(1.0, 0.35, v) # ingusteaza spre capatul indepartat
		var lat_fade := 1.0 - smoothstep(0.5 * lat_extent, 1.0 * lat_extent, absf(u))
		var far_fade := 1.0 - smoothstep(0.25, 0.9, v)
		return clampf(lat_fade * far_fade, 0.0, 1.0) * 0.7

	# Placa orizontala (Y=0, jos de tot): utila din unghiuri de sus/aproape,
	# grid NX x NZ ca fade-ul sa fie neted, nu doar pe cele 4 colturi.
	for zi in NZ:
		for xi in NX:
			var u0 := lerpf(-1.0, 1.0, float(xi) / NX)
			var u1 := lerpf(-1.0, 1.0, float(xi + 1) / NX)
			var v0 := float(zi) / NZ
			var v1 := float(zi + 1) / NZ
			var pts: Array[Vector3] = [
				Vector3(u0 * hw, 0.0, lerpf(-reach * 0.5, reach * 0.5, v0)),
				Vector3(u1 * hw, 0.0, lerpf(-reach * 0.5, reach * 0.5, v0)),
				Vector3(u1 * hw, 0.0, lerpf(-reach * 0.5, reach * 0.5, v1)),
				Vector3(u0 * hw, 0.0, lerpf(-reach * 0.5, reach * 0.5, v1))]
			var uv_a: Array[float] = [
				alpha_at.call(u0, v0), alpha_at.call(u1, v0),
				alpha_at.call(u1, v1), alpha_at.call(u0, v1)]
			for qi in 4:
				st.set_color(Color(1.0, 1.0, 1.0, uv_a[qi]))
				st.set_uv(Vector2(0.5, 0.5))
				st.set_uv2(Vector2(pts[qi].x, pts[qi].z))
				st.set_normal(Vector3.UP)
				st.add_vertex(pts[qi])
			st.add_index(idx); st.add_index(idx + 1); st.add_index(idx + 2)
			st.add_index(idx); st.add_index(idx + 2); st.add_index(idx + 3)
			idx += 4

	# Doua panze verticale JOASE, PARALELE cu drumul (normala pe X, intinse pe
	# Z), la doua offset-uri laterale — dau volumul vizibil de la nivelul
	# soferului, privind de-a lungul culoarului. Alpha cade la 0 sus (top) SI
	# spre capatul departat, plin jos si langa perdea; subimpartite pe Z ca
	# fade-ul sa fie neted.
	var cross_offsets: Array[float] = [-hw * 0.3, hw * 0.3]
	for ox in cross_offsets:
		var u_side := ox / hw
		for zi in NZ:
			var v0 := float(zi) / NZ
			var v1 := float(zi + 1) / NZ
			var z0 := lerpf(-reach * 0.5, reach * 0.5, v0)
			var z1 := lerpf(-reach * 0.5, reach * 0.5, v1)
			var pts2: Array[Vector3] = [
				Vector3(ox, 0.0, z0), Vector3(ox, 0.0, z1),
				Vector3(ox, height, z1), Vector3(ox, height, z0)]
			var a_bot0: float = alpha_at.call(u_side, v0)
			var a_bot1: float = alpha_at.call(u_side, v1)
			var uv_a2: Array[float] = [a_bot0, a_bot1, 0.0, 0.0]
			for qi in 4:
				st.set_color(Color(1.0, 1.0, 1.0, uv_a2[qi]))
				st.set_uv(Vector2(0.5, 0.5))
				st.set_uv2(Vector2(pts2[qi].x, pts2[qi].z))
				st.set_normal(Vector3.BACK)
				st.add_vertex(pts2[qi])
			st.add_index(idx); st.add_index(idx + 1); st.add_index(idx + 2)
			st.add_index(idx); st.add_index(idx + 2); st.add_index(idx + 3)
			idx += 4
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


## Explozia de spray (splash, brief pasul 3b): `one_shot`, spre in SUS SI
## LATERAL (spread mare, viteza mare fata de spray-ul continuu), gravitate
## reala, lifetime 0.6-1.2s. Acelasi material partajat (`spray_material()`) —
## zero materiale noi. `count` vine de la chemator: <=64 la Stirling, <=24 la
## o cascada de ploaie (brief pasul 3b).
func _spray_burst_node(size: Vector3, count: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "SprayBurst"
	p.amount = maxi(count, 1)
	p.lifetime = 1.2
	p.one_shot = true
	p.explosiveness = 0.85
	p.randomness = 0.5
	p.fixed_fps = 30
	p.emitting = false
	p.position = Vector3(0.0, 0.4, 0.0)
	p.visibility_aabb = AABB(
		Vector3(-size.x * 0.5 - 6.0, -1.0, -size.z * 0.5 - 6.0),
		Vector3(size.x + 12.0, 12.0, size.z + 12.0))
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(size.x * 0.5, 0.2, size.z * 0.5)
	pm.direction = Vector3(0.0, 1.0, 0.0)
	# Spread mare + directie predominant laterala fata de spray-ul continuu:
	# o EXPLOZIE se imprastie in lateral, nu doar in sus.
	pm.spread = 75.0
	pm.initial_velocity_min = 4.0
	pm.initial_velocity_max = 8.5
	# Gravitate REALA (brief pasul 3b): stropii cad inapoi, nu plutesc.
	pm.gravity = Vector3(0.0, -9.8, 0.0)
	pm.damping_min = 0.3
	pm.damping_max = 0.9
	pm.scale_min = 1.2
	pm.scale_max = 2.4
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.6))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_tex := CurveTexture.new()
	grow_tex.curve = grow
	pm.scale_curve = grow_tex
	pm.angle_min = -180.0
	pm.angle_max = 180.0
	pm.angular_velocity_min = -40.0
	pm.angular_velocity_max = 40.0
	pm.color = SPRAY_COLOR
	var fade := Gradient.new()
	fade.set_offsets(PackedFloat32Array([0.0, 0.15, 1.0]))
	fade.set_colors(PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)]))
	var fade_tex := GradientTexture1D.new()
	fade_tex.gradient = fade
	pm.color_ramp = fade_tex
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = spray_material()
	p.draw_pass_1 = quad
	return p


## Porneste explozia de spray o singura data (brief pasul 3b: cand o masina
## INTRA in perdea, nu la fiecare cadru cat timp sta sub ea). `restart()` pe
## un `GPUParticles3D` cu `one_shot=true` reia emisia de la zero — apelantul
## (`WaterfallHazard`) e responsabil sa nu cheme asta la fiecare cadru cat
## masina ramane inauntru (memoria `sonda-masura-alt-obiect`: un trigger care
## nu se opreste nu mai e o explozie, e un al doilea emitator continuu).
func trigger_splash_burst() -> void:
	if _spray_burst == null or not is_instance_valid(_spray_burst):
		return
	if _intensity <= 0.01:
		return
	_spray_burst.restart()
	_spray_burst.emitting = true
