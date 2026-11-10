-- T03 사용자는 지울 수 없음: 이력이 있는 사용자 삭제 → ERROR 1451 이 나야 통과
DELETE FROM users WHERE login_id = 'u021';
