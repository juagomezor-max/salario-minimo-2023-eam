# ==============================================================================
# run_all.R
#
# Corre todo el pipeline de replicación desde la raíz del repositorio:
#   00 (descarga datos si faltan) -> 02 -> 01 -> 03 -> 04 -> 05 -> 06 ->
#   herramientas/graficar_tendencias_paralelas.R ->
#   herramientas/graficar_figuras_tesis.R
#
# Cada script corre en su propio proceso de Rscript (así "rm(list = ls())"
# al inicio de cada uno no afecta a los demás ni a este orquestador). La
# salida de cada paso queda en "_tmp_log_<script>.txt" en la raíz (no se
# versiona, ver .gitignore).
#
# Bandera CORRER_HONESTDID: FALSE (por defecto) salta las secciones de
# HonestDiD en 05 (tardan varios minutos); TRUE corre la réplica completa.
# Cambiar aquí abajo o definir la variable de entorno CORRER_HONESTDID antes
# de llamar a este script (p. ej. desde una terminal:
#   CORRER_HONESTDID=TRUE Rscript run_all.R   [Linux/Mac]
#   $env:CORRER_HONESTDID="TRUE"; Rscript run_all.R   [PowerShell]
# ).
#
# Al final compara las cifras clave en resultados/VERIFICACION.csv contra
# los valores de referencia de la tesis (tolerancia 0.001) y avisa si algo
# no coincide.
# ==============================================================================

inicio_total <- Sys.time()

if (!exists("CORRER_HONESTDID_RUN_ALL")) {
  CORRER_HONESTDID_RUN_ALL <- Sys.getenv("CORRER_HONESTDID", unset = "FALSE")
}
Sys.setenv(CORRER_HONESTDID = CORRER_HONESTDID_RUN_ALL)

cat("==============================================================================\n")
cat("run_all.R -- réplica de 'Rigideces laborales y decisiones de la firma'\n")
cat("==============================================================================\n")
cat("CORRER_HONESTDID =", Sys.getenv("CORRER_HONESTDID"), "\n")

# --- 1. Versión de R ----------------------------------------------------------
version_actual <- paste(R.version$major, R.version$minor, sep = ".")
if (!identical(version_actual, "4.5.2")) {
  cat("\nAVISO: este proyecto se desarrolló con R 4.5.2; esta sesión corre con R",
      version_actual, "\n",
      "(renv::restore() puede fallar o dar paquetes compilados distinto -- ver README.md).\n")
} else {
  cat("\nVersión de R: 4.5.2 (OK)\n")
}

# --- 2. Pasos del pipeline ------------------------------------------------------
pasos <- list(
  list(nombre = "00_descargar_datos",                 ruta = file.path("scripts", "00_descargar_datos.R")),
  list(nombre = "02_medidas_exposicion",               ruta = file.path("scripts", "02_medidas_exposicion.R")),
  list(nombre = "01_descriptivos_y_contexto",          ruta = file.path("scripts", "01_descriptivos_y_contexto.R")),
  list(nombre = "03_primer_eslabon_medidas",           ruta = file.path("scripts", "03_primer_eslabon_medidas.R")),
  list(nombre = "04_decision_medida",                  ruta = file.path("scripts", "04_decision_medida.R")),
  list(nombre = "05_resultados_y_mecanismos",           ruta = file.path("scripts", "05_resultados_y_mecanismos.R")),
  list(nombre = "06_tratamiento_continuo",              ruta = file.path("scripts", "06_tratamiento_continuo.R")),
  list(nombre = "herramientas_graficar_tendencias_paralelas", ruta = file.path("scripts", "herramientas", "graficar_tendencias_paralelas.R")),
  list(nombre = "herramientas_graficar_figuras_tesis",  ruta = file.path("scripts", "herramientas", "graficar_figuras_tesis.R"))
)

tiempos <- data.frame(paso = character(0), segundos = numeric(0), stringsAsFactors = FALSE)

for (p in pasos) {
  cat("\n------------------------------------------------------------------------------\n")
  cat("Corriendo:", p$nombre, "\n")
  cat("------------------------------------------------------------------------------\n")

  log <- paste0("_tmp_log_", p$nombre, ".txt")
  t0 <- Sys.time()

  codigo <- system2("Rscript", shQuote(p$ruta), stdout = log, stderr = log,
                     env = paste0("CORRER_HONESTDID=", Sys.getenv("CORRER_HONESTDID")))

  dt <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  tiempos <- rbind(tiempos, data.frame(paso = p$nombre, segundos = round(dt, 1)))

  if (!identical(codigo, 0L)) {
    cat("\nERROR en", p$nombre, "(código de salida", codigo, "). Ver", log, "\n")
    cat("Últimas líneas del log:\n")
    salida <- tryCatch(readLines(log, warn = FALSE), error = function(e) character(0))
    cat(paste(tail(salida, 30), collapse = "\n"), "\n")
    stop("run_all.R se detiene en '", p$nombre, "'. Revisa '", log, "' para el detalle.")
  }

  cat("OK --", p$nombre, ":", round(dt, 1), "s\n")
}

cat("\n==============================================================================\n")
cat("Tiempos por paso\n")
cat("==============================================================================\n")
print(tiempos, row.names = FALSE)
cat("Tiempo total:", round(as.numeric(difftime(Sys.time(), inicio_total, units = "mins")), 1), "min\n")

# --- 3. VERIFICACIÓN: cifras clave contra los valores de referencia de la tesis ---
cat("\n==============================================================================\n")
cat("VERIFICACIÓN: cifras clave contra los valores de referencia\n")
cat("==============================================================================\n")

leer_csv_seguro <- function(ruta) {
  if (!file.exists(ruta)) return(NULL)
  tryCatch(read.csv(ruta, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8"),
            error = function(e) NULL)
}

valor_o_na <- function(df, condicion, columna) {
  if (is.null(df)) return(NA_real_)
  fila <- df[condicion, , drop = FALSE]
  if (nrow(fila) != 1) return(NA_real_)
  as.numeric(fila[[columna]][1])
}

t16 <- leer_csv_seguro(file.path("resultados", "06_tratamiento_continuo", "T16_distribucion_exposicion.csv"))
t24 <- leer_csv_seguro(file.path("resultados", "06_tratamiento_continuo", "T24_tres_medidas_real_vs_placebo.csv"))
t08 <- leer_csv_seguro(file.path("resultados", "05_resultados_y_mecanismos", "T08_resumen_principal.csv"))
t11b <- leer_csv_seguro(file.path("resultados", "05_resultados_y_mecanismos", "T11b_coeficientes_tendencias.csv"))

firmas_quintil <- if (is.null(t16)) rep(NA_real_, 5) else as.numeric(t16$firmas)

cond_t24 <- function(df, resultado, ejercicio) {
  df$medida == "A. Salario de la firma en el año base" &
    df$ejercicio == ejercicio &
    df$quintil == "Q5 (más expuestas)" &
    df$resultado == resultado
}

cond_t08 <- function(df, eslabon_prefijo) {
  df$lectura == "A. Cambio 2022 -> 2023" & startsWith(df$eslabon, eslabon_prefijo)
}

cond_t11b <- function(df) {
  df$variable == "log_empleo" & df$control == "Con control por tamaño" & df$anio == 2023
}

verificacion <- data.frame(
  concepto = c(
    "Firmas Q1", "Firmas Q2", "Firmas Q3", "Firmas Q4", "Firmas Q5",
    "Q5 costo, 2023 vs 2022 (%)", "Q5 empleo, 2023 vs 2022 (%)",
    "Efecto lineal costo, 2023 vs 2022 (%)", "Efecto lineal empleo, 2023 vs 2022 (%)",
    "Q5 costo, placebo 2019 (%)",
    "p tendencias previas, empleo con tamaño"
  ),
  valor_esperado = c(
    1020, 1022, 1017, 1020, 1020,
    8.2053, -0.7677,
    3.2692, -0.7659,
    8.3641,
    0.4551
  ),
  valor_obtenido = c(
    firmas_quintil,
    valor_o_na(t24, cond_t24(t24, "Costo laboral por trabajador (log)", "Real (choque de 2023)"), "efecto_porcentual"),
    valor_o_na(t24, cond_t24(t24, "Empleo total (log)", "Real (choque de 2023)"), "efecto_porcentual"),
    valor_o_na(t08, cond_t08(t08, "1. Costo laboral"), "efecto_pct"),
    valor_o_na(t08, cond_t08(t08, "2. Empleo total"), "efecto_pct"),
    valor_o_na(t24, cond_t24(t24, "Costo laboral por trabajador (log)", "Placebo (año sin choque: 2019)"), "efecto_porcentual"),
    valor_o_na(t11b, cond_t11b(t11b), "p_previos")
  ),
  stringsAsFactors = FALSE
)
verificacion$diferencia_absoluta <- abs(verificacion$valor_obtenido - verificacion$valor_esperado)
verificacion$ok <- !is.na(verificacion$diferencia_absoluta) & verificacion$diferencia_absoluta <= 0.001

dir.create("resultados", showWarnings = FALSE)
write.csv(verificacion, file.path("resultados", "VERIFICACION.csv"), row.names = FALSE)

print(verificacion, row.names = FALSE)

n_mal <- sum(!verificacion$ok)
if (n_mal > 0) {
  cat("\nAVISO:", n_mal, "cifra(s) difieren en más de 0.001 del valor de referencia.\n",
      "Revisa resultados/VERIFICACION.csv y los logs de cada paso.\n")
} else {
  cat("\nVERIFICACIÓN OK: las", nrow(verificacion), "cifras clave coinciden con la tesis",
      "(tolerancia 0.001).\n")
}

cat("\nGuardado: resultados/VERIFICACION.csv\n")
cat("==============================================================================\n")
cat("FIN de run_all.R\n")
cat("==============================================================================\n")
