extends Node
## Generator de decor MANUAL pentru POI C — KIYOMIZU-DERA (Track18, Kyoto,
## frac 0.15-0.34: urcarea C1 spre E, coltul, scena pe stalpi, saritura C2 si
## aterizarea langa pagoda Koyasu).
##
## Nu e sonda: CALCULEAZA transformarile pe teren si pe axa reala si scrie
## blocul `DecorManual/ZoneC_Kiyomizu` (tiparul gen_decor_jod_a.gd) in
## tools/kyoto_decor/poi_c.part (sectiuni `;;EXT` / `;;NODES`, id-uri `poic_`),
## pe care tools/gen_kyoto_route.py il lipeste sub DecorManual la regenerare:
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoC.tscn
##   python tools/gen_kyoto_route.py scenes/tracks/Track18.tscn
##
## ------------------------------------------------------------------------
## DECIZIILE (brief kyoto.md §2 randurile C/C2, §2.0, §3)
##
## - POARTA NIOMON peste C1 la x 250 (punctul de traseu „C1 Niomon"), axa
##   portii pe axa drumului, scara 1: golul masurat 14,30 m (±7,15) fata de
##   semilatimea 5 m a rampei. Baza la cota cea mai joasa a celor doua randuri
##   de stalpi (panta 8,5%). `camera_blocker`: camera de 10 m trece prin etajul
##   portii (golul liber are 7,10 m).
## - Pe STANGA lui C1 (nord, exteriorul buclei) incinta templului: zid ciclopic
##   la 11 m de ax (soclul terasei), pagoda Sanjunoto la 17 m, clopotnita si
##   bazinul chozuya. DREAPTA lui C1 ramane joasa (zid de templu doar langa
##   poarta, felinare): pe acolo se vede scena din lateral (§2.0), iar padurea
##   e golita de luminisurile „C1 vedere" din gen_kyoto_route.py.
## - SALA (kiyomizu_hondo) la STANGA scenei, cu fata (−Z, scara si frontoanele)
##   spre punte, pe 24 de module kakezukuri puse pe fundul rapei (15,7): sala
##   sta la cota punctii, acoperisul la inaltimea camerei (§2 randul C).
## - PAGODA KOYASU pe versantul de aterizare, la 15 m in dreapta axei, ~65 m de
##   buza: din camera de pe scena azimut ~13°, varful la +4 m fata de punte
##   (intreaga in cadru, §2.0). Doua perechi de felinare marcheaza aterizarea.

const TRACK := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneC_Kiyomizu"

const RES := {
	"niomon_gate": "poic_niomon",
	"sanjunoto_pagoda": "poic_sanjunoto",
	"koyasu_pagoda": "poic_koyasu",
	"kiyomizu_hondo": "poic_hondo",
	"kakezukuri_scaffold": "poic_scaffold",
	"cyclopean_wall": "poic_cyclopean",
	"temple_wall": "poic_temple_wall",
	"bell_tower": "poic_bell",
	"chozuya": "poic_chozuya",
	"stone_lantern_a": "poic_lantern_a",
	"stone_lantern_b": "poic_lantern_b",
	"momiji_a": "poic_momiji_a",
	"momiji_b": "poic_momiji_b",
	"momiji_c": "poic_momiji_c",
}

## Cotele de amplasare (lume). Luminisurile din gen_kyoto_route.py au aceleasi
## centre — daca se muta ceva aici, se muta si acolo.
const GATE_X := 250.0
const SANJU := Vector2(288.0, -216.0)
const BELL := Vector2(312.0, -215.5)
const HONDO := Vector2(383.5, -152.0)
const KOYASU := Vector2(350.0, -42.0)
const SCAFFOLD_XS := [375.4, 381.4, 387.4, 393.4]
const SCAFFOLD_ZS := [-165.5, -159.5, -153.5, -147.5, -141.5, -135.5]
const SCAFFOLD_H := 15.92

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _n := 0
var _out_path := "res://tools/kyoto_decor/poi_c.part"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for i in 4:
		await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_rng.seed = 31026
	_out.append('[node name="ZoneC_Kiyomizu" type="Node3D" parent="DecorManual"]')
	_out.append("")
	_gate()
	_precinct()
	_lanterns_c1()
	_hall()
	_koyasu()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ piese

func _gate() -> void:
	var r := _c1_at(GATE_X)
	var p: Vector3 = r[0]
	var d: Vector3 = r[1]
	var yaw := atan2(-d.x, -d.z)
	# Randurile de stalpi la ±4,5 m pe axa de trecere (Gate_Wood z ±4,5).
	var lo := INF
	for s in [-4.5, 4.5]:
		for side in [-1.0, 1.0]:
			var q: Vector3 = p + d * float(s) + _left(d) * 7.6 * float(side)
			lo = minf(lo, _sol_real(q.x, q.z))
	lo = minf(lo, p.y)
	_raw("niomon_gate", "PoartaNiomon", Vector3(p.x, lo - 0.05, p.z), yaw, 1.0, "")
	_meta_last("metadata/camera_blocker = true")
	print("; Niomon la (%.1f, %.2f, %.1f), yaw %.1f, drum y %.2f" % [p.x, lo, p.z, rad_to_deg(yaw), p.y])


func _precinct() -> void:
	# Zidul ciclopic pe stanga, la 11 m de ax, fata (-Z local) spre drum.
	var x := 270.0
	while x <= 334.1:
		var r := _c1_at(x)
		var p: Vector3 = r[0]
		var d: Vector3 = r[1]
		var q: Vector3 = p + _left(d) * 11.0
		var yaw := atan2(-d.z, d.x) + PI
		_raw("cyclopean_wall", "cZidCiclopic", Vector3(q.x, _sol_min(q, d, 3.6) - 0.15, q.z), yaw, 1.0, "")
		x += 8.0
	# Zidul de templu pe dreapta, doar langa poarta (3 module, 258-282).
	x = 262.0
	while x <= 278.1:
		var r := _c1_at(x)
		var p: Vector3 = r[0]
		var d: Vector3 = r[1]
		var q: Vector3 = p - _left(d) * 10.2
		_raw("temple_wall", "cZidTemplu", Vector3(q.x, _sol_min(q, d, 3.8) - 0.1, q.z), atan2(d.x, d.z), 1.0, "")
		x += 8.0
	# Pagoda Sanjunoto, clopotnita si bazinul, toate cu fata spre drum (sud).
	_raw("sanjunoto_pagoda", "cSanjunoto", _on_ground(SANJU, 4.0), PI, 1.0, "")
	_raw("bell_tower", "cClopotnita", _on_ground(BELL, 2.6), PI + 0.1, 1.0, "")
	var rc := _c1_at(262.0)
	var pc: Vector3 = (rc[0] as Vector3) + _left(rc[1]) * 14.5
	_raw("chozuya", "cChozuya", _on_ground(Vector2(pc.x, pc.z), 1.5), PI, 1.0, "")


func _lanterns_c1() -> void:
	var x := 262.0
	var k := 0
	while x <= 340.0:
		var r := _c1_at(x)
		var p: Vector3 = r[0]
		var d: Vector3 = r[1]
		for side in [1.0, -1.0]:
			var q: Vector3 = p + _left(d) * 8.2 * float(side)
			var m := "stone_lantern_a" if (k % 2 == 0) else "stone_lantern_b"
			_raw(m, "cFelinar", _on_ground(Vector2(q.x, q.z), 0.6),
				atan2(-d.x, -d.z) + PI * 0.5 * float(side), 1.0, "")
		x += 13.0
		k += 1


func _hall() -> void:
	var top := -INF
	for sx in SCAFFOLD_XS:
		for sz in SCAFFOLD_ZS:
			var gy := _sol_real(sx, sz)
			_raw("kakezukuri_scaffold", "cEsafodajSala", Vector3(sx, gy - 0.05, sz), 0.0, 1.0, "")
			top = maxf(top, gy - 0.05 + SCAFFOLD_H)
	# Fata (-Z local, scara + frontoane) spre scena (-X lume): yaw +90.
	_raw("kiyomizu_hondo", "cSalaHondo", Vector3(HONDO.x, top, HONDO.y), PI * 0.5, 1.0, "")
	print("; sala la cota %.2f (puntea 32,0)" % top)


func _koyasu() -> void:
	_raw("koyasu_pagoda", "cKoyasu", _on_ground(KOYASU, 3.2), 0.15, 1.0, "")
	# Felinarele aterizarii: doua perechi la 13,5 m de ax (la 10,5 m, ProbeRace
	# seed 1: [blocaj] al jucatorului iesit larg la aterizare, frac 0.319, lat 9,9).
	for z in [-80.0, -64.0]:
		for side in [-1.0, 1.0]:
			var q := Vector2(364.0 + 13.5 * float(side), z)
			_raw("stone_lantern_a", "cFelinarAterizare", _on_ground(q, 0.6), 0.0, 1.0, "")
	# Primul rand de artari langa pagoda (coroane in cadrul de pe scena).
	var spots := [Vector2(341.0, -50.0), Vector2(343.0, -33.0), Vector2(357.5, -30.0)]
	var models := ["momiji_a", "momiji_c", "momiji_b"]
	for i in spots.size():
		_raw(models[i], "cArtar", _on_ground(spots[i], 0.4), _rng.randf() * TAU,
			_rng.randf_range(0.95, 1.1), "")


# ------------------------------------------------------------------ geometrie

## Punctul si directia axei pe C1 (spre E, z ~ -190..-205) la abscisa x.
func _c1_at(x: float) -> Array:
	var pts := _track.baked
	var n := pts.size()
	for i in n:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % n]
		if a.z > -185.0 or a.z < -210.0 or b.z > -185.0 or b.z < -210.0:
			continue
		if a.x <= x and b.x > x:
			var t := (x - a.x) / (b.x - a.x)
			var d := (b - a)
			d.y = 0.0
			return [a.lerp(b, t), d.normalized()]
	push_error("C1: nu gasesc x %.1f" % x)
	return [Vector3(x, 0, -200), Vector3(1, 0, 0)]


## Stanga fata de sensul de mers (pe C1, spre E, stanga e nordul, -Z).
func _left(d: Vector3) -> Vector3:
	return Vector3(d.z, 0.0, -d.x)


## Cota minima a solului pe o latura de `half` m in lungul directiei d.
func _sol_min(q: Vector3, d: Vector3, half: float) -> float:
	return minf(minf(_sol_real(q.x, q.z), _sol_real(q.x + d.x * half, q.z + d.z * half)),
		_sol_real(q.x - d.x * half, q.z - d.z * half))


## Pozitia pe teren, la cota minima a unui patrat de semilatura `half`.
func _on_ground(c: Vector2, half: float) -> Vector3:
	var lo := _sol_real(c.x, c.y)
	for o in [Vector2(half, half), Vector2(-half, half), Vector2(half, -half), Vector2(-half, -half)]:
		lo = minf(lo, _sol_real(c.x + o.x, c.y + o.y))
	return Vector3(c.x, lo - 0.05, c.y)


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


## GLB-ul fiecarei piese din [constant RES] (sectiunea `;;EXT`).
const GLB := {
	"niomon_gate": "structures/niomon_gate", "sanjunoto_pagoda": "structures/sanjunoto_pagoda",
	"koyasu_pagoda": "structures/koyasu_pagoda", "kiyomizu_hondo": "structures/kiyomizu_hondo",
	"kakezukuri_scaffold": "structures/kakezukuri_scaffold",
	"cyclopean_wall": "structures/cyclopean_wall", "temple_wall": "structures/temple_wall",
	"bell_tower": "structures/bell_tower", "chozuya": "props/chozuya",
	"stone_lantern_a": "props/stone_lantern_a", "stone_lantern_b": "props/stone_lantern_b",
	"momiji_a": "plants/momiji_a", "momiji_b": "plants/momiji_b", "momiji_c": "plants/momiji_c",
}


func _write() -> void:
	print("; asezate %d piese" % _n)
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	fa.store_line(";;EXT")
	for m in RES:
		fa.store_line('[ext_resource type="PackedScene" path="res://assets/models/kyoto/%s.glb" id="%s"]'
			% [GLB[m], RES[m]])
	fa.store_line(";;NODES")
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
