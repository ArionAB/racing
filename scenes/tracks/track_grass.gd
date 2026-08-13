class_name TrackGrass
extends RefCounted
## Iarba DENSA de margine: smocuri de fire din geometrie opaca, pe banda de
## langa asfalt. Prototipul directiei "pajistea se vede fir cu fir" (referinta:
## randarea promo a kitului de animale — iarba de acolo e geometrie solida
## low-poly, nu billboard-uri).
##
## DE CE GEOMETRIE SI NU QUAD-URI CU TEXTURA ALPHA: GPU-urile mobile (tile-based)
## platesc scump alpha testing + overdraw — mii de quad-uri semi-transparente
## suprapuse sunt exact clasa de fill rate care pica 60fps, chiar daca numarul de
## triunghiuri pare mic. Firele solide costa doar vertecsi, adica axa pe care
## CLAUDE.md a decis explicit ca ne permitem s-o ingreunam.
##
## TRUCUL DE LUMINA care vinde tot: normalele TUTUROR vertecsilor sunt UP.
## Firele nu se umbresc ca niste placi verticale (fete intunecate spre camera),
## ci ca solul pe care stau — covorul citeste moale si uniform, ca in referinta.
## E trucul standard de iarba stilizata, gratis.
##
## VANTUL e in vertex shader, nu in [SwayDriver]: driverul CPU rescrie bufferul
## MultiMesh la fiecare cadru si are plafon de 240 de instante — aici sunt mii.
## Shaderul misca varfurile gratis, cu faza din pozitia in lume (rafale care
## trec prin peisaj, ca la SwayDriver).
##
## MATERIAL: unul singur, partajat, pentru toata iarba din joc — o clasa de
## assets cu material propriu, decizie explicita in sensul regulii din
## CLAUDE.md (ca foliage_material si rock_material). Culoarea vine din
## ground_tint-ul temei, deci fiecare lume isi coloreaza singura iarba.
##
## CHUNK-URI: un MultiMesh pe celula de 40 m, cu visibility_range — un buffer pe
## toata pista ar trimite la GPU si iarba din spatele camerei (aceeasi lectie ca
## TrackDecorBatch). Dincolo de MELT_END firele se "topesc" in teren din shader
## (inaltimea scade la zero), iar textura pictata de pe sol preia culoarea —
## deci taierea celulei nu se vede niciodata ca pop.
##
## FARA COLIZIUNE, FARA UMBRE ARUNCATE: strat strict vizual.

## Banda: de la cati metri de marginea asfaltului incepe iarba...
const BAND_MIN: float = 0.35
## ...pana unde tine zona DEASA (cea pe care chase cam-ul o vede fir cu fir)...
const BAND_NEAR: float = 3.5
## ...si pana unde se rareste spre textura pictata a terenului.
const BAND_MAX: float = 7.0

## Smocuri pe metru de sosea, PE O PARTE, in zona deasa / in cea rarita.
## Astea doua sunt butoanele de buget: densitatea vizuala si numarul total de
## triunghiuri scaleaza liniar cu ele. Prima incercare (2.5 / 0.9, fire de
## 6 cm latime) a iesit buruieni razlete, nu covor — de la chase cam firele
## trebuie sa fie LATE si INDESATE ca sa se citeasca unele peste altele.
## Aproape-uniform pe toata banda: un raport mare dens/rar face banda departata
## sa citeasca a camp gol si tot efectul devine un "franj" pe buza asfaltului.
const NEAR_PER_M: float = 7.0
const FAR_PER_M: float = 3.5

## Firele unui smoc si raza lui la scara 1. Un smoc = FIRE * 2 triunghiuri.
## Mai multe fire IN smoc e cel mai ieftin buton de desime: nu costa nici
## plasare, nici ground_y, doar triunghiuri — iar smocul plin citeste a covor.
const BLADES: int = 12
const PATCH_RADIUS: float = 0.50

## Latura celulei de MultiMesh. Mai mica decat la TrackDecorBatch (250 m):
## iarba are taiere de distanta agresiva, deci celule mici chiar economisesc.
const CELL_M: float = 40.0

## De unde incepe topirea in teren si unde e completa (distanta de camera, m).
const MELT_START: float = 68.0
const MELT_END: float = 86.0

## Smocul se ingroapa putin: grila terenului e la ~8 m, deci intre noduri cota
## reala difera de ground_y — baza scufundata ascunde si plutirea, si topirea.
const SINK: float = 0.06

## Cat de aproape de o banda secundara (scurtatura, poteca) NU creste iarba.
const CORRIDOR_CLEAR: float = 5.0

## Pe cati metri sub plafonul de altitudine se rareste iarba pana la zero.
const ALT_FADE: float = 10.0

static var _material: ShaderMaterial

const _SHADER: String = "
shader_type spatial;
render_mode cull_disabled, specular_disabled;

// Vantul: amplitudine mica — o adiere care trece, nu o furtuna (aceeasi
// filozofie ca SwayDriver.AMPLITUDE).
uniform float sway_amp = 0.10;
uniform float sway_freq = 1.6;
uniform float melt_start = 68.0;
uniform float melt_end = 86.0;

varying float tint;

void vertex() {
	vec3 wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Varfurile se leagana, baza sta: COLOR.a e 0 la sol si 1 la varf.
	float w = COLOR.a * COLOR.a;
	float phase = (wpos.x + wpos.z) * 0.35;
	float s = sin(TIME * sway_freq + phase)
		+ 0.35 * sin(TIME * sway_freq * 2.7 + phase * 1.7);
	VERTEX.x += s * sway_amp * w;
	VERTEX.z += s * sway_amp * 0.6 * w;
	// Topirea cu distanta: firele se scufunda in teren in loc sa dispara
	// dintr-o data — textura pictata a solului preia culoarea de acolo.
	float dcam = distance(wpos, CAMERA_POSITION_WORLD);
	VERTEX.y *= 1.0 - smoothstep(melt_start, melt_end, dcam);
	// Variatie de nuanta PER SMOC, din pozitia instantei: un covor din acelasi
	// mesh repetat de mii de ori ar citi ca gazon de plastic fara ea.
	vec2 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xz;
	tint = 0.88 + 0.24 * fract(sin(dot(o, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	ALBEDO = COLOR.rgb * tint;
	ROUGHNESS = 1.0;
}
"


## Construieste covorul de iarba. Intoarce radacina cu celulele de MultiMesh.
##
## `max_y`: plafonul de altitudine (in lume) peste care iarba nu mai creste —
## pe Alpi pajistea se opreste unde incepe etajul de stanca. 1e9 = fara plafon.
static func build(sampler: TrackSideSampler, world_seed: int,
		ground_tint: Color, max_y: float = 1e9) -> Node3D:
	var root := Node3D.new()
	root.name = "DenseGrass"
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed ^ 0x6772A55  # sa nu repete sirul rng al decorului

	var mesh := _patch_mesh(rng, ground_tint)

	# Benzile secundare (scurtatura prin iarba, poteci), intr-un cos spatial:
	# verificarea "sunt pe poteca?" per smoc devine O(1), nu O(n).
	var corridor := _bucket(sampler.extra_points())

	# Plasarea: pe indecsii curbei coapte (~3 m intre puncte), cate o mana de
	# smocuri pe fiecare parte, cu numarul scalat de lungimea segmentului.
	# Usoara indesire in viraje (punctele coapte se strang acolo) — inofensiva,
	# chiar placuta: virajele sunt unde te uiti.
	var cells := {}
	var n := sampler.point_count()
	var placed := 0
	for i in n:
		var a := sampler.baked_point(i)
		var b := sampler.baked_point((i + 1) % n)
		var seg := a.distance_to(b)
		if seg <= 0.0:
			continue
		var along := (b - a) / seg
		var side_v := sampler.side_at(i)
		var hw := sampler.half_width_at(i)
		var frac := float(i) / float(n)
		for side_sign: float in [-1.0, 1.0]:
			# Buza de rapa/cornisa ramane piatra, nu pajiste.
			if sampler.ravine_at(frac, side_sign):
				continue
			var side := side_v * side_sign
			placed += _scatter(cells, sampler, rng, corridor, max_y,
				a, along, side, hw, seg, NEAR_PER_M, BAND_MIN, BAND_NEAR)
			placed += _scatter(cells, sampler, rng, corridor, max_y,
				a, along, side, hw, seg, FAR_PER_M, BAND_NEAR, BAND_MAX)

	_emit_cells(root, cells, mesh)
	root.set_meta(&"grass_patches", placed)
	return root


## Materialul UNIC al ierbii (vezi antetul: clasa de assets cu material propriu).
static func material() -> ShaderMaterial:
	if _material == null:
		var sh := Shader.new()
		sh.code = _SHADER
		_material = ShaderMaterial.new()
		_material.shader = sh
		_material.set_shader_parameter("melt_start", MELT_START)
		_material.set_shader_parameter("melt_end", MELT_END)
	return _material


## Imprastie smocurile unei benzi pe segmentul curent. Intoarce cate a pus.
static func _scatter(cells: Dictionary, sampler: TrackSideSampler,
		rng: RandomNumberGenerator, corridor: Dictionary, max_y: float,
		a: Vector3, along: Vector3, side: Vector3, hw: float, seg: float,
		per_m: float, off_min: float, off_max: float) -> int:
	# Numarul fractionar se rotunjeste STOCASTIC, altfel segmentele scurte din
	# viraje n-ar primi niciodata nimic si banda ar avea gauri exact pe arc.
	var want := per_m * seg
	var count := int(want) + (1 if rng.randf() < want - float(int(want)) else 0)
	var placed := 0
	for _k in count:
		var off := rng.randf_range(off_min, off_max)
		var p := a + along * rng.randf_range(0.0, seg) + side * (hw + off)
		if _near_corridor(corridor, p.x, p.z):
			continue
		# Paraul si malurile lui raman fara iarba (smocul si-ar lua cota din
		# ground_y si ar creste de pe fundul albiei, cu varful prin apa).
		if sampler.channel_mix(p.x, p.z) > 0.25:
			continue
		var y := sampler.ground_y(p.x, p.z)
		# Plafonul de altitudine, cu rarire pe ALT_FADE metri sub el: limita
		# pajistii e o zona, nu o linie (aceeasi lectie ca snow_fade).
		var over := (y - (max_y - ALT_FADE)) / ALT_FADE
		if over > 0.0 and rng.randf() < over:
			continue
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
			Vector3(rng.randf_range(0.85, 1.15), rng.randf_range(0.75, 1.35),
				rng.randf_range(0.85, 1.15)))
		var xf := Transform3D(basis, Vector3(p.x, y - SINK, p.z))
		var key := Vector2i(int(floor(p.x / CELL_M)), int(floor(p.z / CELL_M)))
		if not cells.has(key):
			cells[key] = [] as Array[Transform3D]
		(cells[key] as Array).append(xf)
		placed += 1
	return placed


## Varsa celulele in MultiMeshInstance3D-uri, cu originea nodului in centrul
## celulei — visibility_range masoara distanta pana la ORIGINEA nodului, deci
## un nod cu originea in (0,0,0) global nu s-ar taia niciodata corect.
static func _emit_cells(root: Node3D, cells: Dictionary, mesh: Mesh) -> void:
	for key: Vector2i in cells:
		var xforms: Array = cells[key]
		var center := Vector3((float(key.x) + 0.5) * CELL_M, 0.0,
			(float(key.y) + 0.5) * CELL_M)
		var sum_y := 0.0
		for xf: Transform3D in xforms:
			sum_y += xf.origin.y
		center.y = sum_y / float(xforms.size())
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xforms.size()
		for i in xforms.size():
			var xf: Transform3D = xforms[i]
			xf.origin -= center
			mm.set_instance_transform(i, xf)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grass_%d_%d" % [key.x, key.y]
		mmi.multimesh = mm
		mmi.material_override = material()
		mmi.position = center
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Dincolo de topirea din shader nu mai e nimic de desenat. Marja de
		# jumatate de diagonala de celula: distanta se masoara la originea
		# nodului, iar un smoc din coltul apropiat e cu ~28 m mai aproape.
		mmi.visibility_range_end = MELT_END + CELL_M * 0.71
		# Leganarea misca varfurile putin in afara AABB-ului static.
		mmi.extra_cull_margin = 0.5
		root.add_child(mmi)


## Mesh-ul unui smoc: BLADES fire, fiecare un "zmeu" din 2 triunghiuri — baza
## lata, varf ciupit, aplecat intr-o directie proprie. Vertex colors: gradient
## baza intunecata -> varf deschis (culoarea vine de aici, nu din textura),
## alpha = fractia de inaltime (greutatea vantului in shader).
static func _patch_mesh(rng: RandomNumberGenerator, tint: Color) -> ArrayMesh:
	# Mai SATURAT decat solul, nu doar mai inchis/deschis: firele stau PESTE
	# textura pictata a terenului, iar daca au aceeasi croma se pierd in ea —
	# prima incercare (varfuri spre galben-pai) iesea buruieni uscate, invizibile
	# pe fundalul oliv. Referinta are verde plin, cu baza in umbra.
	var base_col := Color(tint.r * 0.28, tint.g * 0.46, tint.b * 0.28, 0.0)
	var tip_col := Color(tint.r * 0.85, minf(tint.g * 1.18 + 0.03, 1.0),
		tint.b * 0.50, 1.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for _b in BLADES:
		var ang := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * PATCH_RADIUS
		var base := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		# Fire INALTE si LATE — geometrie de dioramă, nu gazon realist: de la
		# inaltimea chase cam-ului un fir de 6 cm latime dispare; la 12-18 cm
		# firele se suprapun si abia atunci citesc a covor.
		var h := rng.randf_range(0.40, 0.70)
		var lean_ang := rng.randf_range(0.0, TAU)
		# Aproape verticale: cu aplecare mare smocul iese "stea de mare" si
		# covorul citeste tepos; referinta are fire drepte, doar cu varful dus.
		var lean := rng.randf_range(0.03, 0.12)
		var face_ang := rng.randf_range(0.0, TAU)
		var half_w := rng.randf_range(0.055, 0.09)
		var perp := Vector3(cos(face_ang), 0.0, sin(face_ang))
		var tip := base + Vector3(cos(lean_ang) * lean, h, sin(lean_ang) * lean)
		# Firele de la margine putin mai scunde: smocul iese boltit, nu tuns.
		tip.y *= 1.0 - 0.35 * (r / PATCH_RADIUS)
		# O idee spre galben pe alocuri: "fan tanar", nu gazon de plastic.
		var tc := tip_col.lerp(Color(0.78, 0.80, 0.28, 1.0), rng.randf() * 0.12)
		var v0 := base - perp * half_w
		var v1 := base + perp * half_w
		var v2 := tip + perp * half_w * 0.18
		var v3 := tip - perp * half_w * 0.18
		# Normala UP pe TOT firul — vezi antetul.
		st.set_normal(Vector3.UP)
		st.set_color(base_col); st.add_vertex(v0)
		st.set_color(base_col); st.add_vertex(v1)
		st.set_color(tc); st.add_vertex(v2)
		st.set_color(base_col); st.add_vertex(v0)
		st.set_color(tc); st.add_vertex(v2)
		st.set_color(tc); st.add_vertex(v3)
	return st.commit()


## Cosul spatial al punctelor de coridor secundar (celule de CORRIDOR_CLEAR m).
static func _bucket(points: PackedVector3Array) -> Dictionary:
	var out := {}
	for p in points:
		var key := Vector2i(int(floor(p.x / CORRIDOR_CLEAR)),
			int(floor(p.z / CORRIDOR_CLEAR)))
		if not out.has(key):
			out[key] = [] as Array[Vector2]
		(out[key] as Array).append(Vector2(p.x, p.z))
	return out


## E punctul la sub CORRIDOR_CLEAR metri de o banda secundara? Se uita doar in
## celula lui si in cele 8 vecine — restul sunt garantat prea departe.
static func _near_corridor(buckets: Dictionary, x: float, z: float) -> bool:
	if buckets.is_empty():
		return false
	var cx := int(floor(x / CORRIDOR_CLEAR))
	var cz := int(floor(z / CORRIDOR_CLEAR))
	var clear_sq := CORRIDOR_CLEAR * CORRIDOR_CLEAR
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var key := Vector2i(cx + dx, cz + dz)
			if not buckets.has(key):
				continue
			for p: Vector2 in buckets[key]:
				var ex := p.x - x
				var ez := p.y - z
				if ex * ex + ez * ez < clear_sq:
					return true
	return false
