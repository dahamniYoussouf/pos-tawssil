import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_state.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/auth/widgets/location_search_field.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final List<String> _selectedRestaurantCategories = [];
  String? _selectedWillaya;
  String? _selectedZone;

  final List<String> _restaurantCategories = const [
    'Pizza',
    'Burger',
    "Sushi",
    "Desserts",
    "Drinks",
    'Autre',
  ];

  List<String> _willayas = [];

  final List<String> _zones = [
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
    'Zone 5',
  ];

  @override
  void initState() {
    super.initState();
    _loadWillayas();
  }

  Future<void> _loadWillayas() async {
    try {
      final String response = await rootBundle.loadString('assets/data/wilayas.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;
      setState(() {
        _willayas = data.map((item) => item['name'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading wilayas: $e');
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedRestaurantCategories.isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorRestaurantTypeRequired);
        return;
      }

      if (_selectedWillaya == null || _selectedWillaya!.isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorWillayaRequired);
        return;
      }

      if (_selectedZone == null || _selectedZone!.isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorZoneRequired);
        return;
      }

      if (_descriptionController.text.trim().isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorDescriptionRequired);
        return;
      }

      if (_addressController.text.trim().isEmpty) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorLocationRequired);
        return;
      }

      final double? latitude = double.tryParse(_latitudeController.text.trim());
      final double? longitude = double.tryParse(_longitudeController.text.trim());

      if (latitude == null || longitude == null) {
        _showErrorSnackBar(AppLocalizations.of(context)!.errorLocationRequired);
        return;
      }

      context.read<AuthCubit>().register(
            restaurantName: _restaurantNameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            restaurantCategories: _selectedRestaurantCategories,
            description: _descriptionController.text.trim(),
            address: _addressController.text.trim(),
            latitude: latitude,
            longitude: longitude,
            willaya: _selectedWillaya!,
            zone: _selectedZone!,
          );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                context.read<AuthCubit>().clearError();
              } else if (state is AuthSuccess) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 24),
                    Text(
                      localizations.signUpTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.signUpSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRestaurantNameField(localizations),
                    const SizedBox(height: 16),
                    _buildEmailField(localizations),
                    const SizedBox(height: 16),
                    _buildPhoneField(localizations),
                    const SizedBox(height: 16),
                    _buildPasswordField(localizations),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(localizations),
                    const SizedBox(height: 16),
                    _buildRestaurantTypeField(localizations),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildWillayaField(localizations)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildZoneField(localizations)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDescriptionField(localizations),
                    const SizedBox(height: 16),
                    _buildLocationSection(localizations),
                    const SizedBox(height: 24),
                    _buildSignupButton(localizations, isLoading),
                    const SizedBox(height: 16),
                    _buildTermsText(localizations),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Image.asset(
        MediaRes.logo,
        height: 100,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildRestaurantNameField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.restaurantName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _restaurantNameController,
          decoration: InputDecoration(
            hintText: localizations.restaurantNameHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.errorRestaurantNameRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.email,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: localizations.emailHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.errorEmailRequired;
            }
            if (!value.contains('@')) {
              return 'Invalid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.phoneNumber,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 80,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryColor, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇩🇿', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  const Text('+213', style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: localizations.phoneNumberHint,
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.errorPhoneNumberRequired;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.password,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: localizations.passwordHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.errorPasswordRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.confirmPassword,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            hintText: localizations.confirmPasswordHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.errorConfirmPasswordRequired;
            }
            if (value != _passwordController.text) {
              return localizations.errorPasswordMismatch;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantTypeField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.restaurantType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _restaurantCategories.map((type) {
            final bool isSelected = _selectedRestaurantCategories.contains(type);
            return FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryColor : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _handleRestaurantTypeTap(type),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primaryColor.withOpacity(0.15),
              checkmarkColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade400,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.description,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: localizations.descriptionHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return localizations.errorDescriptionRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection(AppLocalizations localizations) {
    return LocationSearchField(
      controller: _addressController,
      onLocationSelected: (selection) {
        _addressController.text = selection.address;
        _latitudeController.text = selection.latitude.toStringAsFixed(6);
        _longitudeController.text = selection.longitude.toStringAsFixed(6);
      },
    );
  }

  void _handleRestaurantTypeTap(String type) {
    setState(() {
      if (_selectedRestaurantCategories.contains(type)) {
        _selectedRestaurantCategories.remove(type);
        return;
      }
      _selectedRestaurantCategories.add(type);
    });
  }

  Widget _buildWillayaField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.willaya,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedWillaya,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: localizations.willayaHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          items: _willayas.map((willaya) {
            return DropdownMenuItem<String>(
              value: willaya,
              child: Text(
                willaya,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return _willayas.map((willaya) {
              return Text(
                willaya,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          onChanged: (value) {
            setState(() {
              _selectedWillaya = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildZoneField(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.zone,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedZone,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: localizations.zoneHint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ),
          items: _zones.map((zone) {
            return DropdownMenuItem<String>(
              value: zone,
              child: Text(
                zone,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          selectedItemBuilder: (BuildContext context) {
            return _zones.map((zone) {
              return Text(
                zone,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          onChanged: (value) {
            setState(() {
              _selectedZone = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton(AppLocalizations localizations, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleSignup,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              localizations.signUp,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildTermsText(AppLocalizations localizations) {
    return Center(
      child: Text(
        localizations.signUpTerms,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
