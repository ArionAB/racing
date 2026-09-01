extends Node
## SILUETA hornurilor, masurata ca latime pe ecran la 7 cote pe inaltime.
##
## De ce exista (runda 16). Lead-ul a masurat pe captura si a gasit ca hornurile
## noastre nu sunt conuri, ci STICLE: latimea relativa, de sus in jos, iesea
## 0.40 0.47 0.72 0.98 0.98 0.97 1.00 — adica sare la maxim pe la 40% din
## inaltime si apoi ramane PLATA. Referinta (`B_chimneys.png`) are corturi
## conice cu laturi aproape drepte, deci profil ~liniar de la varf la baza.
##
## Sonda masoara pe MESH-UL VIU, dupa `ChimneyShape._deform` si dupa `_add_extras`
## (taluz, bolovani), fiindca acolo se decide silueta — nu in GLB si nu in
## profilul analitic din generatorul Blender. Proiectia e cea a camerei de
## livrare (`--driver`, MEASURE_* din snapshot.gd), deci cifra e comparabila
## direct cu ce a citit lead-ul de pe poza.
##
## Cheia de citire: `raport` = latime(cota) / latime(baza), tiparita de la VARF
## spre BAZA, ca la lead. Tinta rundei 16: ~0.25 0.38 0.50 0.62 0.75 0.88 1.00,
## fara palier.
##
## Rulare:
##   godot --headless --path . res://tools/ProbeCappSilueta.tscn -- --frac=0.06

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2
const VIEW: Vector2 = Vector2(1280.0, 720.0)
## Cate hornuri se raporteaza, in ordinea apropierii de camera.
const TOP: int = 5
## Esantioane pe inaltime. 7 ca la lead; palaria se exclude separat.
const SAMPLES: int = 7


func _ready() -> void:
	var frac := 0.06
	var cap_from_default := 0.77
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))

	await get_tree().process_frame
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	var look := focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = MEASURE_FOV
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	# Viewport-ul sondei nu are rezolutia capturii; latimile se normalizeaza
	# oricum la baza, dar raportul de aspect conteaza pentru proiectie.
	get_viewport().size = Vector2i(VIEW)
	await get_tree().process_frame

	print("EYE ", eye.snappedf(0.01), "  frac ", frac)
	print("--- silueta, latime relativa la baza, de la VARF spre BAZA ---")

	var found: Array = []
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd.get_script() == null:
			continue
		if not (nd is Node3D):
			continue
		# doar nodurile cu ChimneyShape: au proprietatea `cap_from`
		if nd.get("cap_from") == null:
			continue
		var pr := nd as Node3D
		var d := eye.distance_to(pr.global_position)
		if d > 90.0:
			continue
		found.append([d, pr])
	found.sort_custom(func(a, b): return a[0] < b[0])

	var shown := 0
	for e in found:
		if shown >= TOP:
			break
		var pr: Node3D = e[1]
		var d: float = e[0]
		var res := _profile_of(pr, cam)
		if res.is_empty():
			continue
		shown += 1
		var line := ""
		for r in res["ratios"]:
			line += "%.2f  " % r
		print("%-16s d=%5.1f  H=%5.1f m  gat_la=%.2f" % [
			pr.name, d, res["h"], float(pr.get("cap_from"))])
		print("    %s" % line)
		print("    liniaritate: abatere max de la rampa = %.3f" % res["dev"])
	if shown == 0:
		print("NICIUN horn in raza de 90 m — verifica fractia")
	get_tree().quit(0)


## Raza corpului la `SAMPLES` cote, in spatiul LUMII, ca fractie din raza bazei.
##
## De ce raza si nu latimea pe ecran. Prima versiune a sondei proiecta vertecsii
## prin camera si masura latimea in pixeli — si a iesit gunoi pe hornurile
## apropiate: la 13 m un con de 18 m are varful in afara cadrului, benzile de
## sus ies goale si raportul devine 0.00. Silueta unui corp aproape de revolutie
## E raza; proiectia doar o scaleaza cu 1/distanta, deci raportul la baza e
## acelasi. Camera ramane in sonda doar ca sa aleaga CARE hornuri se masoara —
## alea din cadrul de livrare.
##
## PALARIA SE EXCLUDE (cota peste `cap_from`): e prin definitie mai lata decat
## gatul si ar ascunde exact gatuirea pe care o cautam. La fel taluzul, care e o
## suprafata separata adaugata de `_add_extras` — largeste poala INTENTIONAT si
## nu e parte din conul propriu-zis; se sare peste ultimele suprafete daca
## `talus_spread` e nenul.
func _profile_of(pr: Node3D, _cam: Camera3D) -> Dictionary:
	var mis: Array[MeshInstance3D] = []
	var stack: Array[Node] = [pr]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd is MeshInstance3D and (nd as MeshInstance3D).mesh != null:
			mis.append(nd as MeshInstance3D)
	if mis.is_empty():
		return {}

	# TOATE suprafetele, poala de grohotis inclusa — si asta e chiar corectia
	# rundei 16. Prima versiune citea doar suprafata 0 (corpul de tuf), pe
	# motiv ca taluzul "nu e parte din con". Masuratoarea a aratat ca motivul e
	# gresit: pe corpul singur profilul iesea deja aproape liniar SI PE
	# BASELINE (abatere 0.047 pe hornSoare5), deci nu acolo era sticla pe care
	# a vazut-o lead-ul. Ochiul si captura nu vad suprafete, vad SILUETA — iar
	# poala e in silueta. Cu `talus_spread` pana la 0.58 si armonicile din
	# `_build_talus` (wob pana la 1.44, lobe pana la 1.22), raza exterioara a
	# poalei ajunge la ~1.9x raza bazei conului: exact umflatura de jos care
	# face pearul.
	#
	# `--corp` masoara doar suprafata 0, pentru cand vrei sa separi conul de
	# poala lui.
	var body_only := false
	for a in OS.get_cmdline_user_args():
		if a == "--corp":
			body_only = true
	var pts: Array[Vector3] = []
	for mi in mis:
		var xf := mi.global_transform
		var m := mi.mesh
		for sfc in m.get_surface_count():
			if body_only and sfc > 0:
				break
			var arrays := m.surface_get_arrays(sfc)
			var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in vs:
				pts.append(xf * v)
	if pts.size() < 8:
		return {}

	var ymin := INF
	var ymax := -INF
	var cx := 0.0
	var cz := 0.0
	for p in pts:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var h := ymax - ymin
	if h < 1.0:
		return {}
	# Axa: centrul feliei de la BAZA, nu media pe tot corpul — hornurile sunt
	# inclinate (`lean_deg`), deci media ar fi tras axa in lateral si ar fi
	# umflat razele de jos.
	var nb := 0
	for p in pts:
		if (p.y - ymin) / h < 0.10:
			cx += p.x
			cz += p.z
			nb += 1
	if nb < 3:
		return {}
	cx /= float(nb)
	cz /= float(nb)

	var cap_from := float(pr.get("cap_from"))
	var top_t: float = clampf(cap_from, 0.4, 0.95)

	# Raza MEDIANA pe INELE de cota, apoi interpolare la cele 7 esantioane.
	#
	# Binarea directa pe 7 benzi da goluri: hornurile au 17-35 de inele, deci o
	# banda din sapte poate ramane fara vertecsi si iese 0.00 in mijlocul
	# profilului — prima versiune a sondei a raportat exact asa si cifra parea
	# un gat inexistent. Mediana si nu maxim: canelurile verticale fac raza sa
	# oscileze pe azimut cu peste 10%, iar maximul citeste doar creasta lor.
	var by_y := {}
	for p in pts:
		var t := (p.y - ymin) / h
		if t > top_t:
			continue
		var key := snappedf(t, 0.004)
		if not by_y.has(key):
			by_y[key] = PackedFloat32Array()
		var dx := p.x - cx
		var dz := p.z - cz
		by_y[key].append(sqrt(dx * dx + dz * dz))
	var ys: Array = by_y.keys()
	ys.sort()
	if ys.size() < 3:
		return {}
	var rings: Array = []
	for y in ys:
		var lst := Array(by_y[y])
		lst.sort()
		rings.append([float(y), float(lst[lst.size() / 2])])

	var w := PackedFloat32Array()
	for i in SAMPLES:
		var t: float = top_t * float(i) / float(SAMPLES - 1)
		var r: float = float(rings[0][1])
		for j in range(rings.size() - 1):
			var a: Array = rings[j]
			var b: Array = rings[j + 1]
			if a[0] <= t and t <= b[0]:
				var u: float = 0.0 if b[0] <= a[0] else (t - a[0]) / (b[0] - a[0])
				r = lerpf(float(a[1]), float(b[1]), u)
				break
			if t > float(rings[rings.size() - 1][0]):
				r = float(rings[rings.size() - 1][1])
		w.append(r)
	var base := w[0]
	if base <= 0.0:
		return {}
	# de la VARF spre BAZA, ca la lead
	var ratios: Array[float] = []
	for i in range(SAMPLES - 1, -1, -1):
		ratios.append(w[i] / base)

	# Abaterea de la rampa ideala 1/N .. 1 (ratios[0] e varful).
	var dev := 0.0
	for i in SAMPLES:
		var ideal := float(i + 1) / float(SAMPLES)
		dev = maxf(dev, absf(ratios[i] - ideal))
	return {"ratios": ratios, "h": h, "dev": dev}
