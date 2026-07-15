import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/magazine.dart';
import '../magazine_widgets.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

class _Cell {
  const _Cell(this.row, this.col);
  final int row;
  final int col;
  @override
  bool operator ==(Object other) =>
      other is _Cell && other.row == row && other.col == col;
  @override
  int get hashCode => row * 1000 + col;
}

class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key, required this.issue});
  final Issue issue;
  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  late final int _n;
  late final List<List<String>> _grid;
  late final List<String> _words;
  final Set<String> _found = {};
  final Set<_Cell> _foundCells = {};

  _Cell? _start;
  List<_Cell> _selection = [];

  @override
  void initState() {
    super.initState();
    final ws = widget.issue.wordSearch;
    _n = ws.size;
    _words = ws.words
        .map((w) => w.toUpperCase().replaceAll(RegExp('[^A-Z]'), ''))
        .toList();
    _grid = _generate(_n, _words, math.Random(widget.issue.number * 7 + 3));
  }

  // ── grid generation ──
  // Only horizontal and vertical placements (no diagonals) to keep it easy.
  static const _dirs = [
    [0, 1], // left → right
    [1, 0], // top → bottom
  ];

  List<List<String>> _generate(int n, List<String> words, math.Random rng) {
    final grid = List.generate(n, (_) => List.filled(n, ''));
    for (final word in words) {
      var placed = false;
      for (int attempt = 0; attempt < 200 && !placed; attempt++) {
        final dir = _dirs[rng.nextInt(_dirs.length)];
        final dr = dir[0], dc = dir[1];
        final len = word.length;
        final rowRange = n - (dr.abs() * (len - 1));
        final colRange = n - (dc.abs() * (len - 1));
        if (rowRange <= 0 || colRange <= 0) continue;
        final r0 = (dr >= 0 ? 0 : (len - 1)) + rng.nextInt(rowRange);
        final c0 = (dc >= 0 ? 0 : (len - 1)) + rng.nextInt(colRange);
        bool fits = true;
        for (int k = 0; k < len; k++) {
          final r = r0 + dr * k;
          final c = c0 + dc * k;
          if (r < 0 || r >= n || c < 0 || c >= n) {
            fits = false;
            break;
          }
          final existing = grid[r][c];
          if (existing.isNotEmpty && existing != word[k]) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        for (int k = 0; k < len; k++) {
          grid[r0 + dr * k][c0 + dc * k] = word[k];
        }
        placed = true;
      }
    }
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = alphabet[rng.nextInt(26)];
        }
      }
    }
    return grid;
  }

  // ── selection handling ──
  _Cell? _cellAt(Offset local, double cellSize) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || row >= _n || col < 0 || col >= _n) return null;
    return _Cell(row, col);
  }

  List<_Cell> _lineFrom(_Cell start, _Cell cur) {
    final dr = cur.row - start.row;
    final dc = cur.col - start.col;
    if (dr == 0 && dc == 0) return [start];
    // Snap the drag to a pure horizontal or vertical line (no diagonals):
    // whichever axis the finger moved further along wins.
    int sr, sc, len;
    if (dc.abs() >= dr.abs()) {
      sr = 0;
      sc = dc.sign;
      len = dc.abs();
    } else {
      sr = dr.sign;
      sc = 0;
      len = dr.abs();
    }
    final cells = <_Cell>[];
    for (int k = 0; k <= len; k++) {
      final r = start.row + sr * k;
      final c = start.col + sc * k;
      if (r < 0 || r >= _n || c < 0 || c >= _n) break;
      cells.add(_Cell(r, c));
    }
    return cells;
  }

  void _commit() {
    if (_selection.length >= 2) {
      final letters = _selection.map((c) => _grid[c.row][c.col]).join();
      final rev = letters.split('').reversed.join();
      String? match;
      for (final w in _words) {
        if ((w == letters || w == rev) && !_found.contains(w)) {
          match = w;
          break;
        }
      }
      if (match != null) {
        setState(() {
          _found.add(match!);
          _foundCells.addAll(_selection);
        });
        HapticFeedback.mediumImpact();
        if (_found.length == _words.length) {
          final id = widget.issue.rubricId(RubricKind.wordSearch);
          store.markSolved(id);
          store.markRead(id); // counts toward issue progress only when solved
          HapticFeedback.heavyImpact();
          WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
        }
      }
    }
    setState(() {
      _start = null;
      _selection = [];
    });
  }

  void _celebrate() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text(
          'Puzzle solved! 🎉',
          style: AppText.masthead(22, color: AppColors.ink),
        ),
        content: Text(
          'You found every hidden word. Egg-cellent work!',
          style: AppText.serif(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Yay!'),
          ),
        ],
      ),
    );
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
              child: ResponsiveContent(
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
                        widget.issue.wordSearch.title,
                        style: AppText.masthead(20, color: AppColors.ink),
                      ),
                    ),
                    Text(
                      '${_found.length}/${_words.length}',
                      style: AppText.serif(15, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ResponsiveContent(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionChip(label: 'Word Search', color: AppColors.teal),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Swipe across letters to find each word.',
              style: AppText.serif(
                13,
                color: AppColors.inkSoft,
                style: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: ResponsiveContent(
                  maxWidth: 560,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildGrid(context),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [for (final w in _words) _wordChip(w)],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scale the puzzle up on larger screens (iPad) instead of staying
        // pinned to a small phone-sized square.
        final shortestSide = MediaQuery.sizeOf(context).shortestSide;
        final maxGridSize = shortestSide >= 700 ? 520.0 : 380.0;
        final size = math.min(constraints.maxWidth, maxGridSize);
        final cell = size / _n;
        final letterFontSize = (cell * 0.46).clamp(14.0, 28.0);
        return Center(
          child: GestureDetector(
            onPanStart: (d) {
              final c = _cellAt(d.localPosition, cell);
              if (c != null) {
                setState(() {
                  _start = c;
                  _selection = [c];
                });
              }
            },
            onPanUpdate: (d) {
              if (_start == null) return;
              final c = _cellAt(d.localPosition, cell);
              if (c != null) {
                setState(() => _selection = _lineFrom(_start!, c));
              }
            },
            onPanEnd: (_) => _commit(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Column(
                children: [
                  for (int r = 0; r < _n; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (int c = 0; c < _n; c++)
                            Expanded(child: _letter(r, c, letterFontSize)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _letter(int r, int c, double fontSize) {
    final cell = _Cell(r, c);
    final selected = _selection.contains(cell);
    final found = _foundCells.contains(cell);
    Color? bg;
    if (selected) {
      bg = AppColors.gold;
    } else if (found) {
      bg = AppColors.leaf.withValues(alpha: 0.35);
    }
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        _grid[r][c],
        style: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          color: found ? AppColors.leaf : AppColors.ink,
        ),
      ),
    );
  }

  Widget _wordChip(String w) {
    final found = _found.contains(w);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: found ? AppColors.leaf : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: found ? AppColors.leaf : AppColors.paperEdge,
          width: 1.5,
        ),
      ),
      child: Text(
        w,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: found ? Colors.white : AppColors.ink,
          decoration: found ? TextDecoration.lineThrough : null,
          decorationColor: Colors.white,
        ),
      ),
    );
  }
}
