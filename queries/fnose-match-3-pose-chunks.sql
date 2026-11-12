-- FNose / partida 3 de 4: chunks de pose SEM os frames (leve).
-- Serve para conferir se a telemetria chegou inteira e sem buracos.
-- Troque o match_id no WHERE.

SELECT
    p.chunk_index,
    p.frame_count,
    p.first_offset_ms,
    p.last_offset_ms,
    p.last_offset_ms - p.first_offset_ms AS duracao_ms,
    p.created_at
FROM msupperlimbs_fnose_pose_chunks p
WHERE p.match_id = %(match_id)s
ORDER BY p.chunk_index;
