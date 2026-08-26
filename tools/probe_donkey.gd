extends Node
## Sonda magarului animat (stromboli/props/donkey.glb) pe pista reala
## (Stromboli, Track11 — figurantul din Ginostra).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDonkey.tscn
##   godot --fixed-fps 60 --path . res://tools/ProbeDonkey.tscn   (+ capturi PNG)
##
## Ca SCENA, nu cu --script (pista trage autoload-uri; vezi probe_cow.gd).
##
## Ce verifica — lantul intreg, nu doar existenta fisierului:
##   1. Magarul din .tscn e chiar un PathMover si si-a construit corpul.
##   2. GLB-ul are AnimationPlayer cu "Walk" si "Idle", iar PathMover l-a GASIT
##      si a pornit ceva (`current_animation` nu e gol). Fara capul asta, un
##      clip redenumit in Blender ar iesi teapan si nimeni n-ar afla.
##   3. Bucla e pusa (LOOP_LINEAR) — importul Godot lasa clipurile one-shot,
##      deci un magar corect exportat ar face un pas si ar ingheta.
##   4. Alegerea automata dupa viteza: cu `speed` > 0 pica pe Walk, cu 0 pe
##      Idle. Asta e contractul lui PathMover._autoplay_animation.
##   5. SCHELETUL CHIAR DEFORMEAZA: doua momente din Walk au poze de oase
##      diferite. Un skin rupt "reda" animatia fara sa miste nimic, si doar
##      capul asta o prinde headless (memoria: efectele nu se verifica
##      numarand). Se masoara si AMPLITUDINEA pe un ciclu intreg: o poza care
##      difera cu 1e-4 trece un test de inegalitate, dar pe ecran e tot un
##      magar inghetat.
##   6. Copitele se ridica de la sol: pe un ciclu de Walk, cota celei mai joase
##      copite variaza. Un rig in care picioarele se rotesc din SOLD dar toata
##      greutatea a cazut pe Body ar da o poza care se schimba (5 trece) fara
##      ca piciorul sa se miste vizibil.
##
## Cu fereastra, salveaza capturi in snapshots/: magarul din vederea soferului.

const TRACK_SCENE := "res://scenes/tracks/Track11.tscn"
const PathMoverScript := preload("res://scenes/props/path_mover.gd")
const DONKEY_GLB := "res://assets/models/stromboli/props/donkey.glb"
## Sub atat, "deformeaza" e zgomot numeric, nu miscare. Amprenta e o SUMA de
## pozitii de oase (m), deci pragul e in metri-echivalenti pe tot scheletul.
const MIN_POSE_DELTA: float = 0.02
## Cat de sus trebuie sa ridice o copita pe ciclu. Un pas de magar de 1.4 m la
## greaban ridica piciorul cativa centimetri; sub 1 cm nu se vede din masina.
const MIN_HOOF_LIFT: float = 0.01

var _failed := false


func _ready() -> void:
	var track := (load(TRACK_SCENE) as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame

	print("\n=== Sonda magarului animat ===")

	# 1. Figurantul din pista, gasit dupa MODELUL pe care il poarta — nu dupa
	# numele nodului: numele se schimba la o rearanjare in editor, modelul nu.
	var movers: Array[Node] = []
	_collect_donkeys(track, movers)
	_check(not movers.is_empty(),
		"PathMover cu magar gasit in Track11 (%d)" % movers.size())
	if movers.is_empty():
		_finish()
		return
	var mover: Node = movers[0]
	print("  nod: %s  speed=%.1f m/s" % [mover.name, mover.speed])

	var ap := _player(mover)
	_check(ap != null, "AnimationPlayer gasit sub figurant")
	if ap == null:
		_finish()
		return
	var names := ap.get_animation_list()
	print("  animatii in GLB: ", ", ".join(names))

	# 2 + 3. Clipurile cerute de contractul cu PathMover, cu bucla pusa.
	for want: String in ["Walk", "Idle"]:
		_check(ap.has_animation(want), "animatia %s exista" % want)
	_check(not ap.current_animation.is_empty(),
		"PathMover a pornit un clip (e '%s')" % ap.current_animation)
	if ap.has_animation("Walk"):
		_check(ap.get_animation("Walk").loop_mode == Animation.LOOP_LINEAR,
			"bucla pusa pe Walk")

	# 4. Alegerea dupa viteza. Magarul din pista merge, deci trebuie sa fie pe
	# Walk; iar acelasi model parcat trebuie sa cada pe Idle.
	_check(ap.current_animation == "Walk",
		"figurantul in mers -> Walk (e '%s')" % ap.current_animation)
	var parked: String = await _parked_animation()
	_check(parked == "Idle", "acelasi model parcat -> Idle (e '%s')" % parked)

	# 5 + 6. Deformarea, masurata pe un ciclu INTREG de Walk: nu doua cadre
	# vecine (care pot cadea pe o portiune plata a curbei), ci extremele.
	var skel := _skeleton(mover)
	_check(skel != null, "Skeleton3D gasit")
	if skel == null:
		_finish()
		return
	print("  oase: %d" % skel.get_bone_count())

	var walk := ap.get_animation("Walk")
	# Numar FIX de pasi, nu `while t += length/N`: cu un clip de lungime 0
	# (animatie lipsa dintr-un export gresit) incrementul e 0 si sonda se
	# invarte la nesfarsit — adica exact cazul pe care ar trebui sa-l RAPORTEZE.
	_check(walk.length > 0.1, "clipul Walk are lungime (%.2f s)" % walk.length)
	const STEPS := 12
	var span := 0.0
	var hoof_lo := 1e9
	var hoof_hi := -1e9
	var first := Vector3.ZERO
	for i in STEPS + 1:
		var t: float = walk.length * float(i) / float(STEPS)
		ap.play("Walk")
		ap.seek(t, true)
		await get_tree().process_frame
		var sig := _bone_signature(skel)
		if i == 0:
			first = sig
		span = maxf(span, first.distance_to(sig))
		var hoof := _lowest_hoof(skel)
		hoof_lo = minf(hoof_lo, hoof)
		hoof_hi = maxf(hoof_hi, hoof)
	_check(span > MIN_POSE_DELTA,
		"scheletul deformeaza pe ciclu (amplitudine poza %.4f, prag %.2f)"
		% [span, MIN_POSE_DELTA])
	_check(hoof_hi - hoof_lo > MIN_HOOF_LIFT,
		"copitele se ridica de la sol (%.3f m pe ciclu, prag %.2f)"
		% [hoof_hi - hoof_lo, MIN_HOOF_LIFT])

	await _shoot(mover, "magar_merge")
	_finish()


## Figurantii care poarta magarul, cautati dupa fisierul modelului.
func _collect_donkeys(node: Node, out: Array[Node]) -> void:
	if node.get_script() == PathMoverScript:
		var m: PackedScene = node.model
		if m != null and m.resource_path == DONKEY_GLB:
			out.append(node)
	for child in node.get_children():
		_collect_donkeys(child, out)


func _player(root: Node) -> AnimationPlayer:
	var players := root.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


func _skeleton(root: Node) -> Skeleton3D:
	var skels := root.find_children("*", "Skeleton3D", true, false)
	return skels[0] as Skeleton3D if not skels.is_empty() else null


## Ce clip alege PathMover pentru acelasi model cu `speed` = 0. Se construieste
## un figurant SEPARAT, ca sa nu se atinga starea celui din pista.
##
## Exporturile se pun INAINTE de add_child, fiindca `_build_body` ruleaza in
## `_ready` si citeste `speed` — setat dupa, magarul s-ar construi cu viteza
## implicita (4 m/s) si ar cadea pe Walk, adica sonda ar masura altceva decat
## crede (lectia din SlidingHazard, citata si in path_mover.gd).
func _parked_animation() -> String:
	var mover: Path3D = PathMoverScript.new()
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(10.0, 0.0, 0.0))
	mover.curve = curve
	mover.model = load(DONKEY_GLB)
	mover.speed = 0.0
	add_child(mover)
	await get_tree().process_frame
	var ap := _player(mover)
	var out: String = ap.current_animation if ap != null else "(fara player)"
	mover.queue_free()
	return out


## Suma pozitiilor globale ale oaselor — amprenta ieftina a pozei scheletului
## (acelasi tipar ca la probe_cow).
func _bone_signature(skel: Skeleton3D) -> Vector3:
	var sum := Vector3.ZERO
	for i in skel.get_bone_count():
		sum += skel.get_bone_global_pose(i).origin
	return sum


## Cota celei mai joase copite in spatiul scheletului. Oasele "Shin*" se
## termina in copita, deci varful lor E talpa.
func _lowest_hoof(skel: Skeleton3D) -> float:
	var lo := 1e9
	for i in skel.get_bone_count():
		if not skel.get_bone_name(i).begins_with("Shin"):
			continue
		lo = minf(lo, skel.get_bone_global_pose(i).origin.y)
	return lo if lo < 1e8 else 0.0


func _shoot(mover: Node, tag: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var body: AnimatableBody3D = mover.body()
	if body == null:
		return
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 55.0
	cam.current = true
	# Din lateral-fata, de la inaltimea capotei: unghiul din care il vede
	# jucatorul cand trece prin Ginostra.
	var at: Vector3 = body.global_position
	cam.global_position = at + Vector3(3.2, 1.5, 3.2)
	cam.look_at(at + Vector3.UP * 0.9, Vector3.UP)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/%s.png" % [dir, tag]
	get_viewport().get_texture().get_image().save_png(out)
	print("  captura: ", out)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print("  %s %s" % ["OK      " if ok else "PROBLEMA", what])


func _finish() -> void:
	print("=== %s ===\n" % ("PROBLEME" if _failed else "TOATE OK"))
	get_tree().quit(1 if _failed else 0)
