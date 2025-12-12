import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/home/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/extensions/app_localizations_extension.dart';
import 'package:client_app/src/features/auth/cubit/auth_state.dart';
import '../cubit/auth_cubit.dart';
import 'user_info_page.dart';
import '../../locations/pages/location_page.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Verification Page for OTP code entry
class VerificationPage extends StatefulWidget {
  final String phoneNumber;
  const VerificationPage({required this.phoneNumber});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any previous error state and ensure timer is running when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>()
        ..inistResendTimer()
        ..ensureResendTimer();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Normalizes phone number by removing leading 0 after country code
  /// For Algeria (+213), removes leading 0 from phone number
  String _normalizePhoneNumber(String phoneNumber, String countryCode) {
    if (countryCode == '+213' &&
        phoneNumber.isNotEmpty &&
        phoneNumber.startsWith('0')) {
      return phoneNumber.substring(1);
    }
    return phoneNumber;
  }

  /// Formats phone number for API (country code + phone number, no +)
  String _formatPhoneForApi(String phoneNumber, String countryCode) {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber, countryCode);
    return (countryCode + normalizedPhone).replaceAll('+', '');
  }

  void _verifyCode() async {
    final state = context.read<AuthCubit>().state;
    if (state is! AuthCodeSent) {
      return;
    }
    final code = _otpController.text;
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.codeComplete),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    String formattedPhone = _formatPhoneForApi(widget.phoneNumber, '+213');
    try {
      await context.read<AuthCubit>().verifyCode(formattedPhone, code);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.verificationErrorMsg}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCodeChanged(String value) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthError) {
      context.read<AuthCubit>().clearError();
    }
  }

  void _handleResendCode() {
    final state = context.read<AuthCubit>().state;
    if (state is AuthError || state is AuthCodeSent) {
      context
          .read<AuthCubit>()
          .sendVerificationCode(widget.phoneNumber, '+213');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.codeRenvoye),
          backgroundColor: ColorApp.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.verificationSuccessful),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          if (mounted) {
            if (state.isNewUser) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => UserInfoPage(userId: state.userId),
                ),
              );
            } else if (state.needsLocation) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => LocationPage(),
                ),
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
                (route) => false,
              );
            }
          }
        } else if (state is AuthError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translateErrorMessage(state.message)),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthVerificationLoading;
        final errorMessageRaw = state is AuthError ? state.message : '';
        final errorMessage = errorMessageRaw.isNotEmpty
            ? AppLocalizations.of(context)!
                .translateErrorMessage(errorMessageRaw)
            : '';

        // Get timer state from AuthCodeSent
        final codeSentState = state is AuthCodeSent ? state : null;

        final resendCountdown = codeSentState?.resendCountdown ?? 60;

        return Scaffold(
          backgroundColor: ColorApp.primary,
          body: SafeArea(
            child: Column(
              children: [
                _HeaderSection(),
                _ContentSection(
                  otpController: _otpController,
                  onCodeChanged: _onCodeChanged,
                  onVerify: _verifyCode,
                  onResend: _handleResendCode,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  resendCountdown: resendCountdown,
                  phoneNumber: codeSentState?.phoneNumber ?? '',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Header section with logo
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 30,
      child: Container(
        width: double.infinity,
        color: ColorApp.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/tawwsil.png',
              width: 200,
              height: 80,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

/// Content section with form fields
class _ContentSection extends StatelessWidget {
  final TextEditingController otpController;
  final Function(String) onCodeChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isLoading;
  final String errorMessage;
  final int resendCountdown;
  final String phoneNumber;

  const _ContentSection({
    required this.otpController,
    required this.onCodeChanged,
    required this.onVerify,
    required this.onResend,
    required this.isLoading,
    required this.errorMessage,
    required this.resendCountdown,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 70,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: ColorApp.white,
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
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.enterVerificationCode,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  children: [
                    TextSpan(
                        text: '${AppLocalizations.of(context)!.codeSentTo} '),
                    TextSpan(
                      text: "+213 $phoneNumber",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              _DevOtpSection(),
              const SizedBox(height: 32),
              _OtpInputSection(
                otpController: otpController,
                onCodeChanged: onCodeChanged,
                onVerify: onVerify,
              ),
              const SizedBox(height: 12),
              if (errorMessage.isNotEmpty) ...[
                _ErrorMessageSection(errorMessage: errorMessage),
                const SizedBox(height: 12),
              ],
              _ResendCodeSection(
                resendCountdown: resendCountdown,
                onResend: onResend,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: ColorApp.backgroundGrey,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(ColorApp.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.confirm,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.read<AuthCubit>().resetAuth();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: ColorApp.white,
                    side: BorderSide(color: ColorApp.greyBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.modifyNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ColorApp.black,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Dev OTP section
class _DevOtpSection extends StatelessWidget {
  const _DevOtpSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthCodeSent) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE3FCEC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFB2F5EA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: ColorApp.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.devOtp} ${state.verificationId}',
                    style: const TextStyle(
                      color: Color(0xFF006C4A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// OTP input section with circular fields
class _OtpInputSection extends StatelessWidget {
  final TextEditingController otpController;
  final Function(String) onCodeChanged;
  final VoidCallback onVerify;

  const _OtpInputSection({
    required this.otpController,
    required this.onCodeChanged,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: 6,
      controller: otpController,
      onChanged: onCodeChanged,
      onCompleted: (value) => onVerify(),
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.circle,
        fieldHeight: 35,
        fieldWidth: 35,
        activeFillColor: ColorApp.backgroundGrey,
        inactiveFillColor: ColorApp.backgroundGrey,
        selectedFillColor: ColorApp.backgroundGrey,
        inactiveColor: ColorApp.greyBorder,
        selectedColor: ColorApp.greyBorder,
        borderWidth: 0.1,
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      enableActiveFill: true,
      animationType: AnimationType.fade,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Error message section
class _ErrorMessageSection extends StatelessWidget {
  final String errorMessage;

  const _ErrorMessageSection({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resend code section with timer
class _ResendCodeSection extends StatelessWidget {
  final int resendCountdown;
  final VoidCallback onResend;

  const _ResendCodeSection({
    required this.resendCountdown,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<AuthCubit, AuthState>(builder: (context, state) {
      final canResend = state is AuthError
          ? true
          : state is AuthCodeSent
              ? state.canResend
              : false;
      return Center(
        child: canResend
            ? TextButton(
                onPressed: onResend,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    children: [
                      TextSpan(text: '${localizations.notReceived} '),
                      TextSpan(
                        text: localizations.resend,
                        style: const TextStyle(
                          color: Color(0xFF006C4A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                localizations.resendCodeIn(resendCountdown),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
      );
    });
  }
}
