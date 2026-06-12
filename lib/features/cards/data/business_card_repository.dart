import 'package:businesscard/core/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:businesscard/features/cards/domain/saved_business_card.dart';
import 'package:businesscard/services/google_drive_upload_service.dart';
import 'package:businesscard/services/image_picker_service.dart';
import 'package:businesscard/services/text_recognition_service.dart';
import 'package:image_picker/image_picker.dart';

class BusinessCardRepository {
  BusinessCardRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
    required ImagePickerService imagePickerService,
    required TextRecognitionService textRecognitionService,
    required GoogleDriveUploadService googleDriveUploadService,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth,
       _imagePickerService = imagePickerService,
       _textRecognitionService = textRecognitionService,
       _googleDriveUploadService = googleDriveUploadService;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final ImagePickerService _imagePickerService;
  final TextRecognitionService _textRecognitionService;
  final GoogleDriveUploadService _googleDriveUploadService;

  Future<List<SavedBusinessCard>> fetchCards() async {
    final user = _requireSignedInUser();
    final snapshot = await _firestore
        .collection(AppConfig.cardsCollection)
        .where('owner_uid', isEqualTo: user.uid)
        .get();

    final cards = snapshot.docs
        .map((doc) => SavedBusinessCard.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);

    cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cards;
  }

  Future<SavedBusinessCard?> scanCardDraft(ImageSource source) async {
    final image = await _imagePickerService.pickBusinessCardImage(
      source: source,
    );
    if (image == null) {
      return null;
    }

    final extracted = await _textRecognitionService.extractContactHints(
      image.path,
    );

    final card = SavedBusinessCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      displayName: extracted.name,
      company: extracted.company,
      phone: extracted.phone,
      email: extracted.email,
      imagePath: image.path,
      createdAt: DateTime.now(),
      remark: '',
    );

    return card;
  }

  Future<SavedBusinessCard> saveCard(SavedBusinessCard card) async {
    final user = _requireSignedInUser();
    final localImagePath = card.imagePath;
    if (localImagePath == null || localImagePath.trim().isEmpty) {
      throw const BusinessCardRepositoryException(
        'No local image was found for this card.',
      );
    }

    final remotePath = await _googleDriveUploadService.uploadBusinessCardImage(
      localImagePath,
    );

    final createdBy = _usernameForUser(user);
    final ownerEmail = user.email?.trim() ?? '';
    final cardToSave = card.copyWith(
      remotePath: remotePath,
      createdBy: createdBy,
      ownerEmail: ownerEmail,
    );
    final docRef = await _firestore
        .collection(AppConfig.cardsCollection)
        .add(
          cardToSave.toFirestoreMap(
            ownerUid: user.uid,
            ownerEmail: ownerEmail,
            createdBy: createdBy,
          ),
        );

    return cardToSave.copyWith(id: docRef.id);
  }

  Future<void> deleteCard(String id) async {
    _requireSignedInUser();
    await _firestore.collection(AppConfig.cardsCollection).doc(id).delete();
  }

  User _requireSignedInUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const BusinessCardRepositoryException(
        'Your Firebase session has expired. Sign in again and retry.',
      );
    }
    return user;
  }

  // Stores the readable username (e.g. "veerji") rather than the opaque UID.
  // Usernames are mapped to <username>@<domain> at sign-in, so strip the domain.
  String _usernameForUser(User user) {
    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return email;
  }
}

class BusinessCardRepositoryException implements Exception {
  const BusinessCardRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
