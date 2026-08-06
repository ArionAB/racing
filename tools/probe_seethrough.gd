extends Node
## Cati pixeli dintr-un cadru de joc se vad PRIN geometrie.
##
##   godot --path . res://tools/ProbeSeeThrough.tscn -- --track=0
##   ... --save    scrie si pozele, in snapshots/, pentru cine vrea sa se uite
##
## Ruleaza CU FEREASTRA: fara randare nu exista pixeli de numarat.
##
## ############################################################################
## CUM MASOARA, si de ce metrica asta si nu alta.
##
## Acelasi cadru se randeaza de doua ori: o data normal si o data cu backface
## culling STINS pe toate materialele. Ce se schimba intre poze e, prin
## definitie, geometrie pe care in mod normal o vezi pe dos sau prin ea —
## fiindca singura diferenta e daca fetele intoarse de la camera se deseneaza
## sau nu. Pe o lume construita din solide inchise, diferenta trebuie sa fie
## aproape zero.
##
## De ce era nevoie de o masuratoare in PIXELI si nu de una pe mesh-uri:
## `probe_watertight.gd` verifica assets-urile, dar ultimele doua cazuri reale
## n-au avut nimic cu assets-ul.
##   - Sectiunile de faleza oglindite (`scale.x = -1`) si-au pierdut fata
##     dinspre sofer cand decorul a intrat in MultiMesh: mesh etans, pozitie
##     corecta, doar sensul fetelor gresit dupa coacere (vezi nota din
##     TrackDecorBatch). Pe Dunele asta insemna 51.048 de pixeli din cadru —
##     5,5% din ecran — prin care se vedea interiorul peretelui.
##   - Rocile din MegaKit veneau rupte de la decimare (vezi
##     `_weld` din build_megakit_rocks.py).
## Prima nu se vede in niciun fisier de asset, a doua nu se vede in niciun cod.
## Cadrul le prinde pe amandoua, fiindca masoara ce ajunge pe ecran.
##
## CE MAI PRINDE METRICA PE LANGA GAURI, si de ce pragurile nu sunt zero.
## Doua suprafete COPLANARE se bat pe adancime, iar cu culling stins intra in
## bataie si fetele din spate, deci castigatorul se schimba si pixelii difera
## fara sa fie vorba de vreo gaura. Pe Okinawa asta e aproape tot ce se
## masoara: petele de apa adanca si benzile de spuma sunt placi plate asezate
## peste suprafata marii. E tot un defect vizual, dar ALTUL, si nu se repara de
## unde se repara gaurile — de aceea sta scris in prag, nu ascuns intr-o medie.
##
## Pragurile de mai jos sunt MASURATE, in aceeasi logica cu `TRIS_OVERRIDE` din
## probe_decor.gd: valoarea de azi plus marja, ca sa prinda regresia, nu un
## numar ales din teorie. Ce inseamna fiecare, la data scrierii:
##   Dunele 1.769 — capul unui stalp de marcaj care se vede pe dinauntru
##   Stramtoarea 1.117 — acelasi tip de rest, pe prop-uri marunte
##   Okinawa 103.171 / v2 18.136 / manual 17.953 — placile de apa, coplanare
## Pentru scara: inainte de reparatia din TrackDecorBatch, Dunele masura
## 147.222 de pixeli — 16% din ecran — din sectiuni de canion oglindite care
## isi pierdusera fata la coacerea in multimesh.
## ############################################################################

## Pragul implicit, pentru o pista fara datorie masurata.
const FAIL_PX: int = 3000
## Praguri proprii, acolo unde se stie ce se numara (vezi antetul).
const FAIL_OVERRIDE := {
	"Okinawa": 130000,
	"Okinawa v2": 25000,
	"Okinawa manual": 25000,
}
## Cat de mult trebuie sa difere un pixel ca sa-l numaram. Sub atat sunt
## diferente de banding/dither, nu geometrie.
const CHANNEL_EPS: int = 18

## Fractiile din traseu la care se uita. Acopera tot turul, nu doar zona in
## care s-a raportat ultimul bug.
const FRACS: Array[float] = [0.02, 0.12, 0.22, 0.32, 0.42, 0.52, 0.62, 0.72,
	0.82, 0.92]

var _twin: Dictionary = {}


func _ready() -> void:
	var track_index := 0
	var save := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg == "--save":
			save = true

	var name: String = GameState.TRACK_NAMES[track_index]
	print("\n=== SE VEDE PRIN GEOMETRIE: %s ===" % name)
	var normal := await _shoot(track_index, false)
	var open := await _shoot(track_index, true)

	var worst := 0
	var worst_at := 0.0
	var dir := ProjectSettings.globalize_path("res://snapshots")
	for i in FRACS.size():
		var px := _differing(normal[i], open[i])
		if px > worst:
			worst = px
			worst_at = FRACS[i]
		print("  frac %.2f : %6d pixeli" % [FRACS[i], px])
		if save:
			DirAccess.make_dir_recursive_absolute(dir)
			var stem := "%s/prin_%s_%02d" % [dir, name.to_lower(),
				int(FRACS[i] * 100.0)]
			(normal[i] as Image).save_png(stem + ".png")
			(open[i] as Image).save_png(stem + "_deschis.png")
	var limit: int = FAIL_OVERRIDE.get(name, FAIL_PX)
	print("  varf: %d pixeli la frac %.2f (prag %d)" % [worst, worst_at, limit])
	if worst > limit:
		print("VERDICT: PROBLEMA — se vede prin geometrie.")
		get_tree().quit(1)
		return
	print("VERDICT: OK")
	get_tree().quit()


## Randeaza toate fractiile pe o pista proaspata si intoarce imaginile.
##
## Pista se reconstruieste pentru fiecare trecere: materialele fara culling sunt
## duplicate, iar un duplicat lasat peste materialul partajat s-ar vedea si in
## trecerea urmatoare.
func _shoot(track_index: int, no_cull: bool) -> Array[Image]:
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	if no_cull:
		_twin.clear()
		_disable_culling(track)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 400.0
	cam.current = true
	var out: Array[Image] = []
	var n := track.baked.size()
	for f in FRACS:
		var idx := int(f * float(n)) % n
		var focus: Vector3 = track.baked[idx]
		var ahead: Vector3 = track.baked[(idx + 12) % n]
		var fwd := (ahead - focus).normalized()
		cam.position = focus - fwd * ChaseCamera.DEFAULT_DISTANCE \
			+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		cam.look_at(focus + fwd * ChaseCamera.LOOK_AHEAD
			+ Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		out.append(get_viewport().get_texture().get_image())
	cam.queue_free()
	track.queue_free()
	await get_tree().process_frame
	return out


func _differing(a: Image, b: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if int(absf(ca.r - cb.r) * 255.0) > CHANNEL_EPS \
					or int(absf(ca.g - cb.g) * 255.0) > CHANNEL_EPS \
					or int(absf(ca.b - cb.b) * 255.0) > CHANNEL_EPS:
				count += 1
	return count


## Duplicat pe material SURSA, nu pe instanta: pista are mii de vizuale pe un
## pumn de materiale, iar cate un duplicat de fiecare epuizeaza resursele
## driverului (masurat: cadru negru si mii de erori de textura).
func _disable_culling(node: Node) -> void:
	var geom := node as GeometryInstance3D
	if geom != null:
		var mat := geom.material_override as StandardMaterial3D
		if mat != null:
			geom.material_override = _no_cull(mat)
		var mi := node as MeshInstance3D
		if mat == null and mi != null and mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				var sm := mi.mesh.surface_get_material(i) as StandardMaterial3D
				if sm != null:
					mi.set_surface_override_material(i, _no_cull(sm))
	for c in node.get_children():
		_disable_culling(c)


func _no_cull(src: StandardMaterial3D) -> StandardMaterial3D:
	if not _twin.has(src):
		var dup := src.duplicate() as StandardMaterial3D
		dup.cull_mode = BaseMaterial3D.CULL_DISABLED
		_twin[src] = dup
	return _twin[src]
