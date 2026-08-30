extends Node
## PLUTESC baloanele aterizate dupa ce le-am mutat?
##
## Mutarea lor pe orizontala le-a scos de pe cotele pe care fusesera asezate.
## O panza „aterizata" care sta la 3 m deasupra solului e mai rea decat una
## suprapusa: se vede imediat ca obiect lipit in aer.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var space := get_viewport().world_3d.direct_space_state
	var items: Array = []
	_walk(t, items)
	var bad := 0
	for it in items:
		var nm: String = it[0]
		var pos: Vector3 = it[1]
		var pr := PhysicsRayQueryParameters3D.create(
			Vector3(pos.x, pos.y + 200.0, pos.z), Vector3(pos.x, pos.y - 300.0, pos.z))
		var hit := space.intersect_ray(pr)
		if hit.is_empty():
			print("  %s: FARA TEREN dedesubt" % nm)
			bad += 1
			continue
		var gy: float = (hit["position"] as Vector3).y
		var d := pos.y - gy
		if absf(d) > 1.5:
			print("  %s: %+.1f m fata de sol (y=%.1f, sol=%.1f)" % [nm, d, pos.y, gy])
			bad += 1
	print("panze cu cota gresita: %d din %d" % [bad, items.size()])
	get_tree().quit()


func _walk(n: Node, out: Array) -> void:
	for c in n.get_children():
		var nm := String(c.name)
		# `*_col` sunt corpurile de coliziune, fii cu transformul la origine
		# locala: pozitia lor globala nu spune nimic despre unde sta panza.
		# Prima versiune a sondei le numara si raporta 80 din 80 „gresite".
		if c is Node3D and not nm.ends_with("_col") 				and (nm.contains("panza") or nm.contains("cos_jos")):
			out.append([nm, (c as Node3D).global_position])
		_walk(c, out)
