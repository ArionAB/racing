extends SceneTree
## Garda de scena: masoara ce costa fiecare pista si arata DE UNDE vine costul
## (procedural din track.gd, sau dintr-un GLB anume).
##
## Doua metrici, cu roluri diferite:
##
## 1. MATERIALE (testul principal). Un material = (cel putin) un draw call, iar
##    draw call-urile sunt constrangerea reala pentru 60fps pe mid-range. Prinde
##    regresia clasica: cineva pune iar StandardMaterial3D.new() intr-o bucla de
##    decor si fiecare instanta isi capata materialul ei — atunci raportul
##    mesh-uri/material cade spre 1.0 si build-ul pica.
##
## 2. TRIUNGHIURI (doar instrumentare). Raportate mereu, dar NU dau verdict:
##    cifra e pe toata pista, iar ceata si visibility_range fac sa nu se
##    randeze niciodata toata in acelasi cadru. Vezi blocul de sub
##    `MAX_MATERIALS_PER_TRACK` pentru de ce plafonul a fost scos.
##
## Rulare (toate pistele, cod de iesire 1 daca vreuna pica):
##   godot --headless --path . --script res://tools/probe_decor.gd
## O singura pista, doar pentru raport:
##   godot --headless --path . --script res://tools/probe_decor.gd -- --track=2

## Cate mesh-uri procedurale trebuie sa imparta, in medie, un material.
## Masurat la introducerea garzii: Dunele 2.8 · Track02 7.8 · Track03 7.9.
## Dunele e cazul strans — are multe culori distincte legitime (asfalt, borduri,
## linii, gimmick-uri). Coborarea reala sub pragul asta cere atlasul de paleta,
## vezi docs/blender_export.md.
const MIN_MESHES_PER_MATERIAL: float = 2.5

## Cate materiale are voie o pista in total. ASTA e testul principal acum.
##
## Raportul mesh-uri/material a fost metrica principala si a incetat sa mai
## masoare ce trebuie, din doua motive care s-au compus:
##
## 1. Atribuirea era rupta (vezi VARIANT_SOURCE): 372 de prop-uri de pe atlas se
##    numarau ca "procedurale" pe Dunele, deci `proc_meshes` era umflat si
##    raportul iesea 16.76 in loc de 1.96. Garda trecea orice.
## 2. Chiar reparata, metrica PENALIZEAZA exact directia dorita. Pe masura ce
##    decorul migreaza din procedural in GLB-uri pe atlas, `proc_meshes` scade
##    (Dunele: 47) dar `proc_mats` ramane (drum, borduri, linii, pereti au nevoie
##    de culorile lor), deci raportul cade. Track02, cu decor procedural
##    ne-migrat, are 150/20 = 7.5 si "trece" desi are aceleasi ~20 de materiale.
##
## Numarul care conteaza de fapt e cat de multe materiale distincte randeaza o
## pista, fiindca ala e numarul de draw call-uri. Masurat la introducere:
## 26/23/24/23. Pragul prinde regresia clasica (un `StandardMaterial3D.new()`
## intr-o bucla de decor sare la sute), fara sa pedepseasca munca legitima.
##
## 34 -> 38 (august 2026, upgrade-ul grafic): planul de imbunatatire vizuala
## adauga cateva materiale de CLASA, deliberate si partajate — specular pe
## asfalt, trim sheet pentru roca, decal-uri de urme. Fiecare e o decizie, nu o
## scapare, iar clasa de accident pe care o vanam sare oricum la sute.
const MAX_MATERIALS_PER_TRACK: int = 38

## Cate mesh-uri procedurale sunt necesare ca raportul sa fie semnificativ.
const MIN_SAMPLE: int = 20

## Plafon de triunghiuri per pista, DERIVAT DIN MASURATOARE.
##
## Istoric, pentru ca cifra sa nu para inventata a doua oara:
##
## CLAUDE.md scria "~50k triunghiuri pe scena", dar cifra aia n-avea nimic in
## spate — fara sursa, fara test pe device, iar garda nici macar nu numara
## triunghiuri. Cand am inceput sa le numaram, pistele erau la 147-163k, din care
## ~110k veniti din primitive Godot lasate la rezolutia implicita (un SphereMesh
## are 64x32 = 4224 de triunghiuri; fiecare tufa de 40cm avea geometria unei
## planete). Dupa reparatie: 24-36k.
##
## Pragul a stat apoi la 100k, larg intentionat, cat timp se construia canionul —
## ca sa prinda exploziile accidentale fara sa blocheze munca pe o presupunere.
## A prins una reala: prima versiune a decorului pe benzi a sarit la 117k.
##
## Pragul a stat apoi la 80k: masuratoarea de atunci (~65k pe Dunele) plus ~20%.
##
## Cifra aia era prea stransa, si din motivul gresit. "Masuratoare + 20%" e o
## regula buna pentru un prag care prinde REGRESII, dar prost aplicata devine un
## plafon care blocheaza munca legitima: la prima benzinarie cu ferestre reale
## (1148 -> 4864 de triunghiuri, o singura instanta pe pista) am fi respins un
## asset corect fiindca depasea un numar derivat din cat de sarac era jocul in
## ziua in care l-am scris.
##
## Un telefon mid-range randeaza cateva SUTE de mii de triunghiuri pe cadru
## confortabil, iar cifra de aici e pe toata PISTA — un tur de ~1.1 km, din care
## ceata taie tot ce e peste 250 m. Deci 80k n-a fost niciodata o limita de
## hardware.
##
## Pragul a stat apoi la 150k — destul cat sa prinda clasa de accident (primitive
## lasate la rezolutia implicita sar cu zeci de mii dintr-un foc).
##
## 150k -> 300k (august 2026): decizia explicita a dezvoltatorului de a ridica
## bugetele vizuale. Un telefon post-2020 duce confortabil 300-500k de
## triunghiuri PE CADRU; cifra de aici e pe toata pista, din care ceata taie tot
## ce e peste 250 m. Planul de upgrade grafic (sosea cambrata, teren 2x mai
## dens, 12 variante de faleza, decal-uri) duce Dunele spre ~140-165k, deci
## 300k ramane un prag de alarma cu ~2x headroom — si tot prinde clasa istorica
## de accident, care sare cu zeci de mii dintr-un foc.
##
## 300k -> 400k (august 2026, la integrarea kitului Okinawa): tot decizia
## explicita a dezvoltatorului, luata cu cifrele in fata. Okinawa a ajuns la
## 302k, din care `Decor` singur face 184k — palmieri, pandanus, banyan si
## coral pe assets reale, in locul primitivelor provizorii.
##
## Ce a inclinat decizia: in acelasi timp numarul de MATERIALE a SCAZUT, 29 ->
## 22. Adica pista s-a ingreunat exact pe axa care nu doare pe mobil si s-a
## usurat pe cea care doare. Un prag care ar fi respins asta ar fi fost fix
## capcana descrisa mai sus — un plafon derivat din cat de sarac era jocul.
##
## Ramane un prag de ALARMA, nu un buget de arta: constrangerea reala pe mobil e
## draw calls / overdraw / fill rate, de asta testul principal al garzii ramane
## numaratoarea de MATERIALE. Validarea finala e primul test pe device — si
## Okinawa e pista pe care trebuie inceput, fiind cea mai grea.
## TRIUNGHIURILE NU MAI DAU VERDICT (august 2026, decizia dezvoltatorului).
##
## Se numara in continuare si se tipares in tabel — cifra ramane utila ca sa
## prinzi accidentul clasic (o primitiva lasata la rezolutia implicita sare cu
## zeci de mii dintr-un foc, iar un `SphereMesh` de 40 cm ajunge sa aiba 4 224
## de triunghiuri). Dar nu mai PICA nimic.
##
## DE CE: cifra e pe TOATA pista, iar pe ecran nu ajunge niciodata toata.
## Ceata taie tot ce e peste 250 m, `visibility_range` si topirea din shader
## scot vegetatia de departe — pe Alpi felia randata pe cadru masurase ~10% din
## total. Un plafon pe suma intregii piste pedepseste geometrie care nu se
## deseneaza in acelasi cadru.
##
## Si istoricul o spune la fel de clar: pragul a fost ridicat de CINCI ori
## (80k -> 150k -> 300k -> 400k, plus patru override-uri per pista), de fiecare
## data fiindca munca legitima nu incapea, si de fiecare data cu MATERIALELE
## neschimbate sau in scadere. Un prag care se muta ori de cate ori e atins nu
## masoara nimic — doar cere o ceremonie inainte de fiecare merge. Track10
## ajunsese la 1.36M cu override de 900k, iar CI-ul era rosu pe main.
##
## Constrangerea reala pe mobil ramane DRAW CALLS / overdraw / fill rate, si aia
## e masurata de `MAX_MATERIALS_PER_TRACK` — testul care a si ramas singurul cu
## drept de veto. Validarea finala e primul test pe device fizic.

var _paths: Array[String] = []
var _index: int = 0
var _frames: int = 0
var _track: Node = null
var _rows: Array[Dictionary] = []


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 20):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_decor: nu am gasit nicio pista")
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		if _index >= _paths.size():
			return _report()
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false

	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine

	_rows.append(_measure(_paths[_index], _track))
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


## E nodul un descendent al containerului de decor manual (DecorManual)?
static func _under_manual(node: Node) -> bool:
	var p := node.get_parent()
	while p != null:
		if p.name == &"DecorManual":
			return true
		p = p.get_parent()
	return false


func _measure(path: String, track: Node) -> Dictionary:
	var world_mat := Palette.world_material()
	var by_source := {}
	var all_mats := {}
	var unique_meshes := {}
	var mesh_count := 0
	var on_atlas := 0
	var tris := 0
	# Triunghiurile unei resurse Mesh se numara O SINGURA DATA si se refolosesc:
	# 60 de cactusi care partajeaza acelasi mesh nu justifica 60 de get_faces(),
	# fiecare din ele o copie a intregii geometrii.
	var tris_cache := {}

	# `draws` numara APELURILE de desenare, `mesh_count` numara PROP-URILE.
	# Pana la decorul copt erau acelasi lucru; de cand un MultiMeshInstance3D
	# desenează sute de instante intr-un apel, nu mai sunt, si tocmai distanta
	# dintre ele e castigul pe care garda trebuie sa-l arate.
	var draws := 0

	for node in _walk(track):
		var mesh: Mesh = null
		var mat: Material = null
		var count := 1
		var named: Node = node
		# In DECORUL MANUAL, ce e stins nu se deseneaza niciodata — deci nu se
		# numara. GLB-urile cu mai multe variante in acelasi fisier (gusuku_wall,
		# coral_rock) se asaza intregi din editor si variantele nefolosite se
		# sting cu `visible = false`; inainte de randul asta garda le numara ca
		# si cum s-ar randa toate (masurat pe Track08: 222k tris "adaugati" din
		# care 125k stinsi). Memoria nu e argumentul contrar: mesh-ul e aceeasi
		# resursa partajata, oricate instante il sting sau il arata.
		#
		# DOAR sub DecorManual, si asta e important: hazardele procedurale
		# (valul, tromba) isi sting nodurile in functie de faza ceasului, deci
		# in restul scenei "invizibil la cadrul 3" nu inseamna "nu se randeaza
		# in joc" — alea raman numarate.
		if node is Node3D and not (node as Node3D).is_visible_in_tree() \
				and _under_manual(node):
			continue
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			mesh = mi.mesh
			mat = mi.material_override
		elif node is MultiMeshInstance3D:
			# Decorul copt de TrackDecorBatch. Fara ramura asta garda ar raporta
			# ca Dunele si-a pierdut 700 de prop-uri peste noapte — adica ar
			# TRECE, si ar trece tocmai fiindca n-a mai vazut nimic.
			var mmi := node as MultiMeshInstance3D
			if mmi.multimesh == null:
				continue
			mesh = mmi.multimesh.mesh
			mat = mmi.material_override
			count = mmi.multimesh.instance_count
		else:
			continue
		if mat == null and mesh != null and mesh.get_surface_count() > 0:
			mat = mesh.surface_get_material(0)
		mesh_count += count
		draws += 1
		if mat == world_mat:
			on_atlas += count
		var key := mat.get_instance_id() if mat != null else 0
		all_mats[key] = true
		var mesh_tris := 0
		if mesh != null:
			var mesh_key := mesh.get_instance_id()
			unique_meshes[mesh_key] = true
			if not tris_cache.has(mesh_key):
				tris_cache[mesh_key] = _tris_of(mesh)
			mesh_tris = tris_cache[mesh_key] * count
			tris += mesh_tris
		var src := _source_of(named, track)
		if not by_source.has(src):
			by_source[src] = {"mats": {}, "meshes": 0, "tris": 0, "draws": 0}
		by_source[src].mats[key] = true
		by_source[src].meshes += count
		by_source[src].draws += 1
		by_source[src].tris += mesh_tris

	var proc: Dictionary = by_source.get("procedural (track.gd)",
		{"mats": {}, "meshes": 0, "tris": 0})
	var proc_meshes: int = proc.meshes
	var proc_mats: int = proc.mats.size()
	var ratio := float(proc_meshes) / float(maxi(proc_mats, 1))
	# Raportul ramane RAPORTAT, dar nu mai da verdictul — vezi
	# MAX_MATERIALS_PER_TRACK pentru de ce a incetat sa masoare ce trebuie.
	var ratio_ok := all_mats.size() <= MAX_MATERIALS_PER_TRACK
	return {
		"path": path.get_file().get_basename(),
		"meshes": mesh_count,
		"draws": draws,
		"materials": all_mats.size(),
		"on_atlas": on_atlas,
		"proc_meshes": proc_meshes,
		"proc_materials": proc_mats,
		"ratio": ratio,
		"tris": tris,
		"unique_meshes": unique_meshes.size(),
		"ratio_ok": ratio_ok,
		"ok": ratio_ok,
		"sources": by_source,
	}


## Triunghiurile unui mesh. ArrayMesh-urile generate cu SurfaceTool nu sunt
## indexate, deci get_faces() e sursa corecta indiferent de tip.
func _tris_of(mesh: Mesh) -> int:
	var faces := mesh.get_faces()
	return faces.size() / 3


func _report() -> bool:
	var failed := false
	print("=== GARDA DE SCENA (materiale: maxim %d / pista · triunghiurile se raporteaza, nu pica) ==="
		% MAX_MATERIALS_PER_TRACK)
	print("%-10s %7s %7s %5s %6s %11s %7s %9s %6s %6s"
		% ["pista", "prop-uri", "desene", "mat.", "atlas", "procedural",
			"raport", "triunghi", "unice", "stare"])
	print("-".repeat(88))
	for row in _rows:
		if not row.ok:
			failed = true
		var state := "OK" if row.ratio_ok else "MAT"
		print("%-10s %7d %7d %5d %6d %5d/%-5d %7.2f %9s %6d %6s" % [
			row.path, row.meshes, row.draws, row.materials, row.on_atlas,
			row.proc_meshes, row.proc_materials, row.ratio,
			_thousands(row.tris), row.unique_meshes, state])

	for row in _rows:
		print("\n%s — pe surse:" % row.path)
		var keys: Array = row.sources.keys()
		keys.sort_custom(func(a, b): return row.sources[a].tris > row.sources[b].tris)
		for src in keys:
			print("  %-26s %4d prop-uri  %4d desene  %3d materiale  %8s tris"
				% [src, row.sources[src].meshes, row.sources[src].draws,
					row.sources[src].mats.size(),
					_thousands(row.sources[src].tris)])

	print("\nVERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	quit(1 if failed else 0)
	return true


## 47200 -> "47 200". Cifrele de triunghiuri se compara intre rulari, iar la 5-6
## cifre lipite ochiul rateaza un ordin de marime.
func _thousands(n: int) -> String:
	var s := str(n)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = " " + out
	return out


## De unde vine mesh-ul: dintr-un GLB importat (are ca stramos un nod numit dupa
## fisier) sau construit procedural in track.gd.
##
## ATENTIE cand adaugi un GLB nou in lume: daca numele lui NU e in lista de mai
## jos, mesh-urile lui sunt puse la socoteala drept "procedurale". Cu cateva zeci
## de faleze si cateva sute de prop-uri clasificate gresit, raportul
## mesh-uri/material sare la valori absurde si garda **trece orice** — devine
## decorativa exact cand ai cea mai mare nevoie de ea.
## Nume de VARIANTA -> GLB-ul din care vine.
##
## Atribuirea mergea pe numele nodurilor-parinte, presupunand ca radacina unui
## GLB instantiat se cheama ca fisierul. Masurat, nu se cheama: iese
## `@Node3D@571`. Lantul real e `Bush_A < @Node3D@571 < Band_hug < Decor`, deci
## nimic nu se potrivea si mesh-urile cadeau in "procedural (track.gd)".
##
## Efectul e exact modul de esec descris la MIN_MESHES_PER_MATERIAL: `proc_meshes`
## se umfla cu prop-uri care de fapt IMPART materialul de atlas, raportul sare la
## valori absurde si garda trece orice. Masurat pe Dunele: desert_scatter
## raportat cu 1 mesh in loc de ~143.
##
## Numele de varianta sunt un contract pe care il impunem oricum — in briefuri,
## in `verify_glb.py` si in registrele din `track.gd` — deci sunt cheia stabila.
const VARIANT_SOURCE := {
	# --- Stromboli (kitul de flanc) ---
	#
	# PRIMELE, din acelasi motiv ca Baikal mai jos: atribuirea ia primul prefix
	# care se potriveste. "lava_slab_" ar cadea altfel pe nimic, dar "prickly_"
	# si "caper_" sunt nume noi si e mai ieftin sa stea toate la un loc decat
	# sa se caute cine cu cine se calca peste doua luni.
	"olive_": "olive_tree", "fig_": "fig_tree",
	"prickly_": "prickly_pear", "caper_": "caper_bush",
	"ginestra_": "ginestra_bush", "cane_clump": "cane_clump",
	"vine_row": "vine_row",
	"basalt_": "basalt_boulder", "scoria_": "scoria_rock",
	"lava_slab": "lava_slab_broken", "lava_stage": "lava_flow",
	"terrace_wall": "terrace_wall", "coast_cliff": "coast_cliff_basalt",
	# --- Baikal (kitul de padure si mal, un fisier pe piesa) ---
	#
	# PRIMELE in dictionar, nu ultimele: atribuirea ia primul prefix care se
	# potriveste, iar "boulderlichen_" ar cadea altfel pe "boulder" (rostogolul
	# de pe Dunele) si "pinesiberian_" pe "pine_" (coniferele alpine).
	"larchwinter_": "larch_winter", "birchwinter_": "birch_winter",
	"pinesiberian_": "pine_siberian", "boulderlichen_": "boulder_lichen",
	"shrubsnow": "shrub_snow", "grasstuftdry": "grass_tuft_dry",
	"bush_": "desert_scatter", "pebbles_": "desert_scatter",
	"grass_tuft": "desert_scatter",
	# Setul de vegetatie refacut in #208. Prefixul "veg_" e AL LUI — numele
	# de noduri incep cu Veg_ tocmai ca sa nu se calce cu "grass_tuft" de
	# deasupra (aceeasi lectie ca Scrub_A vs Bush_A din kitul MegaKit).
	"veg_": "veg_set",
	"butte_": "butte", "mesa_": "butte",
	"cluster_": "rock_cluster", "cactus_": "cactus", "cliff_": "cliff_wall",
	"canyon_": "canyon_rocks",
	# Bibliotecile din Stylized Nature MegaKit. `bush_` era deja luat de
	# desert_scatter, de aceea tufa de acolo se cheama `Scrub_A` — vezi nota din
	# tools/blender/build_megakit_plants.py.
	"kit_": "megakit_rocks",
	"tuft_": "megakit_plants", "scrub_": "megakit_plants",
	"fan_": "megakit_plants", "rosette_": "megakit_plants",
	"dead_": "megakit_plants",
	"marker_": "marker_post",
	"bone_": "dino_bones", "dino_skeleton": "dino_bones",
	"arch_": "rock_arch",
	"portal": "mine_portal", "minerail": "mine_portal", "minecart": "mine_portal",
	"pipe_": "pipe_leak", "boulder": "boulder_roller",
	"gasstation": "gas_station", "route66sign": "route66",
	"driveinscreen": "drive_in_screen", "gaspolesign": "gas_pole_sign",
	"startgate": "start_gate", "windmill": "windmill", "blades": "windmill",
	"water_tower": "water_tower",
	"house_": "village_house",
	"train_": "train",
	# --- Insula (Okinawa) ---
	#
	# Lipseau de la inceput, dar nu se vedea: mesh-urile lor cadeau in bucata
	# "procedural (track.gd)", care pe Okinawa arata oricum umflata din alte
	# motive. Coacerea in MultiMesh le-a scos la iveala, fiindca buffer-ele
	# neatribuite au acum galeata lor — 776 de prop-uri raportate ca venind de
	# niciunde. Cifrele nu se schimba; se muta in dreptul fisierului corect.
	"palm_": "coconut_palm", "bentpalm_": "beach_palm_bent",
	"pandanus_": "pandanus", "banyan_": "banyan",
	"coral_rock_": "coral_rock", "cane_clump_": "sugar_cane_clump",
	"hibiscus": "hibiscus_bush",
	"beach_grass": "island_scatter", "coral_pebbles": "island_scatter",
	"driftwood": "island_scatter",
	"awamori_": "beach_clutter", "bamboo_": "beach_clutter",
	"fishing_": "beach_clutter", "net_": "beach_clutter",
	"tetrapod_": "tetrapod", "island_": "horizon_island",
	# --- Muntele (Alpii) ---
	#
	# Kitul alpin (#226) plus coniferele (#222). Inregistrate ODATA cu
	# folosirea lor, nu dupa: pinii au aparut prima data pe pista ca 146 de
	# instante contabilizate la "procedural (track.gd)", exact modul de esec
	# descris in capul acestui dictionar. Se vedeau pe ecran, dar garda ii
	# citea gresit — motiv suficient sa nu te increzi intr-o cifra care nu
	# stie ce numara.
	"pine_": "alpine_pines", "trunk_": "alpine_pines",
	"alpineshrub": "alpine_shrub", "flowercluster": "flower_cluster",
	"snowpatch": "snow_patch", "mountainpeak": "mountain_peak",
	"peaksnow": "mountain_peak",
	"fence_": "wooden_fence", "haybale": "hay_bale", "haycart": "hay_cart",
	"timbersled": "timber_sled", "snowplow": "snowplow", "cow": "cow",
	"alpinechurch": "alpine_church", "cablecarstation": "cable_car_station",
	"cablecarpylon": "cable_car_pylon",
	"mountainchalet": "mountain_chalet", "mountaintunnel": "mountain_tunnel",
	"streambridge": "stream_bridge", "jumpkicker": "jump_kicker",
	"alpinesignpost": "alpine_signpost", "woodstack": "wood_stack",
}


## `mi` e orice vizual — [MeshInstance3D] sau [MultiMeshInstance3D]. Atribuirea
## merge pe NUME, iar TrackDecorBatch pastreaza intentionat numele variantei in
## numele buffer-ului tocmai ca sonda asta sa continue sa functioneze.
func _source_of(mi: Node, track: Node) -> String:
	const KNOWN := ["cactus", "rocks", "bucket", "sandcastle", "start_arch", "beach_ball",
		"toy_excavator", "toy_dino", "garden_hose", "bowling_pin", "sandbox_border",
	"marker_post", "drive_in_screen", "gas_pole_sign", "start_gate",
	"boulder_roller", "dino_bones", "pipe_leak", "rusted_digger",
	"rock_arch", "mine_portal",
		"water_tower", "windmill", "gas_station", "route66",
		# kitul de tuf al Cappadociei (POI B si mai departe). Fara numele astea
		# cele 83 de piese asezate de mana se raportau ca "procedural
		# (track.gd)" — intrau corect in TOTALURI (prop-uri, desene, materiale),
		# dar linia pe surse minte, si exact linia aia se citeste cand cauti
		# cine a adus un material in plus.
		"chimney", "twin_chimney_gate", "cave_house", "dovecote",
		"rock_church_facade", "shrub_dry", "pigeon",
		"poplar", "carpet_terrace", "pottery_cart", "pot_stack",
		# Stratul uman al piatei din Goreme. Aceeasi capcana ca mai sus, a doua
		# oara: piesele intrau in totaluri dar linia pe surse le arunca in
		# "procedural (track.gd)", care iesea cu 39 de prop-uri si 89k tris —
		# adica mai mult decat poate face geometria din track.gd.
		"farmhouse", "church_arch", "cave_entrance", "vine_row", "torch",
		"cracked_chimney",
		# peisajul de canion
		"cliff_wall", "rock_cluster", "canyon_rocks", "desert_scatter", "butte",
		"wood_fence", "train"]
	# Intai numele PROPRIU al mesh-ului: variantele sunt cheia stabila.
	var own := String(mi.name).to_lower()
	for prefix: String in VARIANT_SOURCE:
		if own.begins_with(prefix):
			return "GLB: " + String(VARIANT_SOURCE[prefix])
	# Apoi lantul de parinti, pentru GLB-urile vechi cu un singur nod, unde
	# containerul chiar poarta numele fisierului.
	var n: Node = mi
	while n != null and n != track:
		var lower := String(n.name).to_lower()
		for k in KNOWN:
			if lower.begins_with(k) or lower.begins_with(k.replace("_", "")):
				return "GLB: " + k
		n = n.get_parent()
	if mi is MeshInstance3D:
		var solo := mi as MeshInstance3D
		if solo.mesh != null and solo.mesh.get_surface_count() > 0:
			return "procedural (track.gd)"
		return "necunoscut"
	# Un buffer copt care a ajuns aici si-a pierdut numele de varianta pe drum —
	# nu e "procedural", e o gaura in atribuire. Il numim ca atare, ca sa se
	# vada in raport in loc sa se topeasca in bucata procedurala.
	return "MultiMesh neatribuit"


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
