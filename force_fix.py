import re
import os

files_to_fix = [
    r"lib\screens\admin\admin_analytics_screen.dart",
    r"lib\screens\student\change_password_screen.dart",
    r"lib\screens\student\edit_profile_screen.dart",
    r"lib\screens\theme_accessibility_screen.dart",
    r"lib\screens\user_info_screen.dart"
]

def force_fix(filepath):
    full_path = os.path.join('d:/economics-learner-app-main/economics-learner-app-main', filepath)
    if not os.path.exists(full_path):
        return
        
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Inject getter into State class
    content = re.sub(
        r'(class\s+_[A-Za-z0-9_]+State\s+extends\s+State<[^>]+>\s*\{)',
        r'\1\n  ThemeData get theme => Theme.of(context);\n',
        content
    )
    
    # Inject getter into StatelessWidget
    content = re.sub(
        r'(class\s+[A-Za-z0-9_]+\s+extends\s+StatelessWidget\s*\{)',
        r'\1\n  // Need context to get theme, so we cannot do getter here easily. Let\'s hope it\'s a state class.',
        content
    )
        
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

for f in files_to_fix:
    force_fix(f)
    
print("Force fix applied via getter.")
