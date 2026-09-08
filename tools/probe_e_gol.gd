extends Node
## Unde e banda GOALA de pe taluzul craterului (POI E, runda 4)?
##
## Dupa ce ceata a iesit de peste bol (fog_begin 190), randurile 0.20-0.30 din
## cadrul hero raman crem gol: taluz de nisip fara nimic pe el, unde referinta
## are stanca gri si coroane verzi dese. Sonda trage raze prin acele randuri si
## scrie PUNCTUL DE LUME lovit, ca prop-urile sa fie asezate pe pozitii reale,
## nu ghicite.

const CAM_DIST: float = 12.5
const CAM_HEIGHT: float = 10.0
const CAM_FOV: float = 68.0

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var i := int(0.40 * float(n)) % n
	var p: Vector3 = r.baked[i]
	var pf: Vector3 = r.baked[(i + 12) % n]
	var fwd := (pf - p)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var eye := p - fwd * CAM_DIST + Vector3(0, CAM_HEIGHT, 0)
	var cam := Camera3D.new()
	get_tree().root.add_child(cam)
	cam.fov = CAM_FOV
	cam.global_position = eye
	cam.look_at(p + fwd * 14.0 + Vector3(0, 1.2, 0), Vector3.UP)
	var smp: TrackSideSampler = track._sampler
	for ry in [0.18, 0.22, 0.26, 0.30, 0.34, 0.40]:
		var line := "rand %.2f:" % ry
		for rx in [0.60, 0.70, 0.80, 0.90]:
			var sp := Vector2(rx * 1280.0, ry * 720.0)
			var o := cam.project_ray_origin(sp)
			var d := cam.project_ray_normal(sp)
			# Raycast NU merge aici: panza craterului n-are corp fizic la
			# distanta (memoria `coliziune-none-e-fantoma-nu-stearsa`), deci
			# toate razele ies "--". Se intersecteaza analitic cu inaltimea de
			# teren: pas mic pe raza, pana cand raza trece sub sol.
			var w := Vector3.ZERO
			var got := false
			var t := 5.0
			while t < 900.0:
				var q2 := o + d * t
				var gy: float = smp.ground_y(q2.x, q2.z)
				if q2.y <= gy:
					w = Vector3(q2.x, gy, q2.z)
					got = true
					break
				t += 2.0
			if not got:
				line += "  x%.2f:--" % rx
			else:
				line += "  x%.2f:(%.0f,%.0f,%.0f)@%.0fm" % [rx, w.x, w.y, w.z,
					o.distance_to(w)]
		print(line)
	get_tree().quit(0)
