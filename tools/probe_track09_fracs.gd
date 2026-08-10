extends Node
## Sonda TEMPORARA de masurare a fractiilor pentru Alpii (Track09).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTrack09Fracs.tscn
##
## Traduce POZITII FIZICE (repere din geometria desenata) in fractii de tur pe
## curba coapta, ca hook-urile pistei sa primeasca numere masurate, nu ghicite —
## regula Stramtorii. Se ruleaza dupa orice mutare de punct de control; valorile
## se copiaza in track09.gd cu mana, ca sa ramana un singur adevar (cel din cod).

## Reperele: nume -> pozitie XZ in lume (Y-ul e ignorat la cautare).
const ANCHORS := {
	"car_cu_fan (ulita)": Vector2(112, -1),
	"iesirea din sat": Vector2(238, -48),
	"sania cu busteni (padure)": Vector2(266, -172),
	# --- CULMEA rescrisa: urcare -> ac -> traversare -> ac -> umar ---
	"poalele (intrarea in urcare)": Vector2(114, -382),
	"acul 1 (intrare)": Vector2(16, -380),
	"acul 1 (varful arcului)": Vector2(-10, -366),
	"acul 1 (iesire)": Vector2(-22, -346),
	"traversarea (inceput)": Vector2(-18, -326),
	"traversarea (mijloc/cornisa)": Vector2(-12, -306),
	"traversarea (sfarsit)": Vector2(-16, -288),
	"acul 2 (intrare)": Vector2(-37, -257),
	"acul 2 (varful arcului)": Vector2(-23, -239),
	"acul 2 (iesire)": Vector2(14, -257),
	"umarul (statia telecabina)": Vector2(56, -261),
	"umarul (varful de sus)": Vector2(56, -239),
	"tren (platoul de nord)": Vector2(-2, -208),
	"creasta fly-off (buza)": Vector2(-96, -254),
	"entry scurtatura": Vector2(-186, -238),
	"vaca (coborare)": Vector2(-220, -209),
	"rampa (coltul NV)": Vector2(-229, -72),
	"exit scurtatura": Vector2(-196, -46),
	"podul peste parau": Vector2(-126, -14),
	"tractorul (vale)": Vector2(-92, -12),
	"sicana satului": Vector2(-42, -3),
}


func _ready() -> void:
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track09.tscn") as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r := track.routes[0]
	var n := r.count()
	print("")
	print("=== Track09 — %s ===" % track.track_name)
	print("lungime bucla: %.1f m (%d puncte coapte)" % [r.length(), n])
	var y_min := INF
	var y_max := -INF
	for p in r.baked:
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	print("cota: min %.1f, max %.1f (diferenta %.1f m)" % [y_min, y_max, y_max - y_min])
	print("")
	for anchor_name in ANCHORS:
		var xz: Vector2 = ANCHORS[anchor_name]
		var best := 0
		var best_d := INF
		for i in n:
			var d := Vector2(r.baked[i].x - xz.x, r.baked[i].z - xz.y).length_squared()
			if d < best_d:
				best_d = d
				best = i
		# Latura EXTERIOARA a buclei la punctul asta. O cere si rapa (pe ce
		# semn se sapa prapastia), si parapetii (pe ce latura e golul), iar
		# semnul NU se poate citi din desen: depinde de sensul de parcurgere.
		var side := _outer_sign(track, r, best)
		print("%-32s frac %.3f  (y %.1f, abatere XZ %.1f m, exterior %+d)" % [
			anchor_name, r.frac_at(best), r.baked[best].y, sqrt(best_d), side])
	for ri in range(1, track.routes.size()):
		var b := track.routes[ri]
		print("")
		print("ruta %d (%s): %.1f m, entry %.3f, exit %.3f" % [
			ri, b.label, b.length(), b.entry_frac, b.exit_frac])
		var main_len: float = r.length() * fposmod(b.exit_frac - b.entry_frac, 1.0)
		print("  ocoleste %.1f m de sosea -> castig brut %.1f m" % [
			main_len, main_len - b.length()])
	track.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


## Pe ce semn de latura (+1/-1) cade EXTERIORUL buclei la punctul copt `i`.
##
## Aceeasi intrebare pe care si-o pune Track._build_walls: un punct offsetat cu
## `side * half_width` care cade IN AFARA poligonului punctelor de control e pe
## exterior. O repetam aici, in loc s-o citim de acolo, fiindca sonda are nevoie
## de raspuns per PUNCT, nu per segment de perete.
func _outer_sign(track: Track, r: TrackRoute, i: int) -> int:
	var poly := PackedVector2Array()
	for p in track._points():
		poly.append(Vector2(p.x, p.z))
	var n := r.count()
	var nxt: Vector3 = r.baked[(i + 1) % n]
	var cur: Vector3 = r.baked[i]
	var dir := (nxt - cur)
	var side := Vector3(-dir.z, 0.0, dir.x).normalized()
	var probe := cur + side * track.half_width * 1.5
	return -1 if Geometry2D.is_point_in_polygon(Vector2(probe.x, probe.z), poly) else 1
