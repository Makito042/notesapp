import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:formz/formz.dart';
import 'package:notes_app/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:notes_app/features/auth/presentation/cubit/signup/signup_state.dart';
import 'package:notes_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes_app/features/auth/data/repositories/auth_repository_impl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  late final SignupCubit _signupCubit;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepositoryImpl();
    _signupCubit = SignupCubit(_authRepository);
    
    // Initialize form fields in the cubit
    _nameController.addListener(() {
      _signupCubit.nameChanged(_nameController.text);
    });
    _emailController.addListener(() {
      _signupCubit.emailChanged(_emailController.text);
    });
    _passwordController.addListener(() {
      _signupCubit.passwordChanged(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _signupCubit.confirmPasswordChanged(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _signupCubit.close();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _onTermsChanged(bool? value) {
    if (value != null) {
      setState(() {
        _termsAccepted = value;
      });
      _signupCubit.termsChanged(value);
    }
  }

  void _onSignUp() {
    // Trigger validation for all fields first
    _signupCubit.nameChanged(_nameController.text);
    _signupCubit.emailChanged(_emailController.text);
    _signupCubit.passwordChanged(_passwordController.text);
    _signupCubit.confirmPasswordChanged(_confirmPasswordController.text);
    _signupCubit.termsChanged(_termsAccepted);
    
    // If form is valid, proceed with signup
    if (_formKey.currentState?.validate() ?? false) {
      _signupCubit.signup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _signupCubit,
      child: BlocConsumer<SignupCubit, SignupState>(
        listener: (context, state) {
          if (state.status == FormzSubmissionStatus.success) {
            Navigator.pushReplacementNamed(context, '/home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.status == FormzSubmissionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'An error occurred'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.blue, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
            title: Text(
              'Create Account',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Icon(
                                Icons.note_alt_rounded,
                                size: 100,
                                color: Colors.blue.shade700,
                              ).animate().fadeIn(duration: 300.ms),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                'Create Your Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 100.ms),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Fill in the details to create your account',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Name Field
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                'Full Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Email Field
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
                              child: Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            BlocBuilder<SignupCubit, SignupState>(
                              buildWhen: (previous, current) => previous.email != current.email,
                              builder: (context, state) {
                                return TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your email',
                                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                                    errorText: state.email.invalid ? state.email.error : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  onChanged: (value) => _signupCubit.emailChanged(value),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Password Field
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
                              child: Text(
                                'Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            BlocBuilder<SignupCubit, SignupState>(
                              buildWhen: (previous, current) => previous.password != current.password,
                              builder: (context, state) {
                                return TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    errorText: state.password.invalid ? state.password.error : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  onChanged: (value) => _signupCubit.passwordChanged(value),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Confirm Password Field
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
                              child: Text(
                                'Confirm Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            BlocBuilder<SignupCubit, SignupState>(
                              buildWhen: (previous, current) => 
                                  previous.password != current.password || 
                                  previous.confirmPassword != current.confirmPassword,
                              builder: (context, state) {
                                return TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm your password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: _toggleConfirmPasswordVisibility,
                                    ),
                                    errorText: state.confirmPassword.invalid ? state.confirmPassword.error : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  onChanged: (value) => _signupCubit.confirmPasswordChanged(value),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Terms and Conditions
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 16),
                              padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -2),
                            child: Checkbox(
                              value: _termsAccepted,
                              onChanged: _onTermsChanged,
                              activeColor: Colors.blue.shade700,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'By creating an account, you agree to our ',
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // TODO: Navigate to terms of service
                                      },
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: GoogleFonts.poppins(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // TODO: Navigate to privacy policy
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                            const SizedBox(height: 16),
                            
                            // Sign Up Button
                            BlocBuilder<SignupCubit, SignupState>(
                              builder: (context, state) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: (state.status == FormzSubmissionStatus.inProgress || !_termsAccepted || !state.isValid)
                                        ? null
                                        : _onSignUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      disabledBackgroundColor: Colors.blue.withAlpha(128), // 0.5 opacity equivalent
                                    ),
                                    child: state.status == FormzSubmissionStatus.inProgress
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            'Create Account',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            
                            // Already have an account? Login
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Login',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.pushReplacementNamed(context, '/login');
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
