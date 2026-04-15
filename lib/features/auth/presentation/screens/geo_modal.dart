import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/location_repository.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../controllers/auth_controller.dart';
import '../../data/models/auth_models.dart';

class GeoModal extends ConsumerStatefulWidget {
  const GeoModal({super.key});

  @override
  ConsumerState<GeoModal> createState() => _GeoModalState();
}

class _GeoModalState extends ConsumerState<GeoModal> {
  // Données
  List<CountryModel> _countries = [];
  List<CityModel> _cities = [];

  // Sélection
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;

  // États
  bool _loadingCountries = true;
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountries = true;
      _error = null;
    });
    try {
      final repo = ref.read(locationRepositoryProvider);
      final countries = await repo.getCountries();
      setState(() {
        _countries = countries;
        _loadingCountries = false;
      });
    } on AppException catch (e) {
      setState(() {
        _error = e.message;
        _loadingCountries = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible de charger les pays.';
        _loadingCountries = false;
      });
    }
  }

  Future<void> _onCountrySelected(CountryModel country) async {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _cities = [];
      _loadingCities = true;
    });
    try {
      final repo = ref.read(locationRepositoryProvider);
      final cities = await repo.getCitiesByCountry(country.code);
      setState(() {
        _cities = cities;
        _loadingCities = false;
      });
    } on AppException catch (e) {
      setState(() {
        _error = e.message;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Impossible de charger les villes.';
        _loadingCities = false;
      });
    }
  }

  void _confirm() {
    if (_selectedCountry == null || _selectedCity == null) return;

    // Mettre à jour le profil user si connecté
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      ref.read(authControllerProvider.notifier).updateUser(
            currentUser.copyWith(
              city: _selectedCity!.name,
              country: _selectedCountry!.displayName,
            ),
          );
    }

    // Mettre à jour la localisation affichée dans l'app
    ref.read(locationControllerProvider.notifier).selectCity(
          _selectedCity!.name,
          _selectedCountry!.code,
          cityId: _selectedCity!.id,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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

          Text('Votre localisation', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choisissez votre pays et votre ville pour voir les abonnements disponibles près de vous.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Contenu ─────────────────────────────────────────────────────
          if (_error != null)
            _ErrorBox(message: _error!, onRetry: _loadCountries)
          else if (_loadingCountries)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else ...[
            // Pays
            Text('Pays', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _countries.map((country) {
                final isSelected = country.id == _selectedCountry?.id;
                return _Chip(
                  label: country.displayName,
                  isSelected: isSelected,
                  onTap: () => _onCountrySelected(country),
                );
              }).toList(),
            ),

            if (_selectedCountry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Ville', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              if (_loadingCities)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_cities.isEmpty)
                Text(
                  'Aucune ville disponible pour ce pays.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _cities.map((city) {
                    final isSelected = city.id == _selectedCity?.id;
                    return _Chip(
                      label: city.name,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCity = city),
                    );
                  }).toList(),
                ),
            ],
          ],

          const SizedBox(height: AppSpacing.xxxl),

          JunaButton(
            label: 'Confirmer',
            variant: JunaButtonVariant.primary,
            onPressed: _selectedCountry != null && _selectedCity != null
                ? _confirm
                : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: isSelected
              ? null
              : Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 36),
            const SizedBox(height: AppSpacing.sm),
            Text(message,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text('Réessayer',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
