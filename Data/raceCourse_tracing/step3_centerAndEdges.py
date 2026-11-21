import numpy as np, json
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from scipy.interpolate import splprep, splev
from scipy.signal import medfilt, savgol_filter
from skimage.morphology import remove_small_objects, disk, binary_closing, binary_opening, skeletonize
im=np.asarray(Image.open('RaceTrack.jpg').convert('RGB')).astype(float)
A=np.load('asphalt.npy'); W=np.load('white.npy'); Rd=np.load('red.npy')
H,Wd=A.shape
pxm=198/7.3152
# ---- walls for the rays: real lines only (no chalk), dashed gaps closed
W2=remove_small_objects(W,400)
lines=binary_closing(W2|Rd,disk(9))
wall=(~A)|lines
from skimage.draw import line as drawline
walls_px=[[(440,292),(2066,292),(2151,445)],[(835,295),(950,500),(1000,600),(1040,645),(1150,690),(1300,730),(1336,780),(1356,870),(1386,990),(1426,1150)],[(115,595),(330,565),(560,527)],[(745,565),(800,625),(860,700),(900,750),(950,820),(1000,865),(1090,900)],[(1210,485),(1276,510),(1426,560),(1491,610),(1556,580),(1696,510),(1836,505),(1976,600),(2096,680),(2326,690),(2501,610)],[(1491,610),(1516,690),(1576,800),(1666,930)],[(610,1120),(715,1395)],[(810,1368),(1891,1370)],[(1911,1410),(1966,1345)],[(2066,1205),(2071,1390)]]
wm=np.zeros_like(wall)
for wl in walls_px:
    for (x0,y0),(x1,y1) in zip(wl[:-1],wl[1:]):
        rr,cc=drawline(int(y0),int(x0),int(y1),int(x1)); wm[rr,cc]=True
wall|=ndi.binary_dilation(wm,iterations=3)
wall[:,:100]=True; wall[:,2500:]=True; wall[:30,:]=True; wall[1425:,:]=True   # (the concrete border around the field)
# ---- centerline: previous trace, straights made exact
d=np.load('trace.npz'); pts=d['pts']
tck,u=splprep([pts[:,0],pts[:,1]],s=len(pts)*4,per=1)
uu=np.linspace(0,1,40000,endpoint=False); x,y=splev(uu,tck)
dd=np.r_[0,np.cumsum(np.hypot(np.diff(x),np.diff(y)))]; L=dd[-1]+np.hypot(x[0]-x[-1],y[0]-y[-1])
step=0.25*pxm; n=int(L/step); si=np.linspace(0,dd[-1],n); x=np.interp(si,dd,x); y=np.interp(si,dd,y)
P=np.c_[x,y]
TOPY,BOTY=183.3,1269.0
def blendStraight(P,box,yc,rampN=40):
    x0,x1=box
    inb=(P[:,0]>x0)&(P[:,0]<x1)&(np.abs(P[:,1]-yc)<35)
    # (the longest contiguous run of samples, with wrap)
    m=np.r_[inb,inb]; best=(0,0); i=0
    while i<len(m):
        if m[i]:
            j=i
            while j<len(m) and m[j]: j+=1
            if j-i>best[1]-best[0]: best=(i,j)
            i=j
        else: i+=1
    idx=np.arange(best[0],best[1]); k=np.arange(len(idx))
    w=np.clip(np.minimum(k,len(idx)-1-k)/rampN,0,1); w=w*w*(3-2*w)
    P=P.copy(); ii=idx%len(P); P[ii,1]=(1-w)*P[ii,1]+w*yc; return P
P=blendStraight(P,(300,2150),TOPY)
P=blendStraight(P,(820,1880),BOTY)
# start at the start line (bottom straight, x = 1440)
i0=np.argmin(np.hypot(P[:,0]-1440,P[:,1]-BOTY)); P=np.roll(P,-i0,axis=0)
# light smoothing outside the straights; resample evenly
tck,u=splprep([P[:,0],P[:,1]],s=len(P)*0.05,per=1)
uu=np.linspace(0,1,60000,endpoint=False); x,y=splev(uu,tck)
dd=np.r_[0,np.cumsum(np.hypot(np.diff(x),np.diff(y)))]; L=dd[-1]+np.hypot(x[0]-x[-1],y[0]-y[-1])
n=int(L/step); si=np.arange(n)*L/n; x=np.interp(si,dd,x); y=np.interp(si,dd,y)
P=np.c_[x,y]
P=blendStraight(P,(300,2150),TOPY,rampN=20); P=blendStraight(P,(820,1880),BOTY,rampN=20)
tg=np.gradient(P,axis=0); tg[0]=P[1]-P[-1]; tg[-1]=P[0]-P[-2]; tg/=np.hypot(tg[:,0],tg[:,1])[:,None]
N=np.c_[-tg[:,1],tg[:,0]]          # image: +N is the right side of travel
s=np.arange(len(P))*L/len(P)/pxm   # meters
# ---- edges by rays
def ray(p,nv,skip=6,maxlen=330):
    for k in range(skip,maxlen):
        xx=int(round(p[0]+k*nv[0])); yy=int(round(p[1]+k*nv[1]))
        if xx<0 or yy<0 or xx>=Wd or yy>=H or wall[yy,xx]: return k
    return maxlen
onTop=(np.abs(P[:,1]-TOPY)<1)&(P[:,0]>300)&(P[:,0]<2150)
def rayC(p,nv,top):
    return ray(p,nv,skip=20 if top else 6)   # (skip the dashed center line)
R=np.array([rayC(p,nv,t) for p,nv,t in zip(P,N,onTop)],float)
Lf=np.array([rayC(p,-nv,t) for p,nv,t in zip(P,N,onTop)],float)
def clean(v):
    sm=medfilt(v,17)
    v=np.where(np.abs(v-sm)>30,sm,v)
    return medfilt(v,7)
R=clean(R); Lf=clean(Lf)
onBot=(np.abs(P[:,1]-BOTY)<1)&(P[:,0]>900)&(P[:,0]<1800)
# (top straight heading east: right = south, edge line y 285; left = north, edge y 84.
#  bottom straight heading west: right = north, edge line y 1170; left = south, pit divider y 1368)
R[onTop]=285-TOPY; Lf[onTop]=TOPY-84
R[onBot]=BOTY-1170; Lf[onBot]=1368-BOTY
np.savez('trace2_base.npz',P=P,N=N,s=s,R=R,Lf=Lf,L=L)
print('loop %.1f m, %d samples; right %.1f..%.1f m, left %.1f..%.1f m'%(L/pxm,len(P),R.min()/pxm,R.max()/pxm,Lf.min()/pxm,Lf.max()/pxm))
