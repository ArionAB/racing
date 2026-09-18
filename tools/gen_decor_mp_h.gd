extends Node
## Generator de decor MANUAL pentru POI H — CORNISA PODULUI INCAS
## (Track15, Machu Picchu, frac 0.94-1.00).
##
## Ca la Serengeti (gen_decor_ser_d.gd) si ca la POI G (gen_decor_mp_g.gd): nu e
## sonda, e unealta care CALCULEAZA transformarile ce se lipesc in Track15.tscn
## sub `DecorManual/ZoneH_Cornisa`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpH.tscn -- \
##       --out=C:/cale/zoneH.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote laterale, semi-latime,
## vectorul lateral, directia soarelui, curbura) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CE CERE BARA (docs/track_briefs/img/bar_machu/bara_poi_H.png)
##
## Citit din decupaj, in ordinea in care sare in ochi:
##  1. POARTA DE PIATRA peste drum — un portal trapezoidal prin care trece
##     soseaua, cu zidarie masiva de o parte si de alta a lui. E lucrul care
##     face cadrul: drumul INTRA undeva.
##  2. DRUMUL E TINUT DE ZIDARIE. Sub carosabil, pe partea golului, se vede
##     fata de piatra care il sprijina — aceeasi lectie ca la POI G, dar aici
##     mai importanta fiindca e o CORNISA: peretele e vertical si drumul e o
##     polita pe el.
##  3. PERETELE PE CEALALTA PARTE, cu vegetatie agatata: copaci verzi care ies
##     din stanca, tufe, bolovani cu muschi. Stanca e in umbra, verdele e aprins.
##  4. ZIDURI JOASE DE PIATRA pe marginea dinspre perete, ca punctuatie de
##     cetate (in bara sunt terase joase).
##  5. Cerul/golul pe o singura parte — jumatate de cadru e gol luminos.
##
## Bara e LOOK, nu LAYOUT (docs/track_briefs/machu_picchu_poi_gauntlet.md).
## Nu se redeseneaza traseul; se compara MATERIA: granit cald, verde de padure
## de nori, silueta de cornisa.
##
## ------------------------------------------------------------------------
## SURVEY (runda 1) — cifrele care decid compozitia. Se completeaza dupa
## prima rulare cu --survey, aici in antet.
##
## (vezi blocul SURVEY R1 de mai jos, completat pe masuratoare)
##
## ------------------------------------------------------------------------
## CAPCANELE DECLARATE ALE POI-ULUI (gauntlet §H)
##
## 1. `main_gate` are **7,39 m gol liber MASURAT**, nu 8,39 cum scrie
##    inventarul (docs/asset_briefs/machu_picchu_masuratori.md §3, proiectia
##    triunghiurilor pe planul (lateral, y), grila de 1 cm). Brief-ul pistei
##    cere 8 m la baza pentru imbranceala cu 4 masini. Deci poarta se aseaza
##    la scara 1 (nu se "corecteaza" la 8,0 — s-ar pierde marja) si se
##    VERIFICA cu ProbeRace/--slice + ProbeLaneClear ca plutonul trece.
##    Daca nu trece, se RAPORTEAZA cifra; nu se largeste poarta in tacere.
##    Golul se masoara pe PROIECTIE, nu pe AABB (memoria
##    cota-de-contract-se-masoara-ca-gol).
##
## 2. Barnele (`BarnePodIncas`, frac 0,9435) aduc rampele podului mobil:
##    un damb de RAMP_RISE = 1,6 m pe 5,0 m la fiecare buza. Deci profilul nu
##    citeste "barne peste gol", ci "cocoasa-gaura-cocoasa"; si SUB gol
##    terenul ramane sus, deci nu e prapastie. Asta e o problema de TEREN
##    (sapatura locala), nu de decor manual — si terenul nu e treaba POI-ului
##    (traseul a trecut ProbeLayout). Ce poate face decorul: sa puna piatra
##    care CITESTE ca buza de prapastie in jurul golului, si sa raporteze ce
##    se vede pe captura cu --bridge-at=0.24.
##
## 3. `main_gate` si `inti_punku` au primit clasa `inca_stone` la integrarea
##    valului 1: portile sunt granit cu rosturi, nu atlas plat. Zidaria de
##    aici (inca_wall_*) foloseste ACEEASI clasa — zero materiale noi.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneH_Cornisa"

const F_IN := 0.9280
const F_OUT := 0.9990

## id-urile ext_resource din Track15.tscn (fundatia).
const RES := {
	"main_gate": "s_main_gate",
	"inca_bridge_ledge": "s_inca_bridge_ledge",
	"rope_rail": "s_rope_rail",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bromeliad": "s_bromeliad",
	"orchid_cluster": "s_orchid_cluster",
	"trail_marker": "s_trail_marker",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI si se imparte la cifra de aici.
const HEIGHT := {
	"main_gate": 7.500, "inca_bridge_ledge": 12.900, "rope_rail": 1.045,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798, "tree_fern": 3.306,
	"bromeliad": 0.377, "orchid_cluster": 0.390, "trail_marker": 1.200,
}

## Raza de DEGAJARE la sol (m) la scara 1: raza corpului fizic.
const BASE_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 0.61, "polylepis_b": 1.10, "tree_fern": 0.54,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
}

const CROWN_R := {
	"main_gate": 8.45, "inca_bridge_ledge": 15.28, "rope_rail": 2.07,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"moss_boulder_a": 0.43, "moss_boulder_b": 1.24, "moss_boulder_c": 2.11,
	"polylepis_a": 1.39, "polylepis_b": 2.27, "tree_fern": 2.07,
	"bromeliad": 0.46, "orchid_cluster": 0.17, "trail_marker": 0.29,
}

const TRI := {
	"main_gate": 588, "inca_bridge_ledge": 914, "rope_rail": 92,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098, "tree_fern": 768,
	"bromeliad": 248, "orchid_cluster": 410, "trail_marker": 76,
}

const EDGE_KEEP := 0.8

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _skipped := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 940971
	_survey()
	if not _survey_only:
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _survey() -> void:
	var sun := _find_sun(_track)
	var shadow := Vector3.ZERO
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, shadow.x, shadow.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac    ax(x,z)            y_drum  half   side(x,z)        curb(1/m)  sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := F_IN - 0.012
	while f <= F_OUT + 0.004:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+7.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.4f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %+8.4f  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, _curv(i), " ".join(cols),
			s.dot(shadow)])
		f += 0.002


func _curv(i: int) -> float:
	var n := _track.baked.size()
	var a: Vector3 = _track.baked[(i - 3 + n) % n]
	var b: Vector3 = _track.baked[i]
	var c: Vector3 = _track.baked[(i + 3) % n]
	var t0 := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var t1 := Vector3(c.x - b.x, 0.0, c.z - b.z)
	var l := t0.length() + t1.length()
	if l < 0.01:
		return 0.0
	var s := _track._side_at(i)
	var dth := t1.normalized().angle_to(t0.normalized())
	var sgn := signf(t1.normalized().dot(s))
	return sgn * absf(dth) / (l * 0.5)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ asezarea

func _step(meters: float) -> float:
	return meters / _total_len


func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull",
		dy: float = 0.0, pitch: float = 0.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z) + dy
	if mode != "none" and d - r < half + EDGE_KEEP:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: corpul la %.2f m de ax, muchia la %.2f" % [
			model, frac, d - r, half])
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < half - 1.0:
		_warn += 1
		print("; ATENTIE silueta %s la frac %.4f ajunge la %.2f m de ax (banda %.2f)" % [
			model, frac, d - cr, half])
	if mode != "none" and _on_any_road(q, i, r):
		_skipped += 1
		return
	var smooth := _sampler.ground_y(q.x, q.z)
	var sink := smooth - (g - dy)
	var piece_h: float = float(HEIGHT.get(model, 1.0)) * scl
	var zvelt: bool = model.begins_with("polylepis") or model == "tree_fern"
	var max_sink: float = 0.8 if zvelt else maxf(0.5 * piece_h, 1.0)
	if sink > max_sink:
		_skipped += 1
		return
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode, pitch)


const NEAR_WINDOW_FRAC := 0.012
const OTHER_ROAD_KEEP := 1.2

func _on_any_road(p: Vector3, home_i: int, body_r: float) -> bool:
	var n := _track.baked.size()
	var skip := int(round(float(n) * NEAR_WINDOW_FRAC))
	for i in n:
		var di := absi(i - home_i)
		di = mini(di, n - di)
		if di <= skip:
			continue
		var b: Vector3 = _track.baked[i]
		var dx := b.x - p.x
		var dz := b.z - p.z
		var clear: float = _track.width_at_index(i) + OTHER_ROAD_KEEP + body_r
		if dx * dx + dz * dz < clear * clear:
			return true
	return false


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, pitch: float = 0.0) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri).
	var b := Basis.from_euler(Vector3(pitch, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d refuzate, %d avertismente, ~%d triunghiuri" % [
		_n, _skipped, _warn, _tri])
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody), nu din
## campul neted (memoria terrain-mesh-y-extrapoleaza).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
