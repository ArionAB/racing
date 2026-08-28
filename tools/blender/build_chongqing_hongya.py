"""Chongqing — Hongya Dong, eroul vizual al pistei (plansa, pozitia 1).

  structures/hongya_dong.glb   ~44 x 22 x 40 m, 11 etaje de case pe piloni

Piesa asta e motivul pentru care exista pista (brief §2, POI D): drumul iese
pe buza falezei si SUB tine se deschid unsprezece etaje de case de lemn pe
piloni, luminate auriu. E singurul lucru din joc care se vede exclusiv de sus.

Trei decizii, toate din brief §2.0 (verificarea cu camera):

1. **Se vede DE SUS si din lateral, deci detaliul sta pe ACOPERISURI si pe
   fatada dinspre rau.** Spatele — lipit de faleza — nu primeste nimic.
   Plansa arata exact asta: vederea TOP e o mare de acoperisuri curbate, si
   aia e vederea de joc.
2. **Etajele sunt in TREPTE, retrase spre spate.** Un bloc drept de 40 m ar
   citi ca o cutie; retragerea e cea care face silueta sa se "agate" de
   faleza si care lasa fiecare acoperis vizibil de sus.
3. **Ferestrele aprinse sunt GEOMETRIE aici, nu textura.** Regula generala a
   pistei (brief §4) le pune in textura de clasa `facade_night` — corect
   pentru cele 30 de blocuri de fundal. Dar asta e piesa pe care camera o
   priveste de la 30 m, in centrul cadrului: aici o pata aprinsa e slot
   LAVA_ORANGE pe o fata retrasa, ca sa aiba adancime si sa prinda AO.
   Un asset, nu o clasa — deci nu incalca bugetul de materiale.

Acoperisurile curbate se fac din DOUA pante cu inclinari diferite (streasina
mai lina decat coama) plus colturi ridicate. Un acoperis chinezesc facut din
doua ape drepte arata elvetian; curbura e toata identitatea.

Rulare:
    blender --background --factory-startup \
        --python tools/blender/run_build.py -- build_chongqing_hongya.py
"""

import math
from mathutils import Matrix, Vector

AO_HERO = dict(samples=28, dist=9.0, gradient="vertical",
               low=0.38, high=1.00, power=0.85, floor=0.10)

TIMBER = LOG_DARK          # structura de lemn inchis a caselor pe piloni
TIMBER_L = WOOD            # lemnaria mai deschisa: balustrade, tamplarie
ROOF = VOLCANIC_BLACK      # olane inchise (plansa: acoperisuri aproape negre)
GLOW = LAVA_ORANGE         # ferestre aprinse — lumina calda, accentul pistei
LANTERN = KERB_RED         # lampioanele rosii de pe streasina


def curved_roof(b, cx, cy, z, w, d, slot=ROOF, rise=None, up_corners=True):
    """Acoperis chinezesc: doua pante pe fiecare parte + colturi ridicate.

    Curbura se aproximeaza cu DOUA felii per apa: una lina langa coama, una
    mai abrupta spre streasina — inversul unui acoperis european. Diferenta
    de unghi (18° vs 34°) e ce citeste ochiul ca "curbat" de la 30 m, fara
    sa coste un loft adevarat.
    """
    # Panta coboara pe ADANCIME (fata->spate), nu pe latimea fatadei: un corp
    # de 40 m lung ar primi altfel un acoperis de 11 m, mai inalt decat casa
    # de sub el. Coama merge PE LUNGUL fatadei, ca la orice casa cu doua ape.
    # Inaltimea acoperisului: ~0.34 din adancime. Peste atat feliile se
    # apropie de verticala si de sus (vederea de joc) citesc ca niste ARIPI
    # subtiri, nu ca olane — exact ce a aratat a treia randare de control.
    rise = rise if rise is not None else d * 0.34
    half_d = d * 0.5
    t = 0.22
    for sy in (-1.0, 1.0):
        # Felia dinspre coama e cea ABRUPTA, cea dinspre streasina se
        # APLATIZEAZA si zboara in afara. Asta e ordinea corecta a unui
        # acoperis chinezesc — invers decat aveam, si inversul e chiar ce
        # deosebeste silueta asta de un acoperis alpin.
        y_in, z_in = 0.0, z + rise
        y_mid, z_mid = sy * half_d * 0.58, z + rise * 0.42
        # streasina: aproape orizontala, iesita mult peste galerie
        y_out, z_out = sy * (half_d + 1.15), z + rise * 0.16
        for (ya, za, yb, zb) in ((y_in, z_in, y_mid, z_mid),
                                 (y_mid, z_mid, y_out, z_out)):
            dy, dz = (yb - ya), (zb - za)
            ln = math.hypot(dy, dz)
            # Rotatia in jurul lui X duce +Y in (0, cos t, sin t), deci semnul
            # e +ang, nu -ang. Cu semnul gresit cele doua ape se rotesc invers
            # si acoperisul se DESFACE in doua placi plate cu o fanta la coama
            # (a patra randare de control: doua aripi, nici un acoperis).
            ang = math.atan2(dz, dy)
            rot = Matrix.Rotation(ang, 3, "X")
            b.box((cx, cy + (ya + yb) * 0.5, (za + zb) * 0.5 - t * 0.25),
                  (w + 1.0, ln, t), slot, rotation=rot)
    # coama groasa, pe lungul fatadei
    b.box((cx, cy, z + rise + 0.10), (w + 1.1, 0.55, 0.28), slot)
    if up_corners:
        # colturile ridicate: cate un mic bloc inclinat la capetele streasinii.
        # Fara ele acoperisul e doar un cort; cu ele e chinezesc.
        for sx in (-1.0, 1.0):
            for sy in (-1.0, 1.0):
                b.box((cx + sx * (w * 0.5 + 0.35), cy + sy * (half_d + 0.72),
                       z + rise * 0.20),
                      (1.0, 0.95, 0.24), slot,
                      rotation=Matrix.Rotation(sy * math.radians(24.0), 3, "X"))


def lit_window(b, x, y, z, w=1.45, h=1.15, face=1.0):
    """Fereastra aprinsa: gol retras + tamplarie. `face` = +1 spre +Y, -1 spre -Y.

    Retragerea de 12 cm e ce face pata sa prinda AO si sa citeasca a gol, nu a
    autocolant (vezi Builder.window, aceeasi lectie).
    """
    b.box((x, y - face * 0.12, z), (w, 0.14, h), GLOW)
    # tamplarie: un montant + o traversa, in lemn deschis
    b.box((x, y, z), (0.07, 0.10, h + 0.06), TIMBER_L)
    b.box((x, y, z), (w + 0.06, 0.10, 0.07), TIMBER_L)
    # cadrul
    for sx in (-1.0, 1.0):
        b.box((x + sx * (w * 0.5 + 0.05), y, z), (0.10, 0.12, h + 0.16), TIMBER)
    for sz in (-1.0, 1.0):
        b.box((x, y, z + sz * (h * 0.5 + 0.05)), (w + 0.20, 0.12, 0.10), TIMBER)


def balcony(b, x0, x1, y, z, slot=TIMBER):
    """Balcon-galerie pe toata fatada: podea in consola + balustrada deasa.

    Galeriile astea sunt orizontalele care rup fatada in benzi si care, de sus,
    dau umbra intre etaje. Fara ele cladirea e un perete cu pete galbene.
    """
    w = x1 - x0
    b.box(((x0 + x1) * 0.5, y, z), (w, 1.15, 0.20), slot)          # podea
    # balustrada: montanti desi + mana curenta (nu `railing`: aici vrem
    # profilul chinezesc, sipci verticale dese, nu doua lise)
    # Pasul sipcilor: 0.55 m, nu 0.34. Pe 40 m de fatada x 10 galerii,
    # diferenta e ~18k triunghiuri — iar de la 30 m (distanta de la care se
    # vede piesa) o sipca la 34 cm si una la 55 cm dau acelasi gri. Ce
    # citeste e RITMUL, nu numarul.
    b.pickets((x0 + 0.15, y + 0.48, z + 0.10), (x1 - 0.15, y + 0.48, z + 0.10),
              0.55, (0.09, 0.09, 0.78), slot)
    b.box(((x0 + x1) * 0.5, y + 0.48, z + 0.92), (w, 0.14, 0.14), TIMBER_L)
    # consolele de sub podea, la ~2.4 m
    n = max(int(w / 2.4), 2)
    for i in range(n):
        xx = x0 + w * (i + 0.5) / n
        b.beam((xx, y - 0.35, z - 0.12), (xx, y + 0.52, z - 0.34), 0.16, slot)


def tier(b, x0, x1, y_front, z_base, height, floors, seed):
    """Un corp de cladire: pereti, galerii pe fiecare nivel, ferestre aprinse.

    `y_front` e fatada dinspre rau (spre +Y). Spatele se inchide plat la
    y_front - depth: nu se vede niciodata (brief: "nimic pe spate").
    """
    depth = 7.0
    y_back = y_front - depth
    w = x1 - x0
    xc = (x0 + x1) * 0.5
    rand = _lcg(seed)
    fh = height / floors
    # corpul: un volum inchis, in lemn inchis
    b.box((xc, (y_front + y_back) * 0.5, z_base + height * 0.5),
          (w, depth, height), TIMBER)
    for f in range(floors):
        z = z_base + fh * (f + 0.5)
        # galerie pe fatada
        balcony(b, x0 + 0.3, x1 - 0.3, y_front + 0.12, z_base + fh * f + 0.16)
        # Ferestre aprinse: pe FIECARE travee, si travei mai dese.
        #
        # Aici era gaura care facea hero-ul o silueta maro: la 0.62 x 0.78 m,
        # o travee la 2.1 m si doar 65% aprinse, slotul GLOW iesea 1.9% din
        # aria piesei. Masurat pe captura --driver: 0.00% pixeli „aprinsi",
        # fata de 3.92% in diorama de referinta. Ce citeste ochiul ca „lume
        # locuita" e RAPORTUL fereastra/lemn de pe fatada, iar in referinta
        # fatada e mai mult geam decat perete.
        #
        # Nu se rezolva din emisie: sa aprinzi lemnul (60% din arie) da un
        # perete portocaliu plat — incercat si masurat, dev 97 si 45% pixeli
        # aprinsi, adica exact opusul. Lemnul TREBUIE sa ramana inchis;
        # contrastul e cel care face lumina sa se citeasca.
        n = max(int(w / 1.75), 1)
        for i in range(n):
            lit_window(b, x0 + w * (i + 0.5) / n, y_front + 0.06, z + 0.12)
        # ...si pe capetele laterale, ca silueta sa arda si din trei-sferturi:
        # camera prinde cornisa in viraj, deci fatada frontala nu e singura
        # care se vede.
        for sx, xx in ((-1.0, x0), (1.0, x1)):
            b.box((xx - sx * 0.12, y_front - depth * 0.42, z + 0.12),
                  (0.14, 1.30, 1.05), GLOW)
        # lampioane rosii pe streasina galeriei, rar
        if rand() > 0.55:
            lx = x0 + w * (0.2 + 0.6 * rand())
            b.cylinder((lx, y_front + 0.55, z_base + fh * f + 1.28), 0.16, 0.30,
                       LANTERN, segments=6)
    return depth


def build_hongya():
    b = Builder()

    # --- pilonii: cladirea nu sta pe pamant, e agatata de faleza -------------
    # Ei sunt jumatate din poveste: "case pe piloni". Se vad de sus, printre
    # etajele retrase, si de pe cheiul de jos.
    STILT_TOP = 7.0
    for i in range(9):
        x = -19.0 + i * 4.7
        for j, yy in enumerate((1.5, -3.0)):
            h = STILT_TOP + (1.2 if j else 0.0)
            b.cylinder((x, yy, h * 0.5), 0.34, h, TIMBER, segments=6)
        # contravantuire in X intre piloni (se citeste de jos)
        if i < 8:
            x2 = x + 4.7
            b.beam((x, 1.5, 1.2), (x2, 1.5, STILT_TOP - 0.6), 0.20, TIMBER)
            b.beam((x2, 1.5, 1.2), (x, 1.5, STILT_TOP - 0.6), 0.20, TIMBER)
    # platforma pe care stau casele
    b.box((0.0, -0.7, STILT_TOP + 0.25), (42.0, 12.0, 0.55), TIMBER)

    # --- corpurile in trepte -------------------------------------------------
    # Fiecare corp e mai scurt si mai retras decat cel de sub el: asa raman
    # acoperisurile vizibile de sus si silueta se "agata" de faleza.
    # (x0, x1, y_fata, z_baza, inaltime, etaje)
    BODIES = [
        (-20.0, 20.0, 5.0, STILT_TOP + 0.5, 10.5, 3),
        (-17.0, 16.0, 2.6, STILT_TOP + 11.0, 10.5, 3),
        (-13.0, 11.5, 0.4, STILT_TOP + 21.5, 7.0, 2),
        (-8.0, 6.0, -1.6, STILT_TOP + 28.5, 7.0, 2),
    ]
    for k, (x0, x1, yf, zb, h, fl) in enumerate(BODIES):
        tier(b, x0, x1, yf, zb, h, fl, seed=11 + k * 7)
        # Acoperisul NU e o singura coama de 40 m: e un rand de module cu
        # coame proprii, la cote usor diferite. Asta e ce se vede de sus
        # (vederea de joc) si e diferenta dintre "hala industriala" si
        # "gramada de case agatate una de alta" — plansa arata exact un
        # mozaic de acoperisuri, nu o creasta continua.
        span = x1 - x0
        mods = max(int(round(span / 9.0)), 2)
        rand = _lcg(101 + k * 13)
        for m in range(mods):
            mx0 = x0 + span * m / mods
            mx1 = x0 + span * (m + 1) / mods
            jog = (rand() - 0.5) * 0.9          # cote putin diferite
            depth = 7.6 + rand() * 1.2
            curved_roof(b, (mx0 + mx1) * 0.5, yf - 3.4, zb + h + jog,
                        (mx1 - mx0) - 0.5, depth)

    # --- pavilioane pe acoperisul de sus ------------------------------------
    # Plansa are doua turnulete peste corpul superior. Ele dau varful siluetei
    # si se vad primele cand privesti in jos de pe cornisa.
    for sx in (-1.0, 1.0):
        px = sx * 3.6
        pz = STILT_TOP + 35.5
        for i in range(4):
            b.cylinder((px + (i % 2 - 0.5) * 2.6, -1.6 + (i // 2 - 0.5) * 2.6,
                        pz + 1.35), 0.20, 2.7, TIMBER, segments=6)
        b.box((px, -1.6, pz + 0.16), (6.2, 6.2, 0.32), TIMBER)
        lit_window(b, px, 1.3, pz + 1.5, w=1.5, h=1.4)
        curved_roof(b, px, -1.6, pz + 2.7, 7.0, 6.6, rise=2.3)

    # --- stanca de sub piloni ----------------------------------------------
    # Cateva lespezi la baza: cladirea trebuie sa iasa DIN faleza, nu sa stea
    # pe o masa. Se vad de pe chei.
    for i, (x, y, s) in enumerate(((-15.0, -4.5, 5.0), (-2.0, -5.2, 6.2),
                                   (12.0, -4.0, 5.4), (19.0, -3.0, 3.8))):
        b.rock((x, y, 0.6), (s, s * 0.8, 2.4), ROCK_DARK, seed=3 + i,
               segments=6, rings=3)

    return b.to_object("HongyaDong")


clear_built()
obj = build_hongya()
stats = finish(obj, bevel=0.05, ao=AO_HERO, origin="base")
path, size = export_glb([obj], "chongqing/structures/hongya_dong.glb")
print("hongya_dong.glb  tris=%d  ao=%.2f..%.2f  %.1f kB"
      % (stats["tris"], stats["ao_min"], stats["ao_max"], size / 1024.0))
