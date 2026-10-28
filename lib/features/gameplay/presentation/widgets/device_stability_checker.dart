import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import '../../application/device_stability_service_provider.dart';
import '../../motion/device_stability_service.dart';

class DeviceStabilityChecker extends ConsumerStatefulWidget {
  final Function? onGameStart;
  final bool suppressCountdown;

  const DeviceStabilityChecker({
    super.key,
    this.onGameStart,
    this.suppressCountdown = true,
  });

  @override
  ConsumerState<DeviceStabilityChecker> createState() =>
      _DeviceStabilityCheckerState();
}

class _DeviceStabilityCheckerState
    extends ConsumerState<DeviceStabilityChecker> {
  // Messages - will be replaced with l10n
  String get _stablePositionMessage => AppLocalizations.of(context)!.stability_stablePositionFound;
  String get _tiltUpMessage => AppLocalizations.of(context)!.stability_tiltPhoneUp;
  String get _tiltDownMessage => AppLocalizations.of(context)!.stability_tiltPhoneDown;
  String get _keepStillMessage => AppLocalizations.of(context)!.stability_keepDeviceStable;
  String get _goMessage => AppLocalizations.of(context)!.stability_go;

  // Style constants
  static const double _messageFontSize = 24.0;
  static const double _countdownFontSize = 36.0;
  static const double _progressBarWidth = 200.0;
  static const double _progressBarHeight = 8.0;
  static const EdgeInsets _containerPadding =
      EdgeInsets.symmetric(vertical: 16, horizontal: 24);
  static const EdgeInsets _messagePadding =
      EdgeInsets.symmetric(vertical: 12, horizontal: 16);

  // Shadow effect
  static const Shadow _textShadow = Shadow(
    blurRadius: 8,
    color: Colors.black,
    offset: Offset(2, 2),
  );

  // State
  int? _countdown;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    _countdown = 3;
  }

  void _startCountdown() {
    if (widget.suppressCountdown) return;

    if (!_isCountingDown) {
      setState(() {
        _isCountingDown = true;
        _countdown = 3;
      });

      _scheduleCountdown();
    }
  }

  void _scheduleCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isCountingDown) {
        setState(() => _countdown = 2);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && _isCountingDown) {
            setState(() => _countdown = 1);
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _isCountingDown) {
                final stabilityService =
                    ref.read(deviceStabilityServiceProvider);
                final currentAngle = stabilityService.currentAngle;
                final isCorrectAngle =
                    currentAngle >= 70 && currentAngle <= 120;
                final currentMessage =
                    _getMessage(stabilityService.isStable, currentAngle);

                if (stabilityService.isStable &&
                    isCorrectAngle &&
                    currentMessage == _stablePositionMessage) {
                  setState(() => _countdown = 0);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _isCountingDown) {
                      final finalAngle = stabilityService.currentAngle;
                      final isStillCorrectAngle =
                          finalAngle >= 70 && finalAngle <= 120;
                      final isStillStable = stabilityService.isStable;
                      final finalMessage =
                          _getMessage(isStillStable, finalAngle);

                      if (isStillStable &&
                          isStillCorrectAngle &&
                          finalMessage == _stablePositionMessage) {
                        widget.onGameStart?.call();
                      } else {
                        _resetCountdown();
                      }
                    }
                  });
                } else {
                  _resetCountdown();
                }
              }
            });
          }
        });
      }
    });
  }

  void _resetCountdown() {
    if (_isCountingDown) {
      setState(() {
        _isCountingDown = false;
        _countdown = 3;
      });
    }
  }

  String _getMessage(bool isStable, double angle) {
    if (!isStable) {
      return _keepStillMessage;
    }

    if (angle < 70) {
      return _tiltUpMessage;
    }

    if (angle > 120) {
      return _tiltDownMessage;
    }

    return _stablePositionMessage;
  }

  Color _getMessageColor(bool isStable, double angle) {
    if (!isStable) {
      return Colors.white;
    }

    if (angle < 70 || angle > 120) {
      return Colors.red;
    }

    return Colors.green;
  }

  Widget _buildStabilityProgress(DeviceStabilityService service) {
    final currentTime = service.currentStableTime;
    final requiredTime = service.requiredStableTime;
    final progress = (currentTime.inMilliseconds / requiredTime.inMilliseconds)
        .clamp(0.0, 1.0);
    final remainingSeconds =
        ((requiredTime - currentTime).inMilliseconds / 1000).ceil().clamp(0, 4);

    return Column(
      children: [
        const SizedBox(height: 16),
        if (remainingSeconds > 0)
          Text(
            '$remainingSeconds...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: _messageFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: _progressBarWidth,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: _progressBarHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildGameCountdown() {
    String text = _countdown == 0 ? _goMessage : '$_countdown...';
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Text(
        text,
        style: TextStyle(
          color: _countdown == 0 ? Colors.green : Colors.white,
          fontSize: _countdownFontSize,
          fontWeight: FontWeight.bold,
          shadows: const [_textShadow],
        ),
      ),
    );
  }

  Widget _buildMessage(String message, Color messageColor) {
    return Container(
      padding: _messagePadding,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.7 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: messageColor.withAlpha((0.5 * 255).round()),
          width: 2,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: _messageFontSize,
          fontWeight: FontWeight.bold,
          color: messageColor,
          shadows: const [_textShadow],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DeviceStabilityService stabilityService =
        ref.read(deviceStabilityServiceProvider);
    final stabilityAsync = ref.watch(deviceStabilityProvider);
    final angleAsync = ref.watch(deviceAngleProvider);

    return stabilityAsync.when(
      data: (isStable) {
        return angleAsync.when(
          data: (angle) {
            final message = _getMessage(isStable, angle);
            final messageColor = _getMessageColor(isStable, angle);
            final isCorrectAngle = angle >= 70 && angle <= 120;
            final currentTime = stabilityService.currentStableTime;
            final requiredTime = stabilityService.requiredStableTime;
            final isCountingDown = currentTime > Duration.zero &&
                currentTime < requiredTime &&
                isStable &&
                isCorrectAngle &&
                message == _stablePositionMessage;

            if (isStable && isCorrectAngle && !widget.suppressCountdown) {
              _startCountdown();
            }

            // Only show countdown and progress when both stable and correct angle
            final shouldShowProgress = isStable && isCorrectAngle;
            final shouldShowCountdown = _isCountingDown &&
                isCorrectAngle &&
                message == _stablePositionMessage;

            return Container(
              width: double.infinity,
              padding: _containerPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMessage(message, messageColor),
                  if (!isStable && !isCorrectAngle)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  if (!isStable && isCorrectAngle)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  if (shouldShowProgress)
                    _buildStabilityProgress(stabilityService),
                  if (shouldShowCountdown) _buildGameCountdown(),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              '${AppLocalizations.of(context)!.stability_errorCheckingAngle} $error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      error: (error, stack) => Center(
        child: Text(
          '${AppLocalizations.of(context)!.stability_errorCheckingStability} $error',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
