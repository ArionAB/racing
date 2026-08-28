# -*- coding: utf-8 -*-
"""Inlocuieste cele patru sectiuni DecorManual din Track12.tscn cu iesirea
generatorului. Perimetru strict: nu atinge nimic in afara blocului A-D."""
import io,sys
SCR=r'C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/956012ed-f1b0-41d6-b5fd-4ca3f7240bd5/scratchpad'
tp='scenes/tracks/Track12.tscn'
s=io.open(tp,encoding='utf-8').read()
gen=io.open(SCR+'/gen4.txt',encoding='utf-8').read()
gen=gen[gen.index('[node name="1) Piata Kuixinglou"'):].rstrip()+'\n'
lines=s.split('\n')
start=None;end=None
for i,l in enumerate(lines):
    if l.startswith('[node name="1) Piata Kuixinglou" type="Node3D" parent="DecorManual"]'):
        start=i
    if l.startswith('[node ') and start is not None and 'parent="DecorManual' in l:
        end=i
assert start is not None and end is not None
j=end+1
while j<len(lines) and not lines[j].startswith('['):
    j+=1
out=lines[:start]+gen.split('\n')+lines[j:]
io.open(tp,'w',encoding='utf-8',newline='\n').write('\n'.join(out))
print('spliced: replaced lines %d..%d with %d lines' % (start,j,len(gen.split('\n'))))
