import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../editor/editor_dashboard_screen.dart';
import '../editor/story_timelines_overview_screen.dart';
import 'ad_campaign_planner_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  bool _loading = true;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _users = [];

  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadEverything() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();

      if (!isAdmin) {
        throw Exception('You do not have administrator access.');
      }

      final stats = await _adminService.fetchStats();
      final users = await _adminService.fetchUsers();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // FILTERED USERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _userSearch.trim().toLowerCase();

    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final email = user['email']?.toString().toLowerCase() ?? '';

      final name = user['full_name']?.toString().toLowerCase() ?? '';

      final role = user['role']?.toString().toLowerCase() ?? '';

      return email.contains(query) ||
          name.contains(query) ||
          role.contains(query);
    }).toList();
  }

  // ============================================================
  // ROLE CHANGE
  // ============================================================

  Future<void> _changeRole(Map<String, dynamic> user, String newRole) async {
    final userId = user['id']?.toString();

    if (userId == null || userId.isEmpty) {
      return;
    }

    try {
      await _adminService.updateUserRole(userId: userId, role: newRole);

      if (!mounted) return;

      await _loadEverything();

      _showMessage('${user['email'] ?? 'User'} is now $newRole.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // USER DETAILS
  // ============================================================

  void _showUserDetails(Map<String, dynamic> user) {
    final name = user['full_name']?.toString().trim().isNotEmpty == true
        ? user['full_name'].toString()
        : 'Unnamed user';

    final email = user['email']?.toString() ?? 'No email';

    final role = user['role']?.toString() ?? 'unknown';

    final language = user['language']?.toString().trim().isNotEmpty == true
        ? user['language'].toString()
        : 'Not set';

    final state = user['state']?.toString().trim().isNotEmpty == true
        ? user['state'].toString()
        : 'Not set';

    final district = user['district']?.toString().trim().isNotEmpty == true
        ? user['district'].toString()
        : 'Not set';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 30,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'User details',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _detailRow('Name', name),
                _detailRow('Email', email),
                _detailRow('Role', role),
                _detailRow('Language', language),
                _detailRow('State', state),
                _detailRow('District', district),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showRoleEditor(user);
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
                      'MANAGE ROLE',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE EDITOR
  // ============================================================

  void _showRoleEditor(Map<String, dynamic> user) {
    final currentRole = user['role']?.toString() ?? 'freelancer';

    const roles = ['freelancer', 'employee', 'editor', 'admin'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Change role',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user['email']?.toString() ?? 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 16),
                ...roles.map((role) {
                  final selected = role == currentRole;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selected
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _changeRole(user, role);
                              },
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.black
                                : const Color(0xFFF7F7F5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _prettyRole(role),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _prettyRole(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'editor':
        return 'Editor';
      case 'employee':
        return 'Employee';
      case 'freelancer':
        return 'Freelancer';
      default:
        return role;
    }
  }

  // ============================================================
  // OPEN EDITOR DESK
  // ============================================================

  void _openEditorDesk() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorDashboardScreen()),
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _logout() async {
    await _adminService.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
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
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEverything,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildStats(),
                    const SizedBox(height: 24),
                    _buildEditorialSection(),
                    const SizedBox(height: 24),
                    _buildUserManagement(),
                    const SizedBox(height: 24),
                    _buildSystemSection(),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.black45,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Good day, Admin',
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.logout_rounded,
                size: 19,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Users',
                _stats['total_users'] ?? 0,
                Icons.people_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Editors',
                _stats['editors'] ?? 0,
                Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Admins',
                _stats['admins'] ?? 0,
                Icons.admin_panel_settings_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Pending',
                _stats['pending'] ?? 0,
                Icons.pending_actions_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'In review',
                _stats['in_review'] ?? 0,
                Icons.rate_review_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Published',
                _stats['published'] ?? 0,
                Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Freelancers',
                _stats['freelancers'] ?? 0,
                Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Employees',
                _stats['employees'] ?? 0,
                Icons.badge_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Rejected',
                _stats['rejected'] ?? 0,
                Icons.cancel_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black45),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.black45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDITORIAL
  // ============================================================

  Widget _buildEditorialSection() {
    return _sectionCard(
      title: 'Editorial',
      subtitle: 'Manage the newsroom review workflow.',
      child: Column(
        children: [
          _actionTile(
            icon: Icons.dashboard_outlined,
            title: 'Open Editor Desk',
            subtitle: 'Review and publish submitted stories.',
            onTap: _openEditorDesk,
          ),
          const SizedBox(height: 8),
          _actionTile(
            icon: Icons.pending_actions_rounded,
            title: 'Pending submissions',
            subtitle: '${_stats['pending'] ?? 0} stories waiting for review.',
            onTap: _openEditorDesk,
          ),
          const SizedBox(height: 8),
          _actionTile(
            icon: Icons.timeline_rounded,
            title: 'Story Timelines & Follow-ups',
            subtitle: 'Organize related stories into chronological developments.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StoryTimelinesOverviewScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _actionTile(
            icon: Icons.campaign_rounded,
            title: 'Ad Campaign Planner',
            subtitle: 'Schedule 1-day, 3+1 (4 days), and 4-page auto-sliding ads in advance.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdCampaignPlannerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USERS
  // ============================================================

  Widget _buildUserManagement() {
    final users = _filteredUsers;

    return _sectionCard(
      title: 'User management',
      subtitle: 'View accounts and manage application roles.',
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _userSearch = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search name, email or role',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.black45,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F7F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No users found.',
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            )
          else
            ...users.take(50).map(_userTile),
        ],
      ),
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final name = user['full_name']?.toString().trim().isNotEmpty == true
        ? user['full_name'].toString()
        : 'Unnamed user';

    final email = user['email']?.toString() ?? 'No email';

    final role = user['role']?.toString() ?? 'unknown';

    final initials = name.isNotEmpty
        ? name.characters.first.toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showUserDetails(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _prettyRole(role),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
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
  // SYSTEM
  // ============================================================

  Widget _buildSystemSection() {
    return _sectionCard(
      title: 'System',
      subtitle: 'Quick system information.',
      child: Column(
        children: [
          _infoTile(Icons.cloud_done_outlined, 'Backend', 'Supabase'),
          _infoTile(Icons.security_outlined, 'Authentication', 'Supabase Auth'),
          _infoTile(Icons.storage_outlined, 'Database', 'PostgreSQL'),
          _infoTile(
            Icons.api_outlined,
            'Application API',
            'First-party Supabase services',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F7F5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.black54),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}