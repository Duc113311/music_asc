import 'package:flutter/material.dart';

import '../../values/app_colors.dart';
import '../../values/app_typography.dart';
import '../common_components/cards.dart';

/// Neutral navy palette of the settings detail mockups (sc_gioi_thieu,
/// sc_hen_gio_tat, sc_phat_qua_tai_nghe, sc_quet_thu_vien). The light theme
/// keeps the regular tokens.
class DetailPalette {
  DetailPalette._(this.dark, this._c);

  factory DetailPalette.of(BuildContext context) => DetailPalette._(
        Theme.of(context).brightness == Brightness.dark,
        context.colors,
      );

  final bool dark;
  final AppColors _c;

  Color get page => dark ? const Color(0xFF0F131C) : _c.background;
  Color get card => dark ? const Color(0xFF141926) : _c.surface;
  Color get border => dark ? const Color(0xFF1F2534) : _c.border;
  Color get divider => dark ? const Color(0xFF1E2331) : _c.divider;
  Color get text => dark ? const Color(0xFFF7F5F2) : _c.textPrimary;
  Color get textSecondary => dark ? const Color(0xFFB0B2D7) : _c.textSecondary;
  Color get muted => dark ? const Color(0xFF8E92AA) : _c.textMuted;
}

/// Scaffold + back app bar on the detail palette.
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottom,
    this.titleSize = 19,
    this.titleWeight = FontWeight.w500,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final double titleSize;
  final FontWeight titleWeight;

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    return Scaffold(
      backgroundColor: p.page,
      appBar: DetailAppBar(
        title: title,
        backgroundColor: p.page,
        titleStyle: AppTypography.appBarTitle.copyWith(
          fontSize: titleSize,
          fontWeight: titleWeight,
          color: p.text,
        ),
      ),
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: bottom,
    );
  }
}

/// Rounded card; children are separated by full-width dividers.
class DetailCard extends StatelessWidget {
  const DetailCard({
    super.key,
    required this.children,
    this.dividerIndent = 0,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = DetailPalette.of(context);
    // Material (not a decorated Container) so the rows' ripples show.
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  endIndent: dividerIndent,
                  color: p.divider,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Accent section label above a card ("Khi kết nối tai nghe").
class DetailSectionLabel extends StatelessWidget {
  const DetailSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppTypography.headingS.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            color: DetailPalette.of(context).dark
                ? const Color(0xFFA9A5D1)
                : c.primary,
          ),
        ),
      ),
    );
  }
}

/// Info icon + muted note.
class DetailNote extends StatelessWidget {
  const DetailNote(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = DetailPalette.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 21, color: c.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyM.copyWith(
              fontSize: 12,
              color: color ?? p.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
