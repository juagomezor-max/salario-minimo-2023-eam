# Salario mínimo y decisiones de la firma: evidencia del aumento de 2023 en la industria manufacturera Colombiana

Repositorio de replicación del código de la tesis de Maestría en Economía
Aplicada **"Salario mínimo y decisiones de la firma: evidencia del aumento
de 2023 en la industria manufacturera Colombiana"**, Universidad de los
Andes.

**Autores:** Julio Alejandro Gómez Orduz ([ORCID 0009-0001-2013-8352](https://orcid.org/0009-0001-2013-8352))
y Nicolás Jácome.
**Asesor:** Andrés Ham.

Estudio de la respuesta de las firmas manufactureras Colombianas al aumento
del salario mínimo de 2023, usando la Encuesta Anual Manufacturera (EAM)
del DANE.

*An English summary follows at the end of this file.*

---

## Qué contiene este repositorio

Solo el código de estimación (`3. SCRIPTS/01` a `3. SCRIPTS/06` y
`3. SCRIPTS/herramientas/`) y la infraestructura para reproducirlo:
descarga de datos, orquestador (`run_all.R`) y entorno (`renv`). **No**
incluye el código de construcción de los paneles desde la macrobase, ni
material de trabajo/archivo de la tesis (borradores, notas de decisiones,
scripts descartados) — eso vive en el repositorio de desarrollo de la
tesis.

```
.
├── run_all.R                    # corre todo el pipeline, de punta a punta
├── renv.lock, renv/, .Rprofile  # entorno de R (versiones exactas de paquetes)
├── 1. DATOS/                    # vacío en git -- ver "1. DATOS/README.md"
├── 4. RESULTADOS/                # salidas de referencia (tablas, gráficos, VERIFICACION.csv)
└── 3. SCRIPTS/
    ├── 00_descargar_datos.R
    ├── 01_descriptivos_y_contexto.R
    ├── 02_medidas_exposicion.R
    ├── 03_primer_eslabon_medidas.R
    ├── 04_decision_medida.R
    ├── 05_resultados_y_mecanismos.R
    ├── 06_tratamiento_continuo.R
    └── herramientas/
        ├── comparar_con_head.R
        ├── graficar_tendencias_paralelas.R
        └── graficar_figuras_tesis.R
```

## Qué hace cada script

| Script | Qué hace | Tablas / gráficos principales |
|---|---|---|
| `00_descargar_datos.R` | Descarga el paquete de datos desde Zenodo, verifica MD5 y SHA256, deja los 3 paneles en `1. DATOS/`. | — (no genera resultados) |
| `01_descriptivos_y_contexto.R` | Estadísticas descriptivas, primer eslabón (costo laboral) y resultado principal de empleo, en la especificación principal. | Perfil de firmas, brechas salariales, primer eslabón, empleo total, estudio de evento, supuestos del modelo |
| `02_medidas_exposicion.R` | Construye y compara medidas alternativas de exposición al choque (Kaitz vs. otras construcciones). Escribe `1. DATOS/exposicion_alternativa_2022.rds`, que leen `03`, `04` y `05`. | Cobertura por categoría ocupacional, correlaciones entre medidas, estabilidad 2019 vs. 2022 |
| `03_primer_eslabon_medidas.R` | Primer eslabón (costo laboral) con las cinco medidas de exposición candidatas; es la prueba decisiva entre ellas. | Comparación de medidas, placebo 2018-2019, robustez de controles |
| `04_decision_medida.R` | Aplica la regla de decisión (ya fijada) sobre qué medida de exposición usar como principal. | Celda limpia, matriz de combinaciones, decisión final |
| `05_resultados_y_mecanismos.R` | Resultados principales (costo laboral y empleo), mecanismos de ajuste, dosis-respuesta por quintil de exposición, trayectorias Q1 vs. Q5, HonestDiD (opcional, ver abajo). | Primer y segundo eslabón, mecanismos, heterogeneidad por tamaño, quintiles de exposición, HonestDiD |
| `06_tratamiento_continuo.R` | Tratamiento continuo (dosis-respuesta) con la medida principal, formas funcionales, placebo de reversión a la media, contraste con el paquete `contdid` (opcional). | Efecto por quintil, formas funcionales, placebo 2018, contraste `contdid` |
| `herramientas/graficar_tendencias_paralelas.R` | Gráfico de tendencias paralelas (12 estudios de evento: 6 resultados × con/sin control de tamaño), leyendo las tablas que ya dejó `05`. | Gráfico de tendencias paralelas |
| `herramientas/graficar_figuras_tesis.R` | Regenera las figuras principales de la tesis (distribución de Kaitz, trayectoria de costo por quintil, dosis-respuesta, placebo, referencias) con un estilo visual unificado, leyendo las tablas que ya dejaron `05` y `06`. | Figuras 1, 3-6 de la tesis (+ anexo de control por tamaño) |
| `herramientas/comparar_con_head.R` | Herramienta de verificación: compara los CSV/MD de una carpeta de `4. RESULTADOS/` contra una versión anterior en git (tolerancia 1e-8). No forma parte del pipeline de estimación. | — |

## Requisitos

- **R 4.5.2 exactamente** (no 4.6.x: `renv::restore()` falla al compilar el
  paquete `S7` bajo R 4.6.1).
- En Windows, **Rtools45**.
- Conexión a internet (para `00_descargar_datos.R` y para
  `renv::restore()`).

## Cómo correr

```r
# 1. Abrir salario-minimo-2023-eam.Rproj (para que R trabaje desde la raíz)

# 2. Restaurar el entorno (una sola vez)
renv::restore(prompt = FALSE)

# 3. Correr todo el pipeline
source("run_all.R")
```

O desde una terminal, en la raíz del repositorio:

```
Rscript -e "renv::restore(prompt = FALSE)"
Rscript run_all.R
```

`run_all.R` descarga los datos si hace falta, corre `02 → 01 → 03 → 04 →
05 → 06 → las dos herramientas` en ese orden (`02` debe ir antes que `03`,
`04` y `05`; los demás no dependen entre sí), y termina comparando las
cifras clave de la tesis contra `4. RESULTADOS/VERIFICACION.csv`.

### HonestDiD

`05_resultados_y_mecanismos.R` incluye un contraste de sensibilidad con
`HonestDiD` (Rambachan y Roth, 2023) que tarda varios minutos. Por defecto
está **apagado** (`CORRER_HONESTDID = FALSE`): se salta esa sección y no
genera `T10*`, `T10b*` ni `G08_honestdid.png`.

Para correr la réplica completa, con HonestDiD incluido:

```
Rscript -e "Sys.setenv(CORRER_HONESTDID='TRUE'); source('run_all.R')"
```

o, desde una terminal:

```
CORRER_HONESTDID=TRUE Rscript run_all.R        # Linux/Mac
$env:CORRER_HONESTDID="TRUE"; Rscript run_all.R # PowerShell
```

**Tiempo aproximado** (equipo de referencia; varía según hardware y
conexión a internet para la descarga):

- Sin HonestDiD (`CORRER_HONESTDID = FALSE`, por defecto): **~3 minutos**
  (pipeline completo, descarga de datos incluida).
- Con HonestDiD (`CORRER_HONESTDID = TRUE`): **~15-20 minutos** (el
  contraste de sensibilidad en `05` es la parte lenta).

### `06` y el paquete `contdid`

`06_tratamiento_continuo.R` incluye, de forma opcional, un contraste con el
paquete `contdid` (Callaway, Goodman-Bacon y Sant'Anna). Si no está
instalado, el script corre igual y se salta ese contraste. Para instalarlo:
`remotes::install_github("bcallaway11/contdid")`.

## Datos

Ver [`1. DATOS/README.md`](1.%20DATOS/README.md). En resumen: se descargan
automáticamente desde Zenodo (DOI
[10.5281/zenodo.23097300](https://doi.org/10.5281/zenodo.23097300)) al
correr `run_all.R` o `3. SCRIPTS/00_descargar_datos.R`. Son un recorte,
verificado contra el pipeline de estimación, del conjunto de microdatos
completo:

> Gómez Orduz, J. A., y Jácome, N. (2026). *Harmonized Microdata from the
> Annual Manufacturing Survey (EAM) and Supporting Metadata for the
> Analysis of Labor Shocks in Colombia, 2008-2024* (v1.1) [Conjunto de
> datos]. Zenodo. https://doi.org/10.5281/zenodo.19675581

**Fuente: Departamento Administrativo Nacional de Estadística (DANE):
www.dane.gov.co**

## Licencia

El **código** de este repositorio está bajo licencia MIT (ver `LICENSE`).

Los **datos** (descargados desde Zenodo) tienen su propia licencia (CC BY
4.0) y su propia fuente (DANE, ver arriba) — no están cubiertos por la
licencia MIT del código.

## Cómo citar

**Código** (este repositorio): ver `CITATION.cff`.

**Datos**: Gómez Orduz, J. A., y Jácome, N. (2026). *Harmonized Microdata
from the Annual Manufacturing Survey (EAM) and Supporting Metadata for the
Analysis of Labor Shocks in Colombia, 2008-2024* (v1.1) [Conjunto de
datos]. Zenodo. https://doi.org/10.5281/zenodo.19675581

**Tesis**: Gómez Orduz, J. A., y Jácome, N. (2026). *Salario mínimo y
decisiones de la firma: evidencia del aumento de 2023 en la industria
manufacturera Colombiana* [Tesis de maestría, Universidad de los Andes].
Asesor: Andrés Ham.

---

## English summary

This repository holds the replication **code** (only) for the Master's
thesis *"Minimum wage and firm decisions: evidence from the 2023 increase
in Colombian manufacturing"*, Universidad de los Andes, by Julio Alejandro
Gómez Orduz ([ORCID 0009-0001-2013-8352](https://orcid.org/0009-0001-2013-8352))
and Nicolás Jácome, advised by Andrés Ham. It studies how Colombian
manufacturing firms responded to the 2023 minimum-wage increase, using the
DANE Annual Manufacturing Survey (EAM).

- **Requirements**: R 4.5.2 exactly, Rtools45 on Windows, internet access.
- **How to run**: open `salario-minimo-2023-eam.Rproj`, run
  `renv::restore(prompt = FALSE)`, then `source("run_all.R")`. This
  downloads the data from Zenodo (DOI
  [10.5281/zenodo.23097300](https://doi.org/10.5281/zenodo.23097300),
  verified by MD5 + SHA256), runs scripts `02 → 01 → 03 → 04 → 05 → 06 →`
  the two `herramientas/` tools in that order, and checks the thesis's key
  figures against `4. RESULTADOS/VERIFICACION.csv`.
- **HonestDiD**: off by default (`CORRER_HONESTDID = FALSE`, ~3 minutes
  end to end); set the `CORRER_HONESTDID` environment variable to `TRUE`
  for the full replication including the sensitivity contrast (~15-20
  minutes).
- **Data**: not included in this repository (see `1. DATOS/README.md`);
  downloaded from Zenodo, a verified trim of Gómez Orduz and Jácome (2026),
  *Harmonized Microdata from the Annual Manufacturing Survey (EAM)...*,
  https://doi.org/10.5281/zenodo.19675581. **Source: Departamento
  Administrativo Nacional de Estadística (DANE): www.dane.gov.co**
- **License**: code under MIT (`LICENSE`); the data has its own license
  (CC BY 4.0) and source (DANE), not covered by the code's MIT license.
- **Citation**: see `CITATION.cff` for the code; see above for the data
  and thesis citations.
