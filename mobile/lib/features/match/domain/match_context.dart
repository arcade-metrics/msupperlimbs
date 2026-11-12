import 'package:msupperlimbs/core/config/app_info.dart';
import 'package:msupperlimbs/features/motion/domain/motion_data_contract.dart';

/// Body of `POST /{slug}/matches/{id}/context` (camelCase, all optional).
Map<String, dynamic> buildMatchContext({
  int? screenWidth,
  int? screenHeight,
  int? imageWidth,
  int? imageHeight,
  String? cameraLens,
  Map<String, double>? preview,
}) => {
  'appVersion': AppInfo.version,
  'platform': AppInfo.platform,
  'osVersion': AppInfo.osVersion,
  'locale': AppInfo.locale,
  'screenWidth': ?screenWidth,
  'screenHeight': ?screenHeight,
  'imageWidth': ?imageWidth,
  'imageHeight': ?imageHeight,
  'cameraLens': ?cameraLens,
  'dataContractVersion': MotionDataContract.version,
  'preview': ?preview,
};

/// `client_meta` of the match finish (snake_case, shared route).
Map<String, dynamic> buildClientMeta() => {
  'app_version': AppInfo.version,
  'platform': AppInfo.platform,
  'locale': AppInfo.locale,
};
