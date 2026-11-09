import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/magazine.dart';
import '../../services/magazine_store.dart';

class MagazineReaderPage extends StatefulWidget {
  final Magazine magazine;

  const MagazineReaderPage({
    super.key,
    required this.magazine,
  });

  @override
  State<MagazineReaderPage> createState() => _MagazineReaderPageState();
}

class _MagazineReaderPageState extends State<MagazineReaderPage> {
  final MagazineStore _store = MagazineStore.instance;

  String? _localPdfPath;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _store.load().then((_) {
      if (mounted) setState(() {});
    });
    _downloadAndPreparePdf();
  }

  Future<void> _downloadAndPreparePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filename = 'mag_${widget.magazine.id}.pdf';
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      // If already cached locally, open directly
      if (await file.exists() && (await file.length()) > 500) {
        if (!mounted) return;
        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
        return;
      }

      // Try network download with timeout
      bool networkSuccess = false;
      try {
        final response = await http
            .get(Uri.parse(widget.magazine.pdfUrl))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 && response.bodyBytes.length > 500) {
          await file.writeAsBytes(response.bodyBytes);
          networkSuccess = true;
        }
      } catch (_) {
        networkSuccess = false;
      }

      // If network fails, copy offline bundled asset PDF as instant fallback
      if (!networkSuccess) {
        final byteData = await rootBundle.load('assets/magazines/dummy.pdf');
        final bytes = byteData.buffer.asUint8List();
        await file.writeAsBytes(bytes);
      }

      if (!mounted) return;
      setState(() {
        _localPdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load the magazine PDF. Please check your internet connection.';
      });
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);
    HapticFeedback.lightImpact();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/mag_${widget.magazine.id}.pdf');

      if (!await file.exists()) {
        final response = await http.get(Uri.parse(widget.magazine.pdfUrl));
        await file.writeAsBytes(response.bodyBytes);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded "${widget.magazine.title}" to storage!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download failed. Try again.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _handleShare() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Read "${widget.magazine.title}" (${widget.magazine.issue}) on Samayam News!\n${widget.magazine.pdfUrl}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _store.isLiked(widget.magazine.id);
    final isSaved = _store.isSaved(widget.magazine.id);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.magazine.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.magazine.issue,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          // Like
          IconButton(
            tooltip: 'Like',
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isLiked ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _store.toggleLike(widget.magazine.id);
              setState(() {});
            },
          ),
          // Bookmark
          IconButton(
            tooltip: 'Bookmark',
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isSaved ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _store.toggleSave(widget.magazine.id);
              setState(() {});
            },
          ),
          // Download
          IconButton(
            tooltip: 'Download PDF',
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _handleDownload,
          ),
          // Share
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _handleShare,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading magazine...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _downloadAndPreparePdf,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_localPdfPath != null)
            PDFView(
              filePath: _localPdfPath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              fitEachPage: true,
              backgroundColor: const Color(0xFF141414),
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? 0;
                  _totalPages = total ?? 0;
                });
              },
              onError: (error) {
                setState(() {
                  _errorMessage = error.toString();
                });
              },
            ),

          // Bottom floating page counter badge
          if (_totalPages > 0)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
