suppressMessages({library(sf); library(dplyr)})
mz <- st_read("manzanas_dp.gpkg", quiet = TRUE)

base <- mz %>%
  mutate(hab = n_per > 0) %>%
  mutate(
    escol   = prom_escolaridad18,
    p_hac   = n_viv_hacinadas      / pmax(n_vp_ocupada, 1),
    p_alle  = n_hog_allegados      / pmax(n_hog, 1),
    p_prec  = (n_viv_irrecuperables + n_mat_paredes_precarios + n_mat_paredes_artesanal +
               n_mat_techo_precarios + n_mat_techo_sin_cubierta + n_mat_piso_tierra) /
              pmax(n_vp_ocupada, 1),
    p_ciuo13 = (n_ciuo_1 + n_ciuo_2 + n_ciuo_3) / pmax(n_ocupado, 1)
  )

# orientar todo en el mismo sentido: mas alto = mejores condiciones
X <- base %>% st_drop_geometry() %>% filter(hab) %>%
  transmute(escol, hac_inv = -p_hac, alle_inv = -p_alle, prec_inv = -p_prec)
X <- X[complete.cases(X), ]

pca <- prcomp(X, center = TRUE, scale. = TRUE)
cat("== PCA: varianza explicada ==\n")
print(round(summary(pca)$importance[, 1:4], 3))
cat("\n== cargas del primer componente (PC1) ==\n")
print(round(pca$rotation[, 1], 3))

# --- puntaje ISMT ---
sc <- function(df) {
  Z <- scale(df, center = pca$center, scale = pca$scale)
  as.numeric(Z %*% pca$rotation[, 1])
}
allrows <- base %>% st_drop_geometry() %>%
  transmute(escol, hac_inv = -p_hac, alle_inv = -p_alle, prec_inv = -p_prec)
pc1 <- rep(NA_real_, nrow(base))
ok  <- complete.cases(allrows) & base$hab
pc1[ok] <- sc(allrows[ok, ])
if (cor(pc1[ok], allrows$escol[ok]) < 0) pc1 <- -pc1     # orientar: alto = mejor

rng <- range(pc1, na.rm = TRUE)
base$ismt <- (pc1 - rng[1]) / (rng[2] - rng[1])

cat("\n== ISMT (0 = peores condiciones, 1 = mejores) ==\n")
print(round(summary(base$ismt), 3))

q <- quantile(base$ismt, probs = seq(0, 1, .2), na.rm = TRUE)
cat("\n== cortes por quintil ==\n"); print(round(q, 3))
base$ismt_cat <- cut(base$ismt, q, include.lowest = TRUE,
                     labels = c("Bajo","Medio bajo","Medio","Medio alto","Alto"))

cat("\n== manzanas y poblacion por categoria ==\n")
print(base %>% st_drop_geometry() %>% filter(hab) %>%
      group_by(ismt_cat) %>%
      summarise(manzanas = n(), poblacion = sum(n_per),
                escolaridad = round(mean(escol, na.rm=TRUE), 1),
                p_hacinam = round(mean(p_hac)*100, 1),
                p_precario = round(mean(p_prec)*100, 1)) %>% as.data.frame())

cat("\n== ¿cuanto del ISMT es solo escolaridad? ==\n")
cat("cor(ISMT, escolaridad) =", round(cor(base$ismt, base$escol, use="complete.obs"), 3), "\n")
cat("cor(ISMT, ocupaciones CIUO 1-3) =", round(cor(base$ismt, base$p_ciuo13, use="complete.obs"), 3), "\n")
cat("cor(ISMT, poblacion) =", round(cor(base$ismt, base$n_per, use="complete.obs"), 3), "\n")

st_write(base, "manzanas_ismt.gpkg", delete_dsn = TRUE, quiet = TRUE)
cat("\nguardado manzanas_ismt.gpkg\n")
suppressMessages({library(sf); library(dplyr); library(ggplot2)})
mz <- st_read("manzanas_ismt.gpkg", quiet = TRUE)

# recorte al continuo urbano principal (misma logica que el mapa 1)
bb <- st_bbox(mz)
cen <- suppressWarnings(st_coordinates(st_point_on_surface(st_geometry(mz))))
mz  <- mz[cen[,1] <= as.numeric(bb$xmin) + 13000, ]

mz$cat <- ifelse(is.na(mz$ismt_cat), "Sin población residente", as.character(mz$ismt_cat))
niv <- c("Bajo","Medio bajo","Medio","Medio alto","Alto","Sin población residente")
mz$cat <- factor(mz$cat, levels = niv)
pal <- c("Bajo"="#b2182b","Medio bajo"="#ef8a62","Medio"="#f7f7f7",
         "Medio alto"="#67a9cf","Alto"="#2166ac","Sin población residente"="#e0e0e0")

p <- ggplot(mz) +
  geom_sf(aes(fill = cat), colour = NA) +
  scale_fill_manual(values = pal, name = "ISMT\n(quintiles)", drop = FALSE) +
  labs(title = "Índice Socio Material Territorial (ISMT) por manzana censal",
       subtitle = "Área urbana de Chillán y Chillán Viejo · Censo 2024 · EPSG:32718",
       caption = paste("Metodología ISMT (Observatorio de Ciudades UC) aplicada a la base de manzanas del Censo 2024.",
                       "Componentes: escolaridad 18+, hacinamiento, allegamiento y materialidad. Pesos por componentes principales.",
                       sep = "\n")) +
  theme_void(base_size = 11, base_family = "DejaVu Sans") +
  theme(legend.position = c(0.02, 0.80), legend.justification = c(0,1),
        plot.title = element_text(face = "bold", size = 13),
        plot.subtitle = element_text(size = 9.5, colour = "grey30"),
        plot.caption = element_text(size = 7.5, colour = "grey35", hjust = .5),
        plot.margin = margin(10, 10, 10, 10))

ggsave("mapa2_ismt.png", p, width = 9.5, height = 8.6, dpi = 190, bg = "white", type = "cairo")
cat("listo\n")
