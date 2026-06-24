import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      _assignment = await _quizRepository.getAssignmentByLessonId(widget.lessonId);

      if (_assignment != null) {
        final user = await AuthRepository().getCurrentUser();
        final uid = user?['uid'] as String?;
        if (uid != null) {
          _existingSubmission = await _quizRepository.getUserAssignmentSubmission(
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
        const SnackBar(content: Text('Please enter your submission or upload a file')),
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
                builder: (context) => CertificateScreen(certificate: certificate),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF4231C0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AutoLearn',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4231C0),
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4231C0)))
            : _assignment == null
                ? Center(child: Text('Assignment not found', style: GoogleFonts.inter(color: Colors.black)))
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 800;
                        return Flex(
                          direction: isDesktop ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isDesktop ? 8 : 0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: _showFeedback && _existingSubmission != null
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
    final isOverdue = _assignment!.dueDate.isBefore(DateTime.now());
    final daysUntilDue = _assignment!.dueDate.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4231C0).withOpacity(0.05),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4231C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        widget.moduleTitle.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4231C0),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _assignment!.title,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121C2A),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOverdue ? const Color(0xFFBA1A1A).withOpacity(0.1) : const Color(0xFF00724E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isOverdue ? const Color(0xFFBA1A1A).withOpacity(0.3) : const Color(0xFF00724E).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isOverdue ? 'Overdue' : 'Due In',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF00724E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverdue ? '0 Days' : ' Days',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? const Color(0xFFBA1A1A) : const Color(0xFF00724E),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          if (_assignment!.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _assignment!.description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF474554),
                height: 1.5,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF4231C0), size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121C2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _assignment!.instructions,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF474554),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResources() {
    // Placeholder resources grid matching the design
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Resources',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF121C2A),
          ),
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
            _buildResourceCard(Icons.picture_as_pdf, 'Architecture_Spec.pdf', '2.4 MB', const Color(0xFFBA1A1A)),
            _buildResourceCard(Icons.play_circle, 'Setup_Guide.mp4', '45 MB', const Color(0xFF6B38D4)),
            _buildResourceCard(Icons.link, 'API_Documentation', 'External Link', const Color(0xFF00724E)),
            _buildResourceCard(Icons.table_chart, 'Dataset_v2.csv', '12 MB', const Color(0xFF4231C0)),
          ],
        )
      ],
    );
  }
  
  Widget _buildResourceCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF121C2A)), overflow: TextOverflow.ellipsis),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF787586))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSubmissionArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF474554).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Not Submitted', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF474554))),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Points', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('0 / ', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF4231C0))),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFC8C4D7)),
          const SizedBox(height: 24),
          
          Text(
            'Upload Work',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121C2A),
            ),
          ),
          const SizedBox(height: 12),
          
          // File Upload Zone
          GestureDetector(
            onTap: _mockFileUpload,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8C4D7), style: BorderStyle.solid),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                       _isFileUploaded ? Icons.check_circle : Icons.cloud_upload, 
                       color: _isFileUploaded ? const Color(0xFF00724E) : const Color(0xFF4231C0), 
                       size: 32
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isFileUploaded ? _uploadedFileName : 'Drag & drop files here\nor click to browse',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554)),
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
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF121C2A)),
            decoration: InputDecoration(
              hintText: 'Add optional comments...',
              hintStyle: GoogleFonts.inter(color: const Color(0xFF787586)),
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC8C4D7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFC8C4D7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4231C0)),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4231C0), Color(0xFF6B38D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4231C0).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Submit Work', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.send, color: Colors.white, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4231C0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Final Score', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF474554))),
                      Text(' / ', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF121C2A))),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Feedback',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121C2A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
            ),
            child: Text(
              _existingSubmission!.feedback ?? 'No feedback available',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554), height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Submission',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF121C2A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8C4D7).withOpacity(0.5)),
            ),
            child: Text(
              _existingSubmission!.content,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF474554), height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3DFFF),
                foregroundColor: const Color(0xFF140067),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Back to Course', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}
