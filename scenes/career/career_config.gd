class_name CareerConfig
extends Resource
## Rafturile carierei, in ordinea afisarii. Un singur fisier de date
## (`data/career_config.tres`) descrie toata structura.

@export var worlds: Array[CareerWorld] = []
## Provocarea gimmick-ului per pista (maxim una pe pista; vezi `Career.validate`).
## O pista fara intrare aici nu are provocare, iar foaia ei arata „SOON".
@export var challenges: Array[CareerChallenge] = []
## Garajul de start: masinile deschise de la prima pornire. PRIMA e masina pe
## care cade selectia unui jucator nou (`Career.ensure_selected_car`).
@export var starting_cars: Array[StringName] = []
## Masinile castigate in cariera, fiecare la pragul ei de puncte. O masina din
## `GameState.CAR_DATA` care nu e nici aici, nici in `starting_cars` e DESCHISA
## (ca o pista in nicio lume: starea normala a continutului nou pana il asaza
## cineva), nu o eroare de config.
@export var car_rewards: Array[CareerCarReward] = []
