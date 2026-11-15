const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "Sat 14 Nov".
String shortDate(DateTime t) =>
    '${_weekdays[t.weekday - 1]} ${t.day} ${_months[t.month - 1]}';

/// Midnight at the start of [t]'s day.
DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

/// Midnight on the Monday of [t]'s week.
DateTime startOfWeek(DateTime t) =>
    startOfDay(t).subtract(Duration(days: t.weekday - 1));
