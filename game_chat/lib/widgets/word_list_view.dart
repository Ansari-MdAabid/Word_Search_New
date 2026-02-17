// lib/widgets/word_list_view.dart

import 'package:flutter/material.dart';

class WordWithColor {
  final String word;
  final Color color;
  final bool found;

  WordWithColor({
    required this.word,
    required this.color,
    required this.found,
  });
}

class WordListView extends StatelessWidget {
  final List<WordWithColor> wordsWithColors;

  const WordListView({
    super.key,
    required this.wordsWithColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Words to Find:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wordsWithColors.map((wordData) => _buildWordChip(wordData)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChip(WordWithColor wordData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: wordData.found 
            ? wordData.color.withOpacity(0.8)
            : Colors.white24,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wordData.found 
              ? wordData.color 
              : Colors.white38,
          width: wordData.found ? 2 : 1,
        ),
        boxShadow: wordData.found ? [
          BoxShadow(
            color: wordData.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (wordData.found)
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            )
          else
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: wordData.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            wordData.word,
            style: TextStyle(
              color: wordData.found ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: wordData.found ? FontWeight.bold : FontWeight.w500,
              decoration: wordData.found ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}