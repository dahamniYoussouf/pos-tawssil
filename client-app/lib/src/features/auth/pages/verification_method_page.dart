import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'verification_page.dart';

class VerificationMethodPage extends StatefulWidget {
  final String phoneNumber;

  const VerificationMethodPage({Key? key, required this.phoneNumber})
      : super(key: key);

  @override
  State<VerificationMethodPage> createState() => _VerificationMethodPageState();
}

class _VerificationMethodPageState extends State<VerificationMethodPage> {
  String _selectedMethod = 'whatsapp'; // Default selection

  void _handleConnect() {
    if (context.read<AuthCubit>().state is AuthLoading) return;

    // For now, we use the same verify code API as the user said "api same structure"
    context
        .read<AuthCubit>()
        .sendVerificationCode(widget.phoneNumber, '+213')
        .then(
      (success) {
        if (success) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerificationPage(phoneNumber: widget.phoneNumber),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
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
                    child: Stack(
                      children: [
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: SvgPicture.asset(
                              MediaRes.backButtonIcon,
                              colorFilter: const ColorFilter.mode(
                                ColorApp.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                MediaRes.tawwsilIcon,
                                width: 200,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.selectVerificationMethod,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.verificationMethodSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ColorApp.grey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildMethodOption(
                            id: 'whatsapp',
                            title: localizations.viaWhatsApp,
                            icon: MediaRes.whatsappIcon,
                            isSelected: _selectedMethod == 'whatsapp',
                            badge: localizations.recommended,
                          ),
                          const SizedBox(height: 16),
                          _buildMethodOption(
                            id: 'sms',
                            title: localizations.viaSMS,
                            icon: MediaRes.smsIcon,
                            isSelected: _selectedMethod == 'sms',
                          ),
                          const Spacer(),
                          _buildConnectButton(localizations, isLoading),
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

  Widget _buildMethodOption({
    required String id,
    required String title,
    required String icon,
    required bool isSelected,
    String? badge,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: ColorApp.backgroundGrey,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? ColorApp.primary : ColorApp.greyBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? ColorApp.primary : ColorApp.black,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: ColorApp.black,
                ),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorApp.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.primary,
                  ),
                ),
              ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: ColorApp.primary,
                size: 24,
              ),
          ],
        ),
      ),
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
}
