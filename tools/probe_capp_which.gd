extends Node
## PE CE PARTE CADE side=+1, in coordonate de ECRAN?
##
## Capturile rundei 10 arata peretele construit corect (strate in trepte, muchii
## adevarate) dar pe STANGA cadrului, desi valea si baloanele sunt pe DREAPTA.
## Deci `side` nu inseamna ce am presupus. Sonda nu ghiceste: ia versorul lateral
## al rutei, il proiecteaza pe dreapta camerei (produsul scalar cu right-ul
## derivat din directia de mers) si spune in ce jumatate de ecran cade.

const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const FRACS: Array[float] = [0.20, 0.28, 0.32]

var _track: Track


func _ready() -> void:
	_track = (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== UNDE CADE side_at PE ECRAN ===")
	for f in FRACS:
		_which(f)
	get_tree().quit(0)


func _which(frac: float) -> void:
	var route := _track.route_at(0)
	var n := route.count()
	var idx := clampi(int(round(frac * float(n))), 0, n - 1)
	var c := _track.point_at(idx)
	var side: Vector3 = route.side_at(idx)
	var fwd: Vector3 = (_track.point_at((idx + 1) % n) - c).normalized()
	# dreapta camerei care se uita pe directia de mers
	var right: Vector3 = fwd.cross(Vector3.UP).normalized()
	var d := side.dot(right)
	var sampler := _track._sampler as TrackSideSampler
	var y_plus: float = sampler.ground_y(c.x + side.x * 40.0, c.z + side.z * 40.0)
	var y_minus: float = sampler.ground_y(c.x - side.x * 40.0, c.z - side.z * 40.0)
	print("  frac %.2f: side_at . right = %+.2f  -> side=+1 e la %s ecranului"
		% [frac, d, "DREAPTA" if d > 0.0 else "STANGA"])
	print("      teren la 40 m pe +side: y=%7.2f (dy %+7.2f)   pe -side: y=%7.2f (dy %+7.2f)  -> valea e pe %s"
		% [y_plus, y_plus - c.y, y_minus, y_minus - c.y,
		"+side" if y_plus < y_minus else "-side"])
