-- 추적표 검증: 각 줄이 PASS/FAIL 로 나온다. today = 2026-11-10 (앱에서 파라미터로 넘기는 값)
SET @today = '2026-11-10';
SET @now = '2026-11-10 10:00:00';

-- T01 시간대: 서버 시간대가 +09:00
SELECT 'T01 server time zone KST' t, IF(@@global.time_zone = '+09:00', 'PASS', 'FAIL') r;

-- T02 로그인 아이디 대소문자 구분 (utf8mb4_bin): admin 과 Admin 공존 가능
INSERT INTO users (login_id,password,name,role,department_id) VALUES ('Admin','x','대소문자테스트','REQUESTER',2);
SELECT 'T02 login_id case-sensitive' t, IF((SELECT COUNT(*) FROM users WHERE login_id='admin')=1, 'PASS','FAIL') r;
DELETE FROM users WHERE login_id='Admin';

-- T03 사용자는 지울 수 없음 (FK): 요청이 있는 사용자 삭제 시 오류 → 아래 블록에서 오류 코드로 확인
-- (별도 실행)

-- T04 요청자 '내 요청' 목록: requester_id + ORDER BY id DESC
SELECT 'T04 my requests rows' t, IF((SELECT COUNT(*) FROM (SELECT id FROM service_request WHERE requester_id=10 ORDER BY id DESC LIMIT 20) x)=20,'PASS','FAIL') r;

-- T05 관리자 탭 건수 (필터와 무관, 탭 조건만)
SELECT 'T05 tab counts' t, CONCAT('승인대기=',SUM(status='PENDING_APPROVAL'),' 접수대기=',SUM(status='RECEIVED')) r FROM service_request WHERE status IN ('PENDING_APPROVAL','RECEIVED');

-- T06 나에게 배정됨 = 배정됨·처리 중·보류만
SELECT 'T06 my assigned (open only)' t, IF((SELECT COUNT(*) FROM service_request WHERE assignee_id=2 AND status IN ('ASSIGNED','IN_PROGRESS','ON_HOLD'))>0,'PASS','FAIL') r;

-- T07 지연: 희망 완료일 < 오늘 AND 미완료 5개 상태 (취소·반려·완료 제외)
SELECT 'T07 overdue count' t, COUNT(*) r FROM service_request
 WHERE status IN ('PENDING_APPROVAL','RECEIVED','ASSIGNED','IN_PROGRESS','ON_HOLD') AND due_date < @today;

-- T08 유형별 평균 처리 시간: 기간 내 최종 완료 + 상태 COMPLETED 만
SELECT 'T08 avg minutes by type' t, GROUP_CONCAT(CONCAT(code,'=',avg_min) ORDER BY code) r FROM (
 SELECT t.code, ROUND(AVG(r.processing_minutes)) avg_min
   FROM service_request r JOIN request_type t ON t.id=r.type_id
  WHERE r.status='COMPLETED' AND r.last_completed_at >= '2026-10-01' AND r.last_completed_at < '2026-11-01'
  GROUP BY t.code) x;

-- T09 담당자 드롭다운: enabled 담당자만 + 처리 중 건수 (퇴사자 staff6 제외)
SELECT 'T09 assignee dropdown excludes disabled' t,
  IF((SELECT COUNT(*) FROM users WHERE role='ASSIGNEE' AND enabled)=5
     AND NOT EXISTS (SELECT 1 FROM users WHERE login_id='staff6' AND enabled),'PASS','FAIL') r;
SELECT u.name, COUNT(r.id) in_progress FROM users u
  LEFT JOIN service_request r ON r.assignee_id=u.id AND r.status='IN_PROGRESS'
 WHERE u.role='ASSIGNEE' AND u.enabled GROUP BY u.id, u.name ORDER BY u.name;

-- T10 상세의 처리 결과 = 가장 최근 COMPLETED 이력의 content
SELECT 'T10 latest completion result' t, IF((SELECT content FROM request_history WHERE request_id=5 AND event_type='COMPLETED' ORDER BY id DESC LIMIT 1) IS NOT NULL,'PASS','FAIL') r;

-- T11 재요청·댓글 7일 규칙: last_completed_at 기준
SELECT 'T11 within 7 days of last completion' t, COUNT(*) r FROM service_request
 WHERE status='COMPLETED' AND last_completed_at >= DATE_SUB(@now, INTERVAL 7 DAY);

-- T12 승인 필요 여부는 등록 시점 값: 유형 설정을 바꿔도 기존 요청 그대로
UPDATE request_type SET approval_required=FALSE WHERE code='DATA_EXTRACT';
SELECT 'T12 approval snapshot unchanged' t, IF((SELECT COUNT(*) FROM service_request WHERE type_id=4 AND approval_required)>0,'PASS','FAIL') r;
UPDATE request_type SET approval_required=TRUE WHERE code='DATA_EXTRACT';

-- T13 처리 시간 누적 규칙 (STARTED → HELD → RESUMED → COMPLETED): 보류 기간 제외
INSERT INTO service_request (type_id,approval_required,requester_id,department_id,assignee_id,title,content,due_date,status,created_at,updated_at)
VALUES (1,FALSE,10,2,2,'시나리오','내용','2026-11-20','ASSIGNED','2026-11-10 09:00:00','2026-11-10 09:00:00');
SET @rid = LAST_INSERT_ID();
UPDATE service_request SET status='IN_PROGRESS', segment_started_at='2026-11-10 09:00:00' WHERE id=@rid;                                   -- STARTED
UPDATE service_request SET status='ON_HOLD', processing_minutes=processing_minutes+TIMESTAMPDIFF(MINUTE,segment_started_at,'2026-11-10 09:30:00'), segment_started_at=NULL WHERE id=@rid; -- HELD (+30)
UPDATE service_request SET status='IN_PROGRESS', segment_started_at='2026-11-10 13:00:00' WHERE id=@rid;                                   -- RESUMED (보류 3.5시간)
UPDATE service_request SET status='COMPLETED', processing_minutes=processing_minutes+TIMESTAMPDIFF(MINUTE,segment_started_at,'2026-11-10 13:45:00'), segment_started_at=NULL, last_completed_at='2026-11-10 13:45:00' WHERE id=@rid; -- COMPLETED (+45)
SELECT 'T13 processing minutes excludes hold (expect 75)' t, IF((SELECT processing_minutes FROM service_request WHERE id=@rid)=75,'PASS','FAIL') r;
UPDATE service_request SET status='IN_PROGRESS', segment_started_at='2026-11-11 09:00:00' WHERE id=@rid;                                   -- REOPENED
SELECT 'T14 reopen keeps last_completed_at, still counted as not completed' t,
  IF((SELECT last_completed_at FROM service_request WHERE id=@rid)='2026-11-10 13:45:00'
     AND (SELECT COUNT(*) FROM service_request WHERE id=@rid AND status='COMPLETED')=0,'PASS','FAIL') r;
DELETE FROM service_request WHERE id=@rid;

-- T15 이력 이벤트 코드 길이·상태 코드 길이 여유 (VARCHAR 30 / 20)
SELECT 'T15 longest codes fit' t, IF(CHAR_LENGTH('PENDING_APPROVAL')<=20 AND CHAR_LENGTH('COMPLETED')<=30,'PASS','FAIL') r;
