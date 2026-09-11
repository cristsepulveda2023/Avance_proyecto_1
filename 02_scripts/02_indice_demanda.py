import geopandas as gpd, pandas as pd, numpy as np
pd.set_option('display.width',200)
SRC="/mnt/user-data/uploads/Análisis Espacial Para la Gestión Empresarial/Clase_5/Clase_2_QGIS/manzanas_chillan_chillanviejo_utm18s_v2.gpkg"
g = gpd.read_file(SRC)
u = g[g.AREA_C=='URBANO'].to_crs(32718).copy()
u["area_km2"]=u.area/1e6
p = u.n_per.replace(0,np.nan)

u["t_auto"] = u.n_transporte_auto/p
u["t_int"]  = u.n_internet/p
u["esc"]    = u.prom_escolaridad18
def z(s): s=s.astype(float); return (s-s.mean())/s.std()
u["ise"] = pd.concat([z(u.t_auto),z(u.t_int),z(u.esc)],axis=1).mean(axis=1)
lo,hi = u.ise.quantile([.02,.98]); u["ise01"]=((u.ise-lo)/(hi-lo)).clip(0,1)
u["dp"] = u.n_per*u.ise01
u["dens"] = u.n_per/u.area_km2

print("MANZANAS CON 0 HAB:", (u.n_per==0).sum(), "->", round((u.n_per==0).mean()*100,1),"%")
print("corr(dp,n_per)=",round(u.dp.corr(u.n_per),3)," corr(ise01,n_per)=",round(u.ise01.corr(u.n_per),3))
print()
tab = u[["n_per","n_hog","dens","esc","t_auto","t_int","ise01","dp"]].describe().T
tab = tab[["count","mean","50%","std","min","max"]]
tab.columns=["N","Media","Mediana","Desv.est.","Mínimo","Máximo"]
tab.index=["Población residente (n_per)","Hogares (n_hog)","Densidad (hab/km²)",
           "Escolaridad prom. 18+ (años)","Prop. traslado en auto","Prop. con internet",
           "ISE (0–1)","Demanda potencial (DP)"]
print(tab.round(2).to_string())
tab.round(2).to_csv("tabla_descriptivas.csv", encoding="utf-8-sig")

# concentracion
s=u.dp.fillna(0).sort_values(ascending=False)
for k in [0.05,0.10,0.20]:
    n=int(len(s)*k); print(f"top {int(k*100)}% de manzanas concentra {s.head(n).sum()/s.sum()*100:.1f}% de la demanda potencial")
u.to_file("manzanas_dp.gpkg", driver="GPKG")
