extends Node
## Sonda de CORNISA pentru POI H: se vede sau nu se vede caderea?
##
## Captura rundei 1 (H_r1_f0935/f0955) arata pe partea golului o PANTA DE IARBA
## care coboara lin, nu o prapastie — desi survey-ul da -11..-12,3 m la 15 m
## lateral. Cele doua nu se contrazic: o cadere de 11 m intinsa pe 15 m
## orizontal e o panta de 36 de grade, adica un DEAL, nu o cornisa.
##
## Memoria umarul-ingust-ascunde-caderea: ochiul e la ~1,5 m peste sosea si
## conteaza UNGHIUL sub care pleaca terenul de la muchie, nu adancimea totala.
## Deci sonda masoara, la fiecare fractie:
##   - panta LOCALA in primii 3 m dupa muchie (asta decide daca citeste cornisa)
##   - panta pe primii 6 si 12 m
##   - cat de departe de muchie incepe caderea de 1 m si de 3 m
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpHCornisa.tscn

const TRACK := "res://scenes/tracks/Track15.tscn"
const F_IN := 0.928
const F_OUT := 0.980

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()
	print("; PARTEA GOLULUI (-side). unghi = panta medie pe primii N m dupa muchie.")
	print("; frac    half   d(1m)  d(3m)   panta 0-3m  0-6m  0-12m   cota la muchie+3/+6/+12/+25")
	var f := F_IN
	while f <= F_OUT:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i) * -1.0    # -side = golul (survey nota 2)
		var half := _track.width_at_index(i)
		var y0 := _sol_real((p + s * half).x, (p + s * half).z)
		var cote: Array[float] = []
		for d: float in [3.0, 6.0, 12.0, 25.0]:
			var q := p + s * (half + d)
			cote.append(_sol_real(q.x, q.z) - p.y)
		# cat de departe de muchie cade 1 m si 3 m
		var d1 := -1.0
		var d3 := -1.0
		var d := 0.25
		while d <= 30.0:
			var q := p + s * (half + d)
			var drop := p.y - _sol_real(q.x, q.z)
			if d1 < 0.0 and drop >= 1.0:
				d1 = d
			if d3 < 0.0 and drop >= 3.0:
				d3 = d
			d += 0.25
		var a3 := rad_to_deg(atan2(maxf(0.0, y0 - (p.y + cote[0])), 3.0))
		var a6 := rad_to_deg(atan2(maxf(0.0, y0 - (p.y + cote[1])), 6.0))
		var a12 := rad_to_deg(atan2(maxf(0.0, y0 - (p.y + cote[2])), 12.0))
		print("; %.4f  %4.1f  %5.1f  %5.1f   %6.1f %6.1f %6.1f   %+6.1f %+6.1f %+6.1f %+6.1f" % [
			f, half, d1, d3, a3, a6, a12, cote[0], cote[1], cote[2], cote[3]])
		f += 0.004
	get_tree().quit(0)


func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = []
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _terrain_rid:
		return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
