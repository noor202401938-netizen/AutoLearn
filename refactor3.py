import re

with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/video_player_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove google_fonts import
content = re.sub(r"import 'package:google_fonts/google_fonts\.dart';\n", "", content)

# Replace GoogleFonts calls
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF4231C0\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*32[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.titleMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.bodyMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF3D2ABB\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF4231C0\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*fontSize:\s*14[^)]*\)", "theme.textTheme.labelLarge", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)


# Generic catch-all for inter if not caught above
content = re.sub(r"style:\s*GoogleFonts\.inter\([^)]*\)", "style: theme.textTheme.bodyMedium", content)


# Replace explicit GoogleFonts inside text styles
content = re.sub(r"style:\s*GoogleFonts\.[a-zA-Z]+\(", "style: TextStyle(", content)


# Replace const colors
content = content.replace("const Color(0xFFF8F9FF)", "theme.colorScheme.background")
content = content.replace("const Color(0xFF4231C0)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFF474554)", "theme.colorScheme.onSurfaceVariant")
content = content.replace("const Color(0xFF5B4ED9)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFFBA1A1A)", "theme.colorScheme.error")
content = content.replace("const Color(0xFF121C2A)", "theme.colorScheme.onSurface")
content = content.replace("const Color(0xFF6B38D4)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFF3D2ABB)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFFC8C4D7)", "theme.colorScheme.outline")
content = content.replace("const Color(0xFFEFF4FF)", "theme.colorScheme.surfaceVariant")
content = content.replace("const Color(0xFF00573A)", "Colors.green.shade800")
content = content.replace("const Color(0xFFFFDAD6)", "theme.colorScheme.errorContainer")
content = content.replace("const Color(0xFFE6EEFF)", "theme.colorScheme.secondaryContainer")
content = content.replace("const Color(0xFF787586)", "theme.colorScheme.onSurfaceVariant")
content = content.replace("const Color(0xFFD0DBED)", "theme.colorScheme.surfaceVariant")

# Add theme declaration at the top of build methods
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context) {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildErrorView() {", "Widget _buildErrorView() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildVideoPlayer() {", "Widget _buildVideoPlayer() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildContentArea() {", "Widget _buildContentArea() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildTab(String id, String title) {", "Widget _buildTab(String id, String title) {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildAboutTab() {", "Widget _buildAboutTab() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildTranscriptTab() {", "Widget _buildTranscriptTab() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildUpNext() {", "Widget _buildUpNext() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildNextLessonCard(String title, String subtitle, String duration, bool locked) {", "Widget _buildNextLessonCard(String title, String subtitle, String duration, bool locked) {\n    final theme = Theme.of(context);")


with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/video_player_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
