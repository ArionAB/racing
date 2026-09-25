extends SceneTree
## Orientarea hazardelor fata de drum: unghiul dintre local -Z al fiecarui
## nod din `Hazarduri` (si din `DecorManual`, optional) si tangenta curbei
## in punctul cel mai apropiat, plus offsetul lateral.
##
##   godot --headless --path . --script res://tools/sv_hazard_orient.gd -- --scene=16 [--decor]
##
## De ce exista: pe 25 sep 2026 toate cele 6 perdele din Track16 aveau
## 50-107 grade fata de drum (transform scris pe coloane in loc de randuri,
## memoria tscn-transform-e-pe-randuri) si nimeni n-a masurat unghiul timp de
## 5 zile — ProbeRace era verde fiindca o perdea rotita e doar o fasie de
## 6 m. Se ruleaza dupa ORICE montare de hazard sau piesa cu axa.
## Conventii: perdele/ploaie/torent = local -Z pe drum (0 grade);
## semafor/kicker = local +Z pe drum (180 grade); avalansa e orientata din
## cod (unghiul ei nu conteaza). Orice altceva intre 20 si 160 de grade e
## suspect si se explica in raport.
##
## RUNDA 1 POI D (Fiordland): `--decor` cere si scatter organic (fagi,
## bolovani, ferigi, tussock) cu YAW ALEATOR intentionat -- memoria
## aranjamentul-bate-numarul: un yaw aliniat pe drum ar citi "instante
## plasate", nu padure. Un fag cu yaw aleator NU e o axa montata gresit, e
## decizia de compozitie. Fara exceptie, sonda ar cere fie 0 piese organice,
## fie yaw fortat (0/180), amandoua gresite. Prefixele de mai jos sunt
## piese FARA axa vizuala/functionala semnificativa (spre deosebire de o
## perdea sau un semafor, unde directia CONTEAZA) -- acelasi principiu ca
## AvalansaF/traffic_light_pole, doar numit explicit in loc de tacut.
const YAW_FREE_PREFIXES: Array[String] = [
	"fagApropiat", "fagEtaj2", "fagFund", "fagIntrare", "fagIesire",
	"muschiBolovan", "feriga", "ferigaMica", "reperMargine", "tufaIarba",
	"marmita", "marmitaMal", "kea", "stumpKea",
	# RUNDA 2 POI D: ansamblul de canion la pod (_bridge_canyon_dressing),
	# aceleasi piese fara axa functionala (chasm_rock/moss_boulder), acelasi
	# motiv ca marmita/muschiBolovan mai sus.
	"canionTreapta", "canionTreaptaMica", "canionMuschi",
	# RUNDA 1 POI G (Bowen): perete/bazin cascada + padure de mal, acelasi
	# principiu — bolovani/muschi/fagi cu yaw aleator intentionat
	# (aranjamentul-bate-numarul), fara axa vizuala semnificativa.
	"poolWall", "poolMoss", "gravelEdge", "poolDrift", "bankForest", "bankUnder",
]
static func _yaw_free(name: String) -> bool:
	for prefix in YAW_FREE_PREFIXES:
		if name.begins_with(prefix):
			return true
	return false

func _init() -> void:
	var scene := 16
	var decor := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = int(a.trim_prefix("--scene="))
		elif a == "--decor":
			decor = true
	var path := "res://scenes/tracks/Track%02d.tscn" % scene
	var ps := load(path) as PackedScene
	if ps == null:
		print("LIPSA ", path)
		quit(1)
		return
	var root := ps.instantiate()
	# Toate curbele scenei: traseul (`Path`) si benzile (`TrackBranch`,
	# ex. ScurtaturaChasm). Fiecare nod se masoara fata de CEA MAI APROPIATA.
	var curves: Array = []
	for c in root.get_children():
		if c is Path3D and (c as Path3D).curve != null and (c as Path3D).curve.get_baked_length() > 0.0:
			curves.append(c)
	var nodes: Array = []
	if root.has_node("Hazarduri"):
		for c in root.get_node("Hazarduri").get_children():
			nodes.append(c)
	if decor and root.has_node("DecorManual"):
		for z in root.get_node("DecorManual").get_children():
			for c in z.get_children():
				nodes.append(c)
	print("%-32s %6s %8s %8s" % ["nod", "frac", "unghi", "lateral"])
	var suspect := 0
	for c in nodes:
		if not (c is Node3D):
			continue
		var n := c as Node3D
		var best: Path3D = null
		var best_d := INF
		var best_o := 0.0
		for pc in curves:
			var pth := pc as Path3D
			var lp := n.position - pth.position
			var oo := pth.curve.get_closest_offset(lp)
			var d := pth.curve.sample_baked(oo).distance_to(lp)
			if d < best_d:
				best_d = d
				best = pth
				best_o = oo
		var curve := best.curve
		var L := curve.get_baked_length()
		var p := curve.sample_baked(best_o) + best.position
		var fwd := (curve.sample_baked(fmod(best_o + 2.0, L)) - curve.sample_baked(best_o)).normalized()
		var ang := rad_to_deg(acos(clampf((-n.transform.basis.z).dot(fwd), -1.0, 1.0)))
		var lat := (n.position - p).dot(fwd.cross(Vector3.UP))
		var flag := ""
		if ang > 20.0 and ang < 160.0:
			if _yaw_free(str(n.name)):
				flag = "  (yaw liber, decor organic)"
			else:
				flag = "  <-- suspect"
				suspect += 1
		var tag := "" if best.name == "Path" else " [%s]" % best.name
		print("%-32s %6.3f %8.1f %8.2f%s%s" % [n.name, best_o / L, ang, lat, tag, flag])
	print("VERDICT: %d noduri cu orientare suspecta (20-160 grade)" % suspect)
	root.free()
	quit()
