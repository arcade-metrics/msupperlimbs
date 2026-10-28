import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/gameplay/presentation/widgets/device_stability_checker.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';

class RapidStabilityCheckerOverlay extends StatelessWidget {
  final AsyncValue<bool> stabilityAsync;
  final bool showValidationUI;

  const RapidStabilityCheckerOverlay({
    super.key,
    required this.stabilityAsync,
    required this.showValidationUI,
  });

  @override
  Widget build(BuildContext context) {
    return stabilityAsync.when(
      data: (isStable) {
        return AnimatedOpacity(
          opacity: showValidationUI ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Visibility(
            visible: !showValidationUI,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withAlpha((0.5 * 255).round()),
              child: const SafeArea(
                child: DeviceStabilityChecker(),
              ),
            ),
          ),
        );
      },
      loading: () => Center(
        child: Text(
          AppLocalizations.of(context)!.common_loading,
          style: const TextStyle(color: Colors.white, fontFamily: 'BebasNeue', fontSize: 24),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          AppLocalizations.of(context)!.stability_errorCheckingStability,
          style: const TextStyle(color: Colors.white, fontFamily: 'BebasNeue', fontSize: 20),
        ),
      ),
    );
  }
}
