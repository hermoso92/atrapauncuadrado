# PRD: Artificial World FASE5 — Sistema de Progresión y Zonas

## Overview del cambio

Extender el modo **Artificial World** con un sistema completo de progresión que incluye: logros (achievements), registro de zonas explorables, sistema de defensa del refugio, spawn de entidades por zona, y memoria de peligros para el agente.

**Target**: v1.2.0  
**Rama**: `feature/artificial-world-cuatro-modos`  
**Estado**: En desarrollo (cambios locales sin confirmar)

---

## Problema que resuelve

El Artificial World actual (v1.1.x) ofrece un mundo persistente con supervivencia básica (hambre/energía), pero carece de:
- **Metas a largo plazo** para el jugador (logros)
- **Exploración estructurada** (zonas desbloqueables)
- **Defensa del refugio** (sistema de patrulla)
- **Variedad de entidades** por zona
- **Memoria de peligros** para IA del agente

El jugador termina la partida sin sentir progresión ni objetivos claros más allá de coleccionar recursos.

---

## Solución propuesta

### 1. Sistema de Logros (Achievements)

**Módulo**: `Features/ArtificialWorld/Progression/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `AchievementRegistry` | `AchievementRegistry.swift` | Registro central con logros predefinidos |
| `AchievementTracker` | `AchievementTracker.swift` | Evaluación de logros según contexto |
| `AchievementDefinition` | Mismo archivo | Definición de cada logro con condición |

**Logros definidos**:
- **Progresión**: `shelter_level_2`, `shelter_level_5`
- **Combate**: `first_defeat`, `defeat_10`, `defeat_50`
- **Exploración**: `explore_forest`, `explore_mountain`
- **Recursos**: `gather_100`
- **Especial**: `legendary_first`

**Condiciones** implementadas:
- `ShelterLevelCondition`
- `EnemyDefeatsCondition`
- `ZoneExploredCondition`
- `ResourcesGatheredCondition`
- `LegendaryDropsCondition`

**UI**: Toast de notificación en escena (`showAchievementToast` en `ArtificialWorldScene+FASE5.swift:148-164`).

---

### 2. Sistema de Zonas (Zones)

**Módulo**: `Features/ArtificialWorld/World/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `WorldZone` | `WorldZone.swift` | Modelo de zona con requisitos de desbloqueo |
| `ZoneRegistry` | `ZoneRegistry.swift` | Registro y acceso a zonas |

**Modelo de zona**:
```swift
struct WorldZone {
    let id: String           // ej. "zone_home", "zone_forest"
    let name: String
    let description: String
    let requiredShelterLevel: Int
    let requiredAchievements: [String]
    let requiredItems: [String: Int]
    let requiredEnemyDefeats: Int
}
```

**Zonas predefinidas** (ejemplos):
- `zone_home` — Refugio inicial (siempre desbloqueado)
- `zone_forest` — Dark Forest (requiere nivel de refugio, logros)
- `zone_mountain` — Crystal Mountains (requiere logros de combate)

**Integración en escena**: `ArtificialWorldScene+FASE5.swift:10-31` — `canEnterZone()`, `tryEnterZone()`.

---

### 3. Sistema de Spawn de Entidades por Zona

**Módulo**: `Features/ArtificialWorld/Entities/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `EntityArchetype` | `EntityArchetype.swift` | Tipos de entidad: hostile, passive, legendary |
| `EntitySpawner` | `EntitySpawner.swift` | Spawn de entidades según zona |
| Entidades concretas | `HostileEntity.swift`, `PassiveEntity.swift`, `LegendaryEntity.swift` | Comportamientos específicos |

**Tipos de entidad**:
```swift
enum EntityKind {
    case hostile(damage: Double, patrolRadius: CGFloat)
    case passive(resourceYield: Int, respawnTime: TimeInterval)
    case legendary(uniqueDrop: String, spawnCondition: SpawnCondition)
}
```

**Spawn por zona**: El `EntitySpawner` recibe la zona actual y genera entidades apropiadas (enemigos más fuertes en zonas avanzadas, recursos específicos por bioma).

**Integración**: `ArtificialWorldScene+FASE5.swift:36-58` — `spawnEntitiesForCurrentZone()`.

---

### 4. Sistema de Defensa del Refugio

**Módulo**: `Features/ArtificialWorld/World/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `RefugeDefenseSystem` | `RefugeDefenseSystem.swift` | Sistema de patrulla y defensa |

**Funcionalidades**:
- **Patrullas**: Entidades que protegen el refugio siguiendo rutas predefinidas
- **Detección de amenazas**: Respuesta automática cuando enemigos se acercan al refugio
- **Visualización**: Renderizado de entidades de patrulla en la escena (`renderPatrolEntities()`)

**Integración**: `ArtificialWorldScene+FASE5.swift:89-120` — `updateRefugeDefense()`, `renderPatrolEntities()`.

---

### 5. Memoria de Peligros (Danger Memory)

**Módulo**: `Features/ArtificialWorld/Brain/`

| Componente | Archivo | Rol |
|------------|---------|-----|
| `DangerMemoryStore` | `DangerMemoryStore.swift` | Almacena zonas donde el jugador recibió daño |

**Funcionalidades**:
- Registrar posiciones de peligro cuando el jugador recibe daño (`recordDangerZone()`)
- Proporcionar dirección segura alejada de peligros (`safeDirectionFromDangers()`)
- Decay temporal de los peligros (se olvidan con el tiempo)

**Integración con IA**: El `WorldAgentBrain` puede usar esta memoria para evitar zonas peligrosas al planificar movimientos.

**Integración**: `ArtificialWorldScene+FASE5.swift:169-180` — `recordDangerZone()`, `safeDirectionFromDangers()`.

---

## Arquitectura y diseño técnico

### Estructura de archivos

```
Features/ArtificialWorld/
├── Progression/
│   ├── AchievementRegistry.swift    # Registro central de logros
│   └── AchievementTracker.swift     # Evaluador de logros
├── World/
│   ├── WorldZone.swift              # Modelo de zona
│   ├── ZoneRegistry.swift          # Acceso a zonas
│   └── RefugeDefenseSystem.swift   # Defensa del refugio
├── Entities/
│   ├── EntityArchetype.swift        # Definición de tipos de entidad
│   ├── EntitySpawner.swift          # Spawn por zona
│   ├── HostileEntity.swift          # Comportamiento enemigo
│   ├── PassiveEntity.swift         # Comportamiento recurso
│   └── LegendaryEntity.swift        # Comportamiento legendary
├── Brain/
│   └── DangerMemoryStore.swift      # Memoria de peligros
└── ArtificialWorldScene+FASE5.swift # Integración en escena principal
```

### Dependencias entre módulos

```
ArtificialWorldScene (Core)
    ├── ZoneRegistry.canEnterZone() → AchievementTracker.unlocked
    ├── EntitySpawner.spawnForZone() → WorldZone actual
    ├── RefugeDefenseSystem.tick()
    ├── DangerMemoryStore.addDanger()
    └── AchievementTracker.evaluate() → AchievementContext
```

### Persistencia

- **Logros**: Guardados en `ArtificialWorldSnapshot` (ya persiste en SwiftData)
- **Zonas exploradas**: Añadido a `snapshot.exploredZones` (Set<String>)
- **Estadísticas extendidas**: enemyDefeats, distanceTraveled, sessionsCompleted, legendaryDropsCollected, maxEnergyReached, maxHungerReached, totalPlayTime

### Telemetría

Eventos a registrar:

| Evento | Parámetros | Trigger |
|--------|-------------|---------|
| `zone_entered` | `{zoneId: String, fromZoneId: String?}` | Jugador entra a una zona |
| `achievement_unlocked` | `{id: String, name: String, category: String}` | Se desbloquea un logro |
| `danger_zone_recorded` | `{x: Int, y: Int, sourceEntityId: UUID?}` | Jugador recibe daño |

Todos los eventos incluyen `timestamp` y `sessionId` automáticamente por el sistema de telemetría.

### UI de Logros

El jugador accede a los logros desde el HUD del mundo artificial:

| Elemento | Ubicación | Acción |
|----------|-----------|--------|
| Botón "Trofeos" | Esquina superior derecha del HUD | Abre modal con lista de logros |
| Toast de notificación | Centro superior (temporal, 2s) | Aparece al desbloquear logro |

**Modal de logros**:
- Lista scrollable con iconos (🔒 locked / 🔓 unlocked)
- Nombre y descripción de cada logro
- Progreso visual: barra de progreso + texto (ej. "5/10 enemigos")
- Filtro por categoría: tabs en la parte superior (All, Progression, Combat, Exploration, Resources, Special)
- Animación de desbloqueo: icono brillante + sonido

### Entrada a Zonas

El jugador accede a las zonas desde la pantalla del mundo:

| Método | Descripción |
|--------|-------------|
| **Mapa zonas** | Botón en HUD que abre mini-mapa con zonas desbloqueadas |
| **Entrada visual** | Portal/arco en el borde de la pantalla que indica zona siguiente |
| **Transición automática** | Al tocar el borde del mundo, se pregunta si desea entrar a la zona adyacente |

Al intentar entrar, se validan los requisitos mediante `canEnterZone()`. Si no cumple, se muestra mensaje con qué le falta.

**UI de requisitos no cumplidos**:
- Modal pequeno con lista de requisitos pendientes
- Cada requisito muestra icono + texto (ej. "🏠 Nivel de refugio: 3 (tienes 1)")
- Botón "Cerrar" para volver al mundo

### Flujo de Cambio de Zona

1. El jugador toca la entrada a una zona (portal, mapa, o borde)
2. `tryEnterZone(zone)` valida requisitos
3. Si OK: `telemetry.logEvent("zone_entered")` + transición suave (fade 0.5s)
4. `EntitySpawner` genera nuevas entidades para la nueva zona
5. Se actualiza `snapshot.exploredZones.insert(zone.id)`
6. Se evalúan logros de exploración (`ZoneExploredCondition`)

**Notas técnicas**:
- Las entidades de la zona anterior desaparecen (no se mantienen entre zonas)
- El refugio es único y no cambia de posición entre zonas
- Los recursos recolectados se mantienen en el inventario

### Definición del Refugio

El refugio es el **centro del mundo** donde el jugador tiene protección completa:

| Propiedad | Valor |
|-----------|-------|
| Posición | Centro del `worldBounds` ( CGPoint(x: width/2, y: height/2) ) |
| Radio visual | 80pt (círculo visible en la escena) |
| Efecto | Entidades hostiles no atacan dentro del radio |
| Upgrade | `shelterLevel` mejora el radio y añade bonificaciones |

**Mejoras por nivel**:
- Nivel 1: Radio base 80pt, sin bonificaciones
- Nivel 2: Radio 100pt, regenera energía 5%/min
- Nivel 3: Radio 120pt, regenera energía 10%/min + defensa automática
- Nivel 4-5: Radio 150pt, más bonificaciones según balance

### Integración con WorldAgentBrain

El `WorldAgentBrain` usa la Danger Memory para evitar zonas peligrosas:

```swift
// En WorldAgentBrain.decideNextAction()
if let safeDir = dangerMemory?.nearestSafeDirection(from: playerPosition, worldBounds: bounds) {
    // Si hay peligro cerca, priorizar dirección segura
    return .moveTo(safeDir)
}
```

**Flujo**:
1. Cada tick, el brain consulta `safeDirectionFromDangers(at: playerPosition)`
2. Si la dirección segura es significativamente diferente del target actual, la usa
3. La prioridad es: **objetivo del jugador > evitar peligro > patrulla por defecto**

**Nota**: En modo manual, el brain solo sugiere direcciones seguras pero el jugador puede ignorarlas. En modo automático, el brain tiene control total y prioriza seguridad sobre el objetivo si hay peligro cercano.

### Estrategia de Testing

| Tipo de test | Cobertura | Herramienta |
|--------------|-----------|-------------|
| **Unit tests** | Lógica de condiciones de logros, validación de zonas, entity behavior | Xcode Test (XCTest) |
| **Integration tests** | Persistencia SwiftData de logros y zonas, HUD → modal | XCTest + mock de SwiftData |
| **UI tests** | Navegación a logros, entrada a zonas, toast de notificación | Xcode UI Tests |

**Coverage objetivo**: 80%+ en lógica de reglas de negocio (AchievementConditions, ZoneRegistry, EntitySpawner).

### Modos de Control del Jugador

El sistema soporta tres modos de interacción:

| Modo | Descripción | Uso de Danger Memory |
|------|-------------|---------------------|
| **Manual** | El jugador controla el movimiento directamente | Solo sugiere direcciones seguras (toast: "Peligro detectado →") |
| **Automático** | El brain controla el movimiento | Prioriza seguridad sobre objetivo cuando hay peligro |
| **Híbrido** | El jugador toca para moverse, brain interviene en peligros | Igual que automático pero con input del jugador |

**Cambio de modo**: Botón en HUD o según configuración en `AppLaunchPreferences`.

### Actualización del Shelter Level

El nivel del refugio (`shelterLevel`) se mejora mediante recursos:

| Nivel requerido | Recursos necesarios |
|-----------------|---------------------|
| 1 → 2 | 50 recursos + 10 minutos de juego |
| 2 → 3 | 100 recursos + logros de combate (1 minimum) |
| 3 → 4 | 200 recursos + explorar zona forest |
| 4 → 5 | 300 recursos + defeats de enemigos (10 minimum) |

**UI de mejora**: Al tocar el refugio, se muestra modal con botón "Mejorar" (si cumple requisitos) o lista de lo que falta.

### Parámetros de Configuración

Valores ajustables vía `GameConfig` (no hardcodeados):

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `maxEntitiesPerZone` | 20 | Máximo de entidades activas por zona |
| `maxDangerMemoryPositions` | 50 | Máximo de posiciones almacenadas en memoria de peligros |
| `dangerDecaySeconds` | 300 | Tiempo en segundos para que un peligro expire (5 min) |
| `achievementCheckIntervalSeconds` | 30 | Frecuencia de evaluación periódica de logros |
| `entityRespawnTimeBase` | 60 | Tiempo base de respawn de recursos en segundos |

---

## Scope no incluido en esta fase

- **Sincronización cloud** de progreso (API stubs ya existen en `Networking/WorldSyncProtocols.swift`)
- **Nuevas zonas geográficas** más allá de los ejemplos (forest, mountain)
- **Quests/Misiones** específicas por zona
- **Tienda de logros** (canje de logros por recompensas)

---

## Métricas de éxito

1. **Al menos 3 logros desbloqueables** en una partida típica (30 min de juego)
2. **Sistema de zonas funcional** con al menos 3 zonas (home, forest, mountain)
3. **Entidades diferenciadas** por zona con comportamientos distintos
4. **Defensa del refugio** visible y funcional
5. **Danger memory** integrada con el agente (el agente evita zonas peligrosas)
6. **Build exitoso** en Xcode y tests pasando

---

## Risks identificados

| Risk | Impacto | Mitigación |
|------|---------|------------|
| Complejidad de entidades slowing el game loop | Alto | Entidades limitadas por zona; máximo 20 activas |
| Memoria de peligros ocupando mucha RAM | Medio | Decay automático; máximo 50 posiciones almacenadas |
| Logros no guardados correctamente | Alto | Tests de integración con SwiftData |
| Balance de spawn demasiado difícil/fácil | Medio | Ajustar parámetros vía GameConfig (no hardcodeado) |

---

## Timeline estimado

| Fase | Descripción | Estimación |
|------|-------------|-------------|
| 1 | Registro de logros y contexto | 2-3 días |
| 2 | Sistema de zonas y registry | 2 días |
| 3 | Entity spawner por zona | 2-3 días |
| 4 | Refuge defense system | 1-2 días |
| 5 | Danger memory + integración con brain | 2 días |
| 6 | UI de logros y tests | 1-2 días |
| **Total** | | **10-14 días** |

---

## User Flows

### Flow 1: Ver Logros

```
Jugador está en ArtificialWorldScene
    │
    ▼
Toca botón "Trofeos" en HUD
    │
    ▼
Se abre modal de logros (SKNode overlay)
    │
    ├── Ve lista de logros con estado (locked/unlocked)
    ├── Toca un logro → muestra detalle
    └── Toca fuera del modal → cierra
    │
    ▼
Vuelve a la escena
```

### Flow 2: Entrar a una Zona

```
Jugador está en zona actual (ej. zone_home)
    │
    ├── Opción A: Ve portal en el borde de la pantalla
    ├── Opción B: Toca botón "Mapa" en HUD
    └── Opción C: Toca el borde del mundo
    │
    ▼
Intenta entrar a nueva zona
    │
    ├── SI cumple requisitos: 
    │   ├── telemetry.logEvent("zone_entered")
    │   ├── transición fade 0.5s
    │   ├── spawn de nuevas entidades
    │   └── se actualiza exploredZones
    │
    └── NO cumple requisitos:
        ├── showBriefStatus("Zona bloqueada: requisitos no cumplidos")
        └── muestra qué le falta (nivel refugio, logros, etc.)
```

### Flow 3: Desbloquear Logro

```
Jugador realiza acción en el mundo
    │
    ▼
ArtificialWorldScene.evaluateAchievements()
    │
    ├── Genera AchievementContext con stats actuales
    ├── AchievementTracker.evaluate(context:)
    └── Comparar con condiciones definidas
    │
    ├── SI se desbloquea nuevo logro:
    │   ├── showAchievementToast(achievement)
    │   ├── telemetry.logEvent("achievement_unlocked")
    │   └── se guarda en snapshot
    │
    └── NO → no hace nada
```

**Frecuencia de evaluación**:
- **Acciones específicas**: cada vez que el jugador derrota un enemigo, recolecta un recurso, o entra a una zona
- **Tick periódico**: cada 30 segundos para logros de tiempo (shelter level progress, play time)
- **Al cargar**: al iniciar una sesión del mundo se evaluan logros por si hay progreso guardado

### Flow 4: Agente Evita Peligros

```
WorldAgentBrain decide próximo movimiento
    │
    ▼
Consulta dangerMemory.nearestSafeDirection(from:)
    │
    ├── SI hay peligro cercano (radio < 100pt):
    │   └── Si está en modo automático, prioriza dirección segura
    │   Si está en modo manual, sugiere dirección al jugador
    │
    └── NO hay peligro → usa target original (objetivo del jugador)
    │
    ▼
Ejecuta movimiento (prioridad: objetivo del jugador > evitar peligro > patrulla)
```

---

## Glosario

| Término | Definición |
|---------|-------------|
| **Shelter / Refugio** | Zona central del mundo donde el jugador está protegido de entidades hostiles. Tiene un nivel (`shelterLevel`) que mejora con el progreso. |
| **Zona / Zone** | Área del mundo con requisitos de desbloqueo y entidades específicas. Cada zona tiene su propio bioma y dificultad. |
| **Entidad (Entity)** | Objeto en el mundo: enemigo (hostile), recurso (passive), o especial (legendary). |
| **Despawn** | Proceso por el cual una entidad deja de existir en la escena (por muerte, recolección, o cambio de zona). |
| **Tick** | Ciclo de actualización del juego (típicamente 60 veces por segundo). El brain y las entidades se actualizan en cada tick. |
| **Achievement / Logro** | Meta desbloqueable por el jugador al cumplir condiciones específicas. |
| **Snapshot** | Estado persistido del mundo artificial en SwiftData (inventario, stats, progreso). |

---

## Doc. relacionada

- `docs/ARTIFICIAL_WORLD_FASE0.md` — Documentación original del modo
- `CHANGELOG.md` — Historial de versiones (se actualizará en release)