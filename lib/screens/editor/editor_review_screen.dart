// screens/editor/editor_review_screen.dart

import 'package:flutter/material.dart';

import '../../data/location_data.dart';
import '../../models/news_submission.dart';
import '../../services/editor_service.dart';
import '../../widgets/common/app_media_viewer.dart';
import '../contributor/news_submission_form.dart'
    show kNewsCategories, kAllowedStates;

class EditorReviewScreen extends StatefulWidget {
  final NewsSubmission submission;

  const EditorReviewScreen({super.key, required this.submission});

  @override
  State<EditorReviewScreen> createState() => _EditorReviewScreenState();
}

class _EditorReviewScreenState extends State<EditorReviewScreen>
    with SingleTickerProviderStateMixin {
  final _editorService = EditorService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  late final TextEditingController _sourceController;
  late final TextEditingController _authorController;
  late final TextEditingController _regionController;
  late final TextEditingController _villageController;

  late String _category;
  late String _state;
  late String _district;

  String? _city;
  String? _mandal;
  String? _village;

  bool _claiming = true;
  bool _busy = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  // ============================================================
  // LOCATION OPTIONS
  // ============================================================

  List<String> get _districtOptions {
    return getDistrictsForState(_state);
  }

  List<String> get _cityOptions {
    return getCitiesForDistrict(_state, _district);
  }

  List<String> get _mandalOptions {
    return getMandalsForDistrict(_state, _district, city: _city);
  }

  List<String> get _villageOptions {
    if (_mandal == null || _mandal!.isEmpty) {
      return const [];
    }

    return getVillagesForLocation(
      state: _state,
      district: _district,
      city: _city,
      mandal: _mandal!,
    );
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    final s = widget.submission;

    _titleController = TextEditingController(text: s.title);

    _descriptionController = TextEditingController(text: s.description);

    _contentController = TextEditingController(text: s.content);

    _sourceController = TextEditingController(text: s.source);

    _authorController = TextEditingController(text: s.author);

    _regionController = TextEditingController(text: s.region ?? '');

    _villageController = TextEditingController(text: s.village ?? '');

    _category = s.category;
    _state = s.state;
    _district = s.district;

    _initializeLocationFromSubmission();

    _claim();
  }

  // ============================================================
  // LOCATION INITIALIZATION
  // ============================================================

  void _initializeLocationFromSubmission() {
    /*
     * Current NewsSubmission has:
     *
     * state
     * district
     * region
     * village
     *
     * but does not yet have a dedicated city field.
     *
     * Therefore we try to interpret the existing `region`
     * against the new local hierarchy.
     *
     * Priority:
     *
     * 1. Existing region matches a Mandal -> select Mandal.
     * 2. Existing region matches a City -> select City.
     * 3. Otherwise preserve it in the text controller so
     *    existing data is not silently discarded.
     */

    final region = sSafe(widget.submission.region);

    final village = sSafe(widget.submission.village);

    _village = null;

    if (village.isNotEmpty && _state.isNotEmpty && _district.isNotEmpty) {
      final possibleMandals = getMandalsForDistrict(_state, _district);

      for (final mandalName in possibleMandals) {
        final villages = getVillagesForLocation(
          state: _state,
          district: _district,
          mandal: mandalName,
        );

        if (villages.contains(village)) {
          _mandal = mandalName;
          _village = village;
          break;
        }
      }
    }

    if (region.isEmpty) {
      return;
    }

    final districtData = getLocationDistrict(_state, _district);

    if (districtData == null) {
      return;
    }

    // ----------------------------------------------------------
    // Try City
    // ----------------------------------------------------------

    final cityMatch = districtData.cityByName(region);

    if (cityMatch != null) {
      _city = cityMatch.name;
      _regionController.clear();

      // If village was not resolved yet, try again within city.
      if (_village == null) {
        for (final mandal in cityMatch.mandals) {
          if (mandal.villages.contains(village)) {
            _mandal = mandal.name;
            _village = village;
            break;
          }
        }
      }

      return;
    }

    // ----------------------------------------------------------
    // Try Mandal
    // ----------------------------------------------------------

    final mandalMatch = districtData.mandalByName(region);

    if (mandalMatch != null) {
      _mandal = mandalMatch.name;
      _regionController.clear();

      if (_village == null && mandalMatch.villages.contains(village)) {
        _village = village;
      }

      return;
    }

    // ----------------------------------------------------------
    // Unknown legacy region
    // ----------------------------------------------------------
    //
    // Keep the existing value visible rather than losing it.
    //
  }

  String sSafe(String? value) {
    return value?.trim() ?? '';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _animController.dispose();

    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    _authorController.dispose();
    _regionController.dispose();
    _villageController.dispose();

    super.dispose();
  }

  // ============================================================
  // CLAIM
  // ============================================================

  Future<void> _claim() async {
    try {
      await _editorService.claimSubmission(widget.submission.id!);

      if (!mounted) return;

      setState(() {
        _claiming = false;
      });

      _animController.forward();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _claiming = false;
      });

      _showMessage(
        'We could not open this story for review. Please try again.',
      );
    }
  }

  // ============================================================
  // LOCATION SELECTION
  // ============================================================

  void _onStateChanged(String? value) {
    if (value == null || value == _state) {
      return;
    }

    final districts = getDistrictsForState(value);

    setState(() {
      _state = value;

      if (districts.contains(_district)) {
        // Keep the current district when it is valid
      } else {
        _district = districts.isNotEmpty ? districts.first : '';
      }

      _city = null;
      _mandal = null;
      _village = null;

      _regionController.clear();
      _villageController.clear();
    });
  }

  void _onDistrictChanged(String? value) {
    if (value == null || value == _district) {
      return;
    }

    setState(() {
      _district = value;

      _city = null;
      _mandal = null;
      _village = null;

      _regionController.clear();
      _villageController.clear();
    });
  }

  void _onCityChanged(String? value) {
    setState(() {
      _city = value;
      _mandal = null;
      _village = null;

      _regionController.clear();
      _villageController.clear();
    });
  }

  void _onMandalChanged(String? value) {
    setState(() {
      _mandal = value;
      _village = null;

      _regionController.clear();
      _villageController.clear();
    });
  }

  void _onVillageChanged(String? value) {
    setState(() {
      _village = value;
      _villageController.text = value ?? '';
    });
  }

  // ============================================================
  // CURRENT FIELDS
  // ============================================================

  Map<String, dynamic> _currentFields() {
    String? regionValue;

    if (_mandal != null && _mandal!.trim().isNotEmpty) {
      regionValue = _mandal!.trim();
    } else if (_city != null && _city!.trim().isNotEmpty) {
      regionValue = _city!.trim();
    } else if (_regionController.text.trim().isNotEmpty) {
      // Preserve an older/manual value that is not yet
      // represented in the new location hierarchy.
      regionValue = _regionController.text.trim();
    }

    final villageValue = _village != null && _village!.trim().isNotEmpty
        ? _village!.trim()
        : _villageController.text.trim().isNotEmpty
        ? _villageController.text.trim()
        : null;

    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category,
      'author': _authorController.text.trim(),
      'source': _sourceController.text.trim(),
      'content': _contentController.text.trim(),
      'image_url': widget.submission.imageUrl,
      'state': _state,
      'district': _district,
      'region': regionValue,
      'village': villageValue,
    };
  }

  // ============================================================
  // SAVE DRAFT
  // ============================================================

  Future<void> _saveDraft() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    if (!_validateLocation()) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _editorService.saveDraft(widget.submission.id!, _currentFields());

      _showMessage('Draft saved successfully.');
    } catch (_) {
      _showMessage('We could not save the draft. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // PUBLISH
  // ============================================================

  Future<void> _publish() async {
    if (_busy) return;

    FocusScope.of(context).unfocus();

    if (!_validateLocation()) {
      return;
    }

    final confirmed = await _showPublishConfirmation();

    if (!confirmed) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      await _editorService.publishSubmission(
        widget.submission.id!,
        _currentFields(),
      );

      if (!mounted) return;

      _showMessage('Story published live.');

      Navigator.pop(context);
    } catch (_) {
      _showMessage('We could not publish this story. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // LOCATION VALIDATION
  // ============================================================

  bool _validateLocation() {
    if (_state.trim().isEmpty) {
      _showMessage('Please select a state.');
      return false;
    }

    if (_district.trim().isEmpty) {
      _showMessage('Please select a district.');
      return false;
    }

    return true;
  }

  // ============================================================
  // PUBLISH CONFIRMATION
  // ============================================================

  Future<bool> _showPublishConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Publish this story?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'This story will become part of the live news feed after publication.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject() async {
    if (_busy) return;

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rejection Feedback',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Provide a reason for rejection...',
            filled: true,
            fillColor: const Color(0xFFF9F9F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = reasonController.text.trim();

              if (text.isEmpty) {
                return;
              }

              Navigator.pop(dialogContext, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reject Story'),
          ),
        ],
      ),
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _editorService.rejectSubmission(widget.submission.id!, reason);

      if (!mounted) return;

      _showMessage('Story rejected.');

      Navigator.pop(context);
    } catch (_) {
      _showMessage('We could not reject this story. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_claiming) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F5),
        body: Center(child: CircularProgressIndicator(color: Colors.black87)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rate_review_rounded, size: 16),
            ),
            const SizedBox(width: 10),
            const Text(
              'Editor Review Desk',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // ==================================================
                // IMAGE
                // ==================================================
                if (widget.submission.imageUrl != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: AppMediaViewer(
                          url: widget.submission.imageUrl!,
                          fit: BoxFit.cover,
                          autoPlay: false,
                          looping: true,
                          showControls: true,
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // ARTICLE DETAILS
                // ==================================================
                const Text(
                  'ARTICLE DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 12),

                _field('Headline', _titleController),

                _field(
                  'Description / Subhead',
                  _descriptionController,
                  maxLines: 3,
                ),

                const SizedBox(height: 8),

                _dropdown(
                  label: 'Category',
                  value: _category,
                  items: kNewsCategories,
                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }

                    setState(() {
                      _category = v;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ==================================================
                // LOCATION
                // ==================================================
                const Text(
                  'LOCATION TAGGING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 12),

                _dropdown(
                  label: 'State *',
                  value: _state,
                  items: kAllowedStates,
                  onChanged: _onStateChanged,
                ),

                _dropdown(
                  label: 'District *',
                  value: _district,
                  items: _districtOptions,
                  enabled: _state.isNotEmpty,
                  onChanged: _onDistrictChanged,
                ),

                _dropdown(
                  label: 'City',
                  value: _city,
                  items: _cityOptions,
                  enabled: _district.isNotEmpty && _cityOptions.isNotEmpty,
                  onChanged: _onCityChanged,
                ),

                _dropdown(
                  label: 'Mandal / Region',
                  value: _mandal,
                  items: _mandalOptions,
                  enabled: _district.isNotEmpty && _mandalOptions.isNotEmpty,
                  onChanged: _onMandalChanged,
                ),

                _dropdown(
                  label: 'Village / Locality',
                  value: _village,
                  items: _villageOptions,
                  enabled: _mandal != null && _villageOptions.isNotEmpty,
                  onChanged: _onVillageChanged,
                ),

                // Preserve an old manually entered region
                // when it doesn't exist in the current hierarchy.
                if (_regionController.text.trim().isNotEmpty)
                  _field('Existing Region / Mandal', _regionController),

                const SizedBox(height: 16),

                // ==================================================
                // CONTENT
                // ==================================================
                const Text(
                  'CONTENT & ATTRIBUTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.black45,
                  ),
                ),

                const SizedBox(height: 12),

                _field('Full Story Content', _contentController, maxLines: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Source', _sourceController)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Author', _authorController)),
                  ],
                ),

                const SizedBox(height: 32),

                // ==================================================
                // ACTIONS
                // ==================================================
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _reject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text(
                          'REJECT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _saveDraft,
                        icon: const Icon(
                          Icons.bookmark_outline_rounded,
                          size: 16,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(
                            color: Colors.black26,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text(
                          'SAVE DRAFT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _publish,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(
                      _busy ? 'PROCESSING...' : 'PUBLISH LIVE',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          hoverColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
        ),
      ),
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
    bool enabled = true,
  }) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownMenu<String>(
        width: double.infinity,
        enabled: enabled,
        initialSelection: safeValue,
        requestFocusOnTap: true,
        enableFilter: true,
        enableSearch: true,
        menuHeight: 320,
        expandedInsets: EdgeInsets.zero,
        hintText: label,
        label: Text(label),
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
            final entryLabel = entries[index].label.toLowerCase();

            if (entryLabel.contains(normalizedQuery)) {
              return index;
            }
          }

          return null;
        },
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF1F1EF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
          ),
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 13),
          floatingLabelStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(8),
          maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 320)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        dropdownMenuEntries: items
            .map((item) => DropdownMenuEntry<String>(value: item, label: item))
            .toList(),
        onSelected: enabled ? onChanged : null,
      ),
    );
  }
}