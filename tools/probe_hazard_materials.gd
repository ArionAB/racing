extends Node
## Garda de materiale a celor patru hazarduri de Chongqing: niciunul nu are voie
## sa aduca un material NOU in scena, in afara unui buget declarat de materiale
## de CLASA (partajate de mai multe mesh-uri), si al unuia singur in total.
##
## De ce o sonda separata, cand `tools/probe_decor.gd` numara deja materialele
## per pista: garda aia masoara pistele care EXISTA. Hazardele astea nu sunt
## inca asezate pe Track12 (pista se construieste in paralel), deci pana la
## asezare nimeni nu le-ar prinde daca ar aduce fiecare cate un
## `StandardMaterial3D.new()` — iar cand ar prinde-o, ar fi patru regresii
## deodata, la merge. Aici se masoara SURSA: instantiaza fiecare hazard singur
## si numara materialele distincte de pe mesh-urile lui.
##
## Ce inseamna „nu aduce materiale noi": fiecare material de pe un mesh al
## hazardului trebuie sa fie ori `Palette.world_material()` (atlasul comun),
## ori unul din materialele de CLASA ale paletei, pe care le are deja orice
## pista care foloseste clasa respectiva (CLAUDE.md: materiale per clasa, nu
## per asset). Orice altceva e un material propriu, deci un draw call in plus
## care nu se imparte cu nimeni.
##
## Ruleaza CA SCENA (hazardele instantiaza modele si cer autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHazardMaterials.tscn
## Iese cu cod 1 daca vreun hazard aduce un material propriu.

const SpanScript := preload("res://scenes/hazards/rotating_span_hazard.gd")
const CraneScript := preload("res://scenes/hazards/crane_hazard.gd")
const FogScript := preload("res://scenes/hazards/fog_corridor_hazard.gd")
const MonoScript := preload("res://scenes/hazards/monorail_hazard.gd")

var _fails: int = 0
## Materialele pe care le are deja lumea: atlasul plus clasele paletei.
var _shared: Dictionary = {}


func _ready() -> void:
	print("=== MATERIALELE HAZARDELOR: zero materiale noi ===")
	_collect_shared()
	print("  materiale comune cunoscute: %d (atlas + clase de paleta)" % _shared.size())
	# Al treilea camp e BUGETUL de clase proprii: cate materiale partajate are
	# voie sa aduca hazardul peste atlasul lumii. Zero e regula; culoarul de
	# ceata are unu, si e o decizie scrisa in antetul lui — benzile reflectori-
	# zante de pe repere ard, fiindca „marcajele raman vizibile (emisive slabe)"
	# din brief nu se poate indeplini cu un atlas care n-are emisie. CLAUDE.md
	# permite exact asta: „o clasa de assets poate primi un material partajat
	# deliberat, decis explicit, nu strecurat".
	for entry: Array in [
		["Pasajul rotativ", SpanScript, 0],
		["Macaraua", CraneScript, 0],
		["Culoarul de ceata", FogScript, 1],
		["Monorailul", MonoScript, 0],
	]:
		await _check(entry[0] as String, entry[1] as GDScript, entry[2] as int)
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


const WorldProp = preload("res://scenes/props/world_prop.gd")


## Atlasul si toate materialele de clasa pe care paleta stie sa le dea.
##
## Clasele se rezolva EXACT ca in `Palette.apply_object_class_materials`:
## numele poate purta un prefix (`tri:`, `finish:`, `shader:`) care trimite la
## alta fabrica de material. Prima versiune a sondei chema `class_material()`
## pe numele intreg si a picat pe primul `tri:coral_rock` — adica ar fi
## raportat drept „material propriu" chiar materialele de clasa partajate.
func _collect_shared() -> void:
	_shared[Palette.world_material()] = "world_material"
	for cls: String in _class_names():
		var mat := _material_for_class(cls)
		if mat != null:
			_shared[mat] = cls


func _material_for_class(cls: String) -> Material:
	if cls.begins_with(Palette.FINISH_PREFIX):
		return Palette.finish_material(cls.trim_prefix(Palette.FINISH_PREFIX))
	if cls.begins_with(Palette.SHADER_PREFIX):
		return Palette.shader_material(cls.trim_prefix(Palette.SHADER_PREFIX))
	if cls.begins_with(Palette.TRI_PREFIX):
		# Materialul triplanar depinde si de scara lumii; hazardele instantiaza
		# modelele la scara 1, deci aia se cere si aici.
		return Palette.object_triplanar_class_material(
			cls.trim_prefix(Palette.TRI_PREFIX), 1.0)
	return Palette.class_material(cls)


func _class_names() -> Array[String]:
	var out: Array[String] = []
	var seen := {}
	var mapping := WorldProp.prop_classes()
	for key in mapping.keys():
		var name := str(mapping[key])
		if name.is_empty() or seen.has(name):
			continue
		seen[name] = true
		out.append(name)
	return out


func _check(label: String, script: GDScript, budget: int) -> void:
	var hazard: Node3D = script.new()
	hazard.name = label.replace(" ", "")
	add_child(hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var mats := {}
	var strangers := {}
	var meshes := 0
	for mi in _meshes(hazard):
		meshes += 1
		for m in _materials_of(mi):
			mats[m] = true
			if not _shared.has(m):
				strangers[m] = int(strangers.get(m, 0)) + 1
	print("--- %s: %d mesh-uri, %d materiale distincte (buget de clase proprii: %d)"
		% [label, meshes, mats.size(), budget])
	# Un material propriu e acceptabil doar daca e o CLASA: purtat de mai multe
	# mesh-uri deodata. Unul singur pe un singur mesh e exact „textura proprie
	# per asset", regula pe care CLAUDE.md o interzice, si e si clasa de
	# regresie pe care garda per pista o vaneaza (un draw call care nu se
	# imparte cu nimeni).
	var per_asset := 0
	for m in strangers.keys():
		var users: int = strangers[m]
		print("    propriu: %s pe %d mesh-uri" % [str(m), users])
		if users < 2:
			per_asset += 1
	_verdict(strangers.size() <= budget,
		"%s: %d materiale proprii (buget %d)"
		% [label, strangers.size(), budget])
	_verdict(per_asset == 0,
		"%s: niciun material per-asset (toate cele proprii sunt clase)" % label)
	_verdict(meshes > 0, "%s: chiar a construit ceva (%d mesh-uri)" % [label, meshes])
	hazard.queue_free()
	await get_tree().physics_frame


## Materialul EFECTIV al unui mesh: override-ul daca exista, altfel cel de pe
## prima suprafata. Exact regula din `tools/probe_decor.gd` — garda care da
## verdictul pe piste — si e important sa fie exact aceeasi.
##
## Prima versiune numara si materialele de pe suprafete, pe langa override. A
## „gasit" astfel cate un material strain in fiecare hazard: fiecare GLB de
## Chongqing isi poarta propriul `PaletteAtlas` copt la export. Numai ca peste
## el sta un `material_override` pus de `Palette.apply_object_class_materials`,
## deci cel copt nu ajunge niciodata la GPU si nu costa niciun draw call. Un
## material care nu se deseneaza nu se numara — altfel garda ar cere ceva ce
## nici pistele existente nu fac.
func _materials_of(mi: MeshInstance3D) -> Array:
	if mi.material_override != null:
		return [mi.material_override]
	var mesh := mi.mesh
	if mesh != null and mesh.get_surface_count() > 0:
		var base := mesh.surface_get_material(0)
		if base != null:
			return [base]
	return []


func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1
