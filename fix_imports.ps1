$filesToFix = @(
    "lib\model\certificate_model.dart",
    "lib\model\chat_message_model.dart",
    "lib\model\notification_model.dart",
    "lib\model\quiz_model.dart",
    "lib\model\video_progress_model.dart",
    "lib\screens\student\student_home.dart"
)

foreach ($file in $filesToFix) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -notmatch "package:cloud_firestore/cloud_firestore.dart") {
            $newContent = "import 'package:cloud_firestore/cloud_firestore.dart';`n" + $content
            Set-Content -Path $file -Value $newContent -Encoding UTF8
        }
    }
}

# Clean up admin_dashboard
$admin = "lib\screens\admin\admin_dashboard.dart"
$adminContent = Get-Content $admin -Raw
$adminContent = $adminContent -replace "(?m)^import 'package:cloud_firestore/cloud_firestore\.dart';\r?\n", ""
$adminContent = "import 'package:cloud_firestore/cloud_firestore.dart';`n" + $adminContent
Set-Content -Path $admin -Value $adminContent -Encoding UTF8

# Also add firebase_auth where needed
$authFiles = @(
    "lib\repository\auth_repository.dart",
    "lib\repository\quiz_repository.dart",
    "lib\screens\student\change_password_screen.dart"
)

foreach ($file in $authFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        if ($content -notmatch "package:firebase_auth/firebase_auth.dart") {
            $newContent = "import 'package:firebase_auth/firebase_auth.dart';`n" + $content
            Set-Content -Path $file -Value $newContent -Encoding UTF8
        }
    }
}
