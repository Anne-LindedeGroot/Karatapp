import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ohyo_model.dart';
import '../services/offline_ohyo_service.dart';
import '../utils/image_utils.dart';
import '../utils/retry_utils.dart';
import '../supabase_client.dart';
import '../core/storage/local_storage.dart' as app_storage;
import '../services/offline_media_cache_service.dart';
import 'error_boundary_provider.dart';
import 'offline_services_provider.dart';
import 'interaction_provider.dart';
import '../utils/search_utils.dart';

// OfflineOhyoService provider is now imported from offline_services_provider.dart

// StateNotifier for ohyo management
class OhyoNotifier extends StateNotifier<OhyoState> {
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;
  OfflineOhyoService? _offlineOhyoService;

  OhyoNotifier(this._errorBoundary, this._ref) : super(OhyoState.initial()) {
    // Don't auto-load ohyos on initialization - wait for explicit call
  }

  void initializeOfflineService(OfflineOhyoService offlineOhyoService) {
    _offlineOhyoService = offlineOhyoService;
  }

  final SupabaseClient _supabase = SupabaseClientManager().client;

  /// Initialize ohyo loading when user is authenticated and on home screen
  void initializeOhyoLoading() {
    // Only load if we haven't loaded yet and not currently loading
    if (state.ohyos.isEmpty && !state.isLoading && state.error == null) {
      Future.microtask(() => loadOhyos());
    }
  }

  /// Load images for a specific ohyo (lazy loading)
  Future<void> loadOhyoImages(int ohyoId, {dynamic ref}) async {
    try {
      List<String> imageUrls = [];

      // First, check if we're offline and try to load cached images immediately
      try {
        final isOnline = await _checkNetworkConnectivity();
        if (!isOnline) {
          debugPrint('🌐 Offline mode detected for ohyo $ohyoId, loading cached images first');
          final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
          if (cachedImageUrls.isNotEmpty) {
            debugPrint('✅ Found ${cachedImageUrls.length} cached images for ohyo $ohyoId');
            imageUrls = cachedImageUrls;

            // Update the ohyo in the state with cached images
            final updatedOhyos = state.ohyos.map((ohyo) {
              if (ohyo.id == ohyoId) {
                return ohyo.copyWith(imageUrls: imageUrls);
              }
              return ohyo;
            }).toList();

            final updatedFilteredOhyos = state.filteredOhyos.map((ohyo) {
              if (ohyo.id == ohyoId) {
                return ohyo.copyWith(imageUrls: imageUrls);
              }
              return ohyo;
            }).toList();

            state = state.copyWith(
              ohyos: updatedOhyos,
              filteredOhyos: updatedFilteredOhyos,
            );
            return; // Return early if we have cached images and are offline
          } else {
            debugPrint('ℹ️ No cached images available for ohyo $ohyoId');
          }
        }
      } catch (networkCheckError) {
        debugPrint('⚠️ Failed to check network status: $networkCheckError');
      }

      // Try to fetch online images
      try {
        imageUrls = await ImageUtils.fetchOhyoImagesFromBucket(ohyoId, ref: ref);
            // Silent: Online image loading success not logged
            // Silent: Online image URLs not logged
      } catch (e) {
        debugPrint('❌ Online image fetch failed for ohyo $ohyoId: $e');

        // Try to load cached images as fallback when online fetch fails
        try {
          final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
          if (cachedImageUrls.isNotEmpty) {
            debugPrint('🔄 Using ${cachedImageUrls.length} cached images for ohyo $ohyoId as fallback');
            // Reduced spam: Cached image loading is now silent
            imageUrls = cachedImageUrls;
          } else {
            debugPrint('ℹ️ No cached images available for ohyo $ohyoId');
          }
        } catch (cacheError) {
          debugPrint('❌ Failed to load cached images for ohyo $ohyoId: $cacheError');
        }
      }

      if (imageUrls.isNotEmpty) {
        // Update the ohyo in the state with the loaded images
        final updatedOhyos = state.ohyos.map((ohyo) {
          if (ohyo.id == ohyoId) {
            return ohyo.copyWith(imageUrls: imageUrls);
          }
          return ohyo;
        }).toList();

        final updatedFilteredOhyos = state.filteredOhyos.map((ohyo) {
          if (ohyo.id == ohyoId) {
            return ohyo.copyWith(imageUrls: imageUrls);
          }
          return ohyo;
        }).toList();

        state = state.copyWith(
          ohyos: updatedOhyos,
          filteredOhyos: updatedFilteredOhyos,
        );
      }
    } catch (e) {
      debugPrint('Failed to load ohyo images for ohyo $ohyoId: $e');
      // Don't show error for image loading failures - it's not critical
    }
  }

  Future<void> loadOhyos() async {
    state = state.copyWith(isLoading: true, error: null);

    List<Ohyo>? cachedOhyos;

    // First, try to load from cache if available
    if (_offlineOhyoService != null) {
      try {
        cachedOhyos = await _offlineOhyoService!.getValidCachedOhyos();
        if (cachedOhyos != null && cachedOhyos.isNotEmpty) {
          // Load cached ohyos first for immediate UI feedback
          state = state.copyWith(
            ohyos: cachedOhyos,
            filteredOhyos: cachedOhyos,
            isLoading: true, // Keep loading true while we try to refresh from online
            error: null,
            isOfflineMode: true,
          );

          // Preload images for cached ohyos (try cached images first, especially when offline)
          if (cachedOhyos.isNotEmpty) {
            await _preloadInitialOhyoImagesWithCache(cachedOhyos.take(3).toList());
          }

          // Preload likes for all ohyos to ensure offline availability
          await _preloadOhyoLikes(cachedOhyos);
        } else {
          // If SharedPreferences cache is empty/expired, try Hive storage
          try {
            final hiveCachedOhyos = app_storage.LocalStorage.getAllOhyos();
            if (hiveCachedOhyos.isNotEmpty) {
              // Convert CachedOhyo to Ohyo with likes data
              cachedOhyos = hiveCachedOhyos.map((cachedOhyo) {
                return Ohyo(
                  id: cachedOhyo.id,
                  name: cachedOhyo.name,
                  description: cachedOhyo.description,
                  style: cachedOhyo.style ?? '',
                  createdAt: cachedOhyo.createdAt,
                  imageUrls: cachedOhyo.imageUrls,
                  videoUrls: [], // Not stored in CachedOhyo
                  order: 0, // Not stored in CachedOhyo
                  isLiked: cachedOhyo.isLiked, // Include cached likes data
                  likeCount: cachedOhyo.likeCount, // Include cached like count
                );
              }).toList();

              // Load cached ohyos from Hive for immediate UI feedback
              state = state.copyWith(
                ohyos: cachedOhyos,
                filteredOhyos: cachedOhyos,
                isLoading: true, // Keep loading true while we try to refresh from online
                error: null,
                isOfflineMode: true,
              );

              // Preload images for cached ohyos
              if (cachedOhyos.isNotEmpty) {
                await _preloadInitialOhyoImagesWithCache(cachedOhyos.take(3).toList());
              }
            }
          } catch (e) {
            debugPrint('Error loading Hive cached ohyos: $e');
          }
        }
      } catch (e) {
        // Ignore cache errors, continue with online loading
      }
    }

    // Then try to load from online
    try {
      await RetryUtils.executeWithRetry(
        () async {
          final response = await _supabase
              .from("ohyo")
              .select()
              .order('order', ascending: true);

          final onlineOhyos = (response as List)
              .map((data) => Ohyo.fromMap(data as Map<String, dynamic>))
              .toList();

          // Cache the online data
          if (_offlineOhyoService != null) {
            await _offlineOhyoService!.cacheOhyos(onlineOhyos);
          }

          // Update state with online data
          state = state.copyWith(
            ohyos: onlineOhyos,
            filteredOhyos: onlineOhyos,
            isLoading: false,
            error: null,
            isOfflineMode: false,
          );

          // Preload images for online ohyos
          if (onlineOhyos.isNotEmpty) {
            await _preloadInitialOhyoImagesWithCache(onlineOhyos.take(3).toList());
          }

          // Preload likes for all ohyos to ensure offline availability
          await _preloadOhyoLikes(onlineOhyos);
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for loading ohyos
        },
      );
    } catch (e) {
      // Online loading failed
      if (cachedOhyos != null && cachedOhyos.isNotEmpty) {
        // We have cached data, show it with offline indicator
        state = state.copyWith(
          isLoading: false,
          error: null,
          isOfflineMode: true,
        );
      } else {
        // No cached data available, show error
        final errorMessage = 'Failed to load ohyos: ${e.toString()}';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isOfflineMode: false,
        );

        // Only report to error boundary if it's not a network error
        if (!_isNetworkError(e)) {
          _errorBoundary.reportNetworkError(errorMessage);
        }
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  /// Check network connectivity more reliably
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Use a simple connectivity check by trying to resolve a hostname
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  void searchOhyos(String query) {
    final normalizedQuery = SearchUtils.normalizeSearchText(query);
    state = state.copyWith(searchQuery: query);

    if (normalizedQuery.isEmpty) {
      // If search is empty, show all filtered by category
      if (state.selectedCategory != null && state.selectedCategory != OhyoCategory.all) {
        final filtered = state.ohyos.where((ohyo) {
          final category = OhyoCategory.fromStyle(ohyo.style);
          return category == state.selectedCategory;
        }).toList();
        state = state.copyWith(filteredOhyos: filtered);
      } else {
        state = state.copyWith(filteredOhyos: state.ohyos);
      }
      return;
    }

    // Check if query is purely numeric (contains only digits)
    final isNumericQuery = RegExp(r'^\d+$').hasMatch(normalizedQuery);
    
    // Check if query matches patterns like "ohyo5", "ohyo-5", "ohyo.5", "o5", "o-5", "o 5", "05", "0 5", "o7", "o8", etc.
    // "o" represents the last letter of "ohyo"
    // Also handle "0" as a shortcut for "o" (since "0" looks like "o" on some keyboards)
    // Pattern: (ohyo|o|0) followed by optional separator and number
    // Make sure to match "o7", "o8", "07", "08" correctly
    String? extractedNumber;
    
    // Unified pattern that matches all variations: "ohyo7", "o7", "07", "o 7", "o-7", etc.
    // The separator [\s\-\._]? is optional, so "o7" matches directly
    final ohyoNumberPattern = RegExp(r'^(?:ohyo|o|0)[\s\-\._]?(\d+)$', caseSensitive: false);
    
    // Try matching on normalized query (handles case variations and whitespace normalization)
    var match = ohyoNumberPattern.firstMatch(normalizedQuery);
    extractedNumber = match?.group(1);
    
    // If no match on normalized query, try original query (before normalization)
    // This handles edge cases where normalization might affect the pattern
    if (extractedNumber == null) {
      final trimmedQuery = query.trim().toLowerCase();
      match = ohyoNumberPattern.firstMatch(trimmedQuery);
      extractedNumber = match?.group(1);
    }

    final filtered = state.ohyos.where((ohyo) {
      bool matchesQuery = false;
      final nameNormalized = SearchUtils.normalizeSearchText(ohyo.name);
      final searchNumber = extractedNumber ?? (isNumericQuery ? normalizedQuery : null);

      if (searchNumber != null) {
        // For numeric queries (either "5" or "ohyo5", "ohyo-5", etc.), use exact number matching
        // This prevents "5" from matching "6", "15", "25", etc.
        final ordinals = _getOrdinalForms(searchNumber);

        // Priority 1: Check exact order number match (most reliable)
        matchesQuery = ohyo.order.toString() == searchNumber;

        // Priority 2: Check if name contains exact number or ordinal forms
        // Extract all numbers from the name and check for exact match
        if (!matchesQuery) {
          matchesQuery = _matchesExactNumber(nameNormalized, searchNumber, ordinals);
        }

        // Priority 3: Check exact ID match (for direct ID searches)
        if (!matchesQuery) {
          matchesQuery = ohyo.id.toString() == searchNumber;
        }

        // Do NOT check description for numeric queries to prevent false matches
      } else {
        // For text queries, search in text fields with normalized matching
        // Check if name starts with the query
        matchesQuery = nameNormalized.startsWith(normalizedQuery);

        // If not, check if any word in the name starts with the query
        if (!matchesQuery) {
          final nameWords = SearchUtils.splitIntoWords(ohyo.name);
          matchesQuery = nameWords.any((word) => word.startsWith(normalizedQuery) || normalizedQuery.startsWith(word));
        }

        // Also check description and style with normalized contains
        if (!matchesQuery) {
          final descNormalized = SearchUtils.normalizeSearchText(ohyo.description);
          final styleNormalized = SearchUtils.normalizeSearchText(ohyo.style);
          matchesQuery = descNormalized.contains(normalizedQuery) ||
                         styleNormalized.contains(normalizedQuery);
        }
        
        // Word-based matching for better tolerance
        if (!matchesQuery) {
          final queryWords = SearchUtils.splitIntoWords(query);
          final nameWords = SearchUtils.splitIntoWords(ohyo.name);
          final descWords = SearchUtils.splitIntoWords(ohyo.description);
          final styleWords = SearchUtils.splitIntoWords(ohyo.style);
          
          // Check if all query words appear in any field
          matchesQuery = queryWords.every((queryWord) {
            final normalizedQueryWord = SearchUtils.normalizeSearchText(queryWord);
            return nameWords.any((word) => word.contains(normalizedQueryWord)) ||
                   descWords.any((word) => word.contains(normalizedQueryWord)) ||
                   styleWords.any((word) => word.contains(normalizedQueryWord));
          });
        }
      }

      if (state.selectedCategory != null && state.selectedCategory != OhyoCategory.all) {
        final category = OhyoCategory.fromStyle(ohyo.style);
        return matchesQuery && category == state.selectedCategory;
      }

      return matchesQuery;
    }).toList();

    // Sort results: exact order matches first, then by order number
    if (extractedNumber != null || isNumericQuery) {
      final searchNum = extractedNumber ?? (isNumericQuery ? normalizedQuery : null);
      if (searchNum != null) {
        filtered.sort((a, b) {
          // Exact order match comes first
          final aExactMatch = a.order.toString() == searchNum;
          final bExactMatch = b.order.toString() == searchNum;
          if (aExactMatch && !bExactMatch) return -1;
          if (!aExactMatch && bExactMatch) return 1;
          // Then sort by order number
          return a.order.compareTo(b.order);
        });
      }
    }

    state = state.copyWith(filteredOhyos: filtered);
  }

  // Helper function to get ordinal forms of a number (e.g., "5" -> ["fifth", "5th"])
  List<String> _getOrdinalForms(String number) {
    final num = int.tryParse(number);
    if (num == null) return [];

    final ordinals = <String>[];

    // Add the number itself
    ordinals.add(number);

    // Add ordinal suffixes
    if (num == 1) {
      ordinals.add('${number}st');
      ordinals.add('first');
    } else if (num == 2) {
      ordinals.add('${number}nd');
      ordinals.add('second');
    } else if (num == 3) {
      ordinals.add('${number}rd');
      ordinals.add('third');
    } else {
      ordinals.add('${number}th');
      // Add word form for common numbers
      const wordOrdinals = {
        1: 'first', 2: 'second', 3: 'third', 4: 'fourth', 5: 'fifth',
        6: 'sixth', 7: 'seventh', 8: 'eighth', 9: 'ninth', 10: 'tenth',
        11: 'eleventh', 12: 'twelfth', 13: 'thirteenth', 14: 'fourteenth',
        15: 'fifteenth', 16: 'sixteenth', 17: 'seventeenth', 18: 'eighteenth',
        19: 'nineteenth', 20: 'twentieth'
      };
      if (wordOrdinals.containsKey(num)) {
        ordinals.add(wordOrdinals[num]!);
      }
    }

    return ordinals;
  }

  // Helper function to check if text matches an exact number or its ordinal forms
  // This ensures "5" matches "ohyo 5" but NOT "ohyo 6", "ohyo 15", "ohyo 50", etc.
  // Also ensures "7" does NOT match "17", "27", "70", etc.
  bool _matchesExactNumber(String text, String number, List<String> ordinals) {
    final textLower = text.toLowerCase();
    final searchNumber = int.tryParse(number);
    if (searchNumber == null) return false;

    // Use word boundaries to match exact numbers only
    // This pattern ensures "7" matches "7" but NOT "17", "27", "70", "71", etc.
    // The \b word boundary ensures the number is not part of a larger number
    final exactNumberPattern = RegExp(r'\b' + RegExp.escape(number) + r'\b');
    if (exactNumberPattern.hasMatch(textLower)) {
      return true;
    }

    // Also check for numbers with word boundaries using regex that finds standalone numbers
    // Extract all numbers from the text and check for exact match with proper boundaries
    final numberMatches = RegExp(r'\b\d+\b').allMatches(textLower);
    for (final match in numberMatches) {
      final matchedNumber = int.tryParse(match.group(0)!);
      if (matchedNumber == searchNumber) {
        // Found exact number match - the \b word boundaries ensure it's standalone
        return true;
      }
    }

    // Check for ordinal forms (word boundaries around ordinals)
    for (final ordinal in ordinals) {
      final ordinalPattern = RegExp(r'\b' + RegExp.escape(ordinal.toLowerCase()) + r'\b');
      if (ordinalPattern.hasMatch(textLower)) {
        return true;
      }
    }

    return false;
  }

  void filterByCategory(OhyoCategory? category) {
    state = state.copyWith(selectedCategory: category);

    if (category == null || category == OhyoCategory.all) {
      // Show all, but still apply search filter if present
      if (state.searchQuery.isNotEmpty) {
        searchOhyos(state.searchQuery);
      } else {
        state = state.copyWith(filteredOhyos: state.ohyos);
      }
      return;
    }

    final filtered = state.ohyos.where((ohyo) {
      final ohyoCategory = OhyoCategory.fromStyle(ohyo.style);
      final matchesCategory = ohyoCategory == category;

      // Also apply search filter if present
      if (state.searchQuery.isNotEmpty) {
        final normalizedQuery = SearchUtils.normalizeSearchText(state.searchQuery);
        // Check if query is purely numeric (contains only digits)
        final isNumericQuery = RegExp(r'^\d+$').hasMatch(normalizedQuery);
        
        // Check if query matches patterns like "ohyo5", "ohyo-5", "ohyo.5", "o5", "o-5", "o 5", "05", "0 5", "o7", "o8", etc.
        // Unified pattern that matches all variations: "ohyo7", "o7", "07", "o 7", "o-7", etc.
        String? extractedNumber;
        
        final ohyoNumberPattern = RegExp(r'^(?:ohyo|o|0)[\s\-\._]?(\d+)$', caseSensitive: false);
        
        // Try matching on normalized query first
        var match = ohyoNumberPattern.firstMatch(normalizedQuery);
        extractedNumber = match?.group(1);
        
        // If no match, try original query (before normalization)
        if (extractedNumber == null) {
          final trimmedQuery = state.searchQuery.trim().toLowerCase();
          match = ohyoNumberPattern.firstMatch(trimmedQuery);
          extractedNumber = match?.group(1);
        }
        
        bool matchesQuery = false;
        final searchNumber = extractedNumber ?? (isNumericQuery ? normalizedQuery : null);
        
        if (searchNumber != null) {
          // For numeric queries, use exact number matching
          final ordinals = _getOrdinalForms(searchNumber);
          final nameNormalized = SearchUtils.normalizeSearchText(ohyo.name);
          
          matchesQuery = ohyo.order.toString() == searchNumber ||
                         ohyo.id.toString() == searchNumber ||
                         _matchesExactNumber(nameNormalized, searchNumber, ordinals);
        } else {
          // For text queries, use normalized matching
          final nameNormalized = SearchUtils.normalizeSearchText(ohyo.name);
          final descNormalized = SearchUtils.normalizeSearchText(ohyo.description);
          final styleNormalized = SearchUtils.normalizeSearchText(ohyo.style);
          
          matchesQuery = nameNormalized.startsWith(normalizedQuery) ||
                         nameNormalized.contains(normalizedQuery) ||
                         descNormalized.contains(normalizedQuery) ||
                         styleNormalized.contains(normalizedQuery);
        }

        return matchesCategory && matchesQuery;
      }

      return matchesCategory;
    }).toList();

    state = state.copyWith(filteredOhyos: filtered);
  }

  Future<void> createOhyo({
    required String name,
    required String description,
    required String style,
    List<File>? images,
    List<String>? videoUrls,
  }) async {
    debugPrint('🔄 Starting ohyo creation process...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          debugPrint('📝 Inserting ohyo into database...');
          debugPrint('  Data: {name: $name, description: $description, style: $style, video_urls: $videoUrls, order: ${state.ohyos.length}}');

          // Insert ohyo into database
          debugPrint('🔍 About to make database insert call...');

          // Force refresh the client connection
          debugPrint('🔄 Refreshing Supabase client...');
          final freshClient = SupabaseClientManager().client;

          // Prepare the insert data explicitly
          final insertData = <String, dynamic>{
            'name': name,
            'description': description,
            'style': style,
            'video_urls': videoUrls ?? [],
            'order': state.ohyos.length,
          };

          debugPrint('📤 Insert data prepared: $insertData');

          final response = await freshClient
              .from("ohyo")
              .insert(insertData)
              .select()
              .single();

          debugPrint('📥 Raw response received: $response');

          debugPrint('✅ Database insert successful: $response');
          final newOhyo = Ohyo.fromMap(response);
          debugPrint('📦 Created ohyo object: ${newOhyo.toString()}');

          // Upload images if provided
          if (images != null && images.isNotEmpty) {
            debugPrint('🖼️ Uploading ${images.length} images...');
            await ImageUtils.uploadOhyoImages(images, newOhyo.id);
            debugPrint('✅ Images uploaded successfully');
          }

          // Reload ohyos to get the updated list
          debugPrint('🔄 Reloading ohyos list...');
          await loadOhyos();
          debugPrint('✅ Ohyos reloaded successfully');
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Silent: Retry attempts are not logged to reduce spam
        },
      );
      debugPrint('🎉 Ohyo creation completed successfully!');
    } catch (e) {
      debugPrint('💥 Error during ohyo creation: $e');
      final errorMessage = 'Failed to create ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> updateOhyo(
    int ohyoId, {
    String? name,
    String? description,
    String? style,
    List<File>? newImages,
    List<String>? videoUrls,
    bool? removeAllImages,
    List<String>? deletedImageUrls,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Prepare update data - only update specific fields, not user-related fields
          final updateData = <String, dynamic>{};
          if (name != null) updateData['name'] = name;
          if (description != null) updateData['description'] = description;
          if (style != null) updateData['style'] = style;
          if (videoUrls != null) updateData['video_urls'] = videoUrls;

          // Update database
          await _supabase
              .from("ohyo")
              .update(updateData)
              .eq('id', ohyoId);

          // Handle image operations
          if (removeAllImages == true) {
            await ImageUtils.deleteOhyoImages(ohyoId);
          }

          // Delete specific images if provided
          if (deletedImageUrls != null && deletedImageUrls.isNotEmpty) {
            // Extract filenames from URLs for deletion
            final filenamesToDelete = deletedImageUrls.map((url) {
              final uri = Uri.parse(url);
              final segments = uri.pathSegments;
              if (segments.length >= 2) {
                return '${segments[segments.length - 2]}/${segments.last}';
              }
              return '';
            }).where((name) => name.isNotEmpty).toList();

            if (filenamesToDelete.isNotEmpty) {
              await ImageUtils.deleteMultipleImagesFromSupabase(filenamesToDelete);
            }
          }

          if (newImages != null && newImages.isNotEmpty) {
            await ImageUtils.uploadOhyoImages(newImages, ohyoId);
          }

          // Reload ohyos to get the updated list
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for updating ohyo
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to update ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> deleteOhyo(int ohyoId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Delete images first
          await ImageUtils.deleteOhyoImages(ohyoId);

          // Delete ohyo from database
          await _supabase
              .from("ohyo")
              .delete()
              .eq('id', ohyoId);

          // Reload ohyos to get the updated list
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for deleting ohyo
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to delete ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset the ohyo tab to its initial state (clear search, filters, etc.)
  void resetOhyoTab() {
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: null,
      filteredOhyos: state.ohyos, // Reset to show all ohyos
    );
  }

  Future<void> reorderOhyos(List<Ohyo> reorderedOhyos) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Update local state first for immediate UI feedback
          final updatedOhyos = List<Ohyo>.from(reorderedOhyos);
          state = state.copyWith(
            ohyos: updatedOhyos,
            filteredOhyos: updatedOhyos,
            isLoading: false,
          );

          // Update database in background
          await _updateOhyoOrdersInDatabase(updatedOhyos);

          // If database update fails, reload from database
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for reordering ohyos
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to reorder ohyos: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> _updateOhyoOrdersInDatabase(List<Ohyo> ohyos) async {
    await RetryUtils.executeWithRetry(
      () async {
        for (final ohyo in ohyos) {
          await _supabase
              .from("ohyo")
              .update({'order': ohyo.order})
              .eq('id', ohyo.id);
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryError,
      onRetry: (attempt, error) {
        // Retry attempt for updating ohyo orders
      },
    );
  }

  /// Clean up orphaned images that don't belong to any existing ohyo
  /// SAFE cleanup function - only removes specific temporary folders
  /// This is much safer than the previous cleanup function
  Future<List<String>> safeCleanupTempFolders() async {
    try {
      // Use the safe cleanup function that only targets known temporary folders
      final deletedPaths = await ImageUtils.safeCleanupTempFolders();

      // Cleanup completed successfully

      return deletedPaths;
    } catch (e) {
      final errorMessage = 'Failed to cleanup temporary folders: ${e.toString()}';
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> _preloadInitialOhyoImagesWithCache(List<Ohyo> initialOhyos) async {
    // Preload images for better UX - prioritize cached images when offline
    for (final ohyo in initialOhyos) {
      try {
        // First, try to load cached images immediately
        final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyo.id);
        if (cachedImageUrls.isNotEmpty) {
          debugPrint('🏠 Preloaded ${cachedImageUrls.length} cached images for ohyo ${ohyo.id}');

          // Update the ohyo in the state with cached images
          final updatedOhyos = state.ohyos.map((o) {
            if (o.id == ohyo.id) {
              return o.copyWith(imageUrls: cachedImageUrls);
            }
            return o;
          }).toList();

          final updatedFilteredOhyos = state.filteredOhyos.map((o) {
            if (o.id == ohyo.id) {
              return o.copyWith(imageUrls: cachedImageUrls);
            }
            return o;
          }).toList();

          state = state.copyWith(
            ohyos: updatedOhyos,
            filteredOhyos: updatedFilteredOhyos,
          );
          continue; // Skip online fetch if we have cached images
        }

        // If no cached images, try online fetch (will cache them)
        await ImageUtils.fetchOhyoImagesFromBucket(ohyo.id);
      } catch (e) {
        // Silently fail - images will be loaded when needed
        debugPrint('Failed to preload ohyo images for ohyo ${ohyo.id}: $e');
      }
    }
  }

  // Preload likes for all ohyos to ensure offline availability
  Future<void> _preloadOhyoLikes(List<Ohyo> ohyos) async {
    try {
      // Load likes for all ohyos in parallel to speed up the process
      final likeFutures = ohyos.map((ohyo) async {
        try {
          final likes = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.getOhyoLikes(ohyo.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          final isLiked = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.isOhyoLiked(ohyo.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          return {
            'ohyoId': ohyo.id,
            'likes': likes,
            'isLiked': isLiked,
          };
        } catch (e) {
          // If loading likes fails, return null data
          return {
            'ohyoId': ohyo.id,
            'likes': <dynamic>[],
            'isLiked': false,
          };
        }
      });

      final likeResults = await Future.wait(likeFutures);

      // Update cached data with likes information
      for (final result in likeResults) {
        final ohyoId = result['ohyoId'] as int;
        final likes = result['likes'] as List;
        final isLiked = result['isLiked'] as bool;

        // Update the cached ohyo with likes data
        final cachedOhyo = app_storage.LocalStorage.getOhyo(ohyoId);
        if (cachedOhyo != null) {
          final updatedOhyo = app_storage.CachedOhyo(
            id: cachedOhyo.id,
            name: cachedOhyo.name,
            description: cachedOhyo.description,
            createdAt: cachedOhyo.createdAt,
            lastSynced: DateTime.now(),
            imageUrls: cachedOhyo.imageUrls,
            style: cachedOhyo.style,
            isFavorite: cachedOhyo.isFavorite,
            needsSync: cachedOhyo.needsSync,
            isLiked: isLiked,
            likeCount: likes.length,
          );
          await app_storage.LocalStorage.saveOhyo(updatedOhyo);
        }
      }

      // Reduced spam: Only log if there were errors or significant issues
    } catch (e) {
      debugPrint('⚠️ Failed to preload ohyo likes: $e');
      // Don't throw - likes preloading failure shouldn't break the app
    }
  }
}

// Provider for the OhyoNotifier
final ohyoNotifierProvider = StateNotifierProvider<OhyoNotifier, OhyoState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  final notifier = OhyoNotifier(errorBoundary, ref);

  // Initialize offline service if available (catch errors if not initialized yet)
  try {
    final offlineOhyoService = ref.watch(offlineOhyoServiceProvider);
    notifier.initializeOfflineService(offlineOhyoService);
  } catch (e) {
    // Offline service not available yet, will be initialized later
  }

  return notifier;
});

// Convenience providers for specific ohyo state properties
final ohyosProvider = Provider<List<Ohyo>>((ref) {
  return ref.watch(ohyoNotifierProvider).filteredOhyos;
});

final ohyoLoadingProvider = Provider<bool>((ref) {
  return ref.watch(ohyoNotifierProvider).isLoading;
});

final ohyoOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(ohyoNotifierProvider).isOfflineMode;
});

final ohyoErrorProvider = Provider<String?>((ref) {
  return ref.watch(ohyoNotifierProvider).error;
});

final ohyoSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(ohyoNotifierProvider).searchQuery;
});

final ohyoSelectedCategoryProvider = Provider<OhyoCategory?>((ref) {
  return ref.watch(ohyoNotifierProvider).selectedCategory;
});

// Family provider for individual ohyo by ID
final ohyoByIdProvider = Provider.family<Ohyo?, int>((ref, ohyoId) {
  final ohyos = ref.watch(ohyoNotifierProvider).ohyos;
  try {
    return ohyos.firstWhere((ohyo) => ohyo.id == ohyoId);
  } catch (e) {
    return null;
  }
});

// Family provider for ohyo images
final ohyoImagesProvider = FutureProvider.family<List<String>, int>((ref, ohyoId) async {
  return await ImageUtils.fetchOhyoImagesFromBucket(ohyoId, ref: ref);
});
