enum ScanStatus { idle, scanning, success, partial, error, cancelled }

/// Steps shown on sc_quet_thu_vien while scanning: read file metadata, then
/// rebuild albums/artists, then write availability and source info.
enum ScanPhase { reading, albums, updating }

/// Progress + result of a library scan. `total` is null when the platform
/// cannot tell the file count up front (show processed count, not a fake %).
class ScanState {
  const ScanState({
    this.status = ScanStatus.idle,
    this.phase = ScanPhase.reading,
    this.processed = 0,
    this.total,
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.markedMissing = 0,
    this.currentSource,
    this.errorCode,
  });

  final ScanStatus status;
  final ScanPhase phase;
  final int processed;
  final int? total;
  final int added;
  final int updated;
  final int skipped;
  final int markedMissing;
  final String? currentSource;
  final String? errorCode;

  bool get isRunning => status == ScanStatus.scanning;
  bool get isFinished =>
      status == ScanStatus.success || status == ScanStatus.partial;
  bool get hasChanges => added > 0 || updated > 0 || markedMissing > 0;
  double? get fraction => (total == null || total == 0)
      ? null
      : (processed / total!).clamp(0, 1).toDouble();

  ScanState copyWith({
    ScanStatus? status,
    ScanPhase? phase,
    int? processed,
    int? total,
    int? added,
    int? updated,
    int? skipped,
    int? markedMissing,
    String? currentSource,
    String? errorCode,
  }) => ScanState(
    status: status ?? this.status,
    phase: phase ?? this.phase,
    processed: processed ?? this.processed,
    total: total ?? this.total,
    added: added ?? this.added,
    updated: updated ?? this.updated,
    skipped: skipped ?? this.skipped,
    markedMissing: markedMissing ?? this.markedMissing,
    currentSource: currentSource ?? this.currentSource,
    errorCode: errorCode ?? this.errorCode,
  );
}
