extends Node
## Politele falezei: se sprijina pe ceva, sau atarna in aer?
##
## Verdictul rundei 7 („citesc ca geometrie rupta la inaltimea soferului")
## arata catre lespedea rosie care pluteste in captura de la fractia 0.235.
## Suspectul e `ledge_*` din CliffFace: fata iese cu `ledge_depth_m` DOAR sub
## cota politei si DOAR pe `ledge_len_m`, deci la capetele ferestrei profilul
## sare inapoi si sub polita ramane gol.
##
## Sonda masoara exact asta: pentru fiecare polita declarata se compara rulajul
## lateral al fetei chiar IN polita cu cel de la un pas in afara ei. O saritura
## mare inseamna lespede detasata.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== POLITE (Track13) ===")
	var faces: Array[CliffFace] = []
	_collect(_track, faces)
	var sampler := _track._sampler as TrackSideSampler
	for f in faces:
		if f.ledge_fracs.is_empty():
			continue
		print("-- nod %s: %d polite, len %.1f m, depth %.1f m"
			% [f.name, f.ledge_fracs.size(), f.ledge_len_m, f.ledge_depth_m])
		# Ce conteaza NU e diferenta dintre mijlocul politei si afara — aia e
		# adancimea ceruta, si trebuie sa existe. Conteaza saltul intre doua
		# COLOANE VECINE, fiindca ala e muchia pe care o vede ochiul: peste ~1 m
		# intre coloane la 4 m distanta, suprafata se rupe si lespedea pluteste.
		var step_frac := f.step_m / maxf(sampler.total_length(), 1.0)
		for lf: float in f.ledge_fracs:
			var half := (f.ledge_len_m * 0.5) / maxf(sampler.total_length(), 1.0)
			var worst := 0.0
			var at := 0.0
			var k := -2.0
			while k <= 2.0:
				var fa := lf + half * k
				var fb := fa + step_frac
				var jump: float = absf(_reach(f, sampler, fb) - _reach(f, sampler, fa))
				if jump > worst:
					worst = jump
					at = fa
				k += 0.25
			print("   frac %.3f: cel mai mare salt intre coloane vecine %.2f m (la frac %.3f)"
				% [lf, worst, at])
	get_tree().quit(0)


static func _collect(node: Node, out: Array[CliffFace]) -> void:
	for child in node.get_children():
		if child is CliffFace:
			out.append(child as CliffFace)
		_collect(child, out)


## Cel mai mare rulaj lateral atins de coloana fetei la fractia data.
func _reach(f: CliffFace, sampler: TrackSideSampler, frac: float) -> float:
	var col: Array = f._column(sampler, frac,
		Callable(_track, "_terrain_mesh_y"))
	if col.is_empty():
		return 0.0
	var n := sampler.point_count()
	var i := clampi(int(round(frac * float(n))) % n, 0, n - 1)
	var p := sampler.baked_point(i)
	var sd := sampler.side_at(i) * signf(f.side)
	var best := 0.0
	for v: Vector3 in col:
		var d: float = Vector2(v.x - p.x, v.z - p.z).dot(Vector2(sd.x, sd.z))
		best = maxf(best, d)
	return best
