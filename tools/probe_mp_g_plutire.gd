extends Node
## Cele doua cote de teren sub piesele pe care `probe_manual` le declara
## PLUTESTE: campul neted (`ground_y`, ce masoara probe_manual) si panza de
## coliziune reala (raycast pe TerrainBody, pe care STA piesa).
##
## Intrebarea la care raspunde: piesa chiar pluteste, sau probe_manual compara
## cu o suprafata care nu exista in joc?
const TRACK := "res://scenes/tracks/Track15.tscn"
const NUME := ["bolovan306", "bolovan311", "quenual379", "quenual380",
	"quenual381", "orhidee432", "bromelie434", "orhidee435", "feriga436",
	"bromelie437"]
var _track: Track
var _rid: RID = RID()
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	var zone := _track.get_node_or_null("DecorManual/ZoneG_Serpentine")
	print("; nume | y_piesa | camp_neted | panza_reala | fata de panza")
	for c in zone.get_children():
		if not NUME.has(str(c.name)):
			continue
		var p: Vector3 = (c as Node3D).global_position
		var smooth := _track._sampler.ground_y(p.x, p.z)
		var real := _sol(p)
		print("; %-12s %8.2f  %10.2f  %11.2f  %+8.2f" % [
			c.name, p.y, smooth, real, p.y - real])
	get_tree().quit(0)

func _sol(q: Vector3) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var sp := _track.get_world_3d().direct_space_state
	var pr := PhysicsRayQueryParameters3D.create(
		Vector3(q.x, _sus, q.z), Vector3(q.x, _sus - 1200.0, q.z))
	pr.collide_with_areas = false
	var hit: Dictionary = sp.intersect_ray(pr)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		pr.exclude = pr.exclude + [hit["rid"]]
		hit = sp.intersect_ray(pr)
		g += 1
	return float(hit["position"].y) if not hit.is_empty() else -999.0
