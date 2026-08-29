import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../services/api_service.dart';
import '../services/forge_service.dart'; // Added for pollProjectStatus
import '../config/api_config.dart';
import '../widgets/web_preview/web_preview_pane.dart';

/// The core workspace screen.
/// Features a split-pane layout:
/// - Left: AI Chat interface for refining the project.
/// - Right: Live website preview using an iframe.
///
/// Handles polling for the initial generation status and subsequent edits.
class PreviewScreen extends StatefulWidget {
  final String? projectId;
  final String? jobId;
  final bool isGenerating;

  const PreviewScreen({
    super.key,
    this.projectId,
    this.jobId,
    this.isGenerating = false,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ApiService _apiService = ApiService();
  final ForgeService _forgeService = ForgeService();

  bool _isRegenerating = false;
  bool _isInitialGeneration = false;
  String? _generationError;
  Timer? _pollTimer;
  String? _currentProjectId;

  // Track refresh state for the preview iframe
  Key _previewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentProjectId = widget.projectId;

    // Set initial state based on whether we're generating
    if (widget.isGenerating || widget.jobId != null) {
      _isInitialGeneration = true;
      _messages.add({
        'role': 'assistant',
        'text':
            'Generating your project... Sit back and relax while your site is being forged.',
      });
      _startPolling();
    } else {
      _messages.add({
        'role': 'assistant',
        'text':
            'Welcome! Your project has been generated. How can I help you refine it?',
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  /// Polls the backend every 2 seconds to check if the generation job is complete.
  /// Updates the UI state when the job finishes (success or failure).
  void _startPolling() {
    if (widget.jobId == null && widget.projectId == null) {
      setState(() {
        _generationError = "No Job ID or Project ID provided.";
        _isInitialGeneration = false;
      });
      return;
    }

    // Poll every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // If we have a Job ID, check job status.
        // If only Project ID, assume we aren't generating anymore or use legacy status (which we mapped to job status in service, but that might fail if ID formats differ).
        // New flow uses Job ID.
        if (widget.jobId != null) {
          final status = await _forgeService.getJobStatus(widget.jobId!);

          if (!mounted) return;

          if (status.isCompleted) {
            timer.cancel();
            setState(() {
              _isInitialGeneration = false;
              _currentProjectId = status.projectId;
              _messages.add({
                'role': 'assistant',
                'text': 'Project generated successfully! displaying preview...',
              });
              _refreshPreview();
            });
          } else if (status.isFailed) {
            timer.cancel();
            setState(() {
              _isInitialGeneration = false;
              _generationError = status.error ?? 'Unknown error occurred';
              _messages.add({
                'role': 'assistant',
                'text': 'Generation failed: $_generationError',
              });
            });
          }
        } else {
          // Legacy/Direct mode - if we have projectId but flag says generating?
          // We shouldn't be here in new flow. Stop polling.
          timer.cancel();
          setState(() => _isInitialGeneration = false);
        }
      } catch (e) {
        // Log error but continue polling (network glitches happen)
        print('Polling error: $e');
      }
    });
  }

  void _refreshPreview() {
    setState(() {
      _previewKey = UniqueKey();
    });
  }

  /// Sends a refinement request to the backend.
  /// Effectively an "Edit" or "Iterate" loop.
  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    // Ensure we have a project ID before editing
    if (_currentProjectId == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatController.clear();
      _isRegenerating = true;
    });

    try {
      await _apiService.editProject(_currentProjectId!, text);

      // Successfully regenerated
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Changes applied! Refreshing preview...',
        });
        _isRegenerating = false;
        _refreshPreview(); // Force iframe reload
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Error applying changes: $e',
        });
        _isRegenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF00F0FF), size: 20),
            const SizedBox(width: 12),
            Text(
              'FORGE AI EDITOR',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 1.2,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'Project: ${_currentProjectId != null && _currentProjectId!.length >= 8 ? _currentProjectId!.substring(0, 8).toUpperCase() : "..."}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Chat / Prompt UI
          SizedBox(
            width: 380,
            child: Column(
              children: [
                // Chat Messages
                Expanded(
                  child: Container(
                    color: const Color(0xFF0F172A),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['role'] == 'user';
                        return _buildChatBubble(msg['text'] ?? '', isUser);
                      },
                    ),
                  ),
                ),

                // Chat Input box at bottom
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(
                      top: BorderSide(color: Color(0xFF334155), width: 1),
                    ),
                  ),
                  child: Card(
                    elevation: 4,
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ask AI to edit...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Color(0xFF00F0FF)),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFF334155),
          ),

          // Right Panel: Live Preview
          Expanded(
            child: Container(
              color: const Color(0xFFF5F6FA), // Neutral workspace background
              child: Column(
                children: [
                  // Browser-like Toolbar
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Live Website Preview',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        _buildToolbarButton(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Refresh',
                          onPressed: _refreshPreview,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _currentProjectId == null
                              ? null
                              : () {
                                  web.window.open(
                                      ApiConfig.previewUrl(_currentProjectId!),
                                      '_blank');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _currentProjectId == null
                              ? null
                              : () {
                                  web.window.open(
                                      ApiConfig.downloadUrl(_currentProjectId!),
                                      '_blank');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Preview Content (The "Card" Container)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              if (_isInitialGeneration)
                                const _SkeletonLoader()
                              else if (_generationError != null)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 48),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Generation Failed',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _generationError!,
                                        style: const TextStyle(
                                            color: Colors.black54),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else if (_currentProjectId != null)
                                WebPreviewWeb(
                                  key: _previewKey,
                                  url: ApiConfig.previewUrl(_currentProjectId!),
                                )
                              else
                                const Center(
                                    child: Text("Waiting for Project ID...")),

                              // Overlay for regeneration (editing)
                              if (_isRegenerating)
                                Container(
                                  color: Colors.black.withOpacity(0.4),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Color(0xFF00F0FF),
                                          strokeWidth: 3,
                                        ),
                                        const SizedBox(height: 20),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E293B),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'REGENERATING...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              letterSpacing: 1.5,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (isUser)
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Loader ─────────────────────────────────────────────────────────

/// Animated shimmer skeleton that mimics a generated website layout.
/// Shows a nav bar, hero section, and content cards while the project builds.
class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _buildSkeletonContent(_controller.value);
      },
    );
  }

  Widget _buildSkeletonContent(double progress) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // ── Skeleton Nav Bar ────────────────────────────────────────────────
          _SkeletonNavBar(progress: progress),

          // ── Skeleton Body ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero
                  _SkeletonHero(progress: progress),
                  const SizedBox(height: 24),
                  // Content cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        _SkeletonCardRow(progress: progress),
                        const SizedBox(height: 20),
                        _SkeletonParagraph(progress: progress),
                        const SizedBox(height: 20),
                        _SkeletonCardRow(
                            progress: progress, isWide: true),
                        const SizedBox(height: 20),
                        _SkeletonParagraph(
                            progress: progress, lines: 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Status Bar ──────────────────────────────────────────────────────
          _SkeletonStatusBar(progress: progress),
        ],
      ),
    );
  }
}

// ── Skeleton sub-components ────────────────────────────────────────────────

class _SkeletonNavBar extends StatelessWidget {
  final double progress;
  const _SkeletonNavBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          _Bone(width: 80, height: 18, progress: progress, radius: 4),
          const SizedBox(width: 32),
          _Bone(width: 50, height: 14, progress: progress, radius: 3),
          const SizedBox(width: 16),
          _Bone(width: 60, height: 14, progress: progress, radius: 3),
          const SizedBox(width: 16),
          _Bone(width: 50, height: 14, progress: progress, radius: 3),
          const Spacer(),
          _Bone(width: 90, height: 32, progress: progress, radius: 6),
        ],
      ),
    );
  }
}

class _SkeletonHero extends StatelessWidget {
  final double progress;
  const _SkeletonHero({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      color: const Color(0xFFF1F3F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Bone(width: 320, height: 36, progress: progress, radius: 6),
          const SizedBox(height: 12),
          _Bone(width: 480, height: 36, progress: progress, radius: 6),
          const SizedBox(height: 20),
          _Bone(width: 240, height: 18, progress: progress, radius: 4),
          const SizedBox(height: 8),
          _Bone(width: 280, height: 18, progress: progress, radius: 4),
          const SizedBox(height: 28),
          Row(
            children: [
              _Bone(width: 120, height: 40, progress: progress, radius: 8),
              const SizedBox(width: 12),
              _Bone(width: 120, height: 40, progress: progress, radius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCardRow extends StatelessWidget {
  final double progress;
  final bool isWide;
  const _SkeletonCardRow({required this.progress, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    final count = isWide ? 2 : 3;
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < count - 1 ? 12 : 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8ECF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bone(
                      width: 40,
                      height: 40,
                      progress: progress,
                      radius: 8),
                  const SizedBox(height: 12),
                  _Bone(
                      width: double.infinity,
                      height: 16,
                      progress: progress,
                      radius: 4),
                  const SizedBox(height: 8),
                  _Bone(
                      width: double.infinity,
                      height: 12,
                      progress: progress,
                      radius: 4),
                  const SizedBox(height: 4),
                  _Bone(
                      width: isWide ? 120 : 80,
                      height: 12,
                      progress: progress,
                      radius: 4),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SkeletonParagraph extends StatelessWidget {
  final double progress;
  final int lines;
  const _SkeletonParagraph({required this.progress, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _Bone(
            width: i == lines - 1
                ? MediaQuery.of(context).size.width * 0.5
                : double.infinity,
            height: 14,
            progress: progress,
            radius: 4,
          ),
        );
      }),
    );
  }
}

class _SkeletonStatusBar extends StatelessWidget {
  final double progress;
  const _SkeletonStatusBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Color(0xFF00F0FF),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'FORGING PROJECT',
                style: TextStyle(
                  color: const Color(0xFF00F0FF).withOpacity(0.85),
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Animated dots
              _AnimatedDots(progress: progress),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Sit back and relax while your site is being forged...',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  final double progress;
  const _AnimatedDots({required this.progress});

  @override
  Widget build(BuildContext context) {
    final dotCount = ((progress * 3) % 4).floor();
    return Text(
      '.' * dotCount,
      style: const TextStyle(
        color: Color(0xFF00F0FF),
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Core Bone (shimmer cell) ────────────────────────────────────────────────

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final double progress;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    required this.progress,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _ShimmerPainter(progress: progress),
        child: SizedBox(
          width: width == double.infinity ? double.infinity : width,
          height: height,
        ),
      ),
    );
  }
}

// ── Shimmer Painter ─────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double progress;

  const _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill
    final basePaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawRect(Offset.zero & size, basePaint);

    // Shimmer sweep
    final shimmerX = (progress * (size.width + 200)) - 100;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFFE2E8F0),
          Color(0xFFF8FAFC),
          Color(0xFFEFF2F7),
          Color(0xFFE2E8F0),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(
        Rect.fromLTWH(shimmerX - 100, 0, 200, size.height),
      );

    canvas.drawRect(Offset.zero & size, shimmerPaint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}
