/// Vacances scolaires françaises — Zone B (Île-de-France) par défaut
/// Années 2025-2026 et 2026-2027
class SchoolHolidays {
  SchoolHolidays._();

  /// Liste des périodes de vacances scolaires (début inclusif, fin inclusif)
  static final List<_HolidayPeriod> _periods = [
    // 2025-2026
    _HolidayPeriod('Toussaint 2025',     DateTime.utc(2025, 10, 18), DateTime.utc(2025, 11, 3)),
    _HolidayPeriod('Noël 2025',          DateTime.utc(2025, 12, 20), DateTime.utc(2026, 1,  5)),
    _HolidayPeriod('Hiver 2026',         DateTime.utc(2026, 2,  14), DateTime.utc(2026, 3,  2)),
    _HolidayPeriod('Printemps 2026',     DateTime.utc(2026, 4,  11), DateTime.utc(2026, 4, 27)),
    _HolidayPeriod('Été 2026',           DateTime.utc(2026, 7,   4), DateTime.utc(2026, 8, 31)),
    // 2026-2027
    _HolidayPeriod('Toussaint 2026',     DateTime.utc(2026, 10, 17), DateTime.utc(2026, 11, 2)),
    _HolidayPeriod('Noël 2026',          DateTime.utc(2026, 12, 19), DateTime.utc(2027, 1,  4)),
    _HolidayPeriod('Hiver 2027',         DateTime.utc(2027, 2,  13), DateTime.utc(2027, 3,  1)),
    _HolidayPeriod('Printemps 2027',     DateTime.utc(2027, 4,  10), DateTime.utc(2027, 4, 26)),
    _HolidayPeriod('Été 2027',           DateTime.utc(2027, 7,   3), DateTime.utc(2027, 8, 31)),
  ];

  /// Vérifie si un jour donné est en période de vacances scolaires
  static bool isHoliday(DateTime day) {
    final d = DateTime.utc(day.year, day.month, day.day);
    for (final p in _periods) {
      if (!d.isBefore(p.start) && !d.isAfter(p.end)) return true;
    }
    return false;
  }

  /// Retourne le nom de la période si le jour est en vacances, sinon null
  static String? periodName(DateTime day) {
    final d = DateTime.utc(day.year, day.month, day.day);
    for (final p in _periods) {
      if (!d.isBefore(p.start) && !d.isAfter(p.end)) return p.name;
    }
    return null;
  }
}

class _HolidayPeriod {
  final String name;
  final DateTime start;
  final DateTime end;
  _HolidayPeriod(this.name, this.start, this.end);
}
