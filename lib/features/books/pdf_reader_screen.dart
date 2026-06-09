import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/post_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../core/utils/r2_helper.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final PostModel post;
  final String filePath;

  const PdfReaderScreen({super.key, required this.post, required this.filePath});

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _totalPages = 0;
  bool _showControls = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateProgress(int page) {
    if (_totalPages > 0) {
      final pct = page / _totalPages;
      ref.read(readingProgressProvider.notifier).update(widget.post.id, pct);
    }
  }

  String get _pdfUrl => R2Helper.postPdf(widget.filePath);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: _showControls
          ? AppBar(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (_totalPages > 0)
                    Text('Page ${_controller.pageNumber} of $_totalPages',
                        style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              actions: [
                // Progress indicator
                if (_totalPages > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    child: Text(
                      '${((_controller.pageNumber / _totalPages) * 100).round()}%',
                      style: const TextStyle(color: NZColors.gold, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: SfPdfViewer.network(
          _pdfUrl,
          controller: _controller,
          onDocumentLoaded: (details) {
            setState(() => _totalPages = details.document.pages.count);
          },
          onPageChanged: (details) {
            setState(() {});
            _updateProgress(details.newPageNumber);
          },
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
        ),
      ),
      bottomNavigationBar: _showControls && _totalPages > 0
          ? Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.first_page, color: Colors.white70),
                      onPressed: () => _controller.firstPage(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: () => _controller.previousPage(),
                    ),
                    Expanded(
                      child: Slider(
                        value: _controller.pageNumber.toDouble().clamp(1.0, _totalPages.toDouble()),
                        min: 1,
                        max: _totalPages.toDouble(),
                        activeColor: NZColors.saffron,
                        inactiveColor: Colors.white24,
                        onChanged: (v) => _controller.jumpToPage(v.round()),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () => _controller.nextPage(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page, color: Colors.white70),
                      onPressed: () => _controller.lastPage(),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
