extends Node
## Ce se poate aseza APROAPE de camera capturii 0,2400, pe dreapta ecranului.
##
## Runda 2 a incercat intai inaltimea (pinten de 20 m la 44 m departare) si a
## esuat de doua ori pe FORMA: nicio piesa din kit nu e destul de zvelta. Cea
## mai zvelta e `guardhouse`, cu raport inaltime/baza 1,00 — un cub. Kitul n-are
## ac de stanca; `huayna_picchu` la 20 m inaltime are baza de 48 m si ingroapa
## drumul.
##
## Deci se cumpara APROPIEREA in locul inaltimii. Aritmetica frustumului
## (ochi la 10 m peste sosea, pitch -28,75 grade, FOV 68, 16:9):
##
##   dist orizontala   inaltime piesa   varful la % din cadru   6 m de aripi
##        15 m              8,0 m             24,4%                16,7%
##        20 m              8,0 m             20,3%                12,5%
##        30 m              8,0 m             18,9%                 8,3%
##        44 m              5,0 m             20,3%                 5,7%   <- runda anterioara
##
## La 15 m o piesa de 8 m e de trei ori mai lata in cadru decat aceeasi piesa la
## 44 m, si sta in banda de cer/nor din treimea de sus. Asta e ce cere criticul
## ("punct de fixare a privirii", "scara"), fara sa ceara o forma pe care kitul
## n-o are.
##
## Sonda cauta, pe 0,2400-0,2500, teren solid cat mai aproape de ochi, pe partea
## +1 (dreapta ecranului, masurat de probe_mp_c_ecran.gd).

const D := 12.5
const H := 10.0
const LA := 5.0
const LH := 0.40
const FOV := 68.0
const ASPECT := 1280.0 / 720.0

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
	var ci := int(0.2400 * float(n)) % n
	var focus: Vector3 = _track.baked[ci]
	var dir := ((_track.baked[(ci + 12) % n] as Vector3) - focus).normalized()
	var eye := focus - dir * D + Vector3.UP * H
	var look := focus + dir * LA + Vector3.UP * LH
	var fwd := (look - eye).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	print("; ochi (%.1f, %.1f, %.1f)" % [eye.x, eye.y, eye.z])
	print("; frac  semn  off  teren(dy)  distOriz  ecranX%  | varf piesa 8m: ecranY%")
	var f := 0.2400
	while f <= 0.2520:
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i)
		var half: float = _track.width_at_index(i)
		for sg: float in [-1.0, 1.0]:
			for off: float in [-2.5, -1.5, -0.5]:
				var q: Vector3 = p + s * sg * (half + off)
				var gy := _sol(q.x, q.z)
				if gy < -900.0 or p.y - gy > 3.0:
					continue
				var base := Vector3(q.x, gy, q.z)
				var v := base - eye
				var z := v.dot(fwd)
				if z < 0.5:
					continue
				var ex := (v.dot(right) / z / (tan(deg_to_rad(FOV * 0.5)) * ASPECT) + 1.0) * 50.0
				var dh := Vector2(q.x - eye.x, q.z - eye.z).length()
				var tip := Vector3(q.x, gy + 8.0, q.z) - eye
				var tz := tip.dot(fwd)
				var ey := (1.0 - (tip.dot(up) / tz) / tan(deg_to_rad(FOV * 0.5))) * 50.0
				print("; %.4f  %+2.0f  %4.1f  %+8.2f  %8.1f  %6.1f   %14.1f" % [
					f, sg, off, gy - p.y, dh, ex, ey])
		f += 0.0018
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
