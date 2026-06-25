import re
import os

files_to_fix = [
    r"lib\screens\admin\admin_analytics_screen.dart",
    r"lib\screens\admin\admin_announcements_screen.dart",
    r"lib\screens\admin\admin_courses_screen.dart",
    r"lib\screens\admin\admin_dashboard_screen.dart",
    r"lib\screens\admin\admin_finance_screen.dart",
    r"lib\screens\admin\admin_users_screen.dart",
    r"lib\screens\notifications_panel.dart",
    r"lib\screens\role_based_wrapper.dart",
    r"lib\screens\student\ai_quiz_screen.dart",
    r"lib\screens\student\ai_tutor_chat_screen.dart",
    r"lib\screens\student\assignment_screen.dart",
    r"lib\screens\student\certificate_screen.dart",
    r"lib\screens\student\certificates_list_screen.dart",
    r"lib\screens\student\change_password_screen.dart",
    r"lib\screens\student\edit_profile_screen.dart",
    r"lib\screens\student\final_test_screen.dart",
    r"lib\screens\student\project_screen.dart",
    r"lib\screens\student\student_home.dart",
    r"lib\screens\theme_accessibility_screen.dart",
    r"lib\screens\user_info_screen.dart",
    r"lib\widgets\student_home\analytics_tab.dart",
    r"lib\widgets\student_home\profile_tab.dart"
]

def fix_file(filepath):
    full_path = os.path.join('d:/economics-learner-app-main/economics-learner-app-main', filepath)
    if not os.path.exists(full_path):
        return
        
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # We will find every method returning a Widget and inject final theme = Theme.of(context);
    # This is slightly dangerous if context is not in scope, but we assume it's in scope for most methods 
    # since it's a State class or passed explicitly. If not, we might need to handle it.
    
    # Actually, a safer regex:
    # Match any method declaration returning Widget that has (..., BuildContext context, ...) or is in a State class
    # Instead of that, let's just replace all `Widget _?[a-zA-Z0-9_]+\([^)]*\)\s*\{`
    # and check if `theme.` exists in that block before the next `Widget ` or end of file.
    
    # Even simpler: since the files have `theme.`, we just add `final theme = Theme.of(context);` 
    # to every `Widget ` method, or `build` method.
    
    # First, let's try replacing `Widget build(BuildContext context) {` again just in case it missed some due to formatting
    content = re.sub(
        r'(Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{)',
        r'\1\n    final theme = Theme.of(context);',
        content
    )
    
    # And other widget methods: `Widget _buildSomething(...) {`
    # We will inject `final theme = Theme.of(context);` right after the opening brace.
    content = re.sub(
        r'(Widget\s+[a-zA-Z0-9_]+\s*\([^)]*\)\s*\{)',
        r'\1\n    final theme = Theme.of(context);',
        content
    )
    
    # De-duplicate the lines if we accidentally injected it twice
    lines = content.split('\n')
    new_lines = []
    for i, line in enumerate(lines):
        if line.strip() == 'final theme = Theme.of(context);':
            # look ahead and behind to see if we already have it
            # this is a bit crude but works
            if len(new_lines) > 0 and 'final theme = Theme.of(context);' in new_lines[-1]:
                continue
            if len(new_lines) > 1 and 'final theme = Theme.of(context);' in new_lines[-2]:
                continue
        new_lines.append(line)
        
    content = '\n'.join(new_lines)
    
    # Sometimes it's inside `builder: (context, snapshot) {`
    content = re.sub(
        r'(builder:\s*\([^)]*context[^)]*\)\s*\{)',
        r'\1\n      final theme = Theme.of(context);',
        content
    )
    
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

for filepath in files_to_fix:
    fix_file(filepath)
    
print("Fix script applied.")
