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

	# A TREIA GARDA: GAZUL CARE SE SUBINTELEGE. Toate comenzile de actiune stau
	# sub acelasi deget mare drept, deci nu pot fi tinute odata cu ^. Daca TURBO
	# sau DRIFT n-ar implica gaz, ai arde bara stand pe loc, respectiv drift-ul
	# s-ar stinge singur sub `drift_min_speed`. Se masoara pe `PlayerController`
	# real, nu pe o copie a regulii.
	print("")
	var pc := PlayerController.new()
	add_child(pc)
	var throttle_cases := [
		["doar GAZ", {"gas": true}, 1.0],
		["doar TURBO", {"turbo": true}, 1.0],
		["doar DRIFT", {"drift": true}, 0.0],
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

	print("")
	print("VERDICT: %s (%d esecuri)" % ["OK" if fail == 0 else "PICA", fail])
	get_tree().quit(1 if fail > 0 else 0)
