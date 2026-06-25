import re

with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/course_content_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove google_fonts import
content = re.sub(r"import 'package:google_fonts/google_fonts\.dart';\n", "", content)

# Replace GoogleFonts calls
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*32[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF4231C0\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*18[^)]*fontWeight:\s*FontWeight\.w600[^)]*color:\s*Colors\.white[^)]*\)", "theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*fontWeight:\s*FontWeight\.w600[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.titleMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*Theme\.of\(context\)\.colorScheme\.onSurface[^)]*\)", "theme.textTheme.bodyLarge", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*Theme\.of\(context\)\.disabledColor[^)]*\)", "theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*fontWeight:\s*FontWeight\.w600[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*fontWeight:\s*FontWeight\.w600[^)]*color:\s*Theme\.of\(context\)\.colorScheme\.primary[^)]*\)", "theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF787586\)[^)]*\)", "theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF00573a\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: Colors.green.shade800, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF4231c0\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF787586\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*Theme\.of\(context\)\.colorScheme\.primary[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodySmall", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*color:\s*const Color\(0xFF787586\)[^)]*\)", "theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*10[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*Theme\.of\(context\)\.colorScheme\.primary[^)]*\)", "theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)", content)


# Catch any leftover GoogleFonts
content = re.sub(r"style:\s*GoogleFonts\.[a-zA-Z]+\(", "style: TextStyle(", content)


# Replace const colors
content = content.replace("const Color(0xFFf8f9ff)", "theme.colorScheme.background")
content = content.replace("const Color(0xFF121c2a)", "theme.colorScheme.onSurface")
content = content.replace("const Color(0xFFeff4ff)", "theme.colorScheme.surfaceVariant")
content = content.replace("const Color(0xFFc8c4d7)", "theme.colorScheme.outline")
content = content.replace("const Color(0xFF787586)", "theme.colorScheme.onSurfaceVariant")
content = content.replace("const Color(0xFF474554)", "theme.colorScheme.onSurfaceVariant")
content = content.replace("const Color(0xFFe9ddff)", "theme.colorScheme.primaryContainer")
content = content.replace("const Color(0xFF5516be)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFFba1a1a)", "theme.colorScheme.error")
content = content.replace("const Color(0xFFffdad6)", "theme.colorScheme.errorContainer")
content = content.replace("const Color(0xFF5b4ed9)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFF4231c0)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFF4231C0)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFF00724e)", "Colors.green")
content = content.replace("const Color(0xFF00573a)", "Colors.green.shade800")
content = content.replace("const Color(0xFF6b38d4)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFFc5c0ff)", "theme.colorScheme.primary.withOpacity(0.5)")
content = content.replace("const Color(0xFFe6eeff)", "theme.colorScheme.secondaryContainer")
content = content.replace("const Color(0xFFd9e3f6)", "theme.colorScheme.secondaryContainer")

# Add theme declaration at the top of build methods
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context) {\n    final theme = Theme.of(context);")
content = content.replace("SliverAppBar _buildSliverAppBar() {", "SliverAppBar _buildSliverAppBar() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildErrorView() {", "Widget _buildErrorView() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildCourseContent() {", "Widget _buildCourseContent() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildHeroSection() {", "Widget _buildHeroSection() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildProgressSummary() {", "Widget _buildProgressSummary() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildModuleList() {", "Widget _buildModuleList() {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildModuleCard(ModuleModel module, int moduleIndex) {", "Widget _buildModuleCard(ModuleModel module, int moduleIndex) {\n    final theme = Theme.of(context);")
content = content.replace("Widget _buildLessonTile(ModuleModel module, LessonModel lesson) {", "Widget _buildLessonTile(ModuleModel module, LessonModel lesson) {\n    final theme = Theme.of(context);")


with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/course_content_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
