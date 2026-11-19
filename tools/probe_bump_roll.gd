extends Node
## Decor lovibil, valul 2: formele care se ROSTOGOLESC (`BumpProp.wrap` cu `shape`).
##
## Fara pista: trei placi (plata, panta de 3 grade, panta de 14 grade) si piese de proba puse pe
## ele, impinse la 0,5 s. Contractele:
##   1. fara `shape`, piesa ramane cutia de dinainte (forma si amortizarile neschimbate);
##   2. un butoi culcat (cilindru), impins cu 6 m/s pe plat, se ROSTOGOLESTE: se invarte cel
##      putin 12 rad si ajunge de cel putin 1,5 ori mai departe decat CONTROLUL — acelasi model
##      cu cutia de dinainte, care aluneca fara sa se invarta (sub 3 rad);
##   3. o sfera, la fel: cel putin 12 rad;
##   4. pe panta lina (3 grade) piesele rotunde se OPRESC si adorm in 10 s — nu coboara la
##      nesfarsit, treze;
##   5. pe panta abrupta (14 grade) butoiul pornit se DUCE la vale: la 6 s e inca treaz, la
##      peste 10 m;
##   6. conul e o infasuratoare convexa: sta in picioare neatins, iar lovit la varf se rastoarna
##      si adoarme.
##
## Sabotaje (fiecare trebuie sa pice):
##   --sabotage=box       piesele rotunde primesc cutia  -> pica 2 si 3
##   --sabotage=nosettle  fara rezistenta la rulare      -> pica 4
##   --sabotage=nohull    conul primeste cutia           -> pica 6
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBumpRoll.tscn [-- --sabotage=box]

const NUDGE_T: float = 0.5
const END_T: float = 12.0
const BARREL_R: float = 0.3
const BARREL_H: float = 0.9
const BALL_R: float = 0.45

var _t: float = 0.0
var _fail: int = 0
var _sabotage: String = ""
var _nudged: bool = false
## nume -> {body, start, rot, asleep_t, v, dir, at6_awake, at6_dist, dist}
var _runs: Dictionary = {}
var _mid_done: bool = false


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
	if not ok:
		_fail += 1


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotage="):
			_sabotage = arg.trim_prefix("--sabotage=")
	print("")
	print("=== FORMELE CARE SE ROSTOGOLESC (BumpProp `shape`)%s ===" % (
		"" if _sabotage.is_empty() else "  [sabotaj: %s]" % _sabotage))
	var flat := _slab(0.0, 0.0)
	var mild := _slab(3.0, 60.0)
	var steep := _slab(14.0, 120.0)
	await get_tree().physics_frame
	var round_kind := "box" if _sabotage == "box" else "cylinder"
	var ball_kind := "box" if _sabotage == "box" else "sphere"
	var cone_kind := "box" if _sabotage == "nohull" else "hull"
	# 1. implicitul neschimbat
	var plain_body := BumpProp.wrap(_barrel(flat, Vector3(-40.0, 0.0, -12.0), false))
	_check(_shape_of(plain_body) is BoxShape3D and is_equal_approx(plain_body.linear_damp, 0.3)
		and is_equal_approx(plain_body.angular_damp, 0.6),
		"fara `shape`: cutie, amortizare 0,3 / 0,6 (implicitul de dinainte)")
	var cyl_probe := BumpProp.wrap(_barrel(flat, Vector3(-40.0, 0.0, -9.0), false), {"shape": "cylinder"})
	var cs := _shape_of(cyl_probe) as CylinderShape3D
	_check(cs != null and absf(cs.radius - BARREL_R) < 0.01,
		"`cylinder`: raza %.2f m pe un butoi de %.2f m" % [cs.radius if cs != null else -1.0, BARREL_R])
	var ball_probe := BumpProp.wrap(_ball(flat, Vector3(-40.0, 0.0, -6.0)), {"shape": "sphere"})
	var bs := _shape_of(ball_probe) as SphereShape3D
	_check(bs != null and absf(bs.radius - BALL_R) < 0.01,
		"`sphere`: raza %.2f m pe o sfera de %.2f m" % [bs.radius if bs != null else -1.0, BALL_R])
	# 2-3. pe plat
	_add_run("butoi_plat", BumpProp.wrap(_barrel(flat, Vector3(-40.0, 0.0, 0.0), true), {"shape": round_kind}), flat, 6.0)
	_add_run("cutie_plat", BumpProp.wrap(_barrel(flat, Vector3(-40.0, 0.0, 6.0), true)), flat, 6.0)
	_add_run("sfera_plat", BumpProp.wrap(_ball(flat, Vector3(-40.0, 0.0, 12.0)), {"shape": ball_kind}), flat, 6.0)
	# 4. panta lina
	_add_run("butoi_3gr", BumpProp.wrap(_barrel(mild, Vector3(-40.0, 0.0, 0.0), true), {"shape": "cylinder"}), mild, 3.0)
	_add_run("sfera_3gr", BumpProp.wrap(_ball(mild, Vector3(-40.0, 0.0, 8.0)), {"shape": "sphere"}), mild, 3.0)
	if _sabotage == "nosettle":
		for k in ["butoi_3gr", "sfera_3gr"]:
			(_runs[k]["body"] as BumpProp).set("_rolls", false)
	# 5. panta abrupta
	_add_run("butoi_14gr", BumpProp.wrap(_barrel(steep, Vector3(-55.0, 0.0, 0.0), true), {"shape": "cylinder"}), steep, 3.0)
	# 6. conul
	var cone_body := BumpProp.wrap(_cone(flat, Vector3(-40.0, 0.0, 20.0)), {"shape": cone_kind})
	_check(_shape_of(cone_body) is ConvexPolygonShape3D,
		"`hull`: conul are infasuratoare convexa")
	_add_run("con_plat", cone_body, flat, 5.0)
	_add_run("con_neatins", BumpProp.wrap(_cone(flat, Vector3(-40.0, 0.0, 26.0)), {"shape": cone_kind}), flat, 0.0)


func _physics_process(delta: float) -> void:
	if not _runs.has("con_neatins"):
		return
	_t += delta
	if not _nudged:
		if _t >= NUDGE_T:
			_nudged = true
			for k in _runs:
				var r: Dictionary = _runs[k]
				var b: BumpProp = r["body"]
				r["start"] = b.global_position
				if float(r["v"]) > 0.0:
					b.sleeping = false
					if String(k).begins_with("con_"):
						# lovit la VARF (ca de o bara de protectie), nu impins din talpa
						b.apply_impulse((r["dir"] as Vector3) * float(r["v"]) * b.mass, Vector3.UP * 0.6)
					else:
						b.linear_velocity = (r["dir"] as Vector3) * float(r["v"])
		return
	var since := _t - NUDGE_T
	for k in _runs:
		var r: Dictionary = _runs[k]
		var b: BumpProp = r["body"]
		if not is_instance_valid(b):
			continue
		r["rot"] = float(r["rot"]) + b.angular_velocity.length() * delta
		if since > 0.2:
			if b.sleeping and float(r["asleep_t"]) < 0.0:
				r["asleep_t"] = since
			elif not b.sleeping:
				r["asleep_t"] = -1.0
	if not _mid_done and since >= 6.0:
		_mid_done = true
		for k in _runs:
			var r: Dictionary = _runs[k]
			var b: BumpProp = r["body"]
			r["at6_awake"] = is_instance_valid(b) and not b.sleeping
			r["at6_dist"] = b.global_position.distance_to(r["start"]) if is_instance_valid(b) else 0.0
	if since >= END_T:
		_verdict()


func _verdict() -> void:
	set_physics_process(false)
	print("  piesa          deplasare   invartire   adormita la")
	for k in _runs:
		var r: Dictionary = _runs[k]
		var b: BumpProp = r["body"]
		r["dist"] = b.global_position.distance_to(r["start"]) if is_instance_valid(b) else -1.0
		print("  %-13s  %6.2f m   %6.1f rad   %s" % [k, float(r["dist"]), float(r["rot"]),
			("%.1f s" % float(r["asleep_t"])) if float(r["asleep_t"]) >= 0.0 else "treaza"])
	print("")
	var bp: Dictionary = _runs["butoi_plat"]
	var cp: Dictionary = _runs["cutie_plat"]
	_check(float(bp["rot"]) >= 12.0 and float(bp["dist"]) >= 1.5 * float(cp["dist"]),
		"butoiul culcat se rostogoleste pe plat: %.1f rad, %.1f m fata de %.1f m cutia (cer >= 12 rad, >= 1,5x)" % [
		float(bp["rot"]), float(bp["dist"]), float(cp["dist"])])
	_check(float(cp["rot"]) <= 3.0,
		"control: acelasi model cu CUTIE aluneca fara sa se invarta: %.1f rad (cer <= 3)" % float(cp["rot"]))
	var sp: Dictionary = _runs["sfera_plat"]
	_check(float(sp["rot"]) >= 12.0,
		"sfera se rostogoleste pe plat: %.1f rad, %.1f m (cer >= 12 rad)" % [float(sp["rot"]), float(sp["dist"])])
	for k in ["butoi_3gr", "sfera_3gr"]:
		var r: Dictionary = _runs[k]
		var a := float(r["asleep_t"])
		_check(a >= 0.0 and a <= 10.0,
			"%s: se opreste pe panta lina (%s; cer adormit in <= 10 s), dupa %.1f m" % [k,
			("adormit la %.1f s" % a) if a >= 0.0 else "inca treaz la 12 s", float(r["dist"])])
	var st: Dictionary = _runs["butoi_14gr"]
	_check(bool(st["at6_awake"]) and float(st["at6_dist"]) >= 10.0,
		"butoiul pornit pe panta abrupta se duce la vale: la 6 s %s, la %.1f m (cer treaz, >= 10 m)" % [
		"treaz" if bool(st["at6_awake"]) else "adormit", float(st["at6_dist"])])
	var still: Dictionary = _runs["con_neatins"]
	_check(float(still["dist"]) <= 0.05 and (still["body"] as BumpProp).sleeping,
		"conul neatins sta pe loc, adormit: %.3f m" % float(still["dist"]))
	var cone: Dictionary = _runs["con_plat"]
	var cb: BumpProp = cone["body"]
	var tilt := rad_to_deg(acos(clampf(cb.global_transform.basis.y.normalized().dot(Vector3.UP), -1.0, 1.0)))
	var ca := float(cone["asleep_t"])
	_check(tilt >= 45.0 and ca >= 0.0,
		"conul lovit se rastoarna si adoarme: inclinat %.0f grade, %s, %.1f m" % [tilt,
		("adormit la %.1f s" % ca) if ca >= 0.0 else "inca treaz la 12 s", float(cone["dist"])])
	print("VERDICT: %s" % ("OK" if _fail == 0 else "PICAT (%d)" % _fail))
	get_tree().quit(0 if _fail == 0 else 1)


func _add_run(key: String, body: BumpProp, slab: StaticBody3D, v: float) -> void:
	_runs[key] = {"body": body, "start": body.global_position, "rot": 0.0, "asleep_t": -1.0,
		"v": v, "dir": slab.global_transform.basis.x.normalized(), "at6_awake": false,
		"at6_dist": 0.0, "dist": 0.0}


func _shape_of(body: Node) -> Shape3D:
	for c in body.get_children():
		if c is CollisionShape3D:
			return (c as CollisionShape3D).shape
	return null


## Placa de 140 x 50 m, coborand spre +X cu `deg` grade; fata de sus trece prin (0, 0, z).
func _slab(deg: float, z: float) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(140.0, 1.0, 50.0)
	cs.shape = sh
	cs.position = Vector3(0.0, -0.5, 0.0)
	b.add_child(cs)
	add_child(b)
	b.global_transform = Transform3D(Basis(Vector3.BACK, deg_to_rad(-deg)), Vector3(0.0, 0.0, z))
	return b


## Butoi (origine la talpa) pe placa, in coordonatele ei; `lying`: culcat, cu axa de-a latul pantei.
func _barrel(slab: StaticBody3D, at: Vector3, lying: bool) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = BARREL_R
	m.bottom_radius = BARREL_R
	m.height = BARREL_H
	m.radial_segments = 12
	m.rings = 1
	mi.mesh = m
	mi.position = Vector3(0.0, BARREL_H * 0.5, 0.0)
	root.add_child(mi)
	add_child(root)
	var xf := slab.global_transform
	if lying:
		# axa modelului (Y) -> Z-ul placii; centrul la o raza (+1 cm) deasupra fetei
		var local := Transform3D(Basis(Vector3.RIGHT, PI * 0.5),
			at + Vector3(0.0, BARREL_R + 0.01, -BARREL_H * 0.5))
		root.global_transform = xf * local
	else:
		root.global_transform = xf * Transform3D(Basis.IDENTITY, at)
	return root


func _ball(slab: StaticBody3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = BALL_R
	m.height = BALL_R * 2.0
	m.radial_segments = 12
	m.rings = 6
	mi.mesh = m
	mi.position = Vector3(0.0, BALL_R, 0.0)
	root.add_child(mi)
	add_child(root)
	root.global_transform = slab.global_transform * Transform3D(Basis.IDENTITY, at + Vector3(0.0, 0.01, 0.0))
	return root


func _cone(slab: StaticBody3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.03
	m.bottom_radius = 0.19
	m.height = 0.75
	m.radial_segments = 10
	m.rings = 1
	mi.mesh = m
	mi.position = Vector3(0.0, 0.375, 0.0)
	root.add_child(mi)
	add_child(root)
	root.global_transform = slab.global_transform * Transform3D(Basis.IDENTITY, at)
	return root
