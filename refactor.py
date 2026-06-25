import re

with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/course_list_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove google_fonts import
content = re.sub(r"import 'package:google_fonts/google_fonts\.dart';\n", "", content)

# Replace GoogleFonts.outfit(...) with theme.textTheme.titleLarge / headlineSmall etc.
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.titleLarge", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*18[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.titleLarge", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*16[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.titleMedium", content)
content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*18[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*(?:course\.price == 0 \? const Color\(0xFF00573a\) : const Color\(0xFF4231c0\))[^)]*\)", "theme.textTheme.titleLarge?.copyWith(color: course.price == 0 ? Colors.green.shade800 : theme.colorScheme.primary)", content)

content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.w600[^)]*\)", "theme.textTheme.labelLarge", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.bodyLarge", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*color:\s*const Color\(0xFFc8c4d7\)[^)]*\)", "theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*color:\s*const Color\(0xFF787586\)[^)]*\)", "theme.textTheme.bodySmall", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF474554\)[^)]*fontWeight:\s*FontWeight\.w500[^)]*\)", "theme.textTheme.bodyMedium", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*10[^)]*color:\s*const Color\(0xFF6b38d4\)[^)]*fontWeight:\s*FontWeight\.bold[^)]*\)", "theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*10[^)]*color:\s*const Color\(0xFF00573a\)[^)]*fontWeight:\s*FontWeight\.bold[^)]*\)", "theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade800)", content)
content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121c2a\)[^)]*\)", "theme.textTheme.labelLarge", content)


# Replace explicit GoogleFonts inside text styles
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
content = content.replace("const Color(0xFF00724e)", "Colors.green")
content = content.replace("const Color(0xFF00573a)", "Colors.green.shade800")
content = content.replace("const Color(0xFF6b38d4)", "theme.colorScheme.primary")
content = content.replace("const Color(0xFFc5c0ff)", "theme.colorScheme.primary.withOpacity(0.5)")
content = content.replace("const Color(0xFFe6eeff)", "theme.colorScheme.secondaryContainer")

# Add theme declaration at the top of build
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context) {\n    final theme = Theme.of(context);")

# Also add theme to _buildCourseCard
content = content.replace("Widget _buildCourseCard(CourseModel course) {", "Widget _buildCourseCard(CourseModel course) {\n    final theme = Theme.of(context);")

with open('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/course_list_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
