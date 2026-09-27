extends Node
## A ajuns clasa `wood` PE OBIECT pe Fiordland (Track16, lotul C), sau doar in
## numaratoare de materiale?
##
## Acelasi tipar ca `tools/probe_capp_clase.gd` (`tuff_cream`): un material in
## plus la `probe_decor` dovedeste ca s-a CONSTRUIT un material, nu ca l-a
## PRIMIT cineva (memoria `scatter-nu-primeste-clasele-temei`,
## `sonda-masura-alt-obiect`). Sonda umbla pe pista incarcata si raporteaza,
## per model, cate MeshInstance3D au `material_override` pe clasa `wood`.
##
## Consumatorii asteptati (lotul C):
##   - `driftwood.glb` (37 instante, DecorManual) — CLASSES_BY_MODEL in
##     world_prop.gd, prin `_ready` (nu deferred, WorldProp nu depinde de
##     tema pistei pentru maparea asta).
##   - tabliera podetului Chasm (`PodetChasm`, generata din cod in
##     LiftBridgeHazard._build_span) — `deck_material_class = "wet_wood"` setat
##     pe TrackChannel in Track16.tscn, propagat prin Track._build_lift_bridge.
##     Aceasta a doua piesa NU are `scene_file_path` (geometrie procedurala),
##     deci se identifica prin parintele ei (`LiftBridgeHazard`), nu prin
##     stem de fisier.
##
## Ruleaza:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFiordWood.tscn -- --track=16 [--sabotage]

func _ready() -> void:
	await get_tree().process_frame
	var idx := 16
	var sabotage := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg == "--sabotage":
			sabotage = true

	var wood_mat := Palette.triplanar_class_material("wet_wood")

	if sabotage:
		# CLASSES_BY_MODEL e `const` — Godot 4.7 tine dictionarele const in
		# stare READ-ONLY (verificat direct: .erase() pe un const arunca
		# "Dictionary is in read-only state"), deci nu se poate sterge
		# maparea din mers si re-rula `WorldProp._ready()` normal. Sabotajul
		# apeleaza in schimb ACEEASI functie de productie
		# (`_apply_classes_mapping`), cu o COPIE mutabila a mapei din care
		# lipseste "driftwood" — verifica mecanismul real (stem -> mapare ->
		# nume-de-parte), nu o reimplementare paralela.
		print("--- SABOTAJ: driftwood.glb, mapare cu 'driftwood' STEARSA ---")
		var sabotaged: Dictionary = WorldProp.CLASSES_BY_MODEL.duplicate(true)
		sabotaged.erase("driftwood")
		var scene: PackedScene = load(
			"res://assets/models/fiordland/props/driftwood.glb")
		# `probe_wp` NU intra NICIODATA in arbore: WorldProp._ready() ruleaza
		# automat la add_child() si aplica mereu maparea REALA (constanta,
		# nesabotata) — indiferent daca sabotajul manual ruleaza inainte sau
		# dupa, `_ready()` fie o suprascrie, fie (mapata pe stem lipsa) o
		# lasa neschimbata prin `continue` (`_apply_classes_mapping`: stem
		# absent din mapare => sare peste nod, NU sterge ce era pus deja).
		# Verificat cu un script minimal, in afara sondei, in ambele ordini —
		# in amandoua mesh-ul ramanea pe wood_mat cat timp nodul intra in
		# arbore. Solutia: se apeleaza direct functia de productie, cu
		# `inst` liber (fara parinte in scena), fara sa se declanseze
		# NICIODATA `_ready()` real.
		var probe_wp := WorldProp.new()
		var inst := scene.instantiate()
		probe_wp.add_child(inst)
		probe_wp._apply_classes_mapping(sabotaged)
		var n_mesh := 0
		var n_wood := 0
		for mi in _meshes(inst):
			n_mesh += 1
			if (mi as MeshInstance3D).material_override == wood_mat:
				n_wood += 1
		print("driftwood mesh-uri: %d, cu wood DUPA sabotaj: %d (asteptat 0)"
			% [n_mesh, n_wood])
		print("VERDICT SABOTAJ: %s" % str(n_wood == 0))
		get_tree().quit(0)
		return

	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().process_frame

	# --- Consumator 1: driftwood.glb (kit GLB, cu scene_file_path) ---
	var per_model := {}
	_walk_glb(track, per_model, wood_mat)
	var keys: Array = per_model.keys()
	keys.sort()
	print("--- Consumatori GLB (scene_file_path) ---")
	print("model                       instante   wood   fara")
	var glb_with_wood := 0
	var glb_total := 0
	for k in keys:
		var d: Dictionary = per_model[k]
		print("%-28s %6d %6d %6d" % [k, d["n"], d["cls"], d["n"] - d["cls"]])
		glb_with_wood += int(d["cls"])
		glb_total += int(d["n"])
	print("TOTAL mesh-uri GLB: %d, cu wood: %d" % [glb_total, glb_with_wood])

	# --- Consumator 2: tabliera podetului Chasm (procedural, sub LiftBridgeHazard) ---
	# NU toate mesh-urile hazardului trebuie sa fie "wood" — piloni/rampe
	# raman CONCRETE (_structure_material), doar TABLIERA (span-ul) e lemn.
	# De aceea se numara separat, pe nume de nod, nu global pe subarbore.
	var res := _walk_deck(track, wood_mat)
	print("--- Consumator procedural (LiftBridgeHazard, PodetChasm) ---")
	print("mesh-uri sub hazard: %d (nume: %s)" % [res["total"], str(res["names"])])
	print("cu wood: %d" % res["wood"])

	# --- Gate opt-in: un LiftBridgeHazard FARA deck_material_class ramane pe
	# culoarea plata (verifica ca opt-in-ul chiar opreste clasa cand e gol,
	# nu doar cand e "wood" — testeaza ambele capete ale comutatorului) ---
	var plain_bridge := LiftBridgeHazard.new()
	get_tree().root.add_child(plain_bridge)
	var plain_mat: Material = plain_bridge._deck_material()
	var gate_ok := plain_mat != wood_mat
	print("Gate opt-in (deck_material_class=''): material != wood -> %s"
		% str(gate_ok))

	# Exact O piesa de tabliera pe canal (span-ul), restul (piloni, rampe,
	# plasa de cadere) raman structura/CONCRETE.
	print("VERDICT: driftwood_ok=%s deck_ok=%s gate_ok=%s" % [
		str(glb_with_wood == glb_total and glb_total > 0),
		str(res["wood"] == 1),
		str(gate_ok)])
	get_tree().quit(0)


func _walk_glb(n: Node, acc: Dictionary, wood_mat: Material) -> void:
	var model := n as Node3D
	if model != null and not model.scene_file_path.is_empty() \
			and model.scene_file_path.contains("/fiordland/props/driftwood"):
		var stem := model.scene_file_path.get_file().get_basename()
		if not acc.has(stem):
			acc[stem] = {"n": 0, "cls": 0}
		for mi in _meshes(model):
			acc[stem]["n"] = int(acc[stem]["n"]) + 1
			var m := (mi as MeshInstance3D).material_override
			if m == wood_mat:
				acc[stem]["cls"] = int(acc[stem]["cls"]) + 1
		return
	for c in n.get_children():
		_walk_glb(c, acc, wood_mat)


func _walk_deck(n: Node, wood_mat: Material) -> Dictionary:
	var acc := {"total": 0, "wood": 0, "names": PackedStringArray()}
	_walk_deck_inner(n, wood_mat, acc, false)
	return acc


func _walk_deck_inner(n: Node, wood_mat: Material, acc: Dictionary,
		under_bridge: bool) -> void:
	var now_under := under_bridge or (n is LiftBridgeHazard)
	if now_under and n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			acc["total"] = int(acc["total"]) + 1
			var is_wood: bool = mi.material_override == wood_mat
			if is_wood:
				acc["wood"] = int(acc["wood"]) + 1
			(acc["names"] as PackedStringArray).append(
				"%s(%s)" % [String(mi.name), "wood" if is_wood else "-"])
	for c in n.get_children():
		_walk_deck_inner(c, wood_mat, acc, now_under)


func _meshes(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_meshes(c))
	return o
