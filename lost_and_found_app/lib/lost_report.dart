import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lost_and_found_app/upload_pic.dart';

const Color _blue = Color(0xFF2563EB);
const Color _lightBlue = Color(0xFFEFF6FF);
const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _border = Color(0xFFE5E7EB);
const Color _canvas = Color(0xFFF5F7FA);
const Color _success = Color(0xFF16A34A);

const int _maxPhotoBytes = 5 * 1024 * 1024;
const List<String> _allowedPhotoExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'webp',
];

class LostReport {
  final String id;
  final String ownerEmail;
  final String title;
  final String description;
  final String category;
  final DateTime dateLost;
  final String location;
  final String status;
  final DateTime createdAt;
  final Uint8List? photoBytes;
  final String? photoName;

  const LostReport({
    required this.id,
    required this.ownerEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.dateLost,
    required this.location,
    required this.status,
    required this.createdAt,
    this.photoBytes,
    this.photoName,
  });
}

class LostReportSession {
  static String? _email;

  static String? get email => _email;

  static void signIn(String email) => _email = email.trim().toLowerCase();

  static void signOut() => _email = null;
}

class LostReportRepository {
  static final List<LostReport> _reports = <LostReport>[];

  static List<LostReport> reportsFor(String ownerEmail) {
    final key = ownerEmail.trim().toLowerCase();
    return List<LostReport>.unmodifiable(
      _reports.where((report) => report.ownerEmail == key),
    );
  }

  static LostReport add({
    required String ownerEmail,
    required String title,
    required String description,
    required String category,
    required DateTime dateLost,
    required String location,
    Uint8List? photoBytes,
    String? photoName,
  }) {
    final report = LostReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ownerEmail: ownerEmail.trim().toLowerCase(),
      title: title.trim(),
      description: description.trim(),
      category: category,
      dateLost: DateTime(dateLost.year, dateLost.month, dateLost.day),
      location: location.trim(),
      status: 'Open',
      createdAt: DateTime.now(),
      photoBytes: photoBytes,
      photoName: photoName,
    );
    _reports.add(report);
    return report;
  }

  static void seedDemoReports(String ownerEmail) {
    if (reportsFor(ownerEmail).isNotEmpty) return;
    final now = DateTime.now();
    add(
      ownerEmail: ownerEmail,
      title: 'Black Wallet',
      description: 'Leather wallet with my student card inside.',
      category: 'Other',
      dateLost: now.subtract(const Duration(days: 2)),
      location: 'Library, Level 2',
    );
    add(
      ownerEmail: ownerEmail,
      title: 'Student ID Card',
      description: 'Name card lost near the student union.',
      category: 'ID / Cards',
      dateLost: now.subtract(const Duration(days: 5)),
      location: 'Student Union',
    );
  }

  static void clear() => _reports.clear();
}

class _CategoryOption {
  const _CategoryOption({
    required this.value,
    required this.label,
    required this.examples,
    required this.icon,
  });

  final String value;
  final String label;
  final String examples;
  final IconData icon;
}

const List<_CategoryOption> _categoryOptions = <_CategoryOption>[
  _CategoryOption(
    value: 'Electronics',
    label: 'Electronics',
    examples: 'Laptops · Phones · Tablets',
    icon: Icons.laptop_mac,
  ),
  _CategoryOption(
    value: 'Keys & Fobs',
    label: 'Keys & Fobs',
    examples: 'Dorm · Car · Locker',
    icon: Icons.vpn_key,
  ),
  _CategoryOption(
    value: 'Clothing',
    label: 'Clothing',
    examples: 'Jackets · Hoodies · Gym items',
    icon: Icons.checkroom,
  ),
  _CategoryOption(
    value: 'ID / Cards',
    label: 'ID / Cards',
    examples: 'Student passes · Transit cards',
    icon: Icons.credit_card,
  ),
  _CategoryOption(
    value: 'Accessories',
    label: 'Accessories',
    examples: 'Watches · Glasses · Rings',
    icon: Icons.watch,
  ),
  _CategoryOption(
    value: 'Bags',
    label: 'Bags',
    examples: 'Backpacks · Purses · Totes',
    icon: Icons.backpack,
  ),
  _CategoryOption(
    value: 'Audio Gear',
    label: 'Audio Gear',
    examples: 'AirPods · Headphones',
    icon: Icons.headphones,
  ),
  _CategoryOption(
    value: 'Other',
    label: 'Other',
    examples: 'Books · Water bottles',
    icon: Icons.more_horiz,
  ),
];

const List<String> lostReportCategories = <String>[
  'Electronics',
  'Keys & Fobs',
  'Clothing',
  'ID / Cards',
  'Accessories',
  'Bags',
  'Audio Gear',
  'Other',
];

const List<String> _dominantColors = <String>[
  'Space Gray / Slate',
  'Black',
  'Silver',
  'Blue',
  'Red',
  'White',
  'Other',
];

const List<String> _headerMenuItems = <String>[
  'Browse Items',
  'Report Item',
  'My Claims',
];

String? validatePhoto(String name, int sizeBytes) {
  final extension = name.split('.').last.toLowerCase();
  if (!_allowedPhotoExtensions.contains(extension)) {
    return 'Only JPG, PNG or WEBP images are accepted.';
  }
  if (sizeBytes > _maxPhotoBytes) {
    return 'Photo must be 5 MB or smaller.';
  }
  return null;
}

String formatReportDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

InputDecoration _fieldDecoration(
  String label, {
  String? hint,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _border),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
  );
}

class CampusHeader extends StatelessWidget {
  const CampusHeader({
    super.key,
    required this.activeItem,
    this.onPostLostItem,
  });

  final String activeItem;
  final VoidCallback? onPostLostItem;

  @override
  Widget build(BuildContext context) {
    final email = LostReportSession.email ?? '';
    final localPart = email.split('@').first;
    final initials = localPart.isEmpty
        ? 'GU'
        : localPart
              .substring(0, localPart.length < 2 ? localPart.length : 2)
              .toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1100) {
            return Row(
              children: [
                _brand(),
                const SizedBox(width: 24),
                ..._menuItems(context),
                const Spacer(),
                SizedBox(width: 220, child: _searchField()),
                const SizedBox(width: 12),
                _notifications(context),
                const SizedBox(width: 12),
                _cta(),
                const SizedBox(width: 12),
                _avatar(initials),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _brand(),
                  const Spacer(),
                  _notifications(context),
                  const SizedBox(width: 8),
                  _cta(),
                  const SizedBox(width: 8),
                  _avatar(initials),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: _searchField()),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _menuItems(context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _brand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.search, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'CampusFind',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'CADT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _menuItems(BuildContext context) => <Widget>[
    for (final item in _headerMenuItems) _menuButton(context, item),
  ];

  Widget _menuButton(BuildContext context, String label) {
    final active = label == activeItem;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: active
            ? () {}
            : () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$label is coming soon.'))),
        style: TextButton.styleFrom(
          backgroundColor: active ? _lightBlue : Colors.transparent,
          foregroundColor: active ? _blue : _muted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search items...',
        hintStyle: const TextStyle(fontSize: 13, color: _muted),
        prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _notifications(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: _muted),
          tooltip: 'Notifications',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          ),
        ),
        const Positioned(
          right: 9,
          top: 9,
          child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _cta() {
    return FilledButton(
      onPressed: onPostLostItem ?? () {},
      style: FilledButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Post Lost Item', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _avatar(String initials) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: _lightBlue,
      child: Text(
        initials,
        style: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ReportLostPage extends StatefulWidget {
  const ReportLostPage({super.key});

  @override
  State<ReportLostPage> createState() => _ReportLostPageState();
}

class _ReportLostPageState extends State<ReportLostPage> {
  final List<GlobalKey<FormState>> _stepKeys = <GlobalKey<FormState>>[
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _category;
  String? _categoryError;
  String? _color;
  Uint8List? _photoBytes;
  String? _photoName;
  bool _confirmed = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _makeCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text.trim()) ?? today,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 1, 12, 31),
      helpText: 'Select date lost',
    );
    if (!context.mounted || picked == null) return;
    setState(() => _dateCtrl.text = formatReportDate(picked));
    _stepKeys[1].currentState?.validate();
  }

  Future<void> _openUploadPic() async {
    final uploaded = await Navigator.of(context).push<UploadedPhoto>(
      MaterialPageRoute<UploadedPhoto>(
        builder: (_) => const UploadPicPage(),
      ),
    );
    if (uploaded == null || !mounted) return;

    setState(() {
      _photoBytes = uploaded.bytes;
      _photoName = uploaded.name;
    });
  }

  void _selectCategory(String value) {
    setState(() {
      _category = value;
      _categoryError = null;
    });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved for this session.')),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      final fieldsValid = _stepKeys[0].currentState?.validate() ?? false;
      if (_category == null) {
        setState(() => _categoryError = 'Select a category');
      }
      return fieldsValid && _category != null;
    }
    if (_currentStep == 3) {
      return _stepKeys[3].currentState?.validate() ?? false;
    }
    return _stepKeys[_currentStep].currentState?.validate() ?? false;
  }

  void _next() {
    if (_currentStep == 3) {
      _submit();
      return;
    }
    if (!_validateCurrentStep()) return;
    setState(() => _currentStep++);
    _scrollCtrl.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  void _submit() {
    final email = LostReportSession.email;
    if (email == null || _category == null) return;
    if (!(_stepKeys[3].currentState?.validate() ?? false)) return;

    LostReportRepository.add(
      ownerEmail: email,
      title: _titleCtrl.text,
      description: _descriptionCtrl.text,
      category: _category!,
      dateLost: DateTime.parse(_dateCtrl.text.trim()),
      location: _locationCtrl.text,
      photoBytes: _photoBytes,
      photoName: _photoName,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lost report saved as Open.')));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const MyReportsPage()),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = LostReportSession.email != null;
    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          CampusHeader(
            activeItem: 'Report Item',
            onPostLostItem: () => _scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
          ),
          Expanded(
            child: loggedIn
                ? SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _titleSection(),
                            const SizedBox(height: 20),
                            _wizard(),
                            const SizedBox(height: 20),
                            _currentStepWidget(),
                            const SizedBox(height: 20),
                            _footer(),
                          ],
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Text('Please log in to report a lost item.'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _titleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final legend = _legend();
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _titleText()),
              const SizedBox(width: 24),
              legend,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_titleText(), const SizedBox(height: 16), legend],
        );
      },
    );
  }

  Widget _titleText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INCIDENT INTAKE',
          style: TextStyle(
            color: _blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Custody & Recovery Intake',
          style: TextStyle(
            color: _ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ticket ID: RW-2024-NEW',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(Colors.red, 'Lost an Item'),
          const SizedBox(height: 8),
          _legendRow(_success, 'Found an Item (Turn In)'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: _ink)),
      ],
    );
  }

  Widget _wizard() {
    const labels = <String>[
      'Item Details',
      'Location & Timing',
      'Proof & Photos',
      'Verification',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Row(
                children: [
                  _stepCircle(i),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP 0${i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                            color: i == _currentStep ? _blue : _muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: i == _currentStep
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i <= _currentStep ? _ink : _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < labels.length - 1)
                    Container(
                      width: 18,
                      height: 2,
                      color: i < _currentStep ? _blue : _border,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _stepCircle(int index) {
    final done = index < _currentStep;
    final active = index == _currentStep;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? _success
            : active
            ? _blue
            : const Color(0xFFF3F4F6),
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '0${index + 1}',
                style: TextStyle(
                  color: active ? Colors.white : _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _currentStepWidget() {
    switch (_currentStep) {
      case 1:
        return _locationStep();
      case 2:
        return _proofStep();
      case 3:
        return _verificationStep();
      default:
        return _itemDetailsStep();
    }
  }

  Widget _itemDetailsStep() {
    return Form(
      key: _stepKeys[0],
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Item Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the category that best matches your item.',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 4
                    : constraints.maxWidth >= 460
                    ? 3
                    : 2;
                return GridView.builder(
                  key: const Key('lost_report_category'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: _categoryOptions.length,
                  itemBuilder: (context, index) {
                    final option = _categoryOptions[index];
                    return _categoryCard(option);
                  },
                );
              },
            ),
            if (_categoryError != null) ...[
              const SizedBox(height: 8),
              Text(
                _categoryError!,
                key: const Key('lost_report_category_error'),
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: _border),
            const SizedBox(height: 20),
            const Text(
              'Item Description Form',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('lost_report_title'),
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration(
                'Describe Item Headline',
                hint: 'e.g. Silver iPad 10th Gen in dark green folio case with pencil loop',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('lost_report_description'),
              controller: _descriptionCtrl,
              maxLines: 4,
              decoration: _fieldDecoration(
                'Item Description',
                hint: 'Include brand, model, color, and distinguishing marks.',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a description'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeCtrl,
                    decoration: _fieldDecoration(
                      'Make / Brand / Label',
                      hint: 'Apple, Patagonia, Hydro Flask',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _color,
                    isExpanded: true,
                    decoration: _fieldDecoration('Dominant Color'),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Select a color'),
                      ),
                      ..._dominantColors.map(
                        (color) => DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _color = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(_CategoryOption option) {
    final selected = _category == option.value;
    return InkWell(
      key: option.value == 'Other'
          ? const Key('lost_report_category_other')
          : ValueKey<String>('lost_report_category_${option.value}'),
      onTap: () => _selectCategory(option.value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _blue : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: selected ? _blue : const Color(0xFFF3F4F6),
              child: Icon(
                option.icon,
                size: 18,
                color: selected ? Colors.white : _muted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? _blue : _ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.examples,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationStep() {
    return Form(
      key: _stepKeys[1],
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location & Timing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tell us where and when you last saw the item.',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('lost_report_location'),
              controller: _locationCtrl,
              decoration: _fieldDecoration(
                'Location',
                hint: 'Library, Level 2, near the entrance',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a location'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('lost_report_date'),
              controller: _dateCtrl,
              keyboardType: TextInputType.datetime,
              decoration: _fieldDecoration(
                'Date lost (YYYY-MM-DD)',
                hint: 'YYYY-MM-DD',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  tooltip: 'Pick date',
                  onPressed: _pickDate,
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter the date lost';
                final parsed = DateTime.tryParse(text);
                if (parsed == null) {
                  return 'Enter a valid date (YYYY-MM-DD)';
                }
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                if (DateTime(
                  parsed.year,
                  parsed.month,
                  parsed.day,
                ).isAfter(today)) {
                  return 'Date lost cannot be in the future';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _proofStep() {
    return Form(
      key: _stepKeys[2],
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proof & Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Optional, but photos make the item easier to recognize.',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  if (_photoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _photoBytes!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _photoName ?? 'Selected photo',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: _ink),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _photoBytes = null;
                            _photoName = null;
                          }),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Icon(Icons.add_photo_alternate, size: 40, color: _blue),
                    const SizedBox(height: 12),
                    const Text(
                      'Add a photo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Text(
                    'Optional · JPG, PNG or WEBP up to 5 MB',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _openUploadPic,
                    icon: const Icon(Icons.upload, size: 18),
                    label: Text(
                      _photoBytes == null ? 'Choose image' : 'Replace image',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verificationStep() {
    return Form(
      key: _stepKeys[3],
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review the details before submitting your report.',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Headline', _titleCtrl.text),
                  _summaryRow('Description', _descriptionCtrl.text),
                  _summaryRow('Category', _category ?? '-'),
                  _summaryRow('Date lost', _dateCtrl.text),
                  _summaryRow('Location', _locationCtrl.text),
                  _summaryRow('Photo', _photoName ?? '-'),
                  _summaryRow('Status', 'Open'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FormField<bool>(
              initialValue: _confirmed,
              validator: (value) =>
                  value == true ? null : 'Confirm the details are accurate',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _confirmed,
                      onChanged: (value) {
                        final checked = value ?? false;
                        setState(() => _confirmed = checked);
                        field.didChange(checked);
                      },
                      title: const Text(
                        'I confirm this information is accurate.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _saveDraft,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Save Draft'),
        ),
        const SizedBox(width: 8),
        if (_currentStep > 0) ...[
          TextButton(onPressed: _back, child: const Text('Back')),
          const SizedBox(width: 8),
        ],
        FilledButton(
          key: Key(
            _currentStep == 3 ? 'submit_report_button' : 'continue_button',
          ),
          onPressed: _next,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentStep == 3 ? 'Submit report' : 'Continue'),
              const SizedBox(width: 8),
              Icon(
                _currentStep == 3 ? Icons.check : Icons.arrow_forward,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = LostReportSession.email;
    if (email == null) {
      return Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            const CampusHeader(activeItem: 'My Claims'),
            Expanded(
              child: Center(child: Text('Please log in to view your reports.')),
            ),
          ],
        ),
      );
    }

    LostReportRepository.seedDemoReports(email);
    final reports = LostReportRepository.reportsFor(email);
    return Scaffold(
      backgroundColor: _canvas,
      body: Column(
        children: [
          CampusHeader(
            activeItem: 'My Claims',
            onPostLostItem: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ReportLostPage()),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'My reports',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track every lost item you have reported.',
                        style: TextStyle(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 20),
                      if (reports.isEmpty)
                        _emptyCard()
                      else
                        for (final report in reports) ...[
                          _reportCard(context, report),
                          const SizedBox(height: 12),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(child: Text('You have no reports yet.')),
    );
  }

  Widget _reportCard(BuildContext context, LostReport report) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ReportDetailPage(report: report),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A111827),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                Chip(
                  label: Text(report.status),
                  backgroundColor: _lightBlue,
                  labelStyle: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                Text(
                  'Category: ${report.category}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                Text(
                  'Date lost: ${formatReportDate(report.dateLost)}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                Text(
                  'Location: ${report.location}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: const TextStyle(fontSize: 13, color: _ink),
            ),
            if (report.photoBytes != null) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.photo_camera, size: 16, color: _blue),
                  SizedBox(width: 6),
                  Text(
                    'Photo attached',
                    style: TextStyle(fontSize: 12, color: _blue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.report});

  final LostReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('Report detail'),
        foregroundColor: _ink,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0A111827),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.photoBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        report.photoBytes!,
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (report.photoName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        report.photoName!,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ] else
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 40,
                          color: _muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _detailRow('Status', report.status),
                  _detailRow('Category', report.category),
                  _detailRow('Date lost', formatReportDate(report.dateLost)),
                  _detailRow('Location', report.location),
                  _detailRow('Description', report.description),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
