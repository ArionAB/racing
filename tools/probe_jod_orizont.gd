extends Node
## Unde a pus `_build_horizon` siluetele Jodhpur si ce material a primit
## fiecare nod (FarCity_A trebuie sa fie blue_lime_light, altfel casele ies
## albe — PR #424). Plus distanta la sosea (cotele legate: < fog_end de noapte
## 240, < FAR_PLANE 380) si cat din silueta intra sub marginea de sus a
## cadrului la distanta aia (10 + 0,092·d, brief §2.0).
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodOrizont.tscn -- --track=10
const NAMES := ["FarCity_A", "DesertRidge_A", "DesertRidge_B", "UmaidBhawan_A"]

func _ready() -> void:
	await get_tree().process_frame
	var only := 10
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	var cls_of := {}
	for cls: String in Palette._tri_mats:
		cls_of[Palette._tri_mats[cls]] = "tri:" + cls
	cls_of[Palette.world_material()] = "atlas"
	var n := 0
	var bad := 0
	var cands: Array[Node] = []
	var st: Array[Node] = [track]
	while not st.is_empty():
		var q: Node = st.pop_back()
		for k in q.get_children():
			st.append(k)
			for nm: String in NAMES:
				if String(k.name).begins_with(nm) and k is Node3D and not (k is MeshInstance3D and k.get_parent().name.begins_with(nm)):
					cands.append(k)
					break
	for c in cands:
		var m := c as Node3D
		n += 1
		var d := track._road_distance_xz(m.global_position)
		var road_y := track.baked[track.closest_index_global(m.global_position)].y
		var aabb := Track.model_aabb(m)
		var top := aabb.end.y - road_y
		var vis := 10.0 + 0.092 * d
		var mats := ""
		for mi in _meshes(m):
			var got: String = cls_of.get(mi.material_override, "ALT")
			mats += " %s=%s" % [mi.name, got]
			if String(mi.name) == "FarCity_A" and got != "tri:blue_lime_light":
				bad += 1
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				bad += 1
				mats += "(UMBRA!)"
		print("%-16s poz (%7.1f, %6.1f, %7.1f) scara %.2f  la sosea %5.1f m  varf +%5.1f / cadrul vede +%5.1f%s" % [
			m.name, m.global_position.x, m.global_position.y, m.global_position.z,
			m.global_transform.basis.get_scale().x, d, top, vis, mats])
	print("siluete: %d" % n)
	print("VERDICT: %s" % ("OK" if n > 0 and bad == 0 else "PICAT (%d)" % bad))
	get_tree().quit(0 if n > 0 and bad == 0 else 1)

func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		for k in c.get_children(): st.append(k)
		if c is MeshInstance3D: out.append(c as MeshInstance3D)
	return out
