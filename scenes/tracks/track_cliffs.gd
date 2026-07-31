class_name TrackCliffs
extends RefCounted
## Peretii de canion de pe marginea soselei.
##
## Deocamdata un ciot care nu construieste nimic: seam-ul exista ca lumea sa
## poata lucra in paralel pe [TrackDecor] si pe assets-urile de faleza fara sa
## se calce in [code]track.gd[/code]. Implementarea vine separat.
##
## Contractul, cand se umple:
##   - sectiuni GLB asezate pe marginea inchisa (vezi
##     [method TrackSideSampler.wall_segments]), la pas fix, suprapuse ~1m;
##   - fiecare sectiune isi aduce propria coliziune (convex hull), pentru ca
##     zidul rosu dispare de pe tema desert;
##   - gol de ±25m in jurul landmark-urilor hero, ca sa nu le acopere.


## Construieste falezele si le intoarce sub un singur nod.
##
## `landmarks` are formatul din [code]Track._landmark_spots()[/code]:
## (fractie 0..1, parte ±1, id-model).
static func build(sampler: TrackSideSampler, theme: String, seed_value: int,
		landmarks: Array[Vector3]) -> Node3D:
	var root := Node3D.new()
	root.name = "Cliffs"
	return root
