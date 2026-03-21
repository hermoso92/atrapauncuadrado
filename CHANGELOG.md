# Historial de versiones

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/), y el proyecto usa [Versionado semántico](https://semver.org/lang/es/).

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
