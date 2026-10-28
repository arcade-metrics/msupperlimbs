# Camera Image Configuration Setup

## Sistema de configuração por dispositivo implementado

### 1. Estrutura criada

- **Modelo de dados:** `lib/core/models/camera_image_config.dart`
- **Serviço:** `lib/core/services/camera_config_service.dart`
- **Script de população:** `lib/core/services/populate_camera_configs.dart`

### 2. Como funciona

#### Inicialização automática:
1. Ao inicializar câmera, detecta modelo do dispositivo (`Build.MODEL`)
2. Busca configuração específica no Firebase
3. Se não encontrar, usa `GLOBAL_ANDROID` ou `GLOBAL_IOS`
4. Faz cache local em SharedPreferences
5. Aplica transformações (rotação + espelhamento) ao bitmap **antes** de enviar ao MediaPipe

#### Fluxo:
```
CameraImage → YUV bytes → Bitmap → [Rotate + Mirror] → MediaPipe → Landmarks
```

### 3. Popular Firebase (executar UMA vez)

Adicionar no `main()` temporariamente ou criar botão de debug:

```dart
import 'package:msupperlimbs/core/services/populate_camera_configs.dart';

// Executar UMA vez ao iniciar app
await PopulateCameraConfigs.populate();
```

Isto cria:
- `camera_image_configs/GLOBAL_ANDROID`
- `camera_image_configs/GLOBAL_IOS`

Valores actuais (sem transformações):
```json
{
  "device_model": "GLOBAL_ANDROID",
  "rotation_degrees": 0,
  "mirror_horizontal": false,
  "mirror_vertical": false
}
```

### 4. Adicionar dispositivo específico

#### Via Firebase Console:
1. Ir a Firebase → Firestore
2. Colecção: `camera_image_configs`
3. Criar documento com ID = modelo do dispositivo (ex: `SM-A515F`)
4. Campos:
   - `device_model`: "SM-A515F"
   - `rotation_degrees`: 270 (0, 90, 180, 270)
   - `mirror_horizontal`: true/false
   - `mirror_vertical`: true/false

#### Via código:
```dart
import 'package:msupperlimbs/core/services/populate_camera_configs.dart';
import 'package:msupperlimbs/core/models/camera_image_config.dart';

const config = CameraImageConfig(
  deviceModel: 'SM-A515F',
  rotationDegrees: 270,
  mirrorHorizontal: true,
  mirrorVertical: false,
);

await PopulateCameraConfigs.addDeviceConfig(config);
```

### 5. Testar no dispositivo

#### Ver qual configuração está a usar:
Os logs mostram automaticamente:
```
📱 Device model detected: SM-A515F
📸 Using camera config: CameraImageConfig(model: SM-A515F, rotation: 270°, mirrorH: true, mirrorV: false)
```

#### Recarregar configs sem reiniciar app:
```dart
await CameraConfigService.instance.reload();
```

### 6. Debugging

#### Ver modelo do dispositivo actual:
```dart
import 'package:device_info_plus/device_info_plus.dart';

final deviceInfo = DeviceInfoPlugin();
final androidInfo = await deviceInfo.androidInfo;
print('Device model: ${androidInfo.model}');
```

#### Testar diferentes rotações:
- **0°:** sem rotação
- **90°:** roda anti-horário
- **180°:** roda 180°
- **270°:** roda horário (equivale a -90°)

#### Testar espelhamento:
- `mirror_horizontal: true` → espelha esquerda/direita
- `mirror_vertical: true` → espelha cima/baixo

### 7. Rollback

Se algo correr mal:
1. Apagar documento específico do Firebase
2. App volta automaticamente para `GLOBAL_ANDROID`/`GLOBAL_IOS`
3. Ou limpar cache: `SharedPreferences.remove('cached_camera_config')`

### 8. Notas importantes

- ✅ Configurações podem ser alteradas no Firebase sem rebuild do app
- ✅ Cache local garante funcionamento offline
- ✅ Fallback automático para GLOBAL se Firebase falhar
- ✅ Zero impacto em performance (transformação só se necessário)
- ⚠️ Rotação aumenta ligeiramente processamento, mas necessário para detecção

### 9. Próximos passos

1. Executar `populate()` para criar configs default
2. Testar em dispositivo actual (verificar logs)
3. Se landmarks não detectam, ajustar rotação (testar 0, 90, 180, 270)
4. Se detectam mas desalinhados, ajustar espelhamento
5. Quando funcionar, criar documento específico no Firebase


