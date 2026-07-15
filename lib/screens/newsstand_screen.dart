import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import 'bookmarks_screen.dart';
import 'issue_screen.dart';
import 'web_view_screen.dart';

/// The home "newsstand" — a stylish cover of the magazine with the current
/// issue featured and the full run of back-issues on a shelf.
class NewsstandScreen extends StatefulWidget {
  const NewsstandScreen({super.key});

  @override
  State<NewsstandScreen> createState() => _NewsstandScreenState();
}

class _NewsstandScreenState extends State<NewsstandScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    final featured = kIssues.last; // the newest issue is "this month"
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverConstrainedCrossAxis(
                maxExtent: 640,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: SectionChip(
                      label: 'This Month’s Issue',
                      color: AppColors.cherry,
                    ),
                  ),
                ),
              ),
              SliverConstrainedCrossAxis(
                maxExtent: 640,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: _FeaturedCover(
                      issue: featured,
                      onTap: () => _open(featured),
                    ),
                  ),
                ),
              ),
              SliverConstrainedCrossAxis(
                maxExtent: 640,
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: SectionChip(
                      label: 'All Issues',
                      color: AppColors.folkBlue,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _shelf()),
              SliverConstrainedCrossAxis(
                maxExtent: 640,
                sliver: SliverToBoxAdapter(child: _footer(context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    return Stack(
      children: [
        // Warm illustrated band behind the nameplate.
        SizedBox(
          height: 188,
          width: double.infinity,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.transparent],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Image.asset(AppAssets.bgVertical, fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(
          child: Container(color: AppColors.paper.withValues(alpha: 0.15)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 44, 18, 8),
          child: Column(
            children: [
              // The golden egg mascot ties the app back to "Flying Egg Rush".
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(AppAssets.egg, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              const Masthead(size: 32, dateLine: 'A Flying Egg Rush Magazine'),
              const SizedBox(height: 8),
              Text(
                'Vol. I · No. 5 · Free · folk tales, facts & puzzles',
                textAlign: TextAlign.center,
                style: AppText.serif(
                  13,
                  color: AppColors.inkSoft,
                  style: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shelf() {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: kIssues.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final issue = kIssues[i];
          return _MiniCover(issue: issue, onTap: () => _open(issue));
        },
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      child: Column(
        children: [
          Container(height: 1.5, color: AppColors.paperEdge),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _footerChip(Icons.bookmark_border_rounded, 'Bookmarks', () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              }),
              _footerChip(Icons.info_outline_rounded, 'About', () {
                _showAbout(context);
              }),
              _footerChip(Icons.privacy_tip_outlined, 'Privacy Policy', () {
                _openWeb(
                  context,
                  'Privacy Policy',
                  'https://flyingeggrush.com/privacy-policy.html',
                );
              }),
              _footerChip(Icons.support_agent_outlined, 'Support', () {
                _openWeb(
                  context,
                  'Support',
                  'https://flyingeggrush.com/support.html',
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2026 The Chicken Times',
            style: AppText.serif(12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _footerChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
            Text(
              label,
              style: AppText.serif(
                13,
                color: AppColors.ink,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(Issue issue) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => IssueScreen(issue: issue)));
  }

  void _openWeb(BuildContext context, String title, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WebViewScreen(title: title, url: url),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('About', style: AppText.masthead(22, color: AppColors.ink)),
        content: Text(
          'The Chicken Times is a cosy illustrated magazine of folk tales, fun '
          'facts, comics, recipes and puzzles — all about hens, roosters and '
          'golden eggs from around the world. Happy reading!',
          style: AppText.serif(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Large featured cover for the current issue.
class _FeaturedCover extends StatelessWidget {
  const _FeaturedCover({required this.issue, required this.onTap});
  final Issue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final read = store.issueReadCount(issue);
    final total = issue.rubrics.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(issue.coverColor, Colors.white, 0.15)!,
                      Color.lerp(issue.coverColor, Colors.black, 0.35)!,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Text(
                        issue.coverEmoji,
                        style: TextStyle(
                          fontSize: 200,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Masthead(
                            size: 18,
                            color: Colors.white,
                            onPaper: false,
                          ),
                          const Spacer(),
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
                              'ISSUE No. ${issue.number}',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            issue.title,
                            style: AppText.masthead(34, color: Colors.white),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppColors.cream,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.dateLine.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$read / $total pages read',
                          style: AppText.serif(13, color: AppColors.ink),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cherry,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            read == 0 ? 'READ NOW' : 'CONTINUE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small cover used on the "All Issues" shelf.
class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.issue, required this.onTap});
  final Issue issue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = store.issueComplete(issue);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(issue.coverColor, Colors.white, 0.12)!,
                      Color.lerp(issue.coverColor, Colors.black, 0.38)!,
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -6,
                      bottom: -10,
                      child: Text(
                        issue.coverEmoji,
                        style: TextStyle(
                          fontSize: 96,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No. ${issue.number}',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            issue.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.masthead(19, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    if (complete)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              issue.dateLine,
              style: AppText.serif(12, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
