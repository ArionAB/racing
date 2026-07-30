class_name CarData
extends Resource
## Identitatea unei masini: statistici + culoare, ca resursa (.tres).
## O masina noua in garaj = un fisier nou, zero modificari in cod.
## Parametrii de feel globali (drift, gravitate) raman pe Car — aici e
## doar ce DIFERENTIAZA masinile intre ele.

@export var display_name: String = ""
## Culoarea de UI (swatch in rezultate/HUD); modelul isi are culorile lui.
@export var color: Color = Color.WHITE
@export var max_speed: float = 34.0     # m/s
@export var acceleration: float = 16.0
@export var grip: float = 8.0
## MASA masinii — cine impinge pe cine la contact. Intra ca 1/m in impulsul de
## coliziune (Car._resolve_bump), deci ce conteaza e RAPORTUL dintre doua masini:
## la contact, delta-v-ul fiecareia e invers proportional cu masa ei. Autobuzul
## (2.6) intrat in Politie (0.9) o trimite de ~3 ori mai tare decat se opreste el.
##
## Nu inghesui valorile: doua masini cu 1.0 si 1.1 se ciocnesc identic, iar
## "identitatea prin masa" dispare. Scara folosita in garaj: 0.9 (sport usor) ..
## 2.6 (autobuz). Verifica orice retunare cu:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=bump
@export var mass_factor: float = 1.0

@export_group("Model 3D")
## Scena modelului (FBX importat); daca lipseste, se deseneaza cuburi.
@export var model: PackedScene
@export var model_scale: float = 1.0
## Corectie de orientare (modelele RgsDev privesc spre +Z; fata Godot = -Z).
@export var model_rotation_deg: float = 180.0
## Dimensiunile vizuale DUPA scalare — dimensioneaza colizerul si efectele.
@export var body_length: float = 3.8
@export var body_width: float = 2.2
