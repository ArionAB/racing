extends Node
## Garda pentru SlidingHazard-urile in TRAVERSARE cu model (#502, #503):
##
##   1. PLUTIRE: corpul sta pe sol pe toata cursa, inclusiv la capatul de
##      parcare de dincolo de asfalt. Pe coama Serengeti (E_Ankole1-5) cota
##      ramanea cea a drumului, iar versantul cobora sub vaca.
##   2. SENS: modelul cu "inainte" are fata pe -Z local (contractul pe care
##      Track il roteste spre directia de mers cu `face_travel`). Elefantul
##      avea trompa pe +Z si mergea cu spatele.
##
## Simuleaza fizica cat sa treaca fiecare hazard dus-intors, si la fiecare pas
## arunca o raza pe SOL (teren + sosea: doar corpuri statice, fara masini si
## fara hazard) sub originea corpului. Gap pozitiv = pluteste.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHazardGround.tscn -- --track=7
##
## --track e INDEXUL din GameState.TRACK_SCENES (Serengeti = 7) sau numarul
## scenei (14). --max-gap=M schimba pragul (implicit 0.35 m).

const SIM_SECONDS := 40.0
## Cat poate sta corpul peste sol fara sa se citeasca drept plutire. Copitele
## au o grosime si modelul nu e perfect plat dedesubt; 35 cm la o vaca de 1,4 m
## se vede ca "umbra sub copite", nu ca levitatie.
const MAX_GAP_DEFAULT := 0.35
## Cat poate intra corpul in sol (copitele in iarba, burta pe taluz) inainte sa
## se citeasca ingropat — oglinda plutirii: elefantul G_Elefant2 parca la
## capatul cursei cu malul la +2,1 m peste origine.
const MAX_SINK := 0.6

var _max_gap := MAX_GAP_DEFAULT


func _ready() -> void:
	var wanted := 7
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			wanted = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--max-gap="):
			_max_gap = float(arg.trim_prefix("--max-gap="))
	var idx := GameState.resolve_track_index(wanted)
	if idx < 0:
		push_error("ProbeHazardGround: pista invalida %d" % wanted)
		get_tree().quit(2)
		return
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(t)
	for i in 4:
		await get_tree().physics_frame

	var hazards: Array[SlidingHazard] = []
	for n in t.find_children("*", "AnimatableBody3D", true, false):
		var h := n as SlidingHazard
		if h != null and h.motion == SlidingHazard.Motion.TRAVERSARE \
				and h.model_scene != null:
			hazards.append(h)
	print("=== PROBE HAZARD GROUND — %s: %d traversari cu model ===" % [
		GameState.track_label(idx), hazards.size()])
	if hazards.is_empty():
		print("PICAT: nicio traversare cu model — sonda n-a masurat nimic")
		get_tree().quit(1)
		return

	if OS.get_cmdline_user_args().has("--profile"):
		# Profilul solului pe axa cursei: unde e sol si cat de jos, fata de
		# cota centrului (asfaltul).
		var sp := t.get_world_3d().direct_space_state
		for h in hazards:
			var line := "%s hw=%.1f A=%.1f:" % [h.name, h.road_half_width, h.travel.length()]
			for i in range(-10, 11):
				var k := float(i) / 10.0
				var p := h.center + h.travel * k
				var gy := _ground_at(sp, p, h)
				line += " %+.1f" % (gy - h.center.y) if not is_nan(gy) else " nan"
			print(line)

	var worst: Dictionary = {}   # hazard -> gap maxim (m)
	var worst_at: Dictionary = {} # hazard -> pozitia gap-ului maxim
	var lowest: Dictionary = {}   # hazard -> gap minim (negativ = ingropat)
	var samples: Dictionary = {}  # hazard -> masuratori reale
	for h in hazards:
		worst[h] = -INF
		lowest[h] = INF
		samples[h] = 0
	var space := t.get_world_3d().direct_space_state
	var steps := int(SIM_SECONDS * Engine.physics_ticks_per_second)
	for s in steps:
		await get_tree().physics_frame
		for h in hazards:
			var g := _ground_under(space, h)
			if is_nan(g):
				continue
			samples[h] = int(samples[h]) + 1
			var gap := h.global_position.y - g
			if gap > float(worst[h]):
				worst[h] = gap
				worst_at[h] = h.global_position
			lowest[h] = minf(float(lowest[h]), gap)

	var fails := 0
	for h in hazards:
		var model := String(h.model_scene.resource_path).get_file()
		var n_ok := int(samples[h])
		var verdict := "OK"
		if n_ok < steps / 2:
			verdict = "PICAT (sol negasit in %d/%d pasi)" % [steps - n_ok, steps]
			fails += 1
		elif float(worst[h]) > _max_gap:
			verdict = "PICAT (pluteste)"
			fails += 1
		elif float(lowest[h]) < -MAX_SINK:
			verdict = "PICAT (ingropat)"
			fails += 1
		var facing := _facing(h)
		if facing == "SPATE":
			verdict += " / PICAT (merge cu spatele)"
			fails += 1
		print("%-22s %-16s gap %+.2f..%+.2f m (max la %s)  sens %s  -> %s" % [
			h.name, model, float(lowest[h]), float(worst[h]),
			worst_at.get(h, Vector3.ZERO), facing, verdict])
	print("VERDICT: %s (%d esecuri, prag %.2f m)" % [
		"TRECUT" if fails == 0 else "PICAT", fails, _max_gap])
	get_tree().quit(0 if fails == 0 else 1)


## Cota solului sub origine: prima suprafata STATICA (teren, sosea, umar),
## sarind peste masini si peste orice corp mobil, inclusiv hazardul insusi.
func _ground_under(space: PhysicsDirectSpaceState3D, h: SlidingHazard) -> float:
	return _ground_at(space, h.global_position, h)


func _ground_at(space: PhysicsDirectSpaceState3D, at: Vector3, h: SlidingHazard) -> float:
	var from := at + Vector3.UP * 6.0
	var exclude: Array[RID] = [h.get_rid()]
	for attempt in 6:
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 60.0)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return NAN
		var body := hit.collider as Node
		if body is StaticBody3D and not body.has_meta("mod_coliziune"):
			return (hit.position as Vector3).y
		# masina, alt hazard sau decor (copac, stanca): nu e sol
		exclude.append(hit.rid as RID)
	return NAN


## Sensul MODELULUI fata de -Z-ul corpului: capatul cu masa joasa langa axa e
## capul (trompa / botul coborat), cel cu masa sus e crupa. Doar pentru
## modelele cunoscute cu asa ceva; restul "n/a".
func _facing(h: SlidingHazard) -> String:
	if not String(h.model_scene.resource_path).ends_with("elephant.glb"):
		return "n/a"
	# Varfurile in spatiul CORPULUI (pozitia de repaus a scheletului).
	var pts := PackedVector3Array()
	for mi in h.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := h.global_transform.affine_inverse() * m.global_transform
		for surf in m.mesh.get_surface_count():
			var verts: PackedVector3Array = m.mesh.surface_get_arrays(surf)[Mesh.ARRAY_VERTEX]
			for v in verts:
				pts.append(xf * v)
	if pts.is_empty():
		return "?"
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	# Capetele lungimii (Z): la cap, varfurile de langa axa ajung jos (trompa
	# atarna pana la sol); la crupa, cel mai jos de langa axa e coada.
	var span := hi.z - lo.z
	var axis := (hi.x - lo.x) * 0.08
	var mid_x := (hi.x + lo.x) * 0.5
	var low_front := INF # capatul -Z
	var low_back := INF  # capatul +Z
	for p in pts:
		if absf(p.x - mid_x) > axis:
			continue
		if p.z < lo.z + span * 0.12:
			low_front = minf(low_front, p.y - lo.y)
		elif p.z > hi.z - span * 0.12:
			low_back = minf(low_back, p.y - lo.y)
	if is_inf(low_front) or is_inf(low_back):
		return "?"
	return "FATA" if low_front < low_back else "SPATE"
