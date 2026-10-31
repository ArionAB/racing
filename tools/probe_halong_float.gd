extends Node
## Plutirea pieselor de DecorManual pe Ha Long, MASURATA PE COLTURILE bazei.
##
## `ProbePlutire` ia centrul bazei si tolereaza 4 m de aer (MAX_GOL), iar dupa
## coacerea DecorManual (noduri de mesh -> buffere) vede o singura piesa din
## 1200. Aici se ia fiecare nod-radacina al unui GLB instantiat sub DecorManual,
## se calculeaza AABB-ul lui local din fisierul GLB, se transforma cele 4 colturi
## de JOS in lume si se trage cate o raza in jos pe TEREN din fiecare. Sprijinul
## e max(teren, oglinda apei): apa de pe Ha Long e opaca, fundul nu se vede.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHalongFloat.tscn -- \
##       [--track=14] [--prefix=Parapet] [--max=0.5]
##
## `--track=` e INDEXUL din GameState (Ha Long = 14). Iese cu cod 1 daca vreo
## piesa are un colt la mai mult de `--max` m (implicit 0.5) deasupra terenului.
## Raportul arata si golul maxim al fiecarei piese, ca sa se vada cat de gresit.

var _max_gap: float = 0.5
var _prefix: String = ""
var _track: int = 14
## Nu stau pe teren prin constructie: poarta scurtaturii sta pe tablierul benzii
## (carosabil, nu teren), `AgatG*` sunt module de faleza suprapuse.
const SKIP_PREFIXES := ["Portic", "AgatG"]


func _ready() -> void:
	call_deferred("_go")


func _local_aabb(root: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [[root, Transform3D.IDENTITY]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var n: Node = it[0]
		var xf: Transform3D = it[1]
		if n is Node3D and n != root:
			xf = xf * (n as Node3D).transform
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var box: AABB = xf * (n as MeshInstance3D).mesh.get_aabb()
			if first:
				out = box
				first = false
			else:
				out = out.merge(box)
		for c in n.get_children():
			stack.append([c, xf])
	return out


func _go() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			_track = int(a.trim_prefix("--track="))
		elif a.begins_with("--prefix="):
			_prefix = a.trim_prefix("--prefix=")
		elif a.begins_with("--max="):
			_max_gap = float(a.trim_prefix("--max="))
	var t := (load(GameState.TRACK_SCENES[_track]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var terrain_rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	if terrain_rid == RID():
		print("EROARE: nu am gasit TerrainBody")
		get_tree().quit(2)
		return
	# Apa e opaca (verde-jad): ce se vede sub o piesa e oglinda apei, nu fundul
	# marii. Sprijinul efectiv = max(teren, apa).
	var sea_y: float = float(t._sampler.mean_road_y()) + float(t.sea_level_offset)
	print("oglinda apei: y = %.2f" % sea_y)
	var dm := t.get_node_or_null("DecorManual")
	var cache: Dictionary = {}
	var bad := 0
	var checked := 0
	for c in dm.get_children():
		if not (c is Node3D) or c.scene_file_path == "":
			continue
		if _prefix != "" and not str(c.name).begins_with(_prefix):
			continue
		var skip := false
		for sp: String in SKIP_PREFIXES:
			if str(c.name).begins_with(sp):
				skip = true
		if skip:
			continue
		var path: String = c.scene_file_path
		if not cache.has(path):
			var inst := (load(path) as PackedScene).instantiate()
			cache[path] = _local_aabb(inst)
			inst.free()
		var bb: AABB = cache[path]
		var gt: Transform3D = (c as Node3D).global_transform
		var worst := -INF
		var lowest := INF
		for cx in [bb.position.x, bb.end.x]:
			for cz in [bb.position.z, bb.end.z]:
				var corner: Vector3 = gt * Vector3(cx, bb.position.y, cz)
				var q := PhysicsRayQueryParameters3D.create(
					corner + Vector3.UP * 300.0, corner + Vector3.DOWN * 400.0)
				q.collide_with_areas = false
				var hit: Dictionary = space.intersect_ray(q)
				var guard := 0
				while not hit.is_empty() and hit["rid"] != terrain_rid and guard < 32:
					q.exclude = q.exclude + [hit["rid"]]
					hit = space.intersect_ray(q)
					guard += 1
				if hit.is_empty() or hit["rid"] != terrain_rid:
					continue
				var gap: float = corner.y - maxf(float(hit["position"].y), sea_y)
				worst = maxf(worst, gap)
				lowest = minf(lowest, gap)
		checked += 1
		if worst > _max_gap:
			bad += 1
			print("  PLUTESTE %-18s gol max %.2f m (min %.2f) la %s" % [
				str(c.name), worst, lowest, str((c as Node3D).global_position.snapped(Vector3(0.1, 0.1, 0.1)))])
	print("piese verificate: %d | peste %.2f m: %d" % [checked, _max_gap, bad])
	print("VERDICT: %s" % ("OK" if bad == 0 else "PROBLEMA"))
	get_tree().quit(1 if bad > 0 else 0)
