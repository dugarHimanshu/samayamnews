import 'dart:typed_data';
// screens/contributor/news_submission_form.dart


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/location_data.dart';
import '../../services/location_repository.dart';
import '../../services/category_repository.dart';
import '../../models/news_submission.dart';
import '../../services/submission_service.dart';
import 'my_submissions_screen.dart';

// ============================================================
// CONFIGURATION
// ============================================================

// Categories come from the API (/v1/categories); the fixed list is only a fallback if it's unreachable.
const List<String> _fallbackCategories = [
  'Politics',
  'Local',
  'National',
  'International',
  'Business',
  'Sports',
  'Entertainment',
  'Technology',
  'Health',
  'Education',
  'Crime',
  'Other',
];

List<String> get kNewsCategories {
  final fromApi = CategoryRepository.instance.items.map((c) => c.nameEn).toList();
  return fromApi.isNotEmpty ? fromApi : _fallbackCategories;
}

const List<String> kAllowedStates = ['Telangana', 'Andhra Pradesh'];

const List<String> kAllowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

const int kMaxImageSizeMb = 10;

const int kHeadlineMaxLength = 140;
const int kDescriptionMaxLength = 300;
const int kContentMaxLength = 10000;

// ============================================================
// NEWS SUBMISSION FORM
// ============================================================

class NewsSubmissionForm extends StatefulWidget {
  const NewsSubmissionForm({super.key});

  @override
  State<NewsSubmissionForm> createState() => _NewsSubmissionFormState();
}

class _NewsSubmissionFormState extends State<NewsSubmissionForm> {
  final _formKey = GlobalKey<FormState>();

  final _submissionService = SubmissionService();
  final _imagePicker = ImagePicker();

  // ----------------------------------------------------------
  // CONTROLLERS
  // ----------------------------------------------------------

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourceController = TextEditingController();
  final _authorController = TextEditingController();

  // ----------------------------------------------------------
  // LOCATION STATE
  // ----------------------------------------------------------

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCity;
  String? _selectedMandal;
  String? _selectedVillage;

  // ----------------------------------------------------------
  // FORM STATE
  // ----------------------------------------------------------

  String? _selectedCategory;

  XFile? _pickedImage;
  Uint8List? _pickedBytes; // works on web and mobile (no dart:io File)

  String? _userRole;

  int _todaySubmissionCount = 0;

  bool _loadingUsage = true;
  bool _submitting = false;

  // ----------------------------------------------------------
  // LIFECYCLE
  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();
    LocationRepository.instance.addListener(_onLocationsChanged);

    _loadRoleAndUsage();

    _titleController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
    _contentController.addListener(_refresh);
  }

  // Mandals/villages load on demand from the API; rebuild when they arrive.
  void _onLocationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LocationRepository.instance.removeListener(_onLocationsChanged);
    _titleController.removeListener(_refresh);
    _descriptionController.removeListener(_refresh);
    _contentController.removeListener(_refresh);

    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    _authorController.dispose();

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ROLE + USAGE
  // ============================================================

  Future<void> _loadRoleAndUsage() async {
    try {
      final role = await _submissionService.getCurrentUserRole();

      final count = await _submissionService.getTodaySubmissionCount();

      if (!mounted) return;

      setState(() {
        _userRole = role;
        _todaySubmissionCount = count;
        _loadingUsage = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingUsage = false;
      });
    }
  }

  bool get _isFreelancer => _userRole == 'freelancer';

  bool get _limitReached => _isFreelancer && _todaySubmissionCount >= 10;

  int get _remainingSubmissions => (10 - _todaySubmissionCount).clamp(0, 10);

  // ============================================================
  // LOCATION HELPERS
  // ============================================================

  List<String> get _districtOptions {
    if (_selectedState == null) {
      return const [];
    }

    return getDistrictsForState(_selectedState!);
  }

  List<String> get _cityOptions {
    if (_selectedState == null || _selectedDistrict == null) {
      return const [];
    }

    return getCitiesForDistrict(_selectedState!, _selectedDistrict!);
  }

  List<String> get _mandalOptions {
    if (_selectedState == null || _selectedDistrict == null) {
      return const [];
    }

    return getMandalsForDistrict(
      _selectedState!,
      _selectedDistrict!,
      city: _selectedCity,
    );
  }

  List<String> get _villageOptions {
    if (_selectedState == null ||
        _selectedDistrict == null ||
        _selectedMandal == null) {
      return const [];
    }

    return getVillagesForLocation(
      state: _selectedState!,
      district: _selectedDistrict!,
      city: _selectedCity,
      mandal: _selectedMandal!,
    );
  }

  // ============================================================
  // LOCATION SELECTION
  // ============================================================

  void _selectState(String? value) {
    if (value == null || value == _selectedState) {
      return;
    }

    setState(() {
      _selectedState = value;

      _selectedDistrict = null;
      _selectedCity = null;
      _selectedMandal = null;
      _selectedVillage = null;
    });
  }

  void _selectDistrict(String? value) {
    if (value == null || value == _selectedDistrict) {
      return;
    }

    setState(() {
      _selectedDistrict = value;

      _selectedCity = null;
      _selectedMandal = null;
      _selectedVillage = null;
    });
  }

  void _selectCity(String? value) {
    if (value == _selectedCity) {
      return;
    }

    setState(() {
      _selectedCity = value;

      _selectedMandal = null;
      _selectedVillage = null;
    });
  }

  void _selectMandal(String? value) {
    if (value == _selectedMandal) {
      return;
    }

    setState(() {
      _selectedMandal = value;

      _selectedVillage = null;
    });
  }

  void _selectVillage(String? value) {
    setState(() {
      _selectedVillage = value;
    });
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) {
        return;
      }

      // On web, `path` is a blob URL, so take the extension from the file name.
      final extension = picked.name.split('.').last.toLowerCase();

      if (!kAllowedImageExtensions.contains(extension)) {
        _showError('Please choose a JPG, JPEG, PNG, or WEBP image.');
        return;
      }

      final data = await picked.readAsBytes();

      final sizeInMb = data.length / (1024 * 1024);

      if (sizeInMb > kMaxImageSizeMb) {
        _showError(
          'This image is '
          '${sizeInMb.toStringAsFixed(1)}MB. '
          'Please choose an image under '
          '$kMaxImageSizeMb MB.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _pickedImage = picked;
        _pickedBytes = data;
      });
    } catch (_) {
      _showError('We could not select that image. Please try again.');
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _pickedBytes = null;
    });
  }

  // ============================================================
  // FRIENDLY ERROR HANDLING
  // ============================================================

  void _showFriendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('storage') ||
        message.contains('upload') ||
        message.contains('bucket')) {
      _showError('We could not upload your image. Please try again.');
      return;
    }

    if (message.contains('permission') ||
        message.contains('row level security') ||
        message.contains('forbidden') ||
        message.contains('unauthorized')) {
      _showError('You do not have permission to complete this action.');
      return;
    }

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      _showError('Please check your internet connection and try again.');
      return;
    }

    _showError('Something went wrong. Please try again.');
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (_submitting) {
      return;
    }

    if (_limitReached) {
      _showError('You have reached your 10 submissions for today.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showError('Please complete the highlighted fields.');
      return;
    }

    if (_selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }

    // ONLY STATE + DISTRICT ARE REQUIRED.
    if (_selectedState == null) {
      _showError('Please select a state.');
      return;
    }

    if (_selectedDistrict == null) {
      _showError('Please select a district.');
      return;
    }

    final shouldSubmit = await _showSubmitConfirmation();

    if (!shouldSubmit) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _submitting = true;
    });

    try {
      // Upload goes straight to storage via a signed URL; we get back a media id.
      String? coverMediaId;

      if (_pickedImage != null) {
        coverMediaId = await _submissionService.uploadImage(_pickedBytes!, fileName: _pickedImage!.name);
      }

      // LGD has no city level: region = mandal.
      final regionValue = _selectedMandal ?? _selectedCity;

      final submission = NewsSubmission(
        submitterId: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        author: _authorController.text.trim(),
        source: _sourceController.text.trim(),
        content: _contentController.text.trim(),
        coverMediaId: coverMediaId,
        state: _selectedState!,
        district: _selectedDistrict!,
        region: regionValue,
        village: _selectedVillage,
      );

      await _submissionService.submitNews(submission);

      if (!mounted) return;

      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;

      _showFriendlyError(e);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool> _showSubmitConfirmation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1EF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 25,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Ready to submit?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Your story will be sent to our editorial '
                  'team for review before it can be published.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 22),

                _confirmationRow(
                  Icons.article_outlined,
                  'Headline',
                  _titleController.text.trim(),
                ),

                const SizedBox(height: 8),

                _confirmationRow(
                  Icons.category_outlined,
                  'Category',
                  _selectedCategory ?? '-',
                ),

                const SizedBox(height: 8),

                _confirmationRow(
                  Icons.map_outlined,
                  'State',
                  _selectedState ?? '-',
                ),

                const SizedBox(height: 8),

                _confirmationRow(
                  Icons.location_on_outlined,
                  'District',
                  _selectedDistrict ?? '-',
                ),

                if (_selectedCity != null) ...[
                  const SizedBox(height: 8),
                  _confirmationRow(
                    Icons.location_city_outlined,
                    'City',
                    _selectedCity!,
                  ),
                ],

                if (_selectedMandal != null) ...[
                  const SizedBox(height: 8),
                  _confirmationRow(
                    Icons.explore_outlined,
                    'Mandal',
                    _selectedMandal!,
                  ),
                ],

                if (_selectedVillage != null) ...[
                  const SizedBox(height: 8),
                  _confirmationRow(
                    Icons.home_work_outlined,
                    'Village',
                    _selectedVillage!,
                  ),
                ],

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFE5E5E5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Review',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Submit story',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Widget _confirmationRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.black54),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF7EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 35,
                    color: Color(0xFF318451),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Story submitted',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your story has been sent to the editorial '
                  'team. You will be notified when there is '
                  'an update.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),

        titleSpacing: 0,

        title: Text(
          'Create a story',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MySubmissionsScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded, color: Colors.black87),
            tooltip: 'My Submissions',
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ScrollConfiguration(
            behavior: const _NoScrollbarBehavior(),
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                _buildHero(),

                const SizedBox(height: 18),

                _buildUsageBanner(),

                const SizedBox(height: 26),

                _sectionHeader(
                  number: '01',
                  title: 'Story information',
                  subtitle: 'Tell us what happened and why it matters.',
                ),

                const SizedBox(height: 14),

                _buildStoryCard(),

                const SizedBox(height: 26),

                _sectionHeader(
                  number: '02',
                  title: 'Where did it happen?',
                  subtitle: 'Choose the area covered by the story.',
                ),

                const SizedBox(height: 14),

                _buildLocationCard(),

                const SizedBox(height: 26),

                _sectionHeader(
                  number: '03',
                  title: 'Story content',
                  subtitle: 'Give our editors enough information to verify it.',
                ),

                const SizedBox(height: 14),

                _buildContentCard(),

                const SizedBox(height: 26),

                _sectionHeader(
                  number: '04',
                  title: 'Source & reporter',
                  subtitle: 'Help our editorial team verify the information.',
                ),

                const SizedBox(height: 14),

                _buildSourceCard(),

                const SizedBox(height: 26),

                _sectionHeader(
                  number: '05',
                  title: 'Add a photo',
                  subtitle: 'A clear image can make your story much stronger.',
                ),

                const SizedBox(height: 14),

                _buildImageCard(),

                const SizedBox(height: 28),

                _buildSubmissionNote(),

                const SizedBox(height: 16),

                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 22,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NEWSROOM SUBMISSION',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Text(
                'Have a story?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Share what is happening around you. '
                'Our editorial team will review it before publishing.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 17),

              Row(
                children: [
                  _heroInfo(Icons.verified_outlined, 'Editorial review'),
                  const SizedBox(width: 14),
                  _heroInfo(Icons.location_on_outlined, 'AP + Telangana'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white60),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USAGE
  // ============================================================

  Widget _buildUsageBanner() {
    if (_loadingUsage) {
      return Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    if (!_isFreelancer) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCEFE0)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFDFF1E3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.all_inclusive_rounded,
                size: 19,
                color: Color(0xFF317D4C),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No daily submission limit',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You can submit as many stories as your role allows.',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final progress = (_todaySubmissionCount / 10).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _limitReached ? const Color(0xFFFFF1F1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _limitReached
              ? const Color(0xFFF3D6D6)
              : const Color(0xFFEAEAE7),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _limitReached
                      ? const Color(0xFFFFE2E2)
                      : const Color(0xFFF1F1EF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _limitReached ? Icons.block_rounded : Icons.bolt_rounded,
                  size: 19,
                  color: _limitReached ? Colors.redAccent : Colors.black87,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s submissions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _limitReached
                          ? 'Your daily limit has been reached.'
                          : 'You have $_remainingSubmissions '
                                'submissions remaining today.',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: _limitReached
                            ? Colors.redAccent
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '$_todaySubmissionCount/10',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _limitReached ? Colors.redAccent : Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.06),
              color: _limitReached ? Colors.redAccent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 9.5, color: Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STORY CARD
  // ============================================================

  Widget _buildStoryCard() {
    return _formCard(
      children: [
        _textField(
          _titleController,
          'Headline',
          required: true,
          maxLength: kHeadlineMaxLength,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 2),

        _textField(
          _descriptionController,
          'Short description',
          required: true,
          maxLines: 4,
          maxLength: kDescriptionMaxLength,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 2),

        _dropdown(
          label: 'Category',
          value: _selectedCategory,
          items: kNewsCategories,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          icon: Icons.category_outlined,
          searchHint: 'Search categories',
          emptySearchText: 'No category found',
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _buildLocationCard() {
    return _formCard(
      children: [
        // ------------------------------------------------------
        // STATE - REQUIRED
        // ------------------------------------------------------
        _dropdown(
          label: 'State *',
          value: _selectedState,
          items: kAllowedStates,
          onChanged: _selectState,
          icon: Icons.map_outlined,
          searchHint: 'Search states',
          emptySearchText: 'No state found',
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // DISTRICT - REQUIRED
        // ------------------------------------------------------
        _dropdown(
          label: 'District *',
          value: _selectedDistrict,
          items: _districtOptions,
          enabled: _selectedState != null,
          onChanged: _selectDistrict,
          icon: Icons.location_on_outlined,
          searchHint: 'Search districts',
          emptySearchText: 'No district found',
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // CITY - OPTIONAL
        // ------------------------------------------------------
        _dropdown(
          label: 'City',
          value: _selectedCity,
          items: _cityOptions,
          enabled: _selectedDistrict != null && _cityOptions.isNotEmpty,
          onChanged: _selectCity,
          icon: Icons.location_city_outlined,
          searchHint: 'Search cities',
          emptySearchText: 'No city found',
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // MANDAL / REGION - OPTIONAL
        // ------------------------------------------------------
        _dropdown(
          label: 'Mandal / Region',
          value: _selectedMandal,
          items: _mandalOptions,
          enabled: _selectedDistrict != null && _mandalOptions.isNotEmpty,
          onChanged: _selectMandal,
          icon: Icons.explore_outlined,
          searchHint: 'Search Mandals / Regions',
          emptySearchText: 'No Mandal found',
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // VILLAGE / LOCALITY - OPTIONAL
        // ------------------------------------------------------
        _dropdown(
          label: 'Village / Locality',
          value: _selectedVillage,
          items: _villageOptions,
          enabled: _selectedMandal != null && _villageOptions.isNotEmpty,
          onChanged: _selectVillage,
          icon: Icons.home_work_outlined,
          searchHint: 'Search villages / localities',
          emptySearchText: 'No village found',
        ),

        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Colors.black38,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'State and district are required. '
                'City, Mandal / Region and Village / Locality are optional.',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  height: 1.35,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT CARD
  // ============================================================

  Widget _buildContentCard() {
    return _formCard(
      children: [
        _textField(
          _contentController,
          'Full story',
          required: true,
          maxLines: 12,
          maxLength: kContentMaxLength,
          textCapitalization: TextCapitalization.sentences,
          hint:
              'Explain what happened, when it happened, '
              'who was involved and any important details...',
        ),

        const SizedBox(height: 2),

        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 17,
                color: Colors.black54,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tip: Include facts, names, dates, locations and '
                  'anything that can help our editors verify the story.',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SOURCE CARD
  // ============================================================

  Widget _buildSourceCard() {
    return _formCard(
      children: [
        _textField(
          _sourceController,
          'Source',
          required: true,
          prefixIcon: Icons.link_rounded,
          hint: 'Example: Local resident, official statement...',
        ),

        const SizedBox(height: 2),

        _textField(
          _authorController,
          'Author / Reporter',
          required: true,
          prefixIcon: Icons.person_outline_rounded,
          hint: 'Name of the person reporting this story',
        ),

        const SizedBox(height: 3),

        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your submission will be reviewed by the '
                  'editorial team before publication.',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE CARD
  // ============================================================

  Widget _buildImageCard() {
    return Column(
      children: [
        GestureDetector(
          onTap: _submitting ? null : _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _pickedImage == null
                    ? const Color(0xFFE5E5E2)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pickedImage == null
                ? _buildEmptyImageState()
                : _buildImagePreview(),
          ),
        ),

        const SizedBox(height: 11),

        _buildImageRequirements(),
      ],
    );
  }

  Widget _buildEmptyImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 27,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Add a story image',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Tap to choose from your gallery',
          style: GoogleFonts.inter(fontSize: 9.5, color: Colors.black45),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'OPTIONAL',
            style: GoogleFonts.inter(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.black45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_pickedBytes!, fit: BoxFit.cover),

        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Image selected',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              _imageAction(
                icon: Icons.refresh_rounded,
                tooltip: 'Change image',
                onTap: _pickImage,
              ),
              const SizedBox(width: 7),
              _imageAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove image',
                onTap: _removeImage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildImageRequirements() {
    return Row(
      children: [
        _requirementChip(Icons.image_outlined, 'JPG / PNG / WEBP'),
        const SizedBox(width: 6),
        _requirementChip(Icons.data_usage_rounded, 'MAX ${kMaxImageSizeMb}MB'),
        const SizedBox(width: 6),
        _requirementChip(Icons.verified_outlined, 'VALID FILE'),
      ],
    );
  }

  Widget _requirementChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1EF),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.black45),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBMISSION NOTE
  // ============================================================

  Widget _buildSubmissionNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 17,
              color: Colors.black54,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you submit',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Make sure the information is accurate. '
                  'An editor will verify and review your story '
                  'before it is published.',
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_submitting || _limitReached) ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.black12,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.black38,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _limitReached
                            ? Icons.block_rounded
                            : Icons.send_rounded,
                        size: 17,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        _limitReached
                            ? 'DAILY LIMIT REACHED'
                            : 'SUBMIT FOR EDITORIAL REVIEW',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          _limitReached
              ? 'You can submit again tomorrow.'
              : 'Your story will be reviewed before publication.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 9, color: Colors.black38),
        ),
      ],
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _formCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.045)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    String? hint,
    IconData? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 11, color: Colors.black26),
        labelStyle: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF8F8F6),
        counterStyle: GoogleFonts.inter(fontSize: 8, color: Colors.black38),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE4A4A4)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ============================================================
  // SEARCHABLE DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    String searchHint = 'Search',
    String emptySearchText = 'No results found',
    bool enabled = true,
  }) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return DropdownMenu<String>(
      width: double.infinity,
      enabled: enabled,
      initialSelection: safeValue,
      requestFocusOnTap: true,
      enableFilter: true,
      enableSearch: true,
      menuHeight: 300,
      expandedInsets: EdgeInsets.zero,
      hintText: label,
      label: Text(label),
      leadingIcon: Icon(
        icon,
        size: 18,
        color: enabled ? Colors.black38 : Colors.black26,
      ),
      trailingIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: Colors.black45,
      ),
      selectedTrailingIcon: const Icon(
        Icons.keyboard_arrow_up_rounded,
        size: 20,
        color: Colors.black45,
      ),
      searchCallback: (entries, query) {
        final normalizedQuery = query.trim().toLowerCase();

        if (normalizedQuery.isEmpty) {
          return null;
        }

        for (var index = 0; index < entries.length; index++) {
          final label = entries[index].label.toLowerCase();

          if (label.contains(normalizedQuery)) {
            return index;
          }
        }

        return null;
      },
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: enabled ? const Color(0xFFF8F8F6) : const Color(0xFFF1F1EF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        labelStyle: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 300)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      dropdownMenuEntries: items
          .map((item) => DropdownMenuEntry<String>(value: item, label: item))
          .toList(),
      onSelected: enabled ? onChanged : null,
    );
  }

  // ============================================================
  // HIDE SCROLLBAR
  // ============================================================

  // This is intentionally kept as a separate ScrollBehavior so
  // the form stays visually clean on platforms that display
  // scrollbar overlays.
}

// ============================================================
// NO SCROLLBAR
// ============================================================

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}