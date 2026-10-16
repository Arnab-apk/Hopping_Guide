import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pandal.dart';
import '../models/pandal_photo.dart';

/// A compact gallery entry point; full-size images load only when opened.
class PandalPhotoGallery extends StatelessWidget {
  const PandalPhotoGallery({super.key, required this.pandal});
  final Pandal pandal;

  @override
  Widget build(BuildContext context) {
    final photos = pandal.photoGallery;
    final colors = Theme.of(context).colorScheme;
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Photos are not available for this pandal yet.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Semantics(
              button: true,
              label: 'Open ${photos.length} photos of ${pandal.name}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () => _open(context, photos),
                child: PandalPhotoImage(
                    photo: photos.first, pandalName: pandal.name),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => _open(context, photos),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text('View ${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}'),
        ),
        if (photos.first.credit.isNotEmpty)
          Text('Photo: ${photos.first.credit}',
              style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _open(BuildContext context, List<PandalPhoto> photos) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PandalPhotoViewer(pandalName: pandal.name, photos: photos),
    ));
  }
}

/// Shared cached cover/fullscreen image with honest network-failure feedback.
class PandalPhotoImage extends StatelessWidget {
  const PandalPhotoImage({
    super.key,
    required this.photo,
    required this.pandalName,
    this.fit = BoxFit.cover,
    this.fullSize = false,
  });
  final PandalPhoto photo;
  final String pandalName;
  final BoxFit fit;
  final bool fullSize;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: photo.caption.isEmpty ? 'Photograph of $pandalName' : photo.caption,
    child: CachedNetworkImage(
      imageUrl: photo.url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: fullSize ? 1600 : 720,
      placeholder: (_, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Photo unavailable. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ),
    ),
  );
}

class PandalPhotoViewer extends StatefulWidget {
  const PandalPhotoViewer({
    super.key,
    required this.pandalName,
    required this.photos,
  }) : assert(photos.length > 0);
  final String pandalName;
  final List<PandalPhoto> photos;

  @override
  State<PandalPhotoViewer> createState() => _PandalPhotoViewerState();
}

class _PandalPhotoViewerState extends State<PandalPhotoViewer> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int page) {
    // Button alternatives to swiping also work with a zoomed photograph.
    _controller.jumpToPage(page);
  }

  Future<void> _openSource(PandalPhoto photo) async {
    if (!PandalPhoto.isSupportedUrl(photo.sourceUrl)) return;
    try {
      final opened = await launchUrl(Uri.parse(photo.sourceUrl),
          mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {
      // Keep the photo viewer usable when there is no browser handler.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the photo source.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.pandalName)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => InteractiveViewer(
                  key: ValueKey(index),
                  minScale: 1,
                  maxScale: 4,
                  child: PandalPhotoImage(
                    photo: widget.photos[index],
                    pandalName: widget.pandalName,
                    fit: BoxFit.contain,
                    fullSize: true,
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.caption.isNotEmpty) Text(photo.caption),
                    if (photo.year != null) Text('Puja ${photo.year}'),
                    if (photo.credit.isNotEmpty) Text('Photo: ${photo.credit}'),
                    if (PandalPhoto.isSupportedUrl(photo.sourceUrl))
                      TextButton.icon(
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        onPressed: () => _openSource(photo),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('View original source'),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous photo',
                  onPressed: _index > 0 ? () => _move(_index - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                Flexible(
                  child: Semantics(
                    liveRegion: true,
                    child: Text('Photo ${_index + 1} of ${widget.photos.length}'),
                  ),
                ),
                IconButton(
                  tooltip: 'Next photo',
                  onPressed: _index + 1 < widget.photos.length
                      ? () => _move(_index + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
