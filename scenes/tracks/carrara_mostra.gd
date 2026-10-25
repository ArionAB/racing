extends Node3D
## TESTUL DE MOSTRA CARRARA (docs/track_briefs/carrara.md §7 pasul 0) — TEMPORAR, se scoate
## inainte de merge odata cu `Track23Mostra*.tscn`.
##
## Geometria sintetica a mostrei, construita in cod (nu GLB-uri): trei gradoni cu fete
## VERTICALE de 7 m pe clasa `carrara_marble`, un zid-contra la umbra, cuburi de marmura si
## balta opaca. Scena (`Track23Mostra.tscn` / `Track23MostraB.tscn`) pune doar nodul si
## alege clasa de marmura (`marble_class`): A = `carrara_marble`, B = `carrara_marble_real`.
## Camionul, fagii si ginestra sunt GLB-uri in `DecorManual` (au nevoie de WorldProp pentru
## remap-ul de sloturi si clasele pe tema).
##
## DE CE O FATA = UN MESH. Fiecare fata verticala e propriul `MeshInstance3D` cu nume
## (`FaceLit_*` = orientata spre soare, `FaceShade_*` = cu spatele la soare): asa
## `ProbeMasca --match=FaceLit` atribuie pixelii pe obiect, fara caseta (memoria
## `masca-de-obiect-prin-rasterizare`). Toate impart ACELASI material (clasa), deci nu costa
## materiale in plus. Geometria e minima: un quad cu 3 randuri de vertecsi (patina in
## vertex color pe treimea de jos, ca `MARBLE_GREY` din brief §4), zero subdiviziuni.
##
## SUPRAFETELE ORIZONTALE (terasele) iau materialul TERENULUI (acelasi `ShaderMaterial`, deci
## zero material nou) cu culoarea `theme_ground_tint`: praful e ce citeste "orizontal".
##
## ORIENTARE: nord = -Z. Soarele (azimut 30) vine din SE: fetele spre S (+Z) sunt luminate,
## cele spre N/V sunt in umbra. Fetele sunt 7 m peste cota de jos.

@export var marble_class: String = "carrara_marble"
## Cota apei bălții (y). Se seteaza din scena dupa masurarea terenului in punct.
@export var pool_y: float = 0.1
## Cota solului unde stau cuburile (masurata pe teren in scena).
@export var cube_y: float = 0.0
## A2 (runda 2): dungi de fir REGULATE pe fetele verticale — benzi orizontale de STRIPE_H metri,
## cu intunecare alternanta in vertex color (zero material nou).
@export var stripes: bool = false
## A2: cuburile in GRILA regulata, aliniata cu drumul, stive de 2, cateva cu o fata "taiata
## proaspat" (mai deschisa decat restul, care sunt intunecate de intemperii).
@export var block_grid: bool = false
## Cota solului pe care sta grila de blocuri (A2).
@export var grid_y: float = 0.0

const FACE_ROWS: int = 3
## Lungimea maxima a unui segment de fata / celula de terasa (m).
const SEG_M: float = 10.0
## Inaltimea unei benzi de dunga de fir (A2) si factorul LINIAR al benzii intunecate (~10% pe V
## dupa gama + tonemap; masurat: ~10% pe luminanta la 0.70). Vertex color doar intuneca (memoria surfacetool-clamp-vertex-color).
const STRIPE_H: float = 0.7
const STRIPE_DARK: float = 0.70
## Treimea de jos a fetei e patina (MARBLE_GREY amestecat spre alb).
const PATINA_MIX: float = 0.45
const PATINA_FRACTION: float = 0.35

# Gradonii: x in [0,80]; fata 1 la z=6.5 (7 m), fata 2 la z=-25 (14 m), fata 3 la z=-31
# (21 m). Fata 1 sta la 4.5 m de linia de mijloc dintre cele doua drumuri (z=2), acolo
# unde treapta naturala a terenului ajunge la cota drumului de jos (masurat cu sampler.ground_y).
const STACK_X0: float = 0.0
const STACK_X1: float = 80.0
const BENCH_TOPS: Array[float] = [7.0, 14.0, 21.0]
const BENCH_FACE_Z: Array[float] = [6.5, -25.0, -31.0]
const STACK_BACK_Z: float = -50.0
# Zidul-contra (fata N spre drumul de jos, in umbra): x in [0,60], z in [29,43], 9 m.
const CW_X0: float = 0.0
const CW_X1: float = 60.0
const CW_Z0: float = 29.0
const CW_Z1: float = 43.0
const CW_TOP: float = 9.0
const FOOT_Y: float = -3.0

var _marble: Material
var _dust: Material
var _body: StaticBody3D
var _ground_tint: Color = Color(0.8, 0.7, 0.55)


func _ready() -> void:
	# Tema pistei se aplica in `Track._ready()`, care ruleaza dupa copiii lui: tinta culorii
	# prafului si materialul terenului exista abia dupa.
	call_deferred("_build")


func _build() -> void:
	var track := get_parent() as Track
	if track != null:
		_ground_tint = track.theme_ground_tint
		var terr := track.get_node_or_null("TerrainBody/Terrain") as MeshInstance3D
		if terr != null:
			_dust = terr.material_override
	if _dust == null:
		var flat := StandardMaterial3D.new()
		flat.vertex_color_use_as_albedo = true
		flat.roughness = 0.95
		_dust = flat
	_marble = Palette.triplanar_class_material(marble_class)

	_body = StaticBody3D.new()
	_body.name = "MostraBody"
	if track != null:
		_body.collision_layer |= Track.CAMERA_BLOCKER_LAYER
	add_child(_body)

	if track != null:
		_hide_start_line(track)
	_build_stack()
	_build_counter_wall()
	_build_cubes()
	_build_pool()


## Linia de start in sah (alb 0.95 / negru 0.08) e un overlay de culoare plata pus
## neconditionat de `Track` pe punctul 0; nu e slot de paleta, dar e ALB, iar mostra masoara
## "nimic alb in cadru" (brief §0.1): se ascunde ca sa nu intre in cadrele de test. Cele doua
## mesh-uri se recunosc dupa gabarit (plat, < 20 m) si distanta fata de primul punct copt.
func _hide_start_line(track: Track) -> void:
	if track.baked.is_empty():
		return
	var p0: Vector3 = track.baked[0]
	var hidden := 0
	for child in track.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.mesh.get_aabb()
		if box.size.y < 0.3 and box.size.x < 20.0 and box.size.z < 20.0 				and (mi.global_transform * box.get_center()).distance_to(p0) < 8.0:
			mi.visible = false
			hidden += 1
	print("carrara_mostra: linia de start ascunsa (%d mesh-uri)" % hidden)


# ----------------------------------------------------------------- gradoni

func _build_stack() -> void:
	var x0 := STACK_X0
	var x1 := STACK_X1
	for i in 3:
		var top := BENCH_TOPS[i]
		var fz := BENCH_FACE_Z[i]
		var low := FOOT_Y if i == 0 else BENCH_TOPS[i - 1] - 0.5
		var tag := "B%d" % (i + 1)
		# Fata dinspre S (lumina). Terasa din spatele ei: pana la fata urmatoare (sau spatele).
		var back_z: float = BENCH_FACE_Z[i + 1] if i < 2 else STACK_BACK_Z
		_face("FaceLit_%sS" % tag, Vector2(x0, fz), Vector2(x1, fz), low, top, Vector3(0, 0, 1))
		# Capetele: E (luminat usor), V (in umbra). De la picior (FOOT_Y), ca peretele sa
		# acopere toata cutia, inclusiv partea de sub gradonii din spate.
		_face("FaceLit_%sE" % tag, Vector2(x1, fz), Vector2(x1, back_z), FOOT_Y, top,
				Vector3(1, 0, 0))
		_face("FaceShade_%sW" % tag, Vector2(x0, fz), Vector2(x0, back_z), FOOT_Y, top,
				Vector3(-1, 0, 0))
		# Terasa: ceva sub cota drumului (drumul T1 sta la 7.0 si acopera), ca praful drumului
		# sau al terenului sa nu faca z-fighting cu ea.
		_top("Terasa_%s" % tag, x0, x1, back_z, fz, top - 0.08)
		# Corpul fizic: cutie plina de la picior pana la terasa.
		_box_collider(Vector3((x0 + x1) * 0.5, (low + top) * 0.5, (fz + back_z) * 0.5),
				Vector3(x1 - x0, top - low, absf(fz - back_z)))


func _build_counter_wall() -> void:
	var low := FOOT_Y
	_face("FaceShade_CW_N", Vector2(CW_X0, CW_Z0), Vector2(CW_X1, CW_Z0), low, CW_TOP,
			Vector3(0, 0, -1))
	_face("FaceLit_CW_E", Vector2(CW_X1, CW_Z0), Vector2(CW_X1, CW_Z1), low, CW_TOP,
			Vector3(1, 0, 0))
	_face("FaceShade_CW_W", Vector2(CW_X0, CW_Z0), Vector2(CW_X0, CW_Z1), low, CW_TOP,
			Vector3(-1, 0, 0))
	_top("Terasa_CW", CW_X0, CW_X1, CW_Z0, CW_Z1, CW_TOP - 0.08)
	_box_collider(Vector3((CW_X0 + CW_X1) * 0.5, (low + CW_TOP) * 0.5, (CW_Z0 + CW_Z1) * 0.5),
			Vector3(CW_X1 - CW_X0, CW_TOP - low, CW_Z1 - CW_Z0))


# ------------------------------------------------------------------ cuburi

## Cuburi de marmura (1.5-3 m) stivuite langa drum, la est de zidul-contra, in soare.
func _build_cubes() -> void:
	if block_grid:
		_build_block_grid()
		return
	# (x, z, latura, yaw grade, cota de sus a stivei pe care sta: 0 = pe sol)
	var cubes: Array[Vector4] = [
		Vector4(66.0, 26.5, 3.0, 8.0),
		Vector4(70.0, 27.0, 2.4, -12.0),
		Vector4(73.5, 26.0, 2.0, 20.0),
		Vector4(66.5, 26.6, 2.2, 15.0),   # peste primul (stivuit)
		Vector4(70.2, 27.0, 1.6, -5.0),   # peste al doilea
		Vector4(77.0, 28.0, 2.8, 4.0),
		Vector4(77.2, 28.0, 1.8, -20.0),  # peste al saselea
		Vector4(63.5, 31.5, 1.5, 30.0),
	]
	# Care cub sta peste care (indexul cubului de dedesubt), -1 = pe sol.
	var on: Array[int] = [-1, -1, -1, 0, 1, -1, 5, -1]
	var base_y: Array[float] = []
	var heights: Array[float] = []
	for i in cubes.size():
		heights.append(cubes[i].z)
		base_y.append(0.0)
	for i in cubes.size():
		var below := on[i]
		base_y[i] = 0.0 if below < 0 else base_y[below] + heights[below]
	var ground := cube_y
	for i in cubes.size():
		var c := cubes[i]
		var mi := MeshInstance3D.new()
		mi.name = "Cub_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(c.z, c.z, c.z)
		mi.mesh = bm
		mi.material_override = _marble
		mi.position = Vector3(c.x, ground + base_y[i] + c.z * 0.5, c.y)
		mi.rotation_degrees.y = c.w
		add_child(mi)
		var col := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bm.size
		col.shape = bs
		col.transform = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(c.w), 0)),
				mi.position)
		_body.add_child(col)


## A2: grila de blocuri 2.6-3 m, doua randuri aliniate cu drumul (axa X), stive de 2 pe unele
## coloane. Blocurile sunt intunecate de intemperii (0.80 liniar); 5 au fetele +X si -Z (cele pe
## care le vede soferul) taiate proaspat: alb curat.
func _build_block_grid() -> void:
	var rows: Array[float] = [26.5, 30.4]
	var sizes: Array[float] = [3.0, 2.8, 2.6, 3.0, 2.8, 2.6, 3.0]
	var stack_on: Array[int] = [1, 3, 4, 6, 2]   # coloane care primesc un bloc deasupra
	var fresh: Array[int] = [0, 3, 8, 10, 12]    # indici (in ordinea de creare) cu fata proaspata
	var k := 0
	var made: Array[Vector3] = []
	for r in rows.size():
		for i in sizes.size():
			var sz := sizes[(i + r) % sizes.size()]
			var cx := 62.0 + float(i) * 3.7
			made.append(Vector3(cx, rows[r], sz))
			_grid_cube(k, Vector3(cx, grid_y + sz * 0.5, rows[r]), sz, k in fresh)
			k += 1
			if (i in stack_on and r == 0) or (i in [0, 5] and r == 1):
				var up_sz := 2.4
				_grid_cube(k, Vector3(cx, grid_y + sz + up_sz * 0.5, rows[r]), up_sz, k in fresh)
				k += 1
	print("carrara_mostra: grila de blocuri: %d cuburi" % k)


func _grid_cube(k: int, center: Vector3, side: float, fresh: bool) -> void:
	var weathered := Color(0.80, 0.80, 0.80)
	var cols := PackedColorArray([weathered, weathered, Color.WHITE, weathered,
		weathered, weathered])
	if fresh:
		cols[0] = Color.WHITE   # +X
		cols[5] = Color.WHITE   # -Z
	var mi := MeshInstance3D.new()
	mi.name = "Cub_%d" % k
	mi.mesh = _cube_mesh(side, cols)
	mi.material_override = _marble
	mi.position = center
	add_child(mi)
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(side, side, side)
	col.shape = bs
	col.position = center
	_body.add_child(col)


# -------------------------------------------------------------------- balta

## Balta de marmettola: un quad plat OPAC pe slotul REEF_SHALLOW (17), brief §4. Fara shader
## de apa. 15 x 10 m, in soare, la capatul estic al pistei (imediat dupa hairpin-ul de est).
func _build_pool() -> void:
	var cx := 95.5
	var cz := 32.0
	var hx := 7.5
	var hz := 5.0
	var mi := MeshInstance3D.new()
	mi.name = "Balta"
	var uv := Palette.uv(Palette.REEF_SHALLOW)
	var verts := PackedVector3Array([
		Vector3(cx - hx, pool_y, cz - hz), Vector3(cx + hx, pool_y, cz - hz),
		Vector3(cx + hx, pool_y, cz + hz), Vector3(cx - hx, pool_y, cz + hz)])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var colors := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	var uvs := PackedVector2Array([uv, uv, uv, uv])
	var idx := PackedInt32Array([0, 1, 2, 0, 2, 3])
	mi.mesh = _array_mesh(verts, normals, colors, uvs, idx)
	mi.material_override = Palette.world_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# ----------------------------------------------------------------- helpere

## O fata verticala: de la `a` la `b` (in XZ), de la `y0` la `y1`, cu normala `n`. Ordinea
## capetelor se potriveste singura la sensul de infasurare (fata vazuta din exterior).
##
## Fata se rupe pe orizontala in segmente de cel mult SEG_M metri: un quad de 80 m care trece
## pe langa camera are triunghiuri ce intersecteaza planul apropiat, iar rasterizatorul
## software din `ProbeMasca` nu decupeaza (le arunca) — fata ar iesi 0 pixeli in masca,
## desi se vede in cadru. Costul e neglijabil (8 segmente x 3 randuri = 48 de triunghiuri).
func _face(mesh_name: String, a: Vector2, b: Vector2, y0: float, y1: float,
		n: Vector3) -> void:
	var right := Vector3.UP.cross(n)
	var pa := Vector3(a.x, 0.0, a.y)
	var pb := Vector3(b.x, 0.0, b.y)
	if (pb - pa).dot(right) < 0.0:
		var t := pa
		pa = pb
		pb = t
	var segs := maxi(1, ceili((pb - pa).length() / SEG_M))
	if stripes:
		_face_striped(mesh_name, pa, pb, y0, y1, n, segs)
		return
	var cols_n := segs + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var patina := Palette.color(Palette.MARBLE_GREY).lerp(Color.WHITE, PATINA_MIX)
	for r in FACE_ROWS:
		var f := float(r) / float(FACE_ROWS - 1)
		var y := lerpf(y0, y1, f)
		# Randul 0 = piciorul (patina); celelalte = alb (marmura curata).
		var col := Color.WHITE
		if r == 0:
			col = patina
		for c in cols_n:
			var p := pa.lerp(pb, float(c) / float(segs))
			verts.append(Vector3(p.x, y, p.z))
			normals.append(n)
			colors.append(col)
			uvs.append(Vector2.ZERO)
	var idx := PackedInt32Array()
	for r in FACE_ROWS - 1:
		for c in segs:
			var i0 := r * cols_n + c          # jos-stanga
			var i1 := i0 + 1                  # jos-dreapta
			var i2 := i0 + cols_n             # sus-stanga
			var i3 := i2 + 1                  # sus-dreapta
			# In sensul acelor de ceasornic, vazut din exterior.
			idx.append_array([i0, i2, i3, i0, i3, i1])
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = _array_mesh(verts, normals, colors, uvs, idx)
	mi.material_override = _marble
	add_child(mi)


## Varianta A2 a fetei: benzi orizontale de STRIPE_H m, fiecare un strat de culoare plata (vertecsi
## dubli la muchie, ca benzile sa aiba muchie crunta, nu gradient Gouraud). Benzile impare sunt mai
## inchise; treimea de jos poarta in plus patina (ca in varianta fara dungi).
func _face_striped(mesh_name: String, pa: Vector3, pb: Vector3, y0: float, y1: float,
		n: Vector3, segs: int) -> void:
	var cols_n := segs + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var patina := Palette.color(Palette.MARBLE_GREY).lerp(Color.WHITE, PATINA_MIX)
	var h := y1 - y0
	var bands := maxi(1, ceili(h / STRIPE_H))
	for b in bands:
		# Benzile se numara de SUS in jos, ca modelul sa fie acelasi indiferent de picior.
		var ya := y1 - float(b + 1) * STRIPE_H
		var yb := y1 - float(b) * STRIPE_H
		ya = maxf(ya, y0)
		var shade := STRIPE_DARK if (b % 2) == 1 else 1.0
		var col := Color(shade, shade, shade)
		if (ya - y0) < h * PATINA_FRACTION:
			col = Color(col.r * patina.r, col.g * patina.g, col.b * patina.b)
		var base := verts.size()
		for yy in [ya, yb]:
			for c in cols_n:
				var p := pa.lerp(pb, float(c) / float(segs))
				verts.append(Vector3(p.x, yy, p.z))
				normals.append(n)
				colors.append(col)
				uvs.append(Vector2.ZERO)
		for c in segs:
			var i0 := base + c
			var i1 := i0 + 1
			var i2 := i0 + cols_n
			var i3 := i2 + 1
			idx.append_array([i0, i2, i3, i0, i3, i1])
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = _array_mesh(verts, normals, colors, uvs, idx)
	mi.material_override = _marble
	add_child(mi)


## Cub cu culoare de vertex PE FATA (A2): `face_cols` = +X, -X, +Y, -Y, +Z, -Z.
func _cube_mesh(side: float, face_cols: PackedColorArray) -> ArrayMesh:
	var h := side * 0.5
	var dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
		Vector3.BACK, Vector3.FORWARD]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for f in 6:
		var nrm := dirs[f]
		var up := Vector3.UP if absf(nrm.y) < 0.5 else Vector3.FORWARD
		var right := up.cross(nrm)
		var base := verts.size()
		# stanga-jos, stanga-sus, dreapta-sus, dreapta-jos (vazut din exterior)
		for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1)]:
			verts.append(nrm * h + right * corner.x * h + up * corner.y * h)
			normals.append(nrm)
			colors.append(face_cols[f])
			uvs.append(Vector2.ZERO)
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	return _array_mesh(verts, normals, colors, uvs, idx)


## O suprafata orizontala (terasa) cu materialul terenului si culoarea prafului. Celule de
## cel mult SEG_M metri (acelasi motiv ca la `_face`).
func _top(mesh_name: String, x0: float, x1: float, z0: float, z1: float, y: float) -> void:
	var zn := minf(z0, z1)
	var zf := maxf(z0, z1)
	var nx := maxi(1, ceili((x1 - x0) / SEG_M))
	var nz := maxi(1, ceili((zf - zn) / SEG_M))
	var c := _ground_tint
	c.a = 0.0 # a = greutatea de iarba in shader-ul terenului: 0 = nisip/praf
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var uvs2 := PackedVector2Array()
	for iz in nz + 1:
		for ix in nx + 1:
			var v := Vector3(lerpf(x0, x1, float(ix) / float(nx)), y,
					lerpf(zn, zf, float(iz) / float(nz)))
			verts.append(v)
			normals.append(Vector3.UP)
			colors.append(c)
			uvs.append(Vector2(v.x, v.z) * Track.SURFACE_TILING)
			uvs2.append(Vector2(v.x, v.z) * Track.SURFACE_TILING_MACRO)
	var idx := PackedInt32Array()
	for iz in nz:
		for ix in nx:
			var tl := iz * (nx + 1) + ix
			var tr := tl + 1
			var bl := tl + nx + 1
			var br := bl + 1
			# Sus, in sensul acelor de ceasornic (x spre dreapta, z spre jos pe ecran).
			idx.append_array([tl, tr, br, tl, br, bl])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uvs2
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = m
	mi.material_override = _dust
	add_child(mi)


func _array_mesh(verts: PackedVector3Array, normals: PackedVector3Array,
		colors: PackedColorArray, uvs: PackedVector2Array,
		idx: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


func _box_collider(center: Vector3, size: Vector3) -> void:
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	col.shape = bs
	col.position = center
	_body.add_child(col)
