extends Node
## BUZELE: cum arata terenul CHIAR la capetele tablierului, si ce se vede din
## ochiul soferului cand vine spre pod. Cifrele lui SvMpE2 arata podea plata
## la -40.30 pe 100 x 50 m si pereti in RAMPA (20 m pe 32 m = 32 grade).
## Bara are o CRAPATURA cu pereti verticali. Aici se masoara exact cat de
## departe de capatul tablierului incepe racordul, ca sa stiu unde pun piatra.
const TRACK := "res://scenes/tracks/Track15.tscn"

var _t: Track
var _rid: RID = RID()
var _sus := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	for i in 5:
		await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	for c in _t.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	# Capetele tablierului: near (31, -20, -155), far (-3, -20, -155).
	print("; A. BUZA DE PLECARE (near, x=31): profil fin pe X la z=-155")
	var x := 40.0
	while x >= 22.0:
		print(";   x=%6.2f  sol %+8.2f  (tablier -20.00, delta %+7.2f)" % [
			x, _sol(x, -155.0), _sol(x, -155.0) + 20.0])
		x -= 1.0
	print("; B. BUZA DE SOSIRE (far, x=-3): profil fin pe X la z=-155")
	x = 0.0
	while x >= -34.0:
		print(";   x=%6.2f  sol %+8.2f  (delta %+7.2f)" % [
			x, _sol(x, -155.0), _sol(x, -155.0) + 20.0])
		x -= 2.0
	print("; C. UNGHIUL PERETILOR gaurii, pe fiecare directie de la mijloc (14,-155):")
	for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1),
			Vector2(0, -1), Vector2(0.7, 0.7), Vector2(0.7, -0.7)]:
		var line := ";   dir (%+.1f,%+.1f):" % [dir.x, dir.y]
		var prev := -40.30
		var prev_d := 0.0
		for d: float in [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0]:
			var p := Vector2(14.0, -155.0) + dir * d
			var g := _sol(p.x, p.y)
			var ang := rad_to_deg(atan2(g - prev, d - prev_d))
			line += " %.0fm:%+.1f(%.0fd)" % [d, g, ang]
			prev = g
			prev_d = d
		print(line)
	print("; D. CE SE VEDE DIN MASINA la intrarea pe pod: ochi la (36,-18.5,-155),")
	print(";    privind spre -X. Unghiul sub orizontala pana la podea, pe distanta:")
	for d: float in [5.0, 10.0, 15.0, 20.0, 25.0, 34.0, 45.0, 60.0]:
		var g := _sol(36.0 - d, -155.0)
		print(";   la %5.1f m in fata: sol %+7.2f, unghi sub orizontala %5.1f deg" % [
			d, g, rad_to_deg(atan2(-18.5 - g, d))])
	get_tree().quit(0)


func _sol(x: float, z: float) -> float:
	var space := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, _sus - 1400.0, z))
	q.collide_with_areas = false
	q.exclude = []
	var hit: Dictionary = space.intersect_ray(q)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 48:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		g += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return -999.0
