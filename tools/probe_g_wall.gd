extends Node
## Garda POI G: decorul stancii goale NU are voie sa intre in carosabilul elicei.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeGWall.tscn
##
## [b]De ce exista.[/b] Peretele interior, firidele si coaja stau pe un INEL in
## jurul elicei, iar corectitudinea lor nu se vede din arborele de noduri:
## originile pot fi toate la raza buna (38.8) si geometria sa fie totusi peste
## sosea, daca piesa e INTOARSA. Exact asta s-a si intamplat — generatorul
## scria baza transpusa in .tscn, adica yaw-ul cu semn schimbat, si fata de
## 20 m a panourilor matura spre axa in loc sa priveasca spre ea. Masurat
## atunci: r=28.5, cu 5.5 m peste marginea asfaltului, pe banda pe care urca
## masina. `ProbeLayout` trecea verde (traseul e neatins), `ProbeBuried` la fel
## (drumul nu e ingropat), `probe_decor` la fel (materialele nu se schimba) —
## niciuna nu intreaba unde ajunge PIELEA decorului.
##
## Se masoara pe VERTECSI, nu pe AABB: cutia unui panou rotit e mult mai mare
## decat panoul si ar da alarme false (aceeasi lectie ca in memoria
## `decor-manual-coliziune`, unde gabaritul se plimba, nu se socoteste).

const AXIS := Vector2(-302.02, 6.00)
## Marginea asfaltului: elicea are raza 28 si semi-latime 6.
const ROAD_EDGE: float = 34.0
## Banda de inaltime a urcarii; sub/peste ea geometria nu mai e langa sosea.
const Y_LO: float = 12.0
const Y_HI: float = 50.0

const GROUPS := ["PereteInterior", "Ferestre", "Creasta", "Coaja"]


func _ready() -> void:
	var track: Node = (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	print("\n=== POI G — degajarea decorului fata de carosabil (prag %.1f m) ===" % ROAD_EDGE)
	var bad := 0
	for grup: String in GROUPS:
		var n: Node = track.get_node_or_null("DecorManual/G) Stanca goala/" + grup)
		if n == null:
			print("  %-16s LIPSA din arbore" % grup)
			bad += 1
			continue
		var rmin := 1e9
		var who := ""
		for child in n.get_children():
			var r := _min_radius(child)
			if r < rmin:
				rmin = r
				who = String(child.name)
		if rmin > 1e8:
			continue
		var mark := ""
		if rmin < ROAD_EDGE:
			mark = "   <<< INTRA CU %.2f m" % (ROAD_EDGE - rmin)
			bad += 1
		print("  %-16s raza minima %6.2f m   (cel mai aproape: %s)%s" % [grup, rmin, who, mark])
	if bad > 0:
		print("\nVERDICT: ESEC — %d grupuri peste carosabil" % bad)
		get_tree().quit(1)
		return
	print("\nVERDICT: OK — decorul lasa banda libera")
	get_tree().quit()


## Raza minima fata de axa a geometriei unui nod, pe vertecsi reali.
func _min_radius(root: Node) -> float:
	var rmin := 1e9
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for k in c.get_children():
			stack.append(k)
		var mi := c as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			for v in arr[Mesh.ARRAY_VERTEX] as PackedVector3Array:
				var w: Vector3 = xf * v
				if w.y < Y_LO or w.y > Y_HI:
					continue
				rmin = minf(rmin, Vector2(w.x - AXIS.x, w.z - AXIS.y).length())
	return rmin
