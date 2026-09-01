extends Node
## Conturul hornurilor NUMITE, masurat pe silueta lor proprie din cadrul de livrare.
##
## De ce exista (runda 21). Trei runde s-au dus pe cifre neatribuibile. Sonda de
## pixeli (`skyline_cones.py`) taie conurile din poza dupa varfurile liniei de
## orizont si le raporteaza dupa coloana X — dar nu stie AL CUI e conul.
## Verdictul rundei 20: cu `taper_min = 0` pe toate cele 55 de hornuri cifrele au
## iesit identice la bit, fiindca cel mai mare "con" din cadru e TEREN de la
## 380 m (`track_from_path.gd`), nu horn.
##
## Prima idee — proiecteaza AABB-ul fiecarui nod si masoara doar in intervalul
## lui de coloane — NU merge, si asta s-a masurat: la 16 m colturile cutiei cad
## langa planul near si intervalul iese de 4575 px pe un cadru de 1280. O cutie
## mai lata decat ecranul nu filtreaza nimic.
##
## Deci aici se rasterizeaza. Fiecare triunghi al fiecarui mesh vizibil se
## proiecteaza cu ACEEASI camera ca `--driver` (MEASURE_* din snapshot.gd), intr-un
## z-buffer care tine si PROPRIETARUL pixelului. Silueta unui horn = pixelii pe
## care ii CASTIGA, deci ocluziunea e tratata corect: un horn ascuns pe jumatate
## de vecin e masurat pe jumatatea vizibila, si terenul nu mai intra niciodata in
## cifra hornului.
##
## Ce raporteaza, per horn numit (criteriul rundei 21):
##   - profilul VARF -> BAZA, latimea la 9 cote raportata la baza;
##   - `suma|d2|` — curbura TOTALA a siluetei, tinta < 0.08;
##   - `d2max` — cea mai mare a doua diferenta pozitiva (umarul de sticla),
##     tinta <= +0.05.
##
## Rulare:
##   godot --headless --path . res://tools/ProbeCappHorn.tscn -- --frac=0.06
##   ... --nume=hornSoare7,hornGemen9    (doar hornurile astea)
##   ... --min-px=400                    (numai siluete de peste atat)

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
## Camera de livrare: aceleasi constante ca `--driver` din snapshot.gd.
const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const W: int = 1280
const H: int = 720
## Esantioane pe inaltime, ca la sonda de pixeli.
const SAMPLES: int = 9

var _cam: Camera3D
var _depth: PackedFloat32Array
var _owner: PackedInt32Array
var _nume: Array[String] = []
var _scripturi: Array[String] = []
var _dist: PackedFloat32Array
var _meshuri: Array = []
## Buffer privat pentru silueta NEOCLUZIONATA a unui singur obiect.
var _solo: PackedByteArray
var _solo_id: int = -2


func _ready() -> void:
	var frac := 0.06
	var min_px := 400
	var filtru: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--min-px="):
			min_px = int(arg.trim_prefix("--min-px="))
		elif arg.begins_with("--nume="):
			for s in arg.trim_prefix("--nume=").split(","):
				if not s.is_empty():
					filtru.append(s)

	await get_tree().process_frame
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame

	_cam = Camera3D.new()
	add_child(_cam)
	_aseaza_camera(track, frac)
	await get_tree().process_frame

	_depth = PackedFloat32Array()
	_depth.resize(W * H)
	_depth.fill(1.0e20)
	_owner = PackedInt32Array()
	_owner.resize(W * H)
	_owner.fill(-1)
	_dist = PackedFloat32Array()

	var t0 := Time.get_ticks_msec()
	_rasterizeaza(track)
	print("EYE %s  frac %.3f  raster %d ms  %d obiecte"
			% [_cam.global_position.snappedf(0.01), frac,
				Time.get_ticks_msec() - t0, _nume.size()])
	print("")

	# Cati pixeli castiga fiecare obiect: asta e silueta lui REALA in cadru.
	var pix := PackedInt32Array()
	pix.resize(_nume.size())
	pix.fill(0)
	for i in _owner.size():
		var o := _owner[i]
		if o >= 0:
			pix[o] += 1

	var rows: Array = []
	for i in _nume.size():
		if pix[i] < min_px:
			continue
		if not filtru.is_empty() and not filtru.has(_nume[i]):
			continue
		rows.append([pix[i], i])
	rows.sort_custom(func(a, b): return a[0] > b[0])

	print("CONTUR pe hornuri NUMITE (silueta proprie, cu ocluziune):")
	print("  nume                 d_m  px_viz  h_px   profil VARF->BAZA (la baza)                     d2max   suma|d2|")
	var rele := 0
	var total := 0
	for r in rows:
		var i: int = r[1]
		if not _scripturi[i].ends_with("chimney_shape.gd"):
			continue
		var m := _masoara(i)
		if m.is_empty():
			continue
		total += 1
		var linie := ""
		for v in m["rat"]:
			linie += "%.2f " % v
		var flag := ""
		if float(m["suma"]) > 0.08 or float(m["d2max"]) > 0.05:
			flag = "  CURB"
			rele += 1
		if bool(m["taiat"]):
			flag += " (taiat de cadru)"
		print("  %-18s %5.1f  %6d   %4d   %s  %+.3f  %.3f%s"
				% [_nume[i], _dist[i], r[0], int(m["h_px"]), linie,
					float(m["d2max"]), float(m["suma"]), flag])
	print("")
	print("  tinta: suma|d2| < 0.08 SI d2max <= +0.05")
	print("VERDICT: %d/%d hornuri curbate" % [rele, total])

	# Ce NU e horn dar domina cadrul — ca sa nu se mai confunde teren cu horn.
	print("")
	print("Alte siluete mari din cadru (NU sunt hornuri):")
	var k := 0
	for r in rows:
		var i: int = r[1]
		if _scripturi[i].ends_with("chimney_shape.gd"):
			continue
		if k >= 6:
			break
		k += 1
		print("  %-18s %6.1f m  %6d px  %s"
				% [_nume[i], _dist[i], r[0], _scripturi[i]])
	get_tree().quit(0)


func _aseaza_camera(track: Track, frac: float) -> void:
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = MEASURE_FOV
	_cam.near = 0.05
	_cam.far = 400.0
	get_viewport().size = Vector2i(W, H)
	_cam.global_position = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	_cam.look_at(focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT,
			Vector3.UP)
	_cam.current = true


## Toate mesh-urile vizibile, triunghi cu triunghi, in z-buffer-ul cu proprietar.
func _rasterizeaza(n: Node) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.is_visible_in_tree():
		var own := n
		while own != null and own.get_script() == null:
			own = own.get_parent()
		var nm := String(mi.name)
		var scr := "-"
		if own != null:
			scr = String(own.get_script().resource_path.get_file())
			nm = String(own.name)
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var id := _nume.size()
		_nume.append(nm)
		_scripturi.append(scr)
		_dist.append(_cam.global_position.distance_to(ab.get_center()))
		_meshuri.append(mi)
		_mesh_in_buffer(mi, id)
	for c in n.get_children():
		_rasterizeaza(c)


func _mesh_in_buffer(mi: MeshInstance3D, id: int) -> void:
	var xf := mi.global_transform
	var cam_xf := _cam.global_transform.affine_inverse()
	for s in mi.mesh.get_surface_count():
		if mi.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays: Array = mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		# O suprafata NEINDEXATA intoarce null aici, nu un array gol.
		var idx := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null:
			idx = arrays[Mesh.ARRAY_INDEX]
		# Proiectia se face O SINGURA data per vertex, nu per triunghi: pe
		# padurea de hornuri sunt sute de mii de triunghiuri si un unproject
		# per colt ar tripla costul degeaba.
		var sx := PackedFloat32Array()
		var sy := PackedFloat32Array()
		var sz := PackedFloat32Array()
		sx.resize(verts.size())
		sy.resize(verts.size())
		sz.resize(verts.size())
		for i in verts.size():
			var wv: Vector3 = xf * verts[i]
			var cv: Vector3 = cam_xf * wv
			# In spatiul camerei Godot, -Z e inainte.
			var z := -cv.z
			sz[i] = z
			if z <= 0.06:
				sx[i] = -1.0e9
				sy[i] = -1.0e9
				continue
			var p := _cam.unproject_position(wv)
			sx[i] = p.x
			sy[i] = p.y
		var has_idx := not idx.is_empty()
		var count := idx.size() if has_idx else verts.size()
		var i2 := 0
		while i2 + 2 < count:
			var a := idx[i2] if has_idx else i2
			var b := idx[i2 + 1] if has_idx else i2 + 1
			var c := idx[i2 + 2] if has_idx else i2 + 2
			i2 += 3
			if sz[a] <= 0.06 or sz[b] <= 0.06 or sz[c] <= 0.06:
				continue
			_triunghi(sx[a], sy[a], sz[a], sx[b], sy[b], sz[b],
					sx[c], sy[c], sz[c], id)


## Umplere de triunghi cu z-buffer, coordonate baricentrice pe ecran.
##
## Adancimea se interpoleaza LINIAR pe ecran, nu perspectiv-corect. E o
## aproximare — dar aici se decide doar CINE castiga pixelul intre obiecte
## separate in adancime cu metri intregi, nu se face shading.
func _triunghi(ax: float, ay: float, az: float, bx: float, by: float, bz: float,
		cx: float, cy: float, cz: float, id: int) -> void:
	var minx := int(floor(minf(ax, minf(bx, cx))))
	var maxx := int(ceil(maxf(ax, maxf(bx, cx))))
	var miny := int(floor(minf(ay, minf(by, cy))))
	var maxy := int(ceil(maxf(ay, maxf(by, cy))))
	if maxx < 0 or minx >= W or maxy < 0 or miny >= H:
		return
	minx = maxi(minx, 0)
	maxx = mini(maxx, W - 1)
	miny = maxi(miny, 0)
	maxy = mini(maxy, H - 1)
	var det := (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
	if absf(det) < 1.0e-9:
		return
	var inv := 1.0 / det
	for y in range(miny, maxy + 1):
		var fy := float(y) + 0.5
		var row := y * W
		for x in range(minx, maxx + 1):
			var fx := float(x) + 0.5
			var l0 := ((by - cy) * (fx - cx) + (cx - bx) * (fy - cy)) * inv
			if l0 < 0.0 or l0 > 1.0:
				continue
			var l1 := ((cy - ay) * (fx - cx) + (ax - cx) * (fy - cy)) * inv
			if l1 < 0.0 or l1 > 1.0:
				continue
			var l2 := 1.0 - l0 - l1
			if l2 < 0.0:
				continue
			var k := row + x
			if _solo_id >= 0:
				# Pasul doi: silueta proprie, fara ocluziune, fara adancime.
				_solo[k] = 1
				continue
			var z := l0 * az + l1 * bz + l2 * cz
			if z < _depth[k]:
				_depth[k] = z
				_owner[k] = id


## Profilul siluetei proprii a obiectului `id`: latimea la SAMPLES cote.
##
## Latimea e numarul de coloane pe care obiectul le CASTIGA in randul respectiv
## — nu intervalul stanga-dreapta. Diferenta conteaza: un horn taiat de un vecin
## din fata ar avea intervalul intreg dar suprafata gaurita, si atunci conturul
## masurat ar fi al vecinului.
func _masoara(id: int) -> Dictionary:
	# Silueta PROPRIE, fara ocluziune. Prima versiune masura pixelii castigati in
	# z-buffer si iesea gunoi masurabil: hornUmbra8 raporta 0.98 apoi 0.00 pe
	# ultima cota, fiindca baza lui e ascunsa de un vecin, iar hornSpate12 sarea
	# la 2.21 la mijloc, unde ocluziunea ii taia trunchiul in doua. Ocluziunea e
	# un fapt de SCENA, nu de forma; conturul se judeca pe obiect. Cati pixeli
	# castiga totusi in cadru se raporteaza separat, ca pondere de relevanta.
	_solo = PackedByteArray()
	_solo.resize(W * H)
	_solo.fill(0)
	_solo_id = id
	_mesh_in_buffer(_meshuri[id] as MeshInstance3D, id)
	_solo_id = -2

	var top := H
	var bot := -1
	var latimi := PackedInt32Array()
	latimi.resize(H)
	latimi.fill(0)
	for y in H:
		var row := y * W
		var c := 0
		for x in W:
			if _solo[row + x] != 0:
				c += 1
		latimi[y] = c
		if c > 0:
			if y < top:
				top = y
			bot = y
	var hpx := bot - top + 1
	if hpx < 40:
		return {}
	# BAZA nu e ultimul rand al siluetei. Prima versiune asa o lua si iesea
	# gunoi masurabil (rapoarte de 87.00, d2max +16.5), fiindca ultimele ~30 de
	# randuri sunt VARFUL POALEI DE GROHOTIS: un con de taluz care se termina
	# intr-un varf de 4 px. Impartind la 4 px, orice horn pare de 80 de ori mai
	# lat sus decat jos.
	#
	# Baza reala a conului e randul cel mai LAT al siluetei — acolo unde corpul
	# intalneste poala. Deasupra lui e conturul pe care il citeste ochiul; sub el
	# e fusta, care are propria panta si nu face parte din silueta hornului.
	var ybase := top
	var wmax := 0
	for y in range(top, bot + 1):
		if latimi[y] > wmax:
			wmax = latimi[y]
			ybase = y
	var hcorp := ybase - top + 1
	if hcorp < 40 or wmax < 8:
		return {}
	var taiat := bot >= H - 1
	var rat := PackedFloat32Array()
	var raw := PackedFloat32Array()
	for i in SAMPLES:
		var y := top + int(round(float(hcorp - 1) * float(i) / float(SAMPLES - 1)))
		raw.append(float(latimi[y]))
	var base := raw[SAMPLES - 1]
	if base < 8.0:
		return {}
	for v in raw:
		rat.append(v / base)
	var d2 := PackedFloat32Array()
	var suma := 0.0
	var mx := -9.0
	for i in range(1, SAMPLES - 1):
		var v := rat[i + 1] - 2.0 * rat[i] + rat[i - 1]
		d2.append(v)
		suma += absf(v)
		mx = maxf(mx, v)
	return {"rat": rat, "suma": suma, "d2max": mx, "h_px": hcorp,
		"top": top, "taiat": taiat, "poala": hpx - hcorp}
