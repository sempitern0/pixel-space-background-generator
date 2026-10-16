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

La versión **1.1.0** está orientada a Godot 4.7. Instala el complemento en `addons/pixel_space_background_generator/`; sus archivos de entrada son `plugin.cfg` y `plugin.gd`. Al actualizar una instalación existente, sustituye la carpeta anterior, actualiza las referencias a recursos en tus propias escenas y vuelve a activar el complemento. La reproducibilidad de las semillas requiere la misma implementación y ajustes del generador.

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
