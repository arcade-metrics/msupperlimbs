// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get common_back => 'Voltar';

  @override
  String get common_email => 'E-mail';

  @override
  String get common_password => 'Senha';

  @override
  String get common_name => 'Nome';

  @override
  String get common_loading => 'Carregando...';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_retry => 'Tentar de novo';

  @override
  String get common_continue => 'Continuar';

  @override
  String common_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get app_title => 'Avaliação de Membros Superiores EM';

  @override
  String get app_name => 'MS Upper Limbs';

  @override
  String app_versionLabel(String version) {
    return 'MS Upper Limbs v$version';
  }

  @override
  String get auth_login => 'Entrar';

  @override
  String get auth_signup => 'Cadastrar';

  @override
  String get auth_createAccount => 'Criar conta';

  @override
  String get auth_noAccountQuestion => 'Não tem conta? Criar conta';

  @override
  String get auth_haveAccountQuestion => 'Já tem conta? Entrar';

  @override
  String get auth_nameRequired => 'Informe o nome';

  @override
  String get auth_emailInvalid => 'Email inválido';

  @override
  String get auth_passwordRequired => 'Informe a senha';

  @override
  String get auth_passwordPolicy =>
      'Mínimo 8 caracteres, com 1 letra maiúscula e 1 número';

  @override
  String get auth_emailInUse =>
      'Este e-mail já está cadastrado. Entre com ele.';

  @override
  String get auth_loginSuccessful => 'Login realizado com sucesso!';

  @override
  String get auth_invalidCredentials => 'E-mail ou senha inválidos.';

  @override
  String get auth_accountCreatedSuccess => 'Conta criada com sucesso!';

  @override
  String get auth_failedToCreateAccount => 'Falha ao criar conta.';

  @override
  String get auth_missingToken => 'Sem token de autenticação';

  @override
  String get error_validation =>
      'Há campos inválidos. Confira e tente de novo.';

  @override
  String get error_sessionExpired => 'A sessão expirou. Entre de novo.';

  @override
  String get error_accountInactive => 'Esta conta está inativa.';

  @override
  String get error_network =>
      'Sem conexão com o servidor. Verifique a internet e tente de novo.';

  @override
  String get error_server =>
      'O servidor está indisponível. Tente de novo em instantes.';

  @override
  String get error_generic => 'Algo deu errado. Tente de novo.';

  @override
  String get home_title => 'Início';

  @override
  String get home_fingerToNoseChallenge => 'Desafio Dedo-ao-Nariz';

  @override
  String get home_rapidChallenge => 'Rapid Challenge';

  @override
  String get home_mediapipeDebug => 'MediaPipe Debug';

  @override
  String get home_changeUser => 'Trocar Usuário';

  @override
  String get home_exit => 'Sair';

  @override
  String get home_noUserLoggedIn => 'Nenhum usuário logado';

  @override
  String get camera_permissionDenied => 'Permissão de câmera negada';

  @override
  String get camera_noneAvailable => 'Nenhuma câmera disponível';

  @override
  String get fnose_intro_title => 'Dedo-ao-Nariz';

  @override
  String fnose_intro_errorLoadingSettings(String error) {
    return 'Erro ao carregar settings: $error';
  }

  @override
  String get fnose_intro_instructionVideo => 'Vídeo de instrução';

  @override
  String get fnose_intro_notImplemented => '(ainda não implementado)';

  @override
  String get fnose_intro_hideOnNextTime => 'Não mostrar da próxima vez';

  @override
  String get fnose_intro_changeGameMode => 'Alterar modo de jogo';

  @override
  String get fnose_intro_start => 'START';

  @override
  String get fnose_intro_settings => 'Settings';

  @override
  String get fnose_mode_title => 'Modo de jogo';

  @override
  String get fnose_mode_chooseGameMode => 'Escolha o modo';

  @override
  String get fnose_mode_leftHandOnly => 'Apenas mão esquerda';

  @override
  String get fnose_mode_leftHandOnlyDesc =>
      'Toque no nariz e no alvo com a mão esquerda';

  @override
  String get fnose_mode_rightHandOnly => 'Apenas mão direita';

  @override
  String get fnose_mode_rightHandOnlyDesc =>
      'Toque no nariz e no alvo com a mão direita';

  @override
  String get fnose_mode_continue => 'Continuar';

  @override
  String get fnose_settings_title => 'FNose Settings';

  @override
  String get fnose_settings_advancedSettings => 'Configurações avançadas';

  @override
  String get fnose_settings_showInstructionVideo =>
      'Mostrar vídeo de instrução';

  @override
  String get fnose_settings_totalTime => 'Tempo total (s)';

  @override
  String get fnose_settings_targetSize => 'Tamanho do alvo (×)';

  @override
  String get fnose_settings_settingsUpdated => 'Settings guardados';

  @override
  String get fnose_settings_defaultsRestored => 'Defaults restaurados';

  @override
  String fnose_settings_saveError(String error) {
    return 'Erro ao guardar: $error';
  }

  @override
  String get restoreDefaults => 'Restaurar defaults';

  @override
  String get fnose_adv_settings_title => 'Configurações avançadas';

  @override
  String get fnose_adv_settings_updated =>
      'Configurações avançadas atualizadas';

  @override
  String get fnose_adv_section_arm => 'Tracking do braço';

  @override
  String get fnose_adv_section_target => 'Alvo';

  @override
  String get fnose_adv_section_position => 'Posicionamento do corpo';

  @override
  String get fnose_adv_section_nose => 'Alinhamento do nariz';

  @override
  String get fnose_adv_section_stability => 'Estabilidade do dispositivo';

  @override
  String get fnose_pregame_keepStill => 'Mantenha o telemóvel estável';

  @override
  String get fnose_pregame_tiltAndStill =>
      'Incline o telemóvel (~90°) e mantenha estável';

  @override
  String get fnose_pregame_deviceStable => 'Dispositivo estável — mantenha…';

  @override
  String get fnose_pregame_motionDetected =>
      'Movimento detetado — volte a estabilizar';

  @override
  String get fnose_pregame_positionPose =>
      'Posicione o tronco e o nariz no centro da câmara';

  @override
  String get fnose_pregame_poseDetected =>
      'Pose detetada — mantenha a posição…';

  @override
  String get fnose_pregame_poseLost => 'Pose perdida — volte a posicionar';

  @override
  String get fnose_pregame_calibrating => 'A calibrar alvo…';

  @override
  String get fnose_pregame_surface =>
      'Mantenha o dispositivo numa superfície estável';

  @override
  String get fnose_pregame_raiseRight => 'Suba o lado direito';

  @override
  String get fnose_pregame_raiseLeft => 'Suba o lado esquerdo';

  @override
  String get fnose_pregame_tiltForward => 'Incline mais para frente';

  @override
  String get fnose_pregame_tiltBack => 'Incline mais para trás';

  @override
  String get fnose_pregame_rollOk => 'Nivelamento lateral correto — mantenha…';

  @override
  String get fnose_pregame_pitchOk => 'Inclinação correta — mantenha…';

  @override
  String get fnose_pregame_alignNose => 'Alinhe o nariz dentro da marcação';

  @override
  String get fnose_pregame_alignFinger =>
      'Posicione a ponta do dedo indicador no centro do alvo';

  @override
  String get fnose_game_saving => 'A guardar partida…';

  @override
  String get fnose_feedback_title => 'FNose Feedback';

  @override
  String get fnose_feedback_noResult => 'Sem resultado';

  @override
  String fnose_feedback_sparksCount(int count) {
    return '$count sparks';
  }

  @override
  String fnose_feedback_summary(int seconds, int left, int right) {
    return '${seconds}s · L $left · R $right';
  }

  @override
  String fnose_feedback_mode(String mode) {
    return 'Modo: $mode';
  }

  @override
  String fnose_feedback_avgAngle(String angle) {
    return 'Ângulo médio: $angle°';
  }

  @override
  String fnose_feedback_saved(String id) {
    return 'Guardado · match $id…';
  }

  @override
  String fnose_feedback_saveFailed(String error) {
    return 'Falha ao guardar: $error';
  }

  @override
  String get fnose_feedback_notSaved => 'Não guardado';

  @override
  String fnose_feedback_logs(int touches, int pose) {
    return 'logs: $touches touches · $pose pose';
  }

  @override
  String get fnose_gameover_title => 'FNose Game Over';

  @override
  String get fnose_gameover_finished => 'Partida terminada';

  @override
  String fnose_gameover_sparksInTime(int count, int seconds) {
    return '$count sparks em ${seconds}s';
  }

  @override
  String fnose_gameover_session(String id) {
    return 'Sessão $id…';
  }

  @override
  String get fnose_gameover_playAgain => 'Jogar outra vez';

  @override
  String get fnose_gameover_home => 'Início';
}
