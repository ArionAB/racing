extends Node
## Blocurile de sub piata au voie sa NU aiba corp fizic (metadata coliziune
## "none"). Daca totusi capata unul, ele intra in lumea fizica si pot schimba
## comportamentul AI-ului chiar departe de piata (scheduling, contacte).
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var root := track.get_node("DecorManual/1) Piata Kuixinglou")
	var with_body := 0
	for ch in root.get_children():
		if not str(ch.name).begins_with("bloc_sub_piata"): continue
		var bodies: Array = []
		_collect(ch, bodies)
		if not bodies.is_empty():
			with_body += 1
			print("%s ARE %d corpuri fizice" % [ch.name, bodies.size()])
	print("blocuri cu corp fizic: %d" % with_body)
	# cate corpuri statice are TOATA pista (comparabil intre versiuni)
	var all: Array = []
	_collect(track, all)
	print("corpuri fizice pe toata pista: %d" % all.size())
	get_tree().quit()
func _collect(n: Node, out: Array) -> void:
	if n is PhysicsBody3D: out.append(n)
	for c in n.get_children(): _collect(c, out)
