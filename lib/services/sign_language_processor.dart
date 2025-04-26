class SignLanguageProcessor {
  // List of all available animations.
  // (This is optional and can be used for reference.)
  static final List<String> animationNames = [
    'idle_2_b',
    'my_name_b',
    'im_fine_b',
    'how_are_u_b',
    'hello_b',
    'Z_b',
    'Y_b',
    'X_b',
    'W_b',
    'V_b',
    'U_b',
    'T_b',
    'S_b',
    'IDLE_1f_b',
    'R_b',
    'Q_b',
    'P_b',
    'O_b',
    'N_b',
    'M_b',
    'L_b',
    'K_b',
    'J_b',
    'I_b',
    'H_b',
    'G_b',
    'F_b',
    'E_b',
    'D_b',
    'C_b',
    'B_b',
    'A_b',
    'IDLE_ANI',
    'IDLE_ANI_b',
  ];

  // Mapping for phrases to their corresponding animations.
  static final Map<String, List<String>> signDictionary = {
    'hello': ['hello_b'],
    'hi': ['hello_b'],
    'how are you': ['how_are_u_b'], // Original mapping.
    'my name': ['my_name_b'],
    "i'm fine": ['im_fine_b'],
    'idle': ['idle_2_b'],
    // You can add more phrase mappings as needed.
  };

  // Mapping for individual letters (a-z) to their animations.
  static final Map<String, String> letterMapping = {
    'a': 'A_b',
    'b': 'B_b',
    'c': 'C_b',
    'd': 'D_b',
    'e': 'E_b',
    'f': 'F_b',
    'g': 'G_b',
    'h': 'H_b',
    'i': 'I_b',
    'j': 'J_b',
    'k': 'K_b',
    'l': 'L_b',
    'm': 'M_b',
    'n': 'N_b',
    'o': 'O_b',
    'p': 'P_b',
    'q': 'Q_b',
    'r': 'R_b',
    's': 'S_b',
    't': 'T_b',
    'u': 'U_b',
    'v': 'V_b',
    'w': 'W_b',
    'x': 'X_b',
    'y': 'Y_b',
    'z': 'Z_b',
  };

  // Default animation for any character that is not in our letter mapping.
  static const String defaultIdle = 'IDLE_ANI_b';

  /// Processes the input text and returns a list of animation names.
  ///
  /// 1. It first tries to find the longest matching phrase in the [signDictionary].
  /// 2. If no phrase match is found, it breaks the word into individual letters
  ///    and maps each letter using [letterMapping].
  static List<String> processText(String text) {
    List<String> animations = [];
    // Convert text to lowercase and split into words.
    List<String> words = text.toLowerCase().trim().split(' ');

    for (int i = 0; i < words.length; i++) {
      bool foundPhrase = false;

      // Try to match the longest possible phrase starting at index i.
      for (int j = words.length - i; j > 0; j--) {
        final phrase = words.sublist(i, i + j).join(' ');
        if (signDictionary.containsKey(phrase)) {
          animations.addAll(signDictionary[phrase]!);
          i += j - 1; // Skip the words that formed the phrase.
          foundPhrase = true;
          break;
        }
      }

      // If no phrase was found, break the word into individual letters.
      if (!foundPhrase) {
        final word = words[i];
        for (int k = 0; k < word.length; k++) {
          final letter = word[k];
          if (letterMapping.containsKey(letter)) {
            animations.add(letterMapping[letter]!);
          } else {
            // If the character is not a letter (e.g., punctuation), use a default animation.
            animations.add(defaultIdle);
          }
        }
      }
    }

    return animations;
  }
}
