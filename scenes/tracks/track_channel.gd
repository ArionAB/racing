@tool
class_name TrackChannel
extends Marker3D
## O taietura de apa peste sosea, asezata VIZUAL: tragi nodul langa drum,
## bifezi Regenerate pe radacina pistei, si golul apare acolo.
##
## Nodul e o DECLARATIE, ca [TerrainPeak] si [TrackBranch]: [Track] aduna
## nodurile astea si le trece prin acelasi [code]_resolve_channels()[/code] pe
## care il folosesc si pistele scrise in cod (vezi Track09._channel_specs).
## Saparea terenului, golul din asfalt, suprafata de apa si podul (sau
## trambulina) raman EXACT aceleasi — o singura implementare, doua feluri de a
## o hrani.
##
## [b]FRACTIA NU SE DECLARA.[/b] Se citeste din POZITIA nodului: canalul taie
## soseaua la punctul copt cel mai apropiat de el. Muti nodul, se mata si
## taietura. Acelasi motiv ca la capetele scurtaturii ([TrackBranch]): o
## fractie scrisa de mana ramane in urma la prima ajustare a traseului, iar
## atunci golul din sosea si apa de sub el ajung in locuri diferite.
##
## Ca sa vezi unde cade taietura inainte de primul Regenerate, crucea gizmo-ului
## se intinde cat [member reach] — adica exact cat tine albia in fiecare parte.
##
## [b]DOUA FELURI DE TRECERE, se alege una.[/b]
##   [member jump] = false  travee ridicatoare la interval fix ([LiftBridgeHazard]) —
##                          asteptare si sincronizare, ca stramtoarea Okinawei
##   [member jump] = true   golul ramane gol si primeste o trambulina pe toata
##                          latimea: se trece din saritura, cu viteza
##
## [b]LATIMEA GOLULUI NU E LIBERA[/b], si asta e capcana care costa cel mai mult
## timp daca o afli tarziu. Cu [member jump] pornit, [member gap] trebuie sa
## treaca de DOUA masuratori, in ordinea asta:
##   1. [code]tools/ProbeJump.tscn[/code] — de la ce viteza se trece golul.
##      Masinile din garaj au plafoane intre 30 si 37 m/s (autobuzul 30), plus
##      11 m/s cat arde turbo. Un prag peste plafonul celei mai lente inseamna
##      ca ea NU trece niciodata.
##   2. [code]tools/ProbeRace.tscn[/code] — arbitrul. Daca AI-ul se aduna in
##      albie, se vede aici ca repuneri si blocaje, nu in sonda de saritura.
## Masurat pe Alpii (august 2026): la 36 m gol, autobuzul si pompierii cadeau la
## fiecare tur — 16 repuneri intr-o cursa de 150 s. La 22 m, zero.
##
## [b]Apa nu vine de la nivelul marii.[/b] Pe o pista cu [code]water[/code] in
## tema (Okinawa), canalul sapat sub cota marii se umple singur din grila de
## tarm. In rest — un parau de munte, de pilda — apa isi are cota ei, si atunci
## [member water_y_drop] e cel care o declara SI comutatorul care cere o
## suprafata proprie.

## Cati metri de sosea LIPSESC.
##
## Valoarea se rotunjeste la pasul curbei coapte, iar cifra OBTINUTA e cea care
## conteaza pentru saritura — o tiparesc si ProbeJump, si ProbeBridge. Nu
## presupune ca ai primit exact cat ai cerut.
@export var gap: float = 22.0

## Jumatatea latimii apei, masurata in lungul soselei.
@export var water_half: float = 9.0

## Pe cati metri urca malul de la apa la cota drumului.
@export var bank: float = 16.0

## Cat sub cota soselei de acolo sta fundul albiei.
##
## Adancimea DECIDE daca ratarea e terminala: sub ~10 m masina coboara taluzul
## rostogolindu-se si se intoarce in cursa, deci frica dispare (lectia rapelor
## din Track09._ravines). Peste, o prinde [RespawnZone].
@export var depth: float = 18.0

## Cat de jos sta APA fata de cota soselei. Negativ = canalul se umple din marea
## pistei (comportamentul Okinawei), deci nu primeste suprafata proprie.
##
## Diferenta [member depth] − [code]water_y_drop[/code] e grosimea reala a
## stratului de apa, si tot ea da scara gradientului de culoare. Un parau sapat
## 18 m cu apa la 15 are 3 m de apa: albie larga cu firicel, nu canal plin ochi.
@export var water_y_drop: float = 15.0

## Cat de departe merge albia in fiecare parte, inainte sa se stinga in teren.
@export var reach: float = 90.0:
	set(value):
		reach = maxf(value, 1.0)
		gizmo_extents = reach

## Pe ultimii metri din [member reach] albia se stinge in terenul din jur.
## Fara stingere, canalul s-ar termina cu un perete drept in mijlocul campului.
@export var fade: float = 30.0

## Golul se trece din SARITURA, nu pe pod. Vezi antetul clasei.
@export var jump: bool = true

## Sapatura e o GROAPA CIRCULARA centrata pe taietura, nu o albie in lungul
## axei. Pentru gauri care exista doar ca sa se ascunda sub un asset rotund
## (cuva craterului de pe Stromboli): terenul coboara radial de la
## [member water_half] (fund plat) la [member water_half] + [member bank]
## (buza), iar in afara cercului plateul ramane neatins — o albie
## dreptunghiulara ar fi scos colturi de sapatura de sub marginea rotunda a
## asset-ului, oricum am fi potrivit-o. [member reach] si [member fade] nu
## participa: cercul isi e propriul capat.
@export var pit: bool = false

## Numele afisat in sonde si in mesaje de eroare.
@export var label: String = ""


func _ready() -> void:
	# Setter-ul nu ruleaza pentru valoarea implicita la instantiere — crucea ar
	# ramane la cei 0.25 m ai lui Marker3D si amprenta n-ar comunica nimic.
	# Aceeasi capcana ca la TerrainPeak.
	gizmo_extents = reach


## Declaratia, in formatul pe care il intoarce si `Track._channel_specs()`.
##
## `frac` se DERIVA din pozitia nodului, in coordonatele pistei — conteaza daca
## nodul e grupat sub ceva cu transformare proprie.
func to_spec(track: Node3D) -> Dictionary:
	var spec := {
		"gap": gap,
		"water_half": water_half,
		"bank": bank,
		"depth": depth,
		"reach": reach,
		"fade": fade,
		"jump": jump,
		"pit": pit,
		"label": label if label != "" else name,
	}
	if water_y_drop >= 0.0:
		spec["water_y_drop"] = water_y_drop
	return spec


## Pozitia nodului in coordonatele PISTEI (nu in lume, nu in spatiul parintelui).
func local_position(track: Node3D) -> Vector3:
	return track.to_local(global_position)
