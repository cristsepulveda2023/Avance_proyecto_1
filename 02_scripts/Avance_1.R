# =============================================================================
## ÍNDICE SOCIO MATERIAL TERRITORIAL (ISMT) PARA CHILLÁN Y CHILLÁN VIEJO ##
# =============================================================================
#
# Asignatura : Análisis Espacial para la Gestión Empresarial 
# Carrera    : Ingeniería Comercial
# Unidad     : Escuela de Administración y Negocios, Universidad de Concepción,
#              Campus Chillán
# Docente    : Mauricio Oyarzo Aguilar
# Integrantes: Cristóbal Sepúlveda Sepúlveda y Eduardo Guerrero Castro
# Proyecto   : Captación de demanda potencial de los centros comerciales de
#              Chillán: análisis espacial aplicado a decisiones de localización
# Fecha      : 11 septiembre de 2026
#
# -----------------------------------------------------------------------------
## QUÉ HACE ESTE SCRIPT ##
# -----------------------------------------------------------------------------
# Construye un indicador de nivel socioeconómico por manzana censal para el área
# urbana de Chillán y Chillán Viejo, aplicando la metodología del Índice Socio
# Material Territorial (ISMT) del Observatorio de Ciudades UC a la base de
# manzanas del Censo de Población y Vivienda 2024 (INE).
#
# -----------------------------------------------------------------------------
## POR QUÉ ESTE ÍNDICE Y NO EL INGRESO ##
# -----------------------------------------------------------------------------
# El Censo chileno no pregunta ingresos. Ninguna de sus versiones lo ha hecho, y
# el cuestionario 2024 tampoco lo incluye. En consecuencia, en Chile no existe
# información de ingreso georreferenciada a escala de manzana: la CASEN entrega
# ingreso, pero su menor nivel de desagregación es la comuna, lo que no genera
# ninguna variación dentro de una ciudad.
#
# El ISMT fue desarrollado por el Observatorio de Ciudades UC precisamente para
# resolver ese vacío. No es un estimador del ingreso ni un proxy de ingreso per
# cápita: es una medida ALTERNATIVA de nivel socioeconómico, construida a partir
# de las condiciones socio materiales observables del territorio. Es importante
# no confundir ambas cosas.
#
# El índice combina cuatro dimensiones del Censo:
#   1. Escolaridad          - años de estudio de la población adulta
#   2. Hacinamiento         - relación entre personas y dormitorios
#   3. Allegamiento         - más de un hogar por vivienda
#   4. Materialidad         - calidad de muros, techo y piso de la vivienda
#
# Los pesos de cada dimensión no se asignan a criterio: se obtienen mediante
# análisis de componentes principales. El resultado se normaliza entre 0 y 1,
# donde 0 corresponde a las peores condiciones socio materiales observadas en la
# muestra y 1 a las mejores, y luego se corta en quintiles.
#
# Al ser un índice relativo a la muestra con que se calcula, un valor de 0,8 en
# Chillán no es directamente comparable con un 0,8 obtenido para otra ciudad.
#
# -----------------------------------------------------------------------------
## SOBRE EL PAQUETE ismtchile ##
# -----------------------------------------------------------------------------
# El Observatorio de Ciudades UC distribuye el paquete de R 'ismtchile', que
# automatiza el cálculo del índice: homologa las variables entre censos, calcula
# los componentes principales y entrega el puntaje final.
#
#   Documentación : https://ismtchile.geocoded.dev
#   CRAN          : https://cran.r-project.org/package=ismtchile
#   Ficha del ISMT: https://observatoriodeciudades.com/portfolio/ismt/
#
# NO utilizamos el paquete directamente, por dos razones que conviene declarar:
#
#   a) Opera con MICRODATOS censales (registros individuales), mientras que la
#      base pública de manzanas del Censo 2024 viene ya agregada por manzana.
#   b) Homologa variables hasta el Censo 2017 y no incorpora todavía el de 2024.
#
# Por eso este script no es una réplica del paquete, sino una ADAPTACIÓN de su
# metodología: se reconstruyen las cuatro dimensiones a partir de las variables
# agregadas disponibles y se aplica el mismo procedimiento de ponderación por
# componentes principales.
#
# Diferencia adicional a declarar: el ISMT original usa la escolaridad del jefe
# de hogar y se calcula a nivel de zona censal. Aquí se usa la escolaridad
# promedio de la población de 18 años y más, que es lo que entrega la base de
# manzanas, y se calcula a nivel de manzana.
#
# -----------------------------------------------------------------------------
# FUENTES DE DATOS
# -----------------------------------------------------------------------------
# INE (2024). Censo de Población y Vivienda 2024, base de manzanas y cartografía
#   censal, Región de Ñuble. Instituto Nacional de Estadísticas.
# Observatorio de Ciudades UC. Índice Socio Material Territorial (ISMT).
#   Pontificia Universidad Católica de Chile.
#
# =============================================================================

# -----------------------------------------------------------------------------
## PASO 1. Verificación del entorno y ubicación de los datos ##
# -----------------------------------------------------------------------------

install.packages(c("sf", "ggplot2")) # Instalación del paquete.

library(sf)       # carga el paquete espacial: permite leer .gpkg y trabajar la
                  # geometría de cada manzana como una columna más de la tabla

sf_extSoftVersion()   # chequeo: imprime las versiones de GDAL, GEOS y PROJ, los
                      # tres motores externos sobre los que corre sf.
                      # GDAL lee y escribe formatos, GEOS hace las operaciones
                      # geométricas y PROJ maneja los sistemas de coordenadas.
                      # Si los tres aparecen, la instalación quedó completa.

list.files(recursive = TRUE, pattern = "\\.gpkg$")

                        # lista los archivos desde la carpeta del proyecto.
                        # recursive = TRUE entra a las subcarpetas y pattern
                        # filtra por nombre: "\\." es un punto literal y "$"
                        # indica que el nombre termina ahí, así que devuelve
                        # solo los .gpkg. Sirve para confirmar la ruta real del
                        # archivo antes de escribirla en el script.

# -----------------------------------------------------------------------------
## PASO 2. Cargar la capa de manzanas y auditarla antes de usarla ##
# -----------------------------------------------------------------------------

ruta <- list.files(recursive = TRUE,
                   pattern = "utm18s_v2\\.gpkg$",
                   full.names = TRUE)[1]

ruta          # en vez de escribir la ruta a mano, dejamos que R la busque.
              # full.names = TRUE devuelve la ruta completa y [1] toma la
              # primera coincidencia. Si el archivo se mueve de carpeta,
              # el script sigue funcionando.    

manzana <- st_read(ruta)  # lee la capa completa: atributos + geometría de cada
                          # manzana. Al cargar, sf imprime cuántos objetos leyó,
                          # el tipo de geometría y el sistema de coordenadas.

nrow(manzana)              # número de manzanas. Debe dar 3.071 (Chillán +
                           # Chillán Viejo, urbanas y rurales juntas).

ncol(manzana)         # número de columnas. La base censal trae ~217 variables.

st_crs(manzana)$epsg       # código EPSG del sistema de coordenadas declarado.

table(manzana$COMUNA, manzana$AREA_C)   
                              # tabla de doble entrada: cruza comuna con área
                              # urbana/rural. Muestra de dónde salen las 3.071
                              # manzanas urbanas con las que vamos a trabajar.

#-----------------------------------------------------------------------------
## PASO 3. Filtrar al área urbana y reproyectar al sistema de trabajo ##
#-----------------------------------------------------------------------------

library(dplyr)

urb <- manzana%>% filter(AREA_C == "URBANO")  # deja las 2.998 manzanas urbanas.
                                              # Las 73 de aldea y rurales quedan
                                              # fuera: tienen otra lógica de
                                              # accesibilidad y consumo.

nrow(urb)                                  # confirmación: 2.998

sum(urb$n_per)                             # población del universo: 194.344

urb <- st_transform(urb, 32718)           # reproyecta de EPSG:4674 (geográfico,
                                          # en grados) a EPSG:32718 (UTM 18S,
                                          # en metros). Sin esto, cualquier
                                          # área o distancia sale en grados y
                                          # no significa nada.                                         

st_crs(urb)$epsg                          # confirmación: 32718

urb$area_km2 <- as.numeric(st_area(urb)) / 1e6   # st_area devuelve m² con
                                                 # unidades pegadas; as.numeric
                                                 # las saca y dividimos a km².

summary(urb$area_km2)                      # revisión rápida: ninguna manzana
                                           # debería tener área 0 ni valores
                                           # absurdos.

summary(urb$area_km2 * 1e6)                # misma revisión, pero en m²

# -----------------------------------------------------------------------------
## PASO 4. Construir las cuatro dimensiones del ISMT ##
# -----------------------------------------------------------------------------

urb$hab <- urb$n_per > 0     # marca las manzanas con población residente
table(urb$hab)               # 2.351 habitadas, 647 sin población

urb <- urb %>% mutate(
  
  # 1. ESCOLARIDAD — años de estudio de la población de 18 y más
  escol = prom_escolaridad18,
  
  # 2. HACINAMIENTO — viviendas hacinadas sobre viviendas ocupadas
  p_hac = n_viv_hacinadas / pmax(n_vp_ocupada, 1),
  
  # 3. ALLEGAMIENTO — hogares allegados sobre total de hogares
  p_alle = n_hog_allegados / pmax(n_hog, 1),
  
  # 4. MATERIALIDAD — se evalúan muros, techo y piso por separado y luego se
  #    promedian. Sumarlos contaría dos o tres veces la misma vivienda cuando
  #    tiene más de un elemento deficiente, y la proporción se pasaba de 1.
  p_muros = (n_mat_paredes_precarios + n_mat_paredes_artesanal) / pmax(n_vp_ocupada, 1),
  p_techo = (n_mat_techo_precarios + n_mat_techo_sin_cubierta)  / pmax(n_vp_ocupada, 1),
  p_piso  =  n_mat_piso_tierra                                  / pmax(n_vp_ocupada, 1),
  p_prec  = (p_muros + p_techo + p_piso) / 3
) 

# Revisión de las cuatro dimensiones

dims <- urb %>% st_drop_geometry() %>% filter(hab) %>%
  select(escol, p_hac, p_alle, p_prec)

summary(dims)                                    # el máximo de p_prec ya no
                                                 # debe pasar de 1

round(sapply(dims, \(x) mean(x == 0, na.rm = TRUE) * 100), 1)
                                                 # % de manzanas en cero

round(cor(dims, use = "pairwise.complete.obs"), 3)
                                                # correlaciones entre las cuatro

#-------------------------------------------------------------------------------
## PASO 5. Ponderar las dimensiones con componentes principales ##
#-------------------------------------------------------------------------------

# Las cuatro dimensiones se orientan en el mismo sentido: más alto = mejores
# condiciones. Escolaridad ya cumple; las otras tres se invierten con el signo
# negativo, porque más hacinamiento, allegamiento o precariedad es peor.

X <- urb %>% st_drop_geometry() %>% filter(hab) %>%
  transmute(escol,
            hac_inv  = -p_hac,
            alle_inv = -p_alle,
            prec_inv = -p_prec)

X <- X[complete.cases(X), ]   # saca la manzana con NA en escolaridad
nrow(X)                       # 2.350

pca <- prcomp(X, center = TRUE, scale. = TRUE)

# scale. = TRUE estandariza antes de calcular.
# Es obligatorio acá: escolaridad va de 6,7 a 18
# (años) y las proporciones de 0 a 0,5. Sin
# estandarizar, escolaridad dominaría el índice
# solo por tener números más grandes, no por
# importar más.

summary(pca)                  # varianza explicada por cada componente

round(pca$rotation[, 1], 3)   # cargas del primer componente: cuánto pesa cada
                              # dimensión en el índice final

#-------------------------------------------------------------------------------
## PASO 6. Construir el puntaje ISMT y clasificarlo ##
#-------------------------------------------------------------------------------

# Proyecta cada manzana sobre PC1. Se aplica a TODAS las manzanas habitadas
# usando el centro y la escala que aprendió el PCA, para no recalcular nada.

todas <- urb %>% st_drop_geometry() %>%
  transmute(escol, hac_inv = -p_hac, alle_inv = -p_alle, prec_inv = -p_prec)

pc1 <- rep(NA_real_, nrow(urb))
ok  <- complete.cases(todas) & urb$hab
pc1[ok] <- as.numeric(scale(todas[ok, ], center = pca$center, scale = pca$scale) %*%
                        pca$rotation[, 1])

# Orienta el eje: si el puntaje quedó inversamente relacionado con escolaridad,
# se invierte, de modo que más alto = mejores condiciones.

if (cor(pc1[ok], todas$escol[ok]) < 0) pc1 <- -pc1

# Normaliza entre 0 y 1

rango <- range(pc1, na.rm = TRUE)
urb$ismt <- (pc1 - rango[1]) / (rango[2] - rango[1])

summary(urb$ismt)

# Corta en quintiles: cinco grupos con aproximadamente el mismo número de
# manzanas cada uno

q <- quantile(urb$ismt, probs = seq(0, 1, 0.2), na.rm = TRUE)

round(q, 3)

urb$ismt_cat <- cut(urb$ismt, q, include.lowest = TRUE,
                    labels = c("Bajo", "Medio bajo", "Medio", "Medio alto", "Alto"))

# Perfil de cada categoría: sirve para verificar que el índice ordena bien

urb %>% st_drop_geometry() %>% filter(hab) %>%
  group_by(ismt_cat) %>%
  summarise(manzanas   = n(),
            poblacion  = sum(n_per),
            escolaridad = round(mean(escol, na.rm = TRUE), 1),
            hacinam    = round(mean(p_hac) * 100, 1),
            precario   = round(mean(p_prec) * 100, 2)) %>%
  as.data.frame()  


#-------------------------------------------------------------------------------
## PASO 7. Validación externa del índice ##
#-------------------------------------------------------------------------------
# Ninguna de estas tres variables entró en el cálculo del ISMT, así que sirven

# para comprobar si el índice ordena el territorio de forma coherente.

urb$p_ciuo13 <- (urb$n_ciuo_1 + urb$n_ciuo_2 + urb$n_ciuo_3) / pmax(urb$n_ocupado, 1)

# proporción de ocupados en categorías CIUO 1 a 3:
# directivos, profesionales y técnicos. Es la variable
# del Censo más asociada al ingreso.

cor(urb$ismt, urb$p_ciuo13, use = "complete.obs")   # validación externa

cor(urb$ismt, urb$n_per,    use = "complete.obs")   # ¿mide tamaño o nivel?

cor(urb$ismt[urb$hab], urb$prom_per_hog[urb$hab], use = "complete.obs")

#-------------------------------------------------------------------------------
## PASO 8. Mapa del ISMT ##
#-------------------------------------------------------------------------------

library(ggplot2)

urb$cat_mapa <- ifelse(is.na(urb$ismt_cat),
                       "Sin población residente",
                       as.character(urb$ismt_cat))

# las manzanas sin residentes van a una clase propia:
# no son "nivel bajo", son otra cosa

urb$cat_mapa <- factor(urb$cat_mapa,
                       levels = c("Bajo","Medio bajo","Medio","Medio alto","Alto","Sin población residente"))

pal <- c("Bajo"       = "#b2182b", "Medio bajo" = "#ef8a62",
         "Medio"      = "#f7f7f7", "Medio alto" = "#67a9cf",
         "Alto"       = "#2166ac", "Sin población residente" = "#e0e0e0")

# rampa divergente rojo-azul: el "Medio" queda casi blanco
# y los extremos se leen de inmediato

ggplot(urb) +
  geom_sf(aes(fill = cat_mapa), colour = NA) +
  scale_fill_manual(values = pal, name = "ISMT\n(quintiles)") +
  labs(title    = "Índice Socio Material Territorial por manzana censal",
       subtitle = "Área urbana de Chillán y Chillán Viejo · Censo 2024 · EPSG:32718",
       caption  = "Elaboración propia aplicando la metodología ISMT (Observatorio de Ciudades UC).") +
  theme_void()

#-------------------------------------------------------------------------------
# PASO 9. Guardar la capa con el índice ---------------------------------------
#-------------------------------------------------------------------------------

st_write(urb,
         "Avance_proyecto_1/03_output/manzanas_ismt.gpkg",
         delete_dsn = TRUE)

# delete_dsn = TRUE sobrescribe si el archivo ya existe.
# Sin eso, st_write falla en vez de reemplazar.

ggsave("Avance_proyecto_1/03_output/mapa_ismt.png",
       width = 9.5, height = 8, dpi = 200, bg = "white")
# guarda el último gráfico dibujado
