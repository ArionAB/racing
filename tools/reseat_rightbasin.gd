extends Node
## Reasaza pe teren piesele din `Zone05_RightBasin` care au ramas in aer dupa
## integrare.
##
## Grupul asta a fost pus de mana (nu are generator propriu, spre deosebire de
## Zone05_Talus si Zone05_Midfield), deci nu se putea recoace rerunand ceva.
## Terenul de sub el s-a mutat cand au intrat rapa lui C si canionul lui D.
##
## Raza porneste de deasupra celui mai inalt punct al traseului si accepta DOAR
## `TerrainBody` — aceeasi regula ca in gen_decor_capp_b.gd.
func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var grup := t.get_node_or_null("DecorManual/Zone05_RightBasin")
	if grup == null:
		print("; grupul lipseste"); get_tree().quit(1); return
	var rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			rid = (c as StaticBody3D).get_rid()
	var hi := -INF
	for bp in t.baked:
		hi = maxf(hi, bp.y)
	var sus := hi + 120.0
	var space := t.get_world_3d().direct_space_state
	for ch in grup.get_children():
		var n3 := ch as Node3D
		if n3 == null:
			continue
		# baza reala a piesei, din AABB-ul copiilor
		var base_y := INF
		for mi in n3.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null:
				continue
			var ab: AABB = m.global_transform * m.mesh.get_aabb()
			base_y = minf(base_y, ab.position.y)
		if base_y == INF:
			continue
		var p := n3.global_position
		var q := PhysicsRayQueryParameters3D.create(
			Vector3(p.x, sus, p.z), Vector3(p.x, sus - 900.0, p.z))
		q.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if hit.is_empty() or hit["rid"] != rid:
			continue
		var sol: float = float(hit["position"].y)
		var gol := base_y - sol
		if absf(gol) < 0.05:
			continue
		print("; %s: baza %.2f sol %.2f -> dy %+.2f" % [n3.name, base_y, sol, -gol])
		print("%s|%.6f" % [n3.name, n3.position.y - gol])
	get_tree().quit(0)
