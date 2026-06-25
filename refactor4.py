import re
import glob

def refactor_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If already using Theme.of(context), this might be safe or maybe not, but we'll try
    # Remove google_fonts import
    content = re.sub(r"import 'package:google_fonts/google_fonts\.dart';\n", "", content)

    # Replace GoogleFonts calls
    content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF4231C0\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*32[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*20[^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.outfit\([^)]*fontSize:\s*24[^)]*fontWeight:\s*FontWeight\.w700[^)]*color:\s*const Color\(0xFF00573A\)[^)]*\)", "theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)", content)


    content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.titleMedium", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*16[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.bodyMedium", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*14[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontSize:\s*12[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)", content)


    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF3D2ABB\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF474554\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF4231C0\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.bold[^)]*color:\s*const Color\(0xFF121C2A\)[^)]*\)", "theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.w600[^)]*fontSize:\s*14[^)]*\)", "theme.textTheme.labelLarge", content)
    content = re.sub(r"GoogleFonts\.inter\([^)]*fontWeight:\s*FontWeight\.w700[^)]*fontSize:\s*14[^)]*\)", "theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)", content)


    # Generic catch-all for inter/outfit if not caught above
    content = re.sub(r"style:\s*GoogleFonts\.inter\([^)]*\)", "style: theme.textTheme.bodyMedium", content)
    content = re.sub(r"style:\s*GoogleFonts\.outfit\([^)]*\)", "style: theme.textTheme.titleMedium", content)
    
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
    
    # ensure theme is defined in build functions.
    if 'Widget build(BuildContext context) {' in content and 'final theme = Theme.of(context);' not in content:
        content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context) {\n    final theme = Theme.of(context);")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)


for filepath in glob.glob('d:/economics-learner-app-main/economics-learner-app-main/lib/screens/student/*.dart'):
    refactor_file(filepath)

print("Done Refactoring Student Screens")
