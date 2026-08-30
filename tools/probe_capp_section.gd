extends Node
## Sonda de SECTIUNE pe cornisa Cappadociei: profilul terenului de-a curmezisul
## drumului, pe amandoua partile, in cifre.
##
## De ce nu o sonda de verdict. `ProbeCornice` raspunde „e polita destul de
## lata", si e o intrebare buna cand cornisa exista. Aici intrebarea criticului
## e alta: [b]exista pe partea de vale o muchie, sau terenul pleaca drept
## inainte?[/b] Un verdict nu poate raspunde — un plan orizontal trece toate
## pragurile de siguranta tocmai fiindca nu are nimic care sa cada.
##
## Deci se tipareste PROFILUL: cota solidului la fiecare pas lateral, de la
## axa spre exterior, plus caderea totala pe primii 20 m dincolo de asfalt.
## Cifra care conteaza e `dY(buza..+20m)`: pe un plan e ~0, pe o cornisa e
## metri. Ea spune daca s-a sapat ceva, nu daca e sigur.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappSection.tscn

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRACS: Array[float] = [0.20, 0.23, 0.26, 0.29, 0.32, 0.35, 0.38]
const LAT_STEP: float = 2.0
const LAT_MAX: float = 40.0

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== SECTIUNE CORNISA Cappadocia (Track13) ===")
	print("  (- = spre deal/interior, + = spre vale/exterior)")
	for f in FRACS:
		_section(f)
	get_tree().quit(0)


## Cota din CAMPUL DE INALTIME, nu din raycast: acelasi numar pe care il
## foloseste generatorul, si de mii de ori mai ieftin (sonda cu raze nu
## termina in 5 minute).
func _ground_at(p: Vector3) -> float:
	return (_track._sampler as TrackSideSampler).ground_y(p.x, p.z)


func _section(frac: float) -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(frac * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var side := route.side_at(idx)
	var hw := _track.width_at(_track.frac_at(idx))
	print("-- frac %.3f, axa y=%.2f, semilatime %.1f m" % [frac, c.y, hw])
	for sign_i: float in [-1.0, 1.0]:
		var line := PackedStringArray()
		var y_lip := INF
		var y_far := 0.0
		var steps := int(LAT_MAX / LAT_STEP)
		for k in steps + 1:
			var d := float(k) * LAT_STEP
			var p: Vector3 = c + side * (d * sign_i)
			var y := _ground_at(p)
			if d >= hw and y_lip == INF:
				y_lip = y
			y_far = y
			if k % 2 == 0:
				line.append("%.0f:%.1f" % [d, y])
		var drop := (y_lip - y_far) if y_lip != INF else 0.0
		print("   %s  %s" % ["deal" if sign_i < 0 else "VALE", " ".join(line)])
		print("        dY(buza..+%.0fm) = %+.2f m" % [LAT_MAX, drop])
