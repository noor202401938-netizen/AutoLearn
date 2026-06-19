$workspace = "d:\economics-learner-app-main\economics-learner-app-main"

# Fix UserPreferencesRepository
$prefRepo = Join-Path $workspace "lib\repository\user_preferences_repository.dart"
if (Test-Path $prefRepo) {
    $content = Get-Content $prefRepo -Raw
    $content = $content -replace "Future<void> saveUserPreferences\(\{required String uid, required Map<String, dynamic> data\}\) async \{\}", "Future<void> saveUserPreferences({required String userId, String? theme, String? fontSize, bool? highContrast, bool? reduceMotion}) async {}"
    Set-Content -Path $prefRepo -Value $content -Encoding UTF8
}

# Fix FirestoreService
$firestoreService = Join-Path $workspace "lib\backend\firestore_service.dart"
if (Test-Path $firestoreService) {
    $content = Get-Content $firestoreService -Raw
    $content = $content -replace "Future<void> updateUserProfile\(\{required String uid, required Map<String, dynamic> data\}\) async \{\}", "Future<void> updateUserProfile({required String uid, String? displayName, String? phone, String? grade, String? interest}) async {}"
    Set-Content -Path $firestoreService -Value $content -Encoding UTF8
}
