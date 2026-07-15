import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.issue});
  final Issue issue;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final Quiz _quiz = widget.issue.quiz;
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  bool _finished = false;

  void _choose(int i) {
    if (_answered) return;
    setState(() {
      _selected = i;
      _answered = true;
      if (i == _quiz.questions[_index].answer) {
        _correct++;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _next() {
    if (_index < _quiz.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      final id = widget.issue.rubricId(RubricKind.quiz);
      store.recordQuiz(id, _correct);
      store.markSolved(id);
      store.markRead(id); // counts toward issue progress only when finished
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    color: AppColors.ink,
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _quiz.title,
                      style: AppText.masthead(20, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 2, color: AppColors.ink),
            Expanded(child: _finished ? _results() : _question()),
          ],
        ),
      ),
    );
  }

  Widget _question() {
    final q = _quiz.questions[_index];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      child: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SectionChip(label: 'Quiz Corner', color: AppColors.teal),
                const Spacer(),
                Text(
                  'Question ${_index + 1} of ${_quiz.questions.length}',
                  style: AppText.serif(13, color: AppColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_index + (_answered ? 1 : 0)) / _quiz.questions.length,
                minHeight: 8,
                backgroundColor: AppColors.paperEdge,
                valueColor: const AlwaysStoppedAnimation(AppColors.teal),
              ),
            ),
            const SizedBox(height: 20),
            Text(q.question, style: AppText.masthead(24, color: AppColors.ink)),
            const SizedBox(height: 22),
            for (int i = 0; i < q.options.length; i++)
              _option(i, q.options[i], q.answer),
            const SizedBox(height: 20),
            if (_answered)
              Center(
                child: FolkButton(
                  label: _index < _quiz.questions.length - 1
                      ? 'NEXT'
                      : 'SEE RESULTS',
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.cherry,
                  width: 240,
                  onTap: _next,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(int i, String label, int answer) {
    Color bg = Colors.white;
    Color border = AppColors.paperEdge;
    IconData? icon;
    Color iconColor = AppColors.ink;

    if (_answered) {
      if (i == answer) {
        bg = AppColors.leaf.withValues(alpha: 0.18);
        border = AppColors.leaf;
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.leaf;
      } else if (i == _selected) {
        bg = AppColors.cherry.withValues(alpha: 0.15);
        border = AppColors.cherry;
        icon = Icons.cancel_rounded;
        iconColor = AppColors.cherry;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _choose(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(
                  String.fromCharCode(65 + i),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppText.serif(17))),
              if (icon != null) Icon(icon, color: iconColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results() {
    final total = _quiz.questions.length;
    final perfect = _correct == total;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ResponsiveContent(
          maxWidth: 480,
          child: Column(
            children: [
              Text(perfect ? '🏆' : '🐣', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 12),
              Text(
                perfect ? 'Perfect Score!' : 'Nice Work!',
                style: AppText.masthead(30, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                'You got $_correct out of $total correct.',
                style: AppText.serif(18),
              ),
              const SizedBox(height: 6),
              Text(
                'Best: ${store.quizBest(widget.issue.rubricId(RubricKind.quiz))}/$total',
                style: AppText.serif(14, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 28),
              FolkButton(
                label: 'TRY AGAIN',
                icon: Icons.refresh_rounded,
                color: AppColors.teal,
                width: 240,
                onTap: () => setState(() {
                  _index = 0;
                  _selected = null;
                  _answered = false;
                  _correct = 0;
                  _finished = false;
                }),
              ),
              const SizedBox(height: 14),
              FolkButton(
                label: 'BACK TO ISSUE',
                icon: Icons.menu_book_rounded,
                color: AppColors.cherry,
                width: 240,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
