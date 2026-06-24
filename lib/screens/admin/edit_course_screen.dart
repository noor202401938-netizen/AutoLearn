// lib/screens/admin/edit_course_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/course_manager.dart';
import '../../model/course_model.dart';

class EditCourseScreen extends StatefulWidget {
  final CourseModel course;

  const EditCourseScreen({super.key, required this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourseManager _courseManager = CourseManager();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _instructorController;
  late TextEditingController _categoryController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _thumbnailController;

  late String _selectedLevel;
  late bool _isPublished;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _descriptionController =
        TextEditingController(text: widget.course.description);
    _instructorController =
        TextEditingController(text: widget.course.instructor);
    _categoryController = TextEditingController(text: widget.course.category);
    _durationController =
        TextEditingController(text: widget.course.duration.toString());
    _priceController =
        TextEditingController(text: widget.course.price.toString());
    _thumbnailController =
        TextEditingController(text: widget.course.thumbnailURL);
    _selectedLevel = widget.course.level;
    _isPublished = widget.course.isPublished;
  }

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

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCourse = widget.course.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        instructor: _instructorController.text.trim(),
        category: _categoryController.text.trim(),
        level: _selectedLevel,
        duration: int.parse(_durationController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        thumbnailURL: _thumbnailController.text.trim(),
        isPublished: _isPublished,
        updatedAt: DateTime.now(),
      );

      final result = await _courseManager.updateCourse(updatedCourse);

      setState(() => _isLoading = false);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course updated successfully!'),
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
        title: Text('Edit Course', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
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
                // Course ID Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Course ID: ${widget.course.courseId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 24),

                // Stats Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Enrollments',
                              widget.course.enrollmentCount.toString(),
                              Icons.people,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Rating',
                              '${widget.course.rating.toStringAsFixed(1)} (${widget.course.ratingCount})',
                              Icons.star,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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

                // Update Button
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
                          onPressed: _updateCourse,
                          child: const Text(
                            'Update Course',
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}