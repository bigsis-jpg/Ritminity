# Configuración de RITMINITY para Web

RITMINITY está preparado para ser portado a la web utilizando [Love.js](https://github.com/Davidobot/love.js).

## Requisitos previos

1. Tener Node.js instalado.
2. Instalar love.js globalmente a través de npm:
   ```bash
   npm install -g love.js
   ```

## Compilación paso a paso

1. Empaqueta el juego en un archivo `.love` (Un archivo `.zip` renombrado a `.love` que contiene la raíz de los archivos `main.lua`, `src/`, `assets/`, etc.).
   ```bash
   # Comando asumiendo bash/linux
   zip -9 -r ritminity.love . -i "main.lua" "conf.lua" "src/*" "assets/*"
   ```

2. Ejecuta el compilador web:
   ```bash
   love.js ritminity.love build/web -c -t RITMINITY
   ```

3. Aloja la carpeta `build/web` en cualquier servidor estático local o remoto. (ej: Vercel, Netlify o GitHub Pages).

## Consideraciones Web

- La carga asíncrona de archivos o base de datos de SQLite (si se integran luego) requerirá un VFS (Virtual File System) compatible con Love.js.
- Se recomienda limitar la calidad de audio a formato `OGG` para menor tamaño de descarga en red.
