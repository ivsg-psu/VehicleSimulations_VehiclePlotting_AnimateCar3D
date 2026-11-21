import numpy as np
from scipy.interpolate import splprep, splev
from scipy.optimize import fsolve
T=np.loadtxt('raceCourse_trace.csv',delimiter=',',skiprows=1)
s,x,y=T[:,0],T[:,1],T[:,2]
L0=s[-1]+np.hypot(x[0]-x[-1],y[0]-y[-1])
tck,u=splprep([x,y],s=len(x)*1e-4,per=1)
ds=2.0; n=int(round(L0/ds)); ds=L0/n
uu=np.linspace(0,1,400001); X,Y=splev(uu,tck); d=np.r_[0,np.cumsum(np.hypot(np.diff(X),np.diff(Y)))]
ub=np.interp(np.arange(n+1)*ds,d,uu); dxb,dyb=splev(ub,tck,der=1); hb=np.unwrap(np.arctan2(dyb,dxb))
k0=np.diff(hb)/ds
sm=(np.arange(n)+0.5)*ds; mid=sm*(s[-1]/L0)
# straights: long runs of constant y in the trace
flat=np.r_[np.abs(np.diff(y))<1e-9,False]; run=np.zeros_like(flat); i=0
while i<len(flat):
    if flat[i]:
        j=i
        while j<len(flat) and flat[j]: j+=1
        if j-i>=40: run[i:j]=True
        i=j
    else: i+=1
run[-1]=run[0]
straight=np.interp(mid,s,run.astype(float))>0.999
ym=np.interp(mid,s,y)
top=np.nonzero(straight&(ym>20))[0]; bot=np.nonzero(straight&(ym<20))[0]
botHead=bot[bot<n/2]; botTail=bot[bot>n/2]
A=np.arange(botHead[-1]+1, top[0]); B=np.arange(top[-1]+1, botTail[0])
yTop=y[run&(y>20)][0]; xTopStart=np.interp(sm[top[0]]*(s[-1]/L0)-ds/2*(s[-1]/L0),s,x)
print('segments: bottom head %d, A %d, top %d, B %d, bottom tail %d'%(len(botHead),len(A),len(top),len(B),len(botTail)))
def integ(kk,h0,x0,y0):
    hh=h0+np.r_[0,np.cumsum(kk*ds)]; xx=[x0]; yy=[y0]
    for i in range(len(kk)):
        if abs(kk[i])<1e-12: xx.append(xx[-1]+ds*np.cos(hh[i])); yy.append(yy[-1]+ds*np.sin(hh[i]))
        else: xx.append(xx[-1]+(np.sin(hh[i+1])-np.sin(hh[i]))/kk[i]); yy.append(yy[-1]-(np.cos(hh[i+1])-np.cos(hh[i]))/kk[i])
    return hh,np.array(xx),np.array(yy)
def portion(idx,h0,p0,h1,p1):
    from scipy.optimize import least_squares
    m=len(idx); uloc=(np.arange(m)+0.5)/m
    Bm=np.column_stack([np.sin(j*np.pi*uloc) for j in range(1,13)])
    base=k0[idx]
    tx=np.interp((idx[0]+np.arange(m+1))*ds*(s[-1]/L0),s,x); ty=np.interp((idx[0]+np.arange(m+1))*ds*(s[-1]/L0),s,y)
    def rr(c):
        kk=base+Bm@c; hh,xx,yy=integ(kk,h0,p0[0],p0[1])
        return np.r_[(xx-tx),(yy-ty),1e3*(xx[-1]-p1[0]),1e3*(yy[-1]-p1[1]),1e3*(hh[-1]-h1),0.3*c]
    sol=least_squares(rr,np.zeros(Bm.shape[1]),xtol=1e-15,ftol=1e-15,gtol=1e-15,max_nfev=2000)
    return base+Bm@sol.x
k=np.zeros(n)
# bottom head: from (0,0) west
pA0=np.array([-len(botHead)*ds,0.0]); hA0=np.pi
# top straight start: heading 0 (east), wrapped: total turning from pi to 0 along A
turnA=hb[top[0]]-hb[A[0]]
hA1=hA0+np.round((turnA)/(2*np.pi)*1)*0+ (hb[top[0]]-hb[botHead[-1]+1]) 
hA1=hA0+2*np.pi*np.round((hA1-hA0-(-np.pi))/(2*np.pi))*0 + (np.round(((hb[top[0]]-hb[A[0]]) - (0-np.pi))/(2*np.pi))*2*np.pi + (0-np.pi))
pA1=np.array([xTopStart,yTop])
kA=portion(A,hA0,pA0,hA1,pA1); k[A]=kA
hB0=hA1; pB0=pA1+np.array([len(top)*ds,0.0])
hB1=hB0+(np.round(((hb[B[-1]+1]-hb[B[0]]) - (np.pi-0))/(2*np.pi))*2*np.pi + np.pi)
pB1=np.array([len(botTail)*ds,0.0])
kB=portion(B,hB0,pB0,hB1,pB1); k[B]=kB
hh,xx,yy=integ(k,np.pi,0.0,0.0)
dev=np.hypot(xx[:-1]-np.interp(np.arange(n)*ds*(s[-1]/L0),s,x), yy[:-1]-np.interp(np.arange(n)*ds*(s[-1]/L0),s,y))
print('closure %.2e m, heading end-start %.4f turns; max dev %.2f m (mean %.2f); min radius %.1f m'%(np.hypot(xx[-1],yy[-1]),(hh[-1]-hh[0])/(2*np.pi),dev.max(),dev.mean(),1/np.abs(k).max()))
np.savetxt('raceCourse_planView.csv',np.c_[np.arange(n)*ds,xx[:-1],yy[:-1],hh[:-1],np.full(n,ds),k],delimiter=',',fmt='%.6f',
  header='s_m,x_m,y_m,heading_rad,length_m,curvature_per_m',comments='')
