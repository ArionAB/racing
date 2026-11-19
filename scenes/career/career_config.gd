class_name CareerConfig
extends Resource
## Rafturile carierei, in ordinea afisarii. Un singur fisier de date
## (`data/career_config.tres`) descrie toata structura.

@export var worlds: Array[CareerWorld] = []
## Bonusul carierei (+1), acelasi pe fiecare pista (19 nov 2026, in locul
## provocarilor per pista): titlul scurt pe HUD, pe foaia pistei si in
## rezultate; hint-ul o propozitie pe foaia pistei. Regula: `BonusTracker`.
@export var bonus_title: String = "NO RETRY"
@export var bonus_hint: String = "Finish without an eject or a RESET."
## Garajul de start: masinile deschise de la prima pornire. PRIMA e masina pe
## care cade selectia unui jucator nou (`Career.ensure_selected_car`).
@export var starting_cars: Array[StringName] = []
## Masinile castigate in cariera, fiecare la pragul ei de puncte. O masina din
## `GameState.CAR_DATA` care nu e nici aici, nici in `starting_cars` e DESCHISA
## (ca o pista in nicio lume: starea normala a continutului nou pana il asaza
## cineva), nu o eroare de config.
@export var car_rewards: Array[CareerCarReward] = []
