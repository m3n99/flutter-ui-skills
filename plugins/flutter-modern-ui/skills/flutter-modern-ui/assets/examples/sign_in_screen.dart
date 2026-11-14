// Reference composition for a sign-in page (references/screens.md › Sign in).
// Shows:
// - one column capped in width and centered, inside the safe area, that
//   scrolls: the keyboard never covers a field or the button;
// - a brand moment made from the app's signature (ledger lines) and one line
//   saying what the app is for, instead of a gradient or a stock picture;
// - email and password with the right keyboards, autofill hints in an
//   AutofillGroup, Next / Done actions and a show-password button;
// - one primary action; the lesser paths as text buttons after it;
// - a failed attempt reported inside the form, next to the button, in words
//   that say what to do, with both fields keeping what was typed and the
//   button giving a short shake;
// - a button that can't be pressed twice (SubmitButton).
//
// Presentation only: `onSignIn` is the project's auth call.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';

/// A failed sign-in, with a message written for the user: what went wrong
/// and what to do. Thrown by [SignInScreen.onSignIn].
class SignInFailure implements Exception {
  const SignInFailure(this.message);

  final String message;
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onCreateAccount,
    this.initialEmail,
    this.initialError,
  });

  /// The project's auth call. Throw a [SignInFailure] to tell the user why
  /// it failed; any other error shows a connection message.
  final Future<void> Function(String email, String password) onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;

  /// The last account used on this device, so there's less to type.
  final String? initialEmail;

  /// Renders the failed state (previews, UI tests).
  final String? initialError;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.initialEmail);
  final TextEditingController _password = TextEditingController();

  late String? _error = widget.initialError;
  bool _obscure = true;
  bool _submitted = false;
  int _failures = 0;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _failures++);
      return;
    }
    try {
      await widget.onSignIn(_email.text.trim(), _password.text);
      // Lets the password manager offer to save what just worked.
      TextInput.finishAutofillContext();
    } on SignInFailure catch (failure) {
      _fail(failure.message);
    } catch (_) {
      _fail("Couldn't reach the server. Check your connection and try again.");
    }
  }

  /// The fields keep what was typed; the message says what to do next.
  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _failures++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final muted = text.bodyMedium?.copyWith(color: colors.onSurfaceVariant);
    final error = _error;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSize.columnMaxWidth),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: AlignmentDirectional.centerStart, child: _LedgerMark()),
                      const SizedBox(height: AppSpace.md),
                      Text('Daybook', style: text.headlineMedium),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        'Your invoices, and who still owes you.',
                        style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      _Labeled(
                        label: 'Email',
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          textDirection: TextDirection.ltr,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(hintText: 'name@example.com'),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            return email.contains('@') && email.contains('.')
                                ? null
                                : 'Enter an email like name@example.com.';
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      _Labeled(
                        label: 'Password',
                        child: TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _signIn(),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(onPressed: widget.onForgotPassword, child: const Text('Forgot password?')),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        _FormError(message: error),
                      ],
                      const SizedBox(height: AppSpace.md),
                      ShakeOnChange(
                        trigger: _failures,
                        child: SubmitButton(label: 'Sign in', onPressed: _signIn),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpace.xxs,
                        children: [
                          Text('New to Daybook?', style: muted),
                          TextButton(onPressed: widget.onCreateAccount, child: const Text('Create an account')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        Text(label, style: context.textStyles.titleSmall),
        child,
      ],
    );
  }
}

/// Why the attempt failed, where the user is looking: an icon and the error
/// color, announced to screen readers. Not a SnackBar that disappears.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.error;

    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.xs,
        children: [
          Icon(Icons.error_outline_rounded, size: context.iconSize(AppIconSize.dense), color: color),
          Expanded(child: Text(message, style: context.textStyles.bodyMedium?.copyWith(color: color))),
        ],
      ),
    );
  }
}

/// The brand mark: three ledger lines, the last one the total. The app's
/// signature (dashboard_screen.dart) in its smallest form.
class _LedgerMark extends StatelessWidget {
  const _LedgerMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppIconSize.hero,
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.primary, borderRadius: AppRadius.controlAll),
          child: CustomPaint(painter: _LedgerMarkPainter(colors.onPrimary)),
        ),
      ),
    );
  }
}

class _LedgerMarkPainter extends CustomPainter {
  const _LedgerMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width / 16;
    final total = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width / 8;
    final start = size.width * 0.28;
    final end = size.width * 0.72;

    canvas.drawLine(Offset(start, size.height * 0.32), Offset(end, size.height * 0.32), line);
    canvas.drawLine(Offset(start, size.height * 0.48), Offset(end, size.height * 0.48), line);
    // The total: heavier, and only as wide as the amounts column.
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.68), Offset(end, size.height * 0.68), total);
  }

  @override
  bool shouldRepaint(_LedgerMarkPainter oldDelegate) => oldDelegate.color != color;
}
