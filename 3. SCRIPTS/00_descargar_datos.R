# ==============================================================================
# 00_descargar_datos.R
#
# Descarga el paquete de datos de replicacion desde Zenodo, verifica su
# integridad y lo deja listo en 1. DATOS/ para que 01-06 lo lean.
#
# Si 1. DATOS/ ya tiene los 3 paneles (panel_analitico_firma_eam.rds,
# panel_firma_eam_expalt_completo.rds, panel_establecimiento_formal.rds), no
# hace nada.
#
# Pasos si faltan: descarga el zip del registro de Zenodo, verifica su MD5,
# lo descomprime en 1. DATOS/_paquete_zenodo/ (se conserva como referencia:
# trae CODEBOOK.csv, README.md y docs/originales/ del paquete), verifica
# cada archivo contra el CHECKSUMS.sha256 que viene dentro del zip, y copia
# los 3 .rds a 1. DATOS/ (ruta plana que esperan 01-06).
#
# Si algo no coincide (descarga incompleta, MD5 distinto, SHA256 distinto,
# archivo faltante), el script se detiene con un mensaje claro -- no sigue
# con datos que no se pudieron verificar.
# ==============================================================================

ZENODO_DOI <- "10.5281/zenodo.23097300"
ZENODO_URL <- "https://zenodo.org/records/23097300/files/zenodo_replicacion.zip?download=1"
ZIP_MD5    <- "fbf8203ade288dcf0e330e118870d60a"

CARPETA_DATOS   <- "1. DATOS"
CARPETA_PAQUETE <- file.path(CARPETA_DATOS, "_paquete_zenodo")
ZIP_DESTINO     <- file.path(CARPETA_DATOS, "_zenodo_replicacion_descarga.zip")

PANELES <- c(
  "panel_analitico_firma_eam.rds",
  "panel_firma_eam_expalt_completo.rds",
  "panel_establecimiento_formal.rds"
)

ya_estan <- all(file.exists(file.path(CARPETA_DATOS, PANELES)))

if (ya_estan) {

  cat("1. DATOS/ ya tiene los 3 paneles -- no se descarga nada.\n")

} else {

  dir.create(CARPETA_DATOS, showWarnings = FALSE, recursive = TRUE)

  cat("==============================================================================\n")
  cat("Descargando el paquete de datos de replicacion desde Zenodo\n")
  cat("DOI:", ZENODO_DOI, "\n")
  cat("URL:", ZENODO_URL, "\n")
  cat("==============================================================================\n")

  descarga_ok <- tryCatch({
    utils::download.file(ZENODO_URL, destfile = ZIP_DESTINO, mode = "wb", quiet = FALSE)
    TRUE
  }, error = function(e) {
    cat("ERROR al descargar:", conditionMessage(e), "\n")
    FALSE
  })

  if (!descarga_ok || !file.exists(ZIP_DESTINO) || file.size(ZIP_DESTINO) == 0) {
    stop(
      "No se pudo descargar el paquete de datos desde Zenodo (", ZENODO_URL, ").\n",
      "Descargalo a mano y coloca el .zip en '", ZIP_DESTINO, "', o descomprimelo ",
      "directamente en '", CARPETA_PAQUETE, "/' (respetando la estructura data/, ",
      "docs/, CHECKSUMS.sha256 del paquete), y vuelve a correr este script."
    )
  }

  cat("\nVerificando MD5 del zip descargado...\n")
  md5_real <- tolower(unname(tools::md5sum(ZIP_DESTINO)))
  if (!identical(md5_real, tolower(ZIP_MD5))) {
    unlink(ZIP_DESTINO)
    stop(
      "El MD5 del zip descargado (", md5_real, ") NO coincide con el esperado (",
      ZIP_MD5, "). El archivo puede estar corrupto, la descarga incompleta, o la ",
      "version publicada en Zenodo cambio. Se borro el zip descargado -- vuelve a ",
      "correr este script para reintentar."
    )
  }
  cat("MD5 OK:", md5_real, "\n")

  cat("\nDescomprimiendo en", CARPETA_PAQUETE, "...\n")
  dir.create(CARPETA_PAQUETE, showWarnings = FALSE, recursive = TRUE)
  utils::unzip(ZIP_DESTINO, exdir = CARPETA_PAQUETE)
  unlink(ZIP_DESTINO)

  ruta_checksums <- file.path(CARPETA_PAQUETE, "CHECKSUMS.sha256")
  if (!file.exists(ruta_checksums)) {
    stop(
      "No se encontro CHECKSUMS.sha256 dentro del paquete descomprimido en '",
      CARPETA_PAQUETE, "'. El contenido del zip no corresponde al paquete esperado."
    )
  }

  if (!requireNamespace("digest", quietly = TRUE)) {
    stop(
      "El paquete 'digest' no esta instalado -- no se puede verificar SHA256.\n",
      "Corre renv::restore() primero (ver README.md) y vuelve a correr este script."
    )
  }

  cat("\nVerificando archivos contra CHECKSUMS.sha256...\n")
  lineas <- readLines(ruta_checksums, warn = FALSE)
  lineas <- lineas[nzchar(trimws(lineas))]
  patron <- "^([0-9a-fA-F]{64})\\s+\\*?(.+)$"

  errores <- character(0)
  n_verificados <- 0

  for (linea in lineas) {
    m <- regmatches(linea, regexec(patron, linea))[[1]]
    if (length(m) != 3) {
      errores <- c(errores, paste("linea con formato invalido en CHECKSUMS.sha256:", linea))
      next
    }
    hash_esperado <- tolower(m[2])
    ruta_rel      <- m[3]
    ruta_completa <- file.path(CARPETA_PAQUETE, ruta_rel)

    if (!file.exists(ruta_completa)) {
      errores <- c(errores, paste("falta el archivo:", ruta_rel))
      next
    }

    hash_real <- tolower(digest::digest(ruta_completa, algo = "sha256", file = TRUE))
    if (!identical(hash_real, hash_esperado)) {
      errores <- c(errores, sprintf(
        "SHA256 no coincide en %s (esperado %s, real %s)",
        ruta_rel, hash_esperado, hash_real
      ))
    } else {
      n_verificados <- n_verificados + 1
    }
  }

  if (length(errores) > 0) {
    stop(
      "Verificacion contra CHECKSUMS.sha256 fallo en ", length(errores), " archivo(s):\n  - ",
      paste(errores, collapse = "\n  - "),
      "\nLos datos en '", CARPETA_PAQUETE, "' no son confiables -- no se copiaron a '",
      CARPETA_DATOS, "'. Borra '", CARPETA_PAQUETE, "' y vuelve a correr este script."
    )
  }

  cat("Verificacion OK:", n_verificados, "archivo(s) coinciden con CHECKSUMS.sha256.\n")

  cat("\nCopiando los 3 paneles a", CARPETA_DATOS, "...\n")
  for (p in PANELES) {
    origen  <- file.path(CARPETA_PAQUETE, "data", p)
    destino <- file.path(CARPETA_DATOS, p)
    if (!file.exists(origen)) {
      stop("No se encontro '", origen, "' tras la verificacion -- revisa el paquete descargado.")
    }
    file.copy(origen, destino, overwrite = TRUE)
    cat("  ", destino, "\n")
  }

  cat("\nListo. Los paneles estan en '", CARPETA_DATOS, "'. El resto del paquete ",
      "(CODEBOOK.csv, README.md, docs/originales/, etc.) queda como referencia en '",
      CARPETA_PAQUETE, "'.\n", sep = "")
}
