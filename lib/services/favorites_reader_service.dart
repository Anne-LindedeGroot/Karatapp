import '../models/kata_model.dart';
import '../models/forum_models.dart';
import '../providers/accessibility_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesReaderService {
  final Ref _ref;
  bool _isReading = false;

  FavoritesReaderService(this._ref);

  void stopReading() {
    _isReading = false;
    final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
    accessibilityNotifier.stopSpeaking();
  }

  /// Read only the Katas tab content with Dutch TTS
  Future<void> readKatasTab(List<Kata> favoriteKatas) async {
    if (_isReading) {
      stopReading();
      return;
    }
    
    _isReading = true;
    
    try {
      final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
      
      // If no favorite katas
      if (favoriteKatas.isEmpty) {
        await accessibilityNotifier.speak('Nog geen favoriete kata\'s');
        _isReading = false;
        return;
      }

      // First read the tab heading: "Katas (number)"
      await accessibilityNotifier.speak('Kata\'s ${favoriteKatas.length}');
      
      if (!_isReading) return;
      
      // Wait for TTS to finish before proceeding
      while (accessibilityNotifier.isSpeaking() && _isReading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!_isReading) return;
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Read each kata completely one by one
      for (int i = 0; i < favoriteKatas.length && _isReading; i++) {
        final kata = favoriteKatas[i];
        
        // Announce kata number
        await accessibilityNotifier.speak('Kata ${i + 1}');
        
        if (!_isReading) return;
        
        // Wait for kata number to finish
        while (accessibilityNotifier.isSpeaking() && _isReading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (!_isReading) return;
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Build the COMPLETE kata content
        final content = StringBuffer();
        
        // Always add the kata name first
        content.write('${kata.name}. ');
        
        // Add style if available and not empty
        if (kata.style.isNotEmpty) {
          content.write('Stijl: ${kata.style}. ');
        }
        
        // Add description if available and not empty
        if (kata.description.isNotEmpty) {
          content.write('Beschrijving: ${kata.description}. ');
        }
        
        // Add video information if available
        if (kata.videoUrls != null && kata.videoUrls!.isNotEmpty) {
          if (kata.videoUrls!.length == 1) {
            content.write('Er is 1 video beschikbaar voor deze kata. ');
          } else {
            content.write('Er zijn ${kata.videoUrls!.length} video\'s beschikbaar voor deze kata. ');
          }
        }
        
        // Add image information if available
        if (kata.imageUrls != null && kata.imageUrls!.isNotEmpty) {
          if (kata.imageUrls!.length == 1) {
            content.write('Er is 1 afbeelding beschikbaar. ');
          } else {
            content.write('Er zijn ${kata.imageUrls!.length} afbeeldingen beschikbaar. ');
          }
        }
        
        // Add creation date
        final createdDate = _formatDateForSpeaking(kata.createdAt);
        content.write('Aangemaakt op $createdDate.');
        
        final fullContent = content.toString();
        print('DEBUG: Reading kata content: $fullContent'); // Debug logging
        
        // Read the complete kata content
        await accessibilityNotifier.speak(fullContent);
        
        if (!_isReading) return;
        
        // Wait for content to finish reading before continuing
        while (accessibilityNotifier.isSpeaking() && _isReading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (!_isReading) return;
        
        // Pause before next kata (only if there is a next kata)
        if (i < favoriteKatas.length - 1) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }
      
      if (!_isReading) return;
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Final message for katas tab
      if (_isReading) {
        await accessibilityNotifier.speak('Klaar met voorlezen van alle favoriete kata\'s.');
      }
      
    } catch (e) {
      print('ERROR in readKatasTab: $e'); // Debug logging
      if (_isReading) {
        final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Fout bij het voorlezen van kata favorieten.');
      }
    } finally {
      _isReading = false;
    }
  }

  /// Read only the Forum tab content with Dutch TTS
  Future<void> readForumTab(List<ForumPost> favoriteForumPosts) async {
    if (_isReading) {
      stopReading();
      return;
    }
    
    _isReading = true;
    
    try {
      final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
      
      // If no favorite forum posts
      if (favoriteForumPosts.isEmpty) {
        await accessibilityNotifier.speak('Nog geen favoriete forumberichten');
        _isReading = false;
        return;
      }

      // First read the tab heading: "Forumberichten (number)"
      await accessibilityNotifier.speak('Forumberichten ${favoriteForumPosts.length}');
      
      if (!_isReading) return;
      
      // Wait for TTS to finish before proceeding
      while (accessibilityNotifier.isSpeaking() && _isReading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!_isReading) return;
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Read each forum post completely one by one
      for (int i = 0; i < favoriteForumPosts.length && _isReading; i++) {
        final post = favoriteForumPosts[i];
        
        // Announce forum post number
        await accessibilityNotifier.speak('Forumbericht ${i + 1}');
        
        if (!_isReading) return;
        
        // Wait for post number to finish
        while (accessibilityNotifier.isSpeaking() && _isReading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (!_isReading) return;
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Build the COMPLETE forum post content
        final content = StringBuffer();
        
        // Add category
        content.write('${post.category.displayName}. ');
        
        // Add pinned/locked status
        if (post.isPinned) {
          content.write('Dit bericht is vastgezet. ');
        }
        
        if (post.isLocked) {
          content.write('Dit bericht is vergrendeld. ');
        }
        
        // Add title and content
        content.write('${post.title}. ');
        content.write('${post.content}. ');
        
        // Add author information
        content.write('Geplaatst door ${post.authorName}. ');
        
        // Add comment count
        if (post.commentCount > 0) {
          if (post.commentCount == 1) {
            content.write('Er is 1 reactie op dit bericht. ');
          } else {
            content.write('Er zijn ${post.commentCount} reacties op dit bericht. ');
          }
        } else {
          content.write('Er zijn nog geen reacties op dit bericht. ');
        }
        
        // Add creation date
        final createdDate = _formatDateForSpeaking(post.createdAt);
        content.write('Geplaatst op $createdDate.');
        
        final fullContent = content.toString();
        print('DEBUG: Reading forum post content: $fullContent'); // Debug logging
        
        // Read the complete forum post content
        await accessibilityNotifier.speak(fullContent);
        
        if (!_isReading) return;
        
        // Wait for content to finish reading before continuing
        while (accessibilityNotifier.isSpeaking() && _isReading) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        if (!_isReading) return;
        
        // Pause before next post (only if there is a next post)
        if (i < favoriteForumPosts.length - 1) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }
      
      if (!_isReading) return;
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Final message for forum tab
      if (_isReading) {
        await accessibilityNotifier.speak('Klaar met voorlezen van alle favoriete forumberichten.');
      }
      
    } catch (e) {
      print('ERROR in readForumTab: $e'); // Debug logging
      if (_isReading) {
        final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Fout bij het voorlezen van forum favorieten.');
      }
    } finally {
      _isReading = false;
    }
  }

  /// Read ALL favorites - both katas and forum posts in one session
  Future<void> readAllFavorites(List<Kata> favoriteKatas, List<ForumPost> favoriteForumPosts) async {
    if (_isReading) {
      stopReading();
      return;
    }
    
    _isReading = true;
    
    try {
      final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
      
      // If no favorites at all
      if (favoriteKatas.isEmpty && favoriteForumPosts.isEmpty) {
        await accessibilityNotifier.speak('Je hebt nog geen favorieten toegevoegd.');
        return;
      }

      // Read favorite katas first
      if (favoriteKatas.isNotEmpty && _isReading) {
        // Announce: "Katas (number)"
        await accessibilityNotifier.speak('Kata\'s ${favoriteKatas.length}');
        
        if (!_isReading) return;
        
        // Read each kata completely in one go
        for (int i = 0; i < favoriteKatas.length && _isReading; i++) {
          final kata = favoriteKatas[i];
          
          // Announce kata number
          await accessibilityNotifier.speak('Kata ${i + 1}');
          
          if (!_isReading) return;
          
          // Read the WHOLE kata content as one unit
          final content = StringBuffer();
          content.write('${kata.name}. ');
          
          // Add style if available and not empty
          if (kata.style.isNotEmpty) {
            content.write('Stijl: ${kata.style}. ');
          }
          
          // Add description if available and not empty
          if (kata.description.isNotEmpty) {
            content.write('Beschrijving: ${kata.description}. ');
          }
          
          if (kata.videoUrls != null && kata.videoUrls!.isNotEmpty) {
            content.write('Er zijn ${kata.videoUrls!.length} video\'s beschikbaar voor deze kata. ');
          }
          
          if (kata.imageUrls != null && kata.imageUrls!.isNotEmpty) {
            content.write('Er zijn ${kata.imageUrls!.length} afbeeldingen beschikbaar. ');
          }
          
          final createdDate = _formatDateForSpeaking(kata.createdAt);
          content.write('Aangemaakt op $createdDate.');
          
          // Read the complete kata content
          await accessibilityNotifier.speak(content.toString());
          
          if (!_isReading) return;
          
          // Short pause before next kata
          if (i < favoriteKatas.length - 1 && _isReading) {
            await Future.delayed(const Duration(milliseconds: 1200));
          }
        }
        
        // Pause between katas and forum posts
        if (favoriteForumPosts.isNotEmpty && _isReading) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }

      // Read favorite forum posts
      if (favoriteForumPosts.isNotEmpty && _isReading) {
        // Announce: "Forum berichten (number)"
        await accessibilityNotifier.speak('Forum berichten ${favoriteForumPosts.length}');
        
        if (!_isReading) return;
        
        // Read each forum post completely in one go
        for (int i = 0; i < favoriteForumPosts.length && _isReading; i++) {
          final post = favoriteForumPosts[i];
          
          // Announce forum post number
          await accessibilityNotifier.speak('Forum bericht ${i + 1}');
          
          if (!_isReading) return;
          
          // Read the WHOLE forum post content as one unit
          final content = StringBuffer();
          content.write('${post.category.displayName}. ');
          
          if (post.isPinned) {
            content.write('Dit bericht is vastgezet. ');
          }
          
          if (post.isLocked) {
            content.write('Dit bericht is vergrendeld. ');
          }
          
          content.write('${post.title}. ');
          content.write('${post.content}. ');
          content.write('Geplaatst door ${post.authorName}. ');
          
          if (post.commentCount > 0) {
            content.write('Er zijn ${post.commentCount} reacties op dit bericht. ');
          } else {
            content.write('Er zijn nog geen reacties op dit bericht. ');
          }
          
          final createdDate = _formatDateForSpeaking(post.createdAt);
          content.write('Geplaatst op $createdDate.');
          
          // Read the complete forum post content
          await accessibilityNotifier.speak(content.toString());
          
          if (!_isReading) return;
          
          // Short pause before next post
          if (i < favoriteForumPosts.length - 1 && _isReading) {
            await Future.delayed(const Duration(milliseconds: 1200));
          }
        }
      }
      
      // Final message - be specific about what was read
      if (_isReading) {
        if (favoriteKatas.isNotEmpty && favoriteForumPosts.isNotEmpty) {
          await accessibilityNotifier.speak('Klaar met voorlezen van alle favorieten.');
        } else if (favoriteKatas.isNotEmpty) {
          await accessibilityNotifier.speak('Klaar met het voorlezen van alle favoriete kata\'s.');
        } else if (favoriteForumPosts.isNotEmpty) {
          await accessibilityNotifier.speak('Klaar met het voorlezen van alle favoriete forumberichten.');
        }
      }
      
    } catch (e) {
      if (_isReading) {
        final accessibilityNotifier = _ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Fout bij het voorlezen van favorieten: ${e.toString()}');
      }
    } finally {
      _isReading = false;
    }
  }

  /// Read favorite katas only - kept for backward compatibility
  Future<void> readFavoriteKatas(List<Kata> favoriteKatas) async {
    await readAllFavorites(favoriteKatas, []);
  }

  /// Read favorite forum posts only - kept for backward compatibility
  Future<void> readFavoriteForumPosts(List<ForumPost> favoriteForumPosts) async {
    await readAllFavorites([], favoriteForumPosts);
  }

  /// Format date for speech
  String _formatDateForSpeaking(DateTime date) {
    final months = [
      'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool get isReading => _isReading;
}

// Provider for the FavoritesReaderService
final favoritesReaderServiceProvider = Provider<FavoritesReaderService>((ref) {
  return FavoritesReaderService(ref);
});
