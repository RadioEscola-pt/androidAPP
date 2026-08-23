import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/question_providers.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _websiteUrl =
      'https://dirtybug.github.io/radioAmadorCat2exame/index.html#';
  static const _telegramUrl = 'https://t.me/+xQNzwNwb2JIxMWY8';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(colorScheme: colorScheme),
              const SizedBox(height: 8),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: screenPaddingH),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categorias',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estuda ao teu ritmo ou simula um exame (40 perguntas, 60 min)',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _CategoryTile(
                category: Category.cat3,
                accentColor: categoryCat3Color,
                icon: Icons.school_outlined,
                subtitle: 'Entrada',
                questionHint: 'Receção e emissão supervisionada',
              ),
              _CategoryTile(
                category: Category.cat2,
                accentColor: categoryCat2Color,
                icon: Icons.auto_graph_outlined,
                subtitle: 'Intermédio',
                questionHint: 'Direitos de emissão e receção',
              ),
              _CategoryTile(
                category: Category.cat1,
                accentColor: categoryCat1Color,
                icon: Icons.emoji_events_outlined,
                subtitle: 'Avançado · HAREC',
                questionHint: 'Plenos direitos de emissão',
              ),

              const SizedBox(height: 32),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: screenPaddingH),
                child: Text(
                  'Comunidade',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: screenPaddingH),
                child: Row(
                  children: [
                    Expanded(
                      child: _CommunityChip(
                        icon: Icons.language,
                        label: 'Website',
                        onTap: () => _openUrl(_websiteUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CommunityChip(
                        icon: Icons.send_rounded,
                        label: 'Telegram',
                        onTap: () => _openUrl(_telegramUrl),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final topPadding = isLandscape ? 20.0 : 40.0;
    final bottomPadding = isLandscape ? 16.0 : 32.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          screenPaddingH, topPadding, screenPaddingH, bottomPadding),
      child: isLandscape
          ? Row(
              children: [
                _brandIcon(48, 14, 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _brandTitle(28, -0.8),
                      const SizedBox(height: 4),
                      _subtitle(14),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _brandIcon(56, radiusM, 32),
                const SizedBox(height: 20),
                _brandTitle(34, -1.0),
                const SizedBox(height: 8),
                _subtitle(16),
              ],
            ),
    );
  }

  Widget _brandIcon(double size, double radius, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.cell_tower_rounded,
        size: iconSize,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _brandTitle(double size, double letterSpacing) {
    return Text(
      'Rádio Escola',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: letterSpacing,
        color: brandColor,
      ),
    );
  }

  Widget _subtitle(double size) {
    return Text(
      'Prepara-te para o exame de rádio amador.',
      style: TextStyle(
        fontSize: size,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.accentColor,
    required this.icon,
    required this.subtitle,
    required this.questionHint,
  });

  final Category category;
  final Color accentColor;
  final IconData icon;
  final String subtitle;
  final String questionHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor =
        accentColor.withAlpha(isDark ? 30 : 18);
    final accentOnSurface =
        isDark ? Color.lerp(accentColor, Colors.white, 0.3)! : accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: screenPaddingH, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(radiusM),
          border: Border.all(
            color: accentColor.withAlpha(isDark ? 50 : 30),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(isDark ? 60 : 35),
                    borderRadius: BorderRadius.circular(radiusS),
                  ),
                  child: Icon(icon, color: accentOnSurface, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$subtitle  ·  $questionHint',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentOnSurface,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            context.push('/study/${category.name}'),
                        child: const Text('Estudar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentOnSurface,
                          side: BorderSide(
                              color: accentOnSurface.withAlpha(120)),
                        ),
                        onPressed: () =>
                            context.push('/exam/${category.name}'),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Simular Exame'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(radiusS),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusS),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
