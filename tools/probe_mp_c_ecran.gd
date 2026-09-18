extends Node
## Pe ce PARTE DE ECRAN cade fiecare semn (+1 / -1) din camera de joc, si la ce
## procent din latimea cadrului. Fara asta, "dreapta" din verdictul criticului
## si "+1" din cod sunt doua limbi diferite.

const D := 12.5
const H := 10.0
const LA := 5.0
const LH := 0.40
const FOV := 68.0
const ASPECT := 1280.0 / 720.0

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var n: int = t.baked.size()
	for cf: float in [0.2400, 0.3000, 0.3600]:
		var ci := int(cf * float(n)) % n
		var focus: Vector3 = t.baked[ci]
		var dir := ((t.baked[(ci + 12) % n] as Vector3) - focus).normalized()
		var eye := focus - dir * D + Vector3.UP * H
		var look := focus + dir * LA + Vector3.UP * LH
		var fwd := (look - eye).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var up := right.cross(fwd).normalized()
		print("; --- captura %.4f ---" % cf)
		for k: int in [8, 16, 24]:
			var j := (ci + k) % n
			var p: Vector3 = t.baked[j]
			var s: Vector3 = t._side_at(j)
			var half: float = t.width_at_index(j)
			for sg: float in [-1.0, 1.0]:
				var q: Vector3 = p + s * sg * half
				var v := q - eye
				var z := v.dot(fwd)
				if z < 0.5:
					continue
				var x := v.dot(right) / z
				var y := v.dot(up) / z
				var tan_h := tan(deg_to_rad(FOV * 0.5)) * ASPECT
				var tan_v := tan(deg_to_rad(FOV * 0.5))
				print(";  frac %.4f semn %+2.0f -> ecran X %5.1f%% (0=stanga,100=dreapta), Y %5.1f%% de sus" % [
					float(j) / float(n), sg,
					(x / tan_h + 1.0) * 50.0, (1.0 - y / tan_v) * 50.0])
	get_tree().quit(0)
