enum CompressionPreset {
  maximum(
    title: 'Original (HD)',
    subtitle: 'Full resolution & archival quality',
    quality: 95,
    maxDimension: 2560,
  ),
  balanced(
    title: 'Balanced (Standard)',
    subtitle: 'Crisp text with ~50% reduced size',
    quality: 75,
    maxDimension: 1600,
  ),
  compact(
    title: 'Compact (Lite)',
    subtitle: 'Aggressive reduction for quick email/sharing',
    quality: 45,
    maxDimension: 1080,
  );

  final String title;
  final String subtitle;
  final int quality;
  final int maxDimension;

  const CompressionPreset({
    required this.title,
    required this.subtitle,
    required this.quality,
    required this.maxDimension,
  });
}
