# MS Upper Limbs - Visão Geral do Aplicativo

## Descrição
Aplicativo Flutter para avaliação de movimentos de membros superiores através do desafio "Finger-to-Nose" (dedo-no-nariz), utilizando visão computacional e detecção de pose em tempo real.

---

## Fluxo de Autenticação

### Inicialização
1. **main.dart**: Inicializa Firebase e Riverpod
2. **Rota inicial**: `/login`

### Métodos de Login
- **Email/Senha**: `AuthRepository.signInWithEmail()`
- **Google Sign-In**: `AuthRepository.signInWithGoogle()`
- **Registo**: `AuthRepository.signUpWithEmail()`

### Pós-Autenticação
Quando o utilizador autentica:
1. Cria/atualiza perfil em Firestore (`users/{userId}`)
2. Cria configurações padrão do jogo (`fnoseSettings`, `fnoseAdvSettings`)
3. Cria sessão diária em `users/{userId}/sessions/{sessionId}`
4. Redireciona para `/home`

---

## Captura de Câmera

### Serviço Principal: `CameraService`
Localização: `lib/features/gameplay/motion/camera_service.dart`

#### Inicialização
```dart
initializeCamera(CameraLensDirection, PoseService, WidgetRef)
```

1. **Deteta câmaras disponíveis**: `availableCameras()`
2. **Seleciona resolução**: baseada no modelo do dispositivo
   - `max`, `high` (1080p), `medium` (720p), `low` (240p)
3. **Configura formato de imagem**:
   - Android: `ImageFormatGroup.nv21`
   - iOS: `ImageFormatGroup.bgra8888`

#### Stream de Imagens
- Inicia `startImageStream()` quando a câmara está pronta
- Processa cada frame (se não estiver a processar)
- Converte `CameraImage` → `InputImage` (ML Kit)
- Aplica correções de rotação e espelhamento
- Chama callback `onPoseDetected(poses, image)`

---

## Detecção de Pose

### Biblioteca: Google ML Kit Pose Detection
Dependência: `google_mlkit_pose_detection`

### Serviço: `PoseService`
Localização: `lib/features/gameplay/motion/pose_service.dart`

#### Configuração
```dart
PoseDetector(
  mode: PoseDetectionMode.stream,  // Optimizado para vídeo
  model: PoseDetectionModel.accurate  // Modelo de alta precisão
)
```

#### Landmarks Detectados
- Nariz, ombros, cotovelos, pulsos, indicadores
- Coordenadas 3D (x, y, z)
- Confiança de cada ponto

#### Processamento
1. `PoseService.detect(InputImage)` → retorna `List<Pose>`
2. `LandmarkSet.fromPose()` extrai pontos relevantes
3. `LandmarkOffsets.fromPose()` projeta para coordenadas de ecrã
4. `PoseFrameData` combina landmarks e offsets

---

## Armazenamento de Dados (Firebase Firestore)

### Estrutura de Dados

#### Utilizadores
```
users/{userId}
├── uid, name, email, createdAt, lastAccess
├── sessions/{sessionId}
│   ├── sessionId, date, createdAt, deviceModel
│   ├── logs/{logId} (registo de dispositivos)
│   └── fnose_matches/{matchId}
│       ├── dados da partida
│       ├── pose_data/{chunkId} (dados brutos de pose)
│       └── touch_data/{chunkId} (dados de toque)
└── settings/
    ├── fnoseSettings (configurações básicas)
    └── fnoseAdvSettings (configurações avançadas)
```

#### Estatísticas Globais
```
games/fnose/
├── global_stats/stats (estatísticas agregadas)
└── recent_matches/{matchId} (últimas 100 partidas)
```

### Repositórios

#### `SessionRepository`
- `createSession()`: Cria sessão diária (formato: YYYYMMDD)
- `addSessionLog()`: Regista informação do dispositivo

#### `FNoseMatchRepository`
- `createMatch()`: Cria nova partida
- `updateMatchFields()`: Atualiza campos específicos
- `savePoseData()`: Guarda dados de pose em chunks
- `saveTouchData()`: Guarda eventos de toque

#### `FNoseSettingsRepository` / `FNoseAdvSettingsRepository`
- `getFNoseSettings()`: Carrega configurações
- `saveFNoseSettings()`: Guarda configurações

#### `UserRepository`
- `createUser()`: Cria perfil
- `updateLastAccess()`: Atualiza último acesso

---

## Configurações do Jogo

### Configurações Básicas (`FNoseSettings`)
Localização: `users/{userId}/settings/fnoseSettings`

- **gameMode**: `leftHand`, `rightHand`, `bothHands`
- **totalTime**: Duração em segundos (padrão: 60)
- **showInfoVideo**: Mostrar vídeo introdutório
- **targetSize**: Escala do alvo (não implementado)

### Configurações Avançadas (`FNoseAdvSettings`)
Localização: `users/{userId}/settings/fnoseAdvSettings`

Parâmetros de detecção e validação (43 configurações):
- **Ângulos**: `elbowFlexionThreshold`, `elbowExtensionThreshold`
- **Distâncias**: `noseTouchDistanceThreshold`, `minDistanceToTarget`
- **Alinhamento**: `noseAlignmentThreshold`, `shoulderYAlignmentThreshold`
- **Alvos**: `targetNumber`, `targetScale`, `xTargetPosition`, `yTargetPosition`
- **Estabilidade**: `requiredStableTimeMs`, `stabilityThreshold`
- **Suavização**: `alpha`, `movingAverageFrames`

---

## Fluxo do Jogo Finger-to-Nose

### Navegação
```
/home → /fnose-intro → /fnose-mode → /fnose-settings → 
/fnose-adv-settings → /fnose-instructions → /fnose-game → 
/fnose-feedback → /fnose-gameover
```

### Ecrãs

1. **FNoseIntroScreen**: Introdução ao desafio
2. **FNoseModeSelectionScreen**: Escolhe mão (esquerda/direita/ambas)
3. **FNoseSettingsScreen**: Configura tempo total
4. **FNoseAdvSettingsScreen**: Ajusta parâmetros avançados
5. **FNoseInstructionsScreen**: Instruções do jogo
6. **FNoseGameScreen**: Jogo principal
7. **FNoseFeedbackScreen**: Resultado da partida
8. **FNoseGameOverScreen**: Estatísticas finais

### Jogo Principal (`FNoseGameScreen`)

#### Estados do Jogo
```dart
enum GameState {
  notStarted,      // Aguarda posicionamento
  touchNose,       // Toca no nariz
  touchTarget,     // Toca no alvo
  targetTouched    // Alvo tocado (feedback)
}
```

#### Fase Pré-Jogo
1. **Validação de Estabilidade**: Dispositivo estável por 2.5s
2. **Validação de Posicionamento**: 
   - Nariz centrado
   - Ombros alinhados
   - Cotovelo e pulso visíveis
3. **Calibração do Alvo**: Ajusta posição baseada no utilizador
4. **Contagem Regressiva**: 3, 2, 1, GO!

#### Ciclo de Jogo
1. **Estado `touchNose`**: 
   - Deteta quando dedo toca nariz
   - Valida ângulo do cotovelo em flexão
   - Transita para `touchTarget`

2. **Estado `touchTarget`**:
   - Mostra alvo na lateral
   - Deteta extensão do braço
   - Valida toque no alvo (distância < threshold)
   - Regista marca de toque
   - Incrementa contador
   - Volta para `touchNose`

#### Tracking de Movimento (`ArmMovementTracker`)
- Monitoriza ângulos do cotovelo em tempo real
- Deteta flexão (< 30°) e extensão (> 160°)
- Suaviza leituras com média móvel
- Valida transições de movimento

#### Registo de Dados
Durante o jogo, regista:
- **Pose Data**: Landmarks a cada frame (JSON)
- **Touch Logs**: Eventos de toque com timestamp
- **Métricas**: Ângulos máximos, distâncias, precisão

#### Fim do Jogo
1. Timer termina ou utilizador sai
2. Guarda dados em Firestore (chunks de 1MB)
3. Calcula estatísticas da partida
4. Atualiza estatísticas globais
5. Navega para `/fnose-feedback`

---

## Tecnologias Principais

### Framework e Estado
- **Flutter**: Framework UI multiplataforma
- **Riverpod**: Gestão de estado reativa
- **GoRouter**: Navegação declarativa

### Firebase
- **Firebase Auth**: Autenticação
- **Cloud Firestore**: Base de dados NoSQL
- **Firebase Core**: Inicialização

### Visão Computacional
- **camera**: Acesso à câmara do dispositivo
- **google_mlkit_pose_detection**: Detecção de pose ML
- **google_mlkit_commons**: Tipos comuns do ML Kit

### Utilitários
- **sensors_plus**: Acelerómetro (detecção de estabilidade)
- **shared_preferences**: Armazenamento local
- **path_provider**: Caminhos de ficheiros
- **permission_handler**: Permissões
- **fl_chart**: Gráficos de estatísticas

---

## Fluxo de Dados Completo

```
1. Login → Firebase Auth
         → Cria/carrega User em Firestore
         → Cria Session diária
         → Cria Settings (se não existirem)

2. Inicia Jogo → Carrega Settings
              → Inicializa Camera
              → Inicia PoseDetector

3. Durante Jogo → Camera stream → CameraImage
                              → InputImage (ML Kit)
                              → PoseDetector.processImage()
                              → List<Pose>
                              → LandmarkSet + LandmarkOffsets
                              → ArmMovementTracker
                              → Valida toques
                              → Regista eventos

4. Fim do Jogo → Agrupa dados em chunks
               → Guarda no Firestore:
                 - Match document
                 - Pose data subcollection
                 - Touch data subcollection
               → Calcula estatísticas
               → Atualiza global stats
               → Mostra feedback
```

---

## Notas de Implementação

### Orientação do Ecrã
- **Portrait**: Login, Home, Menus
- **Landscape**: Jogo (detecção de pose)

### Resolução de Câmara
Ajustada automaticamente por modelo:
- Dispositivos potentes: `high` ou `max`
- Dispositivos médios: `medium`
- Dispositivos baixos: `low`

### Otimizações
- Processamento assíncrono de frames
- Flag `_isProcessing` previne sobrecarga
- Dados guardados em chunks (limite Firestore: 1MB)
- Stream throttling e debouncing

### Suporte Multiplataforma
- Android: Formato NV21, rotação específica
- iOS: Formato BGRA8888, espelhamento de câmara frontal

---

## Estrutura de Pastas

```
lib/
├── core/                          # Funcionalidades base
│   ├── application/               # Providers globais
│   ├── domain/                    # Serviços de domínio
│   ├── presentation/              # Rotas, guards, widgets
│   ├── shared/                    # Constantes, tema
│   └── utils/                     # Utilitários
├── features/                      # Funcionalidades por módulo
│   ├── auth/                      # Autenticação
│   │   ├── application/           # Estado
│   │   ├── data/                  # Repositórios
│   │   ├── domain/                # Serviços
│   │   └── presentation/          # UI
│   ├── fnose/                     # Finger-to-Nose
│   │   ├── application/           # Providers e estado
│   │   ├── data/                  # Modelos e repositórios
│   │   │   ├── models/            # Entidades
│   │   │   └── repositories/      # Firestore
│   │   ├── domain/                # Serviços de negócio
│   │   ├── motion/                # Validação de pose
│   │   └── presentation/          # Ecrãs e widgets
│   ├── gameplay/                  # Sistema de jogo base
│   │   ├── application/           # Estado de sessão
│   │   ├── data/                  # Modelos de sessão
│   │   ├── domain/                # Serviços de sessão
│   │   ├── motion/                # Câmara e pose
│   │   └── presentation/          # Widgets reutilizáveis
│   └── user/                      # Gestão de utilizador
├── l10n/                          # Localização (en, pt)
├── presentation/                  # UI global
└── main.dart                      # Entry point
```

---

## Dependências Principais (pubspec.yaml)

```yaml
camera: ^0.11.1                           # Captura de câmara
google_mlkit_pose_detection: ^0.14.0      # Detecção de pose
firebase_core: ^3.12.1                    # Firebase
firebase_auth: ^5.5.1                     # Autenticação
cloud_firestore: ^5.6.5                   # Base de dados
flutter_riverpod: ^2.6.1                  # Estado
go_router: ^14.8.1                        # Navegação
sensors_plus: ^6.1.1                      # Sensores
fl_chart: ^1.0.0                          # Gráficos
```

---

**Versão**: 1.1.0+3  
**Última atualização**: 2025-10-01

