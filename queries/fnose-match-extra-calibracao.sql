-- FNose / extra: calibração que precedeu a partida (se houver).
-- Troque o match_id no WHERE. Sem linha = partida sem calibração associada.

SELECT cr.*
FROM msupperlimbs_match_snapshots s
JOIN calibration_runs cr ON cr.id = s.calibration_run_id
WHERE s.match_id = %(match_id)s;
