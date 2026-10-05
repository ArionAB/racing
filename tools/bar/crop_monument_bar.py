"""Decupeaza diorama-bara Monument Valley (Track19) pe POI.

Bara e `docs/track_briefs/img/monument_plan/diorama_v02.jpg` (1536x1024), a
doua generare (brief §9.0b): asfaltul se opreste la grila, Mittens sunt turnuri
cu deget, platoul de start e ridicat. Densitatea APROPIATA de drum (butte-uri
mici, ace de stanca, hoodoo-uri la 10-60 m de sosea) e mai buna in prima
generare, `diorama_v02_iter1.jpg` (aceeasi dimensiune, acelasi cadru): cele
`*_iter1` de mai jos vin de acolo si se folosesc DOAR pentru densitate si
aranjament (grupari, perechi, distante), NU pentru asfalt (iter1 are asfalt pe
cornisa si dupa grila — defect declarat in brief §9.0b).

Ea NU e layout-ul pistei (acela e `monument_plan.png`, generat din scena, si
fractiile masurate din `monument_poi_gauntlet.md`); ea e *look-ul* fiecarui
loc. Criticul compara captura din masina la un POI cu decupajul POI-ului, nu cu
toata plansa (regula „bara e look, nu layout", `docs/bara_vizuala.md`).

Orientarea dioramei = orientarea planului real: SUS = nord, STANGA = vest, sensul
de mers e ORAR. Start/sosire pe platoul din dreapta-sus; coborarea B pe dreapta
(spre sud); trecatoarea E jos (spre vest); cornisa F pe stanga (spre nord);
campia G in stanga-sus; H = asfaltul de sus, de la stanga la dreapta.

Cutiile sunt in PIXELI pe 1536x1024 (imaginea e fixa), alese prin citirea
dioramei la rezolutie plina (decupaje marite 3x), 5 oct 2026. Fiecare are
justificarea langa ea. Decupajele se SALVEAZA MARITE (LANCZOS) la cel putin
~1800 px pe latura lunga: planșa intreaga e micsorata de ~4-7x si ascunde
exact detaliile pe care criticul trebuie sa le vada (memoria
`numaratoarea-trece-amplasarea-nu`).

Defectele dioramei care NU se iau din imagine:
  - haboob-ul (zidul de praf din stanga-sus) e al lui HaboobHazard, nu al
    decorului; decupajul G2 il mai prinde in margine (praful din stanga), nu
    se compara;
  - caii din A au sa pe spate; in joc fara sa si fara calaret (brief §8);
  - peretele rosu de platou care insoteste asfaltul de sus (H + A) pe toata
    lungimea lui: in joc exista doar la A, la ~55 m SUD de axa (terenul cade
    cu 7 m la 60 m), iar pe H terenul e plat lateral (rampa 0,8 -> 12 m);
    peretele de pe H se poate pune ca mesa_wall_module la >= 35 m, nu ca relief;
  - scurtatura G' (dunele) lipseste din ambele generari: pozitia ei vine din
    scena, nu din imagine;
  - Mittens au in dioramă o fusta de grohotis larga, aproape conica; in joc
    fusta e conul TerrainPeak (raza 28 m, ~4 m inaltime) plus fusta GLB-ului
    (<= 7,4 m);
  - drumul de pamant are in dioramă aceeasi culoare cu solul; in joc
    `dirt_road_tint` e usor mai inchis (brief §4);
  - belvederul din dioramă (camioane, turisti, ramada) e pe un promontoriu
    inalt de ~3 m peste mesa; in joc cornisa F e plata (+/-0,5 m) pe stanga
    (premisa 5 din monument_poi_gauntlet.md), deci se pune pe un cadran plat;
  - gospodaria e pe un platou din colt NE; in joc zona est de B e valea la y=0
    cu raft la y~4 dincolo de x=420 (premisa 8).

    python tools/bar/crop_monument_bar.py [--out DIR] [--min-long 1800]

Scrie `<out>/<POI>.png` (marit), `<out>/_index.png` (dreptunghiurile desenate
pe diorama, cu litera POI-ului) si `<out>/_index.txt` (caseta + ce trebuie sa
se citeasca).
"""

import argparse
import os

from PIL import Image, ImageDraw, ImageFont

SRC_V02 = "docs/track_briefs/img/monument_plan/diorama_v02.jpg"
SRC_IT1 = "docs/track_briefs/img/monument_plan/diorama_v02_iter1.jpg"
SIZE = (1536, 1024)

# nume: (sursa, (x0, y0, x1, y1) px, culoare in index, ce trebuie sa se citeasca)
REGIONS = {
    # asfalt sus-dreapta pana la viraj: postul de negot cu prispa, pickup,
    # turnul de apa, moara cu jgheab, cai langa jgheab, telegraf, gard, masina
    # albastra pe grila. Platoul se termina cu o cornisa rosie spre vale.
    "A": ("v02", (780, 50, 1230, 235), (255, 220, 40),
          "startul pe platou: postul de negot de piatra cu prispa de lemn, pickup "
          "vechi in fata, turnul de apa de lemn, moara de vant cu jgheab rotund si "
          "cai la jgheab, stalpi de telegraf cu fire, gard de sarma; platoul "
          "se rupe intr-un perete rosu spre vale"),
    # coborarea pe asfalt din colt: asfalt cu linie dubla galbena, stalpi de
    # telegraf pe margine, gard, salvie, butte-uri; Mittens + Merrick in capat.
    "B": ("v02", (1010, 150, 1400, 540), (255, 140, 40),
          "coama si dreapta US-163: asfalt negru cu linie dubla galbena, stalpi de "
          "telegraf pe o parte, gard de sarma, salvie in tufe, rabbitbrush galben; "
          "in capat cele doua turnuri cu deget"),
    # aceeasi coborare, dar din prima generare: butte-urile mici si acele de
    # stanca de langa drum (10-60 m): grupari de 2-3, mese joase, hoodoo-uri.
    "B_iter1": ("it1", (800, 140, 1330, 540), (255, 140, 40),
                "DENSITATE lateral de B (iter1): butte-uri mici si ace de stanca in "
                "perechi si grupari la 10-60 m de asfalt, grohotis la picior, "
                "salvie si ienupar intre ele (asfaltul din iter1 NU se ia)"),
    # grila: bare de otel peste drum, semn galben cu cal, asfaltul devine pamant
    # rosu cu urme; praful din urma masinii galbene.
    "C": ("v02", (1010, 470, 1260, 720), (240, 90, 60),
          "grila pentru vite si inceputul Valley Drive: bare peste drum, doi stalpi "
          "de capat, romb galben cu cal, asfalt care se termina drept, pamant rosu "
          "cu urme, praf de la masina"),
    # poarta: West Mitten stanga (turn cu coloane, deget separat, fusta de
    # grohotis), East Mitten dreapta, Merrick in spate dreapta.
    "D": ("v02", (880, 380, 1450, 740), (230, 40, 40),
          "poarta dintre Mittens: doua turnuri cu coloane, deget de piatra "
          "separat cu gol de cer, fusta de grohotis cu bolovani, calota palida; "
          "drumul de pamant trece printre ele; Merrick lat in spate"),
    # fiecare turn separat, mai strans (silueta e reperul pistei)
    "WM": ("v02", (890, 430, 1100, 640), (230, 40, 40),
           "West Mitten singur: turn cu coloane late, deget subtire cu gol de cer, "
           "trei etaje (grohotis dungat jos, perete cu fisuri verticale, calota palida)"),
    "EM_MB": ("v02", (1150, 380, 1450, 690), (230, 40, 40),
              "East Mitten si Merrick: turn cu deget pe dreapta, bloc lat cu "
              "contraforturi; trei etaje"),
    # canionul de jos: pereti verticali de 3 lungimi de masina, in umbra, cu muchia
    # aprinsa; capatul din dreapta e intrarea (mase mari), stanga = arcul.
    "E": ("v02", (500, 690, 1310, 1000), (150, 60, 200),
          "trecatoarea dintre mese: pereti verticali rosii cu muchii aprinse, in "
          "umbra adanca, grohotis la picior, drum de pamant pe fund; in dreapta "
          "mesele mari de la intrare"),
    "E_iter1": ("it1", (500, 690, 1310, 1000), (150, 60, 200),
                "trecatoarea (iter1): acelasi cadru, pentru comparatia de densitate"),
    # arcul peste drum: punte masiva de gresie cu gol, in partea stanga a
    # canionului, tufe si grohotis la picioare, masina verde care trece.
    "EArc": ("v02", (320, 620, 620, 810), (150, 60, 200),
             "arcul de gresie peste drum: masa plata cu gaura, blocuri mari, calota "
             "palida, picioare cu grohotis; masina verde trece pe sub el"),
    # cornisa din stanga: drumul pe buza mesei, perete cu cadere spre dreapta,
    # mesa plata pe stanga cu belvedere.
    "F": ("v02", (0, 380, 470, 830), (40, 120, 230),
          "cornisa: drum de pamant pe buza unei mese, perete vertical cu cadere "
          "spre dreapta, fara parapet; mesa plata pe stanga cu belvederul"),
    # belvederul singur: ramada de lemn cu masa, 3 camioane de tur, 6-8 turisti,
    # taluz de piatra, tufe.
    "F_belvedere": ("v02", (30, 370, 330, 500), (40, 120, 230),
                    "belvederul: ramada de stalpi si crengi cu masa, trei camioane "
                    "de tur deschise, un grup de turisti cu aparate, pe mesa plata"),
    # campia: S-urile din valea deschisa, salvie in tufe, rabbitbrush galben,
    # bolovani, urme de cauciuc vechi, doua butte-uri stanga-sus.
    "G": ("v02", (240, 230, 800, 560), (60, 190, 90),
          "campia deschisa: S-urile drumului de pamant, vegetatie in tufe (nu "
          "uniform), rabbitbrush galben ca accent, bolovani rari, butte-uri la "
          "marginea din stanga"),
    "G_iter1": ("it1", (240, 230, 800, 560), (60, 190, 90),
                "campia (iter1): butte-uri mici, ace de stanca si hoodoo-uri langa "
                "S-uri, perechi si grupari — densitatea de luat"),
    # albia: ravena cu maluri taiate, cai pe malul de langa, masina in aer pe
    # rampa de pamant, a doua grila in spate.
    "G2": ("v02", (430, 150, 740, 350), (30, 180, 180),
           "albia secata: ravena ingusta cu maluri taiate de nisip palid, cai la "
           "marginea ei, masina in aer pe o rampa de pamant, a doua grila + romb "
           "galben in spate"),
    # asfaltul de sus: stalpi de telegraf, gard, plutind spre platou; mesele de
    # orizont in spate.
    "H": ("v02", (500, 40, 1010, 230), (230, 140, 200),
          "dreapta H: asfalt cu linie dubla galbena, stalpi de telegraf cu fire, "
          "gard de sarma, perete rosu de platou pe sub drum, mese de orizont in "
          "spate"),
    # gospodaria: casa modulara, hogan cu 8 laturi, tarc cu cai, oi, rezervor,
    # pickup, gard.
    "GOSPODARIE": ("v02", (1250, 240, 1530, 400), (200, 200, 200),
                   "gospodaria din vale: casa modulara de scanduri, hogan cu opt "
                   "laturi, tarc de lemn cu cai, 10 oi, rezervor, pickup, gard"),
    # orizontul: mese lungi, turle, cer cu cumulus.
    "ORIZONT": ("v02", (420, 0, 1536, 130), (120, 120, 255),
                "orizontul: mese lungi de gresie, turle, cumulus mari, cerul "
                "albastru adanc cald la linia orizontului"),
}


def load(path: str) -> Image.Image:
    im = Image.open(path).convert("RGB")
    assert im.size == SIZE, "%s are %s, se astepta %s" % (path, im.size, SIZE)
    return im


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_monument")
    ap.add_argument("--min-long", type=int, default=1800)
    args = ap.parse_args()

    srcs = {"v02": load(SRC_V02), "it1": load(SRC_IT1)}
    os.makedirs(args.out, exist_ok=True)
    notes = []
    for name, (src, box, _col, what) in REGIONS.items():
        crop = srcs[src].crop(box)
        long_side = max(crop.size)
        k = max(2.0, args.min_long / long_side)
        big = crop.resize((int(crop.width * k), int(crop.height * k)), Image.LANCZOS)
        path = os.path.join(args.out, "%s.png" % name)
        big.save(path)
        line = "%-12s %-4s box %-22s -> %dx%d (x%.1f)  %s" % (
            name, src, str(box), big.width, big.height, k, what)
        print(line)
        notes.append(line)

    # planșa de control: dreptunghiurile pe diorama (v02), cu litera lor.
    idx = srcs["v02"].copy()
    d = ImageDraw.Draw(idx)
    try:
        font = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    for name, (src, box, col, _what) in REGIONS.items():
        d.rectangle(box, outline=col, width=3 if src == "v02" else 2)
        # iter1: dungi, ca sa se vada ca vine din alta generare
        if src == "it1":
            x0, y0, x1, y1 = box
            for x in range(x0, x1, 14):
                d.line([(x, y0), (x + 7, y0)], fill=(255, 255, 255), width=2)
                d.line([(x, y1), (x + 7, y1)], fill=(255, 255, 255), width=2)
        tx, ty = box[0] + 4, box[1] + 3
        d.text((tx + 1, ty + 1), name + ("*" if src == "it1" else ""), fill=(0, 0, 0), font=font)
        d.text((tx, ty), name + ("*" if src == "it1" else ""), fill=col, font=font)
    idx.save(os.path.join(args.out, "_index.png"))
    with open(os.path.join(args.out, "_index.txt"), "w", encoding="utf-8") as f:
        f.write("* = din diorama_v02_iter1.jpg (doar densitate/aranjament)\n")
        f.write("\n".join(notes) + "\n")
    print("index -> %s" % os.path.join(args.out, "_index.png"))


if __name__ == "__main__":
    main()
