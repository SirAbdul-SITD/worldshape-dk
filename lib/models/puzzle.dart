class Puzzle {
  final int id;
  final String tier;
  final String country;
  final List<String> options;
  final int answerIndex;
  final List<List<List<double>>> loops; // list of closed point loops

  Puzzle({
    required this.id,
    required this.tier,
    required this.country,
    required this.options,
    required this.answerIndex,
    required this.loops,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final loopsRaw = j['loops'] as List;
    final loops = loopsRaw.map((loop) {
      return (loop as List).map((pt) {
        final p = pt as List;
        return [(p[0] as num).toDouble(), (p[1] as num).toDouble()];
      }).toList();
    }).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      country: j['country'] as String,
      options: (j['options'] as List).map((e) => e as String).toList(),
      answerIndex: j['answerIndex'] as int,
      loops: loops,
    );
  }
}
