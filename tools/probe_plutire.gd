extends Node
## Garda pentru prop-uri care PLUTESC. Scrisa dupa ce 12 mese s-au asezat cu cota
## din `_terrain_mesh_y`, care EXTRAPOLEAZA dincolo de panza de teren (masurat:
## intoarce 27.5 unde solul real e la -27.6). Nicio sonda n-a prins-o, fiindca
## mesele au `coliziune = "none"` si razele trec prin ele — s-a vazut abia cand
## cineva a deschis captura.
##
## Aici nu se cere coliziune pe prop: se trage o raza IN JOS din baza fiecarui
## prop vizibil si se cere sa gaseasca TEREN sub el, la o distanta rezonabila.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePlutire.tscn -- --track=6
const MAX_GOL := 4.0   ## metri de aer tolerati sub baza unui prop
## Ce ARE VOIE sa pluteasca: pasari, baloane, cabine de telecabina. Lista e scurta
## si explicita, ca sa nu devina o portita — orice adaugat aici trebuie sa aiba un
## motiv de lume, nu de convenienta.
const ZBURATOARE := ["Pigeon", "Balloon", "Balon", "Cabina", "Porumbel",
	# TARUSII baloanelor de pe cornisa (POI C). Nu e o portita: brief §2 POI C
	# cere explicit ca cele 3 baloane sa fie ancorate pe POLITE SAPATE IN
	# FALEZA, si scrie de ce — masurat cu tools/probe_balloon.gd, un cos pornit
	# de pe fundul vaii urca direct in panta si se infunda dupa 1 m din 30.
	# Deci tarusul STA IN PERETE prin cerinta, la 25-33 m, cu fundul vaii la
	# -30..-37 sub el. A-l cere "asezat pe teren" ar contrazice brief-ul.
	"Tarus", "Tether"]
## Grupuri care sunt STRUCTURA, nu obiecte asezate pe sol — vezi mai jos.
const ZIDURI := ["ZidulValeiRosii"]
## SUBGRUPURI-structura, dupa un fragment din CALEA nodului (nu doar numele
## grupului de nivel 1, fiindca de la integrare incoace structurile stau in
## subarbori: `DecorManual/F2_Sala1/...`).
##
## Fiecare intrare e o STIVA sau o SAPATURA, adica geometrie care prin
## constructie nu se sprijina pe teren:
##   Sala1/Sala2/Gat/Gura  — tavanul, coloanele si alcovele orasului subteran
##                           (POI F): sunt INTERIORUL unei caverne, deci stau
##                           deasupra podelei prin definitie;
##   Chei de scara         — usile si porumbarele SAPATE IN FALEZA (POI C):
##                           brief §2 le cere pe polite in perete, explicit NU
##                           pe fundul vaii;
##   Strate                — benzile de roca ale canionului (POI D): sunt
##                           straturi in perete, nu obiecte puse jos;
##   Coroana               — coroana stancii goale (POI G).
## Tot lista explicita ramane, si tot cere motiv de LUME: ce se adauga aici
## trebuie sa fie structura, nu un prop care se intampla sa pluteasca.
const STRUCTURI_CALE := [
	"F1_Gura", "F2_Sala1", "F3_Gat", "F4_Sala2",
	"Chei de scara", "Strate", "StancaCoroana",
	# Peretii si grohotisul canionului (POI D) si interiorul stancii goale
	# (POI G): tot stive de module de faleza, ca `ZidulValeiRosii`.
	"BuzaRapei", "Faleza", "Grohotis", "PereteInterior", "Creasta", "Ferestre",
]

func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	var only := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			only = int(a.trim_prefix("--track="))
	var t := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	# Panza de teren: singurul lucru pe care are voie sa stea un prop. Cutia
	# plata de la -27.6 e plasa de siguranta a lumii, nu sol (vezi track.gd).
	var terrain_rid := RID()
	for c in t.get_children():
		if str(c.name) == "TerrainBody":
			terrain_rid = (c as StaticBody3D).get_rid()
	if terrain_rid == RID():
		print("EROARE: nu am gasit TerrainBody, verdictul n-ar insemna nimic")
		get_tree().quit(1)
		return
	var bad := 0
	var checked := 0
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if not mi.visible or mi.mesh == null:
			continue
		# doar prop-uri din decor, nu carosabil/teren
		var owner_nm := ""
		var grup := ""
		var cale := ""
		var ascuns := false
		var up: Node = n
		while up != null:
			# `mi.visible` e doar steagul PROPRIU: un grup intreg stins
			# (`ZidulRosuDeDeparte`, mesele ascunse in runda 28) lasa copiii cu
			# visible = true, desi pe ecran nu e nimic. Ce nu se randeaza nu
			# poate sa pluteasca in cadru.
			if up is Node3D and not (up as Node3D).visible:
				ascuns = true
			if str(up.name).begins_with("DecorManual"):
				owner_nm = str(n.name)
				break
			if up.get_parent() != null and str(up.get_parent().name).begins_with("DecorManual"):
				grup = str(up.name)
			cale = str(up.name) + "/" + cale
			up = up.get_parent()
		if owner_nm == "" or ascuns:
			continue
		# ZIDURILE nu stau pe sol, sunt sol. `ZidulValeiRosii` e peretele Vaii
		# Rosii, construit ca stiva de module de faleza (y de la -143 la +250 prin
		# constructie); a-l cere "asezat pe teren" n-are inteles — modulul de
		# deasupra sta pe cel de dedesubt, nu pe nisip. Lista e explicita, ca sa
		# nu devina o portita: orice grup adaugat aici trebuie sa fie o
		# STRUCTURA, nu un obiect pus in lume.
		if grup in ZIDURI:
			continue
		var e_structura := false
		for frag in STRUCTURI_CALE:
			if cale.contains(frag):
				e_structura = true
				break
		if e_structura:
			continue
		var aabb := mi.get_aabb()
		var base: Vector3 = mi.global_transform * (aabb.position + Vector3(
			aabb.size.x * 0.5, 0.0, aabb.size.z * 0.5))
		var zboara := false
		for z in ZBURATOARE:
			if owner_nm.contains(z):
				zboara = true
				break
		if zboara:
			continue
		checked += 1
		# Raza porneste DE SUS DE TOT si accepta DOAR panza de teren.
		#
		# Prima versiune pornea de la baza + 1 m si lua prima lovitura. Pentru
		# cele 55 de piese cu hull de coliziune asta inseamna ca raza pleca din
		# INTERIORUL piesei, ii iesea prin fund (trimesh-urile noastre au
		# backface_collision) si cadea pe plasa de siguranta de la -27.6 —
		# terenul dintre ele nici nu era intrebat. Rezultatul: 17 piese asezate
		# corect in runda 29 erau raportate "in afara panzei", si numarul crestea
		# tocmai cand asezarea se imbunatatea. Cine sta pe teren se decide fata de
		# TEREN, deci se sare peste orice altceva.
		var sus := base + Vector3.UP * 300.0
		var q := PhysicsRayQueryParameters3D.create(sus, base + Vector3.DOWN * 400.0)
		q.collide_with_areas = false
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != terrain_rid and guard < 32:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if hit.is_empty() or hit["rid"] != terrain_rid:
			print("  %s: FARA TEREN dedesubt (baza y=%.1f)" % [owner_nm, base.y])
			bad += 1
		else:
			var sol: float = float(hit["position"].y)
			var gol: float = base.y - sol
			if gol > MAX_GOL:
				print("  %s: pluteste %.1f m (baza y=%.1f, sol y=%.1f) | %s" % [
					owner_nm, gol, base.y, sol, cale])
				bad += 1
	print("")
	print("prop-uri verificate: %d | care plutesc: %d" % [checked, bad])
	print("VERDICT: %s" % ("OK" if bad == 0 else "PROBLEMA"))
	get_tree().quit(1 if bad > 0 else 0)
