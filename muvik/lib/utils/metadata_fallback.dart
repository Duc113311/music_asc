/// Metadata fallbacks and search normalization (P05-08, P09-08).
class MetadataFallback {
  MetadataFallback._();

  static const _unknownTags = {'<unknown>', 'unknown', ''};

  /// Null when the tag is missing or a platform "unknown" placeholder.
  static String? clean(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return _unknownTags.contains(t.toLowerCase()) ? null : t;
  }

  /// Title, or the file name without extension when the tag is missing.
  static String title(String? tag, String fileName) {
    final t = clean(tag);
    if (t != null) return t;
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  /// Lower-case, Vietnamese diacritics removed, whitespace collapsed.
  static String normalize(String input) {
    final lower = input.toLowerCase();
    final b = StringBuffer();
    for (final r in lower.runes) {
      final ch = String.fromCharCode(r);
      b.write(_map[ch] ?? ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String searchKey(List<String> parts) =>
      normalize(parts.where((p) => p.isNotEmpty).join(' '));

  static final Map<String, String> _map = _buildMap();

  static Map<String, String> _buildMap() {
    const groups = {
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };
    final m = <String, String>{};
    groups.forEach((base, chars) {
      for (final r in chars.runes) {
        m[String.fromCharCode(r)] = base;
      }
    });
    return m;
  }
}
