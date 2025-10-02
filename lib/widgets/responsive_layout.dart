import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// A responsive layout wrapper that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return context.responsiveValue(
      mobile: mobile,
      tablet: tablet ?? mobile,
      desktop: desktop ?? tablet ?? mobile,
      largeDesktop: largeDesktop ?? desktop ?? tablet ?? mobile,
    );
  }
}

/// A responsive container that adapts its properties based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final bool centerContent;
  final bool limitMaxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
    this.centerContent = false,
    this.limitMaxWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply max width constraint if enabled
    if (limitMaxWidth) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.maxContentWidth,
        ),
        child: content,
      );
    }

    // Center content if requested
    if (centerContent) {
      content = Center(child: content);
    }

    return Container(
      width: width,
      height: height,
      padding: padding ?? context.responsivePadding,
      margin: margin ?? context.responsiveMargin,
      color: color,
      decoration: decoration,
      constraints: constraints,
      child: content,
    );
  }
}

/// A responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? maxColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxColumns,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.getGridColumns(context, maxColumns: maxColumns);
    
    return GridView.builder(
      padding: padding ?? context.responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive card that adapts its width and styling based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final bool adaptiveWidth;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.shape,
    this.adaptiveWidth = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardElevation = elevation ?? 
        context.responsiveValue(
          mobile: 2.0,
          tablet: 4.0,
          desktop: 6.0,
          largeDesktop: 8.0,
        );

    final cardShape = shape ?? 
        RoundedRectangleBorder(
          borderRadius: context.responsiveBorderRadius,
        );

    Widget card = Card(
      color: color,
      elevation: cardElevation,
      shape: cardShape,
      margin: margin ?? context.responsiveMargin,
      child: Padding(
        padding: padding ?? context.responsivePadding,
        child: child,
      ),
    );

    if (adaptiveWidth && !context.isMobile) {
      card = SizedBox(
        width: context.cardWidth,
        child: card,
      );
    }

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: context.responsiveBorderRadius,
        child: card,
      );
    }

    return card;
  }
}

/// A responsive list that adapts its layout based on screen size
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final bool useGrid;
  final int? maxColumns;

  const ResponsiveList({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.useGrid = false,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    if (useGrid && context.isDesktop) {
      return ResponsiveGrid(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        maxColumns: maxColumns,
        children: children,
      );
    }

    return ListView(
      padding: padding ?? context.responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      children: children,
    );
  }
}

/// A responsive app bar that adapts its height and styling
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      toolbarHeight: ResponsiveUtils.responsiveAppBarHeight(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A responsive dialog that adapts its size and constraints
class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final bool scrollable;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.contentPadding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: context.responsiveBorderRadius,
      ),
      child: ConstrainedBox(
        constraints: context.dialogConstraints,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: context.responsivePadding,
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                physics: scrollable ? null : const NeverScrollableScrollPhysics(),
                padding: contentPadding ?? context.responsivePadding,
                child: child,
              ),
            ),
            if (actions != null)
              Padding(
                padding: context.responsivePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A responsive button that adapts its size and styling
class ResponsiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isElevated;
  final bool isOutlined;
  final bool fullWidth;

  const ResponsiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.isElevated = true,
    this.isOutlined = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.responsiveButtonHeight(context);
    final buttonPadding = context.responsivePadding;

    final baseStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(fullWidth ? double.infinity : 88, buttonHeight),
      ),
      padding: WidgetStateProperty.all(buttonPadding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: context.responsiveBorderRadius,
        ),
      ),
    );

    final combinedStyle = style != null ? baseStyle.merge(style) : baseStyle;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: combinedStyle,
        child: child,
      );
    }

    if (isElevated) {
      return ElevatedButton(
        onPressed: onPressed,
        style: combinedStyle,
        child: child,
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: combinedStyle,
      child: child,
    );
  }
}
