"""Generate original PCM chip music / bubble FX; no external recordings."""
from pathlib import Path
import math, wave, struct
RATE=22050
OUT=Path(__file__).resolve().parents[1]/"assets/audio"
OUT.mkdir(parents=True,exist_ok=True)
def save(name,samples):
    with wave.open(str(OUT/(name+".wav")),"wb") as w:
        w.setparams((1,2,RATE,0,"NONE","not compressed"))
        w.writeframes(b"".join(struct.pack("<h",round(max(-1,min(1,v))*32767)) for v in samples))
def hz(note): return 440*2**((note-69)/12)
def pulse(phase): return 1.0 if phase%1<0.25 else -0.333333
# 32 beats / 16 bars of original cheerful arpeggiated melody, seamless loop.
melody=[76,79,81,79,76,72,74,76, 77,81,84,81,79,76,74,72,
        76,79,83,86,84,83,79,76, 74,77,81,79,77,74,71,74,
        72,76,79,84,83,79,76,74, 72,74,76,79,81,79,76,72,
        69,72,76,81,79,76,74,72, 71,74,77,79,77,74,71,67]
chords=[(48,60,64,67),(53,65,69,72),(48,60,64,67),(55,62,65,71),
        (48,60,64,67),(53,65,69,72),(45,57,60,64),(55,62,65,71)]
step=0.18
samples=[]
for i in range(round(len(melody)*step*RATE)):
    t=i/RATE; idx=int(t/step); q=(t/step)%1
    chord=chords[(idx//8)%8]
    lead=.14*pulse(t*hz(melody[idx]))*min(1,q*25)*max(0,1-q)**.35
    arp=.065*math.sin(math.tau*t*hz(chord[1+(idx%3)]))*math.exp(-q*5)
    bass=.10*math.sin(math.tau*t*hz(chord[0]))*math.exp(-q*3)
    kick=.07*math.sin(math.tau*(65*t+4*(1-math.exp(-q*14))))*math.exp(-q*20) if idx%2==0 else 0
    samples.append((lead+arp+bass+kick)*.85)
save("garden_loop",samples)
def effect(name,duration,base,slide,warble=0):
    data=[]
    for i in range(round(RATE*duration)):
        t=i/RATE; u=t/duration
        phase=base*t+0.5*slide*t*t+warble*(1-math.cos(math.tau*18*t))
        env=min(1,u*35)*(1-u)**1.6
        data.append(.32*env*(math.sin(math.tau*phase)+.18*math.sin(math.tau*phase*2)))
    save(name,data)
effect("bubble",.19,360,3400,.035)
effect("jump",.22,270,2100)
effect("capture",.32,780,1700,.055)
effect("pop",.24,1250,-3900,.08)
effect("hurt",.4,260,-430,.02)
for name,notes in [("clear",[72,76,79,84]),("victory",[72,76,79,84,79,84,88,91]),("game_over",[64,60,57,48])]:
    out=[]
    for note in notes:
        for i in range(round(.14*RATE)):
            t=i/RATE; env=(1-t/.14)
            out.append(.19*pulse(hz(note)*t)*env)
    save(name,out)
# A convenient listening preview: music followed by each sound.
preview=list(samples)
for n in ["bubble","jump","capture","pop","hurt","clear","victory"]:
    preview += [0.0]*int(RATE*.25)
    with wave.open(str(OUT/(n+".wav")),"rb") as w:
        b=w.readframes(w.getnframes())
        preview += [v[0]/32768 for v in struct.iter_unpack("<h",b)]
save("sound_preview",preview)
