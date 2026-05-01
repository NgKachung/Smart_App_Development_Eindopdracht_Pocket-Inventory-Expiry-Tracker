import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorText;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorText = 'All fields are required.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorText = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthService().registerWithEmailPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Centered form content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Create Account',
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          )),
                      const SizedBox(height: 8),
                      Text('Enter your details below',
                          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                      const SizedBox(height: 30),

                      // Email
                      CupertinoTextField(
                        controller: _emailController,
                        placeholder: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
                        placeholderStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBackground : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : CupertinoColors.systemGrey4),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Password
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          CupertinoTextField(
                            controller: _passwordController,
                            placeholder: 'Password',
                            obscureText: _obscurePassword,
                            autocorrect: false,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
                            placeholderStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBackground : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : CupertinoColors.systemGrey4),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.only(right: 8),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Confirm Password
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          CupertinoTextField(
                            controller: _confirmPasswordController,
                            placeholder: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            autocorrect: false,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
                            placeholderStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBackground : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.darkBorder : CupertinoColors.systemGrey4),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.only(right: 8),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            child: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: CupertinoColors.systemGrey,
                              size: 20,
                            ),
                          )
                        ],
                      ),

                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Signup button
                      GestureDetector(
                        onTap: _isLoading ? null : _register,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? theme.primaryColor.withValues(alpha: 0.65)
                                : theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                : const Text('SIGN UP',
                                    style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Login link at bottom
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: SizedBox(
                width: w,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: CupertinoColors.systemGrey),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: theme.primaryColor, 
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
