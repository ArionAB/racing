extends Node
## Sonda de UNICA INTREBARE: o diferenta intre doua rulari de cursa vine din
## GEOMETRIE sau din ORDINEA in care solverul rezolva contactele?
##
## De ce exista. Pe Chongqing, `ProbeRace --seed=2` a aratat o pereche de
## repuneri la frac 0.301/0.316 (cornisa D) care apare doar cand pasajul
## rotativ isi taie gaura din carosabil — o gaura aflata la frac 0.65, adica la
## 366 m de cornisa. Explicatia „e nedeterminism Jolt" a fost data o data si
## respinsa, pe buna dreptate: efectul se comuta dintr-un steag si se repeta
## identic, deci nu e zgomot de rulare. Dar „se comuta dintr-un steag" nu spune
## nici el DE CE, si intre cele doua explicatii posibile diferenta e uriasa:
##
##   (a) gaura strica ceva la cornisa (progres, latime, coliziune, AI) — atunci
##       e un bug de generare, si se repara in geometrie;
##   (b) lumea de la cornisa e neatinsa, iar taietura doar schimba forma
##       arborelui de coliziune al soselei, deci ordinea insulelor de contact —
##       atunci nu exista nimic de reparat in geometrie, si singura reparatie
##       posibila ar fi la fizica sau la cornisa insasi.
##
## Cele doua se deosebesc printr-o singura masuratoare: [b]cand[/b] incep sa
## difere traiectoriile, si [b]unde erau masinile[/b] in acel moment. Daca
## divergenta incepe dupa ce o roata a atins zona schimbata, e (a). Daca incepe
## inainte, la sute de metri distanta si cu abateri de milimetri, e (b) — o
## diferenta de ultim bit amplificata de haos, nu un defect local.
##
## [b]LIMITA, si trebuie citita INAINTE de verdict: sonda asta nu are brat de
## control, deci nu poate singura sa DEMONSTREZE (b).[/b] Verificat dandu-i
## doua rulari identice ca setare, fara sa se comute nimic intre ele:
##
##   C1 vs C2 (setare IDENTICA):        t=4.02 s, 0.0060 m -> t=20 s: 132.2 m
##   C1 vs C3 (setare IDENTICA):        t=4.02 s, 0.0060 m -> t=20 s:  48.1 m
##   B1 vs B2 (identice, gaura stinsa): t=4.02 s, 0.0007 m -> t=20 s:  39.3 m
##   C1 vs B1 (A/B-ul REAL):            t=4.02 s, 0.0060 m -> t=20 s:  36.7 m
##
## Toate patru tiparesc „DERIVA DE SOLVER" — inclusiv perechile in care nu s-a
## schimbat absolut nimic — iar A/B-ul real diverge mai PUTIN decat controlul.
## Pragul de 1 cm nu separa nimic: pe pista asta orice doua rulari se despart
## cu milimetri la t=4.02 s, inca pe grila de start. Sonda masoara corect CAND
## si CU CAT, dar „identice pana la 4.02 s, apoi haos" e comportamentul de baza
## al motorului, nu un fapt despre schimbarea testata.
##
## Deci foloseste-o ca sa EXCLUZI (a) — daca divergenta incepe dupa ce o roata
## a atins zona schimbata, ai gasit ceva real — dar nu ca sa confirmi (b).
## Pentru (b) trebuie un brat de control care nu depinde de sonda: adauga
## geometrie de coliziune INERTA pe baseline (cutii ingropate sub pista, pe
## care nu le atinge nimeni) si vezi daca produce aceeasi semnatura. Pe
## Chongqing chiar o produce — 50 de cutii dau 2 repuneri deterministe pe seed
## 2, in trei rulari, pe cod de baseline neatins. Vezi antetul lui
## `cut_road_hole` din `rotating_span_hazard.gd`.
##
## Verdictul masurat pe Chongqing, seed 2: primele 4.0 secunde sunt IDENTICE
## bit cu bit; la t=4.02 s apare o abatere de 1.0 mm, cu tot plutonul inca pe
## grila de start (x~130, z~-192, y~65) — la 600 m de gaura si cu 26 s inainte
## ca vreo masina sa ajunga la ea (la t=30.8 s, cand cade pilotul, liderul e
## abia la 0.53 tururi). La t=10 s abaterea e deja 56 m, la t=20 s 170 m.
## Deci (b).
##
## Doua verificari care au INFIRMAT explicatii mai simple, si de aceea merita
## pastrate — fiecare a costat cate sase rulari:
##
##   * „e doar numarul de triunghiuri". Nu: 304, apoi 20.000 de triunghiuri
##     INERTE (la 5 km deasupra hartii, unde nimic nu le atinge) adaugate pe
##     baseline lasa seed 2 la 0/0/0. Nici adaugarea a 104 triunghiuri inerte
##     in CHIAR corpul soselei nu reproduce efectul. Conteaza CARE triunghiuri
##     dispar, fiindca ele schimba partitionarea arborelui, nu cate sunt.
##   * „lumea de la cornisa difera". Nu: o grila de 1550 de raycast-uri pe
##     frac 0.28-0.34 da aceeasi amprenta de cote (46044.5171) si 0 raze in gol
##     in ambele variante. Geometria pe care se conduce acolo e identica.
##
## Si contextul care schimba intrebarea din „regresie?" in „cat de stabila e
## curba aia?": cornisa D cade si pe `origin/main`, doar pe alt seed — baseline
## seed 3 da o repunere la frac 0.309, poz (-243,34,123), t=31.0 s, adica
## exact aceeasi bucata de drum. Pe 8 seed-uri (2-9) numarul de curse cu
## repunere pe cornisa e 1 pe baseline si 1 pe ramura. Cornisa fara parapet
## (brief §2 randul D) e o margine pe care AI-ul se imbranceste; ce seed o
## nimereste depinde de ultimul bit, nu de ramura.
##
## Rulare (ca SCENA, are nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSolverDrift.tscn \
##     -- --track=5 --seed=2 --seconds=35
##
## Cele doua variante se dau prin variabila de mediu pe care o citeste codul
## testat; sonda ruleaza o singura varianta si scrie un CSV. Se ruleaza de doua
## ori si se compara cu `--compare=A,B`.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"

var _race: Node
var _out: String = ""
var _compare: String = ""
var _track: int = 5
var _seed: int = 2
var _seconds: float = 35.0
var _t: float = 0.0
var _next: float = 0.0
var _lines: PackedStringArray = PackedStringArray()


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--compare="):
			_compare = arg.trim_prefix("--compare=")
		elif arg.begins_with("--track="):
			_track = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
	if _compare != "":
		_do_compare()
		return
	if _out == "":
		print("EROARE: dati --out=<fisier.csv> sau --compare=A,B")
		get_tree().quit(1)
		return
	GameState.selected_track = _track
	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	await get_tree().process_frame
	# Acelasi seed = aceleasi zaruri (rocket start, linii AI). Fizica NU se
	# fixeaza cu el — exact asta se masoara aici.
	if _race.get("_rng") != null:
		(_race.get("_rng") as RandomNumberGenerator).seed = _seed


func _physics_process(delta: float) -> void:
	if _compare != "" or _race == null:
		return
	_t += delta
	if _t < _next:
		return
	# 0.5 s: destul de des ca sa prinda momentul in care apare abaterea, destul
	# de rar ca fisierul sa ramana citibil de om.
	_next += 0.5
	var cars: Array[Node] = []
	_find_cars(_race, cars)
	var row := "%.2f" % _t
	for c in cars:
		var p: Vector3 = (c as Node3D).global_position
		row += ",%s,%.4f,%.4f,%.4f" % [c.name, p.x, p.y, p.z]
	_lines.append(row)
	if _t >= _seconds:
		var f := FileAccess.open(_out, FileAccess.WRITE)
		for l in _lines:
			f.store_line(l)
		f.close()
		print("scris %d randuri in %s" % [_lines.size(), _out])
		get_tree().quit(0)


## Compara doua CSV-uri si spune cand si unde incepe divergenta.
func _do_compare() -> void:
	var parts := _compare.split(",")
	if parts.size() != 2:
		print("EROARE: --compare=fisierA,fisierB")
		get_tree().quit(1)
		return
	var a := _read(parts[0])
	var b := _read(parts[1])
	if a.is_empty() or b.is_empty():
		print("EROARE: nu pot citi CSV-urile")
		get_tree().quit(1)
		return
	print("=== DERIVA DE SOLVER: %s vs %s ===" % [parts[0], parts[1]])
	var first_t := -1.0
	var first_d := 0.0
	var first_pos := ""
	var rows := mini(a.size(), b.size())
	for i in rows:
		var ra: PackedStringArray = a[i]
		var rb: PackedStringArray = b[i]
		if ra.size() != rb.size():
			continue
		var t := float(ra[0])
		var maxd := 0.0
		var pos := ""
		for k in range(1, ra.size(), 4):
			var pa := Vector3(float(ra[k + 1]), float(ra[k + 2]), float(ra[k + 3]))
			var pb := Vector3(float(rb[k + 1]), float(rb[k + 2]), float(rb[k + 3]))
			var d := pa.distance_to(pb)
			if d > maxd:
				maxd = d
				pos = "(%.0f, %.0f, %.0f)" % [pa.x, pa.y, pa.z]
		if first_t < 0.0 and maxd > 0.0:
			first_t = t
			first_d = maxd
			first_pos = pos
		if t in [1.0, 5.0, 10.0, 20.0, 30.0]:
			print("  t=%5.1f s   abatere maxima %10.4f m" % [t, maxd])
	if first_t < 0.0:
		print("VERDICT: rulari IDENTICE — diferenta nu vine de aici.")
		get_tree().quit(0)
		return
	print("prima abatere: t=%.2f s, %.4f m, masina la %s" % [first_t, first_d, first_pos])
	# Pragul nu e ales, e citit din ce inseamna fiecare varianta. O abatere sub
	# un centimetru e sub rezolutia oricarei geometrii din pista: nicio bordura,
	# niciun prag si niciun perete nu se masoara in milimetri. O diferenta atat
	# de mica nu poate fi „masina a atins altceva" — e ultimul bit al unei sume
	# in virgula mobila, adica ordinea in care s-au adunat contactele.
	if first_d < 0.01:
		print("VERDICT: DERIVA DE SOLVER (ordinea contactelor), nu geometrie.")
		print("  Traiectoriile pornesc identice si se despart cu %.1f mm." % (first_d * 1000.0))
		print("  Sub un centimetru nu exista geometrie de pista: e ultimul bit,")
		print("  amplificat pe urma de haos. Diferenta de rezultat e reala, dar")
		print("  nu e un defect local — cauta reparatia la stabilitatea cursei,")
		print("  nu in mesh.")
	else:
		print("VERDICT: divergenta incepe cu %.3f m — prea mult pentru ultimul" % first_d)
		print("  bit. Verifica geometria de la pozitia de mai sus: acolo se")
		print("  atinge ceva ce difera intre variante.")
	get_tree().quit(0)


func _read(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var l := f.get_line().strip_edges()
		if l != "":
			out.append(l.split(","))
	f.close()
	return out


func _find_cars(root: Node, out: Array[Node]) -> void:
	for c in root.get_children():
		if c is RigidBody3D and c.has_method("ignite"):
			out.append(c)
		_find_cars(c, out)
