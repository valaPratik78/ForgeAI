import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/generation_model.dart';
import '../services/forge_service.dart';
import 'preview_screen.dart';
import '../main.dart';

/// The primary entry point for the user.
/// Redesigned to match the Forge AI "New Project Environment" screen.
/// Split-pane layout: left = Project Details + Architecture, right = Visual preview
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _forgeService = ForgeService();

  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Landing Page';
  String _themeColor = '#A788FA';
  String _aiModel = 'Nvidia';
  bool _isLoading = false;

  late AnimationController _scanAnimController;

  final List<String> _categories = [
    'Portfolio',
    'Landing Page',
    'Product Page',
    'Blog',
  ];

  final List<Map<String, String>> _colorPalette = [
    {'hex': '#A788FA', 'label': 'Violet'},
    {'hex': '#7701D0', 'label': 'Purple'},
    {'hex': '#00FF90', 'label': 'Emerald'},
    {'hex': '#FFB700', 'label': 'Amber'},
    {'hex': '#E3E1E9', 'label': 'White'},
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _projectNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generateApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String name = _projectNameController.text.trim();
      String desc = _descriptionController.text.trim();

      if (name.isEmpty) {
        if (_selectedCategory == 'Portfolio') {
          name = 'Alex Morgan';
          if (desc.isEmpty) desc = 'Creative technologist & senior product designer specializing in high-performance digital systems.';
        } else if (_selectedCategory == 'Landing Page') {
          name = 'Nova Systems';
          if (desc.isEmpty) desc = 'Next-generation cloud orchestration platform built for high-throughput teams and enterprise scale.';
        } else if (_selectedCategory == 'Product Page') {
          name = 'Aura Core X';
          if (desc.isEmpty) desc = 'Precision-engineered hardware and software interface for modern creative professionals.';
        } else {
          name = 'The Terminal Post';
          if (desc.isEmpty) desc = 'Deep analytical essays on software engineering, architecture, and technology culture.';
        }
      } else if (desc.isEmpty) {
        desc = 'A modern high-impact digital experience built for excellence, performance, and scalability.';
      }

      final request = GenerationRequest(
        applicationType: 'Website',
        projectName: name,
        description: desc,
        category: _selectedCategory,
        sections: ['Home', 'About', 'Contact'],
        themeColor: _themeColor,
        aiModel: _aiModel,
      );

      final response = await _forgeService.generateApplication(request);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            projectId: response.projectId,
            jobId: response.jobId,
            isGenerating: !response.isCompleted,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Column(
        children: [
          _buildNavBar(),
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(bottom: BorderSide(color: Color(0xFF27272A), width: 1)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Forge AI',
                style: TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(width: 40),
          ..._buildNavLinks(),
          const Spacer(),
          IconButton(
            onPressed: () {
              themeModeNotifier.value =
                  themeModeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
            icon: const Icon(Icons.dark_mode_outlined,
                color: Color(0xFFA1A1AA), size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: const BorderSide(color: Color(0xFF27272A)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildPrimaryButton(
            label: 'Launch Project',
            icon: Icons.rocket_launch_outlined,
            onTap: _isLoading ? null : _generateApplication,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavLinks() {
    final links = ['Home', 'Solutions', 'Pricing', 'Showcases'];
    return links.map((link) {
      final isActive = link == 'Home';
      return Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Text(
          link,
          style: TextStyle(
            color: isActive ? const Color(0xFFA78BFA) : const Color(0xFFA1A1AA),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            decoration: isActive ? TextDecoration.underline : null,
            decorationColor: const Color(0xFFA78BFA),
            decorationThickness: 2,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFA78BFA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (onTap == null)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                    text: 'New ',
                    style: TextStyle(color: Color(0xFFFAFAFA))),
                TextSpan(
                    text: 'Project Environment',
                    style: TextStyle(color: Color(0xFFA78BFA))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure your digital infrastructure. Forge AI will construct your optimized\narchitecture in real-time based on these parameters.',
            style: TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 340, child: _buildLeftPanel()),
                const SizedBox(width: 16),
                Expanded(child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildProjectDetailsCard(),
            const SizedBox(height: 12),
            _buildArchitectureCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildObsidianCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFA78BFA), size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard() {
    return _buildObsidianCard(
      title: 'Project Details',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('APPLICATION NAME'),
          const SizedBox(height: 6),
          _buildObsidianTextField(
              controller: _projectNameController,
              hint: 'Nexus E-Commerce'),
          const SizedBox(height: 14),
          _buildFieldLabel('CORE OBJECTIVE'),
          const SizedBox(height: 6),
          _buildObsidianTextField(
            controller: _descriptionController,
            hint:
                'A modern storefront for high-end mechanical keyboards...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureCard() {
    return _buildObsidianCard(
      title: 'Architecture',
      icon: Icons.grid_view_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('PRIMARY CATEGORY'),
          const SizedBox(height: 10),
          _buildCategoryGrid(),
          const SizedBox(height: 16),
          _buildFieldLabel('AI MODEL'),
          const SizedBox(height: 10),
          _buildAiModelSelector(),
          const SizedBox(height: 16),
          _buildFieldLabel('COLOR PALETTE'),
          const SizedBox(height: 4),
          Text(
            'HEX. MAP. ACTIVE',
            style: TextStyle(
              color: const Color(0xFFA78BFA).withOpacity(0.7),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          _buildColorPalette(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: const Text(
              'SYSTEM NOTE: SELECTED PALETTE WILL PROPAGATE TO ALL UI COMPONENTS.',
              style: TextStyle(
                color: Color(0xFFA1A1AA),
                fontSize: 10,
                letterSpacing: 0.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildObsidianTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Color(0xFFFAFAFA), fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF52525B), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF18181B),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFA78BFA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFA78BFA).withOpacity(0.15)
                  : const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFA78BFA)
                    : const Color(0xFF27272A),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFFA1A1AA),
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAiModelSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModelOption(
                id: 'Nvidia',
                label: 'Nemotron 70B (NIM)',
                color: const Color(0xFFA78BFA),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModelOption(
                id: 'Gemini',
                label: 'Gemini 1.5 Pro',
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildModelOption(
                id: 'OpenRouter',
                label: 'Nemotron Ultra (OR)',
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModelOption({
    required String id,
    required String label,
    required Color color,
  }) {
    final isSelected = _aiModel == id;
    return GestureDetector(
      onTap: () => setState(() => _aiModel = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF27272A),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFAFAFA),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Row(
      children: _colorPalette.map((c) {
        final isSelected = _themeColor == c['hex'];
        final color =
            Color(int.parse(c['hex']!.replaceFirst('#', '0xFF')));
        return GestureDetector(
          onTap: () => setState(() => _themeColor = c['hex']!),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  c['hex']!,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        Expanded(child: _buildHeroPreviewArea()),
        const SizedBox(height: 12),
        _buildGenerateButton(),
      ],
    );
  }

  Widget _buildHeroPreviewArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Row(
              children: [
                _buildStatusDot(
                    const Color(0xFF34D399), 'SYS_STATUS: OPTIMAL'),
                const Spacer(),
                _buildStatusDot(
                    const Color(0xFFA78BFA), 'NODE: FG-09'),
              ],
            ),
          ),
          Expanded(child: _buildHeroIllustration()),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: Color(0xFF27272A))),
            ),
            child: AnimatedBuilder(
              animation: _scanAnimController,
              builder: (_, __) {
                return Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFF34D399),
                          const Color(0xFFA78BFA),
                          _scanAnimController.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'RENDERING PREVIEW...',
                      style: TextStyle(
                        color: Color.lerp(
                          const Color(0xFF34D399),
                          const Color(0xFFA78BFA),
                          _scanAnimController.value,
                        ),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return AnimatedBuilder(
      animation: _scanAnimController,
      builder: (context, child) {
        return ClipRect(
          child: CustomPaint(
            painter: _ForgePainter(
              progress: _scanAnimController.value,
              primaryColor: const Color(0xFFA78BFA),
              accentColor: const Color(0xFF34D399),
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA78BFA).withOpacity(0.15),
                border: Border.all(
                  color: const Color(0xFFA78BFA).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child:
                  const Icon(Icons.bolt, color: Color(0xFFA78BFA), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'INTELLIGENCE FORGED',
              style: TextStyle(
                color: Color(0xFFFAFAFA),
                fontSize: 16,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI Powered Interface Design & Development',
              style: TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _generateApplication,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _isLoading
              ? const Color(0xFF7C3AED)
              : const Color(0xFFA78BFA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA78BFA).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isLoading
                  ? 'FORGING APPLICATION...'
                  : 'Generate Application',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            '© 2024 FORGE AI. POWERED BY FORGE AI LABORATORY.',
            style: TextStyle(color: Color(0xFF52525B), fontSize: 11),
          ),
          const Spacer(),
          ...['Documentation', 'Privacy', 'Terms', 'Twitter', 'Discord']
              .map(
            (l) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                l,
                style: const TextStyle(
                    color: Color(0xFF71717A), fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgePainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  _ForgePainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    paint.color = primaryColor.withOpacity(0.06);
    paint.strokeWidth = 1;
    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final scanY = size.height * progress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0),
          primaryColor.withOpacity(0.15),
          primaryColor.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));

    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 40, size.width, 80),
      scanPaint,
    );

    paint.color = primaryColor.withOpacity(0.3);
    paint.strokeWidth = 2;
    const bracketSize = 24.0;
    const margin = 16.0;

    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin + bracketSize, margin), paint);
    canvas.drawLine(const Offset(margin, margin),
        const Offset(margin, margin + bracketSize), paint);

    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin - bracketSize, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + bracketSize), paint);

    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + bracketSize, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin, size.height - margin - bracketSize), paint);

    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin - bracketSize, size.height - margin),
        paint);
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin, size.height - margin - bracketSize),
        paint);

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 1; i <= 3; i++) {
      final radius =
          80.0 * i + 40 * math.sin(progress * 2 * math.pi + i * 1.2);
      paint.color = primaryColor.withOpacity(0.04 * (4 - i));
      paint.strokeWidth = 1;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ForgePainter old) => old.progress != progress;
}
