// screens/contributor/contributor_gate.dart
//
// Decides where "Submit news" goes for a signed-in user:
//   reporter / freelancer / editor / admin → the submission form
//   reader with an application under review → a "please wait" note
//   any other reader → the Reporter / Freelancer registration form

import 'package:flutter/material.dart';

import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import 'news_submission_form.dart';
import 'reporter_registration_screen.dart';

const _newsroomRoles = {'freelancer', 'employee', 'editor', 'admin'};

Future<void> openNewsroom(NavigatorState nav) async {
  String? role;
  ContributorApplication? application;
  try {
    role = await AuthService.instance.getCurrentUserRole();
    if (role == 'reader') application = await ApplicationService.instance.myApplication();
  } catch (_) {
    if (!nav.mounted) return;
    ScaffoldMessenger.of(nav.context).showSnackBar(
      const SnackBar(content: Text('Could not check your account. Please try again.')),
    );
    return;
  }
  if (!nav.mounted) return;

  if (_newsroomRoles.contains(role)) {
    nav.push(MaterialPageRoute(builder: (_) => const NewsSubmissionForm()));
    return;
  }

  if (application != null && application.isPending) {
    await showApplicationStatusDialog(nav.context, application);
    return;
  }

  if (application != null && application.status == 'rejected') {
    await showApplicationStatusDialog(nav.context, application);
    if (!nav.mounted) return;
  }
  nav.push(MaterialPageRoute(builder: (_) => const ReporterRegistrationScreen()));
}

/// Shows "under review" or "not approved (reason)" for a reader's application.
Future<void> showApplicationStatusDialog(BuildContext context, ContributorApplication a) {
  final pending = a.isPending;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: Icon(
        pending ? Icons.hourglass_top_rounded : Icons.info_outline_rounded,
        color: pending ? const Color(0xFFC9A24B) : const Color(0xFFB91C1C),
        size: 34,
      ),
      title: Text(pending ? 'Application under review' : 'Application not approved'),
      content: Text(
        pending
            ? 'Your ${a.roleLabel.toLowerCase()} registration was received. You can submit news as soon as the admin approves it.'
            : 'Your last application was not approved${(a.rejectionReason ?? '').isNotEmpty ? ':\n“${a.rejectionReason}”' : '.'}\n\nYou can update your details and apply again.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(pending ? 'OK' : 'Continue')),
      ],
    ),
  );
}
