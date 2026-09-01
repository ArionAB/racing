@tool
class_name LightShaft
extends Node3D
## Coloana de lumina care cade dintr-un put de ventilatie pe drum (Cappadocia
## brief §2 POI F): un CON cu alfa, nu volumetrie.
##
## [b]De ce un con si nu ceata volumetrica.[/b] Constrangerea de mobil din
## CLAUDE.md interzice post-procesarea scumpa, iar `VolumetricFog` e chiar
## exemplul de manual: cere o textura 3D reevaluata pe cadru. Un con transparent
## cu blend aditiv costa UN draw call si arata la fel de bine la scara de
## jucarie, fiindca ce citeste jucatorul e silueta razei si pata luminata de pe
## jos — nu imprastierea fizica din ea.
##
## [b]De ce e nod, si nu geometrie in `.glb`.[/b] `vent_shaft.glb` e piesa de
## PIATRA (gura, bordura, gatul). Raza nu e piatra: ea trebuie sa se poata
## stinge, muta si recolora fara re-export, si mai ales trebuie sa aiba ALT
## material — unul transparent, care nu are ce cauta in atlasul lumii. Tinandu-le
## separate, putul ramane un prop obisnuit si raza un efect.
##
## [b]Materialul e UNUL SINGUR, partajat[/b] (`static var _shared`), exact ca
## `Palette.world_material`: garda din `tools/probe_decor.gd` numara materialele
## per pista, iar cinci puturi cu cinci materiale ar fi cinci intrari in buget
## pentru acelasi efect. Cu `static` raman una, oricate coloane s-ar pune.

## Raza gurii de sus (m). Cat gatul putului din `vent_shaft.glb`.
@export_range(0.5, 12.0, 0.1) var top_radius: float = 2.4:
	set(value):
		top_radius = value
		_rebuild()

## Raza petei de pe jos (m). Mai MARE decat gura: lumina se imprastie coborand,
## si un cilindru drept citeste ca teava de sticla, nu ca raza.
@export_range(0.5, 20.0, 0.1) var bottom_radius: float = 4.6:
	set(value):
		bottom_radius = value
		_rebuild()

## Cat coboara coloana (m). Se da cat inaltimea salii, ca pata sa cada PE drum:
## o raza care se opreste in aer se vede ca obiect, nu ca lumina.
@export_range(1.0, 40.0, 0.5) var length: float = 16.0:
	set(value):
		length = value
		_rebuild()

## Culoarea razei. Zori calzi, dar PALIZI: la 13° soarele e portocaliu, insa o
## raza saturata pe un perete brun iese pata de vopsea. Lumina se citeste din
## VALOARE, nu din croma.
@export var tint: Color = Color(1.0, 0.86, 0.66):
	set(value):
		tint = value
		_rebuild()

## Cat de tare arde.
##
## MIC. Masurat pe captura de la frac 0.672: la 0.24 conul iesea o lespede
## alb-laptos care ASCUNDEA peretele din spate — adica un obiect solid, exact ce
## nu trebuie sa fie o raza. Cu blend aditiv, valoarea se aduna pe fiecare pixel
## si un con vazut pe lungime aduna de doua ori (intri prin fata, iesi prin
## spate, `CULL_DISABLED`), deci pragul util e mult sub cel intuit.
@export_range(0.0, 1.0, 0.01) var strength: float = 0.085:
	set(value):
		strength = value
		_rebuild()

## Cate laturi are conul. 12 e destul: raza e transparenta, deci silueta ei nu se
## citeste ca poligon. Se declara EXPLICIT — un `CylinderMesh` lasat pe implicit
## vine cu 64 (CLAUDE.md: „cand creezi o primitiva in cod, seteaza-i
## radial_segments/rings").
@export_range(6, 32, 1) var sides: int = 12:
	set(value):
		sides = value
		_rebuild()

## Materialul e partajat de TOATE coloanele: vezi antetul (garda de materiale).
static var _shared: StandardMaterial3D
static var _shared_key: String = ""

var _mesh: MeshInstance3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Raza"
		add_child(_mesh)
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_radius
	cyl.bottom_radius = bottom_radius
	cyl.height = length
	cyl.radial_segments = sides
	# Un singur inel pe verticala: conul n-are relief, si fiecare inel in plus e
	# geometrie transparenta desenata degeaba (fill rate, constrangerea reala).
	cyl.rings = 1
	# Fara capace, si nu din economie: capacul de jos e un disc orizontal la cota
	# drumului (z-fighting garantat), iar cel de sus, vazut de la 6.5 m inaltime,
	# se citea ca un dop opac in tavan — pe captura ieseau amandoua ca farfurii.
	# Pata de pe jos o face lumina care cade, nu un poligon asezat acolo.
	cyl.cap_top = false
	cyl.cap_bottom = false
	_mesh.mesh = cyl
	# CylinderMesh e centrat pe origine; nodul se pune la GURA (in tavan), deci
	# corpul coboara cu jumatate din lungime.
	_mesh.position = Vector3.DOWN * (length * 0.5)
	_mesh.material_override = _material()
	# Raza nu arunca si nu primeste umbre: e lumina, nu obiect. Fara asta, cascada
	# directionala ii deseneaza conturul pe drum ca pe o teava.
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _material() -> StandardMaterial3D:
	var key := "%s|%.3f" % [tint.to_html(false), strength]
	if _shared != null and _shared_key == key:
		return _shared
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# ADITIV: lumina se ADAUGA peste ce e in spate. Cu alfa obisnuita raza ar
	# ACOPERI peretele, adica ar arata ca o folie de plastic atarnata din tavan.
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	# Se vede si din interiorul conului (treci prin raza cu masina).
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Nu scrie in adancime: doua coloane suprapuse trebuie sa se adune, nu sa se
	# decupeze una pe alta.
	mat.no_depth_test = false
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	# Intensitatea intra in CULOARE, nu in alfa.
	#
	# Masurat: cu `BLEND_MODE_ADD`, alfa din albedo nu mai scade nimic — pixelul
	# adaugat e culoarea insasi, deci un tint aproape alb ramane aproape alb
	# oricat de mic ar fi alfa. Prima varianta scazuse alfa de la 0.24 la 0.085 si
	# captura a iesit IDENTICA: conul tot o lespede alb-laptoasa. Ce conteaza la
	# aditiv e cat de departe de negru e culoarea, deci intensitatea se aplica
	# inmultind chiar RGB-ul.
	mat.albedo_color = Color(tint.r * strength, tint.g * strength,
		tint.b * strength, 1.0)
	# --- TOPIREA CONTURULUI, si de ce nu era facuta ---------------------------
	#
	# Comentariul de aici cerea deja „mai transparenta la margini decat in ax",
	# dar linia de sub el era `rim_enabled = false` — adica intentia era scrisa,
	# nu implementata. Si nici n-avea cum: `rim` e un termen de iluminare, iar
	# materialul e `SHADING_MODE_UNSHADED`, deci rim-ul nu se evalueaza deloc.
	#
	# Asta e chiar „valul translucid" pe care criticul l-a vazut peste jumatatea
	# stanga a capturilor R3_068/072 (si care lipsea din 074 doar fiindca acolo
	# raza cadea in afara cadrului). Nu era o problema de intensitate: masurat
	# geometric, un con de 16 m inaltime si 3 m raza, privit de la 10 m, acopera
	# 77° pe verticala intr-un FOV de 74° — adica NU e o raza in cadru, e o folie
	# peste tot cadrul, cu muchii verticale drepte fiindca cilindrul are 12 laturi
	# si `CULL_DISABLED` deseneaza si fata din spate. De-aia scaderea lui
	# `strength` de la 0.24 la 0.085 „a iesit identica": micsora valoarea, nu
	# suprafata acoperita.
	#
	# `proximity_fade` stinge pixelii unde geometria transparenta se APROPIE de
	# ce e in spate — deci exact cusaturile: podeaua, peretii, si camera cand
	# treci prin raza. Silueta se topeste in loc sa taie.
	mat.proximity_fade_enabled = true
	mat.proximity_fade_distance = 2.5
	# Si o stingere la DISTANTA MICA: cand camera intra in con, pixelii de langa
	# ochi sunt cei care spala tot cadrul. Fade-ul ii scoate inainte sa devina
	# perdea, si lasa raza sa se vada de departe, unde ea CHIAR citeste ca raza.
	mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	mat.distance_fade_min_distance = 4.0
	mat.distance_fade_max_distance = 1.5
	mat.disable_receive_shadows = true
	_shared = mat
	_shared_key = key
	return mat
