import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_article.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;
  final bool showCategory;
  final bool showDescription;

  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
    this.showCategory = true,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(),
                const SizedBox(width: 14),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: Image.network(
        article.imageUrl,
        width: 105,
        height: 125,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 105,
            height: 125,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, color: Colors.black38),
          );
        },
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return SizedBox(
      height: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // CATEGORY
          // ------------------------------------------------------
          if (showCategory) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                article.category.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.black54,
                ),
              ),
            ),

            const SizedBox(height: 7),
          ],

          // ------------------------------------------------------
          // TITLE
          // ------------------------------------------------------
          Text(
            article.title,
            maxLines: showDescription ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: Colors.black,
            ),
          ),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------
          if (showDescription) ...[
            const Spacer(),

            Text(
              article.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
          ],

          const Spacer(),

          // ------------------------------------------------------
          // AUTHOR + TIME
          // ------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  article.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Text(
                article.publishedAt,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
