// screens/editor/published_news_edit_screen.dart

import 'package:flutter/material.dart';

import '../../data/location_data.dart';
import '../../models/news_article.dart';
import '../../services/editor_service.dart';
import '../contributor/news_submission_form.dart'
    show kNewsCategories, kAllowedStates;

class PublishedNewsEditScreen extends StatefulWidget {
  final NewsArticle article;

  const PublishedNewsEditScreen({super.key, required this.article});

  @override
  State<PublishedNewsEditScreen> createState() =>
      _PublishedNewsEditScreenState();
}

class _PublishedNewsEditScreenState extends State<PublishedNewsEditScreen> {
  final _editorService = EditorService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  late final TextEditingController _sourceController;
  late final TextEditingController _authorController;

  String _category = '';
  String _state = '';
  String _district = '';

  String? _city;
  String? _mandal;
  String? _village;

  bool _busy = false;

  List<String> get _districtOptions => getDistrictsForState(_state);
  List<String> get _cityOptions => getCitiesForDistrict(_state, _district);
  List<String> get _mandalOptions =>
      getMandalsForDistrict(_state, _district, city: _city);

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

    final article = widget.article;

    _titleController = TextEditingController(text: article.title);
    _descriptionController = TextEditingController(text: article.description);
    _contentController = TextEditingController(text: article.content);
    _sourceController = TextEditingController(text: article.source);
    _authorController = TextEditingController(text: article.author);

    _category = article.category;
    _initializeLocation(article.location);
  }

  void _initializeLocation(String location) {
    if (location.isEmpty) {
      return;
    }

    final parts = location
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final state in kAllowedStates) {
      if (parts.contains(state)) {
        _state = state;
        break;
      }
    }

    if (_state.isEmpty) {
      return;
    }

    final districts = getDistrictsForState(_state);

    for (final district in districts) {
      if (parts.contains(district)) {
        _district = district;
        break;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  void _changeState(String? value) {
    if (value == null) return;
    final districts = getDistrictsForState(value);
    setState(() {
      _state = value;
      _district = districts.isNotEmpty ? districts.first : '';
      _city = null;
      _mandal = null;
      _village = null;
    });
  }

  void _changeDistrict(String? value) {
    if (value == null) return;
    setState(() {
      _district = value;
      _city = null;
      _mandal = null;
      _village = null;
    });
  }

  void _changeCity(String? value) {
    setState(() {
      _city = value;
      _mandal = null;
      _village = null;
    });
  }

  void _changeMandal(String? value) {
    setState(() {
      _mandal = value;
      _village = null;
    });
  }

  void _changeVillage(String? value) {
    setState(() {
      _village = value;
    });
  }

  Future<void> _save() async {
    if (_busy) return;

    if (_titleController.text.trim().isEmpty) {
      _showMessage('Headline is required.');
      return;
    }

    if (_state.isEmpty) {
      _showMessage('State is required.');
      return;
    }

    if (_district.isEmpty) {
      _showMessage('District is required.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      String? region;

      if (_mandal != null && _mandal!.trim().isNotEmpty) {
        region = _mandal!.trim();
      } else if (_city != null && _city!.trim().isNotEmpty) {
        region = _city!.trim();
      }

      await _editorService.updatePublishedNews(widget.article.id, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'author': _authorController.text.trim(),
        'source': _sourceController.text.trim(),
        'content': _contentController.text.trim(),
        'state': _state,
        'district': _district,
        'region': region,
        'village': _village,
      });

      if (!mounted) return;

      _showMessage('Published news updated successfully.');
      Navigator.pop(context, true);
    } catch (_) {
      _showMessage('Unable to update this news article.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
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
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Live Article',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
              // ==================================================
              // HEADER IMAGE CARD
              // ==================================================
              if (widget.article.imageUrl.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          widget.article.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 220,
                              color: const Color(0xFFEDEDEB),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_outlined,
                                size: 42,
                                color: Colors.black38,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF318451).withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'LIVE ON FEED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF318451),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // SECTION: ARTICLE DETAILS
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
              _dropdown('Category', _category, kNewsCategories, (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                });
              }),

              const SizedBox(height: 20),

              // ==================================================
              // SECTION: LOCATION TAGGING
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
              _dropdown('State *', _state, kAllowedStates, _changeState),
              _dropdown(
                'District *',
                _district,
                _districtOptions,
                _changeDistrict,
                enabled: _state.isNotEmpty,
              ),
              _dropdown(
                'City',
                _city,
                _cityOptions,
                _changeCity,
                enabled: _cityOptions.isNotEmpty,
              ),
              _dropdown(
                'Mandal / Region',
                _mandal,
                _mandalOptions,
                _changeMandal,
                enabled: _mandalOptions.isNotEmpty,
              ),
              _dropdown(
                'Village / Locality',
                _village,
                _villageOptions,
                _changeVillage,
                enabled: _villageOptions.isNotEmpty,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SECTION: CONTENT & ATTRIBUTION
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _busy ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
  }) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownMenu<String>(
        width: double.infinity,
        enabled: enabled,
        initialSelection: safeValue,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        expandedInsets: EdgeInsets.zero,
        menuHeight: 300,
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF1F1EF),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withOpacity(0.03)),
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
}