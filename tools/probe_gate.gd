extends Node
## Garda pentru POARTA DE START per pista: ce model a ajuns efectiv in scena.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGate.tscn
##
## Trebuie rulata ca SCENA, nu cu --script: are nevoie de autoload-uri.
##
## De ce se uita la CALEA modelului si nu doar "exista o poarta": suprascrierea
## per pista se poate rupe tacut (o cale gresita cade pe cea implicita, o
## atribuire inainte de apply_theme se pierde) si in ambele cazuri numaratoarea
## de noduri iese la fel — vezi memoria "efecte invizibile nu se numara".
##
## Nu are prag pe modelul ales: ce poarta merita fiecare pista e decizie de
## design, nu de sonda. Verifica doar ca alegerea AJUNGE in scena, ca poarta
## sta pe linia de start intoarsa pe directia de mers, si ca s-a scalat pe
## latimea soselei — un GLB de alta marime altfel ramane cu coliziunea in aer.

## Cat de departe de start are voie sa stea poarta.
const MAX_START_OFFSET: float = 0.5
## Sub atat, poarta nu e intoarsa spre masinile care vin.
##
## Fata assetului e -Z (contractul "+Y in Blender"), iar masinile vin DINSPRE
## -start_direction(), deci fata trebuie sa se uite in sens INVERS mersului.
## Semnul asta a fost gresit si nu se vedea din nicio cifra: poarta era pe
## linia de start, scalata corect, doar ca aratai spatele panoului la countdown.
const MIN_FACING_DOT: float = 0.99
## Abaterea admisa de la latimea tinta.
const WIDTH_TOLERANCE: float = 0.5


func _ready() -> void:
	await get_tree().process_frame
	var failed := false
	for i in GameState.TRACK_SCENES.size():
		if await _check(i):
			failed = true
	print("")
	print("VERDICT: %s" % ("PROBLEMA" if failed else "OK"))
	get_tree().quit(1 if failed else 0)


func _check(idx: int) -> bool:
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var bad := false
	var want := track._gate_model_path()
	var gates := track.find_children("*", "StaticBody3D", true, false) \
		.filter(func(n: Node) -> bool: return n.is_in_group("start_gate"))

	if gates.is_empty():
		# Poate e voit ("none"), poate e o cale gresita — se vede din cerere.
		print("%-16s POARTA: niciuna  (cerut: %s)" % [track.track_name, want])
		if want != "none":
			print("    ^ dar nu s-a cerut \"none\"")
			bad = true
		track.queue_free()
		return bad

	var gate := gates[0] as StaticBody3D
	# Nodul model, singurul copil Node3D care nu e forma de coliziune.
	var model_node: Node3D = null
	for c in gate.get_children():
		if c is Node3D and not (c is CollisionShape3D):
			model_node = c as Node3D
			break

	# Ce s-a INSTANTIAT efectiv, nu ce s-a cerut: aici se vede caderea pe
	# modelul implicit dupa o cale gresita.
	var got: String = model_node.scene_file_path if model_node != null else ""

	# Latimea se masoara pe NODUL MODEL, nu pe `gate`: gate e rotit pe
	# start_direction(), iar model_aabb da o cutie aliniata la axe — adica
	# proiectia rotita, care pe acelasi model a citit intre 3.1 si 12.1 m, dupa
	# cum e intors startul fiecarei piste.
	#
	# Si NU se mai inmulteste cu model_node.scale: model_aabb coboara PRIN
	# transformul nodului, deci scara e deja in cifra. Inmultind-o inca o data
	# ieseau 11.8 m in loc de 16.4 si sonda acuza codul de o eroare a ei.
	var aabb := track.model_aabb(model_node)
	var gate_w := aabb.size.x
	var gate_h := aabb.size.y
	# Poarta se scaleaza pe latimea soselei plus 1.2 m degajare pe fiecare parte.
	var want_w := (track.width_at_index(0) + 1.2) * 2.0

	var offset := gate.global_position.distance_to(track.baked[0])
	var facing := -gate.global_basis.z.dot(-track.start_direction())

	print("%-16s POARTA: %s" % [track.track_name, got.get_file()])
	print("    latime %.1f m (tinta %.1f)   inaltime %.1f m" % [
		gate_w, want_w, gate_h])
	print("    fata de start %.2f m   orientare %.3f" % [offset, facing])

	if got != want:
		print("    ^ cerut %s, dar in scena e %s" % [want.get_file(), got.get_file()])
		bad = true
	if absf(gate_w - want_w) > WIDTH_TOLERANCE:
		print("    ^ poarta nu s-a scalat pe latimea soselei")
		bad = true
	if offset > MAX_START_OFFSET:
		print("    ^ poarta nu e pe linia de start")
		bad = true
	if facing < MIN_FACING_DOT:
		print("    ^ poarta nu e intoarsa spre masinile care vin")
		bad = true

	track.queue_free()
	return bad
