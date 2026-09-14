# SEO/GEO dentro de una web de producto

Lee esta referencia al ejecutar seo-geo o seo-audit. Sus heurísticas sirven
para descubrir preguntas, no sustituyen documentación oficial vigente ni la
evidencia del proyecto. Fecha de contraste de las fuentes: 2026-09-10.

## De intención a página

Parte del inventario, consultas/páginas existentes y preguntas del público.
Usa Search Console/Bing si están disponibles y autorizados, en la propiedad
exacta del proyecto; completa con búsqueda de solo lectura y fuentes primarias.
Si falta acceso, no repares credenciales ni atribuyas volumen/dificultad a una
intuición: marca la oportunidad como hipótesis y trabaja con evidencia pública.
Para tráfico agregado usa la fuente canónica del proyecto (Umami en este
portfolio); visitas, registros, indexación y menciones IA son señales distintas.

Entrega por página: intención, respuesta útil, propuesta de title/description,
H1/estructura, enlaces internos, idioma y política de indexación/canonical.
Usa vocabulario de búsqueda con naturalidad; no metas todas las keywords en la
home ni copies la misma respuesta en rutas para SEO y GEO. El contenido útil,
fuentes, ejemplos y límites deben ser visibles a las personas.

## Comprobaciones técnicas proporcionadas

- Conserva las convenciones URL y relaciones canonical/hreflang existentes
  salvo un cambio explícitamente incluido. Para contenido nuevo único, propone
  canonical propio; no apuntes toda página hermana a la home. No implementes
  migraciones/redirecciones o cambios de indexación al resolver otra tarea.
- Comprueba title/description, encabezados y enlaces del alcance. Valida que
  metadata, HTML renderizado y datos estructurados afirmen lo mismo.
- Usa JSON-LD solo si describe contenido visible y tiene sentido para ese tipo
  de página; consulta el vocabulario y soporte actual antes de implementarlo.
  Una FAQ útil puede estar en texto sin JSON-LD. No fabriques ratings,
  testimonios, precios ni identidades para satisfacer un schema.
- Distingue HTML de origen, DOM renderizado y texto extraído: una herramienta
  que omite scripts no demuestra ausencia de JSON-LD. Valida enlaces a rutas
  existentes; las propuestas aún no construidas no son enlaces públicos.

## GEO sin promesas ni permisos inferidos

- Haz explícitos nombre/categoría, funcionamiento, capacidades, condiciones y
  evidencia. Las respuestas deben entenderse por sí mismas sin convertirse en
  fragmentos artificiales para un robot. Las comparativas citan fuentes y fecha;
  una fecha de actualización solo cambia cuando cambia/revalida su contenido.
- No asumas que fuentes, estadísticas o FAQ aumentan citas en un porcentaje
  fijo. Resultados de estudios son contextuales, no un objetivo probado aquí.
  Disponibilidad técnica, recuperación, cita, recomendación y conversión no
  son equivalentes. Una única respuesta de un modelo no certifica visibilidad.
- No hay un archivo o schema especial obligatorio para aparecer en las
  funciones IA de Google Search. No generes llms.txt, pricing.md o contenido
  duplicado como requisitos de publicación; solo cuando haya un consumidor o
  encargo concreto que los justifique, sin prometer ranking.
- Separa rastreo de búsqueda, consultas de usuario y entrenamiento. Comprueba
  la documentación actual de cada proveedor antes de interpretar sus bots;
  permitir entrenamiento no es un requisito universal de citación. No cambies
  robots.txt, WAF, CDN ni la política de datos por una recomendación GEO.
- Un checker local acredita contenido/configuración inspeccionados, no que
  Google indexará o una IA citará. Las observaciones posteriores requieren URL
  publicada y condiciones de medición documentadas; no bloquean una entrega local.

## Fuentes primarias a reconsultar cuando afecten la decisión

- [Funciones IA y requisitos de Google Search](https://developers.google.com/search/docs/appearance/ai-features): fundamentos SEO, elegibilidad y límites de medición.
- [Actualizaciones de Search Central](https://developers.google.com/search/updates): comprobar soporte de funcionalidades. En el corte consultado, Google retiró FAQ rich results en mayo de 2026 y su documentación en junio; una receta antigua no acredita soporte.
- [Canonicalización](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls): selección de canónicas entre contenido duplicado/similar.
- [Políticas de spam](https://developers.google.com/search/docs/essentials/spam-policies): doorway pages y contenido escalado sin valor.
- [Crawlers de Google](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers): funciones y alcance de Google-Extended; no controla inclusión en Google Search.

Si otra skill contradice estas distinciones, contrasta la fuente vigente y
aplica el resultado al encargo; no propagues la contradicción ni edites esa
skill global como parte de crear una página.
