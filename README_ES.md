<p align="center"><img src="icon.svg" width="112" alt="Generador de fondos espaciales"></p>
<h1 align="center">Pixel Space Background Generator</h1>
<p align="center">Estrellas, planetas y nebulosas procedurales para Godot 4.7.</p>

[English](README.md) · **Español** · [Validación](https://github.com/sempitern0/pixel-space-background-generator/actions)

Crea variaciones de fondos espaciales sin dibujarlas una a una. Puedes utilizarlas
en una escena 2D o exportarlas a PNG. Es una adaptación a Godot del
[generador original de Deep-Fold](https://deep-fold.itch.io/space-background-generator).

## Primeros pasos

1. Utiliza **Godot 4.7.x**. Las comprobaciones automáticas usan **4.7.2 estable** y el renderizador Compatibility.
2. Copia `addons/pixel_space_background_generator/` a la carpeta `addons/` de tu juego, conservando su nombre.
3. Activa el complemento en **Proyecto → Ajustes del proyecto → Plugins**.
4. Instancia `addons/pixel_space_background_generator/src/pixel_space_background_generator.tscn` en una escena con controles. Asigna un tamaño mayor que cero.
5. Selecciona su raíz y pulsa **Generate New** en el Inspector. Elige una paleta y activa las capas que necesites.

También puedes abrir este repositorio y pulsar **F5**, o **F6** sobre la escena del
generador. Instancia la escena incluida: el script necesita sus nodos de capas.

## Conservar una variación

Desactiva **Randomize Seed** y establece **Manual Seed** para repetir una composición.
Si generas aleatoriamente, `last_seed` conserva la semilla del resultado actual.
Guárdala junto con los ajustes y la paleta.

```gdscript
@onready var fondo: PixelSpaceBackgroundGenerator = $PixelSpaceBackgroundGenerator

func _ready() -> void:
    fondo.randomize_seed = false
    fondo.manual_seed = 42
    fondo.auto_based_on_viewport_size = false
    fondo.fixed_amount_of_stars = 24
    fondo.fixed_amount_of_planets = 3
    fondo.generate_new()
```

| Ajuste | Función |
| --- | --- |
| Auto Based on Viewport Size | Calcula una cantidad de estrellas según el área disponible |
| Fixed Amount | Un valor positivo fija la cantidad; cero utiliza el intervalo o el modo automático |
| Min / Max Amount | Intervalo inclusivo; se normalizan límites negativos o invertidos |
| Current Color Scheme | Recurso `ColorGradient` con una `GradientTexture1D` |
| Display Stars / Stars Dust / Planets / Nebulaes | Activa cada capa por separado |
| Show Stars / Planets Behind | Coloca esos objetos detrás del polvo estelar y las nebulosas |
| Tiled / Tile Offset | Repetición del shader y margen de colocación; no garantiza bordes perfectamente continuos en toda combinación |

Los cambios y el redimensionado actualizan la vista de forma diferida. Desde código,
puedes modificar varios parámetros y llamar a `generate_new()`. Los nodos generados
son temporales: reserva `StarsContainer` y `PlanetContainer` para el generador y
coloca los nodos de tu juego fuera de ellos. Cada instancia tiene materiales propios.

## Exportar el fondo

**Export Background** crea el directorio seleccionado y guarda un PNG con nombre
único. Renderiza únicamente el fondo en un viewport independiente: no incluye
paneles del editor, su zoom ni la interfaz del juego. Exportar copia el resultado
actual, sin elegir otra semilla.

```gdscript
var error := await fondo.export_png("user://fondo.png")
if error != OK:
    push_warning(error_string(error))
```

El método `export_png()` requiere que exista la carpeta de destino y que haya un
renderizador activo. En modo `--headless` devuelve `ERR_UNAVAILABLE`, sin bloquearse.
El PNG tiene el tamaño entero del generador, entre 1 y 4096 píxeles por eje.
Usa `res://space_backgrounds` al trabajar en el editor y `user://` en juegos exportados.

Para obtener un planeta aislado, usa un fondo pequeño con una sola instancia de
planeta, desactiva estrellas, polvo y nebulosas y asigna un color de fondo
transparente. La posición y escala siguen las reglas del generador de fondos;
no es un editor específico de planetas ni un exportador de animaciones.

## Compatibilidad y pruebas

La versión **1.3.0** está orientada a Godot 4.7. Instala el complemento en `addons/pixel_space_background_generator/`; sus archivos de entrada son `plugin.cfg` y `plugin.gd`. Al actualizar una instalación existente, sustituye la carpeta anterior, actualiza las referencias a recursos en tus propias escenas y vuelve a activar el complemento. La reproducibilidad de las semillas requiere la misma implementación y ajustes del generador.

```sh
python3 scripts/run_tests.py --godot /ruta/a/godot
# Con una pantalla disponible; CI en Linux utiliza xvfb-run:
python3 scripts/run_tests.py --godot /ruta/a/godot --render
```

Se comprueban importación, scripts, semillas, aislamiento entre instancias,
cantidades, tamaños, capas y exportación PNG con OpenGL real. La composición se
reproduce con la misma implementación y configuración, pero los píxeles de un
shader pueden variar entre controladores gráficos. No se certifican dispositivos
Windows, macOS o móviles sin probarlos físicamente.

## Créditos y soporte

Generador y algoritmos visuales originales de [Deep-Fold](https://github.com/Deep-Fold).
Adaptación a Godot mantenida por [sempitern0](https://github.com/sempitern0).
Consulta [LICENSE](LICENSE) y conserva las atribuciones aplicables al redistribuir.

[Comunica un problema](https://github.com/sempitern0/pixel-space-background-generator/issues)
con versión de Godot, plataforma, semilla, ajustes y pasos de reproducción.

## Composición orgánica opcional

- **Star Cluster Strength** (0–1): concentra las estrellas en zonas de densidad variable; 0 mantiene el reparto uniforme original.
- **Planet Spacing** (píxeles): distancia mínima entre centros de planetas; puede producir menos planetas cuando no cabe la cantidad solicitada. Con 0 se mantiene el comportamiento anterior.

Ambos controles son reproducibles con una semilla fija. Se aplican a las posiciones sin modificar los shaders originales.

Pulsa **F5** para abrir el laboratorio interactivo con tres composiciones, semillas editables y exportación PNG. **F6** en la escena original conserva la demostración básica.

## Composición astronómica

**Planet Surface** permite elegir Classic, Rocky, Gas giant o Ice. **Planet Surface Detail** regula cuánto influye la textura procedural en la paleta y la iluminación existentes. Las superficies rocosas varían la corteza; los gigantes gaseosos forman bandas onduladas y los planetas helados añaden casquetes claros y fisuras. No se simula física astronómica.

**Nebula Filaments** combina filamentos con el ruido original, mientras **Nebula Coverage** regula la cobertura de las nubes. Con filamentos a 0 y cobertura a 0.5 se conserva el aspecto clásico.

```gdscript
fondo.randomize_seed = false
fondo.manual_seed = 4242
fondo.planet_surface = 2 # Gigante gaseoso
fondo.planet_surface_detail = 0.8
fondo.nebula_filaments = 0.75
fondo.nebula_coverage = 0.6
fondo.star_cluster_strength = 0.8
fondo.planet_spacing = 96.0
fondo.generate_new()
var error := await fondo.export_png("user://gigante_gaseoso.png")
```

Pulsa **F5** para comparar órbita tranquila, un campo estelar denso con gigantes gaseosos y sistemas lejanos con planetas helados. La exportación PNG conserva solamente el fondo generado. La escena original también funciona con **F6**.

Son shaders 2D artísticos, no órbitas físicas ni planetas 3D. Todos los planetas de una instancia comparten estilo; para combinar familias usa varias escenas generadoras. Verifica los bordes del PNG si necesitas repetición perfectamente continua, ya que el modo tiled anterior no garantiza continuidad de todos los elementos.

## Composición artística (opcional)

**Armonías cromáticas:** Activa `procedural_palette_enabled` para crear un `ColorGradient` reproducible que comparten estrellas, planetas y nebulosas. Configura `color_harmony` (Auto, Análoga, Complementaria, Complementaria dividida, Triádica, Neutros + acento), `space_atmosphere` (Espacio profundo, Nebulosa fría, Galaxia polvorienta, Vacío inquietante) y `palette_color_count` (3–16). El gradiente se crea para cada generador: no modifica los recursos `.tres` originales. Desactivado, se conserva el gradiente existente.

**Composición:** `clear_zone_radius` (0–0,45 de la dimensión menor) y `composition_focus` (punto normalizado) reservan una zona despejada de estrellas y de **centros** planetarios, útil para plataformas, acción o interfaz. Un planeta grande aún puede invadir ligeramente la zona. `planet_radius_spacing` compara radios visibles y utiliza `planet_spacing` como **margen adicional entre bordes**. Si no caben todos los planetas, omite los que provocarían solapamientos. El agrupamiento de estrellas continúa disponible.

**Paralaje ligero:** Activa `parallax_enabled` y llama `set_parallax_offset(camera_position)` con la posición de cámara en píxeles. Las estrellas usan velocidades reproducibles entre `far_star_factor` y `near_star_factor` y los planetas utilizan `planet_parallax_factor`. No vuelve a generar fondos. En esta primera integración, el polvo y las nebulosas continúan siendo capas estáticas de shader. El PNG captura las posiciones actuales. Para volver a la composición original, llama `set_parallax_offset(Vector2.ZERO)` antes de desactivar el paralaje.

```gdscript
@onready var space: PixelSpaceBackgroundGenerator = $PixelSpaceBackgroundGenerator

func _ready() -> void:
    space.randomize_seed = false
    space.manual_seed = 2026
    space.procedural_palette_enabled = true
    space.space_atmosphere = SpaceColorTheory.Atmosphere.COLD_NEBULA
    space.planet_radius_spacing = true
    space.clear_zone_radius = 0.17
    space.parallax_enabled = true
    space.generate_new()

func _process(_delta: float) -> void:
    space.set_parallax_offset(get_viewport().get_camera_2d().global_position)
```

En `demo/space_lab.tscn` puedes activar **Art-directed layout** y **Color harmony** para comparar con el mismo seed. El shader de nebulosas también reutiliza un cálculo idéntico de ruido para reducir el trabajo gráfico sin cambiar deliberadamente su aspecto.

## Vista previa automática de parámetros

**Auto Regenerate** está activado por defecto. Cambiar en el Inspector la composición, paletas, superficies planetarias, nebulosas, número de estrellas, mosaico o parámetros de paralaje actualiza el fondo tras una pausa breve (~140 ms). Varios cambios seguidos se agrupan para no reconstruir la escena con cada evento del deslizador. La actualización **conserva la semilla actual**, incluso con **Randomize Seed** activado. Utiliza **Generate New** cuando quieras otra composición aleatoria; `regenerate_current()` vuelve a dibujar la semilla seleccionada. Si Randomize Seed está desactivado, modificar `manual_seed` también actualiza el fondo. El color de fondo se aplica directamente.

Para modificar muchos parámetros desde código sin regeneraciones intermedias, ajusta `auto_regenerate = false`, configura los valores, llama `regenerate_current()` y vuelve a activar la actualización automática si lo necesitas. La demo usa esta estrategia para aplicar presets y ahora actualiza la escena al modificar su campo de semilla. La generación de una escena compleja sigue siendo síncrona, pero los deslizadores ya no disparan reconstrucciones por cada valor intermedio.

## Paralaje por capas, planetas variados y exportación PNG

Activa `parallax_enabled` y llama `set_parallax_offset(camera_position)`: ahora se desplazan **estrellas, planetas, polvo estelar y nebulosas** con factores independientes (`far_star_factor`, `near_star_factor`, `planet_parallax_factor`, `dust_parallax_factor`, `nebula_parallax_factor`). Polvo y nebulosas se desplazan mediante el shader, sin volver a generar ruido cada fotograma. Con desplazamiento cero o paralaje desactivado se conserva el aspecto estático.

Activa `mixed_planet_surfaces` para combinar planetas Classic, Rocky, Gas giant e Ice dentro de una misma escena. Su selección es determinista según la semilla y el índice. Desactívalo para seguir utilizando el tipo único de `planet_surface`.

Para exportar **cinco PNG independientes**, utiliza `await background.export_layers("user://capas", "nivel")`. Se guardan `nivel_background.png`, `nivel_dust.png`, `nivel_nebula.png`, `nivel_stars.png` y `nivel_planets.png`, con fondo transparente en las capas correspondientes y el mismo tamaño que la escena. Las capas desactivadas permanecen transparentes. Se crea la carpeta automáticamente; la exportación requiere renderizador gráfico y admite hasta 4096×4096 píxeles. Si necesitas un solo PNG compuesto, continúa usando `export_png()`. La demo incorpora un botón **Export Layers**.

## Estrellas densas y perfiles de nebulosas

Activa **Batched Stars** (`batched_stars = true`) para campos de estrellas densos. En vez de generar un `Sprite2D`, textura atlas y material por estrella, se usa un único `MultiMeshInstance2D` con un shader compartido que dibuja los cinco tipos de estrella existentes. Se conservan las posiciones, variantes de estrella y semillas posteriores de planetas. `get_generated_star_count()` devuelve la cantidad en cualquiera de los modos. En modo agrupado `star_objects` está vacío porque no existen nodos individuales. MultiMesh reduce el coste de objetos, pero conviene medir el rendimiento en el hardware objetivo. Está desactivado por defecto y respeta `set_parallax_offset()` y la paleta activa.

**Nebula Profile** (`nebula_profile`) permite Classic (0), Wisps (1), Veils (2), Cloud banks (3) y Void pockets (4). Reutiliza los campos de ruido existentes con ajustes de contraste y cobertura, sin añadir nuevas pasadas de ruido fractal. Classic conserva el shader anterior; los demás perfiles cambian deliberadamente la densidad. En `demo/space_lab.tscn` encontrarás **Batch stars** y el selector de nebulosa para comparar resultados con una misma semilla.

## Rendimiento: actualizaciones incrementales y benchmark

La vista previa automática ahora distingue **modificaciones estructurales** (cantidad, distancias, agrupación, semilla y renderizado agrupado) de **modificaciones visuales** (paletas, armonías, tipo y cobertura de nebulosa, sombreado planetario, orden y factores de paralaje). Las modificaciones visuales usan `refresh_visuals()` sin destruir y volver a crear estrellas ni planetas, conservando sus instancias y la semilla seleccionada. También puedes llamar `refresh_visuals()` después de modificar manualmente el recurso de gradiente. Se conserva la pausa de ~140 ms de los controles.

`last_generation_ms` indica el tiempo de CPU de la última regeneración completa y `last_visual_refresh_ms` el de la última actualización parcial. El botón **Benchmark stars** de la demo compara el coste de creación en CPU para 1.000 estrellas clásicas y 1.000 con MultiMesh, después restaura la configuración. **No mide los tiempos de GPU ni los FPS**, que deben comprobarse en el hardware de destino.

## Mundos orgánicos, exportación de producción y prueba de cámara

**Variación orgánica**, desactivada por defecto: `planet_size_variation` distingue un planeta principal de cuerpos secundarios. `planet_organic_strength` introduce asimetrías deterministas en bandas, relieves y hielo, mientras que `planet_rim_strength` añade iluminación atmosférica tenue. `nebula_organic_strength` y `nebula_flow_angle` aportan flujo direccional y irregularidad a las nubes sin volver a calcular la distribución de objetos. El tamaño planetario requiere regeneración; los demás cambios pueden actualizarse con `refresh_visuals()`.

**Exportación:** `await generator.export_parallax_bundle("user://space_pack", "nivel_01")` guarda un PNG compuesto, cinco PNG de capas (background, dust, nebula, stars y planets) y un archivo `nivel_01_manifest.json` con semilla, resolución, opciones visuales y factores de profundidad. Admite destinos `user://` y `res://`, y necesita un renderer activo. **Importante:** el PNG de estrellas está aplanado y pierde los factores de profundidad individuales; para reproducirlos exactamente se debe reinstanciar el generador con los parámetros y la semilla guardados.

**Prueba de cámara:** abre `demo/parallax_preview.tscn` y ejecuta la escena con F6. Una `Camera2D` alimenta el desplazamiento de las capas; el fondo y la interfaz están fijados a `CanvasLayer` para aislar los efectos del parallax. Puedes observar el movimiento automático, conducir con flechas/WASD, pausar con Espacio, reiniciar con R, variar velocidad y amplitud y pulsar **Export bundle** para guardar la escena. Es una validación visual de desplazamiento, no una medición de FPS.

## Dos modos de paralaje: profundidad 3D simulada y scroll 2D infinito

**Profundidad simulada:** abre `demo/parallax_preview.tscn` y ejecútala con F6. Los planos de estrellas, planetas, polvo y nebulosas recrean profundidad sin utilizar un mundo 3D real. `star_depth_curve` modifica la distribución de velocidades (1 por defecto); `star_depth_size` añade pistas de tamaño según profundidad (0 conserva el aspecto anterior). Para suavizar movimientos de cámara, usa `parallax_follow_rate` y `follow_parallax_target(camera.global_position, delta)`, que aplica interpolación exponencial independiente del framerate. `set_parallax_offset()` permanece disponible para desplazamiento inmediato y exportación precisa.

**Plataformeros / scroll lateral:** abre `demo/infinite_parallax_preview.tscn` (F6). `SpaceInfiniteParallax` ofrece tres capas de paisajes procedurales continuos con perfiles de cordilleras alienígenas, dunas o siluetas de asteroides. Genera y recicla segmentos próximos a la cámara, incluso al retroceder o avanzar por coordenadas negativas; no se repite una imagen fija. Las capas avanzan a velocidades independientes `background_speed`, `midground_speed` y `foreground_speed`. Los bordes comparten los mismos valores de muestreo mundial y evitan discontinuidades geométricas. Es decoración del fondo, no terreno de colisión.

```gdscript
var fondo := SpaceInfiniteParallax.new()
add_child(fondo)
fondo.configure(2026, 512, 360, 0)
fondo.update_camera(camera.global_position, get_viewport_rect().size.x)
```

Puedes definir `chunk_width`, `layer_height`, `buffer_chunks`, los colores, el preset y la velocidad de cada plano. En la demo se prueba con flechas izquierda/derecha, Espacio para alternar movimiento automático, R para volver al origen, selector de escenario y velocidad. Ambos modos son independientes: no se alteran por defecto los fondos o las exportaciones existentes. Falta validar gráficamente en Godot 4.7.

## Streaming espacial infinito (shooters 2D)

El componente `SpaceInfiniteParallax` ya no dibuja montañas: ahora genera segmentos de **estrellas del atlas, planetas del addon, asteroides poligonales, chatarra y campos de polvo y nebulosas con shaders del proyecto**. Reutiliza los mismos segmentos de forma determinista, limita los nodos activos y soporta movimiento horizontal, vertical y retroceso. Cinco ambientes: Open space, Asteroid belt, Orbital debris, Nebula corridor y Frozen void. Abre `demo/infinite_parallax_preview.tscn` (F6); mueve la cámara con las flechas, cambia el ambiente y la velocidad. El modo de profundidad simulada sigue independiente.

```gdscript
var fondo := SpaceInfiniteParallax.new()
add_child(fondo)
fondo.configure(2026, 512, 720, 1)
fondo.update_camera(camera.global_position, viewport_size.x, viewport_size.y)
```

Los objetos son decorativos, sin física ni enemigos. La exportación de mundo infinito no equivale a un PNG finito. Las siluetas montañosas anteriores dejan de formar parte de este modo. **Validación visual en Godot 4.7 pendiente**.
