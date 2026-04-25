# Arquitectura RITMINITY

RITMINITY sigue un patrón de diseño orientado a componentes y estados, diseñado para ser modular y mantenible, inspirado en estándares de juegos AAA desarrollados con Love2D.

## Estructura de Directorios

- `src/core/`: Manejo de bucles principales, eventos, recursos y estados (EventSystem, StateManager).
- `src/managers/`: Singletons globales que administran Input, Audio, Redes y Renderizado.
- `src/gameplay/`: El corazón del juego.
  - `engine/`: `engine.lua` procesa la lógica en tiempo real. `scoring.lua` maneja métricas de MS y combos.
  - `systems/`: Sistemas independientes que inyectan comportamiento.
  - `mods/`: Modificadores de juego (DoubleTime, Easy, etc).
  - `replay/`: Grabación y reproducción de keystrokes.
- `src/ui/`: Componentes de interfaz gráfica de usuario.
  - `core/`: Primitivas reutilizables como `Button.lua`.
  - `screens/`: Estados principales (MainMenu, Gameplay, Results, etc).
- `src/loaders/`: Parseadores de mapas (`.osu`, `.sm`, `.json`).
- `src/net/`: Sistemas asíncronos y descargas de red (Mock Downloader).

## Flujo de Datos

1. `love.load` inicializa el `StateManager` y registra las pantallas.
2. `InputManager` intercepta pulsaciones de teclas y clics, emitiendo eventos al sistema y al estado activo actual.
3. En la fase de `Gameplay`, el `Engine` sincroniza los eventos de nota utilizando el tiempo de audio maestro (`Audio-driven time`) y evalúa el hit basándose en la latencia de MS exactos.
4. El `ScoringSystem` suma puntuación y vida, pasando el control final a la pantalla de `Results` al acabar la pista.
