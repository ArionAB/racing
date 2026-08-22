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

var _clock: float = 0.0
var _fired: int = -1


func _ready() -> void:
	# In editor nu batem ceasul, dar sincronizarea o facem: asa vezi in
	# Inspector ce phase a primit fiecare bomba, fara sa rulezi jocul.
	_resync()
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
	elif _clock < warn:
		_fired = -1


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
		if "period" in h:
			h.set("period", period)
		if "phase" in h:
			# Faza e "cu cat e decalat ceasul propriu fata de al nostru".
			# Pulsul cade la sfarsitul ciclului (dupa telegraph), deci bombele
			# pleaca de acolo.
			h.set("phase", fposmod(period - telegraph + offset, period))
