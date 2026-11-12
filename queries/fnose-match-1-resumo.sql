-- FNose / partida 1 de 4: resumo (partida + jogador + métricas + contexto do device).
-- Uma linha. Troque o match_id no WHERE.

SELECT
    m.id            AS match_id,
    u.name          AS jogador,
    m.status,
    m.started_at,
    m.ended_at,
    s.game_mode,
    -- métricas
    fm.total_left_sparks,
    fm.total_right_sparks,
    fm.total_sparks,
    fm.avg_distance,
    fm.avg_angle,
    fm.is_valid_match,
    -- device / contexto
    s.app_version,
    s.platform,
    s.device_model,
    s.os_version,
    s.locale,
    s.screen_width,  s.screen_height,
    s.image_width,   s.image_height,
    s.camera_lens,
    s.data_contract_version,
    s.context_recorded_at,
    s.calibration_run_id,
    -- configurações congeladas (JSON: clique na célula para expandir)
    s.settings          AS settings,
    s.preset_settings   AS preset_settings,
    s.models,
    s.preview,
    m.level_config_snapshot,
    m.state
FROM matches m
LEFT JOIN msupperlimbs_match_snapshots s      ON s.match_id = m.id
LEFT JOIN users u                             ON u.id = s.user_id
LEFT JOIN msupperlimbs_fnose_match_metrics fm ON fm.match_id = m.id
WHERE m.id = %(match_id)s;
