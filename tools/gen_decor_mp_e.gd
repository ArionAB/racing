extends Node
## Generator de decor MANUAL pentru POI E — PODUL DE FRANGHIE (Track15,
## Machu Picchu, frac 0.56-0.64). Nu e sonda: calculeaza transformarile care
## se lipesc in Track15.tscn sub `DecorManual/ZoneE_Pod`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorMpE.tscn -- \
##       --out=C:/cale/zoneE.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului masurat si nu genereaza nimic.
##
## CE SE VEDE IN BARA (bara_poi_E.png, deschisa inainte de asezare):
## scanduri pe cabluri intre DOUA TURNURI de piatra gri; autobuzul galben pe
## tablier; sub el DEFILEUL — doi pereti de STANCA PALIDA aproape verticali,
## cu vegetatie inchisa doar pe umeri si pe coama; in fund, jos, un fir de
## APA ALBA cu spuma printre pietre; departe, munti albastri in ceata.
## Materia: piatra gri deschisa + verde inchis dens pe coame + alb in gorja.
##
## CAPCANA CARE M-A ADUS AICI: POI-ul E **nu construieste podul**. Tablierul,
## cablurile si cele patru turnuri sunt facute IN COD
## (`rope_bridge_hazard.gd:_build_visual` / `_build_towers`), hazardul e cablat
## in Track15.tscn:93 cu `deck_width = 11.0` si capetele la ±17.12 m.
## Eu construiesc CE E IN JURUL lui.
##
## CE A ARATAT SURVEY-UL, si de ce rastoarna prima ipoteza (runda 1).
##
## 1. GAURA EXISTA SI E MAI MARE DECAT CERE BRIEF-UL. Cu raza filtrata pe
##    RID-ul lui TerrainBody (capcana lui E: o raza sub tablier loveste
##    `Plate3`/`Plate7`, corpurile AnimatableBody3D ale hazardului, si
##    raporteaza „gol 0"), cotele sunt:
##      near (31,-20,-155) frac 0.5482  SOL -33.74  gol 13.74 m
##      mid  (14,-20,-155) frac 0.5572  SOL -40.30  gol 20.30 m
##      far  ( -3,-20,-155) frac 0.5662 SOL -40.30  gol 20.30 m
##    Brief-ul cere 20 m. Ii avem.
##
## 2. DAR NU E O CRAPATURA, E UN BAZIN (tools/SvMpE2.tscn). Podeaua plata la
##    -40.30 tine pe z = -205..-105 (100 m) si x = -28..+20 (48 m). In bara
##    defileul e o FANTA ingusta cu pereti verticali si un fir de apa alba.
##
## 3. PERETII SUNT RAMPE, NU FALEZE (tools/SvMpE3.tscn):
##      spre +X: 16 / 28 / 38 / 22 grade pe primii 40 m
##      spre -X: 25 / 28 / 32 grade
##      spre +-Z: 33 / 59 grade (astea doua sunt singurele care ar prinde tinta)
##    `scarp_tint` (tema `machupicchu`, track.gd:992) porneste la
##    `scarp_slope_deg = 28` cu `scarp_fade_deg = 10`, deci roca PLINA abia la
##    38 grade. Pe peretele de 16-28 de grade — exact cel pe care il vezi
##    venind spre pod — tenta de stanca e ZERO sau partiala.
##
## 4. CAPTURA CONFIRMA, SI E DECISIVA (E_r0_0.540.png, E_r0_0.556.png,
##    regula zero din bara_vizuala: captura bate cifra). De pe tablier,
##    defileul de 20,3 m citeste ca o ADANCITURA IERBOASA:
##      - peretii sunt verzi pana la orizont, cu doar doua petice cenusii
##        acolo unde panta chiar trece de 38 de grade;
##      - podeaua de 100x50 m e complet goala — fara rau, fara spuma, fara
##        bolovani, fara nimic care sa dea scara;
##      - coamele n-au vegetatie, cand in bara sunt incoronate de verde
##        inchis dens;
##      - tablierul se termina in IARBA, nu in piatra.
##
## CONCLUZIA, si e chiar lectia valului 2 cu un etaj mai jos: FORMA EXISTA,
## lipsesc CONTRASTUL si CONTINUTUL. Nu modelez relief. Imbrac ce e:
##   (a) piatra pe peretii de 16-28 de grade, unde `scarp_tint` nu ajunge —
##       bolovani, nu tenta (tenta ar fi o schimbare de tema, si tema e a
##       intregii piste, nu a POI-ului meu);
##   (b) RAUL pe podeaua de la -40.30, cu spuma alba pe pietre — firul alb
##       din bara, si singurul lucru care da scara unei gauri de 20 m;
##   (c) VEGETATIE DENSA pe cele doua coame, ca in bara;
##   (d) PIATRA la capetele tablierului, ca podul sa plece de pe stanca.

const TRACK := "res://scenes/tracks/Track15.tscn"
const ZONE := "DecorManual/ZoneE_Pod"

const F_IN := 0.545
const F_OUT := 0.655

const RES := {
	"moss_boulder_a": "s_moss_boulder_a",
	"moss_boulder_b": "s_moss_boulder_b",
	"moss_boulder_c": "s_moss_boulder_c",
	"polylepis_a": "s_polylepis_a",
	"polylepis_b": "s_polylepis_b",
	"tree_fern": "s_tree_fern",
	"bamboo_clump": "s_bamboo_clump",
	"bromeliad": "s_bromeliad",
	"inca_house_b": "s_inca_house_b",
	"inca_wall_a": "s_inca_wall_a",
	"inca_wall_b": "s_inca_wall_b",
	"inca_wall_c": "s_inca_wall_c",
	"trail_marker": "s_trail_marker",
}

## Inaltimea AABB masurata (docs/asset_briefs/machu_picchu_masuratori.md §1).
## Scara se cere in METRI si se imparte la cifra de aici.
const HEIGHT := {
	"moss_boulder_a": 0.741, "moss_boulder_b": 1.957, "moss_boulder_c": 3.069,
	"polylepis_a": 4.190, "polylepis_b": 6.798,
	"tree_fern": 3.306, "bamboo_clump": 5.010, "bromeliad": 0.377,
	"inca_house_b": 2.833,
	"inca_wall_a": 2.487, "inca_wall_b": 2.487, "inca_wall_c": 2.432,
	"trail_marker": 1.200,
}
const BASE_R := {
	"moss_boulder_a": 0.37, "moss_boulder_b": 0.94, "moss_boulder_c": 1.73,
	"polylepis_a": 0.61, "polylepis_b": 1.10,
	"tree_fern": 0.30, "bamboo_clump": 0.50, "bromeliad": 0.46,
	"inca_house_b": 3.64,
	"inca_wall_a": 2.03, "inca_wall_b": 3.02, "inca_wall_c": 1.06,
	"trail_marker": 0.29,
}
const TRI := {
	"moss_boulder_a": 200, "moss_boulder_b": 242, "moss_boulder_c": 238,
	"polylepis_a": 598, "polylepis_b": 1098,
	"tree_fern": 768, "bamboo_clump": 958, "bromeliad": 248,
	"inca_house_b": 496,
	"inca_wall_a": 208, "inca_wall_b": 296, "inca_wall_c": 152,
	"trail_marker": 76,
}

## GEOMETRIA LOCULUI, toata din survey — nu din brief si nu din ochi.
## Tablierul: z = -155, de la x = -3 (far) la x = 31 (near), cota -20.00.
const POD_Z := -155.0
const POD_X_NEAR := 31.0
const POD_X_FAR := -3.0
const POD_Y := -20.0
## Podeaua bazinului, masurata plata pe z = -205..-105 si x = -28..+20.
const PODEA_Y := -40.30
const PODEA_X0 := -28.0
const PODEA_X1 := 20.0
const PODEA_Z0 := -205.0
const PODEA_Z1 := -105.0

## RAUL. Curge in lungul bazinului, pe Z (adica PERPENDICULAR pe pod, deci
## trece PE SUB tablier si se vede in ambele sensuri de pe el) — asta e
## singura orientare pe care firul de apa se citeste ca rau si nu ca balta.
## Firul e la x = 6, adica la 8 m de mijlocul tablierului (x=14): apa trece
## sub pod dar nu fix pe axa lui, ca in bara.
const RAU_X := 6.0
const RAU_Z0 := -198.0
const RAU_Z1 := -112.0
## Semi-latimea albiei. Podeaua are 48 m; un rau de 48 m ar fi un lac.
## In bara firul de apa e o dunga subtire in fundul crapaturii: 5 m.
const RAU_HALF := 5.0
## Luciul. Podeaua e plata la -40.30, deci luciul NU poate fi mai jos (ar
## disparea sub pamant, lectia rundei 19 de la POI F) si nici mult mai sus
## (ar fi un film peste iarba). Fereastra e ingusta: +0,18 m peste podea.
const RAU_Y := -40.12

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _tri := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _total_len := 1.0
var _shadow := Vector3.ZERO


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	for i in 4:
		await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 200.0
	_rng.seed = 560064
	_survey()
	if not _survey_only:
		_build()
		_write()
	get_tree().quit(0)


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


## Profilul real al terenului pe intervalul meu. Cifrele din antet vin de aici.
func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		_shadow = Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z,
			_shadow.x, _shadow.z, rad_to_deg(asin(-dir.y))])
	# Unde e podul, in fractii, si ce cota are solul REAL sub el.
	var pod := _track.find_child("PodFranghie", true, false) as Node3D
	if pod != null:
		var ne: Vector3 = pod.global_transform * (pod.get("near_end") as Vector3)
		var fe: Vector3 = pod.global_transform * (pod.get("far_end") as Vector3)
		var mid := (ne + fe) * 0.5
		print("; POD: near %s  far %s  mid %s  latime %.1f" % [
			str(ne.round()), str(fe.round()), str(mid.round()),
			float(pod.get("deck_width"))])
		for nm: String in ["near", "mid", "far"]:
			var w: Vector3 = ne if nm == "near" else (fe if nm == "far" else mid)
			print(";   %-5s frac %.4f  y_tablier %+.2f  SOL_REAL %+.2f  => GOL %.2f m" % [
				nm, _frac_of(w.x, w.z), w.y, _sol_real(w.x, w.z),
				w.y - _sol_real(w.x, w.z)])
	var n := _track.baked.size()
	print("; frac      ax(x,z)          y_drum  half  side(x,z)      sol la -60 -40 -25 -15 -8 -3 | +3 +8 +15 +25 +40 +60")
	var f := F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-60.0, -40.0, -25.0, -15.0, -8.0, -3.0,
				3.0, 8.0, 15.0, 25.0, 40.0, 60.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %6.1f  %4.1f  (%+.2f,%+.2f)  %s" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols)])
		f += 0.005
	# UNGHIUL DIN OCHIUL CAMEREI, nu panta pe harta (lectia valului 2): cat de
	# jos trebuie sa privesti de la 10 m peste ax ca sa vezi solul la N metri
	# lateral. Sub ~12 grade nu se citeste cadere, oricat de adanca ar fi.
	print("; unghi de coborare din ochiul soferului (y_ax + 10 m) spre sol lateral:")
	f = F_IN
	while f <= F_OUT + 0.001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var eye := p + Vector3(0.0, 10.0, 0.0)
		var line := "; %.3f " % f
		for sgn: float in [-1.0, 1.0]:
			var best := 0.0
			for off: float in [4.0, 6.0, 8.0, 12.0, 18.0, 25.0, 35.0, 50.0]:
				var q := p + s * (sgn * off)
				var gy := _sol_real(q.x, q.z)
				var ang := rad_to_deg(atan2(eye.y - gy, off))
				best = maxf(best, ang)
			line += " %s max %5.1f deg " % ["st" if sgn < 0.0 else "dr", best]
		print(line)
		f += 0.01


func _frac_of(x: float, z: float) -> float:
	var n := _track.baked.size()
	var best := 0
	var bd := 1e9
	for j in n:
		var d: float = Vector2(_track.baked[j].x - x, _track.baked[j].z - z).length_squared()
		if d < bd:
			bd = d
			best = j
	return float(best) / float(n)


func _step(meters: float) -> float:
	return meters / _total_len


func _build() -> void:
	_rau()
	# Ordinea NU e cosmetica: `_spuma` citeste `_pietre_ude` ca sa puna albul
	# unde apa chiar loveste piatra. Daca bolovanii s-ar aseza dupa spuma,
	# lista ar fi goala si spuma ar cadea uniform — adica exact „covorul de
	# nuferi" pe care POI F l-a reclamat.
	_alege_pietre_ude()
	_spuma()
	_bolovani_albie()
	_pereti()
	_coame()
	_capete_pod()


func _write() -> void:
	print("; asezate %d piese, ~%d triunghiuri" % [_n, _tri])
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


## Cota SOLULUI din coliziunea reala a TERENULUI, nu din campul neted
## (memoria terrain-mesh-y-extrapoleaza) si nu de pe PLACILE PODULUI.
##
## CAPCANA LUI E, verificata de lead inainte sa pornesc: o raza verticala sub
## tablier loveste `Plate3`/`Plate7` (AnimatableBody3D ale hazardului) si
## raporteaza „gol 0". Filtrul e pe RID-ul lui TerrainBody: se continua sub
## orice alt corp pana se atinge terenul.
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1400.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 48:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)


## ============================================================
## RAUL — firul alb din fundul crapaturii (bara).
## ============================================================
## De ce apa si de ce acolo. In captura de baza (E_r0_0.556.png) podeaua de
## 100x50 m e complet goala, si o gaura goala de 20 m n-are SCARA: ochiul nu
## are cu ce sa masoare cat de adanc e. Firul de apa e lucrul care da scara,
## si e exact ce se vede in bara sub tablier.
##
## Sloturile, RUNDA 2, alese pe masuratoarea proprie a barei (nu preluate):
##   apa din BARA     rgb( 95, 97, 98) H 208,2  S 0,03  V 0,39  R-B  -3
## Runda 1 folosise perechea lui POI F (6 ASPHALT_EDGE + 5 ASPHALT) si a iesit
## rgb(123,119,108) H 44,6 S 0,12 — adica pe partea CALDA a rotii, fiindca
## slotul 6 e #696765, H 30 / R-B +4. Sloturile s-au reales dupa cele trei
## cifre ale barei, dintre cele deja folosite pe pista:
##   5  ASPHALT         #4B4B4D H 240  S 0,03  V 0,30  R-B  -2  <- apa mica
##   20 VOLCANIC_BLACK  #55535A H 257  S 0,08  V 0,35  R-B  -5  <- ochiuri
## Amandoua neutre-reci, cu saturatia exact pe cifra barei (0,03 si 0,08 fata
## de 0,03). ZERO materiale noi: sunt sloturi de atlas, nu clase.
## Memoria `apa-iluminata-v12`: culoarea NU vine din slot, contrastul vine din
## spuma alba si din pietre. Un gri singur pe iarba citeste asfalt; acelasi
## gri intre bolovani si spuma citeste apa.
func _rau() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var pos_d: PackedVector3Array = []
	var yaw_d: PackedFloat32Array = []
	var tries := 0
	while pos.size() + pos_d.size() < 900 and tries < 60000:
		tries += 1
		var z := _rng.randf_range(RAU_Z0, RAU_Z1)
		# Albia serpuieste: un fir drept pe 86 m citeste ca un canal, nu ca rau.
		var mid := RAU_X + sin((z + 155.0) * 0.045) * 4.5
		# Clepsidra: se stramteaza pe praguri, se largeste in bulboane.
		var half := RAU_HALF * (0.62 + 0.38 * absf(sin((z + 155.0) * 0.031)))
		var o := _rng.randf_range(-half, half)
		var x := mid + o
		var g := _sol_real(x, z)
		# Malul taie apa singur: unde terenul real urca peste luciu, nu se pune
		# placa. Cerinta creste spre margine, ca sa nu se vada muchia de caseta
		# (lectia rundei 2 a lui F: o placa de apa pe iarba e un autocolant).
		var m: float = 1.0 - clampf(absf(o) / half, 0.0, 1.0)
		var need: float = lerpf(0.30, 0.01, clampf(m / 0.25, 0.0, 1.0))
		if g > RAU_Y - need:
			continue
		# Si nu trece de podea in jos: dincolo de bazin terenul cade in rapa.
		if g < RAU_Y - 3.0:
			continue
		if absf(g - PODEA_Y) > 1.2:
			continue
		if _rng.randf() < 0.24:
			pos_d.append(Vector3(x, RAU_Y - 0.03, z))
			yaw_d.append(_rng.randf_range(0.0, TAU))
		else:
			pos.append(Vector3(x, RAU_Y, z))
			yaw.append(_rng.randf_range(0.0, TAU))
	if pos.is_empty():
		print("; ATENTIE: albia e goala — luciul e sub tot terenul")
		return
	_disc_flock("E_Luciu", 5, 4.2, 0.85, 1.35, pos, yaw, 56001)
	if not pos_d.is_empty():
		_disc_flock("E_LuciuAdanc", 20, 3.4, 0.8, 1.2, pos_d, yaw_d, 56002)
	print("; rau: %d placi luciu + %d ochiuri adanci, din %d incercari" % [
		pos.size(), pos_d.size(), tries])


## SPUMA — `FOAM_WHITE` (22), albul din bara.
## Nu se imprastie uniform: spuma se face UNDE APA LOVESTE CEVA. Aici, pe
## pietrele din albie (`_wet_rocks`, umplut de `_bolovani_albie`) si pe
## stramtorile firului. Memoria `particule-muchia-nu-numarul`: conteaza unde
## cade, nu cate sunt.
func _spuma() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	var tries := 0
	while pos.size() < 42 and tries < 40000:
		tries += 1
		var z := _rng.randf_range(RAU_Z0 + 4.0, RAU_Z1 - 4.0)
		var mid := RAU_X + sin((z + 155.0) * 0.045) * 4.5
		var half := RAU_HALF * (0.62 + 0.38 * absf(sin((z + 155.0) * 0.031)))
		# Spuma sta pe primii doi treimi de albie, nu pe mal.
		var o := _rng.randf_range(-half * 0.8, half * 0.8)
		var x := mid + o
		var g := _sol_real(x, z)
		if g > RAU_Y - 0.02 or absf(g - PODEA_Y) > 1.2:
			continue
		# Preferinta pentru stramtori (unde `half` e mic) si pentru vecinatatea
		# unei pietre ude.
		var strans: float = 1.0 - clampf((half - RAU_HALF * 0.62)
			/ (RAU_HALF * 0.38), 0.0, 1.0)
		var langa_piatra := false
		for r in _pietre_ude:
			if Vector2(x - r.x, z - r.y).length() < r.z + 1.6:
				langa_piatra = true
				break
		# RUNDA 2: spuma NUMAI langa piatra. Masurat pe E_r1_0.556.png, spuma
		# facea 9,1% din cadru fata de 0,0% (12 pixeli) pe bara — adica nu
		# citea ca repezis, citea ca petice de zapada. Un repezis face alb
		# acolo unde apa LOVESTE ceva, nu pe toata albia.
		if not langa_piatra:
			continue
		var p_accept: float = 0.25 + strans * 0.5
		if _rng.randf() > p_accept:
			continue
		pos.append(Vector3(x, RAU_Y + 0.05, z))
		yaw.append(_rng.randf_range(0.0, TAU))
		# Scalare NEUNIFORMA: o creasta de repezis e LUNGA si INGUSTA. Cu
		# discuri egale iese un covor de nuferi (lectia rundei 3 a lui F).
		sc3.append(Vector3(_rng.randf_range(0.5, 0.9), 1.0,
			_rng.randf_range(1.2, 2.2)))
	if pos.is_empty():
		return
	_disc_flock("E_Spuma", 22, 0.45, 1.0, 1.0, pos, yaw, 56003, sc3)
	print("; spuma: %d creste, din %d incercari" % [pos.size(), tries])


## Pietrele din ALBIE, retinute ca ancore de spuma: (x, z, raza).
var _pietre_ude: Array[Vector3] = []


## BOLOVANII DIN ALBIE — piatra intre care curge apa (bara: repezisuri printre
## bolovani). Pozitiile sunt alese de `_alege_pietre_ude`, care ruleaza
## INAINTEA spumei tocmai ca spuma sa aiba de ce sa se agate.
func _bolovani_albie() -> void:
	var loturi := {}
	for r in _pietre_ude:
		var mdl: String = "moss_boulder_a"
		if r.z > 1.3:
			mdl = "moss_boulder_c"
		elif r.z > 0.7:
			mdl = "moss_boulder_b"
		var g := _sol_real(r.x, r.y)
		# Bolovanul sta PE fundul albiei, cu talpa ingropata: o piatra de rau
		# nu pluteste pe luciu.
		var sx := _rng.randf_range(0.8, 1.35)
		_lot_add(loturi, mdl, Vector3(r.x, g - 0.18, r.y),
			_rng.randf_range(0.0, TAU),
			Vector3(sx, _rng.randf_range(0.7, 1.1), sx * _rng.randf_range(0.85, 1.2)))
	var tot := 0
	for mdl: String in loturi.keys():
		var d: Dictionary = loturi[mdl]
		var pp: PackedVector3Array = d["pos"]
		if pp.is_empty():
			continue
		tot += pp.size()
		_model_flock("E_PiatraAlbie_%s" % mdl, RES[mdl], pp, d["yaw"],
			d["sc"], 56010 + tot, "inca_stone")
	print("; bolovani in albie: %d" % tot)


## Alege pozitiile pietrelor din albie. Separat de `_bolovani_albie` fiindca
## spuma are nevoie de ele mai devreme (vezi comentariul din `_build`).
func _alege_pietre_ude() -> void:
	var tries := 0
	while _pietre_ude.size() < 85 and tries < 20000:
		tries += 1
		var z := _rng.randf_range(RAU_Z0 + 2.0, RAU_Z1 - 2.0)
		var mid := RAU_X + sin((z + 155.0) * 0.045) * 4.5
		var half := RAU_HALF * (0.62 + 0.38 * absf(sin((z + 155.0) * 0.031)))
		# Pietrele stau si IN apa si pe prundisul de langa ea.
		var o := _rng.randf_range(-half * 1.5, half * 1.5)
		var x := mid + o
		var g := _sol_real(x, z)
		if absf(g - PODEA_Y) > 1.4:
			continue
		var r := _rng.randf_range(0.35, 1.9)
		var prea_aproape := false
		for q in _pietre_ude:
			if Vector2(x - q.x, z - q.y).length() < r + q.z + 0.9:
				prea_aproape = true
				break
		if prea_aproape:
			continue
		_pietre_ude.append(Vector3(x, z, r))
	print("; pietre in albie alese: %d din %d incercari" % [
		_pietre_ude.size(), tries])


## ============================================================
## PERETII DEFILEULUI — piatra unde `scarp_tint` nu ajunge.
## ============================================================
## Masuratoarea care decide asta (SvMpE3): peretii bazinului au 16-38 de grade,
## iar `scarp_tint` din tema porneste la 28 si da roca plina abia la 38. Deci
## pe fasia de 16-28 de grade — exact cea pe care o vezi venind spre pod —
## peretele e IARBA. In captura se vede fara dubiu: doua petice cenusii mici,
## in rest versant verde de la podea la coama.
##
## NU schimb `scarp_slope_deg`: tema e a INTREGII piste, iar un prag coborat la
## 16 grade ar transforma in stanca toate dealurile domoale din tur — inclusiv
## POI-uri deja judecate. Materia vine din PIESE, pe fasia care n-o are.
##
## Piesele: `moss_boulder_*`, clasa `inca_stone`. Bolovanul are muschi pe capac
## (slot 12), deci nu e piatra sterila — e exact peretele din bara, care are
## verde agatat pe stanca.
func _pereti() -> void:
	var loturi := {}
	var puse := 0
	var tries := 0
	while puse < 430 and tries < 90000:
		tries += 1
		# Peretele: inelul din jurul podelei, intre buza bazinului si fund.
		var z := _rng.randf_range(PODEA_Z0 - 6.0, PODEA_Z1 + 6.0)
		var x := _rng.randf_range(PODEA_X0 - 34.0, PODEA_X1 + 40.0)
		var g := _sol_real(x, z)
		# Doar pe VERSANT: intre 1,5 m peste podea si 2 m sub buza.
		if g < PODEA_Y + 1.2 or g > POD_Y - 1.0:
			continue
		# Panta reala in punctul asta, din patru raze vecine.
		var d := 3.0
		var gx := (_sol_real(x + d, z) - _sol_real(x - d, z)) / (2.0 * d)
		var gz := (_sol_real(x, z + d) - _sol_real(x, z - d)) / (2.0 * d)
		var panta := rad_to_deg(atan(sqrt(gx * gx + gz * gz)))
		# FASIA CARE N-ARE TENTA: sub 30 de grade `scarp_tint` e zero sau
		# aproape. Peste 34 terenul se descurca singur si piatra ar fi dubla.
		if panta < 9.0 or panta > 34.0:
			continue
		# Cu cat panta e mai mica, cu atat tenta lipseste mai tare, deci cu
		# atat mai multa piatra: probabilitatea e INVERSA pantei.
		var p_accept: float = clampf(1.0 - (panta - 9.0) / 28.0, 0.15, 1.0)
		if _rng.randf() > p_accept:
			continue
		if not _departe_de_drum(x, z, 7.0):
			continue
		var mdl: String = ["moss_boulder_c", "moss_boulder_b",
			"moss_boulder_b", "moss_boulder_a"][_rng.randi() % 4]
		# Bolovanii de perete sunt MARI: la 20-40 m de ochi, o piatra de 1 m
		# subintinde cat nimic. Se scaleaza 1,6-3,4x, dar NEUNIFORM, ca sa nu
		# iasa un sir de bile egale.
		# RUNDA 2: scara coborata de la 1,6-3,4 la 0,9-2,0. Masurat pe
		# E_r1_0.540.png: piatra iesea V 0,86 fata de 0,59 pe bara, si pe
		# captura se vede de ce — doi bolovani de ~10 m flancau drumul ca
		# niste dune si ACOPEREAU chiar defileul pe care trebuiau sa-l
		# descrie. Nu e o problema de culoare (la 0.556, unde sunt departe,
		# piatra mea da V 0,58 fata de 0,59 pe bara), e una de SCARA.
		var sx := _rng.randf_range(0.9, 2.0)
		_lot_add(loturi, mdl, Vector3(x, g - 0.25, z), _rng.randf_range(0.0, TAU),
			Vector3(sx, sx * _rng.randf_range(0.55, 0.95),
				sx * _rng.randf_range(0.8, 1.3)))
		puse += 1
	var tot := 0
	var k := 0
	for mdl: String in loturi.keys():
		var dd: Dictionary = loturi[mdl]
		var pp: PackedVector3Array = dd["pos"]
		if pp.is_empty():
			continue
		tot += pp.size()
		k += 1
		_model_flock("E_PeretePiatra_%s" % mdl, RES[mdl], pp, dd["yaw"],
			dd["sc"], 56100 + k, "inca_stone")
	print("; perete: %d bolovani pe fasia de 9-34 grade, din %d incercari" % [
		tot, tries])


## ============================================================
## COAMELE — verdele inchis dens din bara.
## ============================================================
## In bara, ambele buze ale defileului sunt INCORONATE de vegetatie inchisa,
## deasa: silueta zimtata care separa stanca palida de cer. La noi coama e
## goala, iar peretele si pajistea de deasupra sunt acelasi verde uniform —
## deci nu exista muchie. Coroana de copaci e ce DESENEAZA buza.
##
## Piesele stau pe BUZA, adica acolo unde panta se rupe, si numai unde nu intra
## in banda drumului.
func _coame() -> void:
	var loturi := {}
	var puse := 0
	var tries := 0
	while puse < 165 and tries < 80000:
		tries += 1
		var z := _rng.randf_range(PODEA_Z0 - 14.0, PODEA_Z1 + 14.0)
		var x := _rng.randf_range(PODEA_X0 - 44.0, PODEA_X1 + 50.0)
		var g := _sol_real(x, z)
		# BUZA: sus, aproape de cota drumului, dar cu golul langa ea.
		if g < POD_Y - 4.5 or g > POD_Y + 8.0:
			continue
		# Chiar e o buza? Se cere ca la 9 m INSPRE bazin terenul sa fi cazut
		# cel putin 4 m. Altfel e pajiste, si un copac pe pajiste nu deseneaza
		# nicio muchie.
		var spre := Vector2(14.0 - x, -155.0 - z)
		if spre.length() < 1.0:
			continue
		spre = spre.normalized()
		var g9 := _sol_real(x + spre.x * 9.0, z + spre.y * 9.0)
		if g - g9 < 4.0:
			continue
		if not _departe_de_drum(x, z, 9.0):
			continue
		var mdl: String
		var r := _rng.randf()
		if r < 0.36:
			mdl = "polylepis_b"
		elif r < 0.66:
			mdl = "polylepis_a"
		elif r < 0.85:
			mdl = "tree_fern"
		else:
			mdl = "bamboo_clump"
		# Inaltimile in METRI, impartite la inaltimea masurata a piesei.
		var meters: float
		match mdl:
			"polylepis_b":
				meters = _rng.randf_range(7.0, 11.0)
			"polylepis_a":
				meters = _rng.randf_range(4.5, 7.5)
			"tree_fern":
				meters = _rng.randf_range(3.2, 5.2)
			_:
				meters = _rng.randf_range(4.5, 7.0)
		var sc := meters / float(HEIGHT[mdl])
		_lot_add(loturi, mdl, Vector3(x, g - 0.12, z), _rng.randf_range(0.0, TAU),
			Vector3(sc * _rng.randf_range(0.85, 1.15), sc,
				sc * _rng.randf_range(0.85, 1.15)))
		puse += 1
	var tot := 0
	var k := 0
	for mdl: String in loturi.keys():
		var dd: Dictionary = loturi[mdl]
		var pp: PackedVector3Array = dd["pos"]
		if pp.is_empty():
			continue
		tot += pp.size()
		k += 1
		# CLASA: NICIUNA, si asta e o revenire masurata, nu o omisiune.
		#
		# Runda 2 pusese `macchia` pe coama, cu argumentul ca verdele meu e
		# V 0,63 fata de 0,29 pe bara. Masurat DUPA, argumentul nu sta:
		#   (a) probe_decor a urcat de la 19 la 20 de materiale — deci
		#       `macchia` NU era deja in cele 19, cum scrisese comentariul
		#       (memoria `justificarea-din-comentariu-se-verifica`);
		#   (b) si n-a cumparat nimic: verdele a ramas V 0,63 / 28,2% fata de
		#       V 0,61 / 26,7% inainte. Fiindca verdele masurat in cadru e
		#       IARBA DE TEREN, nu frunzisul meu — 165 de copaci nu misca un
		#       versant intreg.
		# Un material care nu cumpara nimic se da inapoi. Tenta verdelui de
		# teren e a temei, deci nu e a POI-ului meu.
		_model_flock("E_Coama_%s" % mdl, RES[mdl], pp, dd["yaw"], dd["sc"],
			56200 + k)
	print("; coame: %d piese de vegetatie pe buza, din %d incercari" % [
		tot, tries])


## ============================================================
## CAPETELE TABLIERULUI — podul pleaca de pe PIATRA, nu din iarba.
## ============================================================
## In captura de baza tablierul se termina intr-un gazon: turnurile din cod
## (TOWER_SIZE, patru cutii) sunt singura piatra din cadru si sunt prea mici ca
## sa citeasca drept ancoraj. Brief-ul cere "buza de plecare".
##
## NU construiesc podul (capcana contractului): las turnurile in pace si pun
## PIATRA IN JURUL LOR — masa de stanca din care ies cablurile.
func _capete_pod() -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var sc3: Array[Vector3] = []
	for capat: float in [POD_X_NEAR, POD_X_FAR]:
		# Sensul "spre afara din gaura" la fiecare capat.
		var spre: float = 1.0 if capat > 14.0 else -1.0
		var k := 0
		while k < 90:
			k += 1
			# Banda dincolo de capat, pe ambele parti ale tablierului (latimea
			# 11 m, deci de la 6,8 m lateral in afara).
			var dx := capat + spre * _rng.randf_range(2.0, 15.0)
			var side: float = 1.0 if _rng.randf() < 0.5 else -1.0
			var dz := -155.0 + side * _rng.randf_range(6.8, 17.0)
			var g := _sol_real(dx, dz)
			# Numai pe versantul de sub buza, nu pe pajistea de deasupra.
			if g > POD_Y - 0.4 or g < POD_Y - 17.0:
				continue
			if not _departe_de_drum(dx, dz, 6.0):
				continue
			pos.append(Vector3(dx, g - 0.3, dz))
			yaw.append(_rng.randf_range(0.0, TAU))
			# Scara, ca la perete: acestia sunt cei mai APROAPE de ochi, deci
			# cei care au blocat cadrul la runda 1. 1,0-2,2 in loc de 1,8-3,6.
			var sx := _rng.randf_range(1.0, 2.2)
			sc3.append(Vector3(sx, sx * _rng.randf_range(0.6, 1.0),
				sx * _rng.randf_range(0.85, 1.25)))
	if pos.is_empty():
		print("; ATENTIE: niciun bolovan de ancoraj n-a incaput")
		return
	_model_flock("E_AncorajPod", RES["moss_boulder_c"], pos, yaw, sc3,
		56300, "inca_stone")
	print("; ancoraj pod: %d bolovani la cele doua capete" % pos.size())


## ============================================================
## GARDA DE BANDA si emiterea
## ============================================================
## Marja peste semi-latime in care ProbeLaneClear inca vede piesa: sonda
## plimba cutia masinii (2,2 x 1,4 x 4,2) la lat = 0 si +-half/3, plus 6 m de
## anticipare pe directia de mers.
const LANE_MARGIN := 2.6


## E LIBERA BANDA? Testul e fata de TOATE punctele coapte ale traseului, nu
## doar fata de POI-ul meu: bucla trece de mai multe ori prin acelasi colt de
## harta, si o piesa la 30 m lateral poate cadea pe alta bucla.
## Verticala conteaza: o piesa din fundul gaurii sta cu 20 m sub sosea, deci nu
## e in banda ei — altfel nimic din defileu n-ar mai incapea.
func _departe_de_drum(x: float, z: float, r: float) -> bool:
	var n := _track.baked.size()
	var y := _sol_real(x, z)
	for i in n:
		var p: Vector3 = _track.baked[i]
		# Scaparea cinstita pe verticala: piesa e cu mult sub cota soselei,
		# deci gabaritul masinii trece pe deasupra ei.
		if y + 12.0 < p.y:
			continue
		var dx := x - p.x
		var dz := z - p.z
		var need: float = _track.width_at_index(i) + LANE_MARGIN + r
		if dx * dx + dz * dz < need * need:
			return false
	return true


func _disc_flock(nume: String, slot: int, radius: float, smin: float,
		smax: float, pos: PackedVector3Array, yaw: PackedFloat32Array,
		sid: int, sc3: Array[Vector3] = []) -> void:
	_n += pos.size()
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [nume, ZONE])
	_out.append('script = ExtResource("flock")')
	_out.append("disc_slot = %d" % slot)
	_out.append("disc_radius = %.2f" % radius)
	_out.append("scale_min = %.2f" % smin)
	_out.append("scale_max = %.2f" % smax)
	_out.append("seed_value = %d" % sid)
	# Apa si spuma sunt un NIVEL, nu o depunere: `snap_to_ground` le-ar tari pe
	# fundul albiei si ar disparea sub pietre (lectia POI F).
	_out.append("snap_to_ground = false")
	_out.append("positions = %s" % var_to_str(pos).replace("\n", ""))
	_out.append("yaws = %s" % var_to_str(yaw).replace("\n", ""))
	if sc3.size() == pos.size() and not sc3.is_empty():
		_out.append("scale3_list = %s" % var_to_str(sc3).replace("\n", ""))
	_out.append("")


## Un lot de piese de kit ca MultiMesh (un desen, zero corpuri fizice).
func _model_flock(nume: String, res_id: String, pos: PackedVector3Array,
		yaw: PackedFloat32Array, sc3: Array[Vector3], sid: int,
		tri_class: String = "") -> void:
	_n += pos.size()
	for m: String in TRI.keys():
		if RES.get(m, "") == res_id:
			_tri += int(TRI[m]) * pos.size()
			break
	_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [nume, ZONE])
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("%s")' % res_id)
	if tri_class != "":
		_out.append('tri_class = "%s"' % tri_class)
	_out.append("seed_value = %d" % sid)
	_out.append("snap_to_ground = false")
	_out.append("positions = %s" % var_to_str(pos).replace("\n", ""))
	_out.append("yaws = %s" % var_to_str(yaw).replace("\n", ""))
	_out.append("scale3_list = %s" % var_to_str(sc3).replace("\n", ""))
	_out.append("")


## APPEND PE PACKED IN DICTIONAR — memoria `append-pe-copie-in-array-netipizat`,
## si m-a costat prima rulare (686 placi de apa dar 0 bolovani, 0 perete, 0
## coama). `PackedVector3Array` e tip VALOARE in GDScript: `(d["pos"] as
## PackedVector3Array).append(v)` scrie in COPIA facuta de cast, iar
## dictionarul ramane neatins. Se citeste, se adauga, se scrie inapoi.
func _lot_add(loturi: Dictionary, mdl: String, p: Vector3, y: float,
		sc: Vector3) -> void:
	if not loturi.has(mdl):
		loturi[mdl] = {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(),
			"sc": [] as Array[Vector3]}
	var d: Dictionary = loturi[mdl]
	var pp: PackedVector3Array = d["pos"]
	pp.append(p)
	d["pos"] = pp
	var yy: PackedFloat32Array = d["yaw"]
	yy.append(y)
	d["yaw"] = yy
	var ss: Array[Vector3] = d["sc"]
	ss.append(sc)
	d["sc"] = ss
