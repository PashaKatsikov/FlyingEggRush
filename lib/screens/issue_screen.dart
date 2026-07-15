import 'package:flutter/material.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';
import 'readers.dart';
import 'word_search_screen.dart';
import 'quiz_screen.dart';

/// Table of contents for a single issue.
class IssueScreen extends StatelessWidget {
  const IssueScreen({super.key, required this.issue});
  final Issue issue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final read = store.issueReadCount(issue);
          final total = issue.rubrics.length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _banner(context, read, total)),
              CenteredSliver(
                maxWidth: 640,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: SectionChip(
                      label: 'In This Issue',
                      color: AppColors.folkBlue,
                    ),
                  ),
                ),
              ),
              CenteredSliver(
                maxWidth: 640,
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 36),
                  sliver: SliverList.separated(
                    itemCount: issue.rubrics.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final kind = issue.rubrics[i];
                      return _RubricCard(
                        issue: issue,
                        kind: kind,
                        index: i + 1,
                        onTap: () => openRubric(context, issue, kind),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _banner(BuildContext context, int read, int total) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(issue.coverColor, Colors.white, 0.12)!,
            Color.lerp(issue.coverColor, Colors.black, 0.4)!,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -30,
              child: Text(
                issue.coverEmoji,
                style: TextStyle(
                  fontSize: 170,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 18, 22),
              child: ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 40,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Masthead(
                            size: 15,
                            color: Colors.white,
                            onPaper: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ISSUE No. ${issue.number} · ${issue.dateLine}',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 1,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            issue.title,
                            style: AppText.masthead(36, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            issue.tagline,
                            style: AppText.serif(
                              15,
                              color: Colors.white,
                              style: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : read / total,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$read of $total pages read',
                            style: AppText.serif(13, color: Colors.white),
                          ),
                        ],
                      ),
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

/// Sends the reader to the right screen for a rubric.
void openRubric(BuildContext context, Issue issue, RubricKind kind) {
  Widget screen;
  switch (kind) {
    case RubricKind.story:
      screen = StoryReader(issue: issue);
      break;
    case RubricKind.breed:
      screen = BreedReader(issue: issue);
      break;
    case RubricKind.facts:
      screen = FactsReader(issue: issue);
      break;
    case RubricKind.comic:
      screen = ComicReader(issue: issue);
      break;
    case RubricKind.recipe:
      screen = RecipeReader(issue: issue);
      break;
    case RubricKind.wordSearch:
      screen = WordSearchScreen(issue: issue);
      break;
    case RubricKind.quiz:
      screen = QuizScreen(issue: issue);
      break;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

String _teaser(Issue issue, RubricKind kind) {
  switch (kind) {
    case RubricKind.story:
      return '${issue.story.flag}  ${issue.story.title}';
    case RubricKind.breed:
      return issue.breed.name;
    case RubricKind.facts:
      return '${issue.facts.length} egg-cellent facts';
    case RubricKind.comic:
      return issue.comic.title;
    case RubricKind.recipe:
      return issue.recipe.title;
    case RubricKind.wordSearch:
      return issue.wordSearch.title;
    case RubricKind.quiz:
      return issue.quiz.title;
  }
}

class _RubricCard extends StatelessWidget {
  const _RubricCard({
    required this.issue,
    required this.kind,
    required this.index,
    required this.onTap,
  });

  final Issue issue;
  final RubricKind kind;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = issue.rubricId(kind);
    final read = store.isRead(id);
    final solved = store.isSolved(id);
    final accent = kind.isInteractive ? AppColors.teal : AppColors.cherry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paperEdge, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(kind.icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kind.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _teaser(issue, kind),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.masthead(18, color: AppColors.ink),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (kind.isInteractive && solved)
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.deepGold,
                size: 24,
              )
            else if (read)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.leaf,
                size: 24,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
                size: 26,
              ),
          ],
        ),
      ),
    );
  }
}
