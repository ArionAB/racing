@tool
class_name EruptionCycle
extends Node3D
## METRONOMUL VULCANULUI (Stromboli, docs/track_briefs/stromboli.md §3).
##
## Un nod mic, fara geometrie, care bate ritmul intregii piste: la fiecare
## `period` secunde vine bubuitul, apoi telegraph-ul, apoi pulsul de bombe.
## Tot ce e ciclic pe pista se aboneaza la el, in loc sa-si tina fiecare
## propriul ceas.
##
## DE CE UN NOD SEPARAT, si nu cate un ciclu per hazard:
##
## Bombele sunt `RockfallHazard`-uri cu traseu, si fiecare are deja `period` +
## `phase`. Lasate pe cont propriu, cele 3-5 trasee ar bate fiecare in ritmul
## lui: pe pista ar ploua cu pietre continuu, iar jucatorul n-ar avea ce sa
## invete. Erupția reala e un PULS — liniste lunga, apoi cateva secunde in
## care sar toate. Aia se poate invata, deci e mecanica, nu taxa.
##
## Nodul asta face un singur lucru: la `_ready` ia toate hazardele dintr-un
## grup si le scrie ACELASI `period` si `phase`-uri asezate manual in
## fereastra de puls. Nu tine referinte la ele in fiecare cadru, nu le
## proceseaza — doar le sincronizeaza ceasurile o data.
##
## SEMNALUL `erupted` e pentru ce nu e rockfall: particulele de cenusa,
## tremurul de camera, sunetul. Se emite cu `telegraph` secunde INAINTE de
## puls, ca sa fie avertisment, nu surpriza.
##
## Calibrarea (brief §3): perioada ~45 s, telegraph ~3 s.

## Cat dureaza un ciclu complet, in secunde.
@export var period: float = 45.0:
	set(value):
		period = maxf(value, 4.0)
		_resync()

## Cu cat timp inainte de puls se anunta erupția (bubuit + tremur + coloana).
@export var telegraph: float = 3.0:
	set(value):
		telegraph = clampf(value, 0.0, period * 0.5)

## Cat de lunga e fereastra in care pleaca bombele. Toate traseele isi asaza
## `phase` in intervalul asta, distribuite egal — asa pleaca "aproape odata",
## dar nu toate in acelasi cadru (ceea ce ar arata mecanic).
@export var burst_window: float = 6.0:
	set(value):
		burst_window = maxf(value, 0.0)
		_resync()

## Grupul din care se iau hazardele de sincronizat. Bombele se pun in el din
## editor (Node → Groups), nu se cauta dupa nume sau dupa tip: asa poate intra
## in puls si altceva decat un rockfall, fara sa se atinga codul.
@export var hazard_group: StringName = &"eruption_bombs"

## Se emite cu `telegraph` secunde inaintea fiecarui puls.
signal erupted(index: int)

## Unde rasare coloana de cenusa (in coordonatele pistei). ZERO = fara
## coloana. E singurul semnal al eruptiei vizibil de ORIUNDE de pe pista —
## bombele se vad doar pe Sciara, bubuitul nu spune de unde vine.
@export var column_position: Vector3 = Vector3.ZERO

var _clock: float = 0.0
var _fired: int = -1
var _column: GPUParticles3D = null


func _ready() -> void:
	# AMANAT, nu direct: bombele din grup sunt construite de pista din
	# HazardMarker-e in _ready-ul EI, care ruleaza dupa al nostru (parintele
	# isi face _ready dupa copii). Un _resync imediat ar gasi grupul gol si
	# fiecare bomba ar bate in ritmul ei — exact ce interzice antetul.
	_resync.call_deferred()
	if Engine.is_editor_hint():
		set_process(false)


func _process(delta: float) -> void:
	_clock = fposmod(_clock + delta, period)
	# Indexul ciclului curent nu conteaza pentru gameplay, dar il trimitem ca
	# sa poata cineva alterna efecte (coloana mai mare la fiecare al treilea).
	var warn := fposmod(period - telegraph, period)
	var idx := int(floor((_clock + telegraph) / period))
	if _clock >= warn and _fired != idx:
		_fired = idx
		erupted.emit(idx)
		_boom()
	elif _clock < warn:
		_fired = -1


## Teatrul propriu al pulsului: bubuitul (2D — vine "de peste tot", exact ca
## in realitate cand bubuie muntele) si coloana de cenusa din crater. Tremurul
## de ecran NU e aici: e feedback de jucator si il leaga race.gd de semnal.
func _boom() -> void:
	AudioManager.play_sfx(&"avalanche_hit", 0.55)
	if column_position != Vector3.ZERO:
		if _column == null:
			_column = _build_column()
			add_child(_column)
			_column.global_position = column_position
		_column.restart()


## Coloana: un burst de fum gri care urca ~50 m si se destrama. UN emitator,
## 40 de particule (limita de count din CLAUDE.md), quad-uri billboard pe un
## material static — nimic per-cadru cand nu erupe.
func _build_column() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "ColoanaCenusa"
	p.amount = 40
	p.one_shot = true
	p.explosiveness = 0.85
	p.lifetime = 7.0
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 7.0
	pm.initial_velocity_min = 10.0
	pm.initial_velocity_max = 16.0
	# Cenusa URCA (aer fierbinte), apoi franata de damping se destrama sus.
	pm.gravity = Vector3(0.6, 2.2, 0.0) # usor aplecata: vantul temei
	pm.damping_min = 0.4
	pm.damping_max = 0.9
	pm.scale_min = 2.4
	pm.scale_max = 4.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.42, 0.40, 0.40, 0.85))
	ramp.set_color(1, Color(0.62, 0.60, 0.58, 0.0))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	pm.color_ramp = ramp_tex
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(7.0, 7.0)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	p.draw_pass_1 = quad
	return p


## Scrie acelasi `period` si `phase`-uri esalonate pe toate hazardele din grup.
##
## `phase` se masoara de la inceputul ciclului, iar traseele trebuie sa ajunga
## PESTE drum in fereastra de puls — nu sa PLECE atunci. De-asta faza se
## calculeaza scazand timpul de traversare al fiecarui traseu, cand hazardul il
## expune (`_cross_time`). Daca nu-l expune, plecarea e destul de aproape.
func _resync() -> void:
	if not is_inside_tree():
		return
	var nodes := get_tree().get_nodes_in_group(hazard_group)
	if nodes.is_empty():
		return
	var n := nodes.size()
	for i in n:
		var h := nodes[i] as Node
		if h == null:
			continue
		# Esalonare egala in fereastra: prima bomba la inceputul ei, ultima la
		# capat. Cu o singura bomba, pleaca fix la inceput.
		var offset := 0.0 if n == 1 else burst_window * float(i) / float(n - 1)
		# Pulsul trebuie sa prinda bomba DEASUPRA drumului, nu la plecare:
		# scadem timpul ei de traversare, cand hazardul il expune.
		var cross := 0.0
		if h.has_method("cross_time"):
			cross = float(h.call("cross_time"))
		if "period" in h:
			h.set("period", period)
		if "phase" in h:
			# Faza e FRACTIE din perioada (contractul RockfallHazard), "cu cat
			# e decalat ceasul propriu fata de al nostru". Pulsul cade la
			# sfarsitul ciclului (dupa telegraph, la trecerea prin zero), deci
			# bomba i (offset in fereastra) trebuie sa fie peste drum la
			# t = offset — adica pleaca la offset - cross.
			h.set("phase", fposmod(cross - offset, period) / period)
