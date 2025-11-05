import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../models/interaction_models.dart';
import '../../providers/interaction_provider.dart';
import '../overflow_safe_widgets.dart';
import '../avatar_widget.dart';
import 'kata_card_comments.dart';

class KataCardInteractions extends StatefulWidget {
  final Kata kata;

  const KataCardInteractions({
    super.key,
    required this.kata,
  });

  @override
  State<KataCardInteractions> createState() => _KataCardInteractionsState();
}

class _KataCardInteractionsState extends State<KataCardInteractions> {
  bool _isCommentsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return _buildInteractionSection();
  }

  Widget _buildInteractionSection() {
    return Consumer(
      builder: (context, ref, child) {
        final interactionState = ref.watch(kataInteractionProvider(widget.kata.id));
        final isLiked = interactionState.isLiked;
        final isFavorited = interactionState.isFavorited;
        final likeCount = interactionState.likeCount;
        final commentCount = interactionState.commentCount;
        final comments = interactionState.comments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons row
            OverflowSafeRow(
              children: [
                // Like button
                IconButton(
                  onPressed: () async {
                    try {
                      await ref.read(kataInteractionProvider(widget.kata.id).notifier).toggleLike();
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                ),
                OverflowSafeText('$likeCount'),
                const SizedBox(width: 16),

                // Favorite button
                IconButton(
                  onPressed: () async {
                    try {
                      await ref.read(kataInteractionProvider(widget.kata.id).notifier).toggleFavorite();
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorited
                                ? 'Removed from favorites'
                                : 'Added to favorites'
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorited ? Colors.teal : Colors.grey,
                  ),
                ),

                const SizedBox(width: 16),

                // Comment button - Opens comment section
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = !_isCommentsExpanded;
                    });
                  },
                  icon: Icon(
                    _isCommentsExpanded ? Icons.comment : Icons.comment_outlined,
                    color: Colors.blue,
                  ),
                  tooltip: _isCommentsExpanded ? 'Sluit reacties' : 'Open reacties',
                ),
                OverflowSafeText('$commentCount'),

                const OverflowSafeSpacer(),
              ],
            ),

            // Show inline comments section when expanded
            if (_isCommentsExpanded) ...[
              const SizedBox(height: 12),
              KataCardComments(
                kata: widget.kata,
                comments: comments,
                isLoading: interactionState.isLoading,
                onCollapse: () {
                  setState(() {
                    _isCommentsExpanded = false;
                  });
                },
              ),
            ] else if (comments.isNotEmpty) ...[
              // Show first few comments inline if any
              const SizedBox(height: 8),
              ...comments.take(2).map((comment) => _buildClickableCommentPreview(comment)),
              if (comments.length > 2)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = true;
                    });
                  },
                  child: Text('Bekijk alle ${comments.length} reacties'),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildClickableCommentPreview(KataComment comment) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCommentsExpanded = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade400,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              customAvatarUrl: comment.authorAvatar,
              userName: comment.authorName,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: '${comment.authorName} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: comment.content, // Show full comment content
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}