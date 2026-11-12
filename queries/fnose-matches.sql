-- FNose: lista das partidas gravadas (uma linha por partida, mais recentes primeiro).
-- Partida sem métricas (colunas fm.* NULL) = criada mas não finalizada / upload pendente.

SELECT
    m.id                AS match_id,
    u.name              AS jogador,
    m.status,
    m.started_at,
    m.ended_at,
    s.game_mode,
    s.app_version,
    s.device_model,
    fm.total_left_sparks,
    fm.total_right_sparks,
    fm.total_sparks,
    fm.avg_distance,
    fm.avg_angle,
    fm.is_valid_match,
    (SELECT count(*)                     FROM msupperlimbs_fnose_events e      WHERE e.match_id = m.id) AS eventos,
    (SELECT coalesce(sum(frame_count),0) FROM msupperlimbs_fnose_pose_chunks p WHERE p.match_id = m.id) AS frames_pose
FROM matches m
JOIN msupperlimbs_match_snapshots s           ON s.match_id = m.id
JOIN users u                                  ON u.id = s.user_id
LEFT JOIN msupperlimbs_fnose_match_metrics fm ON fm.match_id = m.id
WHERE s.game_slug = 'msupperlimbs-fnose'
  AND m.deleted_at IS NULL
ORDER BY m.started_at DESC
LIMIT 100;
