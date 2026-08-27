extends Node
## Generator de decor MANUAL pentru Chongqing (Track12, tema `chongqing`) —
## deocamdata DOAR scenografia de MAL.
##
## NU e o sonda de verificare, e unealta cu care se CALCULEAZA transformarile
## care se lipesc apoi in Track12.tscn sub `DecorManual`. Acelasi rost ca
## gen_decor_baikal.gd: fiecare grup e o DECIZIE, dar cotele vin din lumea
## reala (`sampler.ground_y`, cota apei, muchia cheiului), nu din ochi.
##
## DE CE EXISTA. Runda 6 a calibrat apa pixel cu pixel dupa diorama si tot a
## picat cu "apa nu citeste ca apa". Masurand referinta (bar/E_chei.png) a
## iesit ca ce spune "lichid" nu e pe apa: e ce sta LANGA ea — zidul de chei,
## slepul acostat, felinarele ale caror reflexii sunt chiar sclipirile de pe
## unda, siluetele de pe malul opus. Zidul si malul opus le construieste
## `Track` (vezi `_build_quay_wall` / `_build_far_shore`); obiectele le aseaza
## fisierul asta.
##
## Rulare (ca SCENA — pista cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorChongqing.tscn
##
## Iesirea se lipeste in Track12.tscn: intai liniile [ext_resource], apoi
## blocul de noduri.

const TRACK := "res://scenes/tracks/Track12.tscn"

## id-urile ext_resource asa cum trebuie sa apara in Track12.tscn.
const RES := {
	"chongqing/vehicles/cargo_ship": "20_ship",
	"chongqing/props/lamp_lantern_a": "21_lamp",
	"chongqing/props/container": "22_box",
	"chongqing/structures/hongya_dong": "23_hongya",
	"chongqing/buildings/tower_silhouette_a": "24_tower",
}

## Cat de sus sta dala cheiului peste apa — ACEEASI valoare ca
## Track.QUAY_FREEBOARD. Daca se schimba acolo, se schimba si aici, altfel
## felinarele plutesc.
const QUAY_FREEBOARD: float = 3.2
## Cat de departe de linia apei se aseaza ce sta pe chei.
const QUAY_INSET: float = 7.0
## Cat de adanc intra in apa carena unui slep incarcat.
const SHIP_DRAFT: float = 1.7
## Cota coroanei malului opus — Track._build_far_shore ridica fata la `h` si
## coboara spatele la 0.8 * h; siluetele stau pe spate.
const FAR_H: float = 12.0

var _track: Track
var _sampler: TrackSideSampler
var _sea: float
var _out: Array[String] = []
var _n := 0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_sea = _sampler.mean_road_y() + _track.sea_level_offset
	print("; sea_y=%.2f  chei=%.2f" % [_sea, _sea + QUAY_FREEBOARD])
	_emit_all()
	print("")
	for line in _out:
		print(line)
	get_tree().quit(0)


# ------------------------------------------------------------------ compozitia

func _emit_all() -> void:
	_quay_lamps()
	_quay_containers()
	_ships()
	_hongya()
	_far_towers()
	print("; asezate %d piese" % _n)


## Felinarele de pe chei. Diorama are un sir REGULAT de-a lungul cheiului, la
## ~25 m, si fiecare isi lasa reflexia pe apa — ele sunt explicatia sclipirilor,
## fara ele apa are pete aurii care nu vin de nicaieri.
func _quay_lamps() -> void:
	var step := 26.0
	for run: Array in _shore_runs():
		var d := step * 0.5
		var total := _run_length(run)
		while d < total:
			var st := _on_run(run, d)
			var p: Vector2 = st[0]
			var n: Vector2 = st[1]
			var q := p - n * QUAY_INSET
			# Felinarul se uita spre apa.
			_node("chongqing/props/lamp_lantern_a", "felinar",
				Vector3(q.x, _sea + QUAY_FREEBOARD, q.y),
				atan2(n.x, n.y), 1.0)
			d += step


## Containerele de la dana. Grupuri MICI si rare, nu un sir: in diorama sunt
## trei-patru stive langa bolarzi, restul cheiului e gol.
func _quay_containers() -> void:
	var spots := [
		Vector2(-46.0, 0.0), Vector2(-46.0, 3.2), Vector2(-40.0, 0.0),
		Vector2(6.0, 0.0), Vector2(6.0, 3.2), Vector2(12.0, 0.0),
		Vector2(12.0, 3.2), Vector2(64.0, 0.0), Vector2(70.0, 0.0),
	]
	var run: Array = _shore_runs()[1]
	var total := _run_length(run)
	for sp: Vector2 in spots:
		var d := total * 0.5 + sp.x
		if d < 4.0 or d > total - 4.0:
			continue
		var st := _on_run(run, d)
		var p: Vector2 = st[0]
		var n: Vector2 = st[1]
		var q := p - n * (QUAY_INSET + 3.4)
		_node("chongqing/props/container", "container",
			Vector3(q.x, _sea + QUAY_FREEBOARD + sp.y, q.y),
			atan2(n.x, n.y) + 0.06, 1.0)


## Slepurile. Cel mai tare semnal de "asta e apa" din toata scenografia: un
## corp mare, orizontal, cu linia de plutire vizibila, ASEZAT in suprafata.
## Trei, la distante diferite: unul acostat la dana (se vede de pe chei),
## unul in golf sub pod, unul departe pe Jialing (se vede de pe cornisa D).
func _ships() -> void:
	var y := _sea - SHIP_DRAFT
	_node("chongqing/vehicles/cargo_ship", "slep_dana",
		Vector3(6.0, y, 236.0), deg_to_rad(88.0), 0.85)
	_node("chongqing/vehicles/cargo_ship", "slep_golf",
		Vector3(192.0, y, 152.0), deg_to_rad(14.0), 0.85)
	_node("chongqing/vehicles/cargo_ship", "slep_pod",
		Vector3(150.0, y, 254.0), deg_to_rad(74.0), 0.85)
	_node("chongqing/vehicles/cargo_ship", "slep_jialing",
		Vector3(-341.0, y, 118.0), deg_to_rad(6.0), 0.85)


## HONGYA DONG pe terasa de sub cornisa (brief §2 D: „orasul-pe-piloni luminat
## auriu SUB tine"). Scara nu e cosmetica: modelul are 47.7 m, faleza noastra
## are 27 m de la terasa (5.7) la sosea (32.8). La scara 1 cladirea ar iesi cu
## 21 m PESTE drum, adica exact pe dos fata de compozitia ceruta. La 0.55 varful
## sta la ~32 m — chiar sub buza cornisei.
func _hongya() -> void:
	# Retragerea de 26 m NU e din ochi: ProbeTerrace verifica terasa in banda
	# 14-45 m la dreapta soselei, iar cladirea are 23 m latime la scara 0.55.
	# La 26 m de axa, tot corpul cade in banda masurata.
	var i := 0
	for f: float in [0.268, 0.300, 0.332]:
		var idx := int(f * float(_track.baked.size()))
		var road: Vector3 = _track.baked[idx]
		var side: Vector3 = _track._side_at(idx)
		var out := road + side * (_track.width_at_index(idx) + 26.0)
		var g := _sampler.ground_y(out.x, out.z)
		# Fatada se uita spre apa, adica in continuarea normalei la sosea.
		_node("chongqing/structures/hongya_dong", "hongya",
			Vector3(out.x, g, out.z), atan2(side.x, side.z), 0.55)
		i += 1


## Siluetele de pe malul opus. Brief §2.0: turnurile exista DOAR ca siluete
## peste rau, la 150-250 m, sub fog_end. Stau pe coroana malului construit de
## Track._build_far_shore.
##
## Pozitiile se CITESC din cheia de tema `far_shore`, nu se tasteaza: prima
## incercare le-a scris de mana la ~25 m de linia malului si turnurile au iesit
## plutind peste apa, cu spatiu vizibil sub ele. Un obiect care sta pe o
## geometrie declarata in alta parte trebuie sa-si ia cota SI pozitia de acolo.
func _far_towers() -> void:
	var i := 0
	for bank: Dictionary in _track.theme_flag("far_shore", []):
		var line: Array = bank.get("line", [])
		var h := float(bank.get("h", 12.0))
		var depth := float(bank.get("depth", 45.0))
		var back := 16.0
		# Coroana coboara liniar de la `h` (fata) la 0.8*h la `depth`; la `back`
		# metri in spate iese asta, minus un metru ca silueta sa fie infipta.
		var y := _sea + h - 0.2 * h * (back / depth) - 1.0
		var c := _track._centroid()
		for k in line.size() - 1:
			var a: Vector2 = line[k]
			var b: Vector2 = line[k + 1]
			var seg := a.distance_to(b)
			var steps := maxi(int(seg / 62.0), 1)
			for m in steps:
				var p := a.lerp(b, (float(m) + 0.5) / float(steps))
				var n := Vector2(-(b.y - a.y), b.x - a.x).normalized()
				if n.dot(a - Vector2(c.x, c.z)) < 0.0:
					n = -n
				var q := p + n * back
				var sizes: Array[float] = [0.85, 1.15, 0.7, 1.0]
				_node("chongqing/buildings/tower_silhouette_a", "turn",
					Vector3(q.x, y, q.y), float(i) * 0.7, sizes[i % 4])
				i += 1


# ------------------------------------------------------------------ conturul

## Portiunile de mal pe care se aseaza scenografia, ca poliliniii in plan XZ.
## Sunt bucati din conturul lagunei (`Track._lagoon_points`), alese: malul de
## sub cornisa (vest) si cheiul (sud). Restul conturului — golful si iesirea
## spre est — ramane gol in runda asta.
func _shore_runs() -> Array:
	var poly := _track._lagoon_points()
	return [
		[poly[1], poly[2], poly[3], poly[4]],
		[poly[4], poly[5], poly[6], poly[7], poly[8]],
	]


func _run_length(run: Array) -> float:
	var total := 0.0
	for i in run.size() - 1:
		total += (run[i] as Vector2).distance_to(run[i + 1])
	return total


## Punctul si normala (catre apa) la distanta `d` de-a lungul unei polilinii.
func _on_run(run: Array, d: float) -> Array:
	var walked := 0.0
	for i in run.size() - 1:
		var a: Vector2 = run[i]
		var b: Vector2 = run[i + 1]
		var seg := a.distance_to(b)
		if walked + seg >= d or i == run.size() - 2:
			var t := clampf((d - walked) / maxf(seg, 0.001), 0.0, 1.0)
			var dir := (b - a).normalized()
			var n := Vector2(-dir.y, dir.x)
			if not Geometry2D.is_point_in_polygon(a.lerp(b, t) + n * 2.0,
					_track._lagoon_poly()):
				n = -n
			return [a.lerp(b, t), n]
		walked += seg
	return [run[0], Vector2.UP]


# ------------------------------------------------------------------ iesirea

func _node(model: String, base: String, pos: Vector3, yaw: float,
		scl: float) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="DecorManual" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	# Decor de mal: nimic din ce se aseaza aici nu e pe traseu, iar un corp
	# fizic acolo ar putea prinde o masina care oricum cade in rau.
	_out.append('metadata/coliziune = "none"')
	_out.append("")
