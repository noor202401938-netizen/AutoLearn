import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../backend/api_client.dart';
import '../../business_logic/ai_feedback_engine.dart';
import '../../business_logic/certificate_manager.dart';
import '../../repository/auth_repository.dart';
import '../../repository/quiz_repository.dart';
import '../../model/quiz_model.dart';
import 'certificate_screen.dart';

class AssignmentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String moduleId;
  final String moduleTitle;
  final String lessonId;
  final String lessonTitle;

  const AssignmentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final AIFeedbackEngine _feedbackEngine = AIFeedbackEngine();
  final QuizRepository _quizRepository = QuizRepository();
  final CertificateManager _certificateManager = CertificateManager();
  final TextEditingController _submissionController = TextEditingController();
  bool _certificateShown = false;

  AssignmentModel? _assignment;
  AssignmentSubmissionModel? _existingSubmission;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showFeedback = false;

  bool _isFileUploaded = false;
  String _uploadedFileName = '';

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoading = true);
    try {
      _assignment =
          await _quizRepository.getAssignmentByLessonId(widget.lessonId);

      if (_assignment != null) {
        final user = await AuthRepository().getCurrentUser();
        final uid = user?['uid'] as String?;
        if (uid != null) {
          _existingSubmission =
              await _quizRepository.getUserAssignmentSubmission(
            userId: uid,
            assignmentId: _assignment!.assignmentId,
          );

          if (_existingSubmission != null) {
            _submissionController.text = _existingSubmission!.content;
            if (_existingSubmission!.content.startsWith('FILE:')) {
              _isFileUploaded = true;
              _uploadedFileName = _existingSubmission!.content.substring(5);
            }
            if (_existingSubmission!.isGraded) {
              _showFeedback = true;
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignment: ')),
        );
      }
    }
  }

  Future<void> _submitAssignment() async {
    String content = _submissionController.text.trim();
    if (content.isEmpty && !_isFileUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your submission or upload a file')),
      );
      return;
    }

    if (_isFileUploaded) {
      content = 'FILE:\n\n' + content;
    }

    final user = await AuthRepository().getCurrentUser();
    final uid = user?['uid'] as String?;
    if (uid == null || _assignment == null) return;

    setState(() => _isSubmitting = true);

    try {
      final feedback = await _feedbackEngine.generateAssignmentFeedback(
        assignmentTitle: _assignment!.title,
        assignmentInstructions: _assignment!.instructions,
        studentSubmission: content,
        maxPoints: _assignment!.maxPoints,
      );

      final score = _feedbackEngine.extractScoreFromFeedback(
        feedback,
        _assignment!.maxPoints,
      );

      final submission = AssignmentSubmissionModel(
        submissionId: 'sub_',
        userId: uid,
        assignmentId: _assignment!.assignmentId,
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        content: content,
        feedback: feedback,
        score: score,
        isGraded: true,
        submittedAt: DateTime.now(),
        gradedAt: DateTime.now(),
      );

      await _quizRepository.submitAssignment(submission);

      setState(() {
        _existingSubmission = submission;
        _showFeedback = true;
        _isSubmitting = false;
      });

      if (!_certificateShown) {
        _certificateShown = true;
        _showCertificate();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignment submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting assignment: ')),
        );
      }
    }
  }

  Future<void> _mockFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiClient.baseUrl}/upload'),
        );

        final token = await ApiClient.instance.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path!,
          ));
        }

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          setState(() {
            _isFileUploaded = true;
            _uploadedFileName = file.name;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully')),
          );
        } else {
          throw Exception('Failed to upload file');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  Future<void> _showCertificate() async {
    try {
      final certificate = await _certificateManager.generateCertificate(
        courseId: widget.courseId,
        courseName: widget.courseTitle,
        lessonId: widget.lessonId,
        lessonName: widget.lessonTitle,
      );

      if (certificate != null && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CertificateScreen(certificate: certificate),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error showing certificate: ');
    }
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AutoLearn',
          style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary))
            : _assignment == null
                ? Center(
                    child: Text('Assignment not found',
                        style: theme.textTheme.bodyMedium))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 800;
                            return Flex(
                              direction:
                                  isDesktop ? Axis.horizontal : Axis.vertical,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: isDesktop ? 8 : 0,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildAssignmentHeader(),
                                      const SizedBox(height: 24),
                                      _buildInstructions(),
                                      const SizedBox(height: 24),
                                      _buildResources(),
                                    ],
                                  ),
                                ),
                                if (isDesktop) const SizedBox(width: 24),
                                if (!isDesktop) const SizedBox(height: 24),
                                Expanded(
                                  flex: isDesktop ? 4 : 0,
                                  child: _showFeedback &&
                                          _existingSubmission != null
                                      ? _buildFeedbackView()
                                      : _buildSubmissionArea(),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildAssignmentHeader() {
    final theme = Theme.of(context);
    final isOverdue = _assignment!.dueDate.isBefore(DateTime.now());
    final daysUntilDue = _assignment!.dueDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        widget.moduleTitle.toUpperCase(),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _assignment!.title,
                      style: theme.textTheme.titleMedium?.copyWith(height: 1.1),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? theme.colorScheme.error.withValues(alpha: 0.1)
                      : theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isOverdue
                          ? theme.colorScheme.error.withValues(alpha: 0.3)
                          : theme.colorScheme.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isOverdue ? 'Overdue' : 'Due In',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverdue ? '0 Days' : '${daysUntilDue} Days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_assignment!.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _assignment!.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _assignment!.instructions,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildResources() {
    final theme = Theme.of(context);
    // Placeholder resources grid matching the design
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Resources',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildResourceCard(Icons.picture_as_pdf, 'Architecture_Spec.pdf',
                '2.4 MB', theme.colorScheme.error),
            _buildResourceCard(Icons.play_circle, 'Setup_Guide.mp4', '45 MB',
                theme.colorScheme.primary),
            _buildResourceCard(Icons.link, 'API_Documentation', 'External Link',
                theme.colorScheme.secondary),
            _buildResourceCard(Icons.table_chart, 'Dataset_v2.csv', '12 MB',
                theme.colorScheme.primary),
          ],
        )
      ],
    );
  }

  Widget _buildResourceCard(
      IconData icon, String title, String subtitle, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubmissionArea() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: theme.textTheme.labelLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Not Submitted',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Points', style: theme.textTheme.labelLarge),
              Text('0 / ',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 24),

          Text(
            'Upload Work',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // File Upload Zone
          GestureDetector(
            onTap: _mockFileUpload,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline, style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                        _isFileUploaded
                            ? Icons.check_circle
                            : Icons.cloud_upload,
                        color: _isFileUploaded
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        size: 32),
                    const SizedBox(height: 12),
                    Text(
                      _isFileUploaded
                          ? _uploadedFileName
                          : 'Drag & drop files here\nor click to browse',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Optional Text Field
          TextField(
            controller: _submissionController,
            maxLines: 4,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add optional comments...',
              hintStyle: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Submit Work', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Icon(Icons.send,
                            color: theme.colorScheme.onPrimary, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackView() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.stars, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Final Score',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Text(' / ',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Feedback',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Text(
              _existingSubmission!.feedback ?? 'No feedback available',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Submission',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            ),
            child: Text(
              _existingSubmission!.content,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Back to Course', style: theme.textTheme.bodyMedium),
            ),
          )
        ],
      ),
    );
  }
}
