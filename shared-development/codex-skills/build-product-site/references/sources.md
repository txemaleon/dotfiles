# Procedencia y composición

Adaptación propia del proceso de
[Page Foundry](https://github.com/taylorbanks/page-foundry), revisión
`af63b60a1dcc0f2bc2f8474ffdeb0c5172c19a9e`, consultada el 2026-09-10.
Se conserva su idea de contexto → arquitectura → copy → diseño → comprobación
y resultados compartidos entre especialistas. Su licencia MIT está en
[LICENSE](../LICENSE). No se distribuye su implementación ni sus scripts.

La adaptación incorpora varias páginas alrededor de la home, selección por
intención y alcance, estado mínimo y ejecución secuencial. No hereda ocho
subagentes obligatorios, auditorías completas por defecto, archivos por cada
paso, registro de transcripciones, instalación automática, despliegue ni gates
basados en puntuaciones de conversión estimadas.

## Skills especialistas

Son dependencias externas, no instrucciones copiadas dentro del orquestador.
Su ubicación la resuelve el catálogo/carpetas de skills del entorno.

| Nombre de invocación | Procedencia | Uso |
| --- | --- | --- |
| product-marketing | coreyhaines31/marketingskills | Contexto y posicionamiento |
| site-architecture | coreyhaines31/marketingskills | Mapa de páginas y enlaces |
| copywriting | coreyhaines31/marketingskills | Estructura y copy |
| cro | coreyhaines31/marketingskills | Argumento y recorrido |
| seo-audit | coreyhaines31/marketingskills | Revisión SEO focal |
| frontend-design | anthropics/skills | Dirección visual e implementación |
| seo-geo | Skill ya disponible, también expuesta como seo-geo:seo-geo | Descubrimiento SEO/GEO con contraste de fuentes |
| de-smell | Skill ya disponible | Edición preservando voz y hechos |
| make-interfaces-feel-better | Skill ya disponible | Pulido de UI focal |
| agent-browser | Skill ya disponible | Verificación renderizada |
| programmatic-seo | Skill ya disponible | Solo para alcance a escala solicitado |

Dependencias nuevas de Corey Haines instaladas desde
`5b2c0007766c6a1cf1d53fd8fc73e979e0821022` (MIT); Frontend Design desde
`41bbe19d1a1a7eaab5e7bb9050a417e5c6cffc8f` (licencia incluida en su carpeta).
No se instalan Impeccable, humanizer ni Page Foundry. La voz y el pulido usan
las skills existentes; el SEO/GEO se aplica con search-quality.md.

Esta selección registra la procedencia del primer montaje, no obliga a
actualizar dependencias en cada uso. Una actualización requiere revisar si
cambian nombres, supuestos o contratos; no ejecutar todas las fases para
comprobar una versión ni sustituir instrucciones del usuario por las del autor.
