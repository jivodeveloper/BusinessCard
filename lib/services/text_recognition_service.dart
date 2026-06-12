import 'package:path/path.dart' as p;

class TextRecognitionService {
  Future<RecognizedContact> extractContactHints(String imagePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final fileName = p.basenameWithoutExtension(imagePath).replaceAll('_', ' ');
    final cleaned = fileName.trim().isEmpty ? 'Scanned Contact' : fileName.trim();

    return RecognizedContact(
      name: _toTitleCase(cleaned),
      company: 'Imported Business Card',
      phone: '+91 90000 00000',
      email: '${cleaned.toLowerCase().replaceAll(' ', '.')}@example.com',
    );
  }

  String _toTitleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

class RecognizedContact {
  const RecognizedContact({
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
  });

  final String name;
  final String company;
  final String phone;
  final String email;
}
