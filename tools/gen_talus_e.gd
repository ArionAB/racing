extends Node
## Conul de grohotis care INGROAPA talpa malului din stanga, pe 0.56-0.66.
##
## Verdictul rundei 2: "talpa peretelui e o curba desenata cu rigla ... lasa-l
## sa INGROAPE imbinarea, ca linia solului sa nu se mai vada ca o curba
## continua." Deci regulile de asezare, in ordinea importantei:
##
##  1. piesele stau CALARE pe linia de imbinare (masurata cu raycast, nu
##     desenata), nu aliniate langa ea — de-aia `across` merge si sub, si peste
##     picior. O piatra langa imbinare lasa imbinarea vizibila.
##  2. gradient de marime: blocuri de ~1.6 m jos, pietris pe acostament.
##  3. densitate mai mare exact pe imbinare, rarita spre drum: un con real e
##     dens la baza peretelui si se stinge in nisip.
##
## Iese pe stdout un fragment de .tscn (memoria `decor-manual-din-cod`).

const FRAC_FROM := 0.545
const FRAC_TO := 0.670
const STEP := 0.0045

const RES := {
	"talus_block": "30_tblk",
	"talus_cobble": "31_tcob",
	"talus_gravel": "32_tgrv",
}


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var curve := track.get_node("Path").curve as Curve3D
	var L := curve.get_baked_length()
	var space := track.get_world_3d().direct_space_state
	var rand := _lcg(4711)
	var n := 0
	print("; --- generat de tools/gen_talus_e.gd, nu edita de mana ---")
	var f := FRAC_FROM
	while f <= FRAC_TO:
		var p: Vector3 = curve.sample_baked(L * f)
		var ahead: Vector3 = curve.sample_baked(fmod(L * f + 8.0, L))
		var fwd := (ahead - p).normalized()
		var left := -fwd.cross(Vector3.UP).normalized()
		# piciorul pantei pe perpendiculara, la fel ca ProbeBankE
		var toe := -1.0
		var d := 8.0
		while d <= 60.0:
			var y := _ground(space, p + left * d)
			if not is_nan(y) and (y - p.y) > 2.5:
				toe = d
				break
			d += 1.5
		if toe < 0.0:
			f += STEP
			continue
		# 5 piese pe sectiune, CALARE pe imbinare: doua sub picior (spre drum),
		# una fix pe el, doua peste (pe panta). Marimea scade spre drum.
		for k in range(5):
			var across: float = toe + [-7.0, -3.4, 0.0, 2.6, 5.2][k]
			across += (rand.call() - 0.5) * 2.2
			var along: float = (rand.call() - 0.5) * 5.0
			var q := p + left * across + fwd * along
			var gy := _ground(space, q)
			if is_nan(gy):
				continue
			var model: String = ["talus_gravel", "talus_gravel", "talus_block",
				"talus_block", "talus_cobble"][k]
			# scara: mare pe imbinare si deasupra, mic spre drum
			var s: float = [0.85, 1.05, 1.15, 0.95, 0.80][k] * (0.80 + rand.call() * 0.45)
			n += 1
			_emit("TalusE%02d" % n, model, Vector3(q.x, gy - 0.12, q.z),
				rand.call() * TAU, s)
		f += STEP
	print("")
	print("; piese: %d" % n)
	get_tree().quit()


func _emit(node_name: String, model: String, pos: Vector3, yaw: float,
		scale: float) -> void:
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3.ONE * scale)
	print("")
	print("[node name=\"%s\" parent=\"DecorManual/Zone05_Talus\" instance=ExtResource(\"%s\")]"
		% [node_name, RES[model]])
	print("transform = %s" % var_to_str(Transform3D(basis, pos)).replace("\n", " "))


func _ground(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 300.0, p.z), Vector3(p.x, -60.0, p.z))
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if hit.has("position") else NAN


func _lcg(seed_v: int) -> Callable:
	var s := [seed_v]
	return func() -> float:
		s[0] = (s[0] * 1103515245 + 12345) & 0x7FFFFFFF
		return float(s[0]) / float(0x7FFFFFFF)
