# datos/

Esta carpeta está vacía en el repositorio (ver `.gitignore`) — los paneles
pesan demasiado para versionarlos en git y ya están publicados en Zenodo.

## Cómo obtenerlos

Corre, desde la raíz del repositorio:

```
Rscript scripts/00_descargar_datos.R
```

Esto descarga el paquete de datos de replicación desde Zenodo
(DOI [10.5281/zenodo.23097300](https://doi.org/10.5281/zenodo.23097300)),
verifica su MD5 y el SHA256 de cada archivo, y deja listos aquí los tres
paneles que leen `scripts/01` a `scripts/06`:

- `panel_analitico_firma_eam.rds`
- `panel_firma_eam_expalt_completo.rds`
- `panel_establecimiento_formal.rds`

También queda, como referencia, el paquete completo descomprimido en
`datos/_paquete_zenodo/` (códigos EAM de cada columna, diccionarios
completos, licencia de los datos).

`run_all.R` llama a `00_descargar_datos.R` automáticamente si faltan los
paneles, así que normalmente no hace falta correr este paso a mano.

**Fuente:** Departamento Administrativo Nacional de Estadística (DANE):
www.dane.gov.co
