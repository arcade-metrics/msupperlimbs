enum FnoseAdvSection {
  stability('Fase 1 — Estabilidade'),
  inclination('Fase 2 — Inclinação do dispositivo'),
  nose('Fase 3 — Alinhamento do nariz'),
  finger('Fase 4 — Calibração do indicador'),
  target('Alvo'),
  arm('Tracking do braço');

  const FnoseAdvSection(this.label);
  final String label;
}

enum FnoseAdvSpace {
  kinematics('Cinemática MediaPipe'),
  screen('Ecrã normalizado'),
  time('Tempo'),
  angle('Ângulo');

  const FnoseAdvSpace(this.label);
  final String label;
}

class FnoseAdvField {
  const FnoseAdvField({
    required this.key,
    required this.section,
    required this.label,
    required this.description,
    required this.defaultValue,
    this.space = FnoseAdvSpace.kinematics,
    this.unit = '',
    this.isInteger = false,
  });

  final String key;
  final FnoseAdvSection section;
  final String label;
  final String description;
  final num defaultValue;
  final FnoseAdvSpace space;
  final String unit;
  final bool isInteger;
}

/// Dicionário único dos ajustes apresentados ao operador.
const fnoseAdvCatalog = <FnoseAdvField>[
  FnoseAdvField(
    key: 'stability_threshold',
    section: FnoseAdvSection.stability,
    label: 'Sensibilidade a movimento',
    description:
        'Movimento máximo permitido para considerar o dispositivo parado. Menor = mais rigoroso.',
    defaultValue: 0.5,
  ),
  FnoseAdvField(
    key: 'required_stable_time_ms',
    section: FnoseAdvSection.stability,
    label: 'Tempo parado',
    description: 'Tempo contínuo sem movimento antes de validar a superfície.',
    defaultValue: 2500,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'stability_grace_ms',
    section: FnoseAdvSection.stability,
    label: 'Tolerância a vibração',
    description:
        'Tempo de movimento tolerado antes de voltar à fase de estabilidade. Evita reinícios por vibração momentânea.',
    defaultValue: 400,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'alpha',
    section: FnoseAdvSection.stability,
    label: 'Suavização do sensor',
    description: 'Peso da leitura mais recente no filtro de movimento (0 a 1).',
    defaultValue: 0.3,
  ),
  FnoseAdvField(
    key: 'roll_min_deg',
    section: FnoseAdvSection.inclination,
    label: 'Roll mínimo',
    description: 'Limite lateral mínimo aceito.',
    defaultValue: -8,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'roll_max_deg',
    section: FnoseAdvSection.inclination,
    label: 'Roll máximo',
    description: 'Limite lateral máximo aceito.',
    defaultValue: 8,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'pitch_min_deg',
    section: FnoseAdvSection.inclination,
    label: 'Pitch mínimo',
    description: 'Limite mínimo de inclinação para frente/trás.',
    defaultValue: -12,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'pitch_max_deg',
    section: FnoseAdvSection.inclination,
    label: 'Pitch máximo',
    description: 'Limite máximo de inclinação para frente/trás.',
    defaultValue: 12,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'tilt_hold_ms',
    section: FnoseAdvSection.inclination,
    label: 'Tempo de confirmação da inclinação',
    description: 'Tempo dentro dos limites antes de avançar.',
    defaultValue: 700,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'x_nose_alignment',
    section: FnoseAdvSection.nose,
    label: 'Posição horizontal da marca do nariz',
    description: 'Coordenada horizontal normalizada da marca (0 a 1).',
    defaultValue: 0.7,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'y_nose_alignment',
    section: FnoseAdvSection.nose,
    label: 'Posição vertical da marca do nariz',
    description: 'Coordenada vertical normalizada da marca (0 a 1).',
    defaultValue: 0.3,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'nose_alignment_target_radius',
    section: FnoseAdvSection.nose,
    label: 'Tamanho da marca do nariz',
    description:
        'Raio da marca, em fração da largura do ecrã. É também a área aceite: o que se vê é o que valida.',
    defaultValue: 0.07,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'nose_hold_ms',
    section: FnoseAdvSection.nose,
    label: 'Tempo de alinhamento do nariz',
    description: 'Tempo contínuo com o nariz dentro da marca.',
    defaultValue: 1200,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'finger_stability',
    section: FnoseAdvSection.finger,
    label: 'Tolerância de movimento do indicador',
    description:
        'Margem além da borda do alvo, como fração do menor lado do ecrã, '
        'antes de considerar o dedo fora. Absorve o tremor da landmark.',
    defaultValue: 0.05,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'finger_smoothing',
    section: FnoseAdvSection.finger,
    label: 'Suavização do indicador',
    description:
        'Peso da leitura mais recente no filtro da ponta do dedo (0 a 1). '
        'Menor = mais estável e mais lento a reagir.',
    defaultValue: 0.35,
  ),
  FnoseAdvField(
    key: 'finger_grace_ms',
    section: FnoseAdvSection.finger,
    label: 'Tolerância a saídas do alvo',
    description:
        'Tempo fora do alvo tolerado antes de reiniciar a contagem. '
        'Evita reinícios por saltos momentâneos da landmark.',
    defaultValue: 400,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'finger_hold_ms',
    section: FnoseAdvSection.finger,
    label: 'Tempo do indicador no alvo',
    description: 'Tempo contínuo com a ponta do indicador dentro do alvo.',
    defaultValue: 1200,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'x_target_position',
    section: FnoseAdvSection.target,
    label: 'Posição horizontal do alvo',
    description: 'Distância normalizada do alvo à borda lateral.',
    defaultValue: 0.1,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'y_target_position',
    section: FnoseAdvSection.target,
    label: 'Posição vertical do alvo',
    description: 'Coordenada vertical normalizada do centro do alvo.',
    defaultValue: 0.5,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'target_scale',
    section: FnoseAdvSection.target,
    label: 'Tamanho do alvo',
    description: 'Escala do alvo em relação ao menor lado da tela.',
    defaultValue: 0.45,
    space: FnoseAdvSpace.screen,
  ),
  FnoseAdvField(
    key: 'elbow_flexion_threshold',
    section: FnoseAdvSection.arm,
    label: 'Ângulo de flexão do cotovelo',
    description:
        'Ângulo máximo para considerar o braço flexionado no toque do nariz.',
    defaultValue: 45,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'elbow_extension_threshold',
    section: FnoseAdvSection.arm,
    label: 'Ângulo de extensão do cotovelo',
    description:
        'Reservado (legado). O ciclo actual só valida nariz e alvo.',
    defaultValue: 160,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'nose_touch_distance_threshold',
    section: FnoseAdvSection.arm,
    label: 'Distância de toque no nariz',
    description:
        'Distância máxima entre pulso e nariz para armar o spark (espaço MediaPipe).',
    defaultValue: 0.28,
  ),
  FnoseAdvField(
    key: 'spark_fire_ms',
    section: FnoseAdvSection.arm,
    label: 'Duração do feedback do spark',
    description: 'Tempo do flash verde no alvo após um hit válido.',
    defaultValue: 450,
    space: FnoseAdvSpace.time,
    unit: 'ms',
    isInteger: true,
  ),
  FnoseAdvField(
    key: 'min_angle_change_for_elbow_detection',
    section: FnoseAdvSection.arm,
    label: 'Variação mínima do cotovelo',
    description: 'Reservado (legado). Já não entra na contagem de sparks.',
    defaultValue: 4,
    space: FnoseAdvSpace.angle,
    unit: '°',
  ),
  FnoseAdvField(
    key: 'landmark_buffer_size',
    section: FnoseAdvSection.arm,
    label: 'Amostras do tracking',
    description: 'Quantidade de amostras usadas para suavizar landmarks.',
    defaultValue: 3,
    isInteger: true,
  ),
];
