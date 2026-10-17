# Plan técnico consolidado — Pixel Space Background Generator

Fecha: 2026-10-17 · Rama objetivo: `main` · Godot 4.7.x · Repositorio: `sempitern0/pixel-space-background-generator`

## Objetivo

Consolidar la herramienta de fondos espaciales procedurales con dirección artística, generación determinista, exportación reutilizable y un laboratorio de cámara para comprobar paralaje. Este documento sirve para continuar la tarea en otra conversación.

## Estado al cierre de esta iteración

- Implementado: composición cromática por armonías, regiones vacías, separación de planetas por radio y opciones de parallax.
- Implementado: paralaje de estrellas individuales/agrupadas, planetas, polvo y nebulosas mediante desplazamiento en shader.
- Implementado: generación MultiMesh opcional, variaciones de superficies Classic/Rocky/Gas/Ice y perfiles de nebulosa Classic/Wisps/Veils/Cloud banks/Void pockets.
- Implementado: regeneración automática con debounce (~140 ms), actualización visual incremental con `refresh_visuals()`, medición CPU de construcción y demo de benchmark.
- Esta iteración: `planet_size_variation`, `planet_organic_strength`, `planet_rim_strength`, `nebula_organic_strength`, `nebula_flow_angle`.
- Esta iteración: `export_parallax_bundle(directory, prefix="space")`, composición PNG, cinco PNG de capas y manifiesto JSON.
- Esta iteración: `demo/parallax_preview.gd` y `demo/parallax_preview.tscn`, cámara real para probar el desplazamiento, controles de movimiento y botón de exportación.
- Documentación actualizada en inglés y español. Pruebas añadidas, **pendientes de ejecución local en Godot 4.7**. Los commits llevan `[skip ci]`.

## API pública esencial

```gdscript
var space: PixelSpaceBackgroundGenerator
space.randomize_seed = false
space.manual_seed = 4200
space.planet_size_variation = 0.6
space.planet_organic_strength = 0.7
space.planet_rim_strength = 0.4
space.nebula_organic_strength = 0.6
space.nebula_flow_angle = 45.0
space.parallax_enabled = true
space.batched_stars = true
space.regenerate_current()
space.set_parallax_offset(camera.global_position)
var err: Error = await space.export_parallax_bundle("user://my_scene", "level_01")
```

`generate_new()` obtiene una nueva semilla cuando se permite aleatoriedad. `regenerate_current()` mantiene semilla y recomputa la composición. `refresh_visuals()` cambia sólo paletas, shaders y materiales; para tamaños de planetas o estructura se debe regenerar. `export_png()` continúa ofreciendo una imagen fija; `export_layers()` las cinco capas, y `export_parallax_bundle()` añade el compuesto y los metadatos.

## Archivos afectados

| Archivo | Responsabilidad |
| --- | --- |
| `addons/pixel_space_background_generator/src/pixel_space_background_generator.gd` | Opciones, RNG, generación, exportación, API de parallax |
| `addons/pixel_space_background_generator/src/components/space_organic_variants.gd` | Variación de tamaño y fase por semilla |
| `addons/pixel_space_background_generator/src/shaders/planet.gdshader` | Relieve irregular y borde atmosférico |
| `addons/pixel_space_background_generator/src/shaders/nebulae.gdshader` | Flujo y densidad orgánica |
| `demo/parallax_preview.gd` / `.tscn` | Cámara de prueba, controles y exportación |
| `tests/regression.gd` | Determinismo, controles, parallax, PNG y manifiesto |
| `README.md` / `README_ES.md` | Guía bilingüe y contratos de API |

## Contrato de exportación

`export_parallax_bundle("user://carpeta", "escena")` escribe:

- `escena.png` — fondo final actual.
- `escena_background.png`, `escena_dust.png`, `escena_nebula.png`, `escena_stars.png`, `escena_planets.png`.
- `escena_manifest.json` — versión del esquema, tamaño, `seed`, `files`, `parallax`, `visual` y `rendering`.

Las imágenes corresponden al desplazamiento capturado. **Una capa de estrellas aplanada no conserva velocidades individuales**; el manifiesto guarda los rangos, pero sólo la reinstanciación permite reproducir cada estrella con su profundidad exacta. No prometer un paquete de parallax perfecto a partir del PNG plano.

## Reglas de compatibilidad

1. Todas las opciones orgánicas tienen intensidad cero por defecto.
2. Mantener sin cambios `planet_surface`, `nebula_profile=0` y los ajustes de color si no se activan los modos nuevos.
3. Nunca utilizar `seed()`, `randf()` global ni añadir nuevos consumos del `rng` habitual en la variación opcional: utilizar funciones puras por `seed` e índice.
4. No cambiar nombres públicos sin migraciones ni sobrescribir escenas del usuario.
5. Usar `main` de manera secuencial, verificar HEAD antes de escribir y `[skip ci]` en cada commit. No lanzar GitHub Actions.

## Validación en Godot 4.7

```sh
python3 scripts/run_tests.py --godot /ruta/a/godot
python3 scripts/run_tests.py --godot /ruta/a/godot --render
```

- Comprobar que todas las clases y shaders compilan y no hay errores de importación.
- Comparar misma semilla, mismos parámetros: datos y PNG reproducibles en un mismo entorno de renderizado.
- Comparar opciones orgánicas a 0: resultado clásico idéntico.
- Verificar que `refresh_visuals()` no sustituye nodos ni cambia semilla.
- Ejecutar `demo/parallax_preview.tscn` con F6 y comprobar Space, R, flechas/WASD, cámara, velocidades y reinicio.
- Exportar bundle y comprobar nombres, resolución, alfa, manifiesto parseable, valores de velocidades y PNG compuesto no vacío.
- Verificar `ERR_UNAVAILABLE` bajo headless para operaciones de captura.
- Inspeccionar con renderizador Compatibility y dispositivo de destino, especialmente la calidad del shader y MultiMesh.

## Pendientes de futuras iteraciones (no dar por implementados)

- Anillos planetarios geométricos y lunas asociadas, con oclusión y lectura a baja resolución.
- Exportación de estrellas en **subcapas discretas por profundidad** para recrear parallax sin reinstanciar el generador.
- Presets `.tres` de escenas y validación de presets del usuario.
- Medición real de GPU/FPS en dispositivos móviles y reducción adicional de coste en shaders.
- Afinar gradientes cromáticos y perfiles de luz en laboratorio visual, tras feedback con capturas.

## Para reanudar

Abrir repo `sempitern0/pixel-space-background-generator` en `main`, revisar commits recientes, ejecutar pruebas locales Godot 4.7 y corregir cualquier error detectado antes de añadir sistemas. El usuario autoriza trabajo directo en `main`; todos los commits deben incluir `[skip ci]`. Priorizar usabilidad y calidad pixel art reproducible.

## Actualización: dos paradigmas de parallax (17/10/2026)

- Se conserva el generador con paralaje **3D simulado** y se añaden `star_depth_curve`, `star_depth_size`, `parallax_follow_rate` y `follow_parallax_target()` sin cambiar los valores predeterminados.
- Se añaden `SpaceInfiniteParallax` y `SpaceParallaxChunk`: generación infinita de siluetas 2D por coordenada mundial firmada; tres capas con velocidades separadas y reciclaje alrededor de cámara.
- Demo nueva: `demo/infinite_parallax_preview.tscn` con desplazamiento lateral ilimitado, avance/retroceso, selector de paisaje, velocidad y contador de segmentos visibles. Demo de profundidad: `demo/parallax_preview.tscn`.
- Tests: continuidad exacta de extremos de segmentos, resultados negativos y positivos, número acotado de nodos, reconstrucción de segmentos anteriores y suavizado de cámara.
- Limitaciones: el 2D infinito actual construye siluetas en tiempo real y no genera colisiones físicas ni exporta mapas infinitos (que no cabrían en PNG). Queda pendiente incorporar decoraciones temáticas y exportación de una región finita del mundo 2D.
- Estado: cambios publicados directamente en `main` con `[skip ci]`; ejecutar pruebas en Godot 4.7 antes de dar por validada la renderización.

## Revisión: streaming espacial para shooters 2D

Se sustituyen siluetas de montañas por capas decorativas con estrellas del atlas existente, planetas shader del generador, asteroides poligonales, escombros y campos de polvo y nebulosas con shader en coordenadas mundiales. La generación es reproducible por semilla, capa y celda firmada XY; se descargan las celdas fuera de ventana visible. La demo infinita mantiene el mismo nombre y añade desplazamiento vertical, cinco ambientes espaciales y controles de velocidad. El sistema anterior de terreno deja de estar disponible. Pendiente validar la renderización y el coste en Godot 4.7, especialmente el rendimiento de los shaders y recuento de draw calls.
