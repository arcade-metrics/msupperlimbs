import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';

class FnoseMatchRepository {
  FnoseMatchRepository(this._api);

  final ApiClient _api;

  Future<FnoseMatchSaveResponse> saveMatch({
    required String accessToken,
    required FnoseGameResult result,
    String? deviceModel,
  }) async {
    final json = await _api.postJson(
      '/fnose/matches',
      accessToken: accessToken,
      body: result.toMatchPayload(deviceModel: deviceModel),
    );
    return FnoseMatchSaveResponse.fromJson(json);
  }
}
