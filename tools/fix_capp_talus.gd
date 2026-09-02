extends Node
## SCOATE GROHOTISUL DIN BANDA, in `Track13.tscn`, o singura data.
##
##   godot --headless --path . res://tools/FixCappTalus.tscn
##   ... -- --dry     (doar raporteaza, nu scrie)
##
## [b]De ce o unealta si nu o regenerare.[/b] Bug-ul e in generatoarele
## `gen_decor_capp_f.gd` / `gen_capp_f_gat.gd` si acolo a si fost reparat — dar
## nodurile lor au fost editate de mana DUPA generare (peretii salii facuti
## fantome, 93 de piese plutitoare reasezate). O regenerare ar fi corecta pentru
## grohotis si ar sterge exact munca aia. Vezi memoria
## `decor-manual-sursa-de-adevar` si `tscn-editat-de-mana-nu-se-rescrie`:
## `.tscn`-ul e sursa de adevar pe toata dezvoltarea, deci se retuseaza EL,
## chirurgical, si generatorul ramane reparat pentru data viitoare.
##
## [b]Ce face, exact.[/b] Pentru fiecare nod `grohotis*` din grupurile
## subteranului: afla indexul de traseu cel mai apropiat, semilatimea benzii
## acolo, si cat de adanc intra GABARITUL piesei (AABB rotit, in lume) peste
## marginea benzii. Daca intra si daca piesa ajunge peste raza rotii (0.30 m),
## il impinge lateral, spre exterior, exact cat trebuie ca sa iasa — plus o
## garda de `CLEAR_M`. Nu il sterge, nu il roteste, nu il scaleaza: un con de
## grohotis retras cu un metru e tot un con de grohotis, pe cand 619 piese
## sterse ar fi lasat muchia de imbinare descoperita, adica exact ce a cerut
## conul.
##
## Se masoara pe GABARIT, nu pe origine: originea unui bloc de 3,2 x 1,5 m cu
## yaw aleator poate sta cuminte langa margine cu corpul intrat 2 m in drum.
## Aia a fost si greseala din generator.

## Grupurile de decor ale subteranului.
const GROUPS: Array[String] = ["F1_Gura", "F2_Sala1", "F3_Gat", "F4_Sala2"]
## Sub atat se trece peste piesa, nu te opreste (raza rotii — vezi memoria
## `suprafete-cu-goluri-si-praguri`).
const WHEEL_R: float = 0.30
## Garda peste marginea benzii, dupa retragere.
const CLEAR_M: float = 0.15
const SCENE_PATH: String = "res://scenes/tracks/Track13.tscn"

var _dry: bool = false


func _ready() -> void:
	await get_tree().process_frame
	_dry = "--dry" in OS.get_cmdline_user_args()
	var scene := load(SCENE_PATH) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]

	# Deplasarile se CALCULEAZA pe pista construita (unde exista latimea reala
	# si terenul), dar se SCRIU in textul .tscn, pe nume de nod: scena
	# instantiata contine si tot ce a generat codul, si aia n-are ce cauta in
	# fisier.
	var shift: Dictionary = {}
	var deepest := 0.0
	for grp in GROUPS:
		var holder := track.find_child(grp, true, false)
		if holder == null:
			push_error("nu gasesc grupul %s" % grp)
			continue
		var moved := 0
		for ch in holder.get_children():
			var nm := String(ch.name)
			if not nm.begins_with("grohotis"):
				continue
			var node := ch as Node3D
			if node == null:
				continue
			var i := r.closest_index_global(node.global_position)
			var hw: float = track.width_at_index(i)
			var side := r.side_at(i)
			var base: Vector3 = r.baked[i]
			var inner := 1e9
			var top := -1e9
			for mi in node.find_children("*", "MeshInstance3D", true, false):
				var m := mi as MeshInstance3D
				if m == null or m.mesh == null:
					continue
				var ab: AABB = m.mesh.get_aabb()
				for k in 8:
					var corner: Vector3 = m.global_transform * (ab.position
						+ Vector3(ab.size.x * float(k & 1),
							ab.size.y * float((k >> 1) & 1),
							ab.size.z * float((k >> 2) & 1)))
					inner = minf(inner, absf(side.dot(corner - base)))
					top = maxf(top, corner.y)
			if inner >= hw or top - base.y <= WHEEL_R:
				continue
			var push := hw - inner + CLEAR_M
			deepest = maxf(deepest, hw - inner)
			# Spre EXTERIOR inseamna in sensul in care sta piesa acum fata de
			# ax — un bloc de pe stanga se retrage la stanga.
			var sgn := signf(side.dot(node.global_position - base))
			if is_zero_approx(sgn):
				sgn = 1.0
			shift[nm] = side * push * sgn
			moved += 1
		print("  %-10s %d piese retrase" % [grp, moved])

	print("cel mai adanc bloc intra %.2f m in banda" % deepest)
	if shift.is_empty():
		print("VERDICT: nimic de mutat.")
		get_tree().quit(0)
		return
	if _dry:
		print("VERDICT (dry): %d noduri ar fi mutate." % shift.size())
		get_tree().quit(0)
		return
	_rewrite(shift)
	get_tree().quit(0)


## Rescrie DOAR randul `transform = ...` al nodurilor din dictionar.
##
## Se lucreaza pe text si pe nume de nod, nu prin `PackedScene.pack()`: un pack
## ar rescrie tot fisierul, ar pierde ordinea si comentariile, si ar coace in el
## tot ce a generat codul la `_ready`. Retusul trebuie sa se vada in `git diff`
## ca 619 randuri schimbate, nu ca un fisier nou.
func _rewrite(shift: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var lines := text.split("\n")
	var out := PackedStringArray()
	var current := ""
	var done := 0
	for line in lines:
		if line.begins_with("[node name=\""):
			var q := line.find("\"", 12)
			current = line.substr(12, q - 12)
		if line.begins_with("transform = Transform3D(") and shift.has(current):
			var body := line.substr(24, line.length() - 25)
			var parts := body.split(",")
			if parts.size() == 12:
				var d: Vector3 = shift[current]
				for k in 3:
					parts[9 + k] = " %.6f" % (float(parts[9 + k])
						+ (d.x if k == 0 else (d.y if k == 1 else d.z)))
				out.append("transform = Transform3D(%s)" % ",".join(parts))
				done += 1
				continue
		out.append(line)
	var w := FileAccess.open(path, FileAccess.WRITE)
	w.store_string("\n".join(out))
	w.close()
	print("VERDICT: %d noduri mutate din %d cerute." % [done, shift.size()])
