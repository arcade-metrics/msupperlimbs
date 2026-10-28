Vou analisar a estrutura actual do projecto e propor um plano de migração do MLKit para MediaPipe com conexão nativa.

[4 tools called]

## Plano de Migração: MLKit → MediaPipe Nativo

### **Fase 1: Preparação Android Nativo**

1. **Dependências no `build.gradle`**
   - Adicionar `com.google.mediapipe:tasks-vision:latest.release`
   - Remover dependências MLKit (após migração completa)

2. **Modelos MediaPipe**
   - Os 3 ficheiros `.task` existem em `android/app/src/main/assets/`
   - Escolher modelo inicial `pose_landmarker_lite.task`

3. **Criar `PoseLandmarkerHelper.kt`** em `android/app/src/main/kotlin/`
   - Adaptar do ficheiro de referência
   - Configurar para `RunningMode.LIVE_STREAM`
   - Suportar CPU/GPU delegate
   - Implementar callbacks de resultado

### **Fase 2: MethodChannel Flutter ↔ Android**

4. **Criar canal nativo no Flutter**
   - Ver como está no jogo rapid, lá está funcionando bem. Implementar a mesma lógica adaptada ao fnose
   - Ficheiro: `lib/features/gameplay/motion/mediapipe_pose_service.dart`
   - MethodChannel: `"com.msupperlimbs/mediapipe_pose"`
   - Métodos necessários:
     - `initialize(model, delegate, confidence)`
     - `processFrame(imageData, width, height, rotation)`
     - `dispose()`

5. **Implementar lado Android**
   - Ficheiro: `android/app/src/main/kotlin/.../MediaPipePosePlugin.kt`
   - Registar canal no `MainActivity.kt`
   - Bridge entre Flutter e `PoseLandmarkerHelper`
   - Converter `CameraImage` → `MPImage`
   - Retornar landmarks normalizadas via canal

### **Fase 3: Adaptação Dart**

6. **Criar estruturas de dados**
   - `MediaPipePoseLandmark` (equivalente a `PoseLandmark` do MLKit)
   - `MediaPipePose` (equivalente a `Pose` do MLKit)
   - Mapear 33 landmarks do MediaPipe

7. **Refactor `PoseService`**
   - Trocar `google_mlkit_pose_detection` por `MediaPipePoseService`
   - Manter interface similar para retrocompatibilidade
   - Adaptar `processImage()` para usar MethodChannel

8. **Actualizar `CameraService`**
   - Remover `_toInputImage()` e conversão NV21
   - Enviar bytes directamente para canal nativo
   - Manter callbacks existentes

### **Fase 4: Overlay e Coordenadas**

9. **Implementar lógica de escala do `OverlayView.kt`**
   - Adicionar em `CoordinatesTranslator`
   - Aplicar `scaleFactor` diferente para LIVE_STREAM:
     ```dart
     // IMAGE/VIDEO: min(viewWidth/imageWidth, viewHeight/imageHeight)
     // LIVE_STREAM: max(viewWidth/imageWidth, viewHeight/imageHeight)
     ```
   - Corrigir alinhamento preview ↔ landmarks

10. **Actualizar `PosePainter`**
    - Usar novas estruturas MediaPipe
    - Aplicar nova lógica de escala
    - Manter conexões de 33 landmarks

### **Fase 5: Integração e Testes**

11. **Adaptar dependências**
    - Actualizar providers do Riverpod
    - `fnose_position_validation_service` 
    - `pose_service_provider`

12. **Testes graduais**
    - Testar inicialização
    - Testar detecção básica
    - Comparar performance MLKit vs MediaPipe
    - Validar coordenadas e alinhamento

### **Fase 6: Limpeza**

13. **Remover código antigo**
    - Dependência `google_mlkit_pose_detection`
    - Classes MLKit não utilizadas
    - Conversões YUV420/NV21 desnecessárias

---

### **Referências Chave**

- **Jogo Rapid**: verificar implementação MethodChannel já existente
- **OverlayView.kt linhas 100-111**: lógica de `scaleFactor` crítica
- **PoseLandmarkerHelper.kt linhas 153-198**: conversão `ImageProxy` → `MPImage`

### **Notas Importantes**

- MediaPipe usa 33 landmarks (MLKit: 33 também, compatível)
- Landmarks normalizadas [0,1] em ambos
- Performance esperada: melhor que MLKit
- Suporte a modelos lite/full/heavy

Pronto para começar quando quiseres [[memory:2134717]]