extends Node
## A DOUA ADANCIME: continut la 40-120 m, pe DREAPTA, unde sonda de cadru a
## gasit numai TerrainBody pana la 200 m.
##
## Criticul POI-ului E: "tot colorul sta in 15 m de camera, deci cadrul citeste
## TARE APROAPE, GOL DEPARTE". Masurat cu ProbeFrameE la frac 0.64: evantaiul
## din fata, pe sapte raze, loveste NUMAI teren, la 120-200 m. Nu e o impresie.
##
## Doua familii, alese fiindca fiecare aduce ce lipseste:
##  - randuri de vie: geometrie cu VERDELE ei proprie (temperatura diferita de
##    nisip) si o suprafata lenta ceruta oricum de brief;
##  - grupuri de hornuri la 60-110 m: valoare inchisa + silueta verticala, ca
##    ochiul sa aiba de ce sa se agate intre bord si creasta.
##
## Hornurile stau pe DREAPTA fiindca acolo e golul; vitele intra pe ambele
## parti, dar in fasii, nu ca un covor (un covor ar fi tot o suprafata plata).

const FRAC_FROM := 0.575
const FRAC_TO := 0.680
const RES := {
	"vine_row": "4_vine",
	"chimney_a": "11_chA",
	"chimney_b": "12_chB",
	"chimney_c": "13_chC",
	"chimney_mushroom": "15_chM",
	"talus_cobble": "31_tcob",
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
	var rand := _lcg(90210)
	var n := 0

	# --- 1. hornuri pe dreapta, la 45-115 m de ax ---
	var f := FRAC_FROM
	while f <= FRAC_TO:
		var p: Vector3 = curve.sample_baked(L * f)
		var ahead: Vector3 = curve.sample_baked(fmod(L * f + 8.0, L))
		var fwd := (ahead - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		# un grup de 2-3 hornuri, la distante diferite: grupurile citesc ca
		# formatiune, hornurile izolate citesc ca stalpi uitati
		var count := 2 + int(rand.call() * 2.0)
		for k in range(count):
			var off: float = 46.0 + rand.call() * 68.0
			var along: float = (rand.call() - 0.5) * 26.0
			var q := p + right * off + fwd * along
			var gy := _ground(space, q)
			if is_nan(gy):
				continue
			# CE A CORECTAT MASURATOAREA: dreapta nu e un mal, e o CAMPIE
			# PLATA la -10.3 m fata de sosea, dreapta pe 110 m (ProbeRightE).
			# Drumul merge pe buza unei trepte. Deci nu filtrez pe diferenta de
			# cota — asta respingea 90% din pozitii si a lasat 9 piese din
			# ~200 — ci accept campia si ridic INALTIMEA pieselor, fiindca un
			# horn de 10 m asezat cu 10 m mai jos are varful exact la nivelul
			# ochiului si dispare sub buza.
			if is_nan(gy) or (gy - p.y) > 6.0:
				continue
			var model: String = ["chimney_a", "chimney_b", "chimney_c",
				"chimney_mushroom"][int(rand.call() * 3.99)]
			n += 1
			# scara compenseaza treapta: piesele de pe campie se ridica pana
			# cand varful trece de buza si taie cerul, altfel n-au silueta.
			var sink: float = maxf(0.0, p.y - gy)
			var s_chim: float = 1.15 + rand.call() * 0.6 + sink * 0.075
			_emit("MidChim%02d" % n, model, Vector3(q.x, gy - 0.30, q.z),
				rand.call() * TAU, s_chim)
			# fiecare grup isi are grohotisul la baza: fara el hornul pare
			# infipt, cu el pare erodat DIN ceva
			for j in range(2):
				var rq := q + Vector3(
					(rand.call() - 0.5) * 7.0, 0.0, (rand.call() - 0.5) * 7.0)
				var ry := _ground(space, rq)
				if is_nan(ry):
					continue
				n += 1
				_emit("MidRub%02d" % n, "talus_cobble",
					Vector3(rq.x, ry - 0.10, rq.z), rand.call() * TAU,
					1.4 + rand.call() * 1.3)
		f += 0.012

	# --- 2. fasii de vie pe dreapta, la 22-40 m: verdele din mijlocul cadrului ---
	f = FRAC_FROM
	while f <= FRAC_TO:
		var p2: Vector3 = curve.sample_baked(L * f)
		var ahead2: Vector3 = curve.sample_baked(fmod(L * f + 8.0, L))
		var fwd2 := (ahead2 - p2).normalized()
		var right2 := fwd2.cross(Vector3.UP).normalized()
		var yaw := atan2(fwd2.x, fwd2.z)
		for k in range(3):
			var off2: float = 8.5 + float(k) * 3.6 + rand.call() * 1.4
			var q2 := p2 + right2 * off2
			var gy2 := _ground(space, q2)
			if is_nan(gy2) or absf(gy2 - p2.y) > 2.5:
				continue
			n += 1
			_emit("MidVine%02d" % n, "vine_row",
				Vector3(q2.x, gy2 - 0.15, q2.z), yaw + deg_to_rad(12.0), 1.0)
		f += 0.010
	print("")
	print("; piese: %d" % n)
	get_tree().quit()


func _emit(node_name: String, model: String, pos: Vector3, yaw: float,
		scale: float) -> void:
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3.ONE * scale)
	print("")
	print("[node name=\"%s\" parent=\"DecorManual/Zone05_Midfield\" instance=ExtResource(\"%s\")]"
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
