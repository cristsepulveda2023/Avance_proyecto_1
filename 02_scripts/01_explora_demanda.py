import geopandas as gpd, pandas as pd, numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap

SRC="/mnt/user-data/uploads/Análisis Espacial Para la Gestión Empresarial/Clase_5/Clase_2_QGIS/manzanas_chillan_chillanviejo_utm18s_v2.gpkg"
g = gpd.read_file(SRC)
u = g[g.AREA_C=='URBANO'].to_crs(32718).copy()
u["area_km2"] = u.area/1e6

# --- proxys de capacidad de gasto (tasas, no conteos) ---
h = u.n_hog.replace(0, np.nan)
p = u.n_per.replace(0, np.nan)
u["t_auto"]  = u.n_transporte_auto / p       # % personas que se mueven en auto
u["t_inter"] = u.n_internet        / p       # % con internet
u["esc"]     = u.prom_escolaridad18          # años de escolaridad 18+
u["t_sup"]   = u.n_asistencia_superior / p   # % en educacion superior

def z(s):
    s = s.astype(float)
    return (s - s.mean())/s.std()

ise = pd.concat([z(u.t_auto), z(u.t_inter), z(u.esc), z(u.t_sup)], axis=1).mean(axis=1)
u["ise"] = ise
# reescalado 0-1 por percentiles robustos
lo, hi = u.ise.quantile([.02,.98])
u["ise01"] = ((u.ise-lo)/(hi-lo)).clip(0,1)
u["dp"] = u.n_hog * u.ise01          # demanda potencial exploratoria

print("=== correlacion entre proxys de capacidad de gasto ===")
print(u[["t_auto","t_inter","esc","t_sup"]].corr().round(3))
print()
print("=== ISE y demanda potencial ===")
print(u[["n_per","n_hog","ise01","dp"]].describe().T[["count","mean","50%","min","max","std"]].round(2))
print()
print("corr(dp, n_per) =", round(u.dp.corr(u.n_per),3), " corr(ise01, n_per) =", round(u.ise01.corr(u.n_per),3))
print()
print("=== top 10 manzanas por demanda potencial ===")
print(u.nlargest(10,"dp")[["MANZENT","COMUNA","n_per","n_hog","ise01","dp"]].round(2).to_string(index=False))

u.to_file("manzanas_dp_expl.gpkg", driver="GPKG")

# --- mapa exploratorio ---
fig, axes = plt.subplots(1,3, figsize=(16.5,7.2))
specs=[("n_per","Población residente (Censo 2024)","YlGnBu"),
       ("ise01","Índice socioeconómico (0–1)","YlOrRd"),
       ("dp","Demanda potencial = hogares × ISE","BuPu")]
for ax,(col,title,cmap) in zip(axes,specs):
    u.plot(column=col, ax=ax, cmap=cmap, scheme="quantiles", k=5,
           legend=True, linewidth=0, edgecolor="none", missing_kwds={"color":"#e8e8e8"},
           legend_kwds={"fontsize":7,"loc":"lower left","frameon":False})
    ax.set_title(title, fontsize=10.5)
    ax.set_axis_off()
fig.suptitle("Chillán y Chillán Viejo — manzanas censales urbanas (n=2.998), EPSG:32718\nExploratorio: quintiles. Fuente: Censo de Población y Vivienda 2024, INE.",
             fontsize=9.5, y=0.99)
fig.tight_layout()
fig.savefig("mapa_exploratorio_demanda.png", dpi=170, bbox_inches="tight")
print("\nmapa guardado")

# NOTA DE REPRODUCIBILIDAD
# Entrada:  manzanas_chillan_chillanviejo_utm18s_v2.gpkg (Cartografia Censo 2024 R16, INE),
#           filtrada a COMUNA in (CHILLAN, CHILLAN VIEJO). 3.071 manzanas.
# Filtro:   AREA_C == 'URBANO'  ->  2.998 manzanas / 194.344 hab.
#           (Las 73 restantes son TIPO_MZ='ALDEA' + 20 rurales de Chillan Viejo.)
# CRS:      el archivo viene declarado EPSG:4674 (SIRGAS 2000, geografico) pese al
#           sufijo "_utm18s" del nombre. Se reproyecta a EPSG:32718 para toda
#           medicion metrica (areas, distancias).
