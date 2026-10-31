extends SceneTree
## Garda issue #606: gardul de nuiele (`shiba_fence`) de pe Kyoto trebuie sa aiba
## coliziune, atat instantele-nod (DecorManual, corp automat din world_prop) cat si
## cele din MultiMesh (POI G, corp `GardG_col` emis de generator).
##
##   godot --headless --path . --script res://tools/probe_fence_col.gd
##   ... -- --sabotage     (scoate corpurile de gard: sonda TREBUIE sa pice)
##
## Pentru fiecare modul de gard se impinge un gabarit de masina (cutie 1,0 x 0,6 x 1,0
## m, la jumatatea inaltimii gardului, cu centrul la 0,4 m de planul panoului: se
## suprapune pe jumatate, ca un impact; coincident cu panoul dau degenerari GJK) in panou: trebuie sa atinga un corp.
## Pe langa asta, la 1,2 m lateral de panou (spre drum, cat sa nu-l atinga) gabaritul
## trebuie sa fie liber de corpul acelui gard: gardul n-are voie sa fie umflat.
## Cod de iesire 1 daca vreun modul nu are corp sau gardul e umflat.

const TRACK := "res://scenes/tracks/Track18.tscn"
const FENCE := "shiba_fence"
const FENCE_H := 1.115
var _track: Node = null
var _frames := 0
var _sabotage := false
var _stripped := false


func _initialize() -> void:
	_sabotage = "--sabotage" in OS.get_cmdline_user_args()
	_track = (load(TRACK) as PackedScene).instantiate()
	root.add_child(_track)


func _collect(node: Node, nodes: Array, mm: Array) -> void:
	for c in node.get_children():
		if c is Node3D and String((c as Node3D).scene_file_path).get_file().get_basename() == FENCE:
			nodes.append(c)
		elif c.get("explicit_xforms") != null and (c.get("explicit_xforms") as PackedFloat32Array).size() > 0:
			mm.append(c)
		_collect(c, nodes, mm)


func _bodies(node: Node, out: Array) -> void:
	for c in node.get_children():
		if c is StaticBody3D and String(c.name).ends_with("_col") and (
				String(c.name).begins_with("GardG") or String(c.name).contains("Gard")):
			out.append(c)
		_bodies(c, out)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 4:
		return false
	if _sabotage and not _stripped:
		var bs: Array = []
		_bodies(_track.get_node("DecorManual"), bs)
		for b in bs:
			b.get_parent().remove_child(b)
			b.free()
		_stripped = true
		_frames = 0
		return false
	var manual := _track.get_node("DecorManual")
	var nodes: Array = []
	var mms: Array = []
	_collect(_track, nodes, mms)
	var bodies: Array = []
	_bodies(manual, bodies)
	var centres: Array[Transform3D] = []
	for n in nodes:
		var t := (n as Node3D).global_transform
		centres.append(t)
	var n_nodes := centres.size()
	for m in mms:
		var f: PackedFloat32Array = m.get("explicit_xforms")
		var models: Array = m.get("models")
		for i in range(0, f.size(), 13):
			var idx := int(f[i])
			if String((models[idx] as PackedScene).resource_path).get_file().get_basename() != FENCE:
				continue
			var b := Basis(Vector3(f[i + 1], f[i + 2], f[i + 3]), Vector3(f[i + 4], f[i + 5], f[i + 6]),
				Vector3(f[i + 7], f[i + 8], f[i + 9]))
			centres.append(Transform3D(b, Vector3(f[i + 10], f[i + 11], f[i + 12])))
	var space := root.world_3d.direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 0.6, 1.0)
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = box
	q.collide_with_areas = false
	var miss := 0
	var fat := 0
	for t in centres:
		var mid: Vector3 = t.origin + t.basis.y * (FENCE_H * 0.5)
		q.transform = Transform3D(t.basis.orthonormalized(), mid + t.basis.x.normalized() * 0.4)
		var hit := false
		for h in space.intersect_shape(q, 128):
			var col := h["collider"] as Node
			if col is StaticBody3D and String(col.name).contains("Gard") or (col != null and col.get_parent() != null
					and String(col.name).begins_with("shiba_fence")):
				hit = true
		if not hit:
			miss += 1
			print("  fara corp la ", t.origin, " (modul ", centres.find(t), ")")
		# gard umflat: gabaritul la 1,2 m lateral (X local) nu trebuie sa atinga gardul
		var off := t.basis.x.normalized() * 1.2
		q.transform = Transform3D(t.basis.orthonormalized(), mid + off)
		for h in space.intersect_shape(q, 128):
			var col := h["collider"] as Node
			if col is StaticBody3D and (String(col.name).contains("Gard") or String(col.name).begins_with("shiba_fence")):
				fat += 1
				break
	print("module de gard: %d (noduri %d, MultiMesh %d); corpuri GardG_col: %d" % [
		centres.size(), n_nodes, centres.size() - n_nodes, bodies.size()])
	print("fara corp: %d  |  gard umflat (atinge la 1,2 m): %d" % [miss, fat])
	var bad := miss > 0 or fat > 0 or centres.is_empty()
	print("VERDICT: %s" % ("PICA" if bad else "OK"))
	quit(1 if bad else 0)
	return true
