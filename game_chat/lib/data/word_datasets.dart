class WordDatasets {
  static const Map<String, List<String>> categories = {
    'ANIMALS': [
      'CAT', 'DOG', 'BIRD', 'FISH', 'LION', 'TIGER', 'BEAR', 'WOLF',
      'ELEPHANT', 'GIRAFFE', 'ZEBRA', 'MONKEY', 'RABBIT', 'HORSE', 'COW',
      'PIG', 'SHEEP', 'GOAT', 'CHICKEN', 'DUCK', 'FROG', 'SNAKE', 'TURTLE',
      'EAGLE', 'HAWK', 'OWL', 'PENGUIN', 'DOLPHIN', 'WHALE', 'SHARK',
      'OCTOPUS', 'CRAB', 'LOBSTER', 'BUTTERFLY', 'BEE', 'ANT', 'SPIDER'
    ],
    
    'NATURE': [
      'TREE', 'LEAF', 'FLOWER', 'GRASS', 'ROCK', 'STONE', 'WATER', 'RIVER',
      'LAKE', 'OCEAN', 'MOUNTAIN', 'HILL', 'FOREST', 'DESERT', 'BEACH',
      'CLOUD', 'RAIN', 'SNOW', 'WIND', 'SUN', 'MOON', 'STAR', 'SKY',
      'EARTH', 'SAND', 'MUD', 'ICE', 'FIRE', 'LIGHTNING', 'RAINBOW',
      'VALLEY', 'CANYON', 'CAVE', 'ISLAND', 'VOLCANO', 'GLACIER'
    ],
    
    'FOOD': [
      'APPLE', 'BANANA', 'ORANGE', 'GRAPE', 'BERRY', 'PEACH', 'PEAR',
      'PIZZA', 'BURGER', 'PASTA', 'BREAD', 'CHEESE', 'MILK', 'BUTTER',
      'CHICKEN', 'BEEF', 'FISH', 'RICE', 'BEANS', 'CORN', 'POTATO',
      'TOMATO', 'CARROT', 'ONION', 'GARLIC', 'PEPPER', 'SALT', 'SUGAR',
      'HONEY', 'CAKE', 'COOKIE', 'CANDY', 'CHOCOLATE', 'COFFEE', 'TEA'
    ],
    
    'SPORTS': [
      'SOCCER', 'FOOTBALL', 'BASKETBALL', 'BASEBALL', 'TENNIS', 'GOLF',
      'HOCKEY', 'CRICKET', 'RUGBY', 'VOLLEYBALL', 'SWIMMING', 'RUNNING',
      'BOXING', 'WRESTLING', 'CYCLING', 'SKIING', 'SURFING', 'CLIMBING',
      'JUMPING', 'RACING', 'FISHING', 'HUNTING', 'ARCHERY', 'BOWLING',
      'DARTS', 'POOL', 'CHESS', 'CARDS', 'DICE', 'GAME', 'PLAY', 'WIN'
    ],
    
    'COLORS': [
      'RED', 'BLUE', 'GREEN', 'YELLOW', 'ORANGE', 'PURPLE', 'PINK',
      'BLACK', 'WHITE', 'GRAY', 'BROWN', 'SILVER', 'GOLD', 'BRONZE',
      'MAROON', 'NAVY', 'TEAL', 'LIME', 'OLIVE', 'AQUA', 'FUCHSIA',
      'VIOLET', 'INDIGO', 'CRIMSON', 'SCARLET', 'AMBER', 'CORAL',
      'IVORY', 'PEARL', 'JADE', 'RUBY', 'EMERALD', 'SAPPHIRE'
    ],
    
    'TECHNOLOGY': [
      'COMPUTER', 'PHONE', 'TABLET', 'LAPTOP', 'MOUSE', 'KEYBOARD',
      'SCREEN', 'MONITOR', 'CAMERA', 'PRINTER', 'SCANNER', 'ROUTER',
      'MODEM', 'CABLE', 'WIRE', 'BATTERY', 'CHARGER', 'SOFTWARE',
      'HARDWARE', 'INTERNET', 'WEBSITE', 'EMAIL', 'DOWNLOAD', 'UPLOAD',
      'CLICK', 'TYPE', 'SCROLL', 'SWIPE', 'TAP', 'TOUCH', 'VOICE',
      'SOUND', 'VIDEO', 'IMAGE', 'FILE', 'FOLDER', 'SAVE', 'DELETE'
    ],
    
    'SPACE': [
      'SUN', 'MOON', 'EARTH', 'MARS', 'VENUS', 'JUPITER', 'SATURN',
      'MERCURY', 'URANUS', 'NEPTUNE', 'PLUTO', 'STAR', 'GALAXY',
      'COMET', 'METEOR', 'ASTEROID', 'PLANET', 'ORBIT', 'ROCKET',
      'SHUTTLE', 'SATELLITE', 'TELESCOPE', 'ASTRONAUT', 'SPACE',
      'UNIVERSE', 'COSMOS', 'NEBULA', 'SOLAR', 'LUNAR'
    ],
    
    'VEHICLES': [
      'CAR', 'TRUCK', 'BUS', 'TRAIN', 'PLANE', 'SHIP', 'BOAT', 'BIKE',
      'MOTORCYCLE', 'SCOOTER', 'TAXI', 'VAN', 'SUV', 'SEDAN', 'COUPE',
      'WAGON', 'PICKUP', 'TRAILER', 'FERRY', 'YACHT', 'SUBMARINE',
      'HELICOPTER', 'JET', 'GLIDER', 'BALLOON', 'ROCKET', 'SPACESHIP',
      'SKATEBOARD', 'UNICYCLE', 'TRICYCLE', 'CART'
    ],
    
    'MUSIC': [
      'GUITAR', 'PIANO', 'DRUM', 'VIOLIN', 'FLUTE', 'TRUMPET', 'SAXOPHONE',
      'BASS', 'HARP', 'ORGAN', 'CYMBAL', 'BELL', 'HORN', 'TUBA',
      'CLARINET', 'OBOE', 'CELLO', 'VIOLA', 'BANJO', 'UKULELE',
      'SONG', 'MELODY', 'RHYTHM', 'BEAT', 'NOTE', 'CHORD', 'SCALE',
      'HARMONY', 'TEMPO', 'PITCH', 'VOLUME', 'SOUND', 'MUSIC', 'BAND'
    ],
    
    'HOME': [
      'HOUSE', 'ROOM', 'KITCHEN', 'BEDROOM', 'BATHROOM', 'LIVING',
      'DINING', 'GARAGE', 'GARDEN', 'YARD', 'ROOF', 'WALL', 'DOOR',
      'WINDOW', 'FLOOR', 'CEILING', 'STAIRS', 'BASEMENT', 'ATTIC',
      'FURNITURE', 'CHAIR', 'TABLE', 'BED', 'SOFA', 'DESK', 'SHELF',
      'CABINET', 'DRAWER', 'CLOSET', 'MIRROR', 'LAMP', 'LIGHT', 'FAN'
    ]
  };

  // Get words for specific difficulty levels
  static List<String> getWordsForDifficulty(String category, String difficulty) {
    List<String> categoryWords = categories[category] ?? categories['NATURE']!;
    
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return categoryWords.where((word) => word.length >= 3 && word.length <= 5).take(6).toList();
      case 'normal':
        return categoryWords.where((word) => word.length >= 4 && word.length <= 7).take(8).toList();
      case 'hard':
        return categoryWords.where((word) => word.length >= 5 && word.length <= 10).take(10).toList();
      default:
        return categoryWords.where((word) => word.length >= 4 && word.length <= 7).take(8).toList();
    }
  }

  // Get random words for infinite mode - improved version
  static List<String> getRandomWords(int count, int gridSize) {
    List<String> allWords = [];
    categories.values.forEach((words) => allWords.addAll(words));
    
    // Filter words that can fit in the grid and remove duplicates
    Set<String> fitWordsSet = allWords.where((word) => 
      word.length >= 3 && word.length <= gridSize
    ).toSet();
    
    List<String> fitWords = fitWordsSet.toList()..shuffle();
    
    // Ensure we have enough words
    if (fitWords.length < count) {
      // If we don't have enough words, repeat some
      while (fitWords.length < count) {
        List<String> additionalWords = fitWordsSet.toList()..shuffle();
        fitWords.addAll(additionalWords.take(count - fitWords.length));
      }
    }
    
    return fitWords.take(count).toList();
  }

  // Get level-specific words
  static List<String> getLevelWords(int level) {
    String category = _getLevelCategory(level);
    List<String> categoryWords = categories[category] ?? categories['NATURE']!;
    
    int wordCount = 6 + (level ~/ 3); // Increase word count every 3 levels
    wordCount = wordCount.clamp(6, 12); // Max 12 words
    
    // Filter words by length based on level
    int maxLength = _getMaxWordLengthForLevel(level);
    List<String> filteredWords = categoryWords.where((word) => 
      word.length >= 3 && word.length <= maxLength
    ).toList();
    
    if (filteredWords.length < wordCount) {
      // If not enough words in category, add from other categories
      for (String otherCategory in categories.keys) {
        if (otherCategory != category) {
          List<String> otherWords = categories[otherCategory]!.where((word) => 
            word.length >= 3 && word.length <= maxLength
          ).toList();
          filteredWords.addAll(otherWords);
          if (filteredWords.length >= wordCount) break;
        }
      }
    }
    
    filteredWords.shuffle();
    return filteredWords.take(wordCount).toList();
  }

  static int _getMaxWordLengthForLevel(int level) {
    if (level <= 5) return 6;
    if (level <= 10) return 7;
    if (level <= 20) return 8;
    if (level <= 30) return 9;
    return 10;
  }

  static String _getLevelCategory(int level) {
    List<String> categoryOrder = [
      'NATURE', 'ANIMALS', 'FOOD', 'COLORS', 'SPORTS',
      'TECHNOLOGY', 'SPACE', 'VEHICLES', 'MUSIC', 'HOME'
    ];
    
    return categoryOrder[(level - 1) % categoryOrder.length];
  }

  static String getLevelTitle(int level) {
    String category = _getLevelCategory(level);
    return 'Level $level - ${category.toLowerCase().capitalize()}';
  }

  // Get all words from a specific category with length filtering
  static List<String> getCategoryWords(String category, int maxLength) {
    List<String> categoryWords = categories[category] ?? categories['NATURE']!;
    return categoryWords.where((word) => 
      word.length >= 3 && word.length <= maxLength
    ).toList();
  }

  // Get a mix of words from multiple categories
  static List<String> getMixedWords(int count, int maxLength) {
    List<String> mixedWords = [];
    List<String> categoryKeys = categories.keys.toList()..shuffle();
    
    int wordsPerCategory = (count / categoryKeys.length).ceil();
    
    for (String category in categoryKeys) {
      List<String> categoryWords = getCategoryWords(category, maxLength);
      categoryWords.shuffle();
      mixedWords.addAll(categoryWords.take(wordsPerCategory));
      
      if (mixedWords.length >= count) break;
    }
    
    mixedWords.shuffle();
    return mixedWords.take(count).toList();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}