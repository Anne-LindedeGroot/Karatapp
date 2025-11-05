import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/responsive_utils.dart';
import '../providers/accessibility_provider.dart';

/// A comprehensive set of overflow-safe widgets that prevent RenderFlex overflow errors
/// These widgets automatically handle layout constraints and provide fallback behaviors

/// An overflow-safe column that automatically handles content that exceeds available space
class OverflowSafeColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool enableScrolling;

  const OverflowSafeColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.enableScrolling = true,
  });

  @override
  Widget build(BuildContext context) {
    if (enableScrolling) {
      // Check if we have Directionality available before using scrollable widgets
      try {
        Directionality.of(context);
      } catch (e) {
        // If no Directionality is available, return non-scrollable column
        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      }
      
      return SingleChildScrollView(
        physics: physics,
        padding: padding,
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only apply constraints if they are valid
        if (constraints.maxHeight <= 0) {
          return Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
        }
        
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
            maxHeight: constraints.maxHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// An overflow-safe row that automatically handles content that exceeds available space
class OverflowSafeRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool enableWrapping;
  final double spacing;
  final double runSpacing;

  const OverflowSafeRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.enableWrapping = true,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (enableWrapping) {
      return Wrap(
        direction: Axis.horizontal,
        alignment: _wrapAlignmentFromMainAxisAlignment(mainAxisAlignment),
        crossAxisAlignment: _wrapCrossAlignmentFromCrossAxisAlignment(crossAxisAlignment),
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only apply constraints if they are valid
        if (constraints.maxWidth <= 0) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
        }
        
        // Check if we have Directionality available before using scrollable widgets
        try {
          Directionality.of(context);
        } catch (e) {
          // If no Directionality is available, return non-scrollable row
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
        }
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: IntrinsicWidth(
              child: Row(
                mainAxisAlignment: mainAxisAlignment,
                crossAxisAlignment: crossAxisAlignment,
                mainAxisSize: mainAxisSize,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }

  WrapAlignment _wrapAlignmentFromMainAxisAlignment(MainAxisAlignment alignment) {
    switch (alignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _wrapCrossAlignmentFromCrossAxisAlignment(CrossAxisAlignment alignment) {
    switch (alignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      case CrossAxisAlignment.stretch:
        return WrapCrossAlignment.center; // Wrap doesn't support stretch
      case CrossAxisAlignment.baseline:
        return WrapCrossAlignment.center; // Wrap doesn't support baseline
    }
  }
}

/// An overflow-safe flexible widget that provides better overflow handling than standard Flexible
/// This widget automatically detects if it's being used in a Wrap context and adapts accordingly
class OverflowSafeFlexible extends StatelessWidget {
  final Widget child;
  final int flex;
  final bool enableOverflowHandling;

  const OverflowSafeFlexible({
    super.key,
    required this.child,
    this.flex = 1,
    this.enableOverflowHandling = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're in a Wrap context by looking for Wrap ancestors
    bool isInWrapContext = false;
    try {
      context.visitAncestorElements((element) {
        if (element.widget is Wrap) {
          isInWrapContext = true;
          return false; // Stop searching
        }
        return true; // Continue searching
      });
    } catch (e) {
      // If we can't determine context, assume we're not in Wrap
      isInWrapContext = false;
    }

    // If we're in a Wrap context, return a Container with flexible constraints
    if (isInWrapContext) {
      return Container(
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
        ),
        child: child,
      );
    }

    // Otherwise, use standard Flexible behavior
    if (!enableOverflowHandling) {
      return Flexible(
        flex: flex,
        child: child,
      );
    }

    return Flexible(
      flex: flex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only apply constraints if they are valid
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return child;
          }
          
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An overflow-safe expanded widget that provides better overflow handling than standard Expanded
class OverflowSafeExpanded extends StatelessWidget {
  final Widget child;
  final int flex;
  final bool enableOverflowHandling;

  const OverflowSafeExpanded({
    super.key,
    required this.child,
    this.flex = 1,
    this.enableOverflowHandling = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're in a Wrap context by looking for Wrap ancestors
    bool isInWrapContext = false;
    try {
      context.visitAncestorElements((element) {
        if (element.widget is Wrap) {
          isInWrapContext = true;
          return false; // Stop searching
        }
        return true; // Continue searching
      });
    } catch (e) {
      // If we can't determine context, assume we're not in Wrap
      isInWrapContext = false;
    }

    // If we're in a Wrap context, return a Container with flexible constraints
    if (isInWrapContext) {
      return Container(
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
        ),
        child: child,
      );
    }

    if (!enableOverflowHandling) {
      return Expanded(
        flex: flex,
        child: child,
      );
    }

    return Expanded(
      flex: flex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Only apply constraints if they are valid
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return child;
          }
          
          // Check if we have Directionality available before using scrollable widgets
          try {
            Directionality.of(context);
          } catch (e) {
            // If no Directionality is available, return child without scrollable wrapper
            return child;
          }
          
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// An overflow-safe spacer widget that provides better overflow handling than standard Spacer
class OverflowSafeSpacer extends StatelessWidget {
  final int flex;

  const OverflowSafeSpacer({
    super.key,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we're in a Wrap context by looking for Wrap ancestors
    bool isInWrapContext = false;
    try {
      context.visitAncestorElements((element) {
        if (element.widget is Wrap) {
          isInWrapContext = true;
          return false; // Stop searching
        }
        return true; // Continue searching
      });
    } catch (e) {
      // If we can't determine context, assume we're not in Wrap
      isInWrapContext = false;
    }

    // If we're in a Wrap context, return a SizedBox with flexible width
    if (isInWrapContext) {
      return const SizedBox(width: 16); // Fixed spacing in Wrap context
    }

    // Otherwise, use standard Spacer behavior
    return Spacer(flex: flex);
  }
}

/// An overflow-safe text widget that automatically handles text overflow
class OverflowSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableAutoSizing;
  final double? minFontSize;
  final double? maxFontSize;

  const OverflowSafeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableAutoSizing = false,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (enableAutoSizing) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only apply auto-sizing if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return Text(
              text,
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow ?? TextOverflow.visible,
            );
          }

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: Text(
                text,
                style: style,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: overflow ?? TextOverflow.visible,
              ),
            ),
          );
        },
      );
    }

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.visible,
    );
  }
}

/// An accessibility-aware overflow-safe text widget
class AccessibleOverflowSafeText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableAutoSizing;
  final double? minFontSize;
  final double? maxFontSize;

  const AccessibleOverflowSafeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableAutoSizing = false,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);

    // When dyslexia font is enabled, prefer visible text over ellipsis
    final effectiveOverflow = accessibilityState.isDyslexiaFriendly
        ? (overflow ?? TextOverflow.visible)
        : (overflow ?? TextOverflow.visible);

    if (enableAutoSizing) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only apply auto-sizing if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return Text(
              text,
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: effectiveOverflow,
            );
          }

          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              ),
              child: Text(
                text,
                style: style,
                textAlign: textAlign,
                maxLines: maxLines,
                overflow: effectiveOverflow,
              ),
            ),
          );
        },
      );
    }

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: effectiveOverflow,
    );
  }
}

/// An overflow-safe container that automatically handles content overflow
class OverflowSafeContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final bool enableOverflowHandling;

  const OverflowSafeContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
    this.enableOverflowHandling = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      constraints: constraints,
      child: child,
    );

    if (enableOverflowHandling) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only apply overflow handling if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return container;
          }
          
          // Check if we have Directionality available before using scrollable widgets
          try {
            Directionality.of(context);
          } catch (e) {
            // If no Directionality is available, return container without scrollable wrapper
            return container;
          }
          
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: container,
            ),
          );
        },
      );
    }

    return container;
  }
}

/// An overflow-safe button that automatically handles text overflow
class OverflowSafeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isElevated;
  final bool isOutlined;
  final bool fullWidth;
  final bool enableOverflowHandling;

  const OverflowSafeButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isElevated = true,
    this.isOutlined = false,
    this.fullWidth = false,
    this.enableOverflowHandling = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (isOutlined) {
      button = OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    } else if (isElevated) {
      button = ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    } else {
      button = TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }

    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    if (enableOverflowHandling) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only apply overflow handling if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return button;
          }
          
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: button,
          );
        },
      );
    }

    return button;
  }
}

/// An overflow-safe dialog that automatically handles content overflow
class OverflowSafeDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final bool scrollable;
  final bool enableOverflowHandling;

  const OverflowSafeDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.contentPadding,
    this.scrollable = true,
    this.enableOverflowHandling = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: contentPadding ?? const EdgeInsets.all(16.0),
                child: Text(
                  title ?? 'Dialog',
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                ),
              ),
            Flexible(
              child: Builder(
                builder: (context) {
                  // Check if we have Directionality available before using scrollable widgets
                  try {
                    Directionality.of(context);
                  } catch (e) {
                    // If no Directionality is available, return child without scrollable wrapper
                    return Padding(
                      padding: contentPadding ?? const EdgeInsets.all(16.0),
                      child: child,
                    );
                  }
                  
                  return SingleChildScrollView(
                    physics: scrollable ? null : const NeverScrollableScrollPhysics(),
                    padding: contentPadding ?? const EdgeInsets.all(16.0),
                    child: child,
                  );
                },
              ),
            ),
            if (actions != null)
              Padding(
                padding: contentPadding ?? const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Check if buttons would overflow
                    final buttonCount = actions?.length ?? 0;
                    final estimatedButtonWidth = 100.0;
                    final spacing = 8.0 * (buttonCount - 1);
                    final totalEstimatedWidth = (buttonCount * estimatedButtonWidth) + spacing;
                    
                    if (totalEstimatedWidth > constraints.maxWidth) {
                      // Stack buttons vertically if they would overflow
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: (actions ?? []).map((action) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: action,
                            ),
                          )
                        ).toList(),
                      );
                    } else {
                      // Use horizontal layout if buttons fit
                      return Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: actions ?? [],
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A global overflow error handler that prevents RenderFlex overflow errors from crashing the app
class OverflowErrorHandler extends ConsumerWidget {
  final Widget child;
  final bool enableErrorHandling;

  const OverflowErrorHandler({
    super.key,
    required this.child,
    this.enableErrorHandling = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enableErrorHandling) {
      return child;
    }

    // Simply return the child - error handling is done in the error catcher
    return child;
  }
}

/// Extension methods for easy overflow-safe widget creation
extension OverflowSafeWidgets on Widget {
  /// Wraps a widget with overflow-safe handling
  Widget withOverflowProtection({bool enable = true}) {
    if (!enable) return this;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Only apply overflow protection if we have valid constraints
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return this;
        }
        
        // Check if we have Directionality available before using scrollable widgets
        try {
          Directionality.of(context);
        } catch (e) {
          // If no Directionality is available, return widget without scrollable wrapper
          return this;
        }
        
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: this,
            ),
          ),
        );
      },
    );
  }
}

/// Extension methods for responsive overflow handling
extension ResponsiveOverflowHandling on BuildContext {
  /// Creates overflow-safe constraints based on screen size
  BoxConstraints get overflowSafeConstraints {
    final size = MediaQuery.of(this).size;
    return BoxConstraints(
      maxWidth: size.width,
      maxHeight: size.height,
    );
  }

  /// Creates overflow-safe padding that adapts to screen size
  EdgeInsets get overflowSafePadding {
    return EdgeInsets.all(responsiveValue(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    ));
  }

  /// Creates overflow-safe margin that adapts to screen size
  EdgeInsets get overflowSafeMargin {
    return EdgeInsets.all(responsiveValue(
      mobile: 4.0,
      tablet: 6.0,
      desktop: 8.0,
    ));
  }
}
