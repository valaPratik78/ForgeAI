import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/generation_model.dart';
import '../services/forge_service.dart';
import '../config/api_config.dart';
import '../widgets/web_preview/web_preview_pane.dart';
import 'preview_screen.dart';
import '../main.dart';

/// The primary entry point for ForgeAI.
/// Features a gated 4-step wizard workflow:
/// Step 1: Site Identity & Page Selection
/// Step 2: Custom Page Content (Zero dummy data, with AI prompt helper)
/// Step 3: Pre-built Template Selection & Live Interactive Preview
/// Step 4: Styling (Color Theme, Relevant Image Mood) & Launch
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _forgeService = ForgeService();

  // Wizard state
  int _currentStep = 0;
  bool _isLoading = false;
  late AnimationController _scanAnimController;

  // Step 1: Project Identity & Pages
  final _projectNameController = TextEditingController();
  final _objectiveController = TextEditingController();
  String _selectedCategory = 'Startup / SaaS';

  final List<String> _categories = [
    'Startup / SaaS',
    'Portfolio',
    'Business',
    'Landing Page',
    'Product Page',
    'Blog',
  ];

  final List<Map<String, String>> _availablePages = [
    {'id': 'Home', 'file': 'index.html', 'desc': 'Primary landing showcase'},
    {'id': 'About Us', 'file': 'about.html', 'desc': 'Mission, story & leadership'},
    {'id': 'Services', 'file': 'services.html', 'desc': 'Offerings & value propositions'},
    {'id': 'Pricing', 'file': 'pricing.html', 'desc': 'Plans, tiers & billing options'},
    {'id': 'Contact', 'file': 'contact.html', 'desc': 'Inquiries & connection channels'},
    {'id': 'Projects', 'file': 'projects.html', 'desc': 'Case studies & portfolio grid'},
    {'id': 'Features', 'file': 'features.html', 'desc': 'Deep-dive product capabilities'},
    {'id': 'Articles', 'file': 'articles.html', 'desc': 'Editorial essays & news'},
  ];

  final Set<String> _selectedPageIds = {'Home', 'About Us', 'Contact'};

  // Step 2: Custom Page Content (Controllers per page)
  final Map<String, TextEditingController> _pageContentControllers = {};
  String _activeContentTab = 'Home';

  // Step 3: Templates
  List<TemplateInfo> _templates = [];
  String _selectedTemplateId = 'startup';
  bool _loadingTemplates = true;

  // Step 4: Design Theme & Images
  String _themeColor = '#A788FA';
  String _imageTheme = 'Modern Tech & Minimalist';
  String _aiModel = 'Nvidia';
  final _customHexController = TextEditingController(text: '#A788FA');

  final List<Map<String, String>> _colorPalette = [
    {'hex': '#A788FA', 'label': 'Violet'},
    {'hex': '#2563EB', 'label': 'Blue'},
    {'hex': '#00FF90', 'label': 'Emerald'},
    {'hex': '#FFB700', 'label': 'Amber'},
    {'hex': '#FF2D78', 'label': 'Rose'},
    {'hex': '#7701D0', 'label': 'Purple'},
    {'hex': '#E3E1E9', 'label': 'White'},
  ];

  final List<String> _imageThemes = [
    'Modern Tech & Minimalist',
    'Creative Studio & Design',
    'Enterprise & Corporate',
    'Product & Hardware',
    'Editorial & Storytelling',
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _initControllersForSelectedPages();
    _loadTemplates();
  }

  void _initControllersForSelectedPages() {
    for (final page in _selectedPageIds) {
      if (!_pageContentControllers.containsKey(page)) {
        _pageContentControllers[page] = TextEditingController();
      }
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final list = await _forgeService.fetchTemplates();
      if (mounted) {
        setState(() {
          _templates = list;
          _loadingTemplates = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingTemplates = false);
      }
    }
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _projectNameController.dispose();
    _objectiveController.dispose();
    _customHexController.dispose();
    for (final c in _pageContentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Step Validation & Gating ---
  bool _validateStep(int step) {
    if (step == 0) {
      if (_projectNameController.text.trim().isEmpty) {
        _showToast('Please provide a Site / Project Name to continue.');
        return false;
      }
      if (_selectedPageIds.isEmpty) {
        _showToast('Please select at least one page for your website.');
        return false;
      }
      return true;
    }

    if (step == 1) {
      // Ensure each selected page has some content
      for (final pageId in _selectedPageIds) {
        final ctrl = _pageContentControllers[pageId];
        if (ctrl == null || ctrl.text.trim().isEmpty) {
          _showToast(
              'Please provide content for the "$pageId" page (or use AI prompt helper).');
          setState(() => _activeContentTab = pageId);
          return false;
        }
      }
      return true;
    }

    if (step == 2) {
      if (_selectedTemplateId.isEmpty) {
        _showToast('Please select a template to continue.');
        return false;
      }
      return true;
    }

    return true;
  }

  void _goToStep(int targetStep) {
    if (targetStep < _currentStep) {
      setState(() => _currentStep = targetStep);
      return;
    }
    // Gating check: All intermediate steps must be valid
    for (int s = _currentStep; s < targetStep; s++) {
      if (!_validateStep(s)) return;
    }
    setState(() => _currentStep = targetStep);
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        _generateApplication();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyAiPromptForPage(String pageId) {
    final siteName = _projectNameController.text.trim().isNotEmpty
        ? _projectNameController.text.trim()
        : 'our brand';
    final objective = _objectiveController.text.trim().isNotEmpty
        ? _objectiveController.text.trim()
        : 'a premier high-performance digital presence';

    final promptText =
        'Write realistic, high-converting, and detailed marketing copy for the "$pageId" page of "$siteName", which is a $_selectedCategory website. Core objective: $objective. Provide compelling headlines, value propositions, key sections, and call-to-actions.';

    Clipboard.setData(ClipboardData(text: promptText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied AI prompt for "$pageId" to clipboard! Paste into ChatGPT/Gemini.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _generateApplication() async {
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) return;

    setState(() => _isLoading = true);

    try {
      final name = _projectNameController.text.trim();
      final desc = _objectiveController.text.trim().isNotEmpty
          ? _objectiveController.text.trim()
          : 'High-impact digital experience built for excellence and scalability.';

      // Collect user-provided page contents
      final Map<String, String> pageContents = {};
      final List<String> selectedFileNames = [];

      for (final p in _availablePages) {
        if (_selectedPageIds.contains(p['id'])) {
          selectedFileNames.add(p['file']!);
          final content = _pageContentControllers[p['id']]?.text.trim();
          if (content != null && content.isNotEmpty) {
            pageContents[p['id']!] = content;
          }
        }
      }

      final request = GenerationRequest(
        applicationType: 'Website',
        projectName: name,
        description: desc,
        category: _selectedCategory,
        sections: _selectedPageIds.toList(),
        themeColor: _themeColor,
        aiModel: _aiModel,
        selectedPages: selectedFileNames,
        pageContents: pageContents,
        template: _selectedTemplateId,
        imageTheme: _imageTheme,
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
      _showToast(e.toString());
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
          _buildWizardStepper(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomBar(),
          _buildFooter(),
        ],
      ),
    );
  }

  // --- Header Navigation ---
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Forge AI',
                style: TextStyle(
                  color: Color(0xFFFAFAFA),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 14, color: Color(0xFFA78BFA)),
                SizedBox(width: 6),
                Text(
                  'Multi-Step Site Forge Studio',
                  style: TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Toggle Theme',
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
        ],
      ),
    );
  }

  // --- Multi-Step Wizard Indicator ---
  Widget _buildWizardStepper() {
    final stepLabels = [
      {'num': '1', 'title': 'Site & Pages', 'sub': 'Configure Pages'},
      {'num': '2', 'title': 'Page Content', 'sub': 'Zero Dummy Data'},
      {'num': '3', 'title': 'Template & Preview', 'sub': 'Live Demo'},
      {'num': '4', 'title': 'Theme & Launch', 'sub': 'Colors & Images'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0F),
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: List.generate(stepLabels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            final isCompleted = _currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? const Color(0xFFA78BFA)
                    : const Color(0xFF27272A),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final step = stepLabels[stepIndex];
          final isActive = _currentStep == stepIndex;
          final isCompleted = _currentStep > stepIndex;

          return InkWell(
            onTap: () => _goToStep(stepIndex),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFFA78BFA)
                          : isActive
                              ? const Color(0xFFA78BFA).withOpacity(0.2)
                              : const Color(0xFF18181B),
                      border: Border.all(
                        color: isCompleted || isActive
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF3F3F46),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              step['num']!,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFFA1A1AA),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFFFAFAFA)
                              : isCompleted
                                  ? const Color(0xFFA78BFA)
                                  : const Color(0xFF71717A),
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        step['sub']!,
                        style: const TextStyle(
                          color: Color(0xFF52525B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Step Routing ---
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1SiteAndPages();
      case 1:
        return _buildStep2PageContent();
      case 2:
        return _buildStep3TemplatesAndPreview();
      case 3:
        return _buildStep4ThemeAndLaunch();
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // STEP 1: Site Identity & Page Selection
  // ==========================================
  Widget _buildStep1SiteAndPages() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Identity Form
        Expanded(
          flex: 5,
          child: _buildCard(
            title: 'Project Identity & Purpose',
            icon: Icons.badge_outlined,
            expand: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('WEBSITE / PROJECT NAME *'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _projectNameController,
                    hint: 'e.g. Apex Workflow, Sarah Designer, CloudPeak Labs',
                    prefixIcon: Icons.web_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('INDUSTRY / CATEGORY'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: const Color(0xFFA78BFA).withOpacity(0.2),
                        backgroundColor: const Color(0xFF18181B),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFFA1A1AA),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF27272A),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('CORE OBJECTIVE & MISSION'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _objectiveController,
                    hint:
                        'A high-performance modern platform built to empower innovators and automate complex workflows.',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Target Pages Matrix
        Expanded(
          flex: 6,
          child: _buildCard(
            title: 'Website Pages Matrix (Choose which pages to build)',
            icon: Icons.account_tree_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFFA78BFA), size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select all pages you wish to include. In Step 2, you will provide custom copy for each chosen page so your site is built without dummy data.',
                          style: TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _availablePages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final page = _availablePages[index];
                      final pageId = page['id']!;
                      final isHome = pageId == 'Home';
                      final isSelected = _selectedPageIds.contains(pageId);

                      return InkWell(
                        onTap: isHome
                            ? null
                            : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedPageIds.remove(pageId);
                                  } else {
                                    _selectedPageIds.add(pageId);
                                    if (!_pageContentControllers
                                        .containsKey(pageId)) {
                                      _pageContentControllers[pageId] =
                                          TextEditingController();
                                    }
                                  }
                                });
                              },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA78BFA).withOpacity(0.08)
                                : const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFA78BFA).withOpacity(0.7)
                                  : const Color(0xFF27272A),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: isHome
                                    ? null
                                    : (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedPageIds.add(pageId);
                                            if (!_pageContentControllers
                                                .containsKey(pageId)) {
                                              _pageContentControllers[pageId] =
                                                  TextEditingController();
                                            }
                                          } else {
                                            _selectedPageIds.remove(pageId);
                                          }
                                        });
                                      },
                                activeColor: const Color(0xFFA78BFA),
                                checkColor: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          pageId,
                                          style: const TextStyle(
                                            color: Color(0xFFFAFAFA),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF27272A),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            page['file']!,
                                            style: const TextStyle(
                                              color: Color(0xFFA1A1AA),
                                              fontSize: 9,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        if (isHome) ...[
                                          const SizedBox(width: 8),
                                          const Text(
                                            '(Required)',
                                            style: TextStyle(
                                              color: Color(0xFFA78BFA),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      page['desc']!,
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: Custom Page Content (Zero Dummy Data)
  // ==========================================
  Widget _buildStep2PageContent() {
    final selectedPagesList = _selectedPageIds.toList();
    if (!_selectedPageIds.contains(_activeContentTab)) {
      _activeContentTab =
          selectedPagesList.isNotEmpty ? selectedPagesList.first : 'Home';
    }

    final activeCtrl = _pageContentControllers[_activeContentTab] ??=
        TextEditingController();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Selected Pages Navigation List
        SizedBox(
          width: 240,
          child: _buildCard(
            title: 'Pages To Fill (${_selectedPageIds.length})',
            icon: Icons.list_alt_rounded,
            child: ListView.separated(
              itemCount: selectedPagesList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final pageId = selectedPagesList[idx];
                final isCurrent = _activeContentTab == pageId;
                final hasContent = _pageContentControllers[pageId]
                        ?.text
                        .trim()
                        .isNotEmpty ??
                    false;

                return InkWell(
                  onTap: () => setState(() => _activeContentTab = pageId),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFA78BFA).withOpacity(0.15)
                          : const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF27272A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasContent
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: hasContent
                              ? const Color(0xFF10B981)
                              : const Color(0xFF71717A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pageId,
                            style: TextStyle(
                              color: isCurrent
                                  ? const Color(0xFFFAFAFA)
                                  : const Color(0xFFA1A1AA),
                              fontSize: 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: AI Prompt Assistant & Page Content Textbox
        Expanded(
          child: _buildCard(
            title: 'Custom Content for: $_activeContentTab Page',
            icon: Icons.edit_note_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Helper Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED).withOpacity(0.2),
                        const Color(0xFF18181B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFA78BFA).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA78BFA).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Color(0xFFA78BFA), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zero Dummy Data Guarantee — Use AI To Generate & Paste Content Here',
                              style: TextStyle(
                                color: Color(0xFFFAFAFA),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tip: Ask ChatGPT, Gemini, or Claude to write copy for your site and paste it below. Forge AI will inject your exact text into the generated website!',
                              style: TextStyle(
                                color: Color(0xFFA1A1AA),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _copyAiPromptForPage(_activeContentTab),
                        icon: const Icon(Icons.copy, size: 13),
                        label: const Text('Copy Prompt for AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA78BFA),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLabel('ENTER PAGE CONTENT / TEXT (HEADLINES, DETAILS, SECTIONS, BULLETS) *'),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildTextField(
                    controller: activeCtrl,
                    hint:
                        'Paste or write your detailed content for $_activeContentTab here...\n\nExample:\n- Hero Headline: Empowering Next-Gen Creators\n- Subtitle: The all-in-one suite designed to accelerate your velocity.\n- Key Highlights: Lightning performance, seamless workflow integration, enterprise-level security.\n- Story/Bio: Founded by engineers passionate about craft and excellence.',
                    maxLines: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Content will be directly forged into the generated HTML structure without filler text.',
                      style: TextStyle(
                        color: const Color(0xFFA1A1AA).withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: Pre-built Template Selection & Live Preview
  // ==========================================
  Widget _buildStep3TemplatesAndPreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Template Cards List
        SizedBox(
          width: 380,
          child: _buildCard(
            title: 'Choose Pre-Built Template',
            icon: Icons.dashboard_customize_outlined,
            child: _loadingTemplates
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA78BFA)))
                : ListView.separated(
                    itemCount: _templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = _templates[index];
                      final isSelected = _selectedTemplateId == t.id;

                      return InkWell(
                        onTap: () => setState(() => _selectedTemplateId = t.id),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFA78BFA).withOpacity(0.12)
                                : const Color(0xFF18181B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFA78BFA)
                                  : const Color(0xFF27272A),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    t.name,
                                    style: const TextStyle(
                                      color: Color(0xFFFAFAFA),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA78BFA),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.description,
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: t.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF27272A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 9,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Live Interactive Iframe Preview of the Pre-built Template
        Expanded(
          child: _buildCard(
            title: 'Live Interactive Template Preview (Zero Dummy Data Needed To Explore)',
            icon: Icons.preview_rounded,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF4444))),
                          const SizedBox(width: 6),
                          Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFBBF24))),
                          const SizedBox(width: 6),
                          Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF10B981))),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090B),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Text(
                            ApiConfig.templatePreviewUrl(_selectedTemplateId),
                            style: const TextStyle(
                              color: Color(0xFF71717A),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: WebPreviewWeb(
                      key: ValueKey(_selectedTemplateId),
                      url: ApiConfig.templatePreviewUrl(_selectedTemplateId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: Styling (Color Theme & Images) & Launch
  // ==========================================
  Widget _buildStep4ThemeAndLaunch() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Visual Styling Options (two stacked cards, each Expanded)
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: _buildCard(
                  title: 'Brand Color Theme',
                  icon: Icons.palette_outlined,
                  expand: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('COLOR PALETTE'),
                        const SizedBox(height: 10),
                        Row(
                          children: _colorPalette.map((c) {
                            final isSelected = _themeColor == c['hex'];
                            final color = Color(int.parse(
                                c['hex']!.replaceFirst('#', '0xFF')));
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _themeColor = c['hex']!;
                                  _customHexController.text = c['hex']!;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['label']!,
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('CUSTOM HEX CODE'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _customHexController,
                                hint: '#7C3AED',
                                onChanged: (val) {
                                  if (val.startsWith('#') && val.length == 7) {
                                    setState(() => _themeColor = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _tryParseColor(_themeColor),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF3F3F46)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCard(
                  title: 'Relevant Contextual Imagery',
                  icon: Icons.image_search_rounded,
                  expand: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('IMAGE MOOD & INDUSTRY FOCUS'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _imageThemes.map((theme) {
                            final isSelected = _imageTheme == theme;
                            return ChoiceChip(
                              label: Text(theme),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _imageTheme = theme),
                              selectedColor:
                                  const Color(0xFFA78BFA).withOpacity(0.2),
                              backgroundColor: const Color(0xFF18181B),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFFA1A1AA),
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFF27272A),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Images are dynamically curated via high-resolution Unsplash CDNs tailored strictly to your site topic and page narratives.',
                          style: TextStyle(
                            color: Color(0xFF71717A),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Summary & Final Launch
        Expanded(
          flex: 6,
          child: _buildCard(
            title: 'Review Forging Parameters & Launch',
            icon: Icons.rocket_launch_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(
                    'Site Name', _projectNameController.text.trim()),
                _buildSummaryRow('Category', _selectedCategory),
                _buildSummaryRow(
                    'Selected Pages', _selectedPageIds.join(', ')),
                _buildSummaryRow('Template', _selectedTemplateId.toUpperCase()),
                _buildSummaryRow('Primary Color', _themeColor),
                _buildSummaryRow('Image Mood', _imageTheme),
                const SizedBox(height: 16),
                _buildLabel('AI ENGINE CONFIGURATION'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildAiOption('Nvidia', 'Nemotron Ultra'),
                    const SizedBox(width: 8),
                    _buildAiOption('Gemini', 'Gemini 1.5 Pro'),
                    const SizedBox(width: 8),
                    _buildAiOption('OpenRouter', 'OpenRouter API'),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your customized copy and selected pre-built template are ready. Clicking below initiates compilation into a complete multi-page web application.',
                          style: TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLaunchButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiOption(String id, String label) {
    final isSelected = _aiModel == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _aiModel = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFA78BFA).withOpacity(0.15)
                : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFA78BFA)
                  : const Color(0xFF27272A),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFA78BFA)
                    : const Color(0xFFA1A1AA),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF71717A),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: Color(0xFFFAFAFA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _generateApplication,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? const Color(0xFF7C3AED) : const Color(0xFFA78BFA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA78BFA).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.rocket_launch, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _isLoading ? 'FORGING COMPLETE SITE...' : 'Launch Project & Forge Site',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Action Bar (Prev / Next) ---
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0F),
        border: Border(top: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA1A1AA),
                side: const BorderSide(color: Color(0xFF3F3F46)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          const Spacer(),
          if (_currentStep < 3)
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: Text(
                _currentStep == 0
                    ? 'Next: Enter Page Content ➔'
                    : _currentStep == 1
                        ? 'Next: Select Template ➔'
                        : 'Next: Styling & Launch ➔',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA78BFA),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // --- Helper Card & Form Builders ---
  /// [expand] controls whether the card's content uses Expanded (requires
  /// the card itself to be inside a bounded-height parent, e.g. an Expanded
  /// in a Row/Column with CrossAxisAlignment.stretch).
  /// Set expand=false when the card is inside a SingleChildScrollView or
  /// when the content sizes itself (form fields, Wrap chips, etc.).
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool expand = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFA78BFA), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA1A1AA),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFFFAFAFA),
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF52525B),
          fontSize: 12,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF71717A), size: 16)
            : null,
        filled: true,
        fillColor: const Color(0xFF18181B),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFA78BFA)),
        ),
      ),
    );
  }

  Color _tryParseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse('0xFF$clean'));
    } catch (_) {
      return const Color(0xFFA78BFA);
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF27272A), width: 1)),
      ),
      child: const Row(
        children: [
          Text(
            '© FORGE AI. ZERO DUMMY DATA ENGINE.',
            style: TextStyle(color: Color(0xFF52525B), fontSize: 10),
          ),
          Spacer(),
          Text(
            'VERSION 2.4.0 — PRODUCTION WORKFLOW',
            style: TextStyle(color: Color(0xFF52525B), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
