# Propuesta: Multijugador Local para "Atrapa un cuadrado"

## Overview

Implementar modo **multijugador local** (2-4 jugadores) en el mismo dispositivo, permitiendo jugar con amigos en pantalla compartida. Los jugadores compiten o cooperan en el mundo artificial.

## Estado actual

- **GameViewController**: Single SKView, una escena a la vez
- **ModeSelectScene**: 4 tarjetas (Clásico, Arsenal, Fantasma, Artificial World)
- **ArtificialWorldScene**: Un solo jugador con `playerNode`, brain IA, hunger/energy, inventario
- **Input**: Touch único, sin distinción de múltiples dedos por jugador

## Desafíos técnicos

1. **Multitouch**: SKView recibe todos los touches — necesita路由 por región de pantalla o por finger ID
2. **Shared state**: Un snapshot actual no soporta múltiples jugadores
3. **Camera**: Actualmente fixed al player — ¿cómo manejar 2-4 players en pantalla?
4. **Performance**: Cada player añade entities, UI, lógica

## Solución propuesta

### Arquitectura

```
Features/Multiplayer/
├── Scenes/
│   ├── PlayerSelectScene.swift     # Seleccionar 2-4 jugadores
│   └── MultiplayerGameScene.swift # Scene base con múltiples players
├── Models/
│   └── MultiplayerSnapshot.swift   # Estado para múltiples jugadores
└── Components/
    ├── PlayerInputRouter.swift      # Routing de touches por zona
    └── SharedWorldEngine.swift     # Lógica de mundo compartida
```

### Modo de juego

| Modo | Descripción |
|------|-------------|
| **Cooperativo** | Juntar recursos, defender refugio juntos, compartir inventario |
| **Competitivo** | Ver quién atrapa más recursos, primero en completar logros |

### Zonas de pantalla para players (iPhone portrait)

```
┌─────────────────────────┐
│      Player 1           │  <- 25% superior
│      (zona táctil)       │
├─────────────────────────┤
│      Player 2           │  <- 25% siguiente
├─────────────────────────┤
│      Player 3 (si hay)  │
├─────────────────────────┤
│      Player 4 (si hay)  │  <- 25% inferior
└─────────────────────────┘
```

### Cambios en ArtificialWorldScene

- `players: [PlayerState]` en vez de `snapshot` único
- Cada player tiene su propio hunger, energy, inventario
- El mundo (entidades, refugio) es compartido
- Camera sigue al centroid de todos los players o permite zoom out

### Input routing

```swift
// PlayerInputRouter.swift
func route(touch: UITouch, in sceneSize: CGSize) -> Int {
    let regionHeight = sceneSize.height / playerCount
    let touchY = touch.location(in: nil).y
    return min(Int(touchY / regionHeight), playerCount - 1)
}
```

## Scope v1 (MVP)

- 2 jugadores máximo en una partida
- Solo modo Artificial World (no arcade)
- Cooperativo por defecto (comparten recursos)
- Sin persistencia multiplayer (cada partida es nueva)
- Sin logros ni zonas en v1

## Complejidad

| Área | Esfuerzo |
|------|----------|
| PlayerSelectScene | Medio |
| Input routing multitouch | Bajo-Medio |
| Multiplayer state | Medio |
| UI por player (HUD individual) | Medio |
| Balance de juego | Alto |
| Tests | Alto |

## siguiente paso

¿Querés que genere un PRD completo para esta feature?