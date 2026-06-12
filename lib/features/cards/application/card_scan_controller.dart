import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:businesscard/features/cards/data/business_card_repository.dart';
import 'package:businesscard/features/cards/domain/business_card_sort.dart';
import 'package:businesscard/features/cards/domain/card_scan_state.dart';
import 'package:businesscard/services/google_drive_upload_service.dart';
import 'package:businesscard/services/image_picker_service.dart';
import 'package:businesscard/services/text_recognition_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => ImagePickerService(),
);

final textRecognitionServiceProvider = Provider<TextRecognitionService>(
  (ref) => TextRecognitionService(),
);

final googleDriveUploadServiceProvider = Provider<GoogleDriveUploadService>(
  (ref) => GoogleDriveUploadService(),
);

final businessCardRepositoryProvider = Provider<BusinessCardRepository>((ref) {
  return BusinessCardRepository(
    firestore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    imagePickerService: ref.read(imagePickerServiceProvider),
    textRecognitionService: ref.read(textRecognitionServiceProvider),
    googleDriveUploadService: ref.read(googleDriveUploadServiceProvider),
  );
});

final cardScanControllerProvider =
    NotifierProvider.autoDispose<CardScanController, CardScanState>(
      CardScanController.new,
    );

class CardScanController extends Notifier<CardScanState> {
  BusinessCardRepository get _repository =>
      ref.read(businessCardRepositoryProvider);

  @override
  CardScanState build() {
    Future<void>.microtask(loadCards);
    return const CardScanState();
  }

  Future<void> loadCards() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );

    try {
      final cards = await _repository.fetchCards();
      state = state.copyWith(isLoading: false, cards: cards);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load saved business cards.\n$error',
      );
    }
  }

  Future<void> scanCard(ImageSource source) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );

    try {
      final card = await _repository.scanCardDraft(source);

      state = state.copyWith(
        isLoading: false,
        currentDraft: card,
        selectedTabIndex: 0,
        statusMessage: card == null
            ? 'Card scan cancelled.'
            : 'Review the scanned details and add a remark before saving.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to open the selected image source.\n$error',
      );
    }
  }

  Future<void> saveCurrentDraft() async {
    final draft = state.currentDraft;
    if (draft == null) {
      state = state.copyWith(
        errorMessage: 'Scan a business card first.',
        clearStatus: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );

    try {
      final saved = await _repository.saveCard(draft);
      final cards = await _repository.fetchCards();
      state = state.copyWith(
        isLoading: false,
        cards: cards,
        clearDraft: true,
        selectedTabIndex: 1,
        statusMessage: 'Saved ${saved.displayName}.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save this scanned card.\n$error',
      );
    }
  }

  void updateDraftRemark(String remark) {
    final draft = state.currentDraft;
    if (draft == null) {
      return;
    }

    state = state.copyWith(currentDraft: draft.copyWith(remark: remark));
  }

  void discardCurrentDraft() {
    state = state.copyWith(
      clearDraft: true,
      clearError: true,
      statusMessage: 'Draft cleared.',
    );
  }

  Future<void> deleteCard(String id) async {
    await _repository.deleteCard(id);
    final cards = await _repository.fetchCards();
    state = state.copyWith(
      cards: cards,
      statusMessage: 'Card removed.',
      clearError: true,
    );
  }

  void updateSort(BusinessCardSort sort) {
    state = state.copyWith(sort: sort);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateTab(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }
}
