"""Profilul de raza al hornurilor de pe CER, pe TOATE conurile din cadru si pe
TOATA inaltimea lor. Fara caseta data de mana.

De ce exista (runda 19). `cone_profile.py` masoara corect, dar cere o caseta
aleasa de om, si in runda 18 caseta a fost pusa in jurul CORPULUI hornului —
adica exact sub varf. Cifrele au iesit frumoase (abatere 0.347 -> 0.178, a doua
diferenta +0.520 -> +0.150) si raportul a spus "umarul de sticla a disparut",
in timp ce in cadru gatul si spirul negru erau intacte. Criticul: "o sonda care
nu poate vedea varful nu poate vedea gatul". Caseta era defectul, nu formula.

Deci aici nu se da nicio caseta. Sonda:
  1. separa silueta de cer pe luminanta (acelasi prag ca la `cap_silhouette`);
  2. gaseste VARFURILE ca minime locale ale liniei de orizont a siluetei —
     fiecare varf e un horn;
  3. coboara de la fiecare varf pana unde silueta se contopeste cu vecinul sau
     cu terenul, si masoara latimea la 9 cote, de la varf spre baza;
  4. raporteaza PE FIECARE CON, nu un agregat: raportul baza/max-de-deasupra
     (criteriul de profil monoton) si a doua diferenta (umarul de sticla).

Criteriul rundei 19, dat de critic:
  - baza cu cel putin 15% mai lata decat orice punct de deasupra ei
    => `baza/max_deasupra >= 1.15`
  - gatul sters => nicio strangere locala: latimea nu are voie sa scada de sus
    in jos (toleranta mica pentru zgomotul de pixeli)

  python tools/bar/skyline_cones.py captura.png
  python tools/bar/skyline_cones.py captura.png --min-h 40 --top 8
"""
import argparse
from PIL import Image

SAMPLES = 9


def load_mask(path, prag):
    """Masca binara silueta/cer, plus latimea imaginii."""
    im = Image.open(path).convert("L")
    w, h = im.size
    px = im.load()
    # Cerul: mediana randului de sus. Mediana si nu media, ca un horn care
    # atinge marginea de sus sa nu traga pragul in jos.
    row = sorted(px[x, 0] for x in range(w))
    sky = row[w // 2]
    thr = sky - prag
    mask = [[px[x, y] < thr for x in range(w)] for y in range(h)]
    return mask, w, h, sky, thr


def horizon(mask, w, h):
    """Pentru fiecare coloana, primul rand de silueta (sau None)."""
    out = []
    for x in range(w):
        y = 0
        while y < h and not mask[y][x]:
            y += 1
        out.append(y if y < h else None)
    return out


def peaks(hz, w, min_prom):
    """Varfurile: coloane unde linia de orizont e minim local, cu proeminenta.

    Proeminenta = cat trebuie sa urce linia in ambele parti inainte sa coboare
    mai jos decat varful. Fara ea, fiecare zimt de un pixel ar fi un horn.
    """
    out = []
    for x in range(w):
        if hz[x] is None:
            continue
        y = hz[x]
        # stanga
        l = x
        lmax = y
        while l > 0 and hz[l - 1] is not None and hz[l - 1] >= y:
            l -= 1
            lmax = max(lmax, hz[l])
        # dreapta
        r = x
        rmax = y
        while r < w - 1 and hz[r + 1] is not None and hz[r + 1] >= y:
            r += 1
            rmax = max(rmax, hz[r])
        prom = min(lmax - y, rmax - y)
        if prom < min_prom or not (l < x < r):
            continue
        # Umerii proprii: unde linia a urcat deja cu `prom` fata de varf.
        sl = x
        while sl > l and hz[sl - 1] - y < prom:
            sl -= 1
        sr = x
        while sr < r and hz[sr + 1] - y < prom:
            sr += 1
        out.append((x, y, prom, l, r, sl, sr))
    # Un singur varf pe platou: se pastreaza cel cu proeminenta cea mai mare
    # din fiecare grup de coloane care se suprapun.
    # Un varf = un BAZIN. Coloanele de pe acelasi platou au acelasi (l, r), deci
    # se compara intervalele: daca varful cade in bazinul unuia deja pastrat, e
    # acelasi horn vazut din alta coloana. Prima versiune cerea 12 px intre
    # varfuri si raporta conul din stanga-fata de SASE ori — palaria lui e lata
    # de 70 px si fiecare coloana de pe ea trecea de prag.
    out.sort(key=lambda t: -t[2])
    kept = []
    for p in out:
        if all(not (k[5] <= p[0] <= k[6] or p[5] <= k[0] <= p[6])
               for k in kept):
            kept.append(p)
    kept.sort(key=lambda t: t[0])
    return kept


def profile(mask, w, h, x, ytop):
    """Latimile hornului de la varful (x, ytop) in jos.

    Se coboara cat timp coloana `x` e inca in silueta si latimea inca CREȘTE
    monoton-ish; oprirea e la primul rand unde silueta locala se lipeste de un
    vecin (latime care sare brusc) sau unde se termina imaginea.
    """
    widths = []
    prev = None
    for y in range(ytop, h):
        if not mask[y][x]:
            break
        l = x
        while l > 0 and mask[y][l - 1]:
            l -= 1
        r = x
        while r < w - 1 and mask[y][r + 1]:
            r += 1
        wd = r - l + 1
        # Lipirea de vecin / de teren: latimea sare cu peste 60% intr-un rand.
        if prev is not None and prev >= 6 and wd > prev * 1.6:
            break
        widths.append(wd)
        prev = wd
    return widths


def sample(widths, n):
    if len(widths) < n:
        return None
    k = len(widths) - 1
    return [widths[int(round(k * i / (n - 1.0)))] for i in range(n)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--prag", type=float, default=28.0)
    ap.add_argument("--min-h", type=int, default=45,
                    help="inaltimea minima in pixeli ca un varf sa conteze")
    ap.add_argument("--min-prom", type=int, default=14,
                    help="proeminenta minima a varfului, in pixeli")
    ap.add_argument("--top", type=int, default=10,
                    help="cate conuri se raporteaza (cele mai inalte)")
    a = ap.parse_args()

    mask, w, h, sky, thr = load_mask(a.image, a.prag)
    hz = horizon(mask, w, h)
    ps = peaks(hz, w, a.min_prom)

    cones = []
    for x, ytop, prom, _l, _r, _sl, _sr in ps:
        ws = profile(mask, w, h, x, ytop)
        if len(ws) < a.min_h:
            continue
        s = sample(ws, SAMPLES)
        if s is None or s[-1] == 0:
            continue
        base = float(s[-1])
        rat = [v / base for v in s]
        # Criteriul 1: baza cu 15% mai lata decat ORICE punct de deasupra.
        mx = max(rat[:-1])
        widen = 1.0 / mx if mx > 0 else 0.0
        # Criteriul 2: gatul. Orice scadere de sus in jos e o strangere.
        neck = max((rat[i] - rat[i + 1]) for i in range(SAMPLES - 1))
        # Umarul de sticla: a doua diferenta pozitiva.
        d2 = [rat[i + 1] - 2.0 * rat[i] + rat[i - 1]
              for i in range(1, SAMPLES - 1)]
        cones.append((len(ws), x, ytop, rat, widen, neck, max(d2)))

    if not cones:
        print("niciun con gasit (cer %.0f, prag %.0f)" % (sky, thr))
        return
    cones.sort(key=lambda c: -c[0])
    cones = cones[:a.top]

    print("cer %.0f, prag %.0f — %d conuri" % (sky, thr, len(cones)))
    print("")
    print("  x   h_px  profil VARF->BAZA (raportat la baza)"
          "                        baza/max  gat   d2max")
    bad_w = bad_n = 0
    for hpx, x, ytop, rat, widen, neck, d2m in cones:
        flag = ""
        if widen < 1.15:
            flag += " LAT"
            bad_w += 1
        if neck > 0.02:
            flag += " GAT"
            bad_n += 1
        print("%4d %5d  %s   %.2f  %+.3f %+.3f%s"
              % (x, hpx, " ".join("%.2f" % r for r in rat),
                 widen, neck, d2m, flag))
    print("")
    print("baza/max: cat e baza mai lata decat cel mai lat punct de deasupra "
          "(tinta >= 1.15)")
    print("gat:      cea mai mare STRANGERE de sus in jos (tinta <= 0.02)")
    print("VERDICT: %d/%d prea inguste la baza, %d/%d cu gat"
          % (bad_w, len(cones), bad_n, len(cones)))


main()
