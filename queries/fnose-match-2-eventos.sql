-- FNose / partida 2 de 4: eventos (fases, faíscas e toques no alvo), um por linha.
-- Troque o match_id no WHERE.

SELECT
    e.offset_ms,
    e.event_type,
    e.from_phase, e.to_phase,
    e.side,
    e.from_state, e.to_state,
    e.angle_deg,
    e.tip_x,  e.tip_y,
    e.nose_x, e.nose_y,
    e.tip_screen_x, e.tip_screen_y,
    e.target_x, e.target_y, e.target_radius,
    e.batch_index
FROM msupperlimbs_fnose_events e
WHERE e.match_id = %(match_id)s
ORDER BY e.offset_ms, e.batch_index;
