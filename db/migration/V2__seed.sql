-- 로컬 개발·시연용 초기 데이터
-- 모든 테스트 계정의 비밀번호: test1234!  (BCrypt, cost 10)
-- 운영 환경에는 이 파일 대신 실제 계정을 넣는 별도 마이그레이션을 씁니다.

INSERT INTO department (id, name) VALUES
  (1, '전산팀'),
  (2, '교무팀'),
  (3, '학생지원팀'),
  (4, '장학팀'),
  (5, '재무팀');

INSERT INTO request_type (id, code, name, approval_required, sort_order) VALUES
  (1, 'PROGRAM_CHANGE', '프로그램 수정', FALSE, 1),
  (2, 'ACCESS',         '권한 요청',     FALSE, 2),
  (3, 'INCIDENT',       '장애 신고',     FALSE, 3),
  (4, 'DATA_EXTRACT',   '데이터 추출',   TRUE,  4);

INSERT INTO users (id, login_id, password, name, role, department_id, extension, enabled) VALUES
  (1, 'admin',    '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '김관리',   'ADMIN',     1, '2001', TRUE),
  (2, 'staff1',   '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '이담당',   'ASSIGNEE',  1, '2002', TRUE),
  (3, 'staff2',   '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '최담당',   'ASSIGNEE',  1, '2003', TRUE),
  (4, 'staff3',   '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '정담당',   'ASSIGNEE',  1, '2004', TRUE),
  (5, 'staff9',   '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '한퇴사',   'ASSIGNEE',  1, '2009', FALSE),
  (6, 'kyomu1',   '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '박교무',   'REQUESTER', 2, '2345', TRUE),
  (7, 'student1', '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '오지원',   'REQUESTER', 3, '2456', TRUE),
  (8, 'scholar1', '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '윤장학',   'REQUESTER', 4, '2567', TRUE),
  (9, 'finance1', '$2b$10$ZGI7eR0TO3SgDhZe.qt8POsGP5tLJtzdg14ll5JUyvmqVHbhn2Vpq', '강재무',   'REQUESTER', 5, '2678', TRUE);
