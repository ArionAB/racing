extends Node
## Cat de sus trebuie sa fie un obiect ca sa se citeasca PE CER din chase cam,
## si pe ce fractie il vede camera de la fracturile de captura ale POI-ului C.
##
## Camera de joc (ChaseCamera): ochi la 10,0 m peste masina, 12,5 m in spate,
## priveste un punct la 5,0 m INAINTE si 0,40 m inaltime, FOV 68. Pitch-ul
## iese -28,75 grade, deci orizontul cade la 7,7% din inaltimea cadrului de
## sus. Consecinta, derivata nu ghicita: orice obiect al carui varf nu trece
## PESTE cota ochiului (+10 m fata de sosea) se citeste pe iarba, nu pe cer.
## Memoria inaltimea-obiectelor-si-camera, aplicata la POI C.

const D := 12.5
const H := 10.0
const LA := 5.0
const LH := 0.40
const FOV := 68.0

func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var n: int = t.baked.size()
	var pitch := atan2(LH - H, D + LA)
	print("; puncte=%d, pitch camera %.2f grade, orizont la %.1f%% din cadru de sus" % [
		n, rad_to_deg(pitch), (1.0 - (-rad_to_deg(pitch)) / (FOV * 0.5)) * 0.5 * 100.0])
	for cf: float in [0.2250, 0.2400, 0.2700, 0.3000, 0.3300, 0.3600]:
		var i := int(cf * float(n)) % n
		var focus: Vector3 = t.baked[i]
		var ahead: Vector3 = t.baked[(i + 12) % n]
		var dir := (ahead - focus).normalized()
		var eye := focus - dir * D + Vector3.UP * H
		print("\n; === captura frac %.4f  ochi (%.1f, %.1f, %.1f) ===" % [
			cf, eye.x, eye.y, eye.z])
		var k := 4
		while k <= 120:
			var j := (i + k) % n
			var q: Vector3 = t.baked[j]
			var d := eye.distance_to(q)
			if d > 130.0:
				break
			var horiz := Vector2(q.x - eye.x, q.z - eye.z).length()
			var need := eye.y + horiz * tan(deg_to_rad(3.0)) - q.y
			print(";   frac %.4f dist %6.1f m  y_drum %6.2f (%+6.2f fata de ochi)  H_pe_cer=%5.1f m" % [
				float(j) / float(n), d, q.y, q.y - eye.y, need])
			k += 10
	get_tree().quit(0)
