import 'package:businesscard/core/widgets/status_banner.dart';
import 'package:businesscard/features/auth/application/auth_controller.dart';
import 'package:businesscard/features/cards/application/card_scan_controller.dart';
import 'package:businesscard/features/cards/domain/business_card_sort.dart';
import 'package:businesscard/features/cards/domain/card_scan_state.dart';
import 'package:businesscard/features/cards/domain/saved_business_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math' as math;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardScanControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.selectedTabIndex == 0 ? 'Card Scanner' : 'Saved Cards',
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  authState.username.isEmpty
                      ? 'Ready to scan'
                      : 'Signed in as @${authState.username}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: state.selectedTabIndex,
                children: [
                  _ScannerTab(
                    state: state,
                    onScan: (source) => ref
                        .read(cardScanControllerProvider.notifier)
                        .scanCard(source),
                    onRemarkChanged: (remark) => ref
                        .read(cardScanControllerProvider.notifier)
                        .updateDraftRemark(remark),
                    onSave: () => ref
                        .read(cardScanControllerProvider.notifier)
                        .saveCurrentDraft(),
                    onDiscard: () => ref
                        .read(cardScanControllerProvider.notifier)
                        .discardCurrentDraft(),
                  ),
                  _SavedCardsTab(
                    state: state,
                    formatter: formatter,
                    onRefresh: () => ref
                        .read(cardScanControllerProvider.notifier)
                        .loadCards(),
                    onDelete: (id) => ref
                        .read(cardScanControllerProvider.notifier)
                        .deleteCard(id),
                    onSearchChanged: (query) => ref
                        .read(cardScanControllerProvider.notifier)
                        .updateSearchQuery(query),
                    onSortChanged: (sort) => ref
                        .read(cardScanControllerProvider.notifier)
                        .updateSort(sort),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTabIndex,
        onDestinationSelected: (index) {
          ref.read(cardScanControllerProvider.notifier).updateTab(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

class _ScannerTab extends StatefulWidget {
  const _ScannerTab({
    required this.state,
    required this.onScan,
    required this.onRemarkChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final CardScanState state;
  final ValueChanged<ImageSource> onScan;
  final ValueChanged<String> onRemarkChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  late final TextEditingController _remarkController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _ScannerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.state.currentDraft?.remark ?? '';
    if (_remarkController.text != incoming) {
      _remarkController.text = incoming;
      _remarkController.selection = TextSelection.fromPosition(
        TextPosition(offset: _remarkController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final draft = state.currentDraft;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatusBanner(message: state.errorMessage!, isError: true),
          ),
        if (state.statusMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatusBanner(message: state.statusMessage!, isError: false),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan a business card',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                // Text(
                //   'Capture a card, review the extracted details, then add a remark before saving it to the shared list.',
                //   style: Theme.of(
                //     context,
                //   ).textTheme.bodyMedium?.copyWith(height: 1.5),
                // ),
                // const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _showSourcePicker(context),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    state.isLoading ? 'Scanning...' : 'Scan or choose image',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (draft == null)
          const _EmptyDraftState()
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned preview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DraftPreviewImage(imagePath: draft.imagePath),
                  const SizedBox(height: 18),
                  _DetailRow(label: 'Name', value: draft.displayName),
                  _DetailRow(label: 'Company', value: draft.company),
                  _DetailRow(label: 'Phone', value: draft.phone),
                  _DetailRow(label: 'Email', value: draft.email),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _remarkController,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: widget.onRemarkChanged,
                    decoration: const InputDecoration(
                      labelText: 'Remark',
                      hintText:
                          'Met at expo, interested in demo, call next week...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isLoading ? null : widget.onDiscard,
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.isLoading ? null : widget.onSave,
                          child: const Text('Save card'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showSourcePicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose image source',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the camera on a real device, or choose a photo when the camera is unavailable.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  subtitle: const Text('Scan a card using the device camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose a saved business card image'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || source == null) {
      return;
    }

    widget.onScan(source);
  }
}

class _SavedCardsTab extends StatelessWidget {
  const _SavedCardsTab({
    required this.state,
    required this.formatter,
    required this.onRefresh,
    required this.onDelete,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final CardScanState state;
  final DateFormat formatter;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BusinessCardSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusBanner(message: state.errorMessage!, isError: true),
            ),
          if (state.statusMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatusBanner(
                message: state.statusMessage!,
                isError: false,
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      labelText: 'Search remarks',
                      hintText: 'Search using saved remarks',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => onSearchChanged(''),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Sort',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SegmentedButton<BusinessCardSort>(
                          segments: BusinessCardSort.values
                              .map(
                                (sort) => ButtonSegment<BusinessCardSort>(
                                  value: sort,
                                  label: Text(sort.label),
                                ),
                              )
                              .toList(),
                          selected: {state.sort},
                          onSelectionChanged: (selection) {
                            onSortChanged(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.filteredCards.isEmpty)
            _FilteredEmptyState(hasQuery: state.searchQuery.trim().isNotEmpty)
          else
            ...state.filteredCards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CardTile(
                  card: card,
                  dateLabel: formatter.format(card.createdAt),
                  onDelete: () => onDelete(card.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.dateLabel,
    required this.onDelete,
  });

  final SavedBusinessCard card;
  final String dateLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolvedImagePath(card);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null) ...[
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _CardImageViewer(card: card),
                    ),
                  );
                },
                child: _SavedCardThumbnail(imagePath: imagePath),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.displayName.trim().isEmpty
                            ? 'Scanned Contact'
                            : card.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      // if (card.subtitle.isNotEmpty) Text(card.subtitle),
                      // if (card.email.isNotEmpty) ...[
                      //   const SizedBox(height: 4),
                      //   Text(card.email),
                      // ],
                      if (card.remark.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          card.remark,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        'Saved on $dateLabel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDraftState extends StatelessWidget {
  const _EmptyDraftState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.center_focus_strong_outlined,
              size: 54,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text('No scan yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // Text(
            //   'Use the scanner above to capture a business card. Once scanned, the image, extracted details, and remark field will appear here.',
            //   textAlign: TextAlign.center,
            //   style: Theme.of(
            //     context,
            //   ).textTheme.bodyMedium?.copyWith(height: 1.5),
            // ),
          ],
        ),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.badge_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No remarks match your search' : 'No cards saved yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Try a different remark keyword or save a card with a note first.'
                : 'Scan a card, add a remark, and it will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DraftPreviewImage extends StatelessWidget {
  const _DraftPreviewImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF1E8D8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? kIsWeb
                ? const _PreviewFallback()
                : Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _PreviewFallback();
                    },
                  )
          : const _PreviewFallback(),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Preview unavailable',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SavedCardThumbnail extends StatelessWidget {
  const _SavedCardThumbnail({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCardImage(imagePath),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_full, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Open', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImageViewer extends StatefulWidget {
  const _CardImageViewer({required this.card});

  final SavedBusinessCard card;

  @override
  State<_CardImageViewer> createState() => _CardImageViewerState();
}

class _CardImageViewerState extends State<_CardImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _rotationTurns = 0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _resolvedImagePath(widget.card);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card.displayName.trim().isEmpty
              ? 'Card Image'
              : widget.card.displayName,
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
          ),
          IconButton(
            tooltip: 'Rotate',
            onPressed: _rotate,
            icon: const Icon(Icons.rotate_right),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF111512),
        alignment: Alignment.center,
        child: imagePath == null
            ? const _PreviewFallback()
            : InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Transform.rotate(
                    angle: _rotationTurns * math.pi / 2,
                    child: _buildCardImage(imagePath),
                  ),
                ),
              ),
      ),
    );
  }

  void _zoomIn() {
    _applyScale(1.2);
  }

  void _zoomOut() {
    _applyScale(1 / 1.2);
  }

  void _rotate() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  void _reset() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _rotationTurns = 0;
    });
  }

  void _applyScale(double factor) {
    final current = _transformationController.value.clone();
    _transformationController.value = current
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1));
  }
}

String? _resolvedImagePath(SavedBusinessCard card) {
  final remote = card.remotePath?.trim();
  if (remote != null && remote.isNotEmpty) {
    return remote;
  }

  final local = card.imagePath?.trim();
  if (local != null && local.isNotEmpty) {
    return local;
  }

  return null;
}

Widget _buildCardImage(String imagePath) {
  final isRemote =
      imagePath.startsWith('http://') || imagePath.startsWith('https://');
  if (isRemote) {
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _PreviewFallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  if (kIsWeb) {
    return const _PreviewFallback();
  }

  return Image.file(
    File(imagePath),
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => const _PreviewFallback(),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF5F665F)),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? 'Not available' : value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
