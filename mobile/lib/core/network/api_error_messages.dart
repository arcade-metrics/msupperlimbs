import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

/// User-facing message for [error], from the ciatec-core `code` when there
/// is one. Codes without a dedicated message fall back by HTTP status.
String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiException) {
    switch (error.code) {
      case 'INVALID_CREDENTIALS':
        return l10n.auth_invalidCredentials;
      case 'EMAIL_IN_USE':
        return l10n.auth_emailInUse;
      case 'VALIDATION_ERROR':
        return l10n.error_validation;
      case 'UNAUTHORIZED':
      case 'INVALID_REFRESH_TOKEN':
        return l10n.error_sessionExpired;
      case 'USER_INACTIVE':
        return l10n.error_accountInactive;
    }
    if (error.statusCode >= 500) return l10n.error_server;
    return l10n.error_generic;
  }
  if (error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException) {
    return l10n.error_network;
  }
  return l10n.error_generic;
}
