import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

class RapidMatchRepository {
  RapidMatchRepository(this._api);

  final ApiClient _api;

  Future<RapidMatchSaveResponse> saveMatch({
    required String accessToken,
    required RapidGameResult result,
    String? deviceModel,
  }) async {
    final json = await _api.postJson(
      '/rapid/matches',
      accessToken: accessToken,
      body: result.toMatchPayload(deviceModel: deviceModel),
    );
    return RapidMatchSaveResponse.fromJson(json);
  }
}
