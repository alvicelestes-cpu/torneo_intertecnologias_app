import '../constants/app_colors.dart';
import '../../models/jugador.dart';

/// Comparador centralizado para ordenar jugadores según especificaciones del torneo:
/// 1. Prioridad por grupo de edad:
///    - Mayores de 40 (1)
///    - Entre 35 y 39 (2)
///    - De 18 a 34 (3)
///    - Edad no disponible (4)
/// 2. Dentro de cada grupo: edad DESCENDENTE (de mayor a menor edad)
/// 3. Empate en edad: fecha de nacimiento desde la más antigua a la más reciente (nació antes primero)
/// 4. Empate persistente: nombre alfabético
int compareJugadoresPorEdad(Jugador a, Jugador b) {
  // 1. Grupo de edad
  final orderA = getAgeGroupOrder(a.edad);
  final orderB = getAgeGroupOrder(b.edad);
  if (orderA != orderB) {
    return orderA.compareTo(orderB);
  }

  // 2. Dentro del grupo: edad DESCENDENTE
  final edadA = a.edad;
  final edadB = b.edad;
  if (edadA != null && edadB != null) {
    if (edadA != edadB) {
      return edadB.compareTo(edadA); // Ej: 48 antes que 45
    }
  } else if (edadA != null) {
    return -1;
  } else if (edadB != null) {
    return 1;
  }

  // 3. Empate en edad: fecha de nacimiento desde el más antiguo al más reciente
  final fechaA = a.fechaNacimiento?.trim();
  final fechaB = b.fechaNacimiento?.trim();
  if (fechaA != null && fechaA.isNotEmpty && fechaB != null && fechaB.isNotEmpty) {
    final dtA = DateTime.tryParse(fechaA);
    final dtB = DateTime.tryParse(fechaB);
    if (dtA != null && dtB != null) {
      final cmpFecha = dtA.compareTo(dtB);
      if (cmpFecha != 0) return cmpFecha;
    } else {
      final cmpStr = fechaA.compareTo(fechaB);
      if (cmpStr != 0) return cmpStr;
    }
  } else if (fechaA != null && fechaA.isNotEmpty) {
    return -1;
  } else if (fechaB != null && fechaB.isNotEmpty) {
    return 1;
  }

  // 4. Empate: nombre alfabético
  return a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase());
}

/// Agrupa los jugadores en los cuatro grupos de edad y ordena cada grupo de forma descendente.
Map<AgeGroup, List<Jugador>> groupJugadoresPorEdad(List<Jugador> jugadores) {
  final Map<AgeGroup, List<Jugador>> grupos = {
    AgeGroup.over40: [],
    AgeGroup.between35And39: [],
    AgeGroup.between18And34: [],
    AgeGroup.unknown: [],
  };

  for (final j in jugadores) {
    final group = getAgeGroup(j.edad);
    grupos[group]!.add(j);
  }

  for (final entry in grupos.entries) {
    entry.value.sort(compareJugadoresPorEdad);
  }

  return grupos;
}

/// Determina si un torneo requiere agrupación/categorías visuales por edad según su id o slug.
/// Únicamente el Torneo Banquita Los Altos actual (ID 2 o slug exacto 'torneo-demo') NO tiene categorías de edad (retorna false).
/// Todos los demás torneos (incluyendo Torneo Intertecnologías ID 1 o futuros torneos con nombres similares) manejan categorías de edad por defecto (retorna true).
bool torneoTieneCategoriasEdad({int? id, String? slug, String? nombre}) {
  if (id == 2) return false;
  if (slug != null) {
    final s = slug.toLowerCase().trim();
    if (s == 'torneo-demo') return false;
  }
  return true;
}


/// Ordena jugadores para torneos sin categorías por edad (ej. Torneo Banquita Los Altos):
/// 1. Por número de camiseta (dorsal) ascendente.
/// 2. Jugadores sin dorsal van al final.
/// 3. Empate en dorsal o sin dorsal: nombre alfabético.
List<Jugador> sortJugadoresSinCategorias(List<Jugador> jugadores) {
  final copy = List<Jugador>.from(jugadores);
  copy.sort((a, b) {
    final numA = a.numeroCamiseta;
    final numB = b.numeroCamiseta;
    if (numA != null && numB != null) {
      final cmp = numA.compareTo(numB);
      if (cmp != 0) return cmp;
    } else if (numA != null) {
      return -1;
    } else if (numB != null) {
      return 1;
    }
    return a.nombreCompleto.toLowerCase().compareTo(b.nombreCompleto.toLowerCase());
  });
  return copy;
}
