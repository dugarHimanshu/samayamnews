import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';
import '../common/app_media_viewer.dart';

class OnePageNewsCard extends StatefulWidget {
  final NewsArticle article;
  final VoidCallback onReadMore;
  final VoidCallback? onLike;

  const OnePageNewsCard({
    super.key,
    required this.article,
    required this.onReadMore,
    this.onLike,
  });

  @override
  State<OnePageNewsCard> createState() => _OnePageNewsCardState();
}

class _OnePageNewsCardState extends State<OnePageNewsCard> {
  bool _isLiked = false;

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.88,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _buildNewsImage(),

            _buildImageGradient(),

            _buildLikeButton(),

            _buildNewsInformation(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsImage() {
    return Positioned.fill(
      child: AppMediaViewer(
        url: widget.article.imageUrl,
        fit: BoxFit.cover,
        autoPlay: true,
        looping: true,
        showControls: true,
      ),
    );
  }

  Widget _buildImageGradient() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.35, 0.65, 1.0],
            colors: [
              Colors.black.withValues(alpha: 0.08),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.20),
              Colors.black.withValues(alpha: 0.88),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return Positioned(
      right: 18,
      top: MediaQuery.of(context).size.height * 0.38,
      child: GestureDetector(
        onTap: _toggleLike,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_isLiked),
              color: _isLiked ? Colors.redAccent : Colors.white,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsInformation() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategory(),

          const SizedBox(height: 10),

          _buildHeadline(),

          const SizedBox(height: 10),

          _buildDescription(),

          const SizedBox(height: 16),

          _buildMetaAndReadMore(),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        widget.article.category.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Text(
      widget.article.title,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.playfairDisplay(
        color: Colors.white,
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.article.description,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: Colors.white.withValues(alpha: 0.95),
        fontSize: 14.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMetaAndReadMore() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildAuthorInformation()),

        const SizedBox(width: 12),

        _buildReadMoreButton(),
      ],
    );
  }

  Widget _buildAuthorInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.article.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          widget.article.publishedAt,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReadMoreButton() {
    return GestureDetector(
      onTap: widget.onReadMore,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Read More',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}