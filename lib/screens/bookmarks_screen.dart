import 'package:flutter/material.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import 'readers.dart';

/// Lists every tale the reader has bookmarked, for quick re-reading.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = kIssues
            .where((i) => store.isBookmarked(i.rubricId(RubricKind.story)))
            .toList();
        return MagazinePage(
          sectionLabel: 'Bookmarks',
          title: 'Saved Tales',
          accent: AppColors.deepGold,
          child: saved.isEmpty
              ? _empty()
              : Column(
                  children: [
                    for (final issue in saved)
                      _SavedRow(
                        issue: issue,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => StoryReader(issue: issue)),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Text('🔖', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No bookmarks yet',
              style: AppText.masthead(22, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(
            'Tap the ribbon on any folk tale to save it here for later.',
            textAlign: TextAlign.center,
            style: AppText.serif(15, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.issue, required this.onTap});
  final Issue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = issue.story;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.paperEdge, width: 1.5),
          ),
          child: Row(
            children: [
              Text(s.flag, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title,
                        style: AppText.masthead(18, color: AppColors.ink)),
                    Text('Issue No. ${issue.number} · ${s.origin}',
                        style: AppText.serif(12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.inkSoft, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
