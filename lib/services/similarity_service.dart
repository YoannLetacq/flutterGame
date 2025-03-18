import 'dart:math';

/// Levenshtein algorithm implementation based on:
/// http://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
int levenshtein(String s, String t, {bool caseSensitive = true}) {
  if (!caseSensitive) {
    s = s.toLowerCase();
    t = t.toLowerCase();
  }
  if (s == t) {
    return 0;
  }
  if (s.isEmpty) {
    return t.length;
  }
  if (t.isEmpty) {
    return s.length;
  }

  List<int> v0 = List<int>.filled(t.length + 1, 0);
  List<int> v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < t.length + 1; i < i++) {
    v0[i] = i;
  }

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      int cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < t.length + 1; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}

class SimilarityService {
  /// Calcule la similarité entre [userResponse] et [expectedResponse].
  /// Retourne un coefficient compris entre 0 et 1, où 1 signifie que les chaînes sont identiques.
  double calculateSimilarity(String userResponse, String expectedResponse) {
    final String trimmedUser = userResponse.trim();
    final String trimmedExpected = expectedResponse.trim();
    final int distance = levenshtein(trimmedUser, trimmedExpected);
    final int maxLength = trimmedUser.length > trimmedExpected.length
        ? trimmedUser.length
        : trimmedExpected.length;
    if (maxLength == 0) return 1.0;
    return 1 - (distance / maxLength);
  }
}