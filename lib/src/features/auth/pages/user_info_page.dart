import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/auth/cubit/auth_state.dart';
import '../cubit/auth_cubit.dart';
import '../../locations/pages/location_page.dart';

/// User Info Page
/// Matches the Tawsil design with green branding
class UserInfoPage extends StatelessWidget {
  final String userId;

  const UserInfoPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserInfoView(userId: userId);
  }
}

class UserInfoView extends StatefulWidget {
  final String userId;

  const UserInfoView({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserInfoView> createState() => _UserInfoViewState();
}

class _UserInfoViewState extends State<UserInfoView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    context.read<AuthCubit>().updateUserInfo(
          firstName: firstName,
          lastName: lastName,
          userId: widget.userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPage(),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthUpdatingProfile;
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
                            AppLocalizations.of(context)!.addUserInfo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            AppLocalizations.of(context)!.userInfoSubtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C757D),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // First name input field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: errorMessage.isNotEmpty ? Colors.red : const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _firstNameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]')),
                              ],
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.firstNameHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color(0xFF6B7280),
                                  size: 20,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (!isLoading) {
                                  _handleSave();
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Last name input field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: errorMessage.isNotEmpty ? Colors.red : const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _lastNameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w500,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]')),
                              ],
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.lastNameHint,
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF6B7280),
                                  size: 20,
                                ),
                              ),
                              onSubmitted: (value) {
                                if (!isLoading) {
                                  _handleSave();
                                }
                              },
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

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleSave,
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
                                      AppLocalizations.of(context)!.save,
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
