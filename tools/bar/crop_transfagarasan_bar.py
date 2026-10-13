"""Decupeaza diorama-bara Transfagarasan (Track21) pe POI.

Bara e `docs/track_briefs/img/transfagarasan_plan/diorama_v02_iter2.jpg`
(1536x1024), a doua corectie ChatGPT, ACCEPTATA (brief §9.2). `iter1` (camera din
sud: serpentinele urcau spre lac, tunel fundatura, Oltul torent, telecabina peste
lac) si `iter3` (semaforul peste serpentine, fara urs si fara tuneluri scurte) sunt
RESPINSE si nu se decupeaza deloc: nu exista `<POI>_iter1` ca la Okinawa.

Ea NU e layout-ul pistei (acela e `transfagarasan_plan.png`, generat din scena, si
fractiile masurate din `transfagarasan_poi_gauntlet.md`); ea e *look-ul* fiecarui
loc. Criticul compara captura din masina la un POI cu decupajul POI-ului, nu cu
toata plansa (regula „bara e look, nu layout", `docs/bara_vizuala.md`).

Orientarea dioramei (citita pe imagine, 14 oct 2026): SUS pe imagine e partea
departata. In dreapta-sus valea Argesului (satul, Poenari, trenul si Oltul pe
marginea dreapta), in sus-centru barajul cu lacul Vidraru in spatele lui si Prometeu,
in stanga-sus tunelurile scurte cu ursul si portalul cu semafor intre peretii de
zapada, in stanga-mijloc lacul Balea cu cabana, in prim-plan-stanga cele patru
serpentine cu oile, in dreapta-jos cascada, podetul rupt si padurea de molid. Sensul
de mers e ANTIORAR pe plan (A -> baraj -> lac -> Capra -> tunel -> Balea ->
serpentine -> cascada -> Olt -> A).

Cutiile sunt in PIXELI pe 1536x1024 (imaginea e fixa), alese prin citirea dioramei la
rezolutie plina si prin potrivirea cu planul real `transfagarasan_plan.png`. Fiecare
are justificarea langa ea. Decupajele se SALVEAZA MARITE (LANCZOS) la cel putin
~1800 px pe latura lunga: plansa intreaga e micsorata de ~4-7x si ascunde exact
detaliile pe care criticul trebuie sa le vada (memoria
`numaratoarea-trece-amplasarea-nu`).

Defectele dioramei care NU se iau din imagine (detaliate si masurate in
`transfagarasan_poi_gauntlet.md`, tabelul „Defectele dioramei"):
  - barajul din diorama are hau adanc si lacul sus la coronament pe toata lungimea;
    in joc coronamentul are 96 m, haul ~40 m, iar apa lacului e la +7,5 (§Probleme
    de nivel de pista);
  - camera dioramei vede SERPENTINELE de pe versantul din fata; in joc le vezi de
    sus doar daca terenul cade sub drum;
  - lacul Balea e un lac mare cu plaja; in joc e un disc de D 68 m, pe dreapta;
  - doua portaluri citesc ca un tunel lung; in joc tunelul are ~60 m, iar al doilea
    portal dinaintea serpentinelor se citeste ca iesire din tunel (abatere asumata,
    brief §9.2);
  - masina in aer peste podet e cursa, podetul e un `TrackChannel` cu `jump`;
  - Oltul din diorama are maluri line; in joc e apa de rapa la 45 m latime;
  - telecabina trece peste serpentine si padure: in joc cabina e de pus la G;
  - trenul, ursul, oile, utilajele, masinile in miscare sunt HAZARDE din cod.

    python tools/bar/crop_transfagarasan_bar.py [--out DIR] [--min-long 1800]

Scrie `<out>/<POI>.png` (marit), `<out>/_index.png` (dreptunghiurile desenate
pe diorama, cu litera POI-ului) si `<out>/_index.txt` (caseta + ce trebuie sa
se citeasca).
"""

import argparse
import os

from PIL import Image, ImageDraw, ImageFont

SRC = "docs/track_briefs/img/transfagarasan_plan/diorama_v02_iter2.jpg"
SIZE = (1536, 1024)

# nume: (caseta px, culoare in _index, ce trebuie sa se citeasca)
REGIONS = {
    "A": ((1120, 90, 1536, 345), (255, 220, 40),
          "valea Argesului: satul cu case cu acoperis de tabla (rosu/albastru/gri), "
          "prispa, garduri de lemn, stoguri, vaci pe pajiste; Poenari = ruina de "
          "caramida pe colt de stanca in partea de jos a casetei; drumul in S prin sat"),
    "A_poenari": ((1130, 225, 1360, 360), (255, 220, 40),
                  "Poenari de aproape: ruina de caramida si piatra pe un colt de "
                  "stanca gri-verzuie cu iarba pe creasta, padure de fag dedesubt, "
                  "Oltul la baza (FARA Dracula: nimic gotic, nimic de sange)"),
    "B": ((690, 30, 1135, 300), (255, 140, 40),
          "barajul: perete de beton gri cald cu rosturi verticale, parapet alb-rosu "
          "pe coronament, turn de priza, centrala la picior cu apa spumegand, "
          "Prometeu pe pinten (dreapta-sus), lacul in spatele coronamentului"),
    "C": ((680, 0, 1250, 135), (240, 90, 60),
          "malul lacului Vidraru: apa verde-inchis cu fatete, mal de stanca si "
          "molid, drumul pe mal; lacul se citeste VERDE, nu albastru de mare"),
    "C_urs": ((30, 110, 345, 275), (240, 90, 60),
              "ursul ridicat in doua labe langa doua portaluri scurte de STANCA "
              "bruta (fara captuseala), pinteni de sist cu iarba si molizi, "
              "drumul care iese din ele"),
    "D": ((330, 20, 745, 255), (230, 40, 40),
          "valea Caprei si portalul: zapada veche pe versant (strat murdar, nu "
          "alb curat), portalul de beton intre pereti de zapada, semaforul pe "
          "stalp, utilajul portocaliu si masina galbena la coada, sist gri-verzui "
          "cu fete luminate; molizi si jnepeni la poale"),
    "E": ((150, 215, 710, 465), (150, 60, 200),
          "lacul Balea: apa turcoaz-verzuie rece cu mal de piatra, cabana de lemn "
          "si piatra cu acoperis abrupt de tabla, masini parcate pe terasa, bujori "
          "magenta in petice, jnepeni, zapada pe versant; in dreapta-jos al doilea "
          "portal (nu se ia ca iesire)"),
    "F": ((270, 440, 1010, 870), (40, 120, 230),
          "serpentinele: patru ace de par stivuite, ziduri de sprijin din piatra "
          "pe fata fiecarei trepte, parapet alb-rosu, oile cu doi caini pe ramura "
          "a treia, masina rosie, bujori magenta si molizi pe fasiile dintre ramuri, "
          "zapada si sist pe versantul de sus"),
    "F_oi": ((330, 565, 900, 730), (40, 120, 230),
             "turma pe ramura a treia: oi crem (nu albe), doi caini negri, gardul "
             "de piatra al treptei, iarba rece, ac de par cu bujori"),
    "G": ((950, 540, 1450, 960), (60, 190, 90),
          "padurea de molid si cascada: molid verde-negru des pe versant, cascada "
          "in trepte alb-turcoaz pe stanca gri, statia de jos a telecabinei (cabana "
          "de lemn), podetul de lemn rupt peste parau, apa verde-cenusie jos, "
          "telecabina rosie pe cablu deasupra"),
    "H": ((1080, 270, 1536, 620), (230, 140, 200),
          "defileul Oltului: rau lat verde-cenusiu cu maluri de stanca impadurita, "
          "calea ferata pe malul celalalt cu trenul rosu, bariere la trecerea la "
          "nivel, drumul pe malul din dreapta, molid si fag pe pereti"),
    "ORIZONT": ((0, 835, 200, 1024), (120, 120, 255),
                "marea de nori: nori joasi cu fund luminat cald si umbra albastruie, "
                "sub si in jurul dioramei (singurul loc din imagine unde se vad nori "
                "in loc de cer gol); in joc norii sunt `CloudSea_*` in orizont, la "
                "240-320 m, SUB cota drumului"),
    "CREASTA": ((120, 0, 700, 210), (120, 120, 255),
                "creasta Fagarasului: zimti de sist gri-verzui cu zapada in caldari, "
                "fete luminate si fete in umbra, molizi la poale (in joc: `FagarasRidge_*`, "
                "la est, 200-260 m)"),
}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_transfagarasan")
    ap.add_argument("--min-long", type=int, default=1800)
    args = ap.parse_args()

    src = Image.open(SRC).convert("RGB")
    assert src.size == SIZE, "%s are %s, se astepta %s" % (SRC, src.size, SIZE)
    os.makedirs(args.out, exist_ok=True)
    notes = []
    for name, (box, _col, what) in REGIONS.items():
        crop = src.crop(box)
        long_side = max(crop.size)
        k = max(2.0, args.min_long / long_side)
        big = crop.resize((int(crop.width * k), int(crop.height * k)), Image.LANCZOS)
        path = os.path.join(args.out, "%s.png" % name)
        big.save(path)
        line = "%-10s box %-22s -> %dx%d (x%.1f)  %s" % (
            name, str(box), big.width, big.height, k, what)
        print(line)
        notes.append(line)

    idx = src.copy()
    d = ImageDraw.Draw(idx)
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    for name, (box, col, _what) in REGIONS.items():
        d.rectangle(box, outline=col, width=3)
        tx, ty = box[0] + 4, box[1] + 3
        d.text((tx + 1, ty + 1), name, fill=(0, 0, 0), font=font)
        d.text((tx, ty), name, fill=col, font=font)
    idx.save(os.path.join(args.out, "_index.png"))
    with open(os.path.join(args.out, "_index.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(notes) + "\n")
    print("index -> %s" % os.path.join(args.out, "_index.png"))


if __name__ == "__main__":
    main()
