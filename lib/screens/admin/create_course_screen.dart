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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create New Course', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: SwitchListTile(
                title: const Text('Publish Course', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Published courses will be visible to students',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                value: _isPublished,
                onChanged: (value) {
                  setState(() => _isPublished = value);
                },
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 40),

            // Create Button
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          helperText: helperText,
          helperStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedLevel,
        dropdownColor: Theme.of(context).colorScheme.surface,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Level *',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          prefixIcon: Icon(Icons.signal_cellular_alt, color: Colors.white.withOpacity(0.5)),
        ),
        items: const [
          DropdownMenuItem(value: 'beginner', child: Text('Beginner', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'intermediate', child: Text('Intermediate', style: TextStyle(color: Colors.white))),
          DropdownMenuItem(value: 'advanced', child: Text('Advanced', style: TextStyle(color: Colors.white))),
        ],
        onChanged: (value) {
          setState(() => _selectedLevel = value!);
        },
      ),
    );
  }
}