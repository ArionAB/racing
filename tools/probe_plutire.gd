extends Node
## Garda pentru prop-uri care PLUTESC. Scrisa dupa ce 12 mese s-au asezat cu cota
## din `_terrain_mesh_y`, care EXTRAPOLEAZA dincolo de panza de teren (masurat:
## intoarce 27.5 unde solul real e la -27.6). Nicio sonda n-a prins-o, fiindca
## mesele au `coliziune = "none"` si razele trec prin ele — s-a vazut abia cand
## cineva a deschis captura.
##
## Aici nu se cere coliziune pe prop: se trage o raza IN JOS din baza fiecarui
## prop vizibil si se cere sa gaseasca TEREN sub el, la o distanta rezonabila.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePlutire.tscn -- --track=6
const MAX_GOL := 4.0   ## metri de aer tolerati sub baza unui prop

func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	var only := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			only = int(a.trim_prefix("--track="))
	var t := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var bad := 0
	var checked := 0
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if not mi.visible or mi.mesh == null:
			continue
		# doar prop-uri din decor, nu carosabil/teren
		var owner_nm := ""
		var up: Node = n
		while up != null:
			if str(up.name).begins_with("DecorManual"):
				owner_nm = str(n.name)
				break
			up = up.get_parent()
		if owner_nm == "":
			continue
		var aabb := mi.get_aabb()
		var base: Vector3 = mi.global_transform * (aabb.position + Vector3(
			aabb.size.x * 0.5, 0.0, aabb.size.z * 0.5))
		checked += 1
		var q := PhysicsRayQueryParameters3D.create(
			base + Vector3.UP * 1.0, base + Vector3.DOWN * 200.0)
		var hit: Dictionary = space.intersect_ray(q)
		if hit.is_empty():
			print("  %s: NIMIC dedesubt (baza y=%.1f)" % [owner_nm, base.y])
			bad += 1
		else:
			var gol: float = base.y - float(hit["position"].y)
			if gol > MAX_GOL:
				print("  %s: pluteste %.1f m (baza y=%.1f, sol y=%.1f)" % [
					owner_nm, gol, base.y, float(hit["position"].y)])
				bad += 1
	print("")
	print("prop-uri verificate: %d | care plutesc: %d" % [checked, bad])
	print("VERDICT: %s" % ("OK" if bad == 0 else "PROBLEMA"))
	get_tree().quit(1 if bad > 0 else 0)
