extends Node
## Reaseaza CHIPAROSII pe teren si scoate din scena pe cei ramasi in gol.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenCappReasezPlopi.tscn
##
## De ce e nevoie. Plopii fusesera asezati candva pe cota platoului (y ~47-48).
## Intre timp terenul de sub o parte din ei a fost SAPAT — canioane, taietura
## vaii, poalele hornurilor — si a coborat la 19-26 m. Nimeni n-a observat
## fiindca piesele erau inalte de 12-15 m: un copac care pluteste cu 20 m dar
## are 15 m inaltime pare doar "un copac pe o movila din spate".
##
## Runda 10 a scalat chiparosii la 3.5 m (erau MAI INALTI decat hornurile, ceea
## ce facea hornurile sa citeasca a ornamente de gradina de 6 m). Scalarea n-a
## creat defectul, doar l-a facut vizibil: in captura de la fractia 0.10 se vad
## fara dubiu trei chiparosi agatati in cer, in dreapta sus.
##
## Sonda ProbeCappPlopi masoara delta fata de teren; asta e unealta care o
## repara. Cine mai muta terenul pe POI B ruleaza AMANDOUA.

const TRACK := "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var sampler: TrackSideSampler = track._sampler
	var stack: Array[Node] = [track]
	var rows: Array[String] = []
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if not (nd is Node3D):
			continue
		var nm := String(nd.name)
		if not nm.begins_with("plop") or nm.ends_with("_col"):
			continue
		var n3 := nd as Node3D
		var pos := n3.global_position
		var g := sampler.ground_y(pos.x, pos.z)
		rows.append("%s|%f" % [nm, g])
	rows.sort()
	print("")
	print("=== COTE ===")
	for r in rows:
		print(r)
	print("; %d chiparosi masurati" % rows.size())
	get_tree().quit(0)
