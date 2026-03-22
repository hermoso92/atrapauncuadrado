# Atrapa un cuadrado

Juego para **iOS** hecho con **Swift**, **UIKit** y **SpriteKit**: arcade clásico (**Clásico**, **Arsenal**, **Fantasma**) más el modo persistente **Artificial World** (mapa, refugio, SwiftData). El jugador atrapa cuadrados, esquiva obstáculos y progresa entre personajes y mejoras.

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

- `App/AppDelegate.swift` — ciclo de vida de la app.
- `App/SceneDelegate.swift` — ventana raíz con `GameViewController` y arranque SwiftData del mundo (`ArtificialWorldPersistence.bootstrapIfNeeded()`).
- `App/GameViewController.swift` — `SKView` y primera escena: **`ModeSelectScene`**.

### Flujo de escenas (SpriteKit)

1. **`ModeSelectScene`** (`Features/Arcade/Scenes/`) — Pantalla inicial: banco de monedas y **cuatro** modos: **Clásico**, **Arsenal**, **Fantasma** y **Artificial World** (cuarta tarjeta). Los tres arcade siguen yendo a `MainMenuScene` → personaje / partida / tienda; Artificial World abre `ArtificialWorldScene`.
2. Arcade: `GameScene`, game over, tienda, ajustes, etc.
3. Mundo: `ArtificialWorldScene` con persistencia local vía `WorldRepository` (SwiftData).

`BaseScene` concentra utilidades comunes (fondos, paneles, `MenuButtonNode`, `SceneDependencies`, etc.).

### Módulos principales (carpetas)

| Carpeta | Rol |
|---------|-----|
| `App/` | `AppDelegate`, `SceneDelegate`, `GameViewController`. |
| `Features/Arcade/` | Arcade: escenas (`Scenes/`), `ArcadeRunTimers`. |
| `Features/ArtificialWorld/` | Modo persistente: `ArtificialWorldScene`, `WorldAgentBrain`, `ArtificialWorldSimulation`. |
| `Domain/` | Modelos y protocolos sin SpriteKit (mundo, telemetría, repositorio). |
| `Persistence/` | SwiftData: `SwiftDataWorldRepository`, modelos persistidos. |
| `Services/` | `SceneDependencies`, telemetría, preferencias de arranque, puente arcade↔mundo. |
| `Networking/` | Contratos de sync futuros (`WorldSyncProtocols`). |
| `Core/` | `GameConfig`, `GameModeProfile`, `Palette`, física. |
| `Entities/` | `PlayerNode`, `SquareNode`, `ObstacleNode`. |
| `Models/` | `GameMode`, `GameProgress`, personajes, habilidades, armas. |
| `Managers/` | `SaveManager`, sonido, hápticos, compras. |
| `UI/` | `MenuButtonNode` y componentes UI. |
| `Utilities/` | Geometría y helpers. |
| `docs/` | Documentación técnica; ver `ARTIFICIAL_WORLD_FASE0.md`. |

### Datos guardados

- **Arcade / metajuego:** `SaveManager` + **UserDefaults** (`atrapa_un_cuadrado.progress`), con migración desde formatos antiguos.
- **Artificial World:** **SwiftData** (estado de mundo, inventario, memoria del agente) a través de `ArtificialWorldPersistence`.
- Opciones de depuración (*god mode*, etc.) revisar antes de publicar.

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
