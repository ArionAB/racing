extends Node
## Garda VANTULUI: verifica faptul ca vegetatia se mai leagana dupa coacerea in
## MultiMesh.
##
##   godot --path . res://tools/ProbeSway.tscn -- --track=0
##
## RULEAZA CU FEREASTRA, si asta nu e o preferinta. Datele unui [MultiMesh] stau
## in serverul de randare; `get_instance_transform()` le CERE de acolo. In
## `--headless` serverul e cel fals si intoarce `Transform3D.IDENTITY` pentru
## orice instanta — deci o sonda headless ar raporta ca tot decorul e ingramadit
## in origine, pe o scena care se randeaza perfect. (Exact asta s-a intamplat la
## prima incercare, si a costat o ora.)
##
## DE CE EXISTA. Pana la TrackDecorBatch, tufele erau noduri si vantul le rotea
## direct; daca se strica ceva, se vedea. Dupa coacere, o tufa e 12 numere
## intr-un buffer, iar [SwayDriver] le rescrie prin doua tablouri paralele de
## indici. Orice greseala acolo — un index gresit, o inregistrare pierduta la
## reconstruire, un buffer schimbat sub picioare — nu da nicio eroare in consola:
## vantul pur si simplu se opreste, si nimeni nu observa luni de zile.

const FRAMES: int = 40
## Sub atatea instante inregistrate, ceva s-a rupt in lantul semn -> coacere ->
## inregistrare. Pe Dunele ies ~150; pragul e larg dinadins, ca sonda sa prinda
## "s-a rupt", nu "s-a schimbat densitatea".
const MIN_ITEMS: int = 20


func _ready() -> void:
	var track_index := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
	track_index = clampi(track_index, 0, GameState.TRACK_SCENES.size() - 1)
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var sway: SwayDriver = null
	for n in _walk(track):
		if n is SwayDriver:
			sway = n as SwayDriver
			break
	if sway == null:
		_fail("nu exista SwayDriver in pista")
		return

	var items: Array = sway.tracked_instances()
	print("=== VANT: %s ===" % track.track_name)
	print("  instante inregistrate: %d" % items.size())
	if items.size() < MIN_ITEMS:
		_fail("prea putine instante inregistrate (minim %d)" % MIN_ITEMS)
		return

	# Se urmaresc mai multe instante, nu una: un singur esantion poate nimeri
	# exact un nod al sinusoidei si ar raporta "nu se misca" pe un vant sanatos.
	var probes: Array[int] = []
	for k in 5:
		probes.append(int(float(k) * float(items.size() - 1) / 4.0))

	var before: Array[Transform3D] = []
	for i in probes:
		before.append(_read(items[i]))
	for f in FRAMES:
		await RenderingServer.frame_post_draw
	var max_tilt := 0.0
	var max_drift := 0.0
	for k in probes.size():
		var after := _read(items[probes[k]])
		max_tilt = maxf(max_tilt,
			(before[k].basis.x - after.basis.x).length())
		max_drift = maxf(max_drift,
			(before[k].origin - after.origin).length())

	print("  inclinare maxima pe %d cadre: %.5f" % [FRAMES, max_tilt])
	print("  deriva de pozitie:            %.5f" % max_drift)
	# Orientarea trebuie sa se schimbe; pozitia NU — o tufa care se leagana
	# ramane infipta unde a fost. Fara a doua conditie, o inmultire pusa pe
	# partea gresita (care ar trimite tufele in zbor prin peisaj) ar trece.
	if max_tilt <= 0.001:
		_fail("vegetatia nu se misca")
		return
	if max_drift > 0.0001:
		_fail("vegetatia DERIVEAZA din pozitie (inmultire pe partea gresita?)")
		return
	print("VERDICT: OK")
	get_tree().quit(0)


func _read(item: Dictionary) -> Transform3D:
	var mm: MultiMesh = item["multimesh"]
	return mm.get_instance_transform(item["index"])


func _fail(reason: String) -> void:
	printerr("VANT: %s" % reason)
	print("VERDICT: PROBLEMA (%s)" % reason)
	get_tree().quit(1)


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
