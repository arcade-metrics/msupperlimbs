import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';

class FNoseAdvSettingsScreen extends ConsumerStatefulWidget {
  const FNoseAdvSettingsScreen({super.key});

  @override
  ConsumerState<FNoseAdvSettingsScreen> createState() =>
      _FNoseAdvSettingsScreenState();
}

class _FNoseAdvSettingsScreenState
    extends ConsumerState<FNoseAdvSettingsScreen> {
  final _controllers = <String, TextEditingController>{};

  void _initControllers(FNoseAdvSettingsModel settings) {
    _controllers['elbowFlexionThreshold'] =
        TextEditingController(text: settings.elbowFlexionThreshold.toString());
    _controllers['elbowExtensionThreshold'] = TextEditingController(
        text: settings.elbowExtensionThreshold.toString());
    _controllers['horizontalElbowShoulderDistanceThreshold'] =
        TextEditingController(
            text: settings.horizontalElbowShoulderDistanceThreshold.toString());
    _controllers['verticalElbowShoulderDistanceThreshold'] =
        TextEditingController(
            text: settings.verticalElbowShoulderDistanceThreshold.toString());
    _controllers['noseTouchDistanceThreshold'] = TextEditingController(
        text: settings.noseTouchDistanceThreshold.toString());
    _controllers['minAngleChangeForElbowDetection'] = TextEditingController(
        text: settings.minAngleChangeForElbowDetection.toString());
    _controllers['minAngleChangeForShoulderDetection'] = TextEditingController(
        text: settings.minAngleChangeForShoulderDetection.toString());
    _controllers['angleBufferSize'] =
        TextEditingController(text: settings.angleBufferSize.toString());
    _controllers['minDistanceToTarget'] =
        TextEditingController(text: settings.minDistanceToTarget.toString());
    _controllers['targetNumber'] =
        TextEditingController(text: settings.targetNumber.toString());
    _controllers['xTargetPosition'] =
        TextEditingController(text: settings.xTargetPosition.toString());
    _controllers['yTargetPosition'] =
        TextEditingController(text: settings.yTargetPosition.toString());
    _controllers['targetScale'] =
        TextEditingController(text: settings.targetScale.toString());
    _controllers['minShoulderDistance'] =
        TextEditingController(text: settings.minShoulderDistance.toString());
    _controllers['maxShoulderDistance'] =
        TextEditingController(text: settings.maxShoulderDistance.toString());
    _controllers['shoulderYAlignmentThreshold'] = TextEditingController(
        text: settings.shoulderYAlignmentThreshold.toString());
    _controllers['shoulderZAlignmentThreshold'] = TextEditingController(
        text: settings.shoulderZAlignmentThreshold.toString());
    _controllers['noseCenterThreshold'] =
        TextEditingController(text: settings.noseCenterThreshold.toString());
    _controllers['xNoseAlignment'] =
        TextEditingController(text: settings.xNoseAlignment.toString());
    _controllers['yNoseAlignment'] =
        TextEditingController(text: settings.yNoseAlignment.toString());
    _controllers['noseAlignmentThreshold'] =
        TextEditingController(text: settings.noseAlignmentThreshold.toString());
    _controllers['noseAlignmentTargetRadius'] =
        TextEditingController(text: settings.noseAlignmentTargetRadius.toString());
    _controllers['movingAverageFrames'] =
        TextEditingController(text: settings.movingAverageFrames.toString());
    _controllers['stabilityThreshold'] =
        TextEditingController(text: settings.stabilityThreshold.toString());
    _controllers['requiredStableTimeMs'] =
        TextEditingController(text: settings.requiredStableTimeMs.toString());
    _controllers['eventThrottleMs'] =
        TextEditingController(text: settings.eventThrottleMs.toString());
    _controllers['updateDebounceMs'] =
        TextEditingController(text: settings.updateDebounceMs.toString());
    _controllers['angleWindowSeconds'] =
        TextEditingController(text: settings.angleWindowSeconds.toString());
    _controllers['minAngle'] =
        TextEditingController(text: settings.minAngle.toString());
    _controllers['maxAngle'] =
        TextEditingController(text: settings.maxAngle.toString());
    _controllers['alpha'] =
        TextEditingController(text: settings.alpha.toString());
  }

  @override
  void initState() {
    super.initState();
    lockToPortrait();
    Future.microtask(() async {
      final user = ref.read(userProvider);
      if (user != null) {
        final settings =
            await ref.read(fnoseAdvSettingsProvider(user.uid).future);
        ref.read(fnoseAdvSettingsStateProvider.notifier).state = settings;
        if (mounted) {
          setState(() => _initControllers(settings));
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateAdvSettings(String uid) async {
    final current = ref.read(fnoseAdvSettingsStateProvider);
    if (current == null) return;

    await ref
        .read(fnoseAdvSettingsServiceProvider)
        .updateFNoseAdvSettings(current);
    ref.invalidate(fnoseAdvSettingsProvider(uid));
    ref.read(fnoseAdvSettingsStateProvider.notifier).state =
        await ref.read(fnoseAdvSettingsProvider(uid).future);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_adv_settings_advancedSettingsUpdated)),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go('/fnose-intro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final advSettings = ref.watch(fnoseAdvSettingsStateProvider);
    final l10n = AppLocalizations.of(context)!;

    String _scaleLabel(double val) {
      switch (val.toStringAsFixed(2)) {
        case '0.30':
          return l10n.small;
        case '0.40':
          return 'Medium';
        case '0.45':
          return 'Default';
        case '0.50':
          return 'Large';
        case '0.60':
          return l10n.big;
        default:
          return val.toStringAsFixed(2);
      }
    }

    if (userState == null || advSettings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = userState.uid;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeader(title: l10n.fnose_adv_settings_title),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Arm Tracker Area
                    _sectionTitle(l10n.armTrackingSettings),
                    _buildNumberField(
                      l10n.armFlexionThreshold,
                      _controllers['elbowFlexionThreshold']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.elbowFlexionThreshold;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(elbowFlexionThreshold: newVal);
                      },
                      helperText: l10n.armFlexionThresholdDesc,
                    ),
                    _buildNumberField(
                      l10n.armExtensionThreshold,
                      _controllers['elbowExtensionThreshold']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.elbowExtensionThreshold;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(
                                elbowExtensionThreshold: newVal);
                      },
                      helperText: l10n.armExtensionThresholdDesc,
                    ),
                    _buildNumberField(
                      l10n.horizontalElbowShoulderDistanceThreshold,
                      _controllers['horizontalElbowShoulderDistanceThreshold']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings
                                .horizontalElbowShoulderDistanceThreshold;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(
                                horizontalElbowShoulderDistanceThreshold:
                                    newVal);
                      },
                      helperText: l10n.horizontalElbowShoulderDistanceThresholdDesc,
                    ),
                                         _buildNumberField(
                       l10n.verticalElbowShoulderDistanceThreshold,
                       _controllers['verticalElbowShoulderDistanceThreshold']!,
                       (val) {
                         final newVal = double.tryParse(val) ??
                             advSettings.verticalElbowShoulderDistanceThreshold;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(
                                 verticalElbowShoulderDistanceThreshold: newVal);
                       },
                       helperText: l10n.verticalElbowShoulderDistanceThresholdDesc,
                     ),
                    _buildNumberField(
                      l10n.distanceToNoseThreshold,
                      _controllers['noseTouchDistanceThreshold']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.noseTouchDistanceThreshold;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(
                                noseTouchDistanceThreshold: newVal);
                      },
                      helperText: l10n.distanceToNoseThresholdDesc,
                    ),
                    _buildNumberField(
                      l10n.minElbowAngleChange,
                      _controllers['minAngleChangeForElbowDetection']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.minAngleChangeForElbowDetection;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(
                                minAngleChangeForElbowDetection: newVal);
                      },
                      helperText: l10n.minElbowAngleChangeDesc,
                    ),
                    _buildNumberField(
                      l10n.minShoulderAngleChange,
                      _controllers['minAngleChangeForShoulderDetection']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.minAngleChangeForShoulderDetection;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(
                                minAngleChangeForShoulderDetection: newVal);
                      },
                      helperText: l10n.minShoulderAngleChangeDesc,
                    ),
                    _buildNumberField(
                      l10n.angleBufferSize,
                      _controllers['angleBufferSize']!,
                      (val) {
                        final newVal =
                            double.tryParse(val) ?? advSettings.angleBufferSize;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(angleBufferSize: newVal);
                      },
                      helperText: l10n.angleBufferSizeDesc,
                    ),
                    _buildNumberField(
                      l10n.minDistanceToTarget,
                      _controllers['minDistanceToTarget']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.minDistanceToTarget;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(minDistanceToTarget: newVal);
                      },
                      helperText: l10n.minDistanceToTargetDesc,
                    ),

                    // Target Area
                    _sectionTitle(l10n.selectTargetModel),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final number = index + 1;
                          final isSelected = advSettings.targetNumber == number;
                          return GestureDetector(
                            onTap: () {
                              ref
                                      .read(fnoseAdvSettingsStateProvider.notifier)
                                      .state =
                                  advSettings.copyWith(targetNumber: number);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  width: isSelected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'lib/assets/targets/target-$number-720x720.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    _sectionTitle(l10n.selectTargetSize),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value:
                              _scaleToIndex(advSettings.targetScale).toDouble(),
                          min: 0,
                          max: 4,
                          divisions: 4,
                          label: _scaleLabel(advSettings.targetScale),
                          onChanged: (val) {
                            final index = val.round();
                            final scaleMap = [0.3, 0.4, 0.45, 0.5, 0.6];
                            final selectedScale = scaleMap[index];

                            ref
                                    .read(fnoseAdvSettingsStateProvider.notifier)
                                    .state =
                                advSettings.copyWith(
                                    targetScale: selectedScale);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "${l10n.small} ← ${l10n.targetSize} → ${l10n.big}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),

                    _sectionTitle(l10n.targetSettings),

                    _buildNumberField(
                      l10n.targetHorizontalPosition,
                      _controllers['xTargetPosition']!,
                      (val) {
                        final newVal =
                            double.tryParse(val) ?? advSettings.xTargetPosition;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(xTargetPosition: newVal);
                      },
                      helperText: l10n.targetHorizontalPositionDesc,
                    ),
                    _buildNumberField(
                      l10n.targetVerticalPosition,
                      _controllers['yTargetPosition']!,
                      (val) {
                        final newVal =
                            double.tryParse(val) ?? advSettings.yTargetPosition;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(yTargetPosition: newVal);
                      },
                      helperText: l10n.targetVerticalPositionDesc,
                    ),
                    // User Area
                    _sectionTitle(l10n.userPositioningSettings),
                    _buildNumberField(
                      l10n.minScreenDistance,
                      _controllers['minShoulderDistance']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.minShoulderDistance;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(minShoulderDistance: newVal);
                      },
                      helperText: l10n.minScreenDistanceDesc,
                    ),
                    _buildNumberField(
                      l10n.maxScreenDistance,
                      _controllers['maxShoulderDistance']!,
                      (val) {
                        final newVal = double.tryParse(val) ??
                            advSettings.maxShoulderDistance;
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            advSettings.copyWith(maxShoulderDistance: newVal);
                      },
                      helperText: l10n.maxScreenDistanceDesc,
                    ),
                                         _buildNumberField(
                       l10n.shoulderVerticalAlignmentThreshold,
                       _controllers['shoulderYAlignmentThreshold']!,
                       (val) {
                         final newVal = double.tryParse(val) ??
                             advSettings.shoulderYAlignmentThreshold;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(
                                 shoulderYAlignmentThreshold: newVal);
                       },
                       helperText: l10n.shoulderVerticalAlignmentThresholdDesc,
                     ),
                                         _buildNumberField(
                       l10n.trunkAxialAlignmentThreshold,
                       _controllers['shoulderZAlignmentThreshold']!,
                       (val) {
                         final newVal = double.tryParse(val) ??
                             advSettings.shoulderZAlignmentThreshold;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(
                                 shoulderZAlignmentThreshold: newVal);
                       },
                       helperText: l10n.trunkAxialAlignmentThresholdDesc,
                     ),
                                         _buildNumberField(l10n.userScreenAlignmentThreshold,
                         _controllers['noseCenterThreshold']!, (val) {
                       final newVal = double.tryParse(val) ??
                           advSettings.noseCenterThreshold;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(noseCenterThreshold: newVal);
                     },
                         helperText: l10n.userScreenAlignmentThresholdDesc),
                                         _buildNumberField(l10n.noseAlignmentPositionX,
                         _controllers['xNoseAlignment']!, (val) {
                       final newVal = double.tryParse(val) ??
                           advSettings.xNoseAlignment;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(xNoseAlignment: newVal);
                     },
                         helperText: l10n.noseAlignmentPositionXDesc),
                                         _buildNumberField(l10n.noseAlignmentPositionY,
                         _controllers['yNoseAlignment']!, (val) {
                       final newVal = double.tryParse(val) ??
                           advSettings.yNoseAlignment;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(yNoseAlignment: newVal);
                     },
                         helperText: l10n.noseAlignmentPositionYDesc),
                                         _buildNumberField(l10n.noseAlignmentThreshold,
                        _controllers['noseAlignmentThreshold']!, (val) {
                      final newVal = double.tryParse(val) ??
                          advSettings.noseAlignmentThreshold;
                      ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                          advSettings.copyWith(noseAlignmentThreshold: newVal);
                    },
                        helperText: l10n.noseAlignmentThresholdDesc),
                                         _buildNumberField(l10n.noseAlignmentTargetRadius,
                        _controllers['noseAlignmentTargetRadius']!, (val) {
                      final newVal = double.tryParse(val) ??
                          advSettings.noseAlignmentTargetRadius;
                      ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                          advSettings.copyWith(noseAlignmentTargetRadius: newVal);
                    },
                        helperText: l10n.noseAlignmentTargetRadiusDesc),
                                        _buildNumberField(
                      l10n.movementSensitivity,
                       _controllers['movingAverageFrames']!,
                       (val) {
                         final newVal = int.tryParse(val) ??
                             advSettings.movingAverageFrames;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(movingAverageFrames: newVal);
                       },
                       helperText: l10n.movementSensitivityDesc,
                     ),
                                         // Device Area
                     _sectionTitle(l10n.devicePositioningSettings),
                                         _buildNumberField(
                       l10n.stabilityThreshold,
                       _controllers['stabilityThreshold']!,
                       (val) {
                         final newVal = double.tryParse(val) ??
                             advSettings.stabilityThreshold;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(stabilityThreshold: newVal);
                       },
                       helperText: l10n.stabilityThresholdDesc,
                     ),
                                         _buildNumberField(l10n.requiredStableTime,
                         _controllers['requiredStableTimeMs']!, (val) {
                       final newVal =
                           int.tryParse(val) ?? advSettings.requiredStableTimeMs;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(requiredStableTimeMs: newVal);
                     },
                         helperText: l10n.requiredStableTimeDesc),
                                         _buildNumberField(
                       l10n.eventThrottle,
                       _controllers['eventThrottleMs']!,
                       (val) {
                         final newVal =
                             int.tryParse(val) ?? advSettings.eventThrottleMs;
                         ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                             advSettings.copyWith(eventThrottleMs: newVal);
                       },
                       helperText: l10n.eventThrottleDesc,
                     ),
                                         _buildNumberField(l10n.updateBounce,
                         _controllers['updateDebounceMs']!, (val) {
                       final newVal =
                           int.tryParse(val) ?? advSettings.updateDebounceMs;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(updateDebounceMs: newVal);
                     },
                         helperText: l10n.updateBounceDesc),
                                         _buildNumberField(l10n.angleWindow,
                         _controllers['angleWindowSeconds']!, (val) {
                       final newVal =
                           int.tryParse(val) ?? advSettings.angleWindowSeconds;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(angleWindowSeconds: newVal);
                     },
                         helperText: l10n.angleWindowDesc),
                                         _buildNumberField(l10n.minAngle, _controllers['minAngle']!,
                         (val) {
                       final newVal =
                           double.tryParse(val) ?? advSettings.minAngle;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(minAngle: newVal);
                     },
                         helperText: l10n.minAngleDesc),
                                         _buildNumberField(l10n.maxAngle, _controllers['maxAngle']!,
                         (val) {
                       final newVal =
                           double.tryParse(val) ?? advSettings.maxAngle;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(maxAngle: newVal);
                     },
                         helperText: l10n.maxAngleDesc),
                                         _buildNumberField(l10n.alpha, _controllers['alpha']!, (val) {
                       final newVal = double.tryParse(val) ?? advSettings.alpha;
                       ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                           advSettings.copyWith(alpha: newVal);
                     },
                         helperText: l10n.alphaDesc),
                    const SizedBox(height: 24),
                    // Buttons Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Back Button
                        TextButton.icon(
                          onPressed: () => context.go('/fnose-intro'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.common_back),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateAdvSettings(uid),
                          child: Text(l10n.update),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final newDefaults = await ref
                            .read(fnoseAdvSettingsServiceProvider)
                            .restoreFNoseAdvSettingsDefaults(uid);
                        ref.read(fnoseAdvSettingsStateProvider.notifier).state =
                            newDefaults;
                        setState(() {
                          _initControllers(newDefaults);
                        });
                      },
                      child: Text(
                        l10n.restoreDefaults,
                        style: const TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _scaleToIndex(double scale) {
    const scaleMap = [0.3, 0.4, 0.45, 0.5, 0.6];
    final index = scaleMap.indexWhere((v) => (v - scale).abs() < 0.01);
    return index == -1 ? 2 : index; // default to index of 0.45
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? helperText,
    double fieldWidth = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                helperText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
