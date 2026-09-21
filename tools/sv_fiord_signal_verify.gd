extends Node
## Sonda ad-hoc, de folosinta unica: verifica ca TunnelSignalHazard construit
## pe Track16 real functioneaza (lampa, autocar ascuns la start, is_red()
## comuta la timpul asteptat, AI_GROUP contine hazardul).
const TRACK := "res://scenes/tracks/Track16.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var t := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame

	var sig := t.get_node_or_null("Hazarduri/SemaforTunel") as TunnelSignalHazard
	if sig == null:
		print("EROARE: SemaforTunel nu a fost gasit")
		get_tree().quit(1)
		return
	print("SemaforTunel gasit: period=%.1f clear_hold=%.1f tunnel_length=%.1f bus_speed=%.1f"
		% [sig.period, sig.clear_hold, sig.tunnel_length, sig.bus_speed])
	print("cross_time=%.2fs red_hold=%.2fs green_hold=%.2fs" % [
		sig.cross_time(), sig.red_hold(), sig.green_hold()])
	print("in grupul AI_GROUP: %s" % sig.is_in_group(TunnelSignalHazard.AI_GROUP))
	print("lampa: %s  lit initial=%d" % [sig.lamp, sig.lamp.lit() if sig.lamp else -1])
	await get_tree().physics_frame
	await get_tree().physics_frame
	var bus := sig.bus()
	print("bus: %s  hidden=%s" % [bus, bus.is_hidden() if bus else "N/A"])
	print("ai_decision_point=%s" % sig.ai_decision_point())

	# Nisele
	for i in 3:
		var nisa := t.get_node_or_null("Hazarduri/Nisa%d" % i)
		print("Nisa%d: %s  colliding_bodies_ok=%s" % [i, nisa, nisa is StaticBody3D])

	# Simulam timpul: verificam ca is_red() comuta corect in jurul green_hold().
	var gh := sig.green_hold()
	print("\n--- simulare avans manual al ceasului (fara fizica reala) ---")
	sig._clock = gh - 0.5
	print("t=%.1f (inainte de rosu) is_red=%s" % [sig._clock, sig.is_red()])
	sig._clock = gh + 0.5
	print("t=%.1f (dupa rosu) is_red=%s" % [sig._clock, sig.is_red()])
	sig._clock = gh + sig.clear_hold + 0.5
	print("t=%.1f (in tranzit) is_red=%s is_transit=%s" % [sig._clock, sig.is_red(), sig.is_transit()])

	get_tree().quit(0)
