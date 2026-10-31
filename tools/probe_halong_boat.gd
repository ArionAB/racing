extends Node
## Jonca din canal (Ha Long, #596) sta pe APA pe tot ciclul, nu deasupra soselei.
##
## Masoara pe scena reala Track22: cota corpului mobil (SlidingHazard) fata de
## oglinda marii si de asfalt, de-a lungul unui ciclu intreg (fereastra de
## asteptare + traversare in ambele sensuri). Contractele:
##   1. cota corpului = oglinda apei (+-0.05 m) in toate cadrele;
##   2. capetele cursei (parcarea) cad pe apa: sub ele terenul e mai jos decat
##      oglinda, deci coca are apa, nu aer, dedesubt;
##   3. cand e pe sosea, baza cocii e SUB asfalt (vela matura, coca nu pluteste
##      peste carosabil): baza < cota asfaltului - 0.5 m.
## `--sabotaj` pune `on_water = false` pe marker (starea veche): trebuie sa pice.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHalongBoat.tscn [-- --sabotaj]

var _failed := false


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _find(n: Node, out: Array) -> void:
	if n is SlidingHazard:
		out.append(n)
	for c in n.get_children():
		_find(c, out)


func _ready() -> void:
	call_deferred("_go")


func _go() -> void:
	var sabotage := "--sabotaj" in OS.get_cmdline_user_args()
	var t := (load(GameState.TRACK_SCENES[14]) as PackedScene).instantiate()
	if sabotage:
		(t.get_node("Hazarduri/JoncaCanal") as HazardMarker).on_water = false
	get_tree().root.add_child(t)
	for i in 30:
		await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var sea_y: float = float(t._sampler.mean_road_y()) + float(t.sea_level_offset)
	var hs: Array = []
	_find(t, hs)
	_check(hs.size() == 1, "un singur SlidingHazard pe Ha Long (%d)" % hs.size())
	var h: SlidingHazard = hs[0]
	print("oglinda apei y=%.2f | centru %s | cursa +-%.1f m | perioada %.1f s" % [
		sea_y, str(h.center), h.travel.length(), h.period])
	var terrain_rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	var y_min := INF
	var y_max := -INF
	var worst_over_road := -INF  # cel mai mare (baza - asfalt) cat e pe sosea
	var worst_end_air := -INF    # cel mai mare aer sub coca la capete
	var frames := int((h.period + 2.0 * (SlidingHazard.CROSS_WAIT + SlidingHazard.CROSS_TELEGRAPH)) * 2.0 * 60.0)
	var on_road := 0
	for f in frames:
		await get_tree().physics_frame
		var p := h.global_position
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
		var rq := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 50.0, p + Vector3.DOWN * 50.0)
		rq.exclude = [h.get_rid()]
		var hit := space.intersect_ray(rq)
		var guard := 0
		while not hit.is_empty() and guard < 8:
			var nm := str((hit["collider"] as Node).name)
			if hit["rid"] == terrain_rid or nm.begins_with("Road"):
				break
			rq.exclude = rq.exclude + [hit["rid"]]
			hit = space.intersect_ray(rq)
			guard += 1
		if hit.is_empty():
			continue
		var is_road := str((hit["collider"] as Node).name).begins_with("Road")
		var sup_y: float = float(hit["position"].y)
		if is_road:
			on_road += 1
			worst_over_road = maxf(worst_over_road, p.y - sup_y)
		else:
			worst_end_air = maxf(worst_end_air, p.y - maxf(sup_y, sea_y))
	print("cota corp: [%.2f, %.2f] | cadre pe sosea %d/%d | baza fata de asfalt (max) %.2f m | aer sub coca pe apa (max) %.2f m" % [
		y_min, y_max, on_road, frames, worst_over_road, worst_end_air])
	_check(absf(y_min - sea_y) < 0.05 and absf(y_max - sea_y) < 0.05, "cota corpului = oglinda apei (+-0.05) pe tot ciclul")
	_check(on_road > 0, "jonca chiar traverseaza soseaua in ciclul masurat")
	_check(worst_over_road < -0.5, "pe sosea baza cocii e sub asfalt (< -0.5 m), nu deasupra lui")
	_check(worst_end_air < 0.1, "la capete coca sta pe apa (aer sub ea < 0.1 m)")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	get_tree().quit(1 if _failed else 0)
