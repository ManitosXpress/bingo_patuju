import '../models/bingo_game_config.dart';

/// Obtiene el nombre de visualización de un patrón de bingo
String getBingoPatternDisplayName(BingoPattern pattern) {
  switch (pattern) {
    case BingoPattern.diagonalPrincipal:
      return 'Diagonal Principal';
    case BingoPattern.diagonalSecundaria:
      return 'Diagonal Secundaria';
    case BingoPattern.lineaHorizontal:
      return 'Línea Horizontal';
    case BingoPattern.lineaVertical:
      return 'Línea Vertical';
    case BingoPattern.marcoCompleto:
      return 'Marco Completo';
    case BingoPattern.marcoPequeno:
      return 'Marco Pequeño';
    case BingoPattern.spoutnik:
      return 'Spoutnik';
    case BingoPattern.corazon:
      return 'Corazón';
    case BingoPattern.cartonLleno:
      return 'Cartón Lleno';
    case BingoPattern.consuelo:
      return 'Consuelo';
    case BingoPattern.x:
      return 'X';
    case BingoPattern.figuraAvion:
      return 'Figura Avión';
    case BingoPattern.caidaNieve:
      return 'Caída de Nieve';
    case BingoPattern.arbolFlecha:
      return 'Árbol o Flecha';
    case BingoPattern.letraI:
      return 'LETRA I';
    case BingoPattern.letraN:
      return 'LETRA N';
    case BingoPattern.autopista:
      return 'Autopista';
    case BingoPattern.relojArena:
      return 'Reloj de Arena';
    case BingoPattern.dobleLineaV:
      return 'Doble Línea V';
    case BingoPattern.figuraSuegra:
      return 'Figura la Suegra';
    case BingoPattern.figuraComodin:
      return 'Figura Infinito';
    case BingoPattern.letraFE:
      return 'Letra FE';
    case BingoPattern.figuraCLoca:
      return 'Figura C Loca';
    case BingoPattern.figuraBandera:
      return 'Figura Bandera';
    case BingoPattern.figuraTripleLinea:
      return 'Figura Triple Línea';
    case BingoPattern.diagonalDerecha:
      return 'Diagonal Derecha';
  }
}
