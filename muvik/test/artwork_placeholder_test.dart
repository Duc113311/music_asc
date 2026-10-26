import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muvik/presentation/common_components/song_artwork.dart';
import 'package:muvik/values/app_assets.dart';
import 'package:muvik/values/app_colors.dart';
import 'package:muvik/values/app_theme.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.dark(AccentColor.lavender),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('a song without artwork shows the brand music note image', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ArtworkPlaceholder(size: 56)));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppAssets.noteIcon);
    expect(find.byIcon(Icons.music_note_rounded), findsNothing);
    expect(tester.getSize(find.byType(ArtworkPlaceholder)), const Size(56, 56));
  });

  testWidgets('playlist placeholders keep their own icon', (tester) async {
    await tester.pumpWidget(
      app(const ArtworkPlaceholder(size: 112, icon: Icons.favorite_rounded)),
    );
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
