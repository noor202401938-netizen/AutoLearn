// lib/screens/admin/create_course_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../repository/auth_repository.dart';
import '../../model/course_model.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourseManager _courseManager = CourseManager();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _thumbnailController = TextEditingController();

  String _selectedLevel = 'beginner';
  bool _isPublished = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await AuthRepository().getCurrentUser();
      if (currentUser == null || currentUser['uid'] == null) {
        throw Exception('Not authenticated');
      }

      // Generate course ID
      final courseId = 'course_${DateTime.now().millisecondsSinceEpoch}';

      final course = CourseModel(
        courseId: courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim(),
        category: _categoryController.text.trim(),
        level: _selectedLevel,
        duration: int.parse(_durationController.text.trim()),
        thumbnailURL: _thumbnailController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        isPublished: _isPublished,
        createdAt: DateTime.now(),
        createdBy: currentUser['uid'],
      );

      final result = await _courseManager.createCourse(course);

      setState(() => _isLoading = false);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course created successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
          Navigator.pop(context, true);
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
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Create New Course', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Container(
        
        child: SafeArea(
          child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Course Title *',
              hint: 'e.g., Introduction to Flutter',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description *',
              hint: 'Describe what students will learn...',
              icon: Icons.description,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course description';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Instructor
            _buildTextField(
              controller: _instructorController,
              label: 'Instructor Name *',
              hint: 'e.g., John Doe',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter instructor name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category
            _buildTextField(
              controller: _categoryController,
              label: 'Category *',
              hint: 'e.g., Mobile Development',
              icon: Icons.category,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter category';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Level
            _buildDropdownField(),
            const SizedBox(height: 20),

            // Duration
            _buildTextField(
              controller: _durationController,
              label: 'Duration (hours) *',
              hint: 'e.g., 10',
              icon: Icons.access_time,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price (USD) *',
              hint: 'e.g., 49.99 or 0 for free',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                if (double.parse(value) < 0) {
                  return 'Price cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Thumbnail URL
            _buildTextField(
              controller: _thumbnailController,
              label: 'Thumbnail URL',
              hint: 'https://example.com/image.jpg',
              icon: Icons.image,
              helperText: 'Optional: Leave empty for default icon',
            ),
            const SizedBox(height: 32),

            // Publish Toggle
            Container(
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                title: Text('Publish Course', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Published courses will be visible to students',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                value: _isPublished,
                onChanged: (value) {
                  setState(() => _isPublished = value);
                },
                activeColor: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),

            // Create Button
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shadowColor: Colors.transparent,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _createCourse,
                      child: const Text(
                        'Create Course',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: colorScheme.onSurface),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          helperText: helperText,
          helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedLevel,
        dropdownColor: colorScheme.surface,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: 'Level *',
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          prefixIcon: Icon(Icons.signal_cellular_alt, color: colorScheme.onSurfaceVariant),
        ),
        items: [
          DropdownMenuItem(value: 'beginner', child: Text('Beginner', style: TextStyle(color: colorScheme.onSurface))),
          DropdownMenuItem(value: 'intermediate', child: Text('Intermediate', style: TextStyle(color: colorScheme.onSurface))),
          DropdownMenuItem(value: 'advanced', child: Text('Advanced', style: TextStyle(color: colorScheme.onSurface))),
        ],
        onChanged: (value) {
          setState(() => _selectedLevel = value!);
        },
      ),
    );
  }
}
