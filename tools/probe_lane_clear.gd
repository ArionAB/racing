extends Node
## E LIBERA BANDA? Plimba gabaritul unei masini pe axul fiecarei benzi si
## raporteaza CE corp solid il atinge, pe nume.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLaneClear.tscn -- --track=6
##
## De ce exista. Pe Cappadocia toate masinile se ingramadeau la frac ~0.80 si
## cursa nu se termina. Cauza: un corp solid pe AXA benzii, in elice. Toate
## corpurile generate erau anonime (`@StaticBody3D@34`), deci a fost nevoie de o
## ora ca sa afli care din 10. Sonda asta raspunde direct, cu numele corpului —
## `_add_mesh_with_collision` le boteaza acum pe toate.
##
## Regula: un corp de SOSEA (carosabil, umeri, tablier, kicker) e legitim sub
## roti si se ignora dupa nume; orice ALTCEVA care intersecteaza cutia caroseriei
## ridicata peste asfalt e un zid in mijlocul drumului.
##
## Limite: se testeaza axa si doua fire laterale la +-1/3 din semilatime, nu
## toata banda. Nu judeca pantele — o rampa cinstita pe care o urci nu apare
## fiindca e in lista de suprafete de rulare.

## Gabaritul masinii (X lateral, Y inaltime, Z lungime) — vezi CarData.
const CAR_SIZE := Vector3(2.2, 1.4, 4.2)
## Cat se ridica centrul cutiei peste asfalt. Jumatate din inaltime plus garda
## la sol: sub atat cutia freaca insusi carosabilul si totul iese "blocat".
const LIFT: float = 1.0
## Pasul pe fractie. 0.005 pe un tur de ~2 km inseamna o proba la ~10 m.
const STEP: float = 0.005
## Corpurile pe care se RULEAZA: contactul cu ele e normal, nu blocaj.
const DRIVABLE := [
	"RoadTop", "RoadSides", "RoadOverpassDeck", "Shoulders",
	"BranchDeck", "BranchDirt", "BranchSand", "BranchRails",
	"Ramp", "ChannelKicker", "FlyoffRamp", "HummockBody",
	"IceSheet",
]


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(
				int(arg.trim_prefix("--track=")))
	if only < 0:
		push_error("ProbeLaneClear: cere --track=N")
		get_tree().quit(1)
		return

	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	print("=== %s ===" % GameState.track_label(only))
	var space := track.get_world_3d().direct_space_state
	var hits := 0
	for ri in track.routes.size():
		var r: TrackRoute = track.routes[ri]
		hits += _sweep(space, track, r)
	print("")
	if hits == 0:
		print("VERDICT: OK — banda e libera")
	else:
		print("VERDICT: PROBLEMA — %d probe blocate" % hits)
	get_tree().quit(1 if hits > 0 else 0)


func _sweep(space: PhysicsDirectSpaceState3D, track: Track,
		r: TrackRoute) -> int:
	print("")
	print("  [%s]" % r.label)
	var n := r.baked.size()
	var shape := BoxShape3D.new()
	shape.size = CAR_SIZE
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false
	var bad := 0
	var f := 0.0
	while f < 1.0:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var fwd := (r.baked[(i + 1) % n] - p)
		if fwd.length() < 0.001:
			f += STEP
			continue
		fwd = fwd.normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var half: float = track.width_at_index(i)
		for lat in [0.0, -half / 3.0, half / 3.0]:
			var basis := Basis(side, Vector3.UP, -fwd)
			q.transform = Transform3D(basis,
				p + Vector3.UP * LIFT + side * lat)
			var res := space.intersect_shape(q, 8)
			for hit in res:
				var body := hit.get("collider") as Node
				if body == null:
					continue
				var nm := String(body.name)
				if DRIVABLE.has(nm):
					continue
				print("    %.3f lat=%+.1f | %s" % [f, lat, nm])
				bad += 1
		f += STEP
	return bad
