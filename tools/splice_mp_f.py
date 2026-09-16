# -*- coding: utf-8 -*-
"""Lipeste fragmentul POI F in Track15.tscn, idempotent.

Sterge tot ce a pus rularea precedenta (nodurile al caror `parent` e zona F si
sub-resursa `BoxShape3D_F_rau`), apoi insereaza continutul proaspat. De aceea se
poate rula de cate ori e nevoie fara sa dubleze nimic.

  python tools/splice_mp_f.py <zoneF.part>

Sub-resursa merge in ANTET (inainte de primul [node]), nodurile merg imediat
dupa `[node name="ZoneF_MalulRaului" ...]`. Regula din memoria
`tscn-comentariu-taie-proprietati` e respectata: nu se scrie niciun `#` intre
proprietatile unui nod.
"""
import io
import re
import sys

TSCN = "scenes/tracks/Track15.tscn"
ZONE = 'DecorManual/ZoneF_MalulRaului'
ZONE_HDR = '[node name="ZoneF_MalulRaului" type="Node3D" parent="DecorManual"]'


def main(part_path):
    part = io.open(part_path, encoding="utf-8").read().rstrip("\n")
    sub_path = part_path.rsplit(".", 1)[0] + ".subres"
    try:
        sub = io.open(sub_path, encoding="utf-8").read().rstrip("\n")
    except IOError:
        sub = ""

    src = io.open(TSCN, encoding="utf-8").read()
    bom = src.startswith("﻿")
    if bom:
        src = src[1:]

    # --- 1. scoate ce a pus rularea precedenta -------------------------------
    blocks = re.split(r"(?m)^(?=\[(?:node|sub_resource|ext_resource|gd_scene)\b)", src)
    kept = []
    for b in blocks:
        if b.startswith("[node ") and ('parent="%s"' % ZONE) in b.split("\n")[0]:
            continue
        if b.startswith("[node ") and ('parent="%s/' % ZONE) in b.split("\n")[0]:
            continue
        if b.startswith("[sub_resource") and 'id="BoxShape3D_F_rau"' in b.split("\n")[0]:
            continue
        kept.append(b)
    src = "".join(kept)

    # --- 2. sub-resursa in antet, inaintea primului [node] -------------------
    if sub:
        i = src.index("[node ")
        src = src[:i] + sub + "\n\n" + src[i:]

    # --- 3. nodurile, imediat dupa antetul zonei ----------------------------
    if ZONE_HDR not in src:
        raise SystemExit("nu gasesc antetul zonei: %s" % ZONE_HDR)
    i = src.index(ZONE_HDR) + len(ZONE_HDR)
    # sari peste restul liniilor de proprietati ale nodului de zona
    j = src.index("\n\n", i) + 2 if "\n\n" in src[i:i + 400] else i + 1
    src = src[:j] + part + "\n\n" + src[j:]

    out = ("﻿" if bom else "") + src
    io.open(TSCN, "w", encoding="utf-8", newline="\n").write(out)
    n = part.count("[node ")
    print("lipit: %d noduri sub %s, %d sub-resurse" % (n, ZONE, 1 if sub else 0))


if __name__ == "__main__":
    main(sys.argv[1])
