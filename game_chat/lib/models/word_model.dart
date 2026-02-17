// lib/models/word_model.dart

import 'package:flutter/material.dart';
import 'position.dart';

class WordModel {
  final String word;
  final List<Position> positions;
  final Color color;
  bool found;

  WordModel({
    required this.word,
    required this.positions,
    required this.color,
    this.found = false,
  });

  WordModel copyWith({
    String? word,
    List<Position>? positions,
    Color? color,
    bool? found,
  }) {
    return WordModel(
      word: word ?? this.word,
      positions: positions ?? this.positions,
      color: color ?? this.color,
      found: found ?? this.found,
    );
  }

  @override
  String toString() {
    return 'WordModel(word: $word, found: $found, positions: $positions)';
  }
}