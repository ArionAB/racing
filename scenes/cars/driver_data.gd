class_name DriverData
extends Resource
## Un SKIN de sofer: figurina + numele din garaj, ca resursa (.tres).
## Soferul se alege separat de masina (garaj, randul DRIVER), deci nu mai e
## legat de `CarData.driver_model` — acela ramane doar implicitul pentru AI.
## Un skin nou = un .tres nou in GameState.DRIVER_DATA, zero modificari in cod.

@export var display_name: String = ""
## Culoarea de UI (swatch); figurina isi are culorile ei, din paleta.
@export var color: Color = Color.WHITE
## GLB-ul figurinei: 7 piese rigide ca noduri separate (Driver.PART_NAMES),
## originea fiecareia in articulatia ei, a ansamblului pe sezut. PROPORTIILE
## corpului sunt contract — `driver_seat` din fiecare CarData, poza procedurala
## (driver.gd) si cutiile ragdoll-ului (toy_ragdoll.gd) sunt reglate pe ele.
## Un skin schimba culorile si capul (casca, accesorii), nu corpul.
@export var model: PackedScene
