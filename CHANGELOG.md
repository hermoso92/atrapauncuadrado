# Historial de versiones

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y el proyecto usa [Versionado semántico](https://semver.org/lang/es/).

## [Unreleased]

### Añadido

- **Selector de modos** (`ModeSelectScene`): entrada desde `GameViewController` con **cuatro** rutas (Clásico, Arsenal, Fantasma, Artificial World); `AppLaunchPreferences.lastExperience` distingue arcade vs mundo para telemetría o futuras mejoras.
- Tests de **`WorldAgentBrain`**: huida con hostil cercano, retirada al refugio con vitales bajos, formato de línea de utilidad.
- **Artificial World — progresión y arcade**: nivel de refugio con escala/regeneración vía `ArtificialWorldSimulation`; botones de habilidades de mundo con cooldowns; puente `ArcadeWorldBridge` para lanzar `GameScene` desde el mundo y volver con bonus de monedas al game over; protocolos de sync en `Networking/WorldSyncProtocols.swift` (stubs / NoOp).
- **Artificial World**: modo persistente con mapa base, refugio, entidades (cuadrados común/nutritivo/hostil/raro/recurso), hambre/energía, inventario mínimo, HUD, guardado **SwiftData** (`WorldRepository`), memoria resumida del agente, agente por utilidades + estados (`WorldAgentBrain`), control manual/automático/híbrido y telemetría en debug (`AppTelemetry`).
- **Dominio**: protocolos en `Domain/Protocols/` (repositorio de mundo, telemetría, reloj de simulación, auth anónima, memoria del agente).
- **Arquitectura**: carpetas `App/`, `Features/Arcade/`, `Features/ArtificialWorld/`, `Persistence/`, `Services/`; documentación en `docs/ARTIFICIAL_WORLD_FASE0.md`.
- Entrada **Artificial World** en la pantalla de selección principal (`ModeSelectScene`).

### Cambiado

- `README.md`: estructura actual (`App/`, `Features/`, Artificial World, SwiftData) y flujo de cuatro modos.
- `ModeSelectScene`: layout de cuatro tarjetas **adaptativo** a la altura de la escena (teléfonos bajos vs altos).
- `ArtificialWorldPersistence`: creación explícita de **Application Support** antes del store SwiftData.
- Escenas SpriteKit del arcade movidas a `Features/Arcade/Scenes/`; `AppDelegate` / `SceneDelegate` / `GameViewController` en `App/`.
- `BaseScene` usa `SceneDependencies` en lugar de singletons directos como propiedades almacenadas.
- `GameScene`: temporizadores de spawn y dificultad centralizados en `ArcadeRunTimersState` (sin cambiar reglas de juego).

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

- Versión de marketing de la app: **1.0** (según configuración del target en Xcode).

[1.0.0]: https://github.com/hermoso92/atrapauncuadrado/releases/tag/v1.0
