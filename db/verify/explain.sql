-- 측정 쿼리 ① 목록 (상태 + 기간 + id 역순 20건) 과 COUNT, ② 지연 집계, 그 외 목록 정렬
EXPLAIN FORMAT=TRADITIONAL SELECT id,title,status,created_at FROM service_request
 WHERE status='COMPLETED' AND created_at >= '2026-09-01' AND created_at < '2026-11-11'
 ORDER BY id DESC LIMIT 20;
EXPLAIN SELECT COUNT(*) FROM service_request
 WHERE status='COMPLETED' AND created_at >= '2026-09-01' AND created_at < '2026-11-11';
EXPLAIN SELECT COUNT(*) FROM service_request
 WHERE status IN ('PENDING_APPROVAL','RECEIVED','ASSIGNED','IN_PROGRESS','ON_HOLD') AND due_date < '2026-11-10';
EXPLAIN SELECT id FROM service_request WHERE requester_id=10 ORDER BY id DESC LIMIT 20;
EXPLAIN SELECT id FROM service_request WHERE created_at >= '2026-10-01' ORDER BY id DESC LIMIT 20;
EXPLAIN SELECT id FROM service_request WHERE assignee_id=2 AND status IN ('ASSIGNED','IN_PROGRESS','ON_HOLD') ORDER BY id DESC LIMIT 20;
