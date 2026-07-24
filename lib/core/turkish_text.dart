class TurkishText {
  static const _lowerMap = <String, String>{
    'A': 'a', 'B': 'b', 'C': 'c', 'Ç': 'ç', 'D': 'd', 'E': 'e',
    'F': 'f', 'G': 'g', 'Ğ': 'ğ', 'H': 'h', 'I': 'ı', 'İ': 'i',
    'J': 'j', 'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'O': 'o',
    'Ö': 'ö', 'P': 'p', 'R': 'r', 'S': 's', 'Ş': 'ş', 'T': 't',
    'U': 'u', 'Ü': 'ü', 'V': 'v', 'Y': 'y', 'Z': 'z',
  };

  static const _upperMap = <String, String>{
    'a': 'A', 'b': 'B', 'c': 'C', 'ç': 'Ç', 'd': 'D', 'e': 'E',
    'f': 'F', 'g': 'G', 'ğ': 'Ğ', 'h': 'H', 'ı': 'I', 'i': 'İ',
    'j': 'J', 'k': 'K', 'l': 'L', 'm': 'M', 'n': 'N', 'o': 'O',
    'ö': 'Ö', 'p': 'P', 'r': 'R', 's': 'S', 'ş': 'Ş', 't': 'T',
    'u': 'U', 'ü': 'Ü', 'v': 'V', 'y': 'Y', 'z': 'Z',
  };

  static String lower(String value) =>
      value.split('').map((c) => _lowerMap[c] ?? c.toLowerCase()).join();

  static String upper(String value) =>
      value.split('').map((c) => _upperMap[c] ?? c.toUpperCase()).join();

  static String normalizeWord(String value) {
    return lower(value.trim())
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .replaceAll(RegExp(r'[^a-zçğıöşü]'), '');
  }
}
