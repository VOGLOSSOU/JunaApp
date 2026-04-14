import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/auth_controller.dart';
import '../../../home/presentation/controllers/location_controller.dart';

class GeoModal extends ConsumerStatefulWidget {
  const GeoModal({super.key});

  @override
  ConsumerState<GeoModal> createState() => _GeoModalState();
}

class _GeoModalState extends ConsumerState<GeoModal> {
  List<Country> _countries = [];
  bool _isLoading = true;
  String? _selectedCountryCode;
  String? _selectedCityCode;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await LocationService().getCountries();
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() => _isLoading = false);
    }
  }

  void _onCountrySelected(String countryCode) {
    setState(() {
      _selectedCountryCode = countryCode;
      _selectedCityCode = null; // Reset city when country changes
    });
  }

  void _onCitySelected(String cityCode) {
    setState(() => _selectedCityCode = cityCode);
  }

  void _confirm() {
    if (_selectedCountryCode == null || _selectedCityCode == null) return;

    final selectedCountry = _countries.firstWhere((c) => c.code == _selectedCountryCode);
    final selectedCity = selectedCountry.cities.firstWhere((c) => c.code == _selectedCityCode);

    // Update user profile
    final authController = ref.read(authControllerProvider.notifier);
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        city: selectedCity.name,
        country: selectedCountry.name,
      );
      authController.updateUser(updatedUser);
    }

    // Update location controller
    ref.read(locationControllerProvider.notifier).selectCity(
      selectedCity.name,
      selectedCountry.code,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _selectedCountryCode != null
        ? _countries.firstWhere((c) => c.code == _selectedCountryCode)
        : null;
    final cities = selectedCountry?.cities ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Choisir votre localisation', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.lg),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Countries
            Text('Pays', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _countries.map((country) {
                final isSelected = country.code == _selectedCountryCode;
                return GestureDetector(
                  onTap: () => _onCountrySelected(country.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      country.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Cities
            if (_selectedCountryCode != null) ...[
              Text('Ville', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: cities.map((city) {
                  final isSelected = city.code == _selectedCityCode;
                  return GestureDetector(
                    onTap: () => _onCitySelected(city.code),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        city.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.xxxl),

          // Confirm button
          JunaButton(
            label: 'Confirmer',
            variant: JunaButtonVariant.primary,
            onPressed: _selectedCountryCode != null && _selectedCityCode != null ? _confirm : null,
          ),
        ],
      ),
    );
  }
}