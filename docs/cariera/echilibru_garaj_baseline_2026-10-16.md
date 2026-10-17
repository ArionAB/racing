# Echilibrul garajului — linia de bază, 16 oct 2026

Matricea din `mod_cariera.md` §2.1, brută. `ProbeRace --mode=race --seconds=240 --seed=1 --car=N` pe main 0b9d21e6, Godot 4.7, headless, fixed-fps 60. Un seed; pentru A/B la pasul 0 rulează ≥2 seed-uri și compară distribuțiile.

Rulare: `godot --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=race --track=T --seconds=240 --car=C --seed=1` cu T ∈ {11 Kyoto, 12 Monument Valley, 7 Serengeti, 2 Transfăgărășan}, C ∈ {0 Muscle, 5 Buggy}.

## track=11 car=0

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Muscle)                     3  min  65.52  med  68.27
    Robo (Autobuzul)                2  min  82.85  med  85.00
    Vex (Politia)                   3  min  67.05  med  69.51
    Luna (Pompierii)                2  min  81.83  med  83.93
    Kai (Taxi)                      3  min  69.42  med  72.03
    Nyx (Autobuzul)                 2  min  83.00  med  87.08
--- TUR global: 15 ture, minim 65.52 s, mediu 76.09 s
repuneri: 1  blocaje: 0
```

## track=11 car=5

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Buggy)                      3  min  65.62  med  68.03
    Robo (Autobuzul)                2  min  90.02  med  91.34
    Vex (Politia)                   3  min  66.87  med  69.24
    Luna (Pompierii)                3  min  76.45  med  77.36
    Kai (Taxi)                      3  min  69.43  med  72.12
    Nyx (Autobuzul)                 2  min  89.17  med  91.09
--- TUR global: 16 ture, minim 65.62 s, mediu 76.57 s
repuneri: 0  blocaje: 0
```

## track=12 car=0

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Muscle)                     3  min  61.55  med  66.82
    Robo (Autobuzul)                2  min  79.93  med  82.11
    Vex (Politia)                   3  min  65.38  med  67.04
    Luna (Pompierii)                3  min  75.15  med  78.03
    Kai (Taxi)                      3  min  65.83  med  67.08
    Nyx (Autobuzul)                 2  min  80.70  med  82.44
--- TUR global: 16 ture, minim 61.55 s, mediu 72.87 s
repuneri: 4  blocaje: 0
```

## track=12 car=5

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Buggy)                      3  min  62.02  med  66.55
    Robo (Autobuzul)                2  min  81.15  med  82.24
    Vex (Politia)                   3  min  64.02  med  66.08
    Luna (Pompierii)                3  min  73.28  med  76.97
    Kai (Taxi)                      3  min  66.37  med  71.56
    Nyx (Autobuzul)                 2  min  77.88  med  80.20
--- TUR global: 16 ture, minim 62.02 s, mediu 73.02 s
repuneri: 3  blocaje: 0
```

## track=7 car=0

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Muscle)                     3  min  71.28  med  72.97
    Robo (Autobuzul)                3  min  17.80  med  68.83
    Vex (Politia)                   3  min  70.68  med  72.49
    Luna (Pompierii)                2  min  86.82  med  87.92
    Kai (Taxi)                      2  min  78.53  med  88.42
    Nyx (Autobuzul)                 2  min  92.67  med  95.99
--- TUR global: 15 ture, minim 17.80 s, mediu 79.17 s
repuneri: 20  blocaje: 4
```

## track=7 car=5

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Buggy)                      3  min  71.02  med  74.80
    Robo (Autobuzul)                2  min  89.30  med  90.12
    Vex (Politia)                   2  min  74.18  med  81.80
    Luna (Pompierii)                2  min  89.25  med  91.07
    Kai (Taxi)                      2  min  81.03  med  82.55
    Nyx (Autobuzul)                 2  min  94.10  med  94.53
--- TUR global: 13 ture, minim 71.02 s, mediu 84.96 s
repuneri: 13  blocaje: 2
```

## track=2 car=0

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Muscle)                     3  min  67.88  med  70.04
    Robo (Autobuzul)                2  min  87.27  med  88.05
    Vex (Politia)                   3  min  69.05  med  71.37
    Luna (Pompierii)                2  min  86.78  med  87.80
    Kai (Taxi)                      3  min  70.83  med  73.38
    Nyx (Autobuzul)                 2  min  87.60  med  88.50
--- TUR global: 15 ture, minim 67.88 s, mediu 78.20 s
repuneri: 3  blocaje: 0
```

## track=2 car=5

```
--- ture (s): masina | ture complete | minim | mediu
    Tu (Buggy)                      3  min  69.03  med  69.91
    Robo (Autobuzul)                2  min  86.20  med  86.81
    Vex (Politia)                   3  min  68.85  med  71.61
    Luna (Pompierii)                2  min  80.62  med  82.59
    Kai (Taxi)                      3  min  73.03  med  73.27
    Nyx (Autobuzul)                 2  min  86.23  med  87.18
--- TUR global: 15 ture, minim 68.85 s, mediu 77.17 s
repuneri: 5  blocaje: 0
```

