"""Decupeaza diorama-bara Okinawa (Track20) pe POI.

Bara e `docs/track_briefs/img/okinawa_plan/diorama_v02.jpg` (1536x1024), a
doua generare acceptata (corectie in aceeasi conversatie ChatGPT, brief §9.2).
Prima generare, `diorama_v02_iter1.jpg` (aceeasi dimensiune, acelasi cadru), a
fost RESPINSA pe 11 puncte (brief §9.2: lipsea aleea B, pod basculant, tromba in
larg, trei faruri, tetrapozi-bolovani). Decupajele `*_iter1` de mai jos se iau
DOAR pentru densitate si aranjament (vegetatie, case, ziduri de camp) unde iter1
arata mai bine, niciodata pentru pod, tetrapozi, far sau tromba.

Ea NU e layout-ul pistei (acela e `okinawa_plan.png`, generat din scena, si
fractiile masurate din `okinawa_poi_gauntlet.md`); ea e *look-ul* fiecarui loc.
Criticul compara captura din masina la un POI cu decupajul POI-ului, nu cu toata
plansa (regula „bara e look, nu layout", `docs/bara_vizuala.md`).

Orientarea dioramei: camera sta in coltul de SV al planului si priveste spre
NE (brief §9). Deci: in PRIM-PLAN digul H cu valul si satul A; la MIJLOC golful,
portul si podul F cu feribotul; in SPATE castelul D pe deal (stanga-sus), capul E
cu farul (centru-dreapta-sus) si insula mica G (dreapta-jos) cu tromba pe peretele
de furtuna (dreapta-sus). Aleea B si trestia C sunt pe STANGA, pe latura de V a
insulei mari. Sensul de mers e ORAR pe plan.

Cutiile sunt in PIXELI pe 1536x1024 (imaginea e fixa), alese prin citirea
dioramei la rezolutie plina (decupaje marite 3x) si prin potrivirea cu planul real
`okinawa_plan.png`, 9 oct 2026. Fiecare are justificarea langa ea. Decupajele se
SALVEAZA MARITE (LANCZOS) la cel putin ~1800 px pe latura lunga: planșa intreaga e
micsorata de ~4-7x si ascunde exact detaliile pe care criticul trebuie sa le vada
(memoria `numaratoarea-trece-amplasarea-nu`).

Defectele dioramei care NU se iau din imagine (detaliate si masurate in
`okinawa_poi_gauntlet.md`, tabelul „Defectele dioramei"):
  - poarta (D) sta pe un drum LATERAL, intr-o intersectie in T; in joc e PESTE
    bucla, la ~0,43, cu golul de 14,35 m al kitului pe un drum de 12 m;
  - stanca-inima apare DE DOUA ORI (golf + insula mica); in joc e una;
  - tetrapozii urmeaza tot frontul satului; in joc sunt doar pe dig (H, 0.84-0.96);
  - castelul si satul sunt mult mai aproape de drum decat permite scara: in joc
    drumul sta pe creasta (terenul lateral e plat la cota drumului pe ±50 m);
  - cocotieri/palmieri pe insula mica: kitul nu are cocotier; vin pandanus si
    fan_palm doar langa port (brief §0.1);
  - masinile de curse, urmele de lansare si masina in aer sunt cursa, nu decor;
  - tromba, valul si feribotul sub pod sunt HAZARDE/CEAS din cod (`TyphoonHazard`,
    `WaveSurge`, `LiftBridgeHazard`), nu decor; decupajele lor sunt doar pentru
    culoarea spumei si a norilor;
  - vaporul de coasta „de afara" (iter1) e decor de fundal, nu pe canal.

    python tools/bar/crop_okinawa_bar.py [--out DIR] [--min-long 1800]

Scrie `<out>/<POI>.png` (marit), `<out>/_index.png` (dreptunghiurile desenate
pe diorama, cu litera POI-ului) si `<out>/_index.txt` (caseta + ce trebuie sa
se citeasca).
"""

import argparse
import os

from PIL import Image, ImageDraw, ImageFont

SRC_V02 = "docs/track_briefs/img/okinawa_plan/diorama_v02.jpg"
SRC_IT1 = "docs/track_briefs/img/okinawa_plan/diorama_v02_iter1.jpg"
SIZE = (1536, 1024)

# nume: (sursa, (x0, y0, x1, y1) px, culoare in index, ce trebuie sa se citeasca)
REGIONS = {
    # A: satul + portul. Primul plan-stanga/centru: casele Ryukyu cu olane rosii
    # si mortar alb, casele de beton albe cu rezervor rotund, palmieri langa
    # port, flori (hibiscus, bougainvillea) peste ziduri, drumul care trece prin
    # sat, cheiul cu scari, barcile de pescari. Tetrapozii din primul plan NU se
    # iau (in joc sunt doar pe dig).
    "A": ("v02", (70, 340, 980, 650), (255, 220, 40),
          "portul si satul: case Ryukyu joase cu olane rosii si mortar alb, case de "
          "beton albe cu rezervor rotund pe acoperis, palmieri doar langa port, "
          "hibiscus si bougainvillea peste ziduri de corali, drumul prin sat, cheiul "
          "cu scari si 6-8 barci de pescari; sub drum marea (tetrapozii NU se iau)"),
    # cheiul singur: bazinul portului in coltul golfului.
    "A_port": ("v02", (520, 460, 990, 640), (255, 220, 40),
               "cheiul de beton cu scari si babale, barci de pescari (albastre/albe), "
               "plase si flotoare, apa turcoaz calma a bazinului, gard de lemn"),
    # A din iter1: aceeasi camera; satul are recuzita mica (automate rosii,
    # adapost de autobuz, felinar de port). Doar densitate si recuzita mica.
    "A_iter1": ("it1", (70, 340, 980, 650), (255, 220, 40),
                "DENSITATE satului (iter1): aceeasi camera; recuzita mica (automate, "
                "adapost de autobuz, stalpi, felinar de port) la marginea drumului "
                "(tetrapozii-bolovani din iter1 NU se iau)"),
    # B: aleea de fukugi pe latura STANGA a insulei: sirul des de arbori inchisi
    # la culoare, cu aleea de nisip crem intre ziduri joase.
    "B": ("v02", (40, 190, 400, 570), (255, 140, 40),
          "aleea de fukugi: sir des de arbori verde-inchis, alee de nisip "
          "coraligen crem intre ziduri joase de corali, case in spatele zidurilor, "
          "masina galbena pe alee; coroane care se inchid (tunelul)"),
    # B din iter1 NU se ia: iter1 are asfalt cu chiparosi in locul aleii de nisip
    # (defectul nr. 1 al primei generari, brief §9.2); arborii conici de acolo nu
    # sunt fukugi.
    # C: trestia: terenul urca spre castel; panouri mari de trestie
    # verde-galbuie, egrete albe, bivolul.
    "C": ("v02", (270, 150, 930, 430), (240, 90, 60),
          "campul de trestie de zahar: panouri dese verde-galbui in randuri, "
          "egrete albe, bivol de apa, drum care urca pe margine spre castel"),
    # C din iter1: campuri separate de ziduri joase de piatra si poteci,
    # trestia in petice, mai multa varietate de verde.
    "C_iter1": ("it1", (270, 150, 930, 430), (240, 90, 60),
                "DENSITATE campului (iter1): panouri de trestie separate de ziduri de "
                "piatra si poteci, nuante diferite de verde-galben (asfaltul/potecile "
                "din iter1 NU se iau: in joc e un singur drum)"),
    # D: castelul: zidurile curbe de calcar gri-crem, pinii Ryukyu rasuciti,
    # palatul rosu pe platforma, poarta rosie.
    "D": ("v02", (330, 30, 1060, 270), (230, 40, 40),
          "castelul pe creasta: ziduri curbe de calcar gri-crem cu colturi "
          "rotunjite (6-10 m), pini Ryukyu rasuciti cu coroane turtite, palatul "
          "rosu cu doua nivele, poarta rosie; drumul in S-uri la baza zidurilor"),
    # poarta + palatul de aproape: lac rosu, acoperis in doua trepte cu olane si
    # mortar alb, ornamente aurii. Poarta in diorama sta pe un drum lateral:
    # NU se ia pozitia, doar materia.
    "D_poarta": ("v02", (520, 30, 800, 190), (230, 40, 40),
                 "poarta Ryukyu si palatul: stalpi rosii lacuiti, acoperis in doua "
                 "trepte de olane rosii cu mortar alb, ornamente aurii (poarta in "
                 "diorama e pe un drum lateral: pozitia NU se ia)"),
    # E: capul: cornisa pe buza falezei, stanci de calcar rase la baza de val,
    # farul alb pe varf, marea dedesubt.
    "E": ("v02", (860, 110, 1240, 440), (150, 60, 200),
          "capul de calcar: faleza gri-crem cu tufe verzi, stanci-ciuperca roase la "
          "baza de val, farul alb pe varf, drumul pe buza falezei fara parapet cu "
          "marea albastra dedesubt"),
    # F: podul: turnuri gemene de beton, traveea ridicata, feribotul alb cu
    # doua punti sub ea, apa turcoaz a golfului.
    "F": ("v02", (870, 230, 1310, 560), (40, 120, 230),
          "podul: doi piloni subtiri de beton gri, traveea ridicata, feribotul alb "
          "cu doua punti pe canal, apa turcoaz a golfului, stanci pe mal"),
    # G: insula mica: plaja de nisip alb, pandanus cu radacini aeriene, stanci
    # de calcar in apa putin adanca, drumul de plaja.
    "G": ("v02", (880, 480, 1536, 900), (60, 190, 90),
          "insula mica: plaja de nisip alb-crem, pandanus cu radacini aeriene (nu "
          "cocotieri), stanci de calcar si bolovani in apa turcoaz, drumul de plaja "
          "in curba, o singura stanca-inima (in diorama sunt doua: NU se ia a doua)"),
    # G: tromba pe peretele de furtuna: doar pentru culoarea norilor si a
    # spumei: panza gri-alb pe fundal ardezie.
    "G_tromba": ("v02", (1230, 90, 1536, 620), (60, 190, 90),
                 "tromba si peretele de furtuna: panza gri-alb de spuma si ceata pe "
                 "norii ardezie, apa sparta la baza (HAZARD din cod: doar culoarea)"),
    # H: digul: tetrapozi mari de beton gri, spuma, valul care trece peste drum,
    # apa albastra in larg. Sat in stanga.
    "H": ("v02", (60, 520, 960, 870), (230, 140, 200),
          "digul: tetrapozi mari de beton gri-deschis pe partea dinspre larg, hula "
          "albastra cu creste albe, valul care trece peste sosea in spuma, drumul "
          "jos pe dig, golful turcoaz calm pe dreapta"),
    # valul singur: spuma in fata unei masini; doar pentru forma spumei.
    "H_val": ("v02", (330, 540, 830, 740), (230, 140, 200),
              "valul si spuma: creasta alba fatetata care trece peste asfalt, stropi "
              "pe tetrapozi, albastru adanc in larg (HAZARD din cod: doar spuma)"),
    # orizontul: conul Iejima la stanga, insule joase, cumulus, peretele de
    # furtuna la dreapta.
    "ORIZONT": ("v02", (0, 0, 1536, 210), (120, 120, 255),
                "orizontul: conul unei insule departate in ceata (stanga), insule "
                "joase, cumulus mari pe cer albastru, peretele de furtuna ardezie la "
                "dreapta-sus"),
}


def load(path: str) -> Image.Image:
    im = Image.open(path).convert("RGB")
    assert im.size == SIZE, "%s are %s, se astepta %s" % (path, im.size, SIZE)
    return im


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/track_briefs/img/bar_okinawa")
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
        line = "%-10s %-4s box %-22s -> %dx%d (x%.1f)  %s" % (
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
