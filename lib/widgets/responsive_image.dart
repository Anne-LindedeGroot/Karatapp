import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/responsive_utils.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';

/// A responsive image widget that adapts to screen density and size
class ResponsiveImage extends ConsumerWidget {
  final String? imageUrl;
  final String? assetPath;
  final File? imageFile;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  final bool enableLazyLoading;
  final Size? baseSize;

  const ResponsiveImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.imageFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableCaching = true,
    this.enableLazyLoading = true,
    this.baseSize,
  }) : assert(
         (imageUrl != null) ^ (assetPath != null) ^ (imageFile != null),
         'Exactly one of imageUrl, assetPath, or imageFile must be provided',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsiveSize = _getResponsiveSize(context);
    final effectiveWidth = width ?? responsiveSize.width;
    final effectiveHeight = height ?? responsiveSize.height;

    Widget imageWidget;

    if (imageUrl != null) {
      imageWidget = _buildNetworkImage(context, ref, effectiveWidth, effectiveHeight);
    } else if (assetPath != null) {
      imageWidget = _buildAssetImage(context, effectiveWidth, effectiveHeight);
    } else if (imageFile != null) {
      imageWidget = _buildFileImage(context, effectiveWidth, effectiveHeight);
    } else {
      imageWidget = _buildErrorWidget(context);
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Size _getResponsiveSize(BuildContext context) {
    if (baseSize != null) {
      return context.getResponsiveImageSize(baseSize: baseSize!);
    }

    // Default responsive sizes based on screen size and density
    final screenSize = context.screenSize;
    final density = context.screenDensity;
    final isLandscape = context.isLandscape;

    double baseWidth = 200;
    double baseHeight = 200;

    // Adjust base size for screen size
    switch (screenSize) {
      case ScreenSize.mobile:
        baseWidth = isLandscape ? 150 : 200;
        baseHeight = isLandscape ? 100 : 200;
        break;
      case ScreenSize.tablet:
        baseWidth = isLandscape ? 250 : 300;
        baseHeight = isLandscape ? 150 : 300;
        break;
      case ScreenSize.foldable:
        baseWidth = 220;
        baseHeight = 220;
        break;
      case ScreenSize.largeFoldable:
        baseWidth = 280;
        baseHeight = 280;
        break;
      case ScreenSize.desktop:
        baseWidth = 350;
        baseHeight = 350;
        break;
      case ScreenSize.largeDesktop:
        baseWidth = 400;
        baseHeight = 400;
        break;
    }

    // Adjust for screen density
    switch (density) {
      case ScreenDensity.low:
        baseWidth *= 0.8;
        baseHeight *= 0.8;
        break;
      case ScreenDensity.medium:
        // Keep default size
        break;
      case ScreenDensity.high:
        baseWidth *= 1.2;
        baseHeight *= 1.2;
        break;
      case ScreenDensity.extraHigh:
        baseWidth *= 1.5;
        baseHeight *= 1.5;
        break;
    }

    return Size(baseWidth, baseHeight);
  }

  Widget _buildNetworkImage(BuildContext context, WidgetRef ref, double width, double height) {
    return FutureBuilder<String>(
      future: OfflineMediaCacheService.getMediaUrl(imageUrl!, false, ref),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? imageUrl!;
        final isLocalFile = resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://');

        if (isLocalFile) {
          return Image.file(
            File(resolvedUrl.replaceFirst('file://', '')),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
          );
        }

        if (!enableCaching) {
          // Check if we're offline - if so, don't try to load network image
          final networkState = ref.watch(networkProvider);
          if (networkState.isDisconnected) {
            return _buildErrorWidget(context);
          }

          return Image.network(
            resolvedUrl,
            width: width,
            height: height,
            fit: fit,
            loadingBuilder: enableLazyLoading ? _buildLoadingBuilder : null,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
          );
        }

        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: placeholder != null
              ? (context, url) => placeholder!
              : enableLazyLoading
                  ? (context, url) => _buildLoadingWidget(context)
                  : null,
          errorWidget: errorWidget != null
              ? (context, url, error) => errorWidget!
              : (context, url, error) => _buildErrorWidget(context),
          memCacheWidth: width.toInt(),
          memCacheHeight: height.toInt(),
        );
      },
    );
  }

  Widget _buildAssetImage(BuildContext context, double width, double height) {
    return Image.asset(
      assetPath!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildFileImage(BuildContext context, double width, double height) {
    return Image.file(
      imageFile!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context),
    );
  }

  Widget _buildLoadingBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return _buildLoadingWidget(context);
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A responsive image grid that adapts to screen size and density
class ResponsiveImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int? maxColumns;
  final double aspectRatio;
  final double spacing;
  final EdgeInsetsGeometry? padding;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final VoidCallback? onImageTap;
  final bool enableCaching;

  const ResponsiveImageGrid({
    super.key,
    required this.imageUrls,
    this.maxColumns,
    this.aspectRatio = 1.0,
    this.spacing = 8.0,
    this.padding,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onImageTap,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    final columns = _getColumnCount(context);

    return GridView.builder(
      padding: padding ?? context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: onImageTap,
          child: ResponsiveImage(
            imageUrl: imageUrls[index],
            fit: fit,
            borderRadius: borderRadius,
            enableCaching: enableCaching,
          ),
        );
      },
    );
  }

  int _getColumnCount(BuildContext context) {
    if (maxColumns != null) {
      return maxColumns!;
    }

    final screenSize = context.screenSize;
    final isLandscape = context.isLandscape;

    switch (screenSize) {
      case ScreenSize.mobile:
        return isLandscape ? 3 : 2;
      case ScreenSize.tablet:
        return isLandscape ? 4 : 3;
      case ScreenSize.foldable:
        return 3;
      case ScreenSize.largeFoldable:
        return 4;
      case ScreenSize.desktop:
        return 5;
      case ScreenSize.largeDesktop:
        return 6;
    }
  }
}

/// A responsive image carousel that adapts to screen size
class ResponsiveImageCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final double? height;
  final double aspectRatio;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool enableAutoPlay;
  final Duration autoPlayInterval;
  final VoidCallback? onImageTap;
  final bool enableCaching;

  const ResponsiveImageCarousel({
    super.key,
    required this.imageUrls,
    this.height,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.enableAutoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.onImageTap,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveHeight = height ?? 
        (context.isLandscape ? screenHeight * 0.4 : screenHeight * 0.3);

    return SizedBox(
      height: effectiveHeight,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: onImageTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing(SpacingSize.sm),
              ),
              child: ResponsiveImage(
                imageUrl: imageUrls[index],
                height: effectiveHeight,
                fit: fit,
                borderRadius: borderRadius,
                enableCaching: enableCaching,
              ),
            ),
          );
        },
      ),
    );
  }
}
