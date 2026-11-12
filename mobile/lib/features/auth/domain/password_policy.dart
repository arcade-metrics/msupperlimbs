/// Same rule as ciatec-core (`src/api/src/modules/auth/passwords.py`):
/// at least 8 characters, 1 uppercase letter (A–Z) and 1 digit.
/// Change both together.
const passwordMinLength = 8;

bool meetsPasswordPolicy(String password) {
  return password.length >= passwordMinLength &&
      RegExp('[A-Z]').hasMatch(password) &&
      RegExp(r'\d').hasMatch(password);
}
