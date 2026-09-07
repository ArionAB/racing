extends Node
## Generator de decor MANUAL pentru POI A — CAMPUL DE SAFARI (Track14,
## frac 0.887-0.04, linia de start la 0.00). Nu e sonda: CALCULEAZA
## transformarile care se lipesc in Track14.tscn sub `DecorManual/ZoneA_Camp`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerA.tscn
##
## Ce decide compozitia, si de ce cifrele sunt astea (toate masurate cu
## ProbeFrac / raycast pe TerrainBody, nu presupuse):
##
## 1. ULTIMII 60 M DINAINTEA LINIEI SUNT UN AC DE PAR, NU O DREAPTA. Brief-ul
##    §2 A vorbea de „60 m dintre spartura si linie" pe o dreapta; pe Track14
##    real drumul de intoarcere vine spre est pe z~112-130 (0.93-0.97), face o
##    bucla la stanga cu apexul la (262.8, 149.3) (0.98) si intra pe dreapta
##    de start spre vest pe z=165 (0.99-0.04). Camera de la 0.97 (masinuta la
##    (251.2, 130.6), directia NE) priveste PESTE bucla, spre est-nord-est.
##    Deci kopje-ul sta in EXTERIORUL apexului, la 8 m de muchie: la 0.955
##    e la 60 m drept in fata (plafon 15,6 m > 14 m: leul se vede), la 0.97
##    la 41 m (plafon 13,8 m: leul chiar intra/iese din cadru), iar din
##    apex, la 15 m, varful nu se mai vede (10 + 0,093·15 = 11,4 < 13,2).
##    Asta e chiar contractul brief-ului: „intra in cadru de la 43 m".
##
## 2. SOARELE. Tema `serengeti` are sun_rotation_deg (-35, 135, 0); calculat
##    si VERIFICAT din DirectionalLight3D la rulare (se tipareste): lumina
##    merge catre (-0.58, -0.57, +0.58), deci umbrele cad spre NV (-x, +z).
##    Fata luminata a kopje-ului e cea de sud-est; tabara sta in fata lui pe
##    partea de SUD-VEST (spre drum si spre camera de la 0.97), ca sa nu
##    cada in umbra de 19 m a stancii (13,2 / tan 35°). Acacia din dreapta
##    drumului la 0.965-0.975 sta la SE de banda: umbra ei cade PE drum.
##
## 3. FRUSTUMUL DE LA 0.97. Camera e la (244, 10, 120), directia (0.57, 0.82),
##    FOV 68 vertical = ~100 orizontal. Tot ce e la sud-est de camera (bearing
##    > 85 grade fata de +z) NU e in cadru, oricat de aproape de masina ar
##    fi. De aceea animalele „din dreapta" stau in interiorul buclei (stanga
##    cadrului, 25-35 m) si in spatele taberei (dreapta, 60-80 m), nu la SE.
##
## 4. ANIMALE STATICE la 15-40 m de banda dupa brief. In interiorul buclei
##    (intre drumul de intoarcere si dreapta de start) sunt doar 25-31 m
##    intre muchii, deci acolo distanta e 10-15 m — acceptata si raportata,
##    fiindca altfel primul plan din stanga cadrului hero ramane gol.
##    Nimic solid sub 0,5 m de muchie (garda de mai jos, masurata de la
##    MARGINEA piesei, nu de la centru).
##
## 5. LEUL sta pe PLATOUL kopje-ului, gasit din mesh (fetele cu normala in
##    sus din ultimii 2,5 m ai piesei), nu pe „13 m" din memorie. Coliziune
##    `none` (world_prop), deci nicio sonda de geometrie nu-l vede: se
##    verifica pe captura.

const TRACK := "res://scenes/tracks/Track14.tscn"
const KOPJE_GLB := "res://assets/models/serengeti/rocks/kopje_camp.glb"

## id-urile ext_resource asa cum sunt deja in Track14.tscn (handoff §1).
const RES := {
	"kopje_camp": "s_kopje_camp", "lion_kopje": "s_lion_kopje",
	"kopje_boulder_a": "s_kopje_boulder_a", "kopje_boulder_b": "s_kopje_boulder_b",
	"kopje_boulder_c": "s_kopje_boulder_c",
	"safari_tent": "s_safari_tent", "land_rover": "s_land_rover",
	"maasai_boma": "s_maasai_boma", "ankole_horns": "s_ankole_horns",
	"campfire": "s_campfire",
	"acacia_umbrella_a": "s_acacia_umbrella_a",
	"acacia_umbrella_b": "s_acacia_umbrella_b",
	"acacia_umbrella_c": "s_acacia_umbrella_c",
	"dead_tree": "s_dead_tree", "euphorbia": "s_euphorbia",
	"termite_mound_a": "s_termite_mound_a", "termite_mound_b": "s_termite_mound_b",
	"wildebeest": "s_wildebeest", "zebra": "s_zebra",
	"broadleaf_shrub": "s_broadleaf_shrub",
	"tropical_shrub": "s_tropical_shrub",
	"grass_tuft_large": "s_grass_tuft_large",
}

## Raza la baza (jumatate din latura mare a AABB, probe_serengeti_kit).
## Pentru copaci e raza COROANEI; trunchiul (coliziunea) e ~0,5 m.
const BASE_R := {
	"kopje_camp": 6.93, "lion_kopje": 1.45,
	"kopje_boulder_a": 1.08, "kopje_boulder_b": 2.03, "kopje_boulder_c": 2.80,
	"safari_tent": 2.82, "land_rover": 2.28, "campfire": 0.72,
	"maasai_boma": 4.20, "ankole_horns": 0.55,
	"acacia_umbrella_a": 4.45, "acacia_umbrella_b": 5.55, "acacia_umbrella_c": 6.24,
	"dead_tree": 2.36, "euphorbia": 0.92,
	"termite_mound_a": 0.95, "termite_mound_b": 1.64,
	"wildebeest": 1.28, "zebra": 1.00,
	"broadleaf_shrub": 0.85, "tropical_shrub": 0.75, "grass_tuft_large": 0.60,
}

## Modul de coliziune din world_prop.PROP_COLLISION (doar ca sa stim ce
## garda aplicam; NU se scrie in .tscn decat daca difera de implicit).
const TRUNK := ["acacia_umbrella_a", "acacia_umbrella_b", "acacia_umbrella_c",
	"dead_tree", "euphorbia"]
const GHOST := ["campfire", "lion_kopje", "ankole_horns",
	"broadleaf_shrub", "tropical_shrub", "grass_tuft_large"]

## Degajarea minima a ANIMALELOR fata de muchie (brief: 15-40 m; in
## interiorul buclei se accepta mai putin — nota 4).
const ANIMAL_GAP: float = 15.0

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _warn := 0
var _kopje_pos := Vector3.ZERO
var _kopje_yaw := 0.0
var _animal_pts: Array[Vector2] = []
var _solid_pts: Array[Vector2] = []


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 140001
	_geometry()
	_sun()
	_camp()
	_trees()
	_bushes()
	_animals()
	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente de degajare" % [_n, _warn])
	get_tree().quit(0)


## Axa soselei in intervalul POI-ului (0.88-1.0 si 0-0.05), la ~8 m: pozitie,
## latime, directia de mers si partea STANGA a soferului (side = +1 in
## conventia din track.gd: left = up x forward). Ca sa asezi dupa cifre, nu
## dupa memoria „drumul e drept pe z=165".
func _geometry() -> void:
	var n := _track.baked.size()
	var step := maxi(1, int(8.0 / (2098.7 / n)))
	var i := 0
	while i < n:
		var f := float(i) / float(n)
		if f >= 0.88 or f <= 0.05:
			var p := _track.baked[i]
			var q := _track.baked[(i + 1) % n]
			var fwd := (q - p).normalized()
			var left := Vector3.UP.cross(fwd).normalized()
			print("; ax %.3f  (%7.1f, %5.1f, %7.1f)  w %.1f  fwd (%.2f, %.2f)  stanga (%.2f, %.2f)"
				% [f, p.x, p.y, p.z, _track.width_at_index(i), fwd.x, fwd.z, left.x, left.z])
		i += step


## Directia REALA a luminii, din nodul scenei (memoria
## `azimutul-soarelui-fata-de-drum`: nu se deduce din euler, se citeste).
func _sun() -> void:
	var stack: Array[Node] = [_track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		var sun := nd as DirectionalLight3D
		if sun != null:
			var d := -sun.global_transform.basis.z
			var sh := Vector2(d.x, d.z).normalized()
			print("; soare: lumina merge catre (%.2f, %.2f, %.2f); umbra pe XZ catre (%.2f, %.2f); elevatie %.1f grade"
				% [d.x, d.y, d.z, sh.x, sh.y, rad_to_deg(asin(-d.y))])
			return
	print("; ATENTIE: nu am gasit DirectionalLight3D")


# ------------------------------------------------------------------ compozitia

## Runda 4 — INVERSAREA IERARHIEI, nu inca o apropiere. Criticul rundei 3 a
## masurat ca cele 3-6 cupole `maasai_boma` acopereau exact obiectele
## semnatura (fiecare Land Rover sub 1 % din latimea cadrului fata de 10-12 %
## in referinta). Cauza e geometrica, nu de compozitie: cupolele stateau la
## 27-40 m de camera, IN FATA masinilor care erau la 28-43 m.
##
## Masurat pe camera hero (frac 0.97: masina in (252.3, 131.6), directia
## (0.67, 0.74), camera 12.5 m in spate => (243.9, 122.3); FOV vertical 68,
## aspect 1340/780 => latimea cadrului = 2*d*tan(34)*1.718):
##   land_rover 4.5 m lung  ->  6.8 % la 28.4 m (vechea pozitie 268.5,136.5)
##                              9.6 % la 20.2 m (noua pozitie 263.0,129.0)
##                              7.4 % la 26.4 m (noua pozitie 268.0,133.0)
## Referinta: ~10-12 %. Deci prima masina trece de pragul cerut de critic
## (>= 3 %) cu marja, iar a doua o urmeaza in adancime.
##
## Ordinea pe raza de la camera decide ocluziunea, deci tabara e asezata pe
## ETAJE DE ADANCIME de-a lungul buzei exterioare a acului de par:
##   20-26 m : cele doua land_rover care flancheaza campfire  (PRIM PLAN)
##   27-33 m : cele doua safari_tent, retrase in spatele lor
##   38-48 m : maxim doua maasai_boma, lipite de kopje         (FUNDAL)
## Marginile solide sunt verificate de `_edge_gap` (marja 1.3-2.4 m la
## masini) si de ProbeLaneClear dupa.
func _camp() -> void:
	_kopje_pos = Vector3(294.0, 0.0, 147.0)
	_kopje_yaw = deg_to_rad(20.0)
	_world("kopje_camp", "kopje", _kopje_pos.x, _kopje_pos.z, _kopje_yaw, 1.0)
	_lion()
	# GRAMADA de granit: ciorchine de bolovani rotunjiti care leaga kopje-ul
	# de tabara. Impinsi in spatele etajului 3, ca sa nu intre in silueta
	# masinilor.
	_world("kopje_boulder_c", "bolovan", 285.5, 136.0, 0.9, 1.5)
	_world("kopje_boulder_c", "bolovan", 299.0, 134.5, 2.4, 1.8)
	_world("kopje_boulder_b", "bolovan", 285.5, 159.5, 2.3, 1.7)
	_world("kopje_boulder_b", "bolovan", 302.0, 156.0, 0.4, 1.5)
	_world("kopje_boulder_c", "bolovan", 305.0, 145.0, 4.0, 1.4)
	_world("kopje_boulder_a", "bolovan", 282.5, 165.0, 4.1, 1.4)
	_world("kopje_boulder_a", "bolovan", 291.0, 130.0, 5.2, 1.3)
	_world("kopje_boulder_a", "bolovan", 288.0, 142.5, 1.7, 0.9)
	_world("kopje_boulder_a", "bolovan", 283.0, 151.0, 0.3, 0.8)
	_world("kopje_boulder_a", "bolovan", 290.0, 154.5, 2.9, 0.8)

	# --- ETAJUL 1 (20-26 m): masinile flancheaza focul. Sunt PRIMUL lucru
	# din tabara pe raza camerei, deci nimic nu le mai poate ocluza.
	var vatra := Vector2(265.6, 131.6)
	# Parcate aproape paralel cu buza lateritului (buza stanga la 0.970 e
	# (257.1, 127.2), la 0.973 e (262.1, 133.3)), botul spre viraj — asa se
	# vede flancul lung, nu botul, si silueta ocupa latime maxima.
	_world("land_rover", "landRover", 263.0, 129.0,
		_yaw_to(Vector2(263.0, 129.0), Vector2(258.6, 124.8)), 1.0)
	_world("land_rover", "landRover", 268.0, 133.0,
		_yaw_to(Vector2(268.0, 133.0), Vector2(272.8, 137.6)), 1.0)
	# Focul INTRE ele, pe axa privirii. Emisiv pe slotul 30 (LAVA_ORANGE)
	# prin metadata `lumina` (world_prop._glow_spec).
	_world("campfire", "foc", vatra.x, vatra.y, 0.0, 1.15, "", "30|2.6")
	_world("ankole_horns", "coarne", 266.8, 128.2, 2.2, 1.0)

	# --- ETAJUL 2 (27-33 m): corturile cu prelata, retrase in spatele
	# masinilor, cu deschiderea spre vatra.
	_world("safari_tent", "cort", 268.5, 127.5,
		_yaw_to(Vector2(268.5, 127.5), vatra), 0.85)
	_world("safari_tent", "cort", 272.5, 134.5,
		_yaw_to(Vector2(272.5, 134.5), vatra), 0.80)
	_world("safari_tent", "cort", 273.0, 142.5,
		_yaw_to(Vector2(273.0, 142.5), Vector2(268.0, 140.0)), 0.75)
	# Al doilea foc, stins, langa corturi.
	_world("campfire", "vatra", 271.0, 130.5, 1.9, 0.8)

	# --- ETAJUL 3 (38-48 m): DOUA bome (nu sase), lipite de kopje. Raman ca
	# volum in fundal, dar nu mai sunt silueta taberei.
	_world("maasai_boma", "boma", 278.5, 146.5,
		_yaw_to(Vector2(278.5, 146.5), vatra), 0.95)
	_world("maasai_boma", "boma", 281.5, 155.0,
		_yaw_to(Vector2(281.5, 155.0), vatra), 0.85)
	_world("ankole_horns", "coarne", 277.5, 151.0, 5.0, 0.9)

	# Termitierele: una rosie la 9 m de muchie in dreapta drumului de
	# intoarcere (in cadrul hero, stanga, la 22 m de camera) si una in
	# interiorul buclei.
	_world("termite_mound_b", "termitiera", 266.0, 124.0, 1.1, 1.0)
	_world("termite_mound_a", "termitiera", 238.0, 152.0, 2.0, 1.0)
	# Euphorbia (candelabru, 4 m) la 4 m de muchie in dreapta la 0.965 si una
	# la nord de dreapta de start.
	_world("euphorbia", "euphorbia", 259.5, 119.5, 0.7, 1.0)
	_world("euphorbia", "euphorbia", 226.0, 176.5, 2.9, 1.1)
	_world("kopje_boulder_a", "bolovan", 240.0, 178.0, 1.7, 1.0)
	_world("kopje_boulder_a", "bolovan", 262.5, 122.5, 3.3, 0.8)


## Leul pe platoul kopje-ului: platoul se gaseste DIN MESH (nota 5).
func _lion() -> void:
	var scn := load(KOPJE_GLB) as PackedScene
	var inst := scn.instantiate()
	var mi: MeshInstance3D = null
	var stack: Array[Node] = [inst]
	while not stack.is_empty() and mi == null:
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		mi = nd as MeshInstance3D
	if mi == null:
		print("; ATENTIE: kopje_camp fara MeshInstance3D")
		return
	var faces := mi.mesh.get_faces()
	var xf := mi.transform
	var top := -INF
	for v in faces:
		top = maxf(top, (xf * v).y)
	print("; kopje: %d vertecsi in fete, varf local %.2f" % [faces.size(), top])
	var acc := Vector3.ZERO
	var area := 0.0
	var i := 0
	while i + 2 < faces.size():
		var a := xf * faces[i]
		var b := xf * faces[i + 1]
		var c := xf * faces[i + 2]
		i += 3
		var nrm := (b - a).cross(c - a)
		var ar := nrm.length() * 0.5
		if ar < 1e-6:
			continue
		nrm /= (ar * 2.0)
		var ctr := (a + b + c) / 3.0
		# Godot infasoara fetele in sens orar: (b-a)x(c-a) da normala SPRE
		# INTERIOR, deci fata de sus are nrm.y NEGATIV.
		if -nrm.y > 0.55 and ctr.y > top - 3.0:
			acc += ctr * ar
			area += ar
	inst.free()
	if area < 0.5:
		print("; ATENTIE: platou negasit pe kopje (arie %.2f)" % area)
		return
	var ctr_local := acc / area
	print("; kopje: varf %.2f m, platou (fete cu normala sus, ultimii 2,5 m) arie %.1f m2, centru local (%.2f, %.2f, %.2f)"
		% [top, area, ctr_local.x, ctr_local.y, ctr_local.z])
	var rot := Basis(Vector3.UP, _kopje_yaw)
	var w := _kopje_pos + rot * Vector3(ctr_local.x, 0.0, ctr_local.z)
	var g := _sol_real(_kopje_pos.x, _kopje_pos.z)
	# Leul priveste spre apexul buclei (spre lider, cand vine din ac).
	var yaw := _yaw_to(Vector2(w.x, w.z), Vector2(250.0, 135.0))
	_raw("lion_kopje", "leu", Vector3(w.x, g + ctr_local.y, w.z), yaw, 1.0, "", "")
	print("; leu la (%.2f, %.2f, %.2f), %.2f m peste sol" % [w.x, g + ctr_local.y, w.z, ctr_local.y])


## Acaciile-umbrela, copacii uscati, termitierele de pe dreapta si de pe ocol.
## Umbra cade spre NV (-0.71, +0.71), 12-14 m la 35 grade: un copac la SE de
## banda, cu trunchiul la 8-11 m de muchie, isi pune coroana de umbra PE drum.
func _trees() -> void:
	# Apexul: acacia mare la SE de bucla, trunchi la 11 m de muchie; umbra
	# (centru la (265,137)) cade pe carosabil in cadrul hero, in stanga.
	_world("acacia_umbrella_b", "acacia", 273.5, 129.0, 0.6, 1.0)
	# Drumul de intoarcere la 0.962: acacia la SE, trunchi la 4 m — umbra pe
	# banda in fata masinii pe apropiere (0.95-0.96).
	_world("acacia_umbrella_a", "acacia", 247.0, 115.5, 2.0, 1.0)
	# Dincolo de tabara, spre est: fundal.
	_world("acacia_umbrella_c", "acacia", 303.0, 130.0, 2.2, 1.0)
	_world("acacia_umbrella_a", "acacia", 300.0, 169.0, 4.0, 1.0)
	# Interiorul buclei: acacia la 5 m de muchia dreptei de start (muchia e la
	# z = 156: jumatatea de latime e 9 m pe grila, nu 4,5), dreapta cadrului
	# la 0.97; umbra pe dreapta de start la 0.99.
	_world("acacia_umbrella_a", "acacia", 247.0, 151.0, 1.4, 1.0)
	_world("dead_tree", "copacUscat", 215.0, 147.5, 0.3, 1.0)
	# Nordul dreptei de start (stanga soferului pe 0.99-0.04): coroane la
	# 4-8 m de muchie (muchia e la z = 174: jumatate de latime 9 m).
	_world("acacia_umbrella_b", "acacia", 236.0, 179.0, 5.1, 1.0)
	_world("acacia_umbrella_c", "acacia", 203.0, 180.0, 0.9, 1.0)
	_world("acacia_umbrella_b", "acacia", 165.0, 178.5, 3.7, 0.95)
	_world("acacia_umbrella_a", "acacia", 152.0, 182.0, 2.5, 1.05)
	_world("termite_mound_b", "termitiera", 176.0, 179.0, 0.5, 1.0)
	_world("termite_mound_a", "termitiera", 198.0, 152.0, 1.9, 1.1)
	# Sudul dreptei de start (interiorul buclei, muchia la z = 156): copacul
	# la SE arunca umbra pe banda.
	_world("acacia_umbrella_a", "acacia", 178.0, 150.5, 4.4, 1.0)
	_world("acacia_umbrella_c", "acacia", 142.0, 147.5, 1.1, 0.95)
	_world("dead_tree", "copacUscat", 128.0, 179.0, 2.1, 0.9)
	# Ocolul (0.887-0.95), drumul de intoarcere spre est pe z~112-127.
	_world("acacia_umbrella_c", "acacia", 190.0, 99.0, 0.2, 1.0)
	_world("acacia_umbrella_a", "acacia", 160.0, 130.0, 3.0, 1.0)
	_world("acacia_umbrella_b", "acacia", 110.0, 141.0, 1.6, 1.0)
	_world("dead_tree", "copacUscat", 95.0, 109.0, 0.8, 1.0)
	_world("termite_mound_b", "termitiera", 121.0, 105.0, 2.7, 1.0)
	_world("kopje_boulder_c", "bolovan", 205.0, 100.0, 1.3, 1.0)
	_world("kopje_boulder_b", "bolovan", 135.0, 102.0, 2.8, 1.0)
	_world("euphorbia", "euphorbia", 226.0, 108.5, 1.5, 1.0)


## Gnu si zebre STATICE, in grupuri care pasc cu capul in aceeasi directie.
## Referinta le are la 3-15 m de laterit, cu zecile; brief-ul zicea 15-40 m,
## dar la 30 m un gnu de 1,4 m e o pata de 20 px — nu se citeste ca turma
## (brief §2.0). Degajarea e 5 m de muchie (corp solid, ca un copac), NU pe
## drum; ProbeLaneClear + ProbeRace decid daca e prea aproape.
func _animals() -> void:
	# Interiorul buclei (dreapta cadrului hero, 15-30 m de camera). Referinta
	# are ZECI de animale in masa, cu corpuri care se SUPRAPUN — nu 8 puncte
	# rasfirate (lectia valului 1). Grupurile din cadrul hero sunt cele care
	# platesc, deci acolo sunt cele mai mari si cele mai indesate.
	_herd(Vector2(243.0, 144.0), 9.0, 7.0, 9, 5, Vector2(-1.0, 0.2), 4.0)
	_herd(Vector2(233.0, 168.0), 8.0, 5.0, 7, 4, Vector2(-1.0, 0.15), 4.0)
	# Sud de tabara, sub acacia mare (stanga cadrului hero, 20-30 m).
	_herd(Vector2(266.0, 121.5), 8.0, 5.5, 8, 4, Vector2(-0.9, 0.3), 4.0)
	_herd(Vector2(283.0, 116.0), 7.0, 5.0, 6, 3, Vector2(-0.8, 0.4), 4.0)
	# In spatele taberei, spre NE (fundal, 60-80 m): masa.
	_herd(Vector2(302.0, 178.0), 12.0, 8.0, 6, 3, Vector2(-0.6, -0.8), 6.0)
	# Nordul dreptei de start (stanga soferului pe 0.99-0.03), 6-13 m.
	_herd(Vector2(212.0, 184.0), 14.0, 3.5, 7, 3, Vector2(-1.0, 0.0), 5.0)
	# Sudul dreptei de start (dreapta soferului la 0.00-0.03), 6-12 m.
	_herd(Vector2(195.0, 147.0), 12.0, 3.0, 5, 2, Vector2(1.0, 0.1), 5.0)
	# Culoarul dintre drumuri (stanga soferului la 0.03), mai departe.
	_herd(Vector2(150.0, 140.0), 22.0, 2.5, 5, 2, Vector2(1.0, 0.1), 8.0)
	# Sudul ocolului (dreapta soferului pe 0.90-0.94).
	_herd(Vector2(150.0, 98.0), 20.0, 6.0, 4, 2, Vector2(0.9, -0.3), 8.0)


## TUFELE DE SAVANA — stratul care lipsea cel mai tare fata de ref_A.png.
## Referinta nu are „camp gol cu cateva obiecte": are un covor de tufe
## verde-inchis de 1-2 m, cu zeci de bucati pe cadru, INDESATE langa drum si
## rarindu-se in departare, plus smocuri de iarba mai mari intre ele. La noi
## solul era o singura nuanta pe toata adancimea (defectul 1 din memoria
## `patru-defecte-de-diorama`).
##
## Ele sunt fantome (coliziune `none`, GHOST): sute de corpuri fizice pentru
## obiecte de 1 m peste care masina trece oricum ar fi transformat campia in
## zid si ar fi picat ProbeLaneClear. Densitatea urmeaza banda soselei, pe
## AMBELE parti, cu jitter mare (>= 0.5 din pas, lectia valului 1) si scara
## variata, ca sa nu se citeasca grila.
func _bushes() -> void:
	var n := _track.baked.size()
	var step := maxi(1, int(4.0 / (2098.7 / n)))
	var i := 0
	while i < n:
		var f := float(i) / float(n)
		i += step
		if not (f >= 0.885 or f <= 0.045):
			continue
		var p := _track.baked[i % n]
		var q := _track.baked[(i + 1) % n]
		var fwd := (q - p).normalized()
		var left := Vector3.UP.cross(fwd).normalized()
		var w := _track.width_at_index(i % n)
		# 3 tufe per pas de 4 m, distribuite pe ambele parti, cu distanta
		# de la muchie trasa spre 1.5 m (aproape) si pana la 26 m (rar).
		# BUGET DE DESENE, nu de triunghiuri: fiecare tufa e un WorldProp,
		# adica UN draw call (DecorManual nu trece prin TrackDecorBatch).
		# 5 pe pas de 4 m au dat 1064 de desene pe pista (probe_decor) —
		# constrangerea reala pe mobil, chiar daca materialele raman 16.
		# 1 pe pas = ~230 de tufe pe intervalul POI-ului; covorul din
		# departare il face `dense_grass` (MultiMesh pe celule, 2 desene).
		for k in 1:
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			# sqrt inversat: mai multe aproape de drum decat departe.
			var t := _rng.randf()
			# +2.6 m de la muchie, nu 1.2: probe_manual masoara latimea cu
			# `width_at(frac_at(i))`, iar generatorul cu `width_at_index(i)`
			# — pe portiunile late (9 m) cele doua esantioane difera si 23
			# de tufe ieseau raportate „IN DRUM". Marja acopera diferenta.
			var dist := w + 2.6 + (t * t) * 30.0
			var along := _rng.randf_range(-2.0, 2.0)
			var c := p + fwd * along + left * (side * dist)
			# Doar doua piese: tufa cu frunza lata la scara MICA (0.35-0.7
			# = 0,6-1,2 m, tufa de savana; la 1.0+ frunzele citeau a
			# bananier tropical, masurat pe A_r1_bushes.png) si smocul de
			# iarba. Fara tropical_shrub: e alt bioclimat.
			var pick := _rng.randf()
			var mdl := "broadleaf_shrub"
			var scl := _rng.randf_range(0.35, 0.75)
			if pick > 0.62:
				# Smocul mare la 1.0 e de 1,6 m: ascundea picioarele
				# animalelor si citea a lan de porumb (A_r1_hero.png).
				# Sub 0.6 ramane tufa de iarba uscata, ca in referinta.
				mdl = "grass_tuft_large"
				scl = _rng.randf_range(0.35, 0.60)
			# Nu pe carosabil si nu peste corpurile deja asezate.
			if _edge_gap(Vector2(c.x, c.z)) < 2.2:
				continue
			var busy := false
			for o in _solid_pts:
				if o.distance_to(Vector2(c.x, c.z)) < 1.6:
					busy = true
					break
			if busy:
				continue
			_world(mdl, "tufa", c.x, c.z, _rng.randf_range(0.0, TAU), scl)


## Un grup: `n_gnu` gnu + `n_zebra` zebre intr-o elipsa `rx` x `rz` in jurul
## lui `c`, toate cu botul aproximativ spre `look` (+/- 35 grade).
func _herd(c: Vector2, rx: float, rz: float, n_gnu: int, n_zebra: int,
		look: Vector2, gap: float) -> void:
	var k := 0
	for j in n_gnu + n_zebra:
		var mdl := "wildebeest" if j < n_gnu else "zebra"
		var q := Vector2.ZERO
		var ok := false
		for attempt in 16:
			var ang := _rng.randf_range(0.0, TAU)
			var r := sqrt(_rng.randf_range(0.15, 1.0))
			q = c + Vector2(cos(ang) * rx * r, sin(ang) * rz * r)
			var free := true
			for o in _animal_pts:
				if o.distance_to(q) < 1.7:
					free = false
					break
			for o in _solid_pts:
				if o.distance_to(q) < 2.2:
					free = false
					break
			if free and _edge_gap(q) >= gap + BASE_R[mdl]:
				ok = true
				break
		if not ok:
			print("; ATENTIE: %s din grupul (%.0f, %.0f) nu incape la %.0f m de muchie; sarit" % [mdl, c.x, c.y, gap])
			continue
		_animal_pts.append(q)
		var l := look.rotated(_rng.randf_range(-0.6, 0.6))
		_world(mdl, "gnu" if mdl == "wildebeest" else "zebra", q.x, q.y,
			_yaw_to(q, q + l), _rng.randf_range(0.95, 1.05))
		k += 1


# ------------------------------------------------------------------ asezarea

## Yaw-ul pentru care -Z al nodului (fata) arata de la `from` spre `to`.
## Basis(UP, a) duce -Z in (-sin a, 0, -cos a), deci a = atan2(-d.x, -d.z).
func _yaw_to(from: Vector2, to: Vector2) -> float:
	var d := (to - from).normalized()
	return atan2(-d.x, -d.y)


## Distanta de la un punct de lume pana la MUCHIA benzii celei mai apropiate
## (negativa = pe carosabil).
func _edge_gap(q: Vector2) -> float:
	var best := INF
	var n := _track.baked.size()
	for i in n:
		var p := _track.baked[i]
		var d := Vector2(p.x, p.z).distance_to(q) - _track.width_at_index(i)
		if d < best:
			best = d
	return best


## Aseaza o piesa la coordonate de LUME; cota vine din raycast pe teren.
func _world(model: String, base: String, x: float, z: float, yaw: float,
		scl: float, mode: String = "", glow: String = "") -> void:
	var r: float = BASE_R.get(model, 0.6) * scl
	var solid_r := r
	if model in TRUNK:
		solid_r = 0.5 * scl
	elif model in GHOST:
		solid_r = 0.0
	var gap := _edge_gap(Vector2(x, z))
	if solid_r > 0.0 and gap - solid_r < 0.5:
		_warn += 1
		print("; ATENTIE %s (%s) la (%.1f, %.1f): marginea solida la %.2f m de muchie" % [
			model, base, x, z, gap - solid_r])
	if model in TRUNK and gap - r < 0.0:
		print("; nota %s la (%.1f, %.1f): coroana trece cu %.2f m peste muchie (trunchi la %.2f m)" % [
			model, x, z, r - gap, gap])
	if solid_r > 0.0:
		_solid_pts.append(Vector2(x, z))
	var g := _sol_real(x, z)
	_raw(model, base, Vector3(x, g, z), yaw, scl, mode, glow)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, glow: String) -> void:
	_n += 1
	# Baza se scrie pe RANDURI (memoria `tscn-transform-e-pe-randuri`), luata
	# dintr-un Basis real, nu compusa de mana.
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(scl, scl, scl))
	var fwd := -Basis(Vector3.UP, yaw).z
	_out.append('[node name="%s%d" parent="DecorManual/ZoneA_Camp" instance=ExtResource("%s")]'
		% [base, _n, RES[model]])
	_out.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.2f, %.2f, %.2f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z, pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	if glow != "":
		_out.append('metadata/lumina = "%s"' % glow)
	_out.append("")
	print("; %-16s %-12s la (%7.2f, %6.2f, %7.2f) fata (-Z) catre (%.2f, %.2f) scara %.2f" % [
		base + str(_n), model, pos.x, pos.y, pos.z, fwd.x, fwd.z, scl])


## Cota SOLULUI din coliziunea reala a panzei de teren (portat din
## gen_decor_capp_a.gd; memoria `terrain-mesh-y-extrapoleaza`).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
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
