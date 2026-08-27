import io, sys

TSCN = "scenes/tracks/Track12.tscn"
MARK = '[node name="1) Piata'

gen_path = sys.argv[1]
scene = io.open(TSCN, encoding="utf-8").read().split("\n")
gen = io.open(gen_path, encoding="utf-8").read().split("\n")

gi = [i for i, l in enumerate(gen) if l.startswith(MARK)][0]
body = [l for l in gen[gi:] if not l.startswith("; ")]
while body and body[-1].strip() == "":
    body.pop()

hi = [i for i, l in enumerate(scene) if l.startswith(MARK)][0]
io.open(TSCN, "w", encoding="utf-8").write("\n".join(scene[:hi] + body) + "\n")

n = sum(1 for l in body
        if l.startswith("[node name=") and 'parent="DecorManual/' in l)
print("piese:", n)
