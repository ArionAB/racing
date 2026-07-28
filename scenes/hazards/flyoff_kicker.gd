@tool
class_name FlyoffKicker
extends Area3D
## Cutia care ARUNCA, pe buza crestei de fly-off.
##
## De ce nu e de ajuns panta: masina e un CharacterBody3D: move_and_slide o
## face sa ALUNECE pe suprafata, iar floor_snap_length o tine lipita si pe
## coborare. O creasta lina, oricat de abrupta, iese o denivelare — masina
## urca si coboara cu velocity.y ~ 0. Airtime-ul se naste aici: impunem viteza
## verticala pe buza, proportional cu cat de tare ai intrat.
##
## Si tocmai fiindca depinde de viteza, creasta e o DECIZIE, nu un scripted
## moment: intri incet si sari scurt, in siguranta; intri cu turbo si zbori
## departe — poate prea departe, pe langa viraj, in nisip.

## Viteza verticala = viteza orizontala * factor, plafonata.
var launch_factor: float = 0.25
var launch_max: float = 10.0
## Sub viteza asta doar treci peste creasta — nu te arunca nimic.
var min_speed: float = 8.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var car := body as Car
	if car == null:
		return
	var speed := car.horizontal_speed()
	if speed < min_speed:
		return
	car.launch(minf(speed * launch_factor, launch_max))
