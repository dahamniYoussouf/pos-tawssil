import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';
import 'package:restaurant_app/src/core/utils/constant.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:restaurant_app/src/features/restaurant/widgets/edit_opening_hours_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  State<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        context.read<RestaurantCubit>().updateImage(image.path);
      }
    }
  }

  void _showEditDialog(RestaurantModel restaurant) {
    final nameController = TextEditingController(text: restaurant.name);
    final descController =
        TextEditingController(text: restaurant.description ?? '');
    final addressController =
        TextEditingController(text: restaurant.address ?? '');
    final phoneController = TextEditingController(text: restaurant.phone);
    final emailController = TextEditingController(text: restaurant.email);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.modifier,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(l10n.restaurantName, nameController),
              const SizedBox(height: 16),
              _buildTextField(l10n.description, descController, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(l10n.address, addressController),
              const SizedBox(height: 16),
              _buildTextField(l10n.phoneNumber, phoneController),
              const SizedBox(height: 16),
              _buildTextField(l10n.email, emailController),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final updated = restaurant.copyWith(
                    name: nameController.text,
                    description: descController.text,
                    address: addressController.text,
                    phone: phoneController.text,
                    email: emailController.text,
                  );
                  this.context.read<RestaurantCubit>().updateProfile(updated);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.saveChanges),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpeningHoursDialog(RestaurantModel restaurant) {
    EditOpeningHoursSheet.show(
      context,
      initialHours: Map<String, dynamic>.from(restaurant.openingHours ?? {}),
      onSave: (updatedHours) {
        final updated = restaurant.copyWith(openingHours: updatedHours);
        context.read<RestaurantCubit>().updateProfile(updated);
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.iconMedium,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.restaurantProfileTitle,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<RestaurantCubit, RestaurantState>(
        builder: (context, state) {
          if (state is RestaurantLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RestaurantLoaded) {
            final restaurant = state.restaurant;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(restaurant, l10n),
                  const SizedBox(height: 24),
                  _buildSectionHeader(l10n.establishmentInformation,
                      l10n.modifier, () => _showEditDialog(restaurant)),
                  const SizedBox(height: 12),
                  _buildInfoCard(restaurant, l10n),
                  const SizedBox(height: 24),
                  _buildSectionHeader(l10n.openingHours, l10n.gerer,
                      () => _showOpeningHoursDialog(restaurant)),
                  const SizedBox(height: 12),
                  _buildOpeningHoursCard(restaurant, l10n),
                  const SizedBox(height: 24),
                  Text(
                    l10n.categoriesYouOffer,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...(restaurant.homeCategories ?? []).map((cat) {
                        return Chip(
                          label: Text(cat.name),
                          backgroundColor: AppColors.primary,
                          labelStyle: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                        );
                      }),
                      if ((restaurant.homeCategories ?? []).isEmpty &&
                          (restaurant.categories ?? []).isNotEmpty)
                        ...(restaurant.categories ?? []).map((cat) {
                          return Chip(
                            label: Text(cat.nom),
                            backgroundColor: AppColors.primary.withOpacity(0.7),
                            labelStyle: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide.none,
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                      l10n.vitrinePhoto, l10n.change, _pickImage),
                  const SizedBox(height: 12),
                  _buildStorefrontPhoto(restaurant, l10n),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showEditDialog(restaurant),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.saveChanges),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String actionText, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(RestaurantModel restaurant, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: restaurant.imageUrl != null &&
                    restaurant.imageUrl!.isNotEmpty
                ? Image.network(
                    restaurant.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.primary,
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        MediaRes.navMenu,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.primary,
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(
                      MediaRes.navMenu,
                      colorFilter:
                          const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  restaurant.description ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLightGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.statusLabel} ',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLightGrey),
                    ),
                    Text(
                      (restaurant.isApproved ?? false)
                          ? l10n.approvedStatus
                          : 'En attente', // Fallback for pending
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (restaurant.isApproved ?? false)
                            ? AppColors.primary
                            : AppColors.statusPending,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      (restaurant.isApproved ?? false)
                          ? Icons.check_circle
                          : Icons.hourglass_empty,
                      size: 14,
                      color: (restaurant.isApproved ?? false)
                          ? AppColors.primary
                          : AppColors.statusPending,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RestaurantModel restaurant, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _showEditDialog(restaurant),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _buildInfoItem(Icons.location_on_outlined, l10n.addressMini,
                restaurant.address ?? ''),
            const Divider(height: 1, indent: 60),
            _buildInfoItem(
                Icons.phone_outlined, l10n.phoneMini, restaurant.phone),
            const Divider(height: 1, indent: 60),
            _buildInfoItem(
                Icons.mail_outline, l10n.emailMini, restaurant.email),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLightGrey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLightGrey,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursCard(
      RestaurantModel restaurant, AppLocalizations l10n) {
    final hours = restaurant.formattedOpeningHours;
    if (hours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            l10n.noDataAvailable,
            style: const TextStyle(color: AppColors.textLightGrey),
          ),
        ),
      );
    }

    final dayLabels = getDayLabels(l10n);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: hours.map((h) {
          final isLast = hours.last == h;
          return Column(
            children: [
              _buildHoursRow(
                dayLabels[h['dayKey']] ?? h['dayKey'],
                h['isClosed'] ? l10n.closedStatus : h['hours'],
                isClosed: h['isClosed'],
              ),
              if (!isLast) const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHoursRow(String days, String hours, {bool isClosed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          days,
          style: const TextStyle(fontSize: 14, color: AppColors.textLightGrey),
        ),
        Text(
          hours,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isClosed ? AppColors.red : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStorefrontPhoto(
      RestaurantModel restaurant, AppLocalizations l10n) {
    final bool hasImage =
        restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: hasImage
              ? Image.network(
                  restaurant.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(l10n),
                )
              : _buildImagePlaceholder(l10n),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderGrey,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: AppColors.textLightGrey),
                const SizedBox(width: 8),
                Text(
                  l10n.updatePhoto,
                  style: const TextStyle(
                    color: AppColors.textLightGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.borderGrey,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: AppColors.textLightGrey,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.updatePhoto,
              style: const TextStyle(
                color: AppColors.textLightGrey,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
