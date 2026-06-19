// lib/screens/admin/course_content_management_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../business_logic/course_manager.dart';
import '../../backend/xml_course_parser.dart';
import '../../model/course_model.dart';

class CourseContentManagementScreen extends StatefulWidget {
  final CourseModel course;

  const CourseContentManagementScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseContentManagementScreen> createState() => _CourseContentManagementScreenState();
}

class _CourseContentManagementScreenState extends State<CourseContentManagementScreen> {
  final CourseManager _courseManager = CourseManager();
  List<ModuleModel> _modules = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  void _loadModules() {
    setState(() {
      _modules = List.from(widget.course.syllabus);
      _hasUnsavedChanges = false;
    });
  }

  Future<void> _importFromXml() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final xmlContent = await XmlCourseParser.readXmlFromFile(file);
        
        if (!XmlCourseParser.validateXml(xmlContent)) {
          throw Exception('Invalid XML format');
        }

        final modules = XmlCourseParser.parseModulesFromXml(xmlContent);
        
        setState(() {
          _modules = modules;
          _hasUnsavedChanges = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported ${modules.length} modules'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import XML: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _exportToXml() async {
    try {
      if (_modules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No modules to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final xmlContent = XmlCourseParser.modulesToXml(_modules);
      
      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.course.courseId}_content_$timestamp.xml';
      final file = File('${directory.path}/$fileName');

      await XmlCourseParser.writeXmlToFile(xmlContent, file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('XML exported to: ${file.path}'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export XML: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveToCourse() async {
    if (!_hasUnsavedChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedCourse = widget.course.copyWith(
        syllabus: _modules,
        updatedAt: DateTime.now(),
      );

      final result = await _courseManager.updateCourse(updatedCourse);

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course content saved successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _addModule() {
    setState(() {
      _modules.add(ModuleModel(
        moduleId: 'module_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Module',
        lessons: [],
      ));
      _hasUnsavedChanges = true;
    });
  }

  void _deleteModule(int index) {
    setState(() {
      _modules.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _addLesson(int moduleIndex) {
    setState(() {
      final module = _modules[moduleIndex];
      final updatedLessons = List<LessonModel>.from(module.lessons)
        ..add(LessonModel(
          lessonId: 'lesson_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Lesson',
          duration: 0,
          type: 'video',
        ));
      _modules[moduleIndex] = ModuleModel(
        moduleId: module.moduleId,
        title: module.title,
        lessons: updatedLessons,
      );
      _hasUnsavedChanges = true;
    });
  }

  void _deleteLesson(int moduleIndex, int lessonIndex) {
    setState(() {
      final module = _modules[moduleIndex];
      final updatedLessons = List<LessonModel>.from(module.lessons)
        ..removeAt(lessonIndex);
      _modules[moduleIndex] = ModuleModel(
        moduleId: module.moduleId,
        title: module.title,
        lessons: updatedLessons,
      );
      _hasUnsavedChanges = true;
    });
  }

  void _updateModuleTitle(int index, String title) {
    setState(() {
      final module = _modules[index];
      _modules[index] = ModuleModel(
        moduleId: module.moduleId,
        title: title,
        lessons: module.lessons,
      );
      _hasUnsavedChanges = true;
    });
  }

  void _updateLesson(int moduleIndex, int lessonIndex, LessonModel updatedLesson) {
    setState(() {
      final module = _modules[moduleIndex];
      final lessons = List<LessonModel>.from(module.lessons);
      lessons[lessonIndex] = updatedLesson;
      _modules[moduleIndex] = ModuleModel(
        moduleId: module.moduleId,
        title: module.title,
        lessons: lessons,
      );
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Content',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              child: Center(
                child: Text(
                  'Unsaved Changes',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text(
                            'Import XML',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: _importFromXml,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text(
                            'Export XML',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: _exportToXml,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Add Module',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          ),
                          onPressed: _addModule,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text(
                            'Save',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          ),
                          onPressed: _saveToCourse,
                        ),
                      ),
                    ],
                  ),
                ),

                // Modules List
                Expanded(
                  child: _modules.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 80,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No modules yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Import from XML or add a new module',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _modules.length,
                          itemBuilder: (context, moduleIndex) {
                            return _buildModuleCard(moduleIndex);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildModuleCard(int moduleIndex) {
    final module = _modules[moduleIndex];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
        title: TextField(
          controller: TextEditingController(text: module.title),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Module Title',
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          onChanged: (value) => _updateModuleTitle(moduleIndex, value),
        ),
        subtitle: Text('${module.lessons.length} lessons'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primaryContainer),
              onPressed: () => _addLesson(moduleIndex),
              tooltip: 'Add Lesson',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              onPressed: () {
                _deleteModule(moduleIndex);
              },
              tooltip: 'Delete Module',
            ),
          ],
        ),
        children: [
          if (module.lessons.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No lessons in this module',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          else
            ...module.lessons.asMap().entries.map((entry) {
              final lessonIndex = entry.key;
              final lesson = entry.value;
              return _buildLessonTile(moduleIndex, lessonIndex, lesson);
            }),
        ],
      ),
    );
  }

  Widget _buildLessonTile(int moduleIndex, int lessonIndex, LessonModel lesson) {
    return ListTile(
      leading: Icon(_getLessonIcon(lesson.type)),
      title: Text(lesson.title),
      subtitle: Text('${lesson.type} • ${lesson.duration} min'),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
        onPressed: () => _deleteLesson(moduleIndex, lessonIndex),
      ),
      onTap: () => _showLessonEditor(moduleIndex, lessonIndex, lesson),
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'reading':
        return Icons.article;
      default:
        return Icons.circle;
    }
  }

  void _showLessonEditor(int moduleIndex, int lessonIndex, LessonModel lesson) {
    final titleController = TextEditingController(text: lesson.title);
    final durationController = TextEditingController(text: lesson.duration.toString());
    final videoURLController = TextEditingController(text: lesson.videoURL ?? '');
    final contentController = TextEditingController(text: lesson.content ?? '');
    String selectedType = lesson.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Lesson Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Lesson Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                    DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                    DropdownMenuItem(value: 'reading', child: Text('Reading')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (selectedType == 'video') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: videoURLController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (selectedType == 'reading') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedLesson = LessonModel(
                  lessonId: lesson.lessonId,
                  title: titleController.text.trim(),
                  duration: int.tryParse(durationController.text) ?? 0,
                  type: selectedType,
                  videoURL: selectedType == 'video' && videoURLController.text.isNotEmpty
                      ? videoURLController.text.trim()
                      : null,
                  content: selectedType == 'reading' && contentController.text.isNotEmpty
                      ? contentController.text.trim()
                      : null,
                );
                _updateLesson(moduleIndex, lessonIndex, updatedLesson);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

