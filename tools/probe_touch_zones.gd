extends Node
## Verifica MAPAREA atingere -> comanda, nu cum arata butoanele.
## Bug-ul de pe iPhone (sageata dreapta vira stanga) a trecut de toate
## capturile fiindca o captura arata unde e desenat butonul, nu ce face.

func _ready() -> void:
	var tc := TouchControls.new()
	add_child(tc)
	# `physics_frame`, nu doar `process_frame`: cu doar process_frame sonda
	# mergea rulata de mana, dar se AGATA sub verify_local.sh — `quit()` chemat
	# prea devreme nu opreste bucla (vezi memoria „garda verde pe zero
	# masuratori"). Asteptam si un cadru de fizica, ca arborele sa fie gata.
	await get_tree().process_frame
	await get_tree().physics_frame
	var s := tc.size
	var cases := [
		["sageata STANGA", tc.call("_steer_left_center"), "left"],
		["sageata DREAPTA", tc.call("_steer_right_center"), "right"],
		["GAZ", tc.call("_gas_center"), "gas"],
		["FRANA", tc.call("_brake_center"), "brake"],
		["TURBO", tc.call("_turbo_center"), "turbo"],
		["DRIFT", tc.call("_drift_center"), "drift"],
		# Jumatatile de ecran au fost SCOASE: o atingere in afara butoanelor nu
		# mai face nimic. Inainte astea doua raspundeau "left"/"right" si virau
		# masina cand sprijineai degetul pe display.
		["gol stanga-sus", Vector2(s.x * 0.2, s.y * 0.3), ""],
		["gol dreapta-sus", Vector2(s.x * 0.8, s.y * 0.3), ""],
		["gol mijloc", Vector2(s.x * 0.5, s.y * 0.5), ""],
		["gol langa sageti", Vector2(s.x * 0.33, s.y - 128.0), ""],
		# Marginea din jurul discului vireaza (degetul cade langa buton), dar se
		# opreste la STEER_TOUCH_PAD: dincolo de ea, display-ul e mort.
		["STANGA langa inel", tc.call("_steer_left_center")
			+ Vector2(0.0, TouchControls.STEER_RADIUS + 2.0), "left"],
		["STANGA in margine", tc.call("_steer_left_center") + Vector2(0.0,
			TouchControls.STEER_RADIUS + TouchControls.STEER_TOUCH_PAD - 2.0), "left"],
		["STANGA dupa margine", tc.call("_steer_left_center") + Vector2(0.0,
			TouchControls.STEER_RADIUS + TouchControls.STEER_TOUCH_PAD + 2.0), ""],
		["DREAPTA dupa margine", tc.call("_steer_right_center") + Vector2(0.0,
			-TouchControls.STEER_RADIUS - TouchControls.STEER_TOUCH_PAD - 2.0), ""],
		# Golul dintre discuri nu e fasie moarta: vireaza sageata mai apropiata.
		["intre sageti, stg", (tc.call("_steer_left_center")
			+ tc.call("_steer_right_center")) * 0.5 - Vector2(4.0, 0.0), "left"],
		["intre sageti, dr", (tc.call("_steer_left_center")
			+ tc.call("_steer_right_center")) * 0.5 + Vector2(4.0, 0.0), "right"],
	]
	var fail := 0
	for c in cases:
		var got: String = tc.call("_zone_at", c[1])
		var ok: bool = got == c[2]
		if not ok:
			fail += 1
		print("%-18s @ %-22s -> %-6s (astept %-6s) %s" % [
			c[0], str(c[1]), got, c[2], "OK" if ok else "<<< PICA"])
	# A DOUA GARDA: discurile care se tin apasate IMPREUNA nu au voie sa se
	# atinga. Gaz+drift (accelerezi in timp ce derapezi) si gaz+turbo (arzi
	# bara pe dreapta) sunt perechile reale; daca discurile se suprapun,
	# degetul cade intre ele si pierzi una din comenzi fara sa intelegi de ce.
	print("")
	var discs := {
		"gaz": [tc.call("_gas_center"), TouchControls.GAS_RADIUS],
		"turbo": [tc.call("_turbo_center"), TouchControls.BUTTON_RADIUS],
		"drift": [tc.call("_drift_center"), TouchControls.BUTTON_RADIUS * 0.9],
		"frana": [tc.call("_brake_center"), TouchControls.BRAKE_RADIUS],
		"stanga": [tc.call("_steer_left_center"), TouchControls.STEER_RADIUS],
		"dreapta": [tc.call("_steer_right_center"), TouchControls.STEER_RADIUS],
	}
	var names := discs.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Array = discs[names[i]]
			var b: Array = discs[names[j]]
			var d: float = (a[0] as Vector2).distance_to(b[0] as Vector2)
			var need: float = float(a[1]) + float(b[1])
			var ok := d >= need
			if not ok:
				fail += 1
			print("%-8s <-> %-8s  %6.0f px (nevoie %.0f) %s" % [
				names[i], names[j], d, need, "OK" if ok else "<<< SE ATING"])

	# A PATRA GARDA: GLISAREA. Un deget pus pe display in afara butoanelor nu
	# are voie sa vireze nici daca aluneca apoi peste ◀ ▶ (palma, degetul
	# sprijinit). Unul pornit de pe ◀ poate glisa pe ▶ si schimba directia.
	# Pe evenimente reale prin `_unhandled_input`, nu pe `_zone_at`.
	print("")
	var left_c: Vector2 = tc.call("_steer_left_center")
	var right_c: Vector2 = tc.call("_steer_right_center")
	var drag_cases := [
		["gol -> STANGA", Vector2(s.x * 0.5, s.y * 0.5), left_c, 0.0],
		["STANGA -> DREAPTA", left_c, right_c, 1.0],
		["STANGA -> gol", left_c, Vector2(s.x * 0.5, s.y * 0.5), 0.0],
	]
	for c in drag_cases:
		var down := InputEventScreenTouch.new()
		down.index = 0
		down.position = c[1]
		down.pressed = true
		tc.call("_unhandled_input", down)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = c[2]
		tc.call("_unhandled_input", drag)
		var got_steer := GameState.touch_steer
		var want_steer: float = c[3]
		var ok := is_equal_approx(got_steer, want_steer)
		if not ok:
			fail += 1
		print("%-18s -> viraj %.1f (astept %.1f) %s" % [
			c[0], got_steer, want_steer, "OK" if ok else "<<< PICA"])
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.position = c[2]
		up.pressed = false
		tc.call("_unhandled_input", up)

	# A TREIA GARDA: GAZUL CARE SE SUBINTELEGE. Toate comenzile de actiune stau
	# sub acelasi deget mare drept, deci nu pot fi tinute odata cu ^. TURBO
	# implica gaz, altfel ai arde bara stand pe loc; DRIFT implica gaz, altfel
	# driftul e o frana (viteza pastrata doar cu gaz, vezi PlayerController).
	# Frana bate orice. Se masoara pe `PlayerController` real, nu pe o copie
	# a regulii.
	print("")
	var pc := PlayerController.new()
	add_child(pc)
	var throttle_cases := [
		["doar GAZ", {"gas": true}, 1.0],
		["doar TURBO", {"turbo": true}, 1.0],
		["doar DRIFT", {"drift": true}, 1.0],
		["TURBO+DRIFT", {"turbo": true, "drift": true}, 1.0],
		["GAZ+DRIFT", {"gas": true, "drift": true}, 1.0],
		["doar FRANA", {"brake": true}, -1.0],
		["FRANA+DRIFT", {"brake": true, "drift": true}, -1.0],
		["FRANA+GAZ", {"brake": true, "gas": true}, -1.0],
		["niciun buton", {}, 0.0],
		["doar viraj", {"steer": 1.0}, 0.0],
	]
	for c in throttle_cases:
		GameState.reset_touch()
		var st: Dictionary = c[1]
		GameState.touch_gas = bool(st.get("gas", false))
		GameState.touch_turbo = bool(st.get("turbo", false))
		GameState.touch_drift = bool(st.get("drift", false))
		GameState.touch_brake = bool(st.get("brake", false))
		GameState.touch_steer = float(st.get("steer", 0.0))
		var got := pc.get_throttle()
		var want: float = c[2]
		var ok := is_equal_approx(got, want)
		if not ok:
			fail += 1
		print("%-14s -> gaz %.1f (astept %.1f) %s" % [
			c[0], got, want, "OK" if ok else "<<< PICA"])
	GameState.reset_touch()
	tc.queue_free()

	fail += await _check_hud_layout()

	print("")
	print("VERDICT: %s (%d esecuri)" % ["OK" if fail == 0 else "PICA", fail])
	get_tree().quit(1 if fail > 0 else 0)


# ------------------------------------------------- HUD-ul fata de zone (#719)
#
# A CINCEA GARDA: bara de turbo nu are voie sa stea in zona de atingere a unui
# buton. Pe 4:3 (iPad) statea peste sageata ▶ si peste frana — gasita de sonda
# turului ghidat, nu de asta, fiindca aici totul rula la o singura marime.
# Acum: HUD-ul REAL si TouchControls REAL, intr-un SubViewport de marimea
# canvas-ului logic (baza 1280x720, stretch `expand`: ecranul mai ingust da
# un canvas mai ingust, nu unul micsorat). Zonele se citesc din `_zone_at`
# punct cu punct, nu din raze copiate — daca un buton se muta, sonda il vede.

## Marimile LOGICE (inaltimea e mereu 720, latimea = 720 x aspect).
const LAYOUT_SIZES := [
	[Vector2i(1280, 720), "1280x720 (baza, 16:9)"],
	[Vector2i(1558, 720), "telefon 2532x1170"],
	[Vector2i(1036, 720), "iPad Air 2360x1640"],
	[Vector2i(960, 720), "4:3 (iPad, 2732x2048)"],
	[Vector2i(900, 720), "5:4 (fereastra desktop)"],
]
## Aerul minim intre bara si orice punct care raspunde la atingere. Peste
## rama de 10 px cu care turul ghidat evidentiaza bara (ProbeTutorial): rama
## nu are voie sa atinga nici ea o zona.
const MIN_GAP := 12.0


## Fiecare punct care raspunde la atingere din `rect` crescut cu `reach`,
## grupat pe zona: {zona: {"box": Rect2 al suprapunerii (sau gol), "gap": cel
## mai mic aer pana la rect, 0 = suprapus}}. Pas de `step` px.
func _touch_near(tc: TouchControls, rect: Rect2, reach: float,
		step: float = 1.0) -> Dictionary:
	var out := {}
	var area := rect.grow(reach)
	var inv := tc.get_global_transform().affine_inverse()
	var y := area.position.y
	while y <= area.end.y:
		var x := area.position.x
		while x <= area.end.x:
			var p := Vector2(x, y)
			var z: String = tc.call("_zone_at", inv * p)
			if z != "":
				var q := Vector2(clampf(x, rect.position.x, rect.end.x),
					clampf(y, rect.position.y, rect.end.y))
				var d := q.distance_to(p)
				var e: Dictionary = out.get(z, {"box": Rect2(), "gap": INF})
				e.gap = minf(float(e.gap), d)
				if d == 0.0:
					var box: Rect2 = e.box
					e.box = Rect2(p, Vector2.ZERO) if box.size == Vector2.ZERO \
						and box.position == Vector2.ZERO else box.expand(p)
				out[z] = e
			x += step
		y += step
	return out


static func _fmt_rect(r: Rect2) -> String:
	return "x %.1f..%.1f  y %.1f..%.1f  (%.1fx%.1f)" % [
		r.position.x, r.end.x, r.position.y, r.end.y, r.size.x, r.size.y]


## Textul unui raport de apropiere: „frana: suprapus 54x22 px (x 592..645)"
## sau „frana: aer 31 px".
static func _fmt_near(near: Dictionary) -> String:
	var parts: Array[String] = []
	for z: String in near:
		var e: Dictionary = near[z]
		if float(e.gap) == 0.0:
			var b: Rect2 = e.box
			parts.append("%s SUPRAPUS %.0fx%.0f px (x %.0f..%.0f, y %.0f..%.0f)" % [
				z, b.size.x + 1.0, b.size.y + 1.0, b.position.x, b.end.x,
				b.position.y, b.end.y])
		else:
			parts.append("%s aer %.1f px" % [z, float(e.gap)])
	return ", ".join(parts) if not parts.is_empty() else "nicio zona in raza"


## Raza de atingere masurata pe o raza libera de alti vecini (primul punct,
## din centru spre `dir`, care nu mai raspunde cu zona butonului).
func _measured_radius(tc: TouchControls, zone: String, dir: Vector2) -> float:
	var c := tc.button_disc(zone).get_center()
	var r := 0.0
	while r < 400.0 and tc.call("_zone_at", c + dir * r) == zone:
		r += 0.5
	return r


func _make_hud(vp_size: Vector2i) -> Array:
	var vp := SubViewport.new()
	vp.size = vp_size
	vp.disable_3d = true
	add_child(vp)
	var hud := RaceHUD.new()
	vp.add_child(hud)
	hud.set_info(5, 6, 1, 3, 142.0, "00:05.5", "00:56.7")
	hud.set_turbo(0.6, false)
	return [vp, hud]


## Elementele care conteaza: bara insasi (jgheabul pe care il evidentiaza
## turul) si randul ei intreg (fulger + jgheab + etichetele vizibile).
func _bar_rects(hud: RaceHUD) -> Dictionary:
	var holder := (hud.get("_charge_bg") as Control).get_parent() as Control
	var row := Rect2()
	for ch in holder.get_children():
		var c := ch as Control
		if c.visible:
			row = c.get_global_rect() if row.size == Vector2.ZERO \
				else row.merge(c.get_global_rect())
	return {"jgheab": hud.turbo_bar_rect(), "rand": row}


## Starile randului barii. Etichetele de mod (GHOST, CHALLENGE) stau pe
## ACELASI rand cu bara, deci il latesc: provocarea cu cel mai lung titlu si cel
## mai lung progres e cazul cel mai rau (pe 1280 intra si ea in zone, inainte
## de #719).
const BAR_STATES := ["cursa", "fantoma", "provocare"]

## Bara de pe telefon si de pe 1280x720, judecata pe device: aici nu are voie
## sa se miste nici un pixel (masurata inainte de #719).
const JUDGED_ON_DEVICE := {
	Vector2i(1280, 720): Rect2(510.5, 654.0, 300.0, 22.0),
	Vector2i(1558, 720): Rect2(649.5, 654.0, 300.0, 22.0),
}


func _set_bar_state(hud: RaceHUD, state: String) -> void:
	hud.set_ghost_time(192400 if state == "fantoma" else 0)
	if state == "provocare":
		hud.set_challenge("NO TUK-TUK HITS")
		hud.set_challenge_progress("LAP 3: 12 PLATES")
	else:
		(hud.get("_challenge_label") as Control).visible = false


## Verifica un rand al barii fata de zone; intoarce numarul de esecuri.
func _guard_bar(tc: TouchControls, what: String, r: Rect2) -> int:
	var near := _touch_near(tc, r, MIN_GAP + 28.0)
	var bad := false
	for z: String in near:
		if float(near[z].gap) < MIN_GAP:
			bad = true
	print("   %-22s %s -> %s %s" % [what, _fmt_rect(r), _fmt_near(near),
		"<<< PICA (aer minim %.0f px)" % MIN_GAP if bad else "OK"])
	return 1 if bad else 0


func _check_hud_layout() -> int:
	var fail := 0
	print("")
	print("== HUD fata de zonele de atingere, la marimile logice (#719)")
	print("   (aer minim %.0f px; „nicio zona in raza\" = peste %.0f px)" % [
		MIN_GAP, MIN_GAP + 28.0])
	var fresh := {}
	for entry in LAYOUT_SIZES:
		var px: Vector2i = entry[0]
		var made := _make_hud(px)
		var vp: SubViewport = made[0]
		var hud: RaceHUD = made[1]
		await _frames(3)
		var tc := hud.touch_controls()
		print("")
		print("-- %dx%d  %s" % [px.x, px.y, entry[1]])
		var radii := []
		for zr in [["left", Vector2.UP], ["right", Vector2.UP], ["brake", Vector2.LEFT],
				["gas", Vector2.DOWN], ["turbo", Vector2.UP], ["drift", Vector2.UP]]:
			var disc := tc.button_disc(zr[0])
			radii.append("%s (%.0f,%.0f) r%.0f/%.0f" % [zr[0],
				disc.get_center().x, disc.get_center().y, disc.size.x * 0.5,
				_measured_radius(tc, zr[0], zr[1])])
		print("   zone (centru, raza desenata/de atingere): " + "; ".join(radii))
		for state: String in BAR_STATES:
			_set_bar_state(hud, state)
			await _frames(3)
			var bars := _bar_rects(hud)
			if state == "cursa":
				fresh[px] = bars.jgheab
			fail += _guard_bar(tc, "%s: bara (jgheab)" % state, bars.jgheab)
			fail += _guard_bar(tc, "%s: randul barii" % state, bars.rand)
		if JUDGED_ON_DEVICE.has(px):
			var want: Rect2 = JUDGED_ON_DEVICE[px]
			var got: Rect2 = fresh[px]
			var same := got.position.is_equal_approx(want.position) 				and got.size.is_equal_approx(want.size)
			if not same:
				fail += 1
			print("   bara ca pe device: %s (astept %s) %s" % [_fmt_rect(got),
				_fmt_rect(want), "OK" if same else "<<< S-A MUTAT"])
		vp.queue_free()

	# Redimensionarea (rotire, fereastra trasa pe desktop): ACELASI HUD trecut
	# prin toate marimile trebuie sa ajunga unde ajunge unul nou-nascut acolo.
	# Altfel bara s-ar aseza bine doar la pornire.
	print("")
	var made := _make_hud(LAYOUT_SIZES[0][0])
	var vp: SubViewport = made[0]
	var hud: RaceHUD = made[1]
	await _frames(3)
	var order: Array[Vector2i] = [Vector2i(960, 720), Vector2i(1558, 720),
		Vector2i(900, 720), Vector2i(1036, 720), Vector2i(1280, 720)]
	for px in order:
		vp.size = px
		await _frames(3)
		var got := hud.turbo_bar_rect()
		var want: Rect2 = fresh[px]
		var same := got.position.is_equal_approx(want.position) 			and got.size.is_equal_approx(want.size)
		if not same:
			fail += 1
		print("   redimensionat la %dx%d: %s %s" % [px.x, px.y, _fmt_rect(got),
			"OK" if same else "<<< difera de HUD-ul nou (%s)" % _fmt_rect(want)])
	vp.queue_free()
	return fail


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
