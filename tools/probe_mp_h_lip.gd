extends SceneTree
## Cat din buza de stanca se vede din camera de joc, si de la ce unghi.
##
## Intrebarea careia raspunde (verdictul orb al rundei 9): "nu exista buza
## taiata / cadere pe partea golului". Runda 10 a pus 47 de bolovani pe muchie,
## si tot nu se vad in captura. Sonda nu numara instante — memoria
## `efecte-invizibile-nu-se-numara` — ci trage RAZE din ochiul soferului catre
## coama fiecarui bolovan si spune cate sunt lovite de teren inainte.
##
##   godot --headless --fixed-fps 60 --path . --script res://tools/probe_mp_h_lip.gd

const TRACK := "res://scenes/tracks/Track15.tscn"
## Ochiul: ChaseCamera sta la ~2,6 m peste sosea, in spate cu ~6 m.
const EYE_UP := 2.6
const EYE_BACK := 6.0


func _initialize() -> void:
	var tr := (load(TRACK) as PackedScene).instantiate()
	get_root().add_child(tr)
	await process_frame
	await process_frame
	await process_frame
	var track = tr
	var n: int = track.baked.size()
	var terrain_rid := RID()
	for c in track.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	var space: PhysicsDirectSpaceState3D = track.get_world_3d().direct_space_state

	# Coamele buzei: nodurile buzaStanca din zona H.
	var zone := track.get_node_or_null("DecorManual/ZoneH_Cornisa")
	if zone == null:
		print("; NU gasesc ZoneH_Cornisa")
		quit(1)
		return
	var vazut := 0
	var ascuns := 0
	var unghiuri: Array[float] = []
	for ch in zone.get_children():
		if not str(ch.name).begins_with("buzaStanca"):
			continue
		var aabb := _aabb(ch)
		if aabb.size == Vector3.ZERO:
			continue
		var coama: Vector3 = (ch as Node3D).global_position
		coama.y = aabb.position.y + aabb.size.y   # varful real, in lume
		# Punctul de pe traseu cel mai apropiat, ca sa stiu de unde se priveste.
		var best := 0
		var bd := INF
		for i in n:
			var b: Vector3 = track.baked[i]
			var d: float = (b.x - coama.x) * (b.x - coama.x) + (b.z - coama.z) * (b.z - coama.z)
			if d < bd:
				bd = d
				best = i
		# Ochiul: cu EYE_BACK inapoi pe traseu, EYE_UP peste sosea.
		var pas: int = maxi(1, int(round(EYE_BACK / 1.8)))
		var p_eye: Vector3 = track.baked[(best - pas + n) % n]
		var eye := Vector3(p_eye.x, p_eye.y + EYE_UP, p_eye.z)
		var q := PhysicsRayQueryParameters3D.create(eye, coama)
		q.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(q)
		var blocat: bool = not hit.is_empty() and hit.get("rid", RID()) == terrain_rid
		# Unghiul sub care se vede coama fata de orizontala ochiului.
		var dv := coama - eye
		var oriz := Vector2(dv.x, dv.z).length()
		var ang := rad_to_deg(atan2(dv.y, maxf(oriz, 0.01)))
		unghiuri.append(ang)
		if blocat:
			ascuns += 1
		else:
			vazut += 1
	unghiuri.sort()
	var med := 0.0
	for a in unghiuri:
		med += a
	if unghiuri.size() > 0:
		med /= float(unghiuri.size())
	print("; BUZA DE STANCA din ochiul soferului (ochi la +%.1f m, %.1f m in spate)" % [EYE_UP, EYE_BACK])
	print("; coame vizibile %d, ascunse de teren %d din %d" % [
		vazut, ascuns, vazut + ascuns])
	if unghiuri.size() > 0:
		print("; unghi fata de orizontala: min %+.1f, median %+.1f, mediu %+.1f, max %+.1f grade" % [
			unghiuri[0], unghiuri[unghiuri.size() / 2], med, unghiuri[-1]])
	quit(0)


func _aabb(nd: Node) -> AABB:
	var out := AABB()
	var first := true
	for m in _meshes(nd):
		var a: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out


func _meshes(nd: Node) -> Array:
	var out: Array = []
	if nd is MeshInstance3D:
		out.append(nd)
	for c in nd.get_children():
		out.append_array(_meshes(c))
	return out
