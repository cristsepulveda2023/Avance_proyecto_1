# Avance 1 — Borrador de la Sección 1

**Proyecto:** Captación de demanda potencial de los centros comerciales de Chillán: análisis
espacial aplicado a decisiones de localización de nuevos locales
**Integrantes:** Nacho Sepúlveda Sepúlveda y Eduardo Guerrero
**Estado:** borrador para revisión y edición de los dos. No entregar sin leerlo completo:
en la defensa hay que poder explicar cada decisión.

---

## 1.1 Delimitación del problema

Un operador que evalúa abrir un nuevo local en Chillán —sea dentro de un centro comercial
existente o en un emplazamiento nuevo— enfrenta una decisión de localización con información
incompleta. Conoce el tamaño agregado del mercado comunal, pero no sabe **dónde**, dentro de la
ciudad, se encuentra la demanda que ese local podría efectivamente captar. La decisión suele
tomarse por criterios de flujo observado o por disponibilidad de arriendo, no por evidencia sobre
la distribución territorial de la demanda.

El problema es que la demanda no se distribuye de manera uniforme en el territorio ni proporcional
a la población. Dos sectores de la ciudad con un número similar de habitantes pueden representar
oportunidades comerciales muy distintas, porque difieren en capacidad de gasto y en su posición
relativa respecto de la oferta existente. Sin una caracterización territorial de la demanda, el
operador no puede distinguir entre un sector saturado y uno desatendido, ni evaluar si la oferta
actual de centros comerciales cubre efectivamente a la población con mayor potencial de consumo.

> *Decisión que se busca apoyar:* dónde localizar un nuevo local comercial en Chillán.
> *Este avance no la resuelve:* la caracteriza territorialmente, que es su condición previa.

---

## 1.2 Relevancia del problema

Para el operador, el error de localización es costoso y difícil de revertir: el arriendo compromete
capital por plazos largos y el local no se traslada. Conocer la distribución de la demanda antes de
decidir permite tres cosas concretas.

Primero, **dimensionar el mercado accesible** de cada emplazamiento candidato, en lugar de suponer
que toda la ciudad es su mercado. Segundo, **detectar sectores desatendidos**: zonas con demanda
potencial alta y sin oferta cercana representan una oportunidad que el flujo peatonal observado en
el centro no revela. Tercero, **evaluar críticamente los argumentos de venta inmobiliaria** —
"ubicación estratégica", "alto flujo", "entorno consolidado" — que se enuncian como hechos pero son
hipótesis espaciales contrastables.

Para el propio centro comercial, además, la pregunta es de gestión de cartera: saber qué parte del
territorio capta y qué parte se le escapa determina su capacidad de negociar arriendos y de decidir
ampliaciones.

---

## 1.3 Relevancia de la dimensión espacial

La dimensión espacial no es decorativa en este problema; es constitutiva, por tres razones.

**El consumidor se desplaza.** La demanda que atiende un local no está en la manzana donde el local
se ubica, sino en las manzanas de su entorno. La variable relevante para explicar el desempeño de
un emplazamiento no es su atributo propio, sino el de sus vecinos. Un análisis sin estructura
espacial omitiría precisamente el mecanismo que genera el fenómeno.

**La demanda está territorialmente concentrada y segregada.** La segregación residencial hace que
hogares de características similares se localicen próximos entre sí. En nuestros datos esto se
observa directamente: el 5% de las manzanas concentra cerca del 40% de la demanda potencial
estimada. La demanda no se distribuye al azar en el territorio.

**Población y capacidad de gasto no coinciden espacialmente.** Este es el punto central. En la base
del Censo 2024, el índice socioeconómico que construimos tiene una correlación de apenas **0,06**
con la población de la manzana. Es decir: saber cuánta gente vive en un sector no dice casi nada
sobre cuánto puede gastar. Un mapa de población y un mapa de demanda potencial son mapas distintos,
y esa diferencia es exactamente lo que una decisión de localización necesita ver.

> *Antecedente propio:* en el Laboratorio 2 de la asignatura encontramos que las farmacias de
> Chillán se localizan en el centro comercial, donde la población residente es baja o nula, a
> distancia caminable de la corona residencial más densa. La localización comercial responde a la
> estructura territorial de la demanda, no a la población inmediata.

---

## 1.4 Pregunta de investigación

> **¿Cómo se distribuye territorialmente la demanda potencial de consumo en el área urbana de
> Chillán y Chillán Viejo, y qué sectores presentan mayor demanda potencial no cubierta por la
> oferta actual de centros comerciales?**

Componentes exigidos por la pauta:

| Componente | En esta pregunta |
|---|---|
| Unidad territorial | Manzana censal urbana de Chillán y Chillán Viejo |
| Variable de interés | Demanda potencial de consumo por manzana |
| Mecanismo espacial | El consumidor se desplaza: la oferta que atiende a una manzana se localiza en manzanas vecinas |
| Decisión asociada | Localización de nuevos locales comerciales |

La segunda mitad de la pregunta (demanda no cubierta) se responde parcialmente en este avance —a
nivel de lectura visual del mapa— y se formaliza en el Avance 2 con I de Moran y LISA, y en el
informe final con el modelo de Huff.

---

## 1.5 Unidad espacial de análisis

La unidad es la **manzana censal urbana** (2.998 manzanas de Chillán y Chillán Viejo).

Justificación:

1. Es la **unidad más desagregada** con información socioeconómica publicada por el INE. Cualquier
   agregación mayor promediaría diferencias internas que son justamente lo que buscamos detectar.
2. Su escala es **compatible con el mecanismo modelado**: el radio de captación de un local
   comercial se mide en cientos de metros, no en kilómetros. Una unidad más gruesa (zona censal,
   distrito) no permitiría distinguir dentro de un área de influencia.
3. La unidad de análisis **no es el centro comercial**. El análisis se estima sobre el territorio
   completo; los centros comerciales entran como capa de oferta que se contrasta contra ese
   territorio. Esta es la lógica del *site selection*: se evalúa un sitio contra un modelo de la
   ciudad, no un sitio contra sí mismo.

**MAUP.** Reconocemos que la elección de unidad puede alterar la lectura del fenómeno. Como
contraste de sensibilidad, el análisis se replicará a nivel de **zona censal** (67 zonas), usando la
capa agregada ya disponible del ejercicio de MAUP de la Clase 3.

---

## 1.6 Objetivo general del avance

> Caracterizar territorialmente la demanda potencial de consumo en el área urbana de Chillán y
> Chillán Viejo, mediante la construcción de una base georreferenciada a nivel de manzana censal y
> su representación cartográfica, como insumo para el análisis posterior de captación y de
> decisiones de localización comercial.

Objetivos específicos:

1. Construir y documentar una base georreferenciada de manzanas censales urbanas con variables de
   demanda potencial provenientes del Censo 2024.
2. Georreferenciar y clasificar la oferta de centros comerciales de Chillán.
3. Construir un indicador de demanda potencial por manzana y describir su distribución estadística.
4. Elaborar la cartografía temática inicial e identificar visualmente los patrones territoriales.

---

## Anexo del borrador — decisiones que deben poder defender

**1. Por qué demanda potencial = población × índice socioeconómico.**
La demanda comercial de un sector depende de cuánta gente hay *y* de cuánto puede gastar. Es la
misma lógica de "masa" del modelo de Huff que aplicaremos en el informe final, de modo que el
indicador de este avance es el insumo directo de la etapa siguiente.

**2. Por qué el índice socioeconómico se construye con tasas y no con conteos.**
Probamos ambas opciones. Todas las variables de conteo del censo (hogares, ocupados, personas con
internet, personas con auto) tienen correlación superior a 0,93 con la población de la manzana: un
índice construido con ellas *es* población con otro nombre y no agrega información. Al expresarlas
como proporciones sobre la población de la manzana, la correlación con población cae a 0,06. El
índice mide intensidad, no tamaño.

**3. Qué compone el índice socioeconómico.**
Promedio de tres variables estandarizadas (z-score), reescalado a 0–1 por percentiles 2 y 98 para
acotar el efecto de valores extremos:

- escolaridad promedio de la población de 18 años y más;
- proporción de personas cuyo principal medio de traslado es el automóvil;
- proporción de personas con acceso a internet en la vivienda.

Se descartó incluir asistencia a educación superior: su correlación con las otras tres es
prácticamente nula (0,00–0,06), lo que indica que capta otra cosa (presencia de estudiantes) y no
capacidad de gasto del hogar.

**4. La limitación más importante: población residente vs. población flotante.**
El Censo mide dónde la gente *duerme*, no dónde *consume*. El 21,6% de las manzanas urbanas tiene
cero habitantes, y muchas de ellas están en el centro comercial de la ciudad —donde el flujo diurno
es máximo. Nuestro indicador mide, entonces, **demanda residente**, y subestima sistemáticamente la
demanda real en el centro. Esto debe quedar declarado explícitamente en la sección 2.8 y no
maquillado: es una limitación de la fuente, no un error del análisis. En el informe final la
distancia y el modelo de Huff corrigen parcialmente el problema, al asignar demanda residente a
destinos comerciales que pueden estar lejos del domicilio.

**5. Por qué se trabaja solo con manzanas urbanas (AREA_C = 'URBANO').**
De las 3.071 manzanas de ambas comunas, 2.998 son urbanas. Las 73 restantes son manzanas de aldea o
rurales, con lógicas de accesibilidad y de consumo distintas. Este filtro además explica la
diferencia con el conteo del manual del Laboratorio 2, que quedó pendiente de consulta al docente.
