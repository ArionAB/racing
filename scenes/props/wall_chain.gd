extends Node3D
## Lant de module de zid (gusuku): sterge din arbore variantele nefolosite.
##
## `gusuku_wall_curve.glb` poarta DOUA variante in acelasi fisier (Wall_A, R=20,
## si Wall_B, R=40, aceasta decalata +10 m pe X). Generatorul alege una per modul
## si o ascundea pe cealalta cu `visible = false` in suprascrierea de nod. Pe
## telefon suprascrierea nu s-a aplicat (captura de pe device, 12 oct 2026): s-au
## randat ambele, a doua decalata 10 m in lateral — arata ca un al doilea zid
## curb pus peste cel drept. Un nod ascuns se poate vedea; un nod sters nu.
##
## Fiecare modul-copil poate purta `metadata/drop_variants` = nume de noduri
## (separate prin virgula) de scos. Ruleaza in `_ready` — copiii se pregatesc
## inaintea parintelui, deci inaintea oricarui pas al pistei care aduna corpuri
## fizice sau materiale din ierarhie.

func _ready() -> void:
	for module in get_children():
		if not module.has_meta("drop_variants"):
			continue
		for nm in String(module.get_meta("drop_variants")).split(",", false):
			var n := module.get_node_or_null(NodePath(nm.strip_edges()))
			if n != null:
				module.remove_child(n)
				n.free()
