extends Node
## EXISTA UMAR? Intrebarea pe care celelalte sonde au ocolit-o.
##
## Toate masuratorile de pana acum au gasit teren solid la offseturi NEGATIVE
## (adica sub carosabil) si aer la offseturi pozitive. Sonda asta pune intrebarea
## direct, pe toata zona C: pe fiecare fractie si fiecare parte, cat de departe
## dincolo de muchie mai e teren la cel mult 3 m sub sosea?
##
## Daca raspunsul e "nicaieri", atunci nu exista loc pentru niciun obiect de
## volum langa drum pe portiunea asta, si orice compozitie care cere asa ceva
## trebuie sa se mute sau sa se schimbe. Asta e o constrangere a TERENULUI,
## deci se raporteaza, nu se ocoleste ridicand piese in aer.

var _track: Node
var _rid: RID

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	_track = ps.instantiate()
	add_child(_track)
	await get_tree().process_frame
	for c in _track.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	var n: int = _track.baked.size()
	print("; umar = cat de departe DINCOLO de muchie mai e teren la cel mult 3 m sub sosea")
	print("; frac    half   umar(-1)   umar(+1)   cota la muchie -1 / +1")
	var f := 0.220
	var best_m1 := 0.0
	var best_p1 := 0.0
	var f_m1 := 0.0
	var f_p1 := 0.0
	while f <= 0.400:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		var um: Array[float] = []
		var la_muchie: Array[float] = []
		for sg: float in [-1.0, 1.0]:
			var lip := p + s * sg * half
			la_muchie.append(_sol(lip.x, lip.z) - p.y)
			var reach := -1.0
			var off := 0.0
			while off <= 12.0:
				var q: Vector3 = p + s * sg * (half + off)
				var gy := _sol(q.x, q.z)
				if gy < -900.0 or p.y - gy > 3.0:
					break
				reach = off
				off += 0.5
			um.append(reach)
		if um[0] > best_m1:
			best_m1 = um[0]
			f_m1 = f
		if um[1] > best_p1:
			best_p1 = um[1]
			f_p1 = f
		print("; %.4f  %5.2f   %+7.1f   %+7.1f    %+6.2f / %+6.2f" % [
			f, half, um[0], um[1], la_muchie[0], la_muchie[1]])
		f += 0.006
	print("; ---")
	print("; cel mai lat umar pe -1: %.1f m la frac %.4f" % [best_m1, f_m1])
	print("; cel mai lat umar pe +1: %.1f m la frac %.4f" % [best_p1, f_p1])
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	var space := (_track as Node3D).get_world_3d().direct_space_state
	var par := PhysicsRayQueryParameters3D.create(Vector3(x, 400.0, z), Vector3(x, -600.0, z))
	par.collide_with_areas = false
	par.exclude = []
	var hit := space.intersect_ray(par)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		par.exclude = par.exclude + [hit["rid"]]
		hit = space.intersect_ray(par)
		g += 1
	return -999.0 if hit.is_empty() else (hit["position"] as Vector3).y
