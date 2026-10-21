// Mirrors the news_submissions table in Supabase.
// Used both when building a submission to send up, and when
// reading back a user's own past submissions.
class NewsSubmission {
  final String? id; // null until Supabase assigns one on insert
  final String submitterId;
  final String title;
  final String description;
  final String category;
  final String author;
  final String source;
  final String content;
  final String? imageUrl;

  // structured location instead of one free text field
  final String state; // 'Telangana' or 'Andhra Pradesh' only
  final String district;
  final String? region; // mandal
  final String? village;

  final String status; // pending / in_review / approved / rejected / published
  final DateTime?
  submittedAt; // set automatically by Supabase, never user-entered

  const NewsSubmission({
    this.id,
    required this.submitterId,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.source,
    required this.content,
    this.imageUrl,
    required this.state,
    required this.district,
    this.region,
    this.village,
    this.status = 'pending',
    this.submittedAt,
  });

  // Converts this object into a map ready to insert into Supabase.
  // We deliberately leave out id/status/submittedAt — the database
  // fills those in itself (defaults + trigger), so the user never
  // sees or controls them from the app.
  Map<String, dynamic> toInsertMap() {
    return {
      'submitter_id': submitterId,
      'title': title,
      'description': description,
      'category': category,
      'author': author,
      'source': source,
      'content': content,
      'image_url': imageUrl,
      'state': state,
      'district': district,
      'region': region,
      'village': village,
    };
  }

  // Converts a row coming back from Supabase into this object.
  factory NewsSubmission.fromMap(Map<String, dynamic> map) {
    return NewsSubmission(
      id: map['id'] as String?,
      submitterId: map['submitter_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      author: map['author'] as String,
      source: map['source'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      state: map['state'] as String,
      district: map['district'] as String,
      region: map['region'] as String?,
      village: map['village'] as String?,
      status: map['status'] as String,
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'] as String)
          : null,
    );
  }
}
