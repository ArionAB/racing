extends Node
## Profilul stancii goale: e plina pe dinafara si goala pe dinauntru?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappRock.tscn -- --track=6
##
## Taie campul de teren pe raze care pleaca din axa elicei. Doua intrebari,
## amandoua obligatorii:
##   - INAUNTRU (r < raza elicei) terenul sta la podea, ca spirala sa incapa;
##   - AFARA masivul se ridica pe FIECARE azimut, ca stanca sa inchida spirala.
##
## [b]De ce per azimut, si de ce a fost gresit inainte.[/b] Prima versiune lua
## un MAX peste toate crestele: un singur perete, oriunde, satisfacea „plin pe
## dinafara". Masurat pe varianta cu un singur dom decentrat, verdictul iesea
## OK in timp ce la 225 si 270 de grade terenul statea la 11-13 m pana la 120 m
## — adica jumatate de stanca lipsea si garda nu vedea nimic. O garda care
## trece pe o singura directie buna nu masoara nimic.
##
## Deci: fiecare azimut isi da propriul verdict, si UNUL singur cazut face
## sonda rosie. Exceptie declarata, nu tacuta: cele doua GURI prin care trece
## chiar drumul (intrarea din orasul subteran, gura de iesire spre platou).
## Acolo peretele nu poate exista — ar ingropa soseaua — si sectorul e trecut
## in [constant DOORWAYS] cu numele lui, ca sa se vada ca e o usa, nu o gaura.
##
## Lista e tinuta la MINIM prin masuratoare, nu prin margine de siguranta: gura
## de iesire spre platou a fost si ea scutita la inceput, dar creasta masurata
## acolo iese 49 m pe toate azimuturile ei — drumul trece PESTE buza, nu prin
## ea, deci nu are nevoie de exceptie si a fost scoasa. O scutire care acopera
## un perete existent ascunde exact spartura pe care ar trebui s-o prinda.
##
## In schimb usa de intrare e mai LATA decat pare din desen (205-258 grade, nu
## 210-240): pe azimuturile 245-255 masca de protectie a asfaltului se INCHIDE
## pe masura ce creste raza (masurat: 0.21 la r=46, 0.00 la r=70), fiindca chiar
## pe directia aia pleaca drumul de apropiere din orasul subteran. Acolo nu e o
## spartura care se poate carpi cu teren — e coridorul de intrare, si un masiv
## pus peste el ar ingropa soseaua.

const AXIS := Vector2(-302.02, 6.00)
## Raza pana la care terenul TREBUIE sa ramana jos (elicea + carosabil).
const INNER_R: float = 34.0
## Cat de sus trebuie sa urce creasta fata de podeaua hornului, pe FIECARE azimut.
const MIN_WALL_RISE: float = 20.0
## Podeaua declarata a scobiturii.
const FLOOR_Y: float = 11.0
## Pe ce interval de raze se cauta creasta: dincolo de peretele scobiturii
## (34 + 12 = 46 m) si pana unde inca mai e stanca, nu desert.
const CREST_R0: float = 40.0
const CREST_R1: float = 72.0

## Sectoarele in care drumul insusi strapunge masivul, deci peretele lipseste
## din constructie. Numele e obligatoriu: o exceptie fara motiv scris e o gaura.
const DOORWAYS: Array = [
	{"name": "gura de intrare (din orasul subteran, y~12)", "a0": 205.0, "a1": 258.0},
]


func _doorway(deg: float) -> String:
	for d: Dictionary in DOORWAYS:
		if deg >= float(d["a0"]) and deg <= float(d["a1"]):
			return String(d["name"])
	return ""


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var s: TrackSideSampler = track.get("_sampler")

	print("")
	print("=== Stanca goala — profil radial din axa elicei (%.1f, %.1f) ==="
		% [AXIS.x, AXIS.y])
	var header := "  r(m) "
	for deg in range(0, 360, 30):
		header += "  %4d" % deg
	print(header)
	var inner_max := -INF
	var r := 0.0
	while r <= 96.0:
		var line := "  %4.0f " % r
		for deg in range(0, 360, 30):
			var a := deg_to_rad(float(deg))
			var y := s.ground_y(AXIS.x + r * cos(a), AXIS.y + r * sin(a))
			line += " %5.1f" % y
			if r <= INNER_R:
				inner_max = maxf(inner_max, y)
		print(line)
		r += 8.0

	# Verdictul PER AZIMUT, la pasul de 10 grade: destul de fin cat sa prinda o
	# spartura de un sector, nu doar o jumatate de stanca lipsa.
	print("")
	print("=== Peretele, azimut cu azimut (creasta intre r=%.0f si r=%.0f) ==="
		% [CREST_R0, CREST_R1])
	var bad: Array[String] = []
	var doors := 0
	var walled := 0
	var deg := 0.0
	while deg < 360.0:
		var a := deg_to_rad(deg)
		var crest := -INF
		var rr := CREST_R0
		while rr <= CREST_R1:
			crest = maxf(crest, s.ground_y(AXIS.x + rr * cos(a),
				AXIS.y + rr * sin(a)))
			rr += 4.0
		var rise := crest - FLOOR_Y
		var door := _doorway(deg)
		var verdict := ""
		if door != "":
			doors += 1
			verdict = "USA — %s" % door
		elif rise >= MIN_WALL_RISE:
			walled += 1
			verdict = "perete OK"
		else:
			bad.append("%.0f deg (doar %+.1f m)" % [deg, rise])
			verdict = "LIPSA PERETE"
		print("  %3.0f deg  creasta %5.1f m  urcare %+6.1f m   %s"
			% [deg, crest, rise, verdict])
		deg += 10.0

	print("")
	print("  interiorul (r <= %.0f m): cel mai inalt teren %.2f m" % [INNER_R, inner_max])
	print("  azimuturi cu perete : %d" % walled)
	print("  azimuturi de usa    : %d (declarate, cu motiv)" % doors)
	print("  azimuturi FARA perete: %d" % bad.size())
	for b in bad:
		print("     - %s" % b)
	var ok_in := inner_max <= 12.0
	var ok_out := bad.is_empty()
	print("")
	print("  gol pe dinauntru : %s" % ("OK" if ok_in else "PROBLEMA"))
	print("  inchis pe dinafara: %s"
		% ("OK" if ok_out else "PROBLEMA (masivul nu inconjoara elicea)"))
	print("VERDICT: %s" % ("OK" if ok_in and ok_out else "PROBLEMA"))
	get_tree().quit(0 if ok_in and ok_out else 1)
