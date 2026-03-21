# Atrapa un cuadrado

Juego arcade para **iOS** hecho con **Swift**, **UIKit** y **SpriteKit**. El jugador mueve un personaje por la pantalla, atrapa cuadrados, esquiva obstáculos y progresa entre modos, personajes y mejoras.

**Repositorio:** [github.com/hermoso92/atrapauncuadrado](https://github.com/hermoso92/atrapauncuadrado)

## Requisitos

| Herramienta | Notas |
|-------------|--------|
| **Xcode** | Proyecto generado con Xcode 26.x (esquema con `LastUpgradeVersion = 2630`). Usa el Xcode que tengas instalado y, si hace falta, ajusta el *deployment target* en el proyecto. |
| **iOS** | `IPHONEOS_DEPLOYMENT_TARGET` actual: **26.2** (según `project.pbxproj`). Para publicar en dispositivos con un sistema anterior, baja ese valor en *Build Settings* del target. |
| **Swift** | 5.0 |

No hay dependencias externas (CocoaPods/SPM) en el estado actual del proyecto.

## Cómo abrir y ejecutar

1. Clona el repositorio:
   ```bash
   git clone https://github.com/hermoso92/atrapauncuadrado.git
   cd atrapauncuadrado
   ```
2. Abre `Atrapa un cuadrado.xcodeproj` en Xcode.
3. Selecciona el esquema **Atrapa un cuadrado** y un simulador o dispositivo.
4. Pulsa **Run** (⌘R).

Compilar desde terminal (ajusta el simulador al que tengas):

```bash
xcodebuild -scheme "Atrapa un cuadrado" -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Cómo está montada la app

### Punto de entrada y pantalla de juego

- `AppDelegate` / ciclo de vida de la app.
- `SceneDelegate` crea la ventana y pone como raíz un `GameViewController`.
- `GameViewController` envuelve un `SKView` y presenta la primera escena del flujo de menús.

### Flujo de escenas (SpriteKit)

1. **`ModeSelectScene`** — Pantalla inicial: banco de monedas, elección entre modos (**Clásico**, **Arsenal**, **Fantasma**) y acceso a tienda / ajustes.
2. Desde ahí se navega a menús de personaje, partida (`GameScene`), game over, tienda, etc., según las acciones del jugador.

`BaseScene` concentra utilidades comunes (fondos, paneles, botones `MenuButtonNode`, acceso a `SaveManager`, `SoundManager`, etc.).

### Módulos principales (carpetas)

| Carpeta | Rol |
|---------|-----|
| `Core/` | Constantes de juego (`GameConfig`), perfiles por modo (`GameModeProfile`), paleta (`Palette`), máscaras de física. |
| `Entities/` | Nodos del mundo: `PlayerNode`, `SquareNode`, `ObstacleNode`. |
| `Models/` | `GameMode`, `GameProgress`, personajes (`CharacterDefinition`), habilidades, armas, mejoras. |
| `Managers/` | Persistencia (`SaveManager`), sonido, hápticos, compras y tienda. |
| `Scenes/` | Todas las escenas SpriteKit del menú y del juego. |
| `UI/` | Componentes reutilizables (por ejemplo `MenuButtonNode`). |
| `Utilities/` | Geometría y helpers (`UIColor+Hex`). |

### Datos guardados

- `SaveManager` serializa `GameProgress` en **UserDefaults** (clave `atrapa_un_cuadrado.progress`).
- Incluye migración desde formatos antiguos si existían datos previos.
- Opciones de depuración (p. ej. *god mode* en progreso) están pensadas para desarrollo; revísalas antes de publicar.

### Compras y desbloqueos

- `PurchaseManager` / `StoreManager` gestionan productos y estado premium.
- Algunos modos o contenidos se desbloquean con monedas, compras o códigos según la lógica definida en `GameMode` y el progreso.

### Tests

- `Atrapa un cuadradoTests` — pruebas unitarias.
- `Atrapa un cuadradoUITests` — pruebas de interfaz.

Ejecutar tests en Xcode: **Product → Test** (⌘U).

## Configuración del proyecto Xcode

- **Product name / bundle:** target `AtrapaUnCuadrado` (nombre del `.app` generado).
- **Esquema compartido:** `Atrapa un cuadrado.xcodeproj/xcshareddata/xcschemes/Atrapa un cuadrado.xcscheme` (conviene versionarlo; `xcuserdata` está ignorado por `.gitignore`).
- **Icono:** `Assets.xcassets/AppIcon.appiconset/` (incluye `app-icon-1024.png`).
- **Entitlements:** `Atrapa un cuadrado.entitlements` y variante Release.

## Versionado y licencia

- **Versión documentada en Git:** etiqueta **`v1.0`** (véase [CHANGELOG.md](CHANGELOG.md)).
- **Licencia:** [MIT](LICENSE) — Copyright (c) 2026 Antonio Hermoso.

GitHub muestra automáticamente el `README.md` en la página del repositorio y detecta el archivo `LICENSE` para el resumen de licencia del proyecto.

## Contribuir

1. Haz un fork o clona el repo.
2. Crea una rama para tu cambio.
3. Mantén los commits claros y el proyecto compilando en Xcode.
4. Abre un *pull request* describiendo el cambio.

## Autor

Antonio Hermoso — proyecto **Atrapa un cuadrado**.
