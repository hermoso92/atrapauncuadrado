# Historial de versiones

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y el proyecto usa [Versionado semántico](https://semver.org/lang/es/).

## [Unreleased]

## [1.1.2] — 2026-03-22

### Añadido

- CI en **GitHub Actions** (`.github/workflows/ios.yml`): build en simulador y tests unitarios en cada push/PR a `main`; badge en `README.md`. En el runner se usa `IPHONEOS_DEPLOYMENT_TARGET=18.0` (el target del proyecto puede seguir en 26.x en local).

## [1.1.1] — 2026-03-22

### Añadido

- `scripts/export-ipa.sh` con `ExportOptions-Development.plist` (método `debugging`) y `ExportOptions-AppStore.plist` (`app-store-connect`); documentado en `README.md`.

## [1.1.0] — 2026-03-22

### Añadido

- **Selector de modos** (`ModeSelectScene`): entrada desde `GameViewController` con **cuatro** rutas (Clásico, Arsenal, Fantasma, Artificial World); `AppLaunchPreferences.lastExperience` distingue arcade vs mundo.
- Tests de **`WorldAgentBrain`**: huida con hostil cercano, retirada al refugio con vitales bajos, formato de línea de utilidad.
- **Artificial World — progresión y arcade**: nivel de refugio con escala/regeneración vía `ArtificialWorldSimulation`; habilidades de mundo con cooldowns; puente `ArcadeWorldBridge` para lanzar `GameScene` desde el mundo y volver con bonus de monedas; protocolos de sync en `Networking/WorldSyncProtocols.swift` (stubs).
- **Artificial World**: modo persistente con mapa, refugio, entidades, hambre/energía, inventario, HUD, **SwiftData** (`WorldRepository`), memoria del agente, `WorldAgentBrain`, control manual/automático/híbrido y telemetría debug (`AppTelemetry`).
- **Dominio**: protocolos en `Domain/Protocols/` (repositorio de mundo, telemetría, reloj, auth, memoria del agente).
- **Arquitectura**: carpetas `App/`, `Features/Arcade/`, `Features/ArtificialWorld/`, `Persistence/`, `Services/`; `docs/ARTIFICIAL_WORLD_FASE0.md`.

### Cambiado

- `README.md`: estructura actual y flujo de cuatro modos.
- `ModeSelectScene`: layout de cuatro tarjetas **adaptativo** según altura de escena.
- `ArtificialWorldPersistence`: creación de **Application Support** antes del store SwiftData.
- Escenas arcade en `Features/Arcade/Scenes/`; punto de entrada UI en `App/`.
- `BaseScene` usa `SceneDependencies` en lugar de singletons como propiedades almacenadas.
- `GameScene`: temporizadores en `ArcadeRunTimersState` (mismas reglas de juego).

## [1.0.0] — 2026-03-21

### Añadido

- Juego en **SpriteKit** (reemplazo del pipeline Metal anterior): `GameScene`, nodos de jugador, cuadrados y obstáculos.
- Pantallas: selección de modo (`ModeSelectScene`), menú / tienda / ajustes, selección de personaje, partida y game over.
- Tres modos de juego: **Clásico**, **Arsenal** y **Fantasma** (con reglas de desbloqueo propias).
- Progresión: monedas, personajes desbloqueables, habilidades, armas y mejoras según modo; persistencia con `UserDefaults` vía `SaveManager`.
- Audio (`SoundManager`), vibración (`HapticsManager`), compras in-app (`PurchaseManager` / `StoreManager`).
- Localización de cadenas de interfaz en **español** (`es.lproj`).
- Documentación en repositorio: `README.md`, `LICENSE` (MIT), este `CHANGELOG.md`.
- Esquema Xcode compartido para compilar el mismo target en otros equipos.

### Notas

- Versión de marketing inicial de la app: **1.0** (etiqueta `v1.0` en Git).

[1.1.2]: https://github.com/hermoso92/atrapauncuadrado/releases/tag/v1.1.2
[1.1.1]: https://github.com/hermoso92/atrapauncuadrado/releases/tag/v1.1.1
[1.1.0]: https://github.com/hermoso92/atrapauncuadrado/releases/tag/v1.1.0
[1.0.0]: https://github.com/hermoso92/atrapauncuadrado/releases/tag/v1.0
