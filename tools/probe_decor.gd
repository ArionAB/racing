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
## 2. TRIUNGHIURI (instrumentare). Raportate mereu, cu prag larg. Nu erau masurate
##    deloc pana acum, desi CLAUDE.md vorbeste de un buget — vezi
##    MAX_TRIS_PER_TRACK pentru de ce pragul e unde e.
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
const MAX_TRIS_PER_TRACK: int = 400000

## Praguri PER PISTA, pentru abaterile decise cu cifrele in fata.
##
## Pragul global a crescut de patru ori (80k -> 150k -> 300k -> 400k) fiindca o
## singura pista avea nevoie de aer, si de fiecare data l-a primit toata lumea.
## Efectul secundar nu e vizibil pana nu se intampla: Dunele masoara ~65k, deci
## si-ar putea DUBLA geometria de doua ori la rand fara ca garda sa clipeasca.
## Un prag pe pista tine alarma stransa acolo unde nu s-a schimbat nimic.
##
## Okinawa v2 (si Okinawa manual, care mosteneste aceeasi lume) au scenografia
## dupa referinta: 524 de piese asezate — dig de tetrapozi, chei, sat, ziduri de
## cetate, lan de trestie, perdele de palmieri — masurate la 896k pe pista.
##
## De ce e acceptabil, in cifrele care conteaza pe mobil:
##   - MATERIALELE raman 22 din 38. Scenografia nu aduce niciunul nou: totul
##     trece prin atlasul comun si prin cele 8 clase de textura existente.
##   - Cifra e pe TOATA pista (1.8 km). Camera de joc sta la 11 m in spate cu
##     FOV 47.6, iar ceata taie la 250 m — deci ce se randeaza pe cadru e o
##     fractiune, si fiecare piesa e un nod separat, adica frustum-culled.
##   - Decizia e explicita a dezvoltatorului ("nu-ti fie frica de draw calls si
##     triunghiuri"), luata dupa ce a fixat parametrii camerei.
## Ce NU stim inca: cat trage asta pe un telefon real. De aia ramane un prag de
## ALARMA, si de aia primul test pe device se face pe Okinawa.
##
## Track08 sta mai sus decat Track07 desi impart aceeasi lume, si nu din
## neglijenta: cele 896k de mai sus s-au masurat pe Track08 cand scena lui era
## un ciot de sase linii, cu cele 87 de prop-uri asezate de mana inca necomise.
## Dar Okinawa manual E, prin definitie, lumea comuna PLUS decor pus cu mouse-ul
## (vezi antetul lui track08.gd) — deci un prag care nu-l cuprinde masoara o
## pista care nu exista. Decorul manual aduce 341 026 de triunghiuri peste
## Track07, si pista iese la 1 237 328.
##
## E fix capcana descrisa in CLAUDE.md: "masuratoare + marja" e buna pentru un
## prag care prinde regresii, dar aplicata pe o masuratoare luata inaintea
## muncii devine un plafon care respinge munca legitima — ca prima benzinarie cu
## ferestre reale, respinsa de un numar derivat din cat de sarac era jocul in
## ziua aia. Materialele, axa care chiar doare pe mobil, raman 22 din 38.
##
## 1.3M lasa ~5% aer peste masuratoarea de acum: strans intentionat, cat sa
## prinda urmatoarea sesiune de asezat decor. Ce ar trebui sa scada cifra fara
## sa taie din compozitie: un tetrapod are 5 104 de triunghiuri pentru un bloc
## de beton de 4.2 m, iar digul are 41.
const TRIS_OVERRIDE := {
	"Track07": 1000000,
	"Track08": 1300000,
}


static func tris_limit(path: String) -> int:
	return int(TRIS_OVERRIDE.get(path.get_file().get_basename(),
		MAX_TRIS_PER_TRACK))

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
	for i in range(1, 10):
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


func _measure(path: String, track: Node) -> Dictionary:
	var world_mat := Palette.world_material()
	# Falezele oglindite folosesc geamanul cu CULL_FRONT. Fara linia asta,
	# jumatate din ele n-ar mai fi numarate ca fiind pe atlas.
	var world_mat_mirror := Palette.world_material_mirrored()
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

	for node in _walk(track):
		if not (node is MeshInstance3D):
			continue
		var mi := node as MeshInstance3D
		mesh_count += 1
		var mat: Material = mi.material_override
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat == world_mat or mat == world_mat_mirror:
			on_atlas += 1
		var key := mat.get_instance_id() if mat != null else 0
		all_mats[key] = true
		if mi.mesh != null:
			var mesh_key := mi.mesh.get_instance_id()
			unique_meshes[mesh_key] = true
			if not tris_cache.has(mesh_key):
				tris_cache[mesh_key] = _tris_of(mi.mesh)
			tris += tris_cache[mesh_key]
		var src := _source_of(mi, track)
		if not by_source.has(src):
			by_source[src] = {"mats": {}, "meshes": 0, "tris": 0}
		by_source[src].mats[key] = true
		by_source[src].meshes += 1
		if mi.mesh != null:
			by_source[src].tris += tris_cache[mi.mesh.get_instance_id()]

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
		"materials": all_mats.size(),
		"on_atlas": on_atlas,
		"proc_meshes": proc_meshes,
		"proc_materials": proc_mats,
		"ratio": ratio,
		"tris": tris,
		"unique_meshes": unique_meshes.size(),
		"ratio_ok": ratio_ok,
		"tris_ok": tris <= tris_limit(path),
		"ok": ratio_ok and tris <= tris_limit(path),
		"sources": by_source,
	}


## Triunghiurile unui mesh. ArrayMesh-urile generate cu SurfaceTool nu sunt
## indexate, deci get_faces() e sursa corecta indiferent de tip.
func _tris_of(mesh: Mesh) -> int:
	var faces := mesh.get_faces()
	return faces.size() / 3


func _report() -> bool:
	var failed := false
	print("=== GARDA DE SCENA (materiale: maxim %d / pista · triunghiuri: alarma la %s) ==="
		% [MAX_MATERIALS_PER_TRACK, _thousands(MAX_TRIS_PER_TRACK)])
	if not TRIS_OVERRIDE.is_empty():
		var notes: PackedStringArray = []
		for key: String in TRIS_OVERRIDE:
			notes.append("%s %s" % [key, _thousands(int(TRIS_OVERRIDE[key]))])
		print("praguri proprii de triunghiuri: %s" % ", ".join(notes))
	print("%-10s %7s %6s %6s %11s %7s %9s %7s %7s"
		% ["pista", "mesh-uri", "mat.", "atlas", "procedural", "raport",
			"triunghi", "unice", "stare"])
	print("-".repeat(82))
	for row in _rows:
		if not row.ok:
			failed = true
		var state := "OK"
		if not row.ratio_ok and not row.tris_ok:
			state = "PICA×2"
		elif not row.ratio_ok:
			state = "MAT"
		elif not row.tris_ok:
			state = "TRIS"
		print("%-10s %7d %6d %6d %5d/%-5d %7.2f %9s %7d %7s" % [
			row.path, row.meshes, row.materials, row.on_atlas,
			row.proc_meshes, row.proc_materials, row.ratio,
			_thousands(row.tris), row.unique_meshes, state])

	for row in _rows:
		print("\n%s — pe surse:" % row.path)
		var keys: Array = row.sources.keys()
		keys.sort_custom(func(a, b): return row.sources[a].tris > row.sources[b].tris)
		for src in keys:
			print("  %-26s %4d mesh-uri  %3d materiale  %8s tris"
				% [src, row.sources[src].meshes, row.sources[src].mats.size(),
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
	"bush_": "desert_scatter", "pebbles_": "desert_scatter",
	"grass_tuft": "desert_scatter",
	"butte_": "butte", "mesa_": "butte",
	"cluster_": "rock_cluster", "cactus_": "cactus", "cliff_": "cliff_wall",
	"canyon_": "canyon_rocks",
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
}


func _source_of(mi: MeshInstance3D, track: Node) -> String:
	const KNOWN := ["cactus", "rocks", "bucket", "sandcastle", "start_arch", "beach_ball",
		"toy_excavator", "toy_dino", "garden_hose", "bowling_pin", "sandbox_border",
	"marker_post", "drive_in_screen", "gas_pole_sign", "start_gate",
	"boulder_roller", "dino_bones", "pipe_leak", "rusted_digger",
	"rock_arch", "mine_portal",
		"water_tower", "windmill", "gas_station", "route66",
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
	if mi.mesh != null and mi.mesh.get_surface_count() > 0:
		return "procedural (track.gd)"
	return "necunoscut"


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
