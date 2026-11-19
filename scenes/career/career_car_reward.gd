class_name CareerCarReward
extends Resource
## O masina castigata in cariera: la `points` puncte de cariera (cumulate, toate
## lumile) masina `car` intra in garaj si ramane acolo (vezi `Career` — masinile
## se ZAVORASC, nu se recalculeaza). O masina noua de castigat = un .tres nou in
## `data/car_rewards/` + o intrare in `career_config.tres`, zero cod.

## `CarData.id` al masinii (niciodata indexul din `GameState.CAR_DATA`).
@export var car: StringName = &""
## Pragul de puncte de cariera. Date de tuning, provizorii: se retuneaza cand
## cariera trece la 4 lumi (#704).
@export var points: int = 0
