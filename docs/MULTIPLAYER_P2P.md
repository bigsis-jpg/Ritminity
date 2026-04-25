# Sistema Multijugador Peer-to-Peer (P2P)

RITMINITY está diseñado con la ambición de soportar juego en línea utilizando topología P2P (Peer-to-Peer).

## Arquitectura de Red Propuesta

1. **Servidor de Señalización (Matchmaking Server):**
   - Un pequeño servidor Node.js o Go encargado únicamente de "presentar" a los clientes a través de WebRTC.
   - Permite salas, listas de espera y descubrimiento.

2. **Conexión Directa:**
   - Una vez los clientes obtienen las IPs, intercambian datagramas UDP (utilizando el módulo `lua-enet` o análogos nativos).
   - Minimiza la latencia para juegos de ritmo estrictos.

## Sincronización de Partida

Dado que los juegos de ritmo dependen críticamente del tiempo:
- La música inicia de forma sincronizada tras un cálculo de RTT (Round Trip Time) y corrección de NTP.
- Durante el juego, los clientes NO envían su estado al otro constantemente.
- Solamente transmiten eventos de **Score/Combo Update** cada ~100ms para actualizar las barras de progreso rivales.
- El juego es determinista; ambos tienen el mismo mapa, las notas caen igual.

## Mock Actual

Actualmente, el sistema en `src/ui/screens/multiplayer.lua` implementa un Mock UI simulando salas de espera para que la base de interfaces esté preparada.
