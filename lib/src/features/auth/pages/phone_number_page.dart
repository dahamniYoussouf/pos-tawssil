import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/auth/cubit/auth_state.dart';
import '../cubit/auth_cubit.dart';
import 'verification_page.dart';

/// Phone Number Authentication Page
/// Matches the Tawsil design with green branding
class PhoneNumberPage extends StatelessWidget {
  const PhoneNumberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: const PhoneNumberView(),
    );
  }
}

class PhoneNumberView extends StatefulWidget {
  const PhoneNumberView({Key? key}) : super(key: key);

  @override
  State<PhoneNumberView> createState() => _PhoneNumberViewState();
}

class _PhoneNumberViewState extends State<PhoneNumberView> {
  final TextEditingController _phoneController = TextEditingController();

  // Country code - default to Algeria
  String _countryCode = '+213';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final phone = _phoneController.text.trim();
    context.read<AuthCubit>().sendVerificationCode(phone, _countryCode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthCodeSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(
                phoneNumber: state.phoneNumber,
                countryCode: _countryCode,
                verificationId: state.verificationId,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError ? state.message : '';

        return Scaffold(
          backgroundColor: const Color(0xFF006C4A), // Tawsil green
          body: SafeArea(
            child: Column(
              children: [
                // Top section with logo
                Expanded(
                  flex: 35,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF006C4A),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tawsil logo image
                        Image.asset(
                          'assets/icons/tawwsil.png',
                          width: 200,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom white card section
                Expanded(
                  flex: 65,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            AppLocalizations.of(context)!.addPhoneNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            AppLocalizations.of(context)!.phoneNumberSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C757D),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Phone input field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: errorMessage.isNotEmpty ? Colors.red : const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Country flag and code
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Color(0xFFD1D5DB),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Algeria flag emoji
                                      const Text(
                                        '🇩🇿',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Color(0xFF6B7280),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _countryCode,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Phone number input
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.phoneNumberHint,
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      if (!isLoading) {
                                        _handleConnect();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error message
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 25),

                          // Connect button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleConnect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF006C4A),
                                disabledBackgroundColor: const Color(0xFF006C4A).withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.connect,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
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
        );
      },
    );
  }
}
