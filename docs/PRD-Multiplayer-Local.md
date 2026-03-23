# PRD: Multijugador Local — "Atrapa un cuadrado"

## Overview del cambio

Implementar modo **multijugador local** (2-4 jugadores) en el mismo dispositivo iOS, permitiendo jugar cooperativo o competitivo en el mundo artificial. Cada jugador controla su personaje con touches en su zona de pantalla.

**Target**: v1.3.0  
**Rama**: `feature/multiplayer-local`  
**Depende de**: FASE5 completada (v1.2.0)

---

## Problema que resuelve

El juego actual es **100% single-player**. No hay forma de jugar con amigos en el mismo dispositivo. Esto limita:
- **Engagement social**: Los juegos locales son más divertidos con amigos
- **Retention**: Compañeros de juego multiplican las sesiones
- **Diferenciación**: Pocos juegos móviles ofrecen multiplayer local real
- **Viralidad**: "Oye, baixamos este jogo pra jogar juntos" es el mejor marketing

El jugador no tiene razón para traer amigos al juego. El multiplayer local cambia eso.

---

## Solución propuesta

### 1. Pantalla de Selección de Jugadores

**Módulo**: `Features/Multiplayer/Scenes/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `PlayerSelectScene` | `PlayerSelectScene.swift` | Selección de 2-4 jugadores, nombres, colores |
| `PlayerSlotView` | Mismo archivo | UI de cada slot de jugador |

**Flujo**:
```
ModeSelectScene → Tarjeta "Multijugador" 
    → PlayerSelectScene (elige 2-4 jugadores)
    → MultiplayerGameScene (partida)
```

**UI del selector**:
- 4 slots de jugador (vacío o ocupado)
- Botón + / - para agregar/quitar jugadores
- Elegir color/avatar por jugador
- Input de nombre opcional (default: "Player 1", "Player 2", etc.)
- Botón "Jugar" (habilitado cuando hay 2+ jugadores)

### 2. Sistema de Zonas de Pantalla

**Módulo**: `Features/Multiplayer/Components/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `ScreenZoneRouter` | `ScreenZoneRouter.swift` | Routing de touches a jugador |
| `ZoneDivider` | Mismo archivo | Líneas visuales entre zonas |

**Layout (portrait, 2 jugadores)**:
```
┌─────────────────────────┐
│  P1 HUD + Touch Zone    │  <- 50% superior
│  ─────────────────────── │
├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤  <- Línea divisoria
│  P2 HUD + Touch Zone    │  <- 50% inferior
└─────────────────────────┘
```

**Layout (4 jugadores)**:
```
┌─────────────────────────┐
│  P1 HUD + Touch Zone    │  <- 25% superior
├─────────────────────────┤
│  P2 HUD + Touch Zone    │  <- 25%
├─────────────────────────┤
│  P3 HUD + Touch Zone    │  <- 25%
├─────────────────────────┤
│  P4 HUD + Touch Zone    │  <- 25% inferior
└─────────────────────────┘
```

**Routing de touches**:
```swift
func playerIndex(for touch: UITouch, in sceneSize: CGSize) -> Int {
    let zoneHeight = sceneSize.height / CGFloat(playerCount)
    let location = touch.location(in: nil)
    let zoneIndex = Int(location.y / zoneHeight)
    return min(zoneIndex, playerCount - 1)
}
```

### 3. Estado Compartido del Mundo

**Módulo**: `Features/Multiplayer/Models/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `MultiplayerWorldState` | `MultiplayerWorldState.swift` | Entidades, refugio, spawn global |
| `PlayerSessionState` | Mismo archivo | Estado individual de cada jugador |
| `SharedInventory` | Mismo archivo | Inventario cooperativo |

**Modelo de estado compartido**:
```swift
struct MultiplayerWorldState {
    let worldId: UUID
    var entities: [Entity]              // Entidades del mundo (compartido)
    var refugeLevel: Int                // Nivel del refugio (compartido)
    var spawnedResourceIds: Set<UUID>   // Recursos ya recolectados
    var hostilePositions: [UUID: CGPoint]
    var zoneBounds: CGRect
}

struct PlayerSessionState {
    let playerId: Int                   // 1, 2, 3, o 4
    let name: String
    let color: PlayerColor
    var position: CGPoint
    var velocity: CGVector
    var hunger: Double                  // 0.0 - 1.0
    var energy: Double                 // 0.0 - 1.0
    var inventory: [String]            // Recursos del jugador
    var abilities: Set<WorldAbility>
    var score: Int                     // Para modo competitivo
    var isAlive: Bool
}
```

**Inventario cooperativo vs individual**:
- **Cooperativo**: Un solo inventario compartido entre todos los jugadores
- **Competitivo**: Cada jugador tiene su propio inventario
- **Híbrido** (v2): Recursos comunes pero score individual

### 4. HUD Individual por Jugador

**Módulo**: `Features/Multiplayer/Components/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `PlayerHUD` | `PlayerHUD.swift` | HUD minimalista por zona |
| `ZoneIndicator` | Mismo archivo | Indicador visual de zona |

**Elementos del HUD por jugador**:
```
┌─────────────────────────┐
│ P1 👤  🍖 ████░░  ⚡░░  │  <- Barra de recursos + energía
│     Score: 42           │
├─────────────────────────┤
│                         │
│    [ZONA DE JUEGO]     │
│                         │
└─────────────────────────┘
```

**Posicionamiento**:
- Las barras de recursos se posicionan en la esquina superior de cada zona
- Rotación del HUD para mantenerlo legible en cada zona
- Colores diferenciados por jugador para fácil identificación

### 5. Shared World Engine

**Módulo**: `Features/Multiplayer/Components/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `SharedWorldEngine` | `SharedWorldEngine.swift` | Lógica de mundo compartida |
| `MultiplayerEntitySpawner` | Mismo archivo | Spawn de entidades cooperativas |
| `DamageDistributor` | Mismo archivo | Distribución de daño a players |

**Responsabilidades**:
- Spawn de entidades basado en cantidad de jugadores (más jugadores = más entidades)
- Balanceo de dificultad: `baseDifficulty * (1 + 0.2 * (playerCount - 1))`
- Detección de colisiones para todos los players simultáneamente
- Distribución de daño cuando múltiples players son golpeados

### 6. Modo Competitivo (v1.2)

**Módulo**: `Features/Multiplayer/Scenes/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `ScoreLeaderboard` | `MultiplayerGameScene+Competitive.swift` | Leaderboard en tiempo real |

**Reglas competitivas**:
- Recurso capturado por un jugador no está disponible para otros
- Primer jugador en morir pierde
- Al final del tiempo, gana el de mayor score
- Modo "Todos contra todos" o "2 vs 2" (futuro)

---

## Arquitectura y diseño técnico

### Estructura de archivos

```
Features/Multiplayer/
├── Scenes/
│   ├── PlayerSelectScene.swift              # Selector de jugadores
│   ├── MultiplayerGameScene.swift          # Scene principal multiplayer
│   └── MultiplayerGameScene+Competitive.swift  # Lógica competitiva
├── Models/
│   ├── MultiplayerWorldState.swift         # Estado del mundo compartido
│   ├── PlayerSessionState.swift            # Estado individual por jugador
│   └── MultiplayerMode.swift               # Coop vs Competitive
├── Components/
│   ├── ScreenZoneRouter.swift              # Routing de touches
│   ├── ZoneDivider.swift                   # Líneas divisorias
│   ├── PlayerHUD.swift                     # HUD individual
│   ├── SharedWorldEngine.swift             # Lógica compartida
│   └── MultiplayerEntitySpawner.swift      # Spawn por player count
└── Extensions/
    └── ArtificialWorldScene+Multiplayer.swift  # Extensión de scene existente
```

### Dependencias entre módulos

```
PlayerSelectScene
    └── Crea → PlayerSessionState[] + MultiplayerWorldState
                    │
                    ▼
MultiplayerGameScene
    ├── ScreenZoneRouter (touches)
    ├── PlayerHUD[] (uno por player)
    ├── SharedWorldEngine
    │       ├── MultiplayerEntitySpawner
    │       └── DamageDistributor
    └── ArtificialWorldScene (reuse entities, refugio)
```

### Integración con código existente

**Minimal changes a archivos existentes**:
- `ModeSelectScene`: Añadir tarjeta "Multijugador"
- `GameViewController`: Cambios en presentScene para soportar multiplayer
- `ArtificialWorldScene`: No se modifica, se crea nuevo `MultiplayerGameScene`

**Reuso de componentes**:
- `WorldAbility` — Ya existe, reusable
- `EntityArchetype` — Ya existe, reusable
- `RefugeDefenseSystem` — Ya existe, compartido entre players
- `SoundManager` — Ya existe, con sonidos multiplayer

### Persistencia

**v1 (MVP)**: Sin persistencia multiplayer
- Cada partida es nueva
- No se guarda progreso entre sesiones multiplayer

**v1.1+**: Guardar records locales
```swift
struct MultiplayerHighScore: Codable {
    let playerCount: Int
    let mode: MultiplayerMode
    let highScore: Int
    let date: Date
}
```

### Telemetría

Eventos a registrar:

| Evento | Parámetros | Trigger |
|--------|-------------|---------|
| `multiplayer_started` | `{playerCount: Int, mode: String}` | Inicio de partida |
| `player_joined` | `{playerIndex: Int, name: String}` | Jugador entra |
| `resource_collected` | `{playerIndex: Int, count: Int, shared: Bool}` | Recolecta recurso |
| `player_died` | `{playerIndex: Int, cause: String}` | Jugador muere |
| `multiplayer_ended` | `{winnerIndex: Int?, score: Int, duration: Int}` | Fin de partida |

---

## User Flows

### Flow 1: Iniciar Partida Multijugador

```
Jugador abre el juego
    │
    ▼
ModeSelectScene → Toca tarjeta "Multijugador"
    │
    ▼
PlayerSelectScene
    │
    ├── Jugador 1 se une (automático, host)
    ├── Otros jugadores tocan "Unirse" (o CPU en v1)
    ├── Eligen colores y nombres
    └── Toca "Jugar" (cuando hay 2+ jugadores)
    │
    ▼
MultiplayerGameScene (coop por defecto)
    │
    ├── Se muestra mundo compartido
    ├── Cada jugador ve su HUD en su zona
    └── Toca para moverse en su zona
```

### Flow 2: Recolectar Recurso (Cooperativo)

```
Player 1 toca recurso en su zona
    │
    ▼
ScreenZoneRouter detecta touch → playerIndex = 0
    │
    ▼
SharedWorldEngine.valida colisión con Player 1
    │
    ├── Recurso se marca como recolectado
    ├── Inventario compartido += recurso
    ├── Todos los players ven el recurso desaparecer
    └── Se actualiza HUD de todos (inventory count)
```

### Flow 3: Modo Competitivo

```
PlayerSelectScene → Toggle "Competitivo"
    │
    ▼
En partida:
    │
    ├── Cada recurso tiene owner (quien lo toca primero)
    ├── Recursos propios dan score
    ├── Recursos ajenos aparecen en gris (no recolectables)
    └── Al morir, el jugador sigue viendo hasta que termine
    │
    ▼
Game Over → Leaderboard muestra ranking de players
```

### Flow 4: Jugador Muere

```
Player 2 recibe daño fatal (hunger o enemigo)
    │
    ▼
PlayerSessionState.isAlive = false
    │
    ├── Player 2 ve "Eliminado" overlay
    ├── Puede spectear a otros jugadores
    └── Otros players siguen jugando
    │
    ▼
Si todos mueren → Game Over competitivo
Si hay supervivientes → Continúa hasta time limit
```

---

## UI/UX Específico

### Pantalla de Selección

**Layout**:
```
┌─────────────────────────────────┐
│   🎮 MULTIJUGADOR              │
│                                 │
│  ┌─────────────────────────┐  │
│  │ 👤 Player 1 (Tú)        │  │  <- Amarillo
│  │ [Cambiar Color] [Nombre]│  │
│  └─────────────────────────┘  │
│  ┌─────────────────────────┐  │
│  │ 👤 Player 2             │  │  <- Azul
│  │ [+ CPU] o [Quitar]      │  │
│  └─────────────────────────┘  │
│  ┌─────────────────────────┐  │
│  │ + Agregar Jugador      │  │
│  └─────────────────────────┘  │
│                                 │
│  [☐ Cooperativo]             │
│  [☐ Competitivo]              │
│                                 │
│  ════════════════════════════  │
│                                 │
│       [ ⚽ JUGAR ]             │  <- Habilitado con 2+
│                                 │
└─────────────────────────────────┘
```

### HUD en Partida (2 jugadores)

**Zona Player 1 (superior, 50%)**:
- Barra hunger/energy en esquina superior
- Color coding: amarillo
- Toca cualquier parte para moverse ahí

**Zona Player 2 (inferior, 50%)**:
- Barra hunger/energy en esquina inferior
- Color coding: azul
- Toca cualquier parte para moverse ahí

### Líneas Divisorias

- Línea punteada entre zonas
- Color semi-transparente (20% opacidad)
- Altura: 2pt
- No bloquea touches (solo visual)

---

## Scope v1 (MVP)

### Incluido

- ✅ Pantalla de selección de 2-4 jugadores
- ✅ Zonas de pantalla fijas (no hay scroll por zona)
- ✅ HUD individual por jugador (hunger, energy, score)
- ✅ Inventario cooperativo
- ✅ Entidades compartidas (spawn adaptado a player count)
- ✅ Modo cooperativo
- ✅ Sonidos multiplayer

### No incluido en v1

- ❌ Modo competitivo (v1.2)
- ❌ Scroll/zoom del mundo (world bounds fijo)
- ❌ Persistencia de progreso multiplayer
- ❌ 2ª pantalla (AirPlay)
- ❌ Bot API o matchmaking online
- ❌ Logros en multiplayer
- ❌ Zonas del Artificial World (FASE5)

---

## Métricas de éxito

1. **Partida promedio**: 8+ minutos de juego con 2 jugadores
2. **Retención**: Jugadores que prueban multiplayer vuelven 2x más
3. **Engagement**: Sessions por día aumentan 30% con feature
4. **Performance**: 60fps con 4 jugadores y 20 entidades
5. **Build exitoso**: Compila y pasa tests en Xcode

---

## Risks identificados

| Risk | Impacto | Mitigación |
|------|---------|------------|
| Multitouch no funciona en Simulator | Alto | Testear en dispositivo real temprano |
| UI cramped con 4 jugadores | Alto | Diseño minimalista del HUD, usar icons |
| Desincronización de estado entre players | Alto | Single source of truth (SharedWorldEngine) |
| Balanceo difícil (2 vs 4 jugadores) | Medio | Escalar dificultad linealmente |
| Memoria con 4 players + entidades | Medio | Limitar entidades activas, pooling de nodos |
| Split-screen confunde a usuarios | Medio | Tutorial on-boarding en primera partida |

---

## Timeline estimado

| Fase | Descripción | Estimación |
|------|-------------|-------------|
| 1 | PlayerSelectScene + UI de selección | 2-3 días |
| 2 | ScreenZoneRouter + multitouch | 1-2 días |
| 3 | MultiplayerGameScene base + PlayerSessionState | 2 días |
| 4 | HUD por jugador + ZoneDivider | 1-2 días |
| 5 | SharedWorldEngine + EntitySpawner adaptado | 2 días |
| 6 | Integración con modo cooperativo | 2 días |
| 7 | Testing + balanceo | 2-3 días |
| **Total v1** | | **12-16 días** |

---

## Estrategia de Testing

| Tipo de test | Cobertura | Herramienta |
|--------------|-----------|-------------|
| **Unit tests** | ScreenZoneRouter, MultiplayerWorldState | XCTest |
| **Integration tests** | Flujo completo: selección → partida → fin | XCTest + mock de touches |
| **UI tests** | Navegación, selección de jugadores | Xcode UI Tests |
| **Manual tests** | Multitouch real, feel del juego | Device testing |

**Nota**: El multitouch es difícil de testear automáticamente. Priorizar device testing manual.

---

## Doc. relacionada

- `docs/PROPUESTA-Multiplayer-Local.md` — Propuesta inicial
- `docs/PRD-FASE5-ArtificialWorld-Progression.md` — Feature que precede a esta
- `CHANGELOG.md` — Se actualiza en release