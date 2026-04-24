# Ritminity

**Ritminity** es un videojuego de ritmo profesional desarrollado sobre el motor [LÖVE (Love2D)](https://love2d.org/).

## Características

- Motor de juego escrito en Lua usando Love2D.
- Diferentes estados de juego integrados: Menú Principal, Selección de Canciones, Gameplay, Resultados, Editor y Multijugador.
- Sistemas modulares para Audio, Renderizado, Entrada, Redes, y Recursos.
- Soporte para perfiles de usuario, puntuaciones, combos y modificadores de juego.
- Soporte para joystick y teclado.

## Estructura del Proyecto

El proyecto está estructurado de forma modular:

- `main.lua`: Punto de entrada principal de la aplicación.
- `conf.lua`: Archivo de configuración global.
- `src/`: Código fuente principal estructurado en submódulos:
  - `core/`: Sistemas base (Eventos, Logger, Gestor de Estados, Gestor de Recursos).
  - `input/`: Manejo de entradas (teclado, ratón y joystick).
  - `audio/`: Gestor de reproducción de música y efectos de sonido.
  - `render/`: Sistemas de dibujo y gráficos.
  - `network/`: Funcionalidades de red y multijugador.
  - `ui/`: Interfaz de usuario y pantallas del juego (menús, editor, autenticación).
- `assets/`: Recursos gráficos y sonoros del juego.

## Requisitos Previos

Para ejecutar Ritminity, necesitas instalar el motor **LÖVE**.

- Descarga LÖVE: [https://love2d.org/](https://love2d.org/) (Versión recomendada: 11.4 o superior).

## Cómo Ejecutar

### En Windows
1. Instala LÖVE.
2. Arrastra la carpeta de código principal de `ritminity` sobre el acceso directo de `love.exe`.
3. Alternativamente, puedes ejecutar desde la línea de comandos en el directorio del proyecto:
   ```cmd
   love .
   ```

### En Linux / macOS
Navega a la carpeta principal del proyecto a través de la terminal y ejecuta:
```bash
love .
```

## Controles Generales

- `F11`: Alternar modo de pantalla completa.
- `F12`: Tomar captura de pantalla (se guardará como `ritminity_screenshot_[timestamp].png`).
- `Esc`: Volver atrás o pausar.

## Autores
- Ritminity Team

## Licencia
Consulta el archivo `LICENSE` incluido en el proyecto para conocer los detalles.
