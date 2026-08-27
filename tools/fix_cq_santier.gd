extends Node
## Cele trei bariere de santier de pe viaduct stau in aer (22-35 m peste
## teren). Le coboram pe suprafata REALA de sub ele - deck-ul viaductului -
## si tiparim transformurile noi, ca sa le scriu in .tscn.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var sec := track.find_child("6) Nodul Huangjuewan", true, false)
	for nm in ["santier212", "santier213", "santier214"]:
		var node := sec.find_child(nm, false, false) as Node3D
		if node == null:
			print("%s: lipseste" % nm)
			continue
		var p: Vector3 = node.global_position
		# cautam podeaua pornind de SUS, ca sa prindem deck-ul viaductului
		var q := PhysicsRayQueryParameters3D.create(
			p + Vector3.UP * 8.0, p + Vector3.DOWN * 3.0)
		var h := space.intersect_ray(q)
		if h.is_empty():
			print("%s: nici de sus nu gasesc podea la (%.1f, %.1f, %.1f)" % [nm, p.x, p.y, p.z])
		else:
			print("%s: pos y %.2f -> podea %.2f (%s), dy %+.2f" % [
				nm, p.y, h.position.y, h.collider.name, h.position.y - p.y])
	get_tree().quit()
