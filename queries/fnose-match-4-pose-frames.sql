-- FNose / partida 4 de 4: frames de pose (landmarks), um frame por linha.
-- PESADA: até ~500 frames por chunk. Use LIMIT/OFFSET ou filtre por chunk_index.
-- Troque o match_id no WHERE.

SELECT
    p.chunk_index,
    f.ordinality - 1 AS frame_index,
    f.frame          AS frame_json
FROM msupperlimbs_fnose_pose_chunks p
CROSS JOIN LATERAL jsonb_array_elements(p.frames) WITH ORDINALITY AS f(frame, ordinality)
WHERE p.match_id = %(match_id)s
  -- AND p.chunk_index = 0
ORDER BY p.chunk_index, f.ordinality
LIMIT %(frame_limit)s;
