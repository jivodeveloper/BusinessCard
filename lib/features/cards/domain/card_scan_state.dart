import 'package:businesscard/features/cards/domain/business_card_sort.dart';
import 'package:businesscard/features/cards/domain/saved_business_card.dart';

class CardScanState {
  const CardScanState({
    this.isLoading = false,
    this.errorMessage,
    this.statusMessage,
    this.cards = const [],
    this.currentDraft,
    this.sort = BusinessCardSort.newestFirst,
    this.searchQuery = '',
    this.selectedTabIndex = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? statusMessage;
  final List<SavedBusinessCard> cards;
  final SavedBusinessCard? currentDraft;
  final BusinessCardSort sort;
  final String searchQuery;
  final int selectedTabIndex;

  List<SavedBusinessCard> get filteredCards {
    final query = searchQuery.trim().toLowerCase();
    final sorted = sort.apply(cards);
    if (query.isEmpty) {
      return sorted;
    }

    return sorted
        .where((card) => card.remark.toLowerCase().contains(query))
        .toList(growable: false);
  }

  CardScanState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? statusMessage,
    List<SavedBusinessCard>? cards,
    SavedBusinessCard? currentDraft,
    BusinessCardSort? sort,
    String? searchQuery,
    int? selectedTabIndex,
    bool clearError = false,
    bool clearStatus = false,
    bool clearDraft = false,
  }) {
    return CardScanState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      statusMessage: clearStatus ? null : statusMessage ?? this.statusMessage,
      cards: cards ?? this.cards,
      currentDraft: clearDraft ? null : currentDraft ?? this.currentDraft,
      sort: sort ?? this.sort,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}
