extends Node
## Unde sta ROATA fiecarui model fata de talpa colizerului.
##
## Intrebarea la care raspunde: de ce par autobuzul si pompierii ca "zboara" la
## coborare, desi sonda de desprindere (tools/probe_slope_hop.gd) arata ca ei
## desprind roatele CEL MAI PUTIN dintre toate masinile?
##
## Ipoteza verificata aici: masina nu zboara, doar PARE, fiindca modelul e
## desenat mai sus decat suprafata pe care se sprijina corpul fizic. Colizerul e
## o cutie de inaltime FIXA (1.0 m, centru la y=0.6) pentru toate masinile, deci
## talpa lui e mereu la y=0.1 fata de origine. Modelele insa au rotile la
## inaltimi diferite dupa scalare. Daca roata unui model sta mai sus de 0.1,
## intre cauciuc si asfalt ramane un gol permanent — invizibil pe drept, evident
## cand masina se inclina peste o creasta si golul se deschide in fata.
##
## Ruleaza CA SCENA (are nevoie de autoload-ul GameState):
##   godot --headless --path . res://tools/ProbeRideHeight.tscn

## Talpa colizerului fata de originea masinii: pozitia cutiei (0.6) minus
## jumatate din inaltimea ei (1.0 / 2). Vezi Car._ready / Car.apply_data.
const COLLIDER_BOTTOM: float = 0.6 - 0.5


func _ready() -> void:
	print("")
	print("=== Inaltimea rotilor fata de talpa colizerului ===")
	print("talpa colizerului e la y = %.2f m fata de originea masinii" % COLLIDER_BOTTOM)
	print("")
	print("%-14s %7s %8s %9s %9s %8s"
		% ["masina", "scala", "roata_y", "raza", "talpa_roti", "gol"])

	var worst := 0.0
	var worst_name := ""
	for i in GameState.CAR_DATA.size():
		var data := GameState.CAR_DATA[i] as CarData
		var info := _measure(data)
		if info.is_empty():
			print("%-14s  (fara model 3D — placeholder din cuburi)"
				% data.display_name)
			continue
		# Talpa cauciucului = centrul rotii minus raza, adica exact suprafata pe
		# care s-ar sprijini modelul daca ar fi el cel care atinge solul.
		var tyre_bottom: float = float(info.center_y) - float(info.radius)
		var gap := tyre_bottom - COLLIDER_BOTTOM
		if absf(gap) > absf(worst):
			worst = gap
			worst_name = data.display_name
		print("%-14s %7.3f %8.3f %9.3f %9.3f %+8.3f"
			% [data.display_name, data.model_scale, float(info.center_y),
				float(info.radius), tyre_bottom, gap])

	print("")
	print("gol > 0 = cauciucul e DEASUPRA talpii fizice: masina pluteste cu")
	print("          atatia metri, permanent. Se vede la inclinare, nu pe drept.")
	print("gol < 0 = cauciucul intra in asfalt (masina pare ingropata).")
	print("")
	print("cel mai mare decalaj: %s, %+.3f m" % [worst_name, worst])
	get_tree().quit(0)


## Raza si inaltimea rotii, dupa scalare — exact cum le calculeaza Car.
func _measure(data: CarData) -> Dictionary:
	if data.model == null:
		return {}
	var model := data.model.instantiate() as Node3D
	add_child(model)
	model.scale = Vector3.ONE * data.model_scale
	var found: Node3D = null
	for child in model.get_children():
		if child is Node3D and "wheel" in String(child.name).to_lower():
			found = child as Node3D
			break
	var out: Dictionary = {}
	if found != null:
		# Car foloseste `position.y * model_scale` si ca raza, si ca inaltime a
		# centrului rotii — presupunerea fiind ca roata sta pe sol.
		var center := found.position.y * data.model_scale
		out = {"center_y": center, "radius": maxf(0.15, center)}
	model.queue_free()
	return out
