# Artificial World — FASE5: Entidades, Zonas y Logros

**Estado**: Implementado ✅  
**Fecha**: 2026-03-22

---

## Resumen

FASE5 expande el Artificial World MVP con:
- **Entidades expandidas**: 3 arquetipos (hostiles, pasivas, legendarias)
- **Sistema de zonas**: Progresión con desbloqueo por requisitos
- **Defensa de refugio**: Patrullas que spawn cuando el jugador sale
- **Memoria del agente**: Zonas de peligro persistentes
- **Sistema de logros**: 9 logros con condiciones

---

## Arquitectura

### Entidades (`Features/ArtificialWorld/Entities/`)

```
EntityArchetype.swift     — Struct Entity + EntityKind enum
HostileEntity.swift      — HostileEntityFactory
PassiveEntity.swift       — PassiveEntityFactory + ResourceType
LegendaryEntity.swift     — LegendaryEntityFactory + LegendaryDrop
EntitySpawner.swift      — Factory por zona
```

### Zonas (`Features/ArtificialWorld/World/`)

```
WorldZone.swift           — ZoneUnlockRequirement + WorldZone
ZoneRegistry.swift        — Registro de zonas + progresión
RefugeDefenseSystem.swift — Patrullas de defensa
```

### Progresión (`Features/ArtificialWorld/Progression/`)

```
AchievementRegistry.swift  — 9 logros con condiciones
AchievementTracker.swift  — Evaluación + notificaciones
```

### Memoria (`Features/ArtificialWorld/Brain/`)

```
DangerMemoryStore.swift    — Zonas de peligro + decaimiento
```

---

## Zonas Implementadas

| ID | Nombre | Requisitos |
|----|--------|------------|
| `zone_home` | Home Territory | Ninguno (default) |
| `zone_forest` | Dark Forest | Shelter nivel 2 |
| `zone_mountain` | Crystal Mountains | Shelter nivel 3 + 10 defeats |
| `zone_ruins` | Ancient Ruins | Shelter nivel 5 |

---

## Logros Implementados

| ID | Nombre | Categoría | Condición |
|----|--------|-----------|------------|
| `shelter_level_2` | Home Improvement | Progression | Shelter nivel 2 |
| `shelter_level_5` | Fortress | Progression | Shelter nivel 5 |
| `first_defeat` | Hunter | Combat | 1 enemigo |
| `defeat_10` | Veteran | Combat | 10 enemigos |
| `defeat_50` | Champion | Combat | 50 enemigos |
| `explore_forest` | Forest Walker | Exploration | Entrar zona forest |
| `explore_mountain` | Mountain Climber | Exploration | Entrar zona mountain |
| `gather_100` | Gatherer | Resources | 100 recursos |
| `legendary_first` | Lucky Find | Special | 1 legendary drop |

---

## Decisiones Técnicas

### Patrol Enemies
- **No persisten** entre sesiones (reset en reload)
- Spawn interval: 10 segundos
- Max patrols: 3
- Daño: 10 por hit

### Legendary Drops
- **Van como bonus arcade** (monedas en GameOverScene)
- Drop values: 500 / 1000 / 2000 monedas

### Notificaciones
- **Toast in-game** con SKLabelNode
- No notificaciones del sistema

---

## Próximas Fases

### FASE6: Backend Sync
- Integración real de protocolos stubs existentes
- Persistencia en servidor
- Sincronización multi-dispositivo

### FASE7: Multiplayer/Passive World
- Evolución pasiva del mundo
- Estados compartidos entre jugadores

---

## Archivos Modificados

| Archivo | Cambios |
|---------|---------|
| `Persistence/ArtificialWorldSwiftDataModels.swift` | zoneUnlockFlagsData, dangerZonesData, PersistedAchievement, PersistedZoneState |
| `ArtificialWorldScene.swift` | +extensión FASE5 |

## Archivos Nuevos

16 archivos en `Features/ArtificialWorld/` + tests

---

## Testing

Tests unitarios en `ArtificialWorldFASE5Tests.swift`:
- EntityTests
- DangerMemoryStoreTests
- ZoneUnlockTests
- AchievementTests
- ZoneRegistryTests
- RefugeDefenseTests
