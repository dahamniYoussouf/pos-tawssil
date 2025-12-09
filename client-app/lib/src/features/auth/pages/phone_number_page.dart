import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/extensions/app_localizations_extension.dart';
import 'package:client_app/src/features/auth/cubit/auth_state.dart';
import 'package:flutter_svg/svg.dart';
import '../cubit/auth_cubit.dart';
import 'verification_page.dart';

class PhoneNumberPage extends StatelessWidget {
  const PhoneNumberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PhoneNumberView();
  }
}

class PhoneNumberView extends StatefulWidget {
  const PhoneNumberView({Key? key}) : super(key: key);

  @override
  State<PhoneNumberView> createState() => _PhoneNumberViewState();
}

class _PhoneNumberViewState extends State<PhoneNumberView> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+213';

  @override
  void initState() {
    super.initState();
    // Clear any previous error state when page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<AuthCubit>().state;
      if (currentState is AuthError) {
        context.read<AuthCubit>().clearError();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final phone = _phoneController.text.trim();
    context.read<AuthCubit>().sendVerificationCode(phone, _countryCode).then(
      (success) {
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(phoneNumber: phone),
            ),
          );
        }
      },
    );
  }

  void _handleAppleLogin() {
    // TODO: Implement Apple login
  }

  void _handleGoogleLogin() {
    // TODO: Implement Google login (keep empty for now)
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessageRaw = state is AuthError ? state.message : '';
        final errorMessage = errorMessageRaw.isNotEmpty
            ? AppLocalizations.of(context)!
                .translateErrorMessage(errorMessageRaw)
            : '';
        final localizations = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: ColorApp.primary,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
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
                ),
                Expanded(
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
                          Text(
                            localizations.addPhoneNumber,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.phoneNumberSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ColorApp.grey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Container(
                            decoration: BoxDecoration(
                              color: ColorApp.grey2,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: errorMessage.isNotEmpty
                                    ? ColorApp.redColor
                                    : ColorApp.greyBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildCountryCodeSelector(),
                                _buildPhoneNumberInput(localizations),
                              ],
                            ),
                          ),
                          if (errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildErrorMessage(errorMessage),
                          ],
                          const SizedBox(height: 25),
                          _buildConnectButton(localizations, isLoading),
                          const SizedBox(height: 20),
                          _buildSeparator(localizations),
                          const SizedBox(height: 20),
                          _buildSocialLoginButtons(localizations),
                          const SizedBox(height: 30),
                          _buildTermsAndPrivacy(localizations),
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

  Widget _buildCountryCodeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: ColorApp.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(MediaRes.algeriaFlagIcon),
            radius: 18,
          ),
          const SizedBox(width: 6),
          Text(
            "ALG" + ' ' + _countryCode,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorApp.black,
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            color: ColorApp.black,
            MediaRes.doubleArrowUpIcon,
            width: 8,
            height: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberInput(AppLocalizations localizations) {
    return Expanded(
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          fontSize: 14,
          color: ColorApp.black,
          fontWeight: FontWeight.w500,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          hintText: "000 00 00 00", // localizations.phoneNumberHint,
          hintStyle: const TextStyle(
            color: ColorApp.black,
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
          if (_phoneController.text.trim().isNotEmpty) {
            _handleConnect();
          }
        },
      ),
    );
  }

  Widget _buildErrorMessage(String errorMessage) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: ColorApp.redColor,
          size: 16,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            errorMessage,
            style: const TextStyle(
              color: ColorApp.redColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton(AppLocalizations localizations, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorApp.primary,
          disabledBackgroundColor: ColorApp.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ColorApp.white),
                ),
              )
            : Text(
                localizations.connect,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ColorApp.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildSeparator(AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: ColorApp.grey,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            localizations.or,
            style: const TextStyle(
              fontSize: 14,
              color: ColorApp.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: ColorApp.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons(AppLocalizations localizations) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: MediaRes.appleIcon,
            label: localizations.apple,
            onPressed: _handleAppleLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: MediaRes.googleIcon,
            label: localizations.google,
            onPressed: _handleGoogleLogin,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF374151),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorApp.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy(AppLocalizations localizations) {
    return Column(
      children: [
        Text(
          localizations.acceptTerms,
          style: const TextStyle(
            fontSize: 12,
            color: ColorApp.black,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLink(
              text: localizations.termsOfUse,
              onTap: () {
                // TODO: Navigate to terms of use
              },
            ),
            const Text(
              ' • ',
              style: TextStyle(
                fontSize: 12,
                color: ColorApp.grey,
              ),
            ),
            _buildLink(
              text: localizations.privacyPolicy,
              onTap: () {
                // TODO: Navigate to privacy policy
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLink({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: ColorApp.black,
          decoration: TextDecoration.underline,
          decorationColor: ColorApp.black,
        ),
      ),
    );
  }
}
