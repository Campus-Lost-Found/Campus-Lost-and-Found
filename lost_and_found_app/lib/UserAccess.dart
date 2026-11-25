import 'package:material_ui/material_ui.dart';

import 'auth_service.dart';
import 'lost_report.dart';

// ---------------------------------------------------------------------------
// Login page
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final user = await AuthService.login(_emailCtrl.text, _passwordCtrl.text);
      if (user == null) {
        final needsSetup = await AuthService.needsStaffPasswordSetup(
          _emailCtrl.text,
        );
        if (mounted) {
          setState(
            () => _error = needsSetup
                ? 'Set up this preconfigured staff account using "Create an account".'
                : 'Invalid email or password. Please try again.',
          );
        }
        return;
      }
      LostReportSession.signIn(user.email);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyReportsPage()),
      );
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 11, child: _WelcomePanel()),
                Expanded(
                  flex: 9,
                  child: _LoginFormPanel(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    error: _error,
                    obscurePassword: _obscurePassword,
                    rememberMe: _rememberMe,
                    onObscureChanged: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onRememberChanged: (value) =>
                        setState(() => _rememberMe = value),
                    onSubmit: _submit,
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _LoginFormPanel(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      error: _error,
                      obscurePassword: _obscurePassword,
                      rememberMe: _rememberMe,
                      onObscureChanged: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onRememberChanged: (value) =>
                          setState(() => _rememberMe = value),
                      onSubmit: _submit,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF122F5C), Color(0xFF1D4E89)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 44, 64, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1D4E89)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CampusFind',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Lost something?\nFound something?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Our campus community is here to help reunite items\nwith their owners.',
                style: TextStyle(
                  color: Color(0xFFDDE8F5),
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _FeatureChip(
                    icon: Icons.verified_outlined,
                    label: 'Verified users',
                  ),
                  _FeatureChip(
                    icon: Icons.notifications_none,
                    label: 'Instant alerts',
                  ),
                  _FeatureChip(
                    icon: Icons.security_outlined,
                    label: 'Safe handoffs',
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                '© 2026 CADT Campus Lost & Found',
                style: TextStyle(color: Color(0xFFBED0E6), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.error,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onObscureChanged,
    required this.onRememberChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String? error;
  final bool obscurePassword;
  final bool rememberMe;
  final VoidCallback onObscureChanged;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        return Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: EdgeInsets.fromLTRB(
            compact ? 22 : 44,
            compact ? 28 : 40,
            compact ? 22 : 44,
            compact ? 24 : 36,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D111827),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue to CampusFind',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Campus Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _authFieldDecoration(
                    hint: 'name@gmail.com',
                    icon: Icons.mail_outline,
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Enter your campus email';
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  decoration:
                      _authFieldDecoration(
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: onObscureChanged,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: rememberMe,
                        onChanged: (value) => onRememberChanged(value ?? false),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember me',
                      style: TextStyle(color: Color(0xFF4B5563)),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password recovery is available after account setup.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4E89),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'New to CampusFind? ',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

InputDecoration _authFieldDecoration({
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
    filled: true,
    fillColor: const Color(0xFFFBFCFE),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: Color(0xFF1D4E89), width: 1.5),
    ),
  );
}

// ---------------------------------------------------------------------------
// Register page
// ---------------------------------------------------------------------------

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final error = await AuthService.register(
        _nameCtrl.text,
        _emailCtrl.text,
        _passwordCtrl.text,
      );
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! You can now log in.')),
      );
      Navigator.pop(context);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('CampusFind'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EAF0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D111827),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Students can register; preconfigured staff can set up their password here.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: _authFieldDecoration(
                        hint: 'Full name',
                        icon: Icons.person_outline,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      decoration: _authFieldDecoration(
                        hint: 'you@cadt.edu.kh',
                        icon: Icons.mail_outline,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your campus email';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    if (AuthService.isPreconfiguredStaffEmail(
                      _emailCtrl.text,
                    )) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Staff access is assigned to this email. First-time users can create a password here.',
                        style: TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: _authFieldDecoration(
                        hint: 'Password (min 6 characters)',
                        icon: Icons.lock_outline,
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: _authFieldDecoration(
                        hint: 'Confirm password',
                        icon: Icons.lock_reset,
                      ),
                      validator: (v) => v != _passwordCtrl.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFBE123C)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4E89),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'Create account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home page (only reachable after a successful login)
// ---------------------------------------------------------------------------

class HomePage extends StatelessWidget {
  final UserRecord user;
  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Lost and Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await AuthService.signOut();
              LostReportSession.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              'Welcome, ${user.name}!',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(user.email),
          ],
        ),
      ),
    );
  }
}
