# Fix RITMINITY Game Engine Root Architecture

Este documento detalla los problemas de raíz (arquitectura y lógica) encontrados en RITMINITY que causan los errores e inestabilidad (especialmente los problemas del menú, botones y los crashes en generación de mapas por audio).

## User Review Required
> [!IMPORTANT]
> El proyecto tiene varios problemas de arquitectura que rompen el ciclo de actualización (`update`) y el manejo de eventos en el estado activo. Por favor revisa los hallazgos y el plan de corrección antes de continuar.

## Problemas de Raíz Detectados y Por Qué Causan Errores

1. **Bug Crítico de Input y UI (Limpieza Prematura del Input)**
   - **Problema:** En `main.lua`, dentro de `love.update(dt)`, el método `InputManager:update(dt)` se llama *antes* que `StateManager.current:update(dt)`. `InputManager:update` vacía (`clearFrameState()`) las tablas de `keysPressed`, `keysReleased` y botones del ratón. 
   - **Efecto:** Cualquier lógica dentro de los estados (como `Gameplay` o los menús) que intente usar `InputManager:isPressed(key)` dentro del método `update()` SIEMPRE recibirá `false`, porque el manager fue borrado en ese mismo frame. Esto rompe parte de la detección de botones y mecánicas dependientes del frame.

2. **Corte en el Flujo de Input hacia la Acción (`keyreleased` no enlazado)**
   - **Problema:** `main.lua` recibe los eventos de Love2D y los pasa al `StateManager.current`. Sin embargo, pasa `love.keypressed` pero **OMITE** pasar `love.keyreleased` al estado actual.
   - **Efecto:** La pantalla de `Gameplay` intenta manejar las teclas sueltas para las Hold Notes en `Gameplay:handleInput` usando `InputManager:isReleased(key)`. Pero como `handleInput` nunca es llamado durante un evento *release*, las teclas sueltas jamás se registran, rompiendo por completo las Hold Notes y la estabilidad de las puntuaciones.

3. **Crash Crítico por Audio (Audio-driven Chart Generation Error)**
   - **Problema:** Cuando el jugador selecciona un archivo de audio para que la IA genere el mapa, la ruta que se pasa a `AIGenerator` es relativa (ej. `assets/songs/song.mp3`). El generador crea el chart pero **corta** la ruta, guardando solo `"song.mp3"` en `chart.metadata.audioFile`.
   - **Efecto:** Cuando la pantalla de `Gameplay` intenta cargar el audio con `AudioManager:loadMusic(self.chart.audioFile)`, Love2D lanza un Fatal Error y crashea porque `"song.mp3"` no existe en la raíz del proyecto.

4. **Variables y Funciones Duplicadas/Manejadas Incorrectamente**
   - **Problema:** En `src/audio/manager.lua`, la función `AudioManager:update(dt)` está declarada dos veces, la segunda sobrescribe a la primera y ambas intentan sincronizar.
   - **Problema:** El manejo de coordenadas del mouse en `MainMenu` asume resolución fija pero el escalado a pantalla completa puede no mapear correctamente a los botones de 440x840 si hay variables globales mal controladas.

5. **Mal uso de Módulos (Require devolviendo valores inesperados o problemas de tablas)**
   - Revisaremos si hay llamadas `require` que devuelven `boolean` o valores no deseados durante el recorrido, limpiando cualquier dependencia que no devuelva la tabla del módulo.

## Proposed Changes

### Core & Base Systems

#### [MODIFY] [main.lua](file:///c:/Users/Vino/Downloads/ritminity/ritminity/main.lua)
- Mover `InputManager:update(dt)` al final de la función `love.update(dt)`, para que todos los sistemas y managers procesen los inputs del frame actual antes de ser limpiados.
- Añadir la llamada a `StateManager.current:keyreleased(...)` (o a través de `handleInput` pasando el tipo de evento) dentro de `love.keyreleased` para habilitar el flujo completo de teclas soltadas hacia los estados.

### Audio & AI Systems

#### [MODIFY] [src/ai/generator.lua](file:///c:/Users/Vino/Downloads/ritminity/ritminity/src/ai/generator.lua)
- Corregir `AIChartGenerator:generateFromAudio` para que no destruya la ruta del archivo de audio, asignando la ruta relativa original a `chart.metadata.audioFile`, evitando el crash al transicionar al `Gameplay`.

#### [MODIFY] [src/audio/manager.lua](file:///c:/Users/Vino/Downloads/ritminity/ritminity/src/audio/manager.lua)
- Eliminar la declaración duplicada de `AudioManager:update(dt)` y consolidar su lógica de sincronización.

### Input & UI Systems

#### [MODIFY] [src/gameplay/gameplay.lua](file:///c:/Users/Vino/Downloads/ritminity/ritminity/src/ui/screens/gameplay.lua)
- Modificar `Gameplay:handleInput` (y añadir un manejador `keyreleased`) para procesar correctamente las teclas mantenidas, solucionando la lógica subyacente.

## Verification Plan

### Manual Verification
1. Ejecutar el juego con `love .`.
2. Probar la navegación del `MainMenu` asegurándose de que todos los botones funcionen al clickear y por teclado.
3. Iniciar un mapa autogenerado para confirmar que no ocurre un crash ("audio-driven chart generation error").
4. Jugar una canción para verificar que los botones de presionar (`keypressed`) y soltar (`keyreleased`) registran la puntuación correctamente.
