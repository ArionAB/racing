extends Node3D
## Umple golul folosind CAMERA ca autoritate de asezare, nu traseul.
##
## Lectia care a costat rundele: generatorul anterior a pus 96 de piese "langa
## fractiile 0.575-0.680" si ProbeInFrameE le-a gasit pe ZERO in cadrul de la
## 0.64. Distanta fata de ax nu prezice ce se vede: drumul coteste, iar camera
## sta cu 7.5 m in urma si priveste 14 m inainte, deci axa ei nu e tangenta.
##
## Deci: reconstruiesc camera de masurare la fiecare fractie, arunc raze PRIN
## PIXELII cadrului (grila peste jumatatea de jos a ecranului), si asez piesele
## exact unde razele lovesc pamantul. O piesa asezata asa e in cadru prin
## constructie.
##
## Densitatea scade cu distanta (piesele apropiate ar acoperi drumul), si se
## sare peste tot ce cade pe carosabil sau prea aproape de el.

## DEPLASATE LA INTEGRARE (+0.019..+0.015). Turul s-a lungit de la 2070 la
## 2128 m dupa serpentina lui C si S-urile lui D, deci aceleasi locuri din lume
## cad la alte fractii. Masurate pe pozitia din lume, una cate una.
const FRACS := [0.564, 0.596, 0.620, 0.652, 0.684]
## ID-urile de ext_resource din Track13.tscn. ACTUALIZATE LA INTEGRARE: la merge
## resursele s-au unit pe CALE, iar ID-urile lui POI E au fost remapate pe cele
## existente (11_chA -> 10_ch_a s.a.m.d.). Un generator ramas pe ID-urile vechi
## scrie noduri cu referinte moarte, si scena nu se mai incarca deloc.
const RES := {
	"chimney_a": "10_ch_a", "chimney_b": "11_ch_b", "chimney_c": "12_ch_c",
	"chimney_mushroom": "14_ch_mush", "chimney_triple": "15_ch_tri",
	"talus_block": "30_tblk", "talus_cobble": "31_tcob",
	"talus_gravel": "32_tgrv",
}
const ROAD_CLEAR := 13.0     # m fata de ax: nimic mai aproape


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 68.0
	cam.far = 400.0
	cam.current = true
	var vp := get_viewport().get_visible_rect().size

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var space := get_world_3d().direct_space_state
	var rand := _lcg(20260901)
	var placed: Array[Vector3] = []
	var count := 0
	var _rej_road := 0
	var _rej_dist := 0
	var _rej_gap := 0
	var _rej_rand := 0
	var _rej_miss := 0
	var _hist: Array[float] = []
	print("; --- generat de tools/gen_infill_e.gd ---")

	for f in FRACS:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		cam.global_position = focus - dir * 7.5 + Vector3.UP * 3.2
		cam.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
		await get_tree().process_frame

		# grila de raze prin cadru: jumatatea de jos (unde e pamantul), si
		# marginile laterale, care sunt exact zonele goale reclamate
		# BANDA DE PIXELI, gasita cu ProbeScanlineE, nu ghicita. Doua incercari
		# gresite inainte, amandoua pornite de la intuitia "pamantul e jos in
		# cadru":
		#   randurile 7-12/16  -> 448/450 raze respinse, median 8.5 m
		#   banda 0.435-0.60   -> 3232/3300 respinse, median 12.5 m
		# Ambele cadeau pe drumul de sub bot. Scanarea pe coloane arata ca
		# departarea (60-300 m) sta intr-o fasie INGUSTA imediat sub orizont,
		# intre 0.26 si 0.36 din inaltimea cadrului; la 0.42 esti deja la 26 m,
		# la 0.50 la 13 m. De aia grila e lata pe orizontala si subtire pe
		# verticala, exact invers decat pare natural.
		for gx in range(0, 34):
			for gy in range(0, 14):
				var sx: float = vp.x * (float(gx) + 0.5) / 34.0
				var sy: float = vp.y * (0.255 + float(gy) * 0.008)
				var from := cam.project_ray_origin(Vector2(sx, sy))
				var dirr := cam.project_ray_normal(Vector2(sx, sy))
				var q := PhysicsRayQueryParameters3D.create(
					from, from + dirr * 260.0)
				var hit := space.intersect_ray(q)
				if not hit.has("position"):
					_rej_miss += 1
					continue
				var hp: Vector3 = hit["position"]
				# RE-ASEZARE PE VERTICALA. Raza camerei loveste FATA unei pante
				# dinspre observator, dar piesa se aseaza pe coloana verticala
				# de la acel x/z — iar acolo terenul poate fi cu 20 m mai sus.
				# Fara pasul asta, ProbeFloatE a gasit piese ingropate 13-24 m
				# in dealuri (si altele iesind prin panta, care pe captura
				# citeau ca hornuri PLUTIND). Punctul de impact da doar x/z;
				# cota vine din raycast vertical.
				var col_y := _ground(space, hp)
				if is_nan(col_y):
					continue
				hp = Vector3(hp.x, col_y, hp.z)
				var dist := cam.global_position.distance_to(hp)
				_hist.append(dist)
				if dist < 26.0 or dist > 240.0:
					_rej_dist += 1
					continue
				# nu pe drum
				var off := _dist_to_route(route, hp, idx)
				if off < ROAD_CLEAR:
					_rej_road += 1
					continue
				# densitate: rarita, si fara suprapuneri
				# DENSITATE, corectata pe captura. Prima instalare a pus 149 de
				# piese si a iesit un DEPOZIT de hornuri identice pe tot
				# orizontul — mai rau decat golul, fiindca golul macar nu
				# minte. Regula devenita clara: hornul e un ACCENT, deci
				# distanta minima creste tare cu departarea (la 150 m un grup
				# la 8 m distanta se citeste lipit), si sunt permise doar
				# grupuri mici, cu goluri intre ele.
				var min_gap: float = 13.0 + dist * 0.16
				var too_close := false
				for q2 in placed:
					if q2.distance_to(hp) < min_gap:
						too_close = true
						break
				if too_close:
					_rej_gap += 1
					continue
				if rand.call() > 0.45:
					_rej_rand += 1
					continue
				placed.append(hp)
				count += 1
				# ce piesa: departe = horn (silueta pe cer), aproape = grohotis
				var model: String
				var scale: float
				if dist > 70.0 and rand.call() < 0.34:
					model = ["chimney_a", "chimney_b", "chimney_c",
						"chimney_mushroom", "chimney_triple"][int(rand.call() * 4.99)]
					# ridicat daca terenul e sub cota camerei: altfel varful nu
					# taie linia orizontului si piesa nu are silueta
					var sink: float = maxf(0.0, cam.global_position.y - 3.2 - hp.y)
					scale = 1.0 + rand.call() * 0.5 + sink * 0.06
				elif dist > 45.0 or dist > 70.0:
					model = ["talus_block", "chimney_a", "talus_cobble"][int(rand.call() * 2.99)]
					scale = 1.1 + rand.call() * 0.9
				else:
					model = ["talus_block", "talus_cobble", "talus_gravel"][int(rand.call() * 2.99)]
					scale = 1.0 + rand.call() * 0.8
				_emit("Fill%03d" % count, model,
					Vector3(hp.x, hp.y - 0.15, hp.z), rand.call() * TAU, scale)
	print("")
	print("; piese: %d" % count)
	_hist.sort()
	if not _hist.is_empty():
		print("; distante lovite: min=%.1f p25=%.1f median=%.1f p75=%.1f max=%.1f (n=%d)" % [_hist[0], _hist[_hist.size()/4], _hist[_hist.size()/2], _hist[_hist.size()*3/4], _hist[-1], _hist.size()])
	print("; respinse: fara_lovire=%d dist=%d drum=%d gap=%d random=%d" % [_rej_miss, _rej_dist, _rej_road, _rej_gap, _rej_rand])
	get_tree().quit()


## Distanta pana la sosea, dar NUMAI pe portiunea din jur.
##
## Prima varianta scana traseul INTREG si a lasat 2 piese din ~450: pista se
## intoarce pe langa ea insasi, deci aproape orice punct din bazin e "la 13 m
## de drum" — de un ALT tur al drumului, aflat la 10 m mai jos si invizibil de
## aici. Fereastra de indici e aceeasi capcana ca la pasajele pe piloni
## (memoria `pista-peste-pista`): proximitatea 2D nu inseamna acelasi drum.
## Se compara si cota, ca sa nu culeg banda de dedesubt.
func _dist_to_route(route, p: Vector3, idx: int) -> float:
	var pts: Array = route.baked
	var n: int = pts.size()
	var best := 1e9
	var _unused := n
	for k in range(-140, 141):
		var b: Vector3 = pts[route.wrap_index(idx + k)]
		if absf(b.y - p.y) > 7.0:
			continue
		best = minf(best, Vector2(b.x - p.x, b.z - p.z).length())
	return best


func _emit(node_name: String, model: String, pos: Vector3, yaw: float,
		scale: float) -> void:
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3.ONE * scale)
	print("")
	print("[node name=\"%s\" parent=\"DecorManual/Zone05_Midfield\" instance=ExtResource(\"%s\")]"
		% [node_name, RES[model]])
	print("transform = %s" % var_to_str(Transform3D(basis, pos)).replace("\n", " "))


## Cota terenului sub un punct — cu doua precautii platite in captura:
##
## 1. plecarea de sus loveste PROP-URILE deja asezate (world_prop le da corp
##    fizic), nu solul: se cere explicit doar layerul terenului;
## 2. plecarea prea joasa rateaza malul cand punctul de impact al camerei era
##    pe o fata inclinata. Se pleaca de la +6 m fata de punct, ceea ce prinde
##    buza fara sa urce pe deal.
##
## Fara (1), 16 din 48 de piese au iesit plutind cu 2-20 m — se vedeau pe
## captura la 0.64 ca hornuri suspendate in aer.
func _ground(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, p.y + 6.0, p.z), Vector3(p.x, p.y - 300.0, p.z))
	q.collide_with_areas = false
	# Se TRECE PRIN ce nu e teren, in loc sa se renunte la prima lovitura
	# straina. Cu `return NAN` pe prima piesa intalnita, orice punct de sub un
	# horn deja asezat era respins sau lasat la cota gresita — de-aia ramasesera
	# piese in aer in bazinul din dreapta dupa integrare.
	var hit := space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and guard < 24:
		var col := hit["collider"] as Node
		if col != null and String(col.name).begins_with("TerrainBody"):
			return (hit["position"] as Vector3).y
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	return NAN


func _lcg(seed_v: int) -> Callable:
	var s := [seed_v]
	return func() -> float:
		s[0] = (s[0] * 1103515245 + 12345) & 0x7FFFFFFF
		return float(s[0]) / float(0x7FFFFFFF)
