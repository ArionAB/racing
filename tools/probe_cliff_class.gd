extends Node
## Garda clasei de roca a falezelor: `TrackCliffs` ia piatra din `rock_class` a
## temei (ca arcada, Track._build_arch), iar o tema FARA cheia — Dunele — ramane
## pe `rock`, adica exact ce primea inainte.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCliffClass.tscn
##
## Trebuie rulata ca SCENA (autoload-uri). Construieste Dunele (Track01) de doua
## ori: nemodificate, apoi cu `rock_class = alpine_granite` pus in tema `desert`.
## Cache-ul de teme e PARTAJAT intre piste (vezi Track._with_overrides), deci
## sonda il muta si il readuce — ruleaza o data si iese, nu are cum sa scurga in
## alta pista.
##
## Ce se verifica, numarand nodurile din `Cliffs` dupa materialul lor de clasa:
##   fara cheie   toate sectiunile pe `rock`, niciuna pe granit     (Dunele neatinse)
##   cu cheie     aceleasi sectiuni, acum toate pe granit, zero pe `rock`
## Numarul trebuie sa fie ACELASI in cele doua: clasa schimba materialul, nu
## asezarea (seed-ul si rng-ul n-au voie sa se miste). Verificata prin sabotaj:
## cu parametrul `rock_class` ignorat in TrackCliffs._place, a doua varianta ramane
## pe `rock` si garda pica.

const SCENE: String = "res://scenes/tracks/Track01.tscn"
const THEME: String = "desert"
const CLASS_NAME: String = "alpine_granite"

var _fail: int = 0


func _ready() -> void:
	await get_tree().process_frame
	var base := await _count(false)
	var swapped := await _count(true)
	print("                     rock  %s  total" % CLASS_NAME)
	print("  fara cheie         %5d  %8d  %5d" % [base["rock"], base["other"], base["all"]])
	print("  cu rock_class      %5d  %8d  %5d" % [swapped["rock"], swapped["other"], swapped["all"]])
	_expect(int(base["rock"]) > 0, "Dunele n-are nicio sectiune pe `rock` — n-am masurat nimic")
	_expect(int(base["other"]) == 0, "fara cheie, o sectiune a plecat de pe `rock`")
	_expect(int(swapped["rock"]) == 0, "cu cheie, au ramas sectiuni pe `rock`")
	_expect(int(swapped["other"]) == int(base["rock"]),
		"asezarea s-a schimbat odata cu clasa (%d vs %d)" % [swapped["other"], base["rock"]])
	if _fail == 0:
		print("VERDICT: OK")
	else:
		print("VERDICT: PROBLEMA (%d)" % _fail)
	get_tree().quit(0 if _fail == 0 else 1)


func _expect(ok: bool, why: String) -> void:
	if not ok:
		_fail += 1
		print("  PICA: %s" % why)


func _count(with_class: bool) -> Dictionary:
	var track := (load(SCENE) as PackedScene).instantiate() as Track
	var theme: Dictionary = track.themes()[THEME]
	if with_class:
		theme["rock_class"] = CLASS_NAME
	get_tree().root.add_child(track)
	# Doua cadre: rebuild() ruleaza in _ready, iar copiii intra in arbore dupa.
	await get_tree().process_frame
	await get_tree().process_frame
	theme.erase("rock_class")
	var rock := Palette.triplanar_class_material("rock")
	var out := {"rock": 0, "other": 0, "all": 0}
	var cliffs := track.get_node_or_null("Cliffs")
	if cliffs != null:
		_walk(cliffs, rock, out)
	track.queue_free()
	await get_tree().process_frame
	return out


## Numara nodurile vizuale dupa materialul de clasa. Scatter-ul de la baza
## falezelor (pietricele din atlas) are alt material si nu intra in niciuna din
## doua, deci „other" tine doar sectiunile cu clasa ceruta.
func _walk(node: Node, rock: Material, out: Dictionary) -> void:
	var mat: Material = null
	if node is MeshInstance3D:
		mat = (node as MeshInstance3D).material_override
	elif node is MultiMeshInstance3D:
		mat = (node as MultiMeshInstance3D).material_override
	if mat != null:
		if mat == rock:
			out["rock"] += 1
			out["all"] += 1
		elif mat == Palette.triplanar_class_material(CLASS_NAME):
			out["other"] += 1
			out["all"] += 1
	for child in node.get_children():
		_walk(child, rock, out)
