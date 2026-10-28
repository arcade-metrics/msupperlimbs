import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings_model.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';

class RapidSettingsScreen extends ConsumerStatefulWidget {
  const RapidSettingsScreen({super.key});

  @override
  ConsumerState<RapidSettingsScreen> createState() => _RapidSettingsScreenState();
}

class _RapidSettingsScreenState extends ConsumerState<RapidSettingsScreen> {
  final _controllers = <String, TextEditingController>{};

  void _initControllers(RapidSettingsModel settings) {
    // Configurações básicas
    _controllers['totalTime'] =
        TextEditingController(text: settings.totalTime.toString());
    _controllers['tapSensitivity'] =
        TextEditingController(text: settings.tapSensitivity?.toString() ?? "50.0");
    _controllers['tapCooldownMs'] =
        TextEditingController(text: settings.tapCooldownMs?.toString() ?? "110");
        
    // Controlador da linha de pulso
    _controllers['maxPoints'] =
        TextEditingController(text: settings.maxPoints?.toString() ?? "420");
    _controllers['minY'] =
        TextEditingController(text: settings.minY?.toString() ?? "0.0");
    _controllers['maxY'] =
        TextEditingController(text: settings.maxY?.toString() ?? "1.0");
    _controllers['baseline'] =
        TextEditingController(text: settings.baseline?.toString() ?? "0.25");
    _controllers['gravityPerSecond'] =
        TextEditingController(text: settings.gravityPerSecond?.toString() ?? "0.35");
    _controllers['impulseStrength'] =
        TextEditingController(text: settings.impulseStrength?.toString() ?? "0.06");
    _controllers['floorRestitution'] =
        TextEditingController(text: settings.floorRestitution?.toString() ?? "0.0");
        
    // Taxas de decaimento por estado
    _controllers['decayRateIdle'] =
        TextEditingController(text: settings.decayRateIdle?.toString() ?? "0.05");
    _controllers['decayRateActive'] =
        TextEditingController(text: settings.decayRateActive?.toString() ?? "0.03");
    _controllers['decayRateUnstable'] =
        TextEditingController(text: settings.decayRateUnstable?.toString() ?? "0.07");
    _controllers['decayRateFlatline'] =
        TextEditingController(text: settings.decayRateFlatline?.toString() ?? "0.10");
        
    // Aparência da linha
    _controllers['lineWidth'] =
        TextEditingController(text: settings.lineWidth?.toString() ?? "3.0");
    _controllers['glowBlurSigma'] =
        TextEditingController(text: settings.glowBlurSigma?.toString() ?? "8.0");
        
    // Configurações globais
    _controllers['fixedDtSeconds'] =
        TextEditingController(text: settings.fixedDtSeconds?.toString() ?? "${1/30}");
        
    // Configurações legadas
    _controllers['pulseMaxIntensity'] =
        TextEditingController(text: settings.pulseMaxIntensity?.toString() ?? "0.6");
    _controllers['pulseGravity'] =
        TextEditingController(text: settings.pulseGravity?.toString() ?? "0.015");
    _controllers['pulseImpulse'] =
        TextEditingController(text: settings.pulseImpulse?.toString() ?? "0.12");
  }

  @override
  void initState() {
    super.initState();
    lockToPortrait();
    Future.microtask(() async {
      final user = ref.read(userProvider);
      if (user != null) {
        final settings = await ref.read(rapidSettingsProvider(user.uid).future);
        ref.read(rapidSettingsStateProvider.notifier).state = settings;
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

  Future<void> _updateSettings(String uid) async {
    final current = ref.read(rapidSettingsStateProvider);
    if (current == null) return;

    await ref.read(rapidSettingsServiceProvider).updateRapidSettings(current);
    ref.invalidate(rapidSettingsProvider(uid));
    ref.read(rapidSettingsStateProvider.notifier).state =
        await ref.read(rapidSettingsProvider(uid).future);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_settings_settingsUpdated)),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go('/rapid-intro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final rapidSettings = ref.watch(rapidSettingsStateProvider);
    final l10n = AppLocalizations.of(context)!;

    if (userState == null || rapidSettings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = userState.uid;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeader(title: 'Rapid Settings'),
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
                    SwitchListTile(
                      title: Text(l10n.fnose_settings_showInstructionVideo),
                      value: rapidSettings.showInfoVideo,
                      onChanged: (value) {
                        ref.read(rapidSettingsStateProvider.notifier).state =
                            rapidSettings.copyWith(showInfoVideo: value);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Visualization type selector
                    const Text('Visualisation Type', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Line Graph'),
                          value: 'line',
                          groupValue: rapidSettings.visualizationType,
                          onChanged: (value) {
                            ref.read(rapidSettingsStateProvider.notifier).state =
                                rapidSettings.copyWith(visualizationType: value);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Vertical Bar'),
                          value: 'bar',
                          groupValue: rapidSettings.visualizationType,
                          onChanged: (value) {
                            ref.read(rapidSettingsStateProvider.notifier).state =
                                rapidSettings.copyWith(visualizationType: value);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Circle with Particles'),
                          value: 'circle',
                          groupValue: rapidSettings.visualizationType,
                          onChanged: (value) {
                            ref.read(rapidSettingsStateProvider.notifier).state =
                                rapidSettings.copyWith(visualizationType: value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        l10n.totalTimeSec, _controllers['totalTime']!, (val) {
                      final newVal =
                          int.tryParse(val) ?? rapidSettings.totalTime;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(totalTime: newVal);
                    }),
                    const SizedBox(height: 8), // Reduzido de 16 para 8
                    // Configurações de detecção de toque
                    const Divider(height: 16), // Altura reduzida
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0), // Reduzido de 8.0 para 4.0
                      child: Text('1. Touch Detection', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildNumberField(
                        'Touch Detection Distance (px)', _controllers['tapSensitivity']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.tapSensitivity ?? 50.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(tapSensitivity: newVal);
                    }, 
                    helperText: 'Lower value = more sensitive. Default: 50.0'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Minimum Interval Between Taps (ms)', _controllers['tapCooldownMs']!, (val) {
                      final newVal =
                          int.tryParse(val) ?? rapidSettings.tapCooldownMs ?? 110;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(tapCooldownMs: newVal);
                    }, 
                    helperText: 'Cooldown between detections. Default: 110'),
                    
                    // Configurações do controlador da linha de pulso
                    const Divider(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('2. Graph Physics (PulseLineController)', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildNumberField(
                        'Window Size (maxPoints)', _controllers['maxPoints']!, (val) {
                      final newVal =
                          int.tryParse(val) ?? rapidSettings.maxPoints ?? 420;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(maxPoints: newVal);
                    }, 
                    helperText: 'Number of points in the graph. Default: 420'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Normalised Floor (minY)', _controllers['minY']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.minY ?? 0.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(minY: newVal);
                    }, 
                    helperText: 'Lower limit of the graph. Default: 0.0'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Normalised Ceiling (maxY)', _controllers['maxY']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.maxY ?? 1.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(maxY: newVal);
                    }, 
                    helperText: 'Upper limit of the graph. Default: 1.0'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Baseline', _controllers['baseline']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.baseline ?? 0.25;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(baseline: newVal);
                    }, 
                    helperText: 'Initial/base level of the line. Default: 0.25'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Gravity per Second', _controllers['gravityPerSecond']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.gravityPerSecond ?? 0.35;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(gravityPerSecond: newVal);
                    }, 
                    helperText: 'Fall per second (↑ = falls faster). Default: 0.35'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Impulse Strength', _controllers['impulseStrength']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.impulseStrength ?? 0.06;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(impulseStrength: newVal);
                    }, 
                    helperText: 'How much it rises per tap. Default: 0.06'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Floor Restitution', _controllers['floorRestitution']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.floorRestitution ?? 0.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(floorRestitution: newVal);
                    }, 
                    helperText: 'Bounce when hitting floor (0 = no bounce). Default: 0.0'),
                    
                    // Taxas de decaimento por estado
                    const Divider(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('3. State Modulation (PulseLineState)', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildNumberField(
                        'Decay Rate - Idle', _controllers['decayRateIdle']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.decayRateIdle ?? 0.05;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(decayRateIdle: newVal);
                    }, 
                    helperText: 'Decay in idle state. Default: 0.05'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Decay Rate - Active', _controllers['decayRateActive']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.decayRateActive ?? 0.03;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(decayRateActive: newVal);
                    }, 
                    helperText: 'Decay in active state. Default: 0.03'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Decay Rate - Unstable', _controllers['decayRateUnstable']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.decayRateUnstable ?? 0.07;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(decayRateUnstable: newVal);
                    }, 
                    helperText: 'Decay in unstable state. Default: 0.07'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Decay Rate - Flatline', _controllers['decayRateFlatline']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.decayRateFlatline ?? 0.10;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(decayRateFlatline: newVal);
                    }, 
                    helperText: 'Decay in flatline state. Default: 0.10'),
                    
                    // Aparência da linha
                    const Divider(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('4. Line Aesthetics (PulseLineWidget)', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildNumberField(
                        'Line Width', _controllers['lineWidth']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.lineWidth ?? 3.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(lineWidth: newVal);
                    }, 
                    helperText: 'Line thickness. Default: 3.0'),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Glow Effect'),
                      value: rapidSettings.glowEnabled ?? true,
                      onChanged: (value) {
                        ref.read(rapidSettingsStateProvider.notifier).state =
                            rapidSettings.copyWith(glowEnabled: value);
                      },
                      subtitle: const Text('Activates the glow effect on the line'),
                    ),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Glow Intensity', _controllers['glowBlurSigma']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.glowBlurSigma ?? 8.0;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(glowBlurSigma: newVal);
                    }, 
                    helperText: 'Intensity of the glow effect. Default: 8.0'),
                    
                    // Configurações globais
                    const Divider(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('5. Global Settings', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: const Text('Use Fixed Time Step'),
                      value: rapidSettings.useFixedDt ?? true,
                      onChanged: (value) {
                        ref.read(rapidSettingsStateProvider.notifier).state =
                            rapidSettings.copyWith(useFixedDt: value);
                      },
                      subtitle: const Text('Stabilises physics using a fixed time step'),
                    ),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Fixed Time Step (seconds)', _controllers['fixedDtSeconds']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.fixedDtSeconds ?? (1/30);
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(fixedDtSeconds: newVal);
                    }, 
                    helperText: 'Time between frames in seconds. Default: 0.0333 (1/30)'),
                    
                    // Configurações legadas (mantidas para compatibilidade)
                    const Divider(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('Legacy Settings', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildNumberField(
                        'Maximum Graph Height (0-1)', _controllers['pulseMaxIntensity']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.pulseMaxIntensity ?? 0.6;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(pulseMaxIntensity: newVal);
                    }, 
                    helperText: 'Maximum line height. 0.6 = 60%. Default: 0.6'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Gravity (Fall)', _controllers['pulseGravity']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.pulseGravity ?? 0.015;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(pulseGravity: newVal);
                    }, 
                    helperText: 'Constant fall speed. Default: 0.006'),
                    const SizedBox(height: 6), // Reduzido de 16 para 6
                    _buildNumberField(
                        'Impulse per Touch', _controllers['pulseImpulse']!, (val) {
                      final newVal =
                          double.tryParse(val) ?? rapidSettings.pulseImpulse ?? 0.12;
                      ref.read(rapidSettingsStateProvider.notifier).state =
                          rapidSettings.copyWith(pulseImpulse: newVal);
                    }, 
                    helperText: 'How much it rises per touch. Default: 0.05'),
                    const SizedBox(height: 12), // Reduzido de 24 para 12
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/rapid-intro'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.common_back),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateSettings(uid),
                          child: Text(l10n.update),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final newDefaults = await ref
                            .read(rapidSettingsServiceProvider)
                            .restoreDefaults(uid);
                        ref.read(rapidSettingsStateProvider.notifier).state =
                            newDefaults;
                        setState(() {
                          _initControllers(newDefaults);
                        });
                      },
                      child: Text(
                        l10n.restoreDefaults,
                        style: const TextStyle(
                            decoration: TextDecoration.underline),
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

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? helperText,
    double fieldWidth = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Reduzido de 16.0 para 6.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14), // Reduzido de 16 para 14
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
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6), // Reduzido de 8,8 para 6,6
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0), // Reduzido de 4.0 para 2.0
              child: Text(
                helperText,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]), // Reduzido de 12 para 10
              ),
            ),
        ],
      ),
    );
  }
}
