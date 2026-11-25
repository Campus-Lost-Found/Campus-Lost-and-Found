import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';

const Color _blue = Color(0xFF2563EB);
const Color _lightBlue = Color(0xFFEFF6FF);
const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _border = Color(0xFFE5E7EB);
const Color _canvas = Color(0xFFF5F7FA);
const Color _success = Color(0xFF16A34A);

class LostReport {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final String title;
  final String description;
  final String category;
  final DateTime dateLost;
  final String location;
  final String status;
  final DateTime createdAt;

  const LostReport({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.dateLost,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory LostReport.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return LostReport(
      id: snapshot.id,
      ownerId: data['ownerId'] as String,
      ownerEmail: data['ownerEmail'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: data['category'] as String,
      dateLost: (data['dateLost'] as Timestamp).toDate(),
      location: data['location'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class LostReportSession {
  static String? _email;

  static String? get email => _email;

  static void signIn(String email) => _email = email.trim().toLowerCase();

  static void signOut() => _email = null;
}

class LostReportRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<LostReport>> reportsFor(String ownerId) async {
    final snapshot = await _firestore
        .collection('reports')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs.map(LostReport.fromSnapshot).toList(growable: false);
  }

  static Future<List<LostReport>> allForStaffReview() async {
    AuthService.requireStaff();
    final snapshot = await _firestore.collection('reports').get();
    return snapshot.docs.map(LostReport.fromSnapshot).toList(growable: false);
  }

  static Future<void> review(String reportId, String status) async {
    AuthService.requireStaff();
    const allowedStatuses = {'Open', 'Under Review', 'Resolved', 'Rejected'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported report status');
    }
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
    });
  }

  static Future<LostReport> add({
    required String title,
    required String description,
    required String category,
    required DateTime dateLost,
    required String location,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw const AccessDeniedException();
    final now = DateTime.now();
    final reference = _firestore.collection('reports').doc();
    final report = LostReport(
      id: reference.id,
      ownerId: user.id,
      ownerEmail: user.email,
      title: title.trim(),
      description: description.trim(),
      category: category,
      dateLost: DateTime(dateLost.year, dateLost.month, dateLost.day),
      location: location.trim(),
      status: 'Open',
      createdAt: now,
    );
    await reference.set({
      'ownerId': report.ownerId,
      'ownerEmail': report.ownerEmail,
      'title': report.title,
      'description': report.description,
      'category': report.category,
      'dateLost': Timestamp.fromDate(report.dateLost),
      'location': report.location,
      'status': report.status,
      'createdAt': Timestamp.fromDate(now),
    });
    return report;
  }
}

class LostReportClaim {
  final String id;
  final String claimantId;
  final String reportId;
  final String claimantEmail;
  final String details;
  final String status;
  final DateTime createdAt;

  const LostReportClaim({
    required this.id,
    required this.claimantId,
    required this.reportId,
    required this.claimantEmail,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  factory LostReportClaim.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return LostReportClaim(
      id: snapshot.id,
      claimantId: data['claimantId'] as String,
      reportId: data['reportId'] as String,
      claimantEmail: data['claimantEmail'] as String,
      details: data['details'] as String,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class LostReportClaimRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<LostReportClaim> submit({
    required String reportId,
    required String details,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw const AccessDeniedException();
    final reference = _firestore.collection('claims').doc();
    final createdAt = DateTime.now();
    final claim = LostReportClaim(
      id: reference.id,
      claimantId: user.id,
      reportId: reportId,
      claimantEmail: user.email,
      details: details.trim(),
      status: 'Pending',
      createdAt: createdAt,
    );
    await reference.set({
      'claimantId': claim.claimantId,
      'claimantEmail': claim.claimantEmail,
      'reportId': claim.reportId,
      'details': claim.details,
      'status': claim.status,
      'createdAt': Timestamp.fromDate(createdAt),
    });
    return claim;
  }

  static Future<List<LostReportClaim>> allForStaffReview() async {
    AuthService.requireStaff();
    final snapshot = await _firestore.collection('claims').get();
    return snapshot.docs
        .map(LostReportClaim.fromSnapshot)
        .toList(growable: false);
  }

  static Future<void> review(String claimId, String status) async {
    AuthService.requireStaff();
    const allowedStatuses = {'Pending', 'Approved', 'Rejected'};
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported claim status');
    }
    await _firestore.collection('claims').doc(claimId).update({
      'status': status,
    });
  }
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

  Future<void> _next() async {
    if (_currentStep == 3) {
      await _submit();
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

  Future<void> _submit() async {
    final email = LostReportSession.email;
    if (email == null || _category == null) return;
    if (!(_stepKeys[3].currentState?.validate() ?? false)) return;

    try {
      await LostReportRepository.add(
        title: _titleCtrl.text,
        description: _descriptionCtrl.text,
        category: _category!,
        dateLost: DateTime.parse(_dateCtrl.text.trim()),
        location: _locationCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lost report saved as Open.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => const MyReportsPage()),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save report: ${error.message}')),
        );
      }
    } on AccessDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Access denied')));
      }
    }
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
              'Optional for now, but photos help the match engine verify ownership.',
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
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
                  const SizedBox(height: 4),
                  const Text(
                    'Photo upload can be enabled in the next release.',
                    style: TextStyle(fontSize: 12, color: _muted),
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

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access denied')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 52, color: Color(0xFF9CA3AF)),
            SizedBox(height: 12),
            Text(
              'Access denied',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text('Your account does not have permission to view this page.'),
          ],
        ),
      ),
    ),
  );
}

class StaffReviewPage extends StatefulWidget {
  const StaffReviewPage({super.key});

  @override
  State<StaffReviewPage> createState() => _StaffReviewPageState();
}

class _StaffReviewPageState extends State<StaffReviewPage> {
  late Future<_ReviewQueues> _queues;

  @override
  void initState() {
    super.initState();
    _queues = AuthService.canReview
        ? _loadQueues()
        : Future.value(const _ReviewQueues([], []));
  }

  Future<_ReviewQueues> _loadQueues() async {
    final reports = await LostReportRepository.allForStaffReview();
    final claims = await LostReportClaimRepository.allForStaffReview();
    return _ReviewQueues(reports, claims);
  }

  Future<void> _updateReport(String id, String status) async {
    try {
      await LostReportRepository.review(id, status);
      if (mounted) setState(() => _queues = _loadQueues());
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'permission-denied'
                  ? 'Access denied'
                  : 'Could not update report: ${error.message}',
            ),
          ),
        );
      }
    } on AccessDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Access denied')));
      }
    }
  }

  Future<void> _updateClaim(String id, String status) async {
    try {
      await LostReportClaimRepository.review(id, status);
      if (mounted) setState(() => _queues = _loadQueues());
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'permission-denied'
                  ? 'Access denied'
                  : 'Could not update claim: ${error.message}',
            ),
          ),
        );
      }
    } on AccessDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Access denied')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.canReview) return const AccessDeniedPage();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff review'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reports'),
              Tab(text: 'Claims'),
            ],
          ),
        ),
        body: FutureBuilder<_ReviewQueues>(
          future: _queues,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              if (snapshot.error is FirebaseException &&
                  (snapshot.error as FirebaseException).code ==
                      'permission-denied') {
                return const AccessDeniedPage();
              }
              return Center(
                child: Text('Could not load review queue: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final reports = snapshot.data!.reports;
            final claims = snapshot.data!.claims;
            return TabBarView(
              children: [
                reports.isEmpty
                    ? const _EmptyReviewQueue(label: 'No reports to review.')
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final report in reports)
                            Card(
                              child: ListTile(
                                title: Text(report.title),
                                subtitle: Text(
                                  '${report.category} · ${report.location}\n'
                                  '${report.description}\n'
                                  'Reported by ${report.ownerEmail}',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Update review status',
                                  onSelected: (status) =>
                                      _updateReport(report.id, status),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'Under Review',
                                      child: Text('Under review'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Resolved',
                                      child: Text('Resolve'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Rejected',
                                      child: Text('Reject'),
                                    ),
                                  ],
                                  child: Chip(label: Text(report.status)),
                                ),
                              ),
                            ),
                        ],
                      ),
                claims.isEmpty
                    ? const _EmptyReviewQueue(label: 'No claims to review.')
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final claim in claims)
                            Card(
                              child: ListTile(
                                title: Text(
                                  'Claim for report ${claim.reportId}',
                                ),
                                subtitle: Text(
                                  '${claim.details}\n'
                                  'Submitted by ${claim.claimantEmail}',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Update claim status',
                                  onSelected: (status) =>
                                      _updateClaim(claim.id, status),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'Approved',
                                      child: Text('Approve'),
                                    ),
                                    PopupMenuItem(
                                      value: 'Rejected',
                                      child: Text('Reject'),
                                    ),
                                  ],
                                  child: Chip(label: Text(claim.status)),
                                ),
                              ),
                            ),
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewQueues {
  const _ReviewQueues(this.reports, this.claims);

  final List<LostReport> reports;
  final List<LostReportClaim> claims;
}

class _EmptyReviewQueue extends StatelessWidget {
  const _EmptyReviewQueue({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(label, style: const TextStyle(color: Colors.grey)),
  );
}

class RoleManagementPage extends StatefulWidget {
  const RoleManagementPage({super.key});

  @override
  State<RoleManagementPage> createState() => _RoleManagementPageState();
}

class _RoleManagementPageState extends State<RoleManagementPage> {
  late Future<List<UserRecord>> _users;

  @override
  void initState() {
    super.initState();
    _users = AuthService.canManageRoles
        ? AuthService.allUsers()
        : Future.value(const <UserRecord>[]);
  }

  Future<void> _updateRole(String userId, UserRole role) async {
    try {
      await AuthService.updateRole(userId, role);
      if (mounted) setState(() => _users = AuthService.allUsers());
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.code == 'permission-denied'
                  ? 'Access denied'
                  : 'Could not update role: ${error.message}',
            ),
          ),
        );
      }
    } on AccessDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Access denied')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.canManageRoles) return const AccessDeniedPage();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage user roles')),
      body: FutureBuilder<List<UserRecord>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (snapshot.error is FirebaseException &&
                (snapshot.error as FirebaseException).code ==
                    'permission-denied') {
              return const AccessDeniedPage();
            }
            return Center(
              child: Text('Could not load users: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No registered users.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: DropdownButton<UserRole>(
                    value: user.role,
                    onChanged: (role) {
                      if (role != null) _updateRole(user.id, role);
                    },
                    items: [
                      for (final role in UserRole.values)
                        DropdownMenuItem(value: role, child: Text(role.label)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late Future<List<LostReport>> _reports;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _reports = user == null
        ? Future.value(const <LostReport>[])
        : LostReportRepository.reportsFor(user.id);
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.currentUser == null || LostReportSession.email == null) {
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
            child: FutureBuilder<List<LostReport>>(
              future: _reports,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load reports: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data!;
                return SingleChildScrollView(
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
                          if (AuthService.canReview ||
                              AuthService.canManageRoles) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (AuthService.canReview)
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => const StaffReviewPage(),
                                      ),
                                    ),
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text(
                                      'Review reports & claims',
                                    ),
                                  ),
                                if (AuthService.canManageRoles)
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const RoleManagementPage(),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                    ),
                                    label: const Text('Manage user roles'),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (reports.isEmpty)
                            _emptyCard()
                          else
                            for (final report in reports) ...[
                              _reportCard(report),
                              const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
                  ),
                );
              },
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

  Widget _reportCard(LostReport report) {
    return Container(
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
        ],
      ),
    );
  }
}
