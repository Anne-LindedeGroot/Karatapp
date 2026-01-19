class DesktopLayoutConfig {
  final int columns;
  final double cardAspectRatio;

  const DesktopLayoutConfig({
    required this.columns,
    required this.cardAspectRatio,
  });

  static DesktopLayoutConfig forWidth(
    double width, {
    bool isLargeDesktop = false,
  }) {
    if (isLargeDesktop) {
      if (width < 1400) {
        return const DesktopLayoutConfig(columns: 2, cardAspectRatio: 0.5);
      }
      if (width < 1800) {
        return const DesktopLayoutConfig(columns: 3, cardAspectRatio: 0.6);
      }
      return const DesktopLayoutConfig(columns: 4, cardAspectRatio: 0.7);
    }

    if (width < 1100) {
      return const DesktopLayoutConfig(columns: 2, cardAspectRatio: 0.5);
    }
    if (width < 1600) {
      return const DesktopLayoutConfig(columns: 3, cardAspectRatio: 0.6);
    }
    return const DesktopLayoutConfig(columns: 4, cardAspectRatio: 0.7);
  }
}
