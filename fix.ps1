$workspace = "d:\economics-learner-app-main\economics-learner-app-main"

# 1. Add missing imports
$imports = @{
    "lib\screens\admin\admin_dashboard.dart" = "import 'package:cloud_firestore/cloud_firestore.dart';`n"
    "lib\business_logic\analytics_monitoring_manager.dart" = "import 'package:firebase_analytics/firebase_analytics.dart';`n"
    "lib\business_logic\notification_manager.dart" = "import 'package:firebase_messaging/firebase_messaging.dart';`n"
    "lib\model\chat_message_model.dart" = "import 'package:cloud_firestore/cloud_firestore.dart';`n"
    "lib\model\certificate_model.dart" = "import 'package:cloud_firestore/cloud_firestore.dart';`n"
    "lib\model\notification_model.dart" = "import 'package:cloud_firestore/cloud_firestore.dart';`n"
}

foreach ($entry in $imports.GetEnumerator()) {
    $filepath = Join-Path -Path $workspace -ChildPath $entry.Key
    $imp = $entry.Value
    if (Test-Path $filepath) {
        $content = Get-Content $filepath -Raw
        if ($content -notmatch "package:cloud_firestore" -and $content -notmatch "package:firebase_") {
            # insert after first import
            $content = $content -replace "(?m)^(import .*?;)", "`$1`n$imp"
            Set-Content -Path $filepath -Value $content -Encoding UTF8
        }
    }
}

# 2. Add stubs to repositories
$stubs = @{
    "lib\repository\progress_repository.dart" = "  Future<dynamic> getCourseProgress({required String uid, required String courseId}) async { return null; }`n"
    "lib\repository\chat_repository.dart" = "  Future<String> getOrCreateCurrentSession(String userId) async { return `"mock_session`"; }`n  Future<void> sendMessage({required String sessionId, required dynamic message}) async {}`n  Future<List<dynamic>> getSessionMessages(String sessionId) async { return []; }`n  Stream<List<dynamic>> watchSessionMessages(String sessionId) async* { yield []; }`n  Future<List<dynamic>> getUserSessions(String userId) async { return []; }`n  Future<void> deleteSession(String sessionId) async {}`n"
    "lib\repository\quiz_repository.dart" = "  Future<dynamic> getUserQuizSubmission({required String uid, required String quizId}) async { return null; }`n  Future<void> submitQuiz(dynamic submission) async {}`n  Future<dynamic> getAssignmentByLessonId(String lessonId) async { return null; }`n  Future<dynamic> getUserAssignmentSubmission({required String uid, required String assignmentId}) async { return null; }`n  Future<void> submitAssignment(dynamic submission) async {}`n"
    "lib\repository\notification_repository.dart" = "  Future<void> createNotification(dynamic notification) async {}`n  Future<int> getUnreadCount(String userId) async { return 0; }`n  Future<void> markAsRead(String id) async {}`n  Stream<List<dynamic>> watchUserNotifications(String userId) async* { yield []; }`n"
    "lib\repository\certificate_repository.dart" = "  Future<bool> certificateExists({required String uid, required String courseId}) async { return false; }`n  Future<void> createCertificate(dynamic certificate) async {}`n"
}

foreach ($entry in $stubs.GetEnumerator()) {
    $filepath = Join-Path -Path $workspace -ChildPath $entry.Key
    $stub = $entry.Value
    if (Test-Path $filepath) {
        $content = Get-Content $filepath -Raw
        $lastBraceIndex = $content.LastIndexOf("}")
        if ($lastBraceIndex -ge 0) {
            $content = $content.Substring(0, $lastBraceIndex) + $stub + $content.Substring($lastBraceIndex)
            Set-Content -Path $filepath -Value $content -Encoding UTF8
        }
    }
}
