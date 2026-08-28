"""Lipeste liniile `transform = ...` generate peste nodurile din Track12.tscn.

Intrarea e iesirea unui generator de reparatie: perechi de linii
    # <nume_nod>
    transform = Transform3D(...)
Fiecare pereche inlocuieste PRIMA linie `transform` din blocul nodului cu
numele respectiv. Daca nodul nu exista, sau daca are deja exact aceeasi
transformare, se raporteaza si nu se atinge nimic — un .tscn editat de mana
nu se rescrie pe tacute.
"""
import re
import sys


def main() -> int:
    tscn_path, fix_path = sys.argv[1], sys.argv[2]

    wanted = {}
    order = []
    name = None
    for line in open(fix_path, encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("# "):
            name = line[2:].strip()
        elif line.startswith("transform = ") and name:
            wanted[name] = line
            order.append(name)
            name = None

    lines = open(tscn_path, encoding="utf-8").read().split("\n")
    node_re = re.compile(r'^\[node name="([^"]+)"')

    changed, missing, same = 0, [], 0
    seen = set()
    i = 0
    while i < len(lines):
        m = node_re.match(lines[i])
        if not m:
            i += 1
            continue
        nm = m.group(1)
        if nm not in wanted:
            i += 1
            continue
        seen.add(nm)
        j = i + 1
        while j < len(lines) and not lines[j].startswith("[node "):
            if lines[j].startswith("transform = "):
                if lines[j] == wanted[nm]:
                    same += 1
                else:
                    lines[j] = wanted[nm]
                    changed += 1
                break
            j += 1
        i = j

    for nm in order:
        if nm not in seen:
            missing.append(nm)

    open(tscn_path, "w", encoding="utf-8").write("\n".join(lines))
    print("schimbate: %d, identice: %d, negasite: %d" % (changed, same, len(missing)))
    for nm in missing[:10]:
        print("  LIPSA:", nm)
    return 0


if __name__ == "__main__":
    sys.exit(main())
