import 'package:businesscard/features/cards/domain/saved_business_card.dart';

enum BusinessCardSort {
  newestFirst,
  oldestFirst,
}

extension BusinessCardSortX on BusinessCardSort {
  String get label {
    switch (this) {
      case BusinessCardSort.newestFirst:
        return 'Newest first';
      case BusinessCardSort.oldestFirst:
        return 'Oldest first';
    }
  }

  List<SavedBusinessCard> apply(List<SavedBusinessCard> cards) {
    final items = List<SavedBusinessCard>.from(cards);

    switch (this) {
      case BusinessCardSort.newestFirst:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BusinessCardSort.oldestFirst:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return items;
  }
}
