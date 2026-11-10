# 설계 검증 스크립트

테이블 설계를 실제 MySQL에서 확인할 때 쓴 파일입니다. 결과는 [테이블 설계 문서의 '검증 결과'](../../docs/02-테이블-설계.md)에 있습니다.
개발용 DB(`helpdesk`)와 섞이지 않게 **별도 DB(`helpdesk_verify`)**에서 실행합니다.

| 파일 | 내용 |
|---|---|
| `gen.py` | 검증용 데이터 생성 (부서 20, 사용자 약 100, 요청 10만, 이력 약 19만. '오늘' = 2026-11-10 고정) |
| `check.sql` | 기획서 항목별 확인 쿼리 (T01~T15, PASS/FAIL 또는 값 출력) |
| `check_fk.sql` | T03: 이력이 있는 사용자 삭제 시 오류 1451이 나야 정상 |
| `explain.sql` | 측정 쿼리 실행 계획 |

## 실행 (docker compose로 띄운 MySQL 8.4 기준)

```bash
python3 db/verify/gen.py > /tmp/seed_verify.sql
docker exec -i helpdesk-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS helpdesk_verify; CREATE DATABASE helpdesk_verify;"
docker exec -i helpdesk-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" helpdesk_verify < backend/src/main/resources/db/migration/V1__init.sql
docker exec -i helpdesk-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" helpdesk_verify < /tmp/seed_verify.sql
docker exec -i helpdesk-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N helpdesk_verify < db/verify/check.sql
docker exec -i helpdesk-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" helpdesk_verify < db/verify/check_fk.sql   # 오류 1451이 나야 정상
```

(4단계에서 V1 파일을 옮기기 전이라면 경로를 `db/migration/V1__init.sql`로 바꿉니다.)

인덱스 전후 비교는 `explain.sql`을 `EXPLAIN ANALYZE`로 바꿔 인덱스 추가 전과 후에 각각 실행합니다. 성능 측정 단계에서는 10회 평균으로 기록합니다.
