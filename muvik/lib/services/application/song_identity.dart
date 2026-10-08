/// Stable identity for a local audio file: `<volume>/<relative path><file>`,
/// lower-cased. MediaStore rows and SAF documents that point at the same file
/// produce the same identity, so overlapping sources never double count
/// (P05-07). Two files with the same name in different folders differ.
class SongIdentity {
  SongIdentity._();

  static const String primaryVolume = 'external_primary';

  /// MediaStore row on [volume] (legacy `external` maps to primary).
  static String fromVolume(
    String volume,
    String relativePath,
    String fileName,
  ) {
    final v = volume == 'external' ? primaryVolume : volume;
    return _join(v, relativePath, fileName);
  }

  /// SAF document URI such as
  /// `content://com.android.externalstorage.documents/tree/primary%3AMusic/document/primary%3AMusic%2Fa.mp3`.
  /// Falls back to the URI itself for providers without a path-like doc id.
  static String fromDocumentUri(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.pathSegments.isEmpty) return uri.toLowerCase();
    final docId = Uri.decodeComponent(parsed.pathSegments.last);
    final colon = docId.indexOf(':');
    if (parsed.host != 'com.android.externalstorage.documents' || colon < 0) {
      return uri.toLowerCase();
    }
    final root = docId.substring(0, colon);
    final path = docId.substring(colon + 1);
    final volume = root == 'primary' ? primaryVolume : root;
    return '$volume/$path'.toLowerCase();
  }

  /// Folder identity prefix for a song identity (used by folder exclusion).
  static String folderOf(String identity) {
    final i = identity.lastIndexOf('/');
    return i < 0 ? identity : identity.substring(0, i + 1);
  }

  static String _join(String volume, String relativePath, String fileName) {
    var rel = relativePath.replaceAll('\\', '/');
    if (rel.startsWith('/')) rel = rel.substring(1);
    if (rel.isNotEmpty && !rel.endsWith('/')) rel = '$rel/';
    return '$volume/$rel$fileName'.toLowerCase();
  }
}
