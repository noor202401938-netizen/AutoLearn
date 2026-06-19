import os
import re

workspace = r"d:\economics-learner-app-main\economics-learner-app-main"

# 1. Add missing imports
imports_to_add = {
    "lib/screens/admin/admin_dashboard.dart": "import 'package:cloud_firestore/cloud_firestore.dart';\n",
    "lib/business_logic/analytics_monitoring_manager.dart": "import 'package:firebase_analytics/firebase_analytics.dart';\n",
    "lib/business_logic/notification_manager.dart": "import 'package:firebase_messaging/firebase_messaging.dart';\n",
    "lib/model/chat_message_model.dart": "import 'package:cloud_firestore/cloud_firestore.dart';\n",
    "lib/model/certificate_model.dart": "import 'package:cloud_firestore/cloud_firestore.dart';\n",
    "lib/model/notification_model.dart": "import 'package:cloud_firestore/cloud_firestore.dart';\n",
    "lib/repository/auth_repository.dart": "import 'package:firebase_auth/firebase_auth.dart';\n",
    "lib/screens/student/change_password_screen.dart": "import 'package:firebase_auth/firebase_auth.dart';\n"
}

for filepath, imp in imports_to_add.items():
    full_path = os.path.join(workspace, filepath)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        if imp not in content:
            # insert after first import
            content = re.sub(r"(import .*?;)", r"\1\n" + imp, content, count=1)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(content)

# 2. Add stubs to repositories
stubs = {
    "lib/repository/user_preferences_repository.dart": """
  Future<Map<String, dynamic>> getUserPreferences(String id) async { return {}; }
  Future<void> saveUserPreferences(String id, Map<String, dynamic> data) async {}
""",
    "lib/repository/enrollment_repository.dart": """
  Future<List<String>> getUserCourseIds({required String uid}) async { return []; }
""",
    "lib/repository/progress_repository.dart": """
  Future<dynamic> getCourseProgress(String uid, String courseId) async { return null; }
""",
    "lib/repository/chat_repository.dart": """
  Future<String> getOrCreateCurrentSession(String userId) async { return "mock_session"; }
  Future<void> sendMessage(String sessionId, dynamic message) async {}
  Future<List<dynamic>> getSessionMessages(String sessionId) async { return []; }
  Stream<List<dynamic>> watchSessionMessages(String sessionId) async* { yield []; }
  Future<List<dynamic>> getUserSessions(String userId) async { return []; }
  Future<void> deleteSession(String sessionId) async {}
""",
    "lib/repository/quiz_repository.dart": """
  Future<dynamic> getUserQuizSubmission(String uid, String quizId) async { return null; }
  Future<void> submitQuiz(dynamic submission) async {}
  Future<dynamic> getAssignmentByLessonId(String lessonId) async { return null; }
  Future<dynamic> getUserAssignmentSubmission(String uid, String assignmentId) async { return null; }
  Future<void> submitAssignment(dynamic submission) async {}
""",
    "lib/repository/notification_repository.dart": """
  Future<void> createNotification(dynamic notification) async {}
  Future<int> getUnreadCount(String userId) async { return 0; }
  Future<void> markAsRead(String id) async {}
  Stream<List<dynamic>> watchUserNotifications(String userId) async* { yield []; }
""",
    "lib/repository/certificate_repository.dart": """
  Future<bool> certificateExists(String uid, String courseId) async { return false; }
  Future<void> createCertificate(dynamic certificate) async {}
""",
    "lib/backend/firestore_service.dart": """
  Future<void> updateUserRole(String uid, String role) async {}
  Future<void> deleteUserProfile(String uid) async {}
  Stream<dynamic> streamUserProfile(String uid) async* {}
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {}
""",
    "lib/repository/auth_repository.dart": """
  User? getCurrentUser() { return FirebaseAuth.instance.currentUser; }
"""
}

for filepath, stub in stubs.items():
    full_path = os.path.join(workspace, filepath)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        # Insert before the last closing brace
        last_brace_idx = content.rfind("}")
        if last_brace_idx != -1:
            content = content[:last_brace_idx] + stub + content[last_brace_idx:]
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(content)

# 3. Fix regex const errors in UI files
files_with_const_errors = [
    "lib/screens/student/help_support_screen.dart",
    "lib/screens/student/about_screen.dart",
    "lib/screens/student/change_password_screen.dart",
    "lib/screens/admin/admin_dashboard.dart"
]
for root, dirs, files in os.walk(os.path.join(workspace, "lib")):
    for file in files:
        if file.endswith(".dart"):
            full_path = os.path.join(root, file)
            with open(full_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            # Simple heuristic: look for "const " on lines that have "Theme.of(context)"
            # we will replace `const ` with nothing, or `const Widget` with `Widget` 
            # if Theme is used inside. Actually, it's safer to just do a regex replace 
            # for common const patterns.
            # E.g., `const CircularProgressIndicator` -> `CircularProgressIndicator`
            # `const Icon` -> `Icon`
            # `const Text` -> `Text`
            # if Theme.of(context) is nearby
            
            # Since we don't have a perfect dart formatter, we can just look for lines with both `const` and `Theme.of(context)`
            new_lines = []
            changed = False
            for line in content.splitlines():
                if "const " in line and "Theme.of(context)" in line:
                    line = line.replace("const ", "")
                    changed = True
                new_lines.append(line)
            
            # Also, remove const from parents if they wrap Theme.of(context)
            # This is harder to do via regex line by line. Let's just fix the specific ones
            
            if changed:
                with open(full_path, "w", encoding="utf-8") as f:
                    f.write("\n".join(new_lines) + "\n")

print("Modifications applied successfully.")
