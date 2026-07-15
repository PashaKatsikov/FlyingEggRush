import 'package:flutter/material.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

/// Marks a rubric as read as soon as the reader opens.
mixin _MarkRead<T extends StatefulWidget> on State<T> {
  void markReadOnce(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) => store.markRead(id));
  }
}

// ── FOLK TALE ───────────────────────────────────────────────────────────
class StoryReader extends StatefulWidget {
  const StoryReader({super.key, required this.issue});
  final Issue issue;
  @override
  State<StoryReader> createState() => _StoryReaderState();
}

class _StoryReaderState extends State<StoryReader> with _MarkRead {
  late final String _id = widget.issue.rubricId(RubricKind.story);

  @override
  void initState() {
    super.initState();
    markReadOnce(_id);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.issue.story;
    return MagazinePage(
      sectionLabel: RubricKind.story.label,
      title: s.title,
      subtitle: '${s.flag}  ${s.origin}',
      accent: AppColors.cherry,
      actions: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) => RoundIconButton(
            icon: store.isBookmarked(_id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: AppColors.deepGold,
            size: 40,
            onTap: () => store.toggleBookmark(_id),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropCapText(paragraphs: s.paragraphs, accent: AppColors.cherry),
          const SizedBox(height: 22),
          MoralBox(text: s.moral),
          const SizedBox(height: 24),
          const _TheEnd(),
        ],
      ),
    );
  }
}

class _TheEnd extends StatelessWidget {
  const _TheEnd();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('THE END',
                    style: AppText.masthead(16, color: AppColors.inkSoft)),
              ),
              _dot(),
            ],
          ),
          const SizedBox(height: 6),
          const Text('🐔', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _dot() => Container(
        width: 26,
        height: 2,
        color: AppColors.paperEdge,
      );
}

// ── BREED OF THE MONTH ──────────────────────────────────────────────────
class BreedReader extends StatefulWidget {
  const BreedReader({super.key, required this.issue});
  final Issue issue;
  @override
  State<BreedReader> createState() => _BreedReaderState();
}

class _BreedReaderState extends State<BreedReader> with _MarkRead {
  @override
  void initState() {
    super.initState();
    markReadOnce(widget.issue.rubricId(RubricKind.breed));
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.issue.breed;
    return MagazinePage(
      sectionLabel: RubricKind.breed.label,
      title: b.name,
      subtitle: b.origin,
      accent: b.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  b.accent.withValues(alpha: 0.18),
                  b.accent.withValues(alpha: 0.02),
                ]),
              ),
              child: Image.asset(b.asset, height: 200),
            ),
          ),
          const SizedBox(height: 16),
          Text(b.blurb, style: AppText.serif(17, style: FontStyle.italic)),
          const SizedBox(height: 20),
          for (final f in b.facts) _Bullet(text: f, color: b.accent),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, this.color = AppColors.cherry});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.egg_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.serif(16))),
        ],
      ),
    );
  }
}

// ── DID YOU KNOW ────────────────────────────────────────────────────────
class FactsReader extends StatefulWidget {
  const FactsReader({super.key, required this.issue});
  final Issue issue;
  @override
  State<FactsReader> createState() => _FactsReaderState();
}

class _FactsReaderState extends State<FactsReader> with _MarkRead {
  @override
  void initState() {
    super.initState();
    markReadOnce(widget.issue.rubricId(RubricKind.facts));
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.issue.facts;
    return MagazinePage(
      sectionLabel: RubricKind.facts.label,
      title: 'Egg-cellent Facts',
      subtitle: 'True tales from the coop.',
      accent: AppColors.folkBlue,
      child: Column(
        children: [
          for (int i = 0; i < facts.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.paperEdge, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.folkBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Georgia')),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(facts[i], style: AppText.serif(16))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── COMIC STRIP ─────────────────────────────────────────────────────────
class ComicReader extends StatefulWidget {
  const ComicReader({super.key, required this.issue});
  final Issue issue;
  @override
  State<ComicReader> createState() => _ComicReaderState();
}

class _ComicReaderState extends State<ComicReader> with _MarkRead {
  @override
  void initState() {
    super.initState();
    markReadOnce(widget.issue.rubricId(RubricKind.comic));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.issue.comic;
    return MagazinePage(
      sectionLabel: RubricKind.comic.label,
      title: c.title,
      accent: AppColors.leaf,
      child: Column(
        children: [
          for (int i = 0; i < c.panels.length; i++)
            _Panel(index: i + 1, panel: c.panels[i]),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.index, required this.panel});
  final int index;
  final ComicPanel panel;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE0F0), Color(0xFFEFE3C4)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.ink, shape: BoxShape.circle),
                    child: Text('$index',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ),
                ),
                Center(
                    child: Text(panel.emoji,
                        style: const TextStyle(fontSize: 68))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(panel.caption,
                style: AppText.serif(16, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── RECIPE ──────────────────────────────────────────────────────────────
class RecipeReader extends StatefulWidget {
  const RecipeReader({super.key, required this.issue});
  final Issue issue;
  @override
  State<RecipeReader> createState() => _RecipeReaderState();
}

class _RecipeReaderState extends State<RecipeReader> with _MarkRead {
  @override
  void initState() {
    super.initState();
    markReadOnce(widget.issue.rubricId(RubricKind.recipe));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.issue.recipe;
    return MagazinePage(
      sectionLabel: RubricKind.recipe.label,
      title: r.title,
      subtitle: r.subtitle,
      accent: AppColors.deepGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(r.emoji, style: const TextStyle(fontSize: 72))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _meta(Icons.schedule_rounded, '${r.minutes} min'),
              const SizedBox(width: 12),
              _meta(Icons.bar_chart_rounded, r.difficulty),
            ],
          ),
          const SizedBox(height: 22),
          Text('Ingredients', style: AppText.masthead(20, color: AppColors.ink)),
          const SizedBox(height: 10),
          for (final ing in r.ingredients) _Bullet(text: ing, color: AppColors.deepGold),
          const SizedBox(height: 16),
          Text('Steps', style: AppText.masthead(20, color: AppColors.ink)),
          const SizedBox(height: 10),
          for (int i = 0; i < r.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.deepGold, shape: BoxShape.circle),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Georgia',
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.steps[i], style: AppText.serif(16))),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.deepGold, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('👩‍🍳', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Chef’s tip: ${r.tip}',
                      style: AppText.serif(15, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Always ask a grown-up for help in the kitchen.',
              style: AppText.serif(13,
                  color: AppColors.inkSoft, style: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperEdge, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(label,
              style: AppText.serif(14, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
