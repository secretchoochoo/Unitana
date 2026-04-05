import 'package:flutter/material.dart';

import '../models/dashboard_copy.dart';
import 'destructive_confirmation_sheet.dart';

Future<bool> showEditSessionDiscardSheet(
  BuildContext context, {
  required String message,
}) {
  return showDestructiveConfirmationSheet(
    context,
    title: DashboardCopy.editDiscardTitle(context),
    message: message,
    confirmLabel: DashboardCopy.editDiscardConfirm(context),
    cancelLabel: DashboardCopy.editDiscardCancel(context),
  );
}
