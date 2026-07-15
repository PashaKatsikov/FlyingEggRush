import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/magazine.dart';

/// Tracks the reader's progress through The Chicken Times: which rubrics have
/// been read, which puzzles are solved, best quiz scores and bookmarks.
class ReaderStore extends ChangeNotifier {
  static const _kRead = 'read_rubrics';
  static const _kSolved = 'solved_rubrics';
  static const _kBookmarks = 'bookmarks';
  static const _kQuizPrefix = 'quiz_best_';

  SharedPreferences? _prefs;

  Set<String> _read = {};
  Set<String> _solved = {};
  Set<String> _bookmarks = {};
  final Map<String, int> _quizBest = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _read = (_prefs!.getStringList(_kRead) ?? const []).toSet();
    _solved = (_prefs!.getStringList(_kSolved) ?? const []).toSet();
    _bookmarks = (_prefs!.getStringList(_kBookmarks) ?? const []).toSet();
    for (final issue in kIssues) {
      final id = issue.rubricId(RubricKind.quiz);
      final v = _prefs!.getInt('$_kQuizPrefix$id');
      if (v != null) _quizBest[id] = v;
    }
    notifyListeners();
  }

  bool isRead(String id) => _read.contains(id);

  void markRead(String id) {
    if (_read.add(id)) {
      _prefs?.setStringList(_kRead, _read.toList());
      notifyListeners();
    }
  }

  bool isSolved(String id) => _solved.contains(id);

  void markSolved(String id) {
    if (_solved.add(id)) {
      _prefs?.setStringList(_kSolved, _solved.toList());
      notifyListeners();
    }
  }

  bool isBookmarked(String id) => _bookmarks.contains(id);

  void toggleBookmark(String id) {
    if (!_bookmarks.remove(id)) _bookmarks.add(id);
    _prefs?.setStringList(_kBookmarks, _bookmarks.toList());
    notifyListeners();
  }

  Set<String> get bookmarks => _bookmarks;

  int quizBest(String id) => _quizBest[id] ?? 0;

  void recordQuiz(String id, int correct) {
    if (correct > (_quizBest[id] ?? 0)) {
      _quizBest[id] = correct;
      _prefs?.setInt('$_kQuizPrefix$id', correct);
      notifyListeners();
    }
  }

  /// How many rubrics of an issue have been read (0..rubrics.length).
  int issueReadCount(Issue issue) =>
      issue.rubrics.where((r) => isRead(issue.rubricId(r))).length;

  bool issueComplete(Issue issue) =>
      issueReadCount(issue) == issue.rubrics.length;

  int get totalRead => _read.length;
}
