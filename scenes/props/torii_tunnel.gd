class_name ToriiTunnel
extends Node3D
## TUNELUL DE TORII (Kyoto, Track18, POI E-prim, brief kyoto.md §2.0 / §3 / §5.6).
##
## Se ancoreaza la banda reala `Track.routes[branch_index]` (acelasi tipar ca
## [AlleyGate]/[CowGate]: ruta coapta exista abia dupa `rebuild()`, deci se
## amana pana apare). [FlockProp] lipeste de TEREN, nu de banda — de aceea
## portile nu pot fi un FlockProp scris de generator: aici pozitiile se CALCULEAZA
## din curba benzii, apoi se predau unor [FlockProp] (MultiMesh) copii.
##
## Ce construieste:
##  1. [b]Portile[/b]: una la `spacing` (1,2 m) pe curba benzii, perpendiculara
##     pe tangenta. Golul dintre ele (spacing - grosimea portii) e mai ingust
##     decat stalpul, ca in realitate: tunelul se citeste ca un perete de
##     stalpi, nu ca o succesiune de ferestre cu cer (ProbeFlicker, §3.2).
##  2. [b]Peretii colizori[/b]: UN trimesh continuu pe fiecare parte, nu 250 de
##     stalpi. Frecare mare, ricoseu mic: atingerea te incetineste, nu te opreste.
##  3. [b]Padurea[/b]: doua randuri de cedri in spatele portilor, pe ambele
##     parti, ca golurile sa dea in umbra si nu in cer (regula de arta: ritmul
##     tunelului e de culoare, nu de luminanta).
##  4. [b]Portile mari[/b] la gura si la iesire.
##
## Tronsonul tunelului e doar unde banda e DEPARTE de bucla principala: capetele
## ei sunt racorduri pe axa soselei, iar o poarta acolo ar sta pe asfalt.
## Nodul trebuie sa stea sub pista, cu transformare identitate (pozitiile sunt
## in coordonatele pistei, iar FlockProp isi pune instantele in coordonate de lume).

@export var branch_index: int = 1
@export var gate_scene: PackedScene = null
@export var large_gate_scene: PackedScene = null
@export var cedar_scene: PackedScene = null
## Pasul portilor pe curba (m). Adancimea portii e 0,7, deci golul e 0,5.
@export_range(0.6, 6.0, 0.05, "suffix:m") var spacing: float = 1.2
## Jumatatea culoarului liber (m): fata interioara a stalpilor.
@export_range(2.0, 6.0, 0.05, "suffix:m") var half_gap: float = 3.2
## Cat de departe de axa buclei principale (peste jumatatea latimii soselei)
## trebuie sa fie banda ca sa inceapa tunelul: jumatatea portii mari + marja.
@export_range(0.0, 30.0, 0.5, "suffix:m") var main_clear_m: float = 14.0
## Gura peretilor se LATESTE (palnie): pe primii `flare_len` metri laterala creste
## cu `flare_out`. Masurat cu ProbeRace: cu zidul taiat drept la gura, masinile care
## taie coltul dinspre sosea (banda se desprinde in unghi de ~37 grade) dau cu botul
## in capatul peretelui si raman acolo; palnia le plimba spre axa.
@export_range(0.0, 20.0, 0.5, "suffix:m") var flare_len: float = 14.0
@export_range(0.0, 10.0, 0.1, "suffix:m") var flare_out: float = 8.0
## Poarta mare + bulevardul: pornesc de unde banda e la `gate_clear_m` de marginea
## buclei (jumatatea portii mari 5,5 + marja), adica LA furca, nu 22 m mai in
## spate. Intre ea si gura tunelului stau porti rare (fara perete), din `avenue_gap`
## in `avenue_gap` metri: se vad de pe sosea si cheama.
@export_range(0.0, 20.0, 0.5, "suffix:m") var gate_clear_m: float = 9.4
## Scara portii mari: de pe sosea, de la 100-150 m, o poarta de 8 m ocupa cativa pixeli.
@export_range(1.0, 2.5, 0.05) var big_scale: float = 1.6
@export_range(1.2, 6.0, 0.1, "suffix:m") var avenue_gap: float = 2.0
## Doua vulpi de piatra (placeholder) de o parte si de alta a portii mari.
@export var foxes_enabled: bool = true
@export var wall_height: float = 6.0
@export var wall_friction: float = 1.0
@export var wall_bounce: float = 0.1
## Padurea: lateral fata de axa (m) pentru cele doua randuri.
@export var forest_rows: PackedFloat32Array = PackedFloat32Array([6.6, 10.4])
@export_range(1.0, 8.0, 0.1, "suffix:m") var forest_step: float = 2.6
## Stinge padurea (sabotajul sondei ProbeFlicker: cer prin goluri).
@export var forest_enabled: bool = true

var _track: Track = null
var gate_count: int = 0
var forest_count: int = 0
var tunnel_start_dist: float = 0.0
var tunnel_end_dist: float = 0.0
var built: bool = false
var avenue_count: int = 0
var big_gate_dist: float = 0.0


func _ready() -> void:
	_place.call_deferred()


func _find_track() -> Track:
	if _track != null:
		return _track
	var n: Node = get_parent()
	while n != null:
		if n is Track:
			_track = n as Track
			break
		n = n.get_parent()
	return _track


func _place() -> void:
	if not is_inside_tree():
		return
	var track := _find_track()
	if track == null or track.routes.size() <= branch_index \
			or track.route_at(branch_index).baked.is_empty():
		if not Engine.is_editor_hint():
			get_tree().process_frame.connect(_place, CONNECT_ONE_SHOT)
		return
	var route := track.route_at(branch_index)
	var main := track.route_at(0)
	var total := route.length()
	# Esantioane la `spacing` pe lungimea benzii.
	var pts: Array[Vector3] = []
	var dirs: Array[Vector3] = []
	var dists: Array[float] = []
	var d := 0.0
	while d <= total:
		var s := _sample(route, d)
		pts.append(s[0])
		dirs.append(s[1])
		dists.append(d)
		d += spacing
	# Tronsonul continuu din mijloc, unde banda e departe de bucla principala.
	var first := -1
	var last := -1
	for i in pts.size():
		if _clear_of_main(track, main, pts[i], main_clear_m):
			if first < 0:
				first = i
			last = i
	if first < 0 or last - first < 8:
		push_warning("ToriiTunnel: banda %d nu are tronson liber de bucla" % branch_index)
		return
	tunnel_start_dist = dists[first]
	tunnel_end_dist = dists[last]
	var gate_pos := PackedVector3Array()
	var gate_yaw := PackedFloat32Array()
	for i in range(first + 1, last):
		gate_pos.append(pts[i])
		gate_yaw.append(_yaw(dirs[i]))
	gate_count = gate_pos.size()
	_add_flock("PortiTorii", gate_scene, gate_pos, gate_yaw, 1.0, 1.0)
	# Furca: poarta mare la inceputul real al benzii (la `gate_clear_m` de bucla).
	var big_first := first
	for i in first:
		if _clear_of_main(track, main, pts[i], gate_clear_m):
			big_first = i
			break
	var step := maxi(1, int(round(avenue_gap / spacing)))
	var av_pos := PackedVector3Array()
	var av_yaw := PackedFloat32Array()
	var k := big_first + step
	while k <= first:
		av_pos.append(pts[k])
		av_yaw.append(_yaw(dirs[k]))
		k += step
	_add_flock("PortiBulevard", gate_scene, av_pos, av_yaw, 1.0, 1.0)
	avenue_count = av_pos.size()
	var big_pos := PackedVector3Array([pts[big_first], pts[last]])
	# Poarta de la furca se roteste spre masina care vine pe bucla (60% spre tangenta
	# buclei): banda se desprinde in unghi de ~37 grade, iar o poarta pusa strict
	# pe axa benzii s-ar vedea din sosea doar pe muchie, ca o linie.
	var mi0 := main.closest_index_global(pts[big_first])
	var mdir := main.baked[mini(mi0 + 2, main.baked.size() - 1)] - main.baked[maxi(mi0 - 2, 0)]
	mdir.y = 0.0
	var bdir := dirs[big_first]
	if mdir.length_squared() > 1e-6:
		bdir = (dirs[big_first] * 0.4 + mdir.normalized() * 0.6).normalized()
	var big_yaw := PackedFloat32Array([_yaw(bdir), _yaw(dirs[last])])
	big_gate_dist = dists[big_first]
	if foxes_enabled:
		_build_foxes(track, main, pts[big_first], dirs[big_first])
	_add_flock("PortiMari", large_gate_scene, big_pos, big_yaw, big_scale, big_scale)
	_build_walls(pts, dirs, first, last)
	if forest_enabled:
		_build_forest(track, main, pts, dirs, first, last)
	built = true


## Punct si directie (orizontala, normalizata) la distanta `d` pe banda.
func _sample(route: TrackRoute, d: float) -> Array:
	var n := route.baked.size()
	var lo := 0
	var hi := n - 1
	while lo < hi - 1:
		var mid := (lo + hi) / 2
		if route.dists[mid] <= d:
			lo = mid
		else:
			hi = mid
	var span := maxf(route.dists[hi] - route.dists[lo], 0.0001)
	var t := clampf((d - route.dists[lo]) / span, 0.0, 1.0)
	var p := route.baked[lo].lerp(route.baked[hi], t)
	# Directia pe o fereastra mai larga decat un segment (curba coapta e
	# poligonala): perpendicularele portilor raman netede.
	var a := route.baked[maxi(lo - 1, 0)]
	var b := route.baked[mini(hi + 1, n - 1)]
	var dir := b - a
	dir.y = 0.0
	dir = dir.normalized() if dir.length_squared() > 1e-6 else Vector3.FORWARD
	return [p, dir]


## Yaw care pune axa -Z locala a portii pe directia benzii (axa portii, X,
## ramane perpendiculara pe drum).
static func _yaw(dir: Vector3) -> float:
	return atan2(-dir.x, -dir.z)


func _clear_of_main(track: Track, main: TrackRoute, p: Vector3, margin: float) -> bool:
	var i := main.closest_index_global(p)
	var lat := main.lateral_distance(i, p)
	return lat > track.width_at_index(i) + margin


func _add_flock(nm: String, scene: PackedScene, pos: PackedVector3Array,
		yaw: PackedFloat32Array, smin: float, smax: float) -> FlockProp:
	if scene == null or pos.is_empty():
		return null
	var f := FlockProp.new()
	f.name = nm
	f.model = scene
	f.positions = pos
	f.yaws = yaw
	f.scale_min = smin
	f.scale_max = smax
	add_child(f)
	return f


## Doi pereti continui (trimesh), cate unul pe parte, la `half_gap` de axa.
func _build_walls(pts: Array[Vector3], dirs: Array[Vector3], first: int, last: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sgn: float in [-1.0, 1.0]:
		for i in range(first, last):
			var a := pts[i] + dirs[i].cross(Vector3.UP) * _wall_lat(i, first, last) * sgn
			var b := pts[i + 1] + dirs[i + 1].cross(Vector3.UP) * _wall_lat(i + 1, first, last) * sgn
			var a0 := a + Vector3.DOWN * 1.0
			var b0 := b + Vector3.DOWN * 1.0
			var a1 := a + Vector3.UP * wall_height
			var b1 := b + Vector3.UP * wall_height
			for v in [a0, a1, b0, a1, b1, b0]:
				st.add_vertex(v)
	var mesh := st.commit()
	var body := StaticBody3D.new()
	body.name = "PereteTunel"
	var pm := PhysicsMaterial.new()
	pm.friction = wall_friction
	pm.bounce = wall_bounce
	body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape() as ConcavePolygonShape3D
	tri.backface_collision = true
	cs.shape = tri
	body.add_child(cs)
	add_child(body)


## Doua vulpi kitsune placeholder (soclu + corp + cap, bavet rosu) la +-7 m de axa,
## cu fata spre masina care vine. Fara coliziune; se omit daca ar cadea pe sosea.
func _build_foxes(track: Track, main: TrackRoute, at: Vector3, dir: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := dir.cross(Vector3.UP)
	var any := false
	for sgn: float in [-1.0, 1.0]:
		var c := at + side * (5.5 * big_scale + 1.6) * sgn
		if not _clear_of_main(track, main, c, 2.5):
			continue
		any = true
		var fwd := -dir # fata spre masina care vine
		var basis := Basis(side, Vector3.UP, -dir)
		_box(st, c, basis, Vector3(1.1, 0.9, 1.1), 0.45, Palette.MARBLE_GREY)
		_box(st, c, basis, Vector3(0.55, 1.0, 0.9), 0.9 + 0.5, Palette.MARBLE_GREY)
		_box(st, c + fwd * 0.45 + Vector3.UP * 0.0, basis, Vector3(0.4, 0.45, 0.5), 2.05, Palette.MARBLE_GREY)
		_box(st, c + fwd * 0.3, basis, Vector3(0.6, 0.5, 0.08), 1.55, Palette.KERB_RED)
	if not any:
		return
	var mesh := st.commit()
	mesh.surface_set_material(0, Palette.world_material())
	var mi := MeshInstance3D.new()
	mi.name = "VulpiKitsune"
	mi.mesh = mesh
	add_child(mi)


func _box(st: SurfaceTool, c: Vector3, basis: Basis, size: Vector3, y_center: float, slot: int) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var ctr := c + Vector3.UP * y_center
	var faces := [
		[Vector3.UP, Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)],
		[Vector3.DOWN, Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, -1, -1), Vector3(-1, -1, -1)],
		[Vector3.RIGHT, Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, -1)],
		[Vector3.LEFT, Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(-1, -1, 1)],
		[Vector3.BACK, Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, -1, 1)],
		[Vector3.FORWARD, Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)],
	]
	for f in faces:
		var nrm: Vector3 = basis * (f[0] as Vector3)
		var vs: Array[Vector3] = []
		for k in range(1, 5):
			vs.append(ctr + basis * ((f[k] as Vector3) * h))
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(nrm)
			st.set_uv(uv)
			st.set_color(Color.WHITE)
			st.add_vertex(vs[idx])


## Laterala peretelui la esantionul `i`: `half_gap`, plus palnia de la capete.
func _wall_lat(i: int, first: int, last: int) -> float:
	var from_end := minf(float(i - first), float(last - i)) * spacing
	return half_gap + flare_out * maxf(0.0, 1.0 - from_end / maxf(flare_len, 0.001))


## Padurea de cedri: doua randuri pe fiecare parte, dincolo de porti. Un cedru
## care ar cadea pe bucla principala se omite.
func _build_forest(track: Track, main: TrackRoute, pts: Array[Vector3],
		dirs: Array[Vector3], first: int, last: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261002
	var pos := PackedVector3Array()
	var yaw := PackedFloat32Array()
	var stride := maxi(1, int(round(forest_step / spacing)))
	var row_k := 0
	for lat: float in forest_rows:
		for sgn: float in [-1.0, 1.0]:
			# Fiecare rand pe fiecare parte porneste la alt decalaj: nu un zid de
			# trunchiuri aliniate, ci o masa.
			var i := first - 2 * stride + ((row_k * stride) / 2)
			while i <= last + 2 * stride:
				var k := clampi(i, 0, pts.size() - 1)
				var p := pts[k] + dirs[k].cross(Vector3.UP) * (lat + rng.randf_range(-0.6, 0.6)) * sgn
				p.y = pts[k].y - 1.2
				if _clear_of_main(track, main, p, 4.5):
					pos.append(p)
					yaw.append(rng.randf() * TAU)
				i += stride
			row_k += 1
	forest_count = pos.size()
	_add_flock("PadureCedri", cedar_scene, pos, yaw, 0.95, 1.35)
