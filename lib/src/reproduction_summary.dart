import 'models.dart';

String getReproductionSummaryFromEvents(List<BugEvent> events) {
  final parts = <String>[];

  for (final e in events) {
    switch (e.type) {
      case 'nav':
        final from = e.data['from'] as String?;
        final to = e.data['to'] as String? ?? '';
        if (parts.isEmpty && to.isNotEmpty) {
          parts.add('Started on ${to.isEmpty ? "/" : to}.');
        } else if (to.isNotEmpty) {
          parts.add('Navigated ${from ?? "?"} → $to.');
        }
        break;
      case 'breadcrumb':
        final action = e.data['action'] as String? ?? 'tap';
        final target = e.data['target'] as String? ?? '';
        if (target.isNotEmpty) {
          parts.add('${action == 'click' ? 'Clicked' : 'Tapped'} $target.');
        } else {
          parts.add('${action == 'click' ? 'Clicked' : 'Tapped'}.');
        }
        break;
      case 'err':
        final message = e.data['message'] as String? ?? 'Error';
        parts.add('Error: $message');
        break;
      default:
        break;
    }
  }

  if (parts.isEmpty) return 'No reproduction steps recorded.';
  return parts.join(' ');
}
