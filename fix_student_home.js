const fs = require('fs');

let content = fs.readFileSync('lib/screens/student/student_home.dart', 'utf8');

// Replace import
content = content.replace(/import '\.\.\/\.\.\/backend\/firestore_service\.dart';/g, "import '../../repository/user_repository.dart';");

// Replace instantiation
content = content.replace(/final FirestoreService _firestoreService = FirestoreService\(\);/g, "final UserRepository _userRepository = UserRepository();");

// Replace StreamBuilder in _buildWelcomeSection and elsewhere
content = content.replace(/StreamBuilder<DocumentSnapshot>/g, "StreamBuilder<Map<String, dynamic>?>");
content = content.replace(/_firestoreService\.streamUserProfile/g, "_userRepository.streamUserProfile");

// Fix the snapshot data parsing for both occurrences
// First occurrence (around line 118)
content = content.replace(/if \(snapshot\.hasData && snapshot\.data!\.exists\) \{\s*final data = snapshot\.data!\.data\(\) as Map<String, dynamic>\?;\s*if \(data != null &&/g, 
  "if (snapshot.hasData && snapshot.data != null) {\n          final data = snapshot.data!;\n          if (data != null &&");

// Second occurrence (around line 795 in _buildProfileTab)
content = content.replace(/if \(!snapshot\.hasData \|\| !snapshot\.data!\.exists\) \{/g, "if (!snapshot.hasData || snapshot.data == null) {");
content = content.replace(/final userData = snapshot\.data!\.data\(\) as Map<String, dynamic>;/g, "final userData = snapshot.data!;");

fs.writeFileSync('lib/screens/student/student_home.dart', content, 'utf8');
