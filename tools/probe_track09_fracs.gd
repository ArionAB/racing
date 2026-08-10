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
	"intrarea in lob": Vector2(48, -362),
	"serpentina (intoarcerea)": Vector2(-24, -296),
	"statia telecabina (diag. sus)": Vector2(44, -286),
	"platou - inceput": Vector2(66, -252),
	"tren (mijlocul platoului)": Vector2(-29, -239),
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
		print("%-32s frac %.3f  (y %.1f, abatere XZ %.1f m)" % [
			anchor_name, r.frac_at(best), r.baked[best].y, sqrt(best_d)])
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
