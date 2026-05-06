// NO hi ha dependencies noves de Flutter.
//
// ## QUÈ FA I PER A QUÈ SERVEIX
// Classe AppCapabilities: converteix la llista de PermisTreballador del backend
// en booleans d'UI. És l'únic lloc on s'interpreta la semàntica dels permisos.
// Llegida per TreballadorMainScaffold i passada als subwidgets via constructor.
//
// Convenció de clau_funcional (cal sembrar a la taula `permis`):
//   tasques.completar    → canCompleteTask
//   incidencies.crear    → canReportIncidencia
//   horari.registrar     → canRegisterHorari
//   recursos.sol_licitar → canRequestResources
//
// Fallback: si la llista de permisos és buida (treballador sense configurar)
// s'usa AppCapabilities.workerDefaults() → accions bàsiques habilitades.
//
// Per a: treballador autenticat.
// Usat per: TreballadorMainScaffold, TreballadorTasquesScreen.
// Conversió a TascaProfileCapabilities: es fa al call site per no crear
// dependència cross-domain des de shared/.

class AppCapabilities {
  final bool canCompleteTask;
  final bool canReportIncidencia;
  final bool canRegisterHorari;
  final bool canRequestResources;

  const AppCapabilities({
    required this.canCompleteTask,
    required this.canReportIncidencia,
    required this.canRegisterHorari,
    required this.canRequestResources,
  });

  /// Valors per defecte quan el treballador no té permisos configurats.
  /// Habilita accions bàsiques d'execució (completar tasca, reportar incidència,
  /// registrar horari) però bloqueja accions avançades (sol·licitar recursos).
  const AppCapabilities.workerDefaults()
      : canCompleteTask = true,
        canReportIncidencia = true,
        canRegisterHorari = true,
        canRequestResources = false;

  /// Construeix les capacitats a partir de la llista de PermisTreballador
  /// retornada per GET /treballadors/me/permisos/.
  ///
  /// Cada element té l'estructura:
  /// { "id": 1, "lectura": true, "escriptura": false, "edicio": false,
  ///   "permis_info": { "clau_funcional": "tasques.completar", "descripcio": "..." } }
  ///
  /// Un permís activa la capacitat corresponent si `escriptura == true`.
  factory AppCapabilities.fromPermisos(List<Map<String, dynamic>> permisos) {
    if (permisos.isEmpty) return const AppCapabilities.workerDefaults();

    bool check(String clauFuncional) {
      for (final p in permisos) {
        final info = p['permis_info'];
        if (info is! Map<String, dynamic>) continue;
        if (info['clau_funcional'] != clauFuncional) continue;
        return p['escriptura'] == true;
      }
      return false;
    }

    return AppCapabilities(
      canCompleteTask: check('tasques.completar'),
      canReportIncidencia: check('incidencies.crear'),
      canRegisterHorari: check('horari.registrar'),
      canRequestResources: check('recursos.sol_licitar'),
    );
  }
}
