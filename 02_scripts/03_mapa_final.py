# -*- coding: utf-8 -*-
"""Mapa 1 del Informe 1: demanda potencial por manzana + centros comerciales."""
import geopandas as gpd, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from matplotlib.lines import Line2D
import mapclassify as mc

mz  = gpd.read_file("manzanas_dp.gpkg")           # 2.998 manzanas urbanas, EPSG:32718
cc  = gpd.read_file("centros_comerciales.gpkg")   # 30 establecimientos geocodificados

# recorte al continuo urbano principal para que el mapa sea legible
minx, miny, maxx, maxy = mz.total_bounds
mz = mz.cx[minx:minx+13000, miny:maxy]
cc = cc.cx[minx:minx+13000, miny:maxy]

# Clasificacion: las manzanas sin poblacion residente (cero estructural) van a una
# clase propia; el resto se divide en quintiles. Mezclarlas dejaria el primer quintil
# entero en cero y desperdiciaria una clase.
sinpob = mz.dp <= 0
pos    = mz[~sinpob]
cls    = mc.Quantiles(pos.dp.values, k=5)
COL    = ["#f1eef6", "#bdc9e1", "#74a9cf", "#2b8cbe", "#045a8d"]
GRIS   = "#e0e0e0"

fig, ax = plt.subplots(figsize=(9.6, 8.4))
mz[sinpob].plot(ax=ax, color=GRIS, linewidth=0.05, edgecolor="#ffffff")
pos = pos.assign(cls=cls.yb)
for k in range(5):
    pos[pos.cls == k].plot(ax=ax, color=COL[k], linewidth=0.05, edgecolor="#ffffff")
cc.plot(ax=ax, color="#d7301f", markersize=34, marker="o",
        edgecolor="white", linewidth=0.7, zorder=5)

# --- leyenda ---
b   = cls.bins
lo  = pos.dp.min()
f   = lambda v: ("%.0f" % v) if v >= 10 else ("%.1f" % v)
lab = [f"{f(lo)} – {f(b[0])}"] + [f"{f(b[i-1])} – {f(b[i])}" for i in range(1, 5)]
handles = [Patch(facecolor=COL[i], edgecolor="#cccccc", label=lab[i]) for i in range(5)]
handles.append(Patch(facecolor=GRIS, edgecolor="#cccccc",
                     label="Sin población residente (n = %d)" % int(sinpob.sum())))
handles.append(Line2D([], [], marker="o", color="none", markerfacecolor="#d7301f",
                      markeredgecolor="white", markersize=8,
                      label="Centro comercial (n = %d)" % len(cc)))
leg = ax.legend(handles=handles, loc="upper left", bbox_to_anchor=(-0.02, 1.0), frameon=True, framealpha=.94,
                edgecolor="#bbbbbb", fontsize=8.5,
                title="Demanda potencial\n(quintiles de las manzanas habitadas)", title_fontsize=9)
leg._legend_box.align = "left"

# --- escala grafica ---
x0, y0 = ax.get_xlim()[0], ax.get_ylim()[0]
w, h = ax.get_xlim()[1]-x0, ax.get_ylim()[1]-y0
bx, by, L = x0 + .60*w, y0 + .055*h, 2000.0
ax.add_patch(plt.Rectangle((bx, by), L/2, h*.007, fc="black", ec="black", lw=.5, zorder=6))
ax.add_patch(plt.Rectangle((bx+L/2, by), L/2, h*.007, fc="white", ec="black", lw=.5, zorder=6))
for frac, t in ((0, "0"), (.5, "1"), (1, "2 km")):
    ax.text(bx+L*frac, by+h*.013, t, ha="center", fontsize=7.5, zorder=6)

# --- norte ---
nx, ny = x0 + .955*w, y0 + .93*h
ax.annotate("N", xy=(nx, ny), xytext=(nx, ny-h*.045), ha="center", fontsize=11, weight="bold",
            arrowprops=dict(arrowstyle="-|>", color="black", lw=1.4))

ax.set_title("Demanda potencial de consumo y localización de centros comerciales\n"
             "Área urbana de Chillán y Chillán Viejo, 2024",
             fontsize=12.5, pad=14)
ax.set_axis_off()
fig.text(.5, .012,
    "Unidad: manzana censal urbana (n = 2.998). Sistema de referencia: EPSG:32718 (WGS 84 / UTM 18S).\n"
    "Demanda potencial = población residente × índice socioeconómico (escolaridad 18+, traslado en automóvil y acceso a internet).\n"
    "Fuente: elaboración propia a partir del Censo de Población y Vivienda 2024 (INE) y catastro propio geocodificado en Google Maps.",
    ha="center", fontsize=7.6, color="#333333", linespacing=1.5)
fig.subplots_adjust(left=.02, right=.99, bottom=.10, top=.93)
fig.savefig("mapa1_demanda_potencial.png", dpi=200, facecolor="white")
print("bins:", [round(x,1) for x in b], "| centros en el recorte:", len(cc))
