class_name CarData
extends Resource
## Identitatea unei masini: statistici + culoare, ca resursa (.tres).
## O masina noua in garaj = un fisier nou, zero modificari in cod.
## Parametrii de feel globali (drift, gravitate) raman pe Car — aici e
## doar ce DIFERENTIAZA masinile intre ele.

@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var max_speed: float = 34.0     # m/s
@export var acceleration: float = 16.0
@export var grip: float = 8.0
## Cine impinge pe cine la contact: grea = stabila, usoara = zboara.
@export var mass_factor: float = 1.0
