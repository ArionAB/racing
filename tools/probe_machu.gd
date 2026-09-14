extends Node
## Sondele tehnice de dinaintea traseului Machu Picchu (brief §7 pasul 1):
## fiecare mecanica noua pe sol plat, cu contractul ei din brief §3.
##
##   A. PODUL DE FRANGHIE (RopeBridgeHazard) — tools/probe_machu_pod.gd:
##      sageata pe masa, valul, balansul, siguranta, costul, captura.
##   B. TREPTELE ca suprafata (raycast pe panta lina + zgomot ±3 cm) — de scris
##   C. TERASELE: 8 caderi de 2.5 m la rand, 4 masini, fara rasturnare — de scris
##   D. AUTOBUZUL cu DeflectorHazard pe ac: ghiont spre exterior, cu masa — de scris
##
## Fiecare test sta in fisierul lui (tools/probe_machu_<test>.gd, cu `run(lib)`)
## si isi construieste lumea intr-un nod copil pe care il sterge la final;
## uneltele comune (masina condusa de script, verdicte) sunt in
## tools/probe_machu_lib.gd. Asa testele se scriu de agenti diferiti fara sa
## se calce pe fisier.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMachu.tscn
## Fara --headless scrie si captura podului in snapshots/. Iese cu cod 1 la
## orice verdict picat.

const Lib := preload("res://tools/probe_machu_lib.gd")
const PodTest := preload("res://tools/probe_machu_pod.gd")


func _ready() -> void:
	await get_tree().physics_frame
	var lib: Lib = Lib.new(self)
	print("")
	print("=== Machu Picchu: sondele tehnice ===")
	await PodTest.new().run(lib)
	# B. treptele: await StepsTest.new().run(lib)
	# C. terasele: await TerracesTest.new().run(lib)
	# D. autobuzul: await BusTest.new().run(lib)
	print("")
	print("REZULTAT: %s (%d verdicte)" % ["PICAT" if lib.failed else "TRECUT", lib.checks])
	get_tree().quit(1 if lib.failed else 0)
