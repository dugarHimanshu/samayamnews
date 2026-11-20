import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Helper function to check if a URL represents a video.
bool isVideoUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final clean = url.split('?').first.toLowerCase();
  return clean.endsWith('.mp4') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.m4v') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.avi') ||
      clean.endsWith('.mkv') ||
      url.contains('video') ||
      url.contains('.mp4');
}

/// Helper function to check if a local file is a video.
bool isVideoFile(File? file) {
  if (file == null) return false;
  final path = file.path.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v') ||
      path.endsWith('.webm') ||
      path.endsWith('.avi') ||
      path.endsWith('.mkv');
}

/// Unified media viewer that seamlessly renders either a video or an image.
class AppMediaViewer extends StatefulWidget {
  final String? url;
  final File? file;
  final BoxFit fit;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final Widget? placeholder;

  const AppMediaViewer({
    super.key,
    this.url,
    this.file,
    this.fit = BoxFit.cover,
    this.autoPlay = true,
    this.looping = true,
    this.showControls = true,
    this.placeholder,
  });

  @override
  State<AppMediaViewer> createState() => _AppMediaViewerState();
}

class _AppMediaViewerState extends State<AppMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = true;

  bool get _isVideo {
    if (widget.file != null) return isVideoFile(widget.file);
    return isVideoUrl(widget.url);
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant AppMediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url || widget.file?.path != oldWidget.file?.path) {
      _disposeVideo();
      if (_isVideo) {
        _initVideo();
      } else {
        setState(() {
          _isInitialized = false;
          _hasError = false;
        });
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      if (widget.file != null) {
        _videoController = VideoPlayerController.file(widget.file!);
      } else if (widget.url != null && widget.url!.isNotEmpty) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      } else {
        return;
      }

      await _videoController!.initialize();
      await _videoController!.setLooping(widget.looping);
      await _videoController!.setVolume(_isMuted ? 0 : 1);

      if (widget.autoPlay) {
        await _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _disposeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo) {
      return _buildVideoPlayer();
    }
    return _buildImageViewer();
  }

  Widget _buildVideoPlayer() {
    if (_hasError) {
      return Container(
        color: const Color(0xFF1F1F1F),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_camera_back_outlined, size: 36, color: Colors.white38),
              SizedBox(height: 6),
              Text(
                'Video unavailable',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _videoController == null) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        ),
      );
    }

    final isPlaying = _videoController!.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The Video Render
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),

          // Play / Pause Overlay Icon (Visible when paused)
          if (widget.showControls && !isPlaying)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.play_arrow_rounded, size: 36, color: Colors.black87),
                ),
              ),
            ),

          // Controls & Indicators (Sound toggle & Video pill)
          if (widget.showControls) ...[
            // Mute / Unmute Button in bottom right
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Video indicator pill
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    if (widget.file != null) {
      return Image.file(
        widget.file!,
        fit: widget.fit,
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    }

    if (widget.url != null && widget.url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.url!,
        fit: widget.fit,
        placeholder: (_, _) => widget.placeholder ?? Container(color: Colors.grey.shade200),
        errorWidget: (_, _, _) => _errorPlaceholder(),
      );
    }

    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return widget.placeholder ??
        Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: Colors.black26, size: 36),
          ),
        );
  }
}
