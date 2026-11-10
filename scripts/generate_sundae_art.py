#!/usr/bin/env python3
"""Deterministic original felt-and-paper Stuffy Land scene art.

Produces nine *different* story scenes, never screenshots or generic repeated
covers. Cast designs follow the universe bible: Lolo is a gray/tan sloth lovey,
Swirly is a chocolate ice-cream cat, Axey is a pink axolotl, and both dogs are
white doodle girls. Re-run when editing an illustration.
"""
import json
import math
import random
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "StuffyLand" / "Assets.xcassets"
W, H = 1200, 720
C = {
 "plum": (33, 21, 46), "violet": (57, 35, 76), "lilac": (176, 139, 207),
 "gold": (244, 191, 113), "cream": (255, 248, 229), "tan": (205, 176, 150),
 "skin": (243, 198, 164), "hair": (157, 112, 67), "gray": (128, 119, 128),
 "darkgray": (75, 69, 82), "chocolate": (103, 56, 48), "white": (247, 239, 226),
 "pink": (242, 157, 196), "deepPink": (193, 90, 137), "green": (109, 150, 101),
 "silver": (191, 200, 211)
}
def scaled(box, s=1):
    return tuple(int(v*s) for v in box)
def oval(d, box, fill, outline=None, width=3):
    d.ellipse(tuple(int(v) for v in box), fill=fill, outline=outline, width=width)
def rounded(d, box, rad, fill, outline=None, width=3):
    d.rounded_rectangle(tuple(int(v) for v in box), radius=int(rad), fill=fill, outline=outline, width=width)
def seg(d, pts, color, width=4):
    d.line([(int(x),int(y)) for x,y in pts], fill=color, width=int(width), joint="curve")
def star(d, x,y,r=13,color=None):
    color=color or C["gold"]
    points=[(x+math.cos(math.radians(-90+k*36))* (r if k%2==0 else r*.43),
             y+math.sin(math.radians(-90+k*36))* (r if k%2==0 else r*.43)) for k in range(10)]
    d.polygon(points,fill=color)
def glow(img,x,y,rad=45,color=(242,184,107),alpha=85):
    layer=Image.new("RGBA",img.size,(0,0,0,0))
    m=ImageDraw.Draw(layer)
    m.ellipse((x-rad,y-rad,x+rad,y+rad),fill=(*color,alpha))
    layer=layer.filter(ImageFilter.GaussianBlur(rad//2))
    img.alpha_composite(layer)
def background(seed,place="tent"):
    rng=random.Random(seed)
    img=Image.new("RGBA",(W,H))
    pix=img.load()
    for y in range(H):
        t=y/H
        if place=="village":
            a=(68,65,110);b=(232,174,151)
        elif place=="garden":
            a=(67,59,114);b=(138,126,116)
        else:
            a=(39,23,67);b=(97,54,101)
        c=tuple(int(a[i]*(1-t)+b[i]*t) for i in range(3))
        for x in range(W):pix[x,y]=(*c,255)
    d=ImageDraw.Draw(img)
    if place=="tent":
        d.polygon([(0,0),(340,0),(0,530)],fill=(53,34,87,220))
        d.polygon([(W,0),(850,0),(W,560)],fill=(63,38,96,230))
        d.polygon([(170,0),(1030,0),(600,260)],fill=(81,52,106,130))
        seg(d,[(150,0),(600,235),(1050,0)],(157,119,167),4)
        for x,y in [(190,68),(338,111),(477,154),(600,179),(725,154),(858,111),(1012,64)]:
            glow(img,x,y,20,alpha=100)
            d=ImageDraw.Draw(img);star(d,x,y,8)
    else:
        for i in range(8):
            x=i*175-20;top=360+rng.randint(-65,55)
            d.polygon([(x,top+95),(x+70,top),(x+145,top+95)],fill=(92,60,112,255))
            rounded(d,(x+16,top+80,x+126,top+220),15,(142,94,122,255))
            rounded(d,(x+61,top+132,x+89,top+205),12,(235,187,131,255))
            star(d,x+75,top+45,13)
    for _ in range(130):
        x=rng.randint(20,W-20);y=rng.randint(14,440)
        r=rng.choice([2,3,3,4,5,7])
        oval(d,(x-r,y-r,x+r,y+r),(232,204,184,110))
        if rng.random()<.19: star(d,x,y,r+3,(231,188,125,255))
    if place=="tent":
        for x,y,r in [(110,670,210),(420,690,250),(750,695,260),(1100,690,240)]:
            oval(d,(x-r,y-r*.65,x+r,y+r*.7),(106,73,125,255),(147,109,148,255),5)
        seg(d,[(0,480),(240,493),(540,487),(840,500),(1200,485)],(178,138,176),5)
    else:
        rounded(d,(0,545,W,720),75,(123,102,116,255))
        for x in range(70,1200,165):star(d,x,585,8,(229,185,127,255))
    return img
def eyes(d,x,y,s=1,closed=False):
    if closed:
        for off in (-14,14):
            d.arc((x+(off-8)*s,y-3*s,x+(off+8)*s,y+8*s), 0,180,fill=C["darkgray"],width=max(2,int(3*s)))
    else:
        for off in (-14,14):
            oval(d,(x+(off-5)*s,y-5*s,x+(off+5)*s,y+6*s),(37,31,43),width=1)
            oval(d,(x+(off-3)*s,y-4*s,x+(off-1)*s,y-2*s),C["white"],width=1)
def opal(d,x,y,s=1,expression="curious"):
    # x,y are center/top of her head. Shoulder length dirty-blonde curls.
    oval(d,(x-82*s,y+100*s,x+84*s,y+276*s),(106,77,156),(198,158,189),int(4*s))
    for ax in [-70,-50,46,65]:
        for k in range(3):
            oval(d,(x+(ax-12)*s,y+(55+k*34)*s,x+(ax+24)*s,y+(96+k*34)*s),
                 (147,108,70),(95,70,59),max(1,int(2*s)))
    oval(d,(x-70*s,y+10*s,x+71*s,y+148*s),C["skin"],(205,146,125),max(2,int(3*s)))
    oval(d,(x-79*s,y-8*s,x+63*s,y+61*s),(156,113,72),(115,80,59),max(2,int(3*s)))
    for ax in [-65,-34,4,35]:
        oval(d,(x+(ax-17)*s,y+13*s,x+(ax+20)*s,y+58*s),(158,114,76),width=1)
    eyes(d,x,y+78*s,s,closed=expression=="happy")
    oval(d,(x-36*s,y+97*s,x-19*s,y+107*s),(230,143,138),width=1)
    oval(d,(x+19*s,y+97*s,x+36*s,y+107*s),(230,143,138),width=1)
    d.arc((x-12*s,y+102*s,x+12*s,y+121*s),0,170,fill=(113,61,65),width=max(2,int(3*s)))
    oval(d,(x-13*s,y+196*s,x+14*s,y+224*s),(141,224,217),(226,183,110),max(2,int(4*s)))
    star(d,x,y+209*s,8,(232,202,132))
    for dx,dy in [(-45,175),(52,203),(-16,245)]:star(d,x+dx*s,y+dy*s,7,(226,190,114))
def sloth(d,x,y,s=1):
    # Slender gray-and-tan female sloth lovey, never a bunny or bear.
    seg(d,[(x-25*s,y+118*s),(x-67*s,y+180*s),(x-82*s,y+186*s)],C["gray"],max(7,int(20*s)))
    seg(d,[(x+25*s,y+120*s),(x+61*s,y+180*s),(x+74*s,y+189*s)],C["gray"],max(7,int(20*s)))
    oval(d,(x-38*s,y+100*s,x+39*s,y+221*s),C["gray"],C["darkgray"],max(1,int(2*s)))
    oval(d,(x-28*s,y+118*s,x+25*s,y+198*s),C["tan"],width=1)
    oval(d,(x-49*s,y,x+49*s,y+130*s),C["gray"],C["darkgray"],max(1,int(3*s)))
    oval(d,(x-40*s,y+18*s,x+40*s,y+110*s),C["tan"],width=1)
    oval(d,(x-33*s,y+54*s,x-5*s,y+89*s),C["darkgray"],width=1)
    oval(d,(x+5*s,y+54*s,x+33*s,y+89*s),C["darkgray"],width=1)
    oval(d,(x-20*s,y+68*s,x-11*s,y+76*s),(32,31,40),width=1)
    oval(d,(x+11*s,y+68*s,x+20*s,y+76*s),(32,31,40),width=1)
    oval(d,(x-6*s,y+88*s,x+6*s,y+97*s),(67,50,55),width=1)
    for off in [-6,1,8]:
        seg(d,[(x-80*s+off*s,y+186*s),(x-85*s+off*s,y+196*s)],C["cream"],max(1,int(2*s)))
        seg(d,[(x+74*s+off*s,y+187*s),(x+78*s+off*s,y+198*s)],C["cream"],max(1,int(2*s)))
def cat(d,x,y,s=1,kind="swirly",mood="calm"):
    if kind=="swirly":
        base=(117,71,61);stripe=(165,111,89);icing=(157,105,81)
    elif kind=="vanilla":
        base=(248,230,205);stripe=(229,198,164);icing=(252,243,228)
    else:
        base=(230,172,188);stripe=(252,204,214);icing=(246,172,192)
    oval(d,(x-62*s,y+120*s,x+65*s,y+235*s),base,C["darkgray"],max(2,int(3*s)))
    d.polygon([(x-62*s,y+63*s),(x-56*s,y-11*s),(x-7*s,y+43*s)],fill=base)
    d.polygon([(x+10*s,y+43*s),(x+58*s,y-14*s),(x+65*s,y+69*s)],fill=base)
    oval(d,(x-80*s,y+35*s,x+79*s,y+173*s),base,C["darkgray"],max(2,int(3*s)))
    oval(d,(x-63*s,y+53*s,x+64*s,y+155*s),stripe,width=1)
    oval(d,(x-53*s,y+62*s,x-5*s,y+96*s),icing,width=1)
    oval(d,(x+5*s,y+62*s,x+53*s,y+96*s),icing,width=1)
    eyes(d,x,y+104*s,s,closed=mood=="happy")
    d.polygon([(x-6*s,y+118*s),(x+5*s,y+118*s),(x,y+127*s)],fill=(108,71,75))
    seg(d,[(x-8*s,y+135*s),(x,y+138*s),(x+8*s,y+135*s)],(77,49,60),max(2,int(2*s)))
    oval(d,(x-25*s,y-17*s,x+35*s,y+34*s),icing,width=1)
    seg(d,[(x+10*s,y+10*s),(x+31*s,y-5*s),(x+16*s,y-17*s)],stripe,max(3,int(7*s)))
    for dx in [-35,35]:oval(d,(x+(dx-12)*s,y+181*s,x+(dx+15)*s,y+203*s),stripe,width=1)
def langston(d,x,y,s=1):
    oval(d,(x-95*s,y+140*s,x+95*s,y+340*s),(73,111,151),(35,59,91),max(2,int(4*s)))
    oval(d,(x-66*s,y+15*s,x+67*s,y+168*s),C["skin"],(182,128,106),max(2,int(3*s)))
    oval(d,(x-75*s,y-6*s,x+75*s,y+77*s),(121,81,64),width=1)
    for dx in [-45,0,48]:oval(d,(x+(dx-22)*s,y+8*s,x+(dx+18)*s,y+58*s),(122,83,68),width=1)
    eyes(d,x,y+103*s,s)
    d.arc((x-20*s,y+112*s,x+20*s,y+147*s),2,179,fill=(118,59,64),width=max(2,int(4*s)))
    seg(d,[(x-62*s,y+193*s),(x-127*s,y+210*s)],(80,114,154),max(7,int(25*s)))
    seg(d,[(x+62*s,y+193*s),(x+132*s,y+162*s)],(80,114,154),max(7,int(25*s)))
def axey(d,x,y,s=1):
    oval(d,(x-38*s,y+120*s,x+41*s,y+230*s),C["pink"],C["deepPink"],max(2,int(3*s)))
    for side in [-1,1]:
        for dy in [34,55,77]:
            seg(d,[(x+side*40*s,y+dy*s),(x+side*78*s,y+(dy-12)*s)],C["deepPink"],max(6,int(10*s)))
    oval(d,(x-61*s,y+2*s,x+61*s,y+147*s),C["pink"],C["deepPink"],max(2,int(3*s)))
    eyes(d,x,y+78*s,s)
    d.arc((x-15*s,y+95*s,x+15*s,y+114*s),0,180,fill=C["darkgray"],width=max(2,int(3*s)))
    for dx in [-26,26]:oval(d,(x+(dx-8)*s,y+100*s,x+(dx+8)*s,y+113*s),(241,115,151),width=1)
def doodle(d,x,y,s=1):
    base=C["white"]
    oval(d,(x-50*s,y+95*s,x+55*s,y+178*s),base,(149,139,135),max(2,int(3*s)))
    oval(d,(x-67*s,y+4*s,x-26*s,y+117*s),base,(155,147,143),max(2,int(3*s)))
    oval(d,(x+29*s,y+4*s,x+67*s,y+117*s),base,(155,147,143),max(2,int(3*s)))
    oval(d,(x-51*s,y,x+49*s,y+123*s),base,(155,147,143),max(2,int(3*s)))
    for bx in [-33,22]:
        oval(d,(x+(bx-7)*s,y+48*s,x+(bx+7)*s,y+60*s),(68,60,66),width=1)
    oval(d,(x-11*s,y+73*s,x+11*s,y+86*s),(76,67,71),width=1)
    for i in range(4):
        oval(d,(x+(-20+i*12)*s,y-4*s,x+(-1+i*12)*s,y+15*s),base,width=1)
def turtle(d,x,y,s=1):
    oval(d,(x-94*s,y+86*s,x+85*s,y+224*s),(62,122,85),(42,73,74),max(2,int(4*s)))
    oval(d,(x-82*s,y+51*s,x+51*s,y+183*s),(101,143,81),(65,97,70),max(2,int(5*s)))
    for dx in [-40,6,44]:
        seg(d,[(x+dx*s,y+64*s),(x+(dx-8)*s,y+152*s)],(61,99,66),max(2,int(4*s)))
    oval(d,(x+23*s,y+18*s,x+111*s,y+104*s),(119,160,109),(49,93,64),max(2,int(3*s)))
    oval(d,(x+71*s,y+48*s,x+80*s,y+57*s),(37,54,48),width=1)
def pillow(d,x,y,rx=120,ry=45,color=(179,145,199)):
    oval(d,(x-rx,y-ry,x+rx,y+ry),color,(226,193,213),4)
    seg(d,[(x-rx+20,y+12),(x+rx-20,y+11)],(222,186,211),3)
def sundae(d,x,y,s=1):
    # y is the bowl's bottom; floating whipped cream & red cherry
    oval(d,(x-139*s,y-65*s,x+139*s,y+24*s),C["silver"],(112,111,134),max(2,int(5*s)))
    d.polygon([(x-145*s,y-61*s),(x-102*s,y+55*s),(x+102*s,y+55*s),(x+145*s,y-61*s)],fill=(191,188,207))
    oval(d,(x-118*s,y-150*s,x-17*s,y-47*s),(153,97,77),(78,49,61),max(1,int(3*s)))
    oval(d,(x-18*s,y-163*s,x+93*s,y-48*s),(247,231,209),(189,158,135),max(1,int(3*s)))
    oval(d,(x-69*s,y-215*s,x+65*s,y-110*s),(248,245,226),(214,188,176),max(1,int(3*s)))
    for k in range(8):
        sx=x+(-107+k*27)*s; yy=y-104*s+math.sin(k*1.3)*12*s
        oval(d,(sx-13*s,yy-13*s,sx+13*s,yy+13*s),(115,67,64),width=1)
    for k in range(12):
        sx=x+math.cos(k*2)*65*s;sy=y-167*s+math.sin(k*2)*26*s
        oval(d,(sx-4*s,sy-4*s,sx+4*s,sy+4*s),(230,149,115),width=1)
    seg(d,[(x,y-207*s),(x+12*s,y-263*s)],(116,75,67),max(2,int(5*s)))
    oval(d,(x-20*s,y-272*s,x+18*s,y-232*s),(190,58,69),(105,46,61),max(2,int(2*s)))
def spinner(d,x,y,s=1):
    oval(d,(x-140*s,y-125*s,x+140*s,y+150*s),(192,150,192),(237,194,170),max(2,int(8*s)))
    oval(d,(x-111*s,y-94*s,x+111*s,y+119*s),(249,223,180),(153,106,132),max(2,int(5*s)))
    for a in range(0,360,45):
        rad=math.radians(a)
        x2=x+math.cos(rad)*105*s;y2=y+11*s+math.sin(rad)*105*s
        star(d,x2,y2,13*s,(129,90,129))
    seg(d,[(x,y+11*s),(x+70*s,y-58*s)],(108,69,95),max(3,int(11*s)))
    star(d,x+70*s,y-58*s,15*s,(191,102,120))
def ribbon(d,points,color=(225,162,180),width=15):
    seg(d,points,color,width)
    for p in points[1:-1]:star(d,p[0],p[1],8,(251,197,135))
def finish(img,seed):
    rng=random.Random(seed)
    dust=Image.new("RGBA",img.size,(0,0,0,0));di=ImageDraw.Draw(dust)
    for _ in range(5200):
        x=rng.randrange(W);y=rng.randrange(H)
        color=(255,247,221,rng.randrange(3,17))
        di.point((x,y),fill=color)
    img.alpha_composite(dust)
    return img.convert("RGB")

def make(scene):
    place="tent" if scene in (1,3,5,7,9) else ("garden" if scene==11 else "village")
    im=background(100+scene,place)
    d=ImageDraw.Draw(im)
    if scene==1:
        pillow(d,270,615,250,80)
        opal(d,270,210,1.07);sloth(d,390,397,.6)
        langston(d,660,160,1.1);cat(d,960,295,.91,"frosted","happy")
        sundae(d,1040,570,.65);glow(im,750,145,75)
        d=ImageDraw.Draw(im);oval(d,(727,108,766,149),(201,47,65));seg(d,[(747,113),(759,93)],(112,79,56),5)
    elif scene==3:
        pillow(d,290,630,200,65);opal(d,305,233,.99);sloth(d,420,390,.55)
        cat(d,830,263,1.22,"swirly");cat(d,1040,364,.56,"vanilla")
        sundae(d,640,629,.55)
    elif scene==5:
        for i in range(5):
            pillow(d,160+i*250,540-(i%2)*85,145,75,(109+i*9,81+i*8,141+i*4))
        ribbon(d,[(60,270),(270,250),(520,310),(750,245),(1100,330)])
        axey(d,480,314,1.22);doodle(d,750,397,.73);doodle(d,948,405,.59)
        oval(d,(600,510,650,540),(94,43,60));opal(d,150,348,.56);sloth(d,230,448,.39)
    elif scene==7:
        rounded(d,(110,490,1110,695),50,(144,100,126));star(d,920,180,20)
        opal(d,280,210,.98);sloth(d,400,400,.53)
        cat(d,870,244,1.16,"swirly");sundae(d,630,577,.57)
        cat(d,1060,390,.53,"vanilla");glow(im,600,177,65)
    elif scene==9:
        pillow(d,590,600,395,95)
        spinner(d,655,324,1.02);opal(d,270,294,.88);sloth(d,390,440,.43)
        axey(d,960,345,1.01);turtle(d,1065,415,.6)
        ribbon(d,[(410,180),(510,196),(620,171),(780,215),(892,187)],width=12)
    elif scene==11:
        ribbon(d,[(45,490),(245,450),(470,425),(760,380),(1140,320)],width=16)
        sundae(d,710,390,1.17);glow(im,715,270,94,alpha=140)
        d=ImageDraw.Draw(im);opal(d,202,415,.66);sloth(d,295,520,.35)
        axey(d,417,498,.58);langston(d,1015,431,.51)
    elif scene==13:
        rounded(d,(70,485,1140,700),45,(192,149,155),(233,197,172),5)
        ribbon(d,[(270,572),(465,536),(654,572),(842,540)],width=10)
        opal(d,345,253,.82);sloth(d,475,390,.45)
        cat(d,810,286,.78,"swirly");cat(d,1030,326,.66,"vanilla")
        axey(d,145,337,.66);turtle(d,1120,400,.6)
        for p in [(250,590),(555,556),(830,580)]:star(d,*p,18,(247,198,130))
    elif scene==15:
        rounded(d,(385,571,1085,700),32,(192,159,156))
        sundae(d,733,448,1.17);glow(im,725,252,130,alpha=125)
        d=ImageDraw.Draw(im);opal(d,156,320,.75);sloth(d,251,487,.38)
        cat(d,1043,386,.8,"swirly");cat(d,1147,480,.59,"vanilla")
        turtle(d,426,452,.79);axey(d,360,247,.54)
        ribbon(d,[(144,196),(405,155),(810,180),(1100,143)],width=11)
    elif scene==17:
        rounded(d,(95,522,1108,700),45,(177,133,148))
        sundae(d,630,567,.75)
        opal(d,300,255,.93);sloth(d,411,410,.52)
        cat(d,934,284,.99,"swirly","happy");cat(d,1080,418,.53,"vanilla","happy")
        for x in [180,430,660,870,1090]:
            glow(im,x,150,28,alpha=90)
            d=ImageDraw.Draw(im);star(d,x,149,15)
    return finish(im,scene+190)

def main():
    for n in (1,3,5,7,9,11,13,15,17):
        asset=f"sundae-scene-{n:02}"
        folder=ASSETS/f"{asset}.imageset"
        folder.mkdir(parents=True,exist_ok=True)
        file=f"{asset}.jpg"
        make(n).save(folder/file,format="JPEG",quality=85,optimize=True,subsampling=0)
        (folder/"Contents.json").write_text(json.dumps({
            "images":[{"filename":file,"idiom":"universal"}],
            "info":{"author":"xcode","version":1}
        },indent=2)+"\n")
        print(f"created {asset}")
if __name__=="__main__":
    main()
