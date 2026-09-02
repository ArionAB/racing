"""Latimea PALARIEI fata de latimea GATULUI, in pixeli, pe silueta din captura.

De ce in pixeli si nu pe mesh: sonda de mesh (`probe_capp_palarie`) imparte
inaltimea in felii pornind de la AABB — dar AABB-ul se schimba cand poala de
moloz coboara sub baza, deci indicii de felie aluneca si "palaria" masurata nu
mai e palaria. Silueta pe ecran nu are ambiguitatea asta: e chiar ce vede ochiul.

  python tools/bar/cap_silhouette.py captura.png --box 800,90,990,290

Se cere o caseta care contine hornul PE CER (fundalul trebuie sa fie cer, ca
separarea se face pe luminanta fata de cer). Iese, pe fiecare rand:
  latimea siluetei in pixeli.
Si, agregat:
  depasire = latimea palariei / latimea gatului de sub ea
  zveltete = inaltimea palariei / latimea ei

Masurat pe captura de la inceputul rundei 15, pe hornul din dreapta (caseta
810,100,980,240): depasire 2.17x, adica o farfurie. Tinta, dupa descrierea din
referinta ("palarii conice mai stranse, asezate pe umar"): depasire sub 1.55x,
fara sa scada zveltetea sub 0.40 — o palarie stramta si PLATA e tot farfurie.
"""
import argparse
from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--box", required=True, help="x0,y0,x1,y1 in pixeli")
    ap.add_argument("--rows", action="store_true", help="tipareste fiecare rand")
    a = ap.parse_args()
    x0, y0, x1, y1 = [int(v) for v in a.box.split(",")]
    im = Image.open(a.image).convert("L")
    px = im.load()

    # Cerul e cel mai luminos lucru din caseta; se ia pragul din coltul de sus.
    sky = sum(px[x, y0] for x in range(x0, x1)) / float(x1 - x0)
    thr = sky - 28.0

    widths = []
    for y in range(y0, y1):
        xs = [x for x in range(x0, x1) if px[x, y] < thr]
        w = 0
        if xs:
            w = xs[-1] - xs[0] + 1
        widths.append((y, w))

    if a.rows:
        for y, w in widths:
            print("y=%4d  %3d px" % (y, w))

    ws = [w for _, w in widths if w > 0]
    if not ws:
        print("caseta nu prinde silueta (prag %.0f, cer %.0f)" % (thr, sky))
        return

    # Palaria e primul MAXIM LOCAL de sus in jos, nu maximul casetei: mai jos
    # silueta se largeste iar (corpul hornului, si vecinii care intra in caseta),
    # iar maximul global cadea acolo — de-aia prima varianta raporta 1.00x pe un
    # con care se vede clar a farfurie. Se coboara pana latimea scade sub 88% din
    # ce s-a atins, si acolo se opreste palaria.
    first = next(i for i, (_, w) in enumerate(widths) if w > 0)
    wmax = 0
    imax = first
    for i in range(first, len(widths)):
        w = widths[i][1]
        if w > wmax:
            wmax = w
            imax = i
        elif w < wmax * 0.88:
            break
    ymax = widths[imax][0]

    # Gatul: cel mai ingust rand imediat SUB palarie, cat timp silueta scade sau
    # sta pe loc. Se opreste cand incepe iar sa creasca (acolo e umarul).
    neck = wmax
    i = imax
    while i + 1 < len(widths):
        w = widths[i + 1][1]
        if w == 0:
            break
        if w > neck * 1.12:
            break
        neck = min(neck, w)
        i += 1
    neck = max(neck, 1)

    # Inaltimea palariei: randurile mai late decat gatul cu 8%.
    lim = neck * 1.08
    top = imax
    while top > 0 and widths[top - 1][1] > lim:
        top -= 1
    bot = imax
    while bot + 1 < len(widths) and widths[bot + 1][1] > lim:
        bot += 1
    hp = bot - top + 1
    print("palarie: latime max %d px la y=%d, inaltime %d px" % (wmax, ymax, hp))
    print("gat:     %d px" % neck)
    print("depasire = %.2fx   zveltete = %.2f" % (wmax / float(neck), hp / float(wmax)))


main()
