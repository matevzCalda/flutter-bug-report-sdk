class RedactionConfig {
  final bool dropQuery;
  final List<String> queryAllowlist;
  final List<String> queryBlocklist;

  final List<Pattern> urlBlocklist;
  final List<Pattern> keyBlocklist;
  final List<Pattern> valuePatterns;

  final String replacement;

  const RedactionConfig({
    this.dropQuery = true,
    this.queryAllowlist = const [],
    this.queryBlocklist = const [
      'token',
      'auth',
      'password',
      'code',
      'session',
      'jwt',
    ],
    this.urlBlocklist = const [],
    this.keyBlocklist = const [
      'authorization',
      'cookie',
      'set-cookie',
      'password',
      'secret',
      'token',
    ],
    this.valuePatterns = const [],
    this.replacement = '[REDACTED]',
  });
}

Map<String, Object?> redactMap(
  Map<String, Object?> input,
  RedactionConfig cfg,
) {
  final out = <String, Object?>{};
  input.forEach((key, value) {
    if (_matchesAny(key, cfg.keyBlocklist)) {
      out[key] = cfg.replacement;
    } else if (value is String && _matchesAny(value, cfg.valuePatterns)) {
      out[key] = cfg.replacement;
    } else if (value is Map<String, Object?>) {
      out[key] = redactMap(value, cfg);
    } else {
      out[key] = value;
    }
  });
  return out;
}

bool _matchesAny(String s, List<Pattern> patterns) {
  for (final p in patterns) {
    if (p is RegExp) {
      if (p.hasMatch(s)) return true;
    } else {
      // simple substring match for string patterns
      if (s.toLowerCase().contains(p.toString().toLowerCase())) return true;
    }
  }
  return false;
}
