import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/presentation/common_components/cards.dart';
import 'package:muvik/presentation/common_components/primary_button.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';

/// Pumps [child] on a small phone; any RenderFlex overflow fails the test.
Future<void> pumpSmall(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(AccentColor.values.first),
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 640),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('onboarding back button stays on one line (x$scale)', (
      tester,
    ) async {
      await pumpSmall(
        tester,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Quay lại',
                  variant: ButtonVariant.secondary,
                  icon: Icons.chevron_left_rounded,
                  onPressed: () async {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Tiếp tục',
                  variant: ButtonVariant.gradient,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () async {},
                ),
              ),
            ],
          ),
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
      for (final label in ['Quay lại', 'Tiếp tục']) {
        final text = tester.renderObject<RenderParagraph>(find.text(label));
        expect(text.didExceedMaxLines, isFalse);
        // One line of 16sp text, never two.
        expect(text.size.height, lessThan(32 * scale));
      }
    });

    testWidgets('CoverCard fits a 236 horizontal list (x$scale)', (
      tester,
    ) async {
      await pumpSmall(
        tester,
        SizedBox(
          height: 236,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CoverCard(
                title: 'Một tên playlist rất dài để xuống hai dòng chắc chắn',
                subtitle: '12 bài hát',
                onPlay: () {},
              ),
            ],
          ),
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('CoverCard fits a 0.72 grid cell (x$scale)', (tester) async {
      await pumpSmall(
        tester,
        GridView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          children: [
            for (var i = 0; i < 4; i++)
              LayoutBuilder(
                builder: (context, box) => CoverCard(
                  width: box.maxWidth,
                  title: 'Album có tên khá dài số $i để xuống dòng',
                  subtitle: 'Nhiều nghệ sĩ • 20 bài hát',
                  onPlay: () {},
                ),
              ),
          ],
        ),
        textScale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
