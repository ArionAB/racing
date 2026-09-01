"""Profilul siluetei unui horn pe CAPTURA: latimea la 7 cote, raportata la baza.

De ce exista (runda 16). Lead-ul a masurat pe poza si a gasit ca hornurile
noastre sunt STICLE, nu conuri: latimea, de sus in jos, iesea

    0.40  0.47  0.72  0.98  0.98  0.97  1.00

adica sare la aproape maxim pe la 40% din inaltime si apoi ramane PLATA. Un con
adevarat urca uniform de la ~0.2 la 1.0.

Sondele de mesh nu raspund la intrebarea asta, si a costat o incercare gresita
sa se vada de ce: pe SUPRAFATA CORPULUI profilul era deja aproape liniar (raza
la 7 cote, abatere 0.05), fiindca umflatura nu e in raza conului — e in POALA
DE GROHOTIS, care e alta suprafata si pe care sonda de corp o excludea. Ochiul
nu vede suprafete, vede conturul; deci masura corecta e conturul, pe pixeli.

  python tools/bar/cone_profile.py captura.png --box x0,y0,x1,y1
  python tools/bar/cone_profile.py captura.png --box ... --tinta 0.25

Caseta trebuie sa contina hornul PE CER (separarea e pe luminanta fata de cer,
la fel ca in `cap_silhouette.py`) si sa mearga de la varf pana la sol.

Iese: latimea in pixeli la 7 cote egale, aceleasi cifre normalizate la baza
(de la VARF spre BAZA, ca la lead), si abaterea maxima de la rampa liniara.
"""
import argparse
from PIL import Image

SAMPLES = 7


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--box", required=True, help="x0,y0,x1,y1 in pixeli")
    ap.add_argument("--tinta", type=float, default=0.25,
                    help="latimea relativa a gatului in rampa ideala")
    ap.add_argument("--prag", type=float, default=28.0,
                    help="cat sub luminanta cerului incepe silueta")
    a = ap.parse_args()
    x0, y0, x1, y1 = [int(v) for v in a.box.split(",")]
    im = Image.open(a.image).convert("L")
    px = im.load()

    sky = sum(px[x, y0] for x in range(x0, x1)) / float(x1 - x0)
    thr = sky - a.prag

    rows = []
    for y in range(y0, y1):
        xs = [x for x in range(x0, x1) if px[x, y] < thr]
        rows.append(xs[-1] - xs[0] + 1 if xs else 0)

    # Varful REAL: primul rand cu silueta. Caseta se poate da mai larga decat
    # hornul fara sa strice cifra.
    top = next((i for i, w in enumerate(rows) if w > 0), None)
    if top is None:
        print("caseta nu contine silueta — verifica pragul si coordonatele")
        return
    # POALA REALA = primul rand de latime maxima, nu marginea casetei.
    #
    # Sub el silueta nu mai e hornul, e terenul din fata lui: latimea ramane
    # blocata pe maxim si ultimele doua esantioane ies mereu 1.00 si 1.00.
    # Prima versiune a sondei citea asa si palierul din cifra era al ei, nu al
    # geometriei — masurat pe acelasi cadru, hornul atingea 104 px la y=305 iar
    # caseta cobora pana la 345, deci un sfert din "inaltime" era pamant.
    wmax = max(rows)
    bot = next(i for i, w in enumerate(rows) if w >= wmax)
    h = bot - top
    if h < 14:
        print("silueta prea scurta (%d px) ca sa aiba profil" % h)
        return

    widths = [rows[top + int(round(h * i / (SAMPLES - 1.0)))]
              for i in range(SAMPLES)]
    base = float(widths[-1]) or 1.0
    ratios = [w / base for w in widths]

    print("inaltime silueta: %d px  (y %d..%d)" % (h, y0 + top, y0 + bot))
    print("latimi px, VARF->BAZA: " + "  ".join("%3d" % w for w in widths))
    print("raport,   VARF->BAZA: " + "  ".join("%.2f" % r for r in ratios))
    ideal = [a.tinta + (1.0 - a.tinta) * i / (SAMPLES - 1.0)
             for i in range(SAMPLES)]
    print("rampa tinta:          " + "  ".join("%.2f" % r for r in ideal))
    dev = max(abs(ratios[i] - ideal[i]) for i in range(SAMPLES))
    print("abatere max de la rampa: %.3f" % dev)
    # Palierul e defectul numit de lead: doua esantioane vecine aproape egale
    # in treimea de jos inseamna ca silueta a incetat sa creasca.
    flat = max(ratios[i + 1] - ratios[i] for i in range(SAMPLES - 4, SAMPLES - 1))
    print("cea mai mica crestere in treimea de jos: %.3f "
          "(sub 0.05 = palier, adica sticla)" % flat)


main()

def convexity(prof):
    """Criteriul care separa "con drept" de "sticla" — si monotonia NU o face.

    Criticul orb, runda 16: "monotonia nu e invariantul care conteaza.
    Invariantul e CONVEXITATEA: punctul cel mai lat trebuie sa fie la contactul
    cu solul, iar a doua diferenta a razei nu are voie sa devina pozitiva. O
    sonda care raporteaza abaterea-de-la-liniar ca un singur scalar nu poate
    deosebi «con drept» de «umar plus gat care se mediaza la drept»."

    Verificat: doua profile monotone, unul con si unul sticla, au abateri medii
    de 0.009 si 0.054 — dar a doua diferenta arata +0.08 pe umarul sticlei acolo
    unde conul e plat.
    """
    d2 = [prof[i + 1] - 2.0 * prof[i] + prof[i - 1]
          for i in range(1, len(prof) - 1)]
    worst = max(d2) if d2 else 0.0
    return d2, worst
