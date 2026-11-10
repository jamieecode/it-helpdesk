# 전산 업무요청 관리 시스템

현업 부서가 전산팀에 보내는 업무 요청(프로그램 수정, 권한 요청, 장애 신고, 데이터 추출)을 접수하고, 승인·배정·처리·완료까지 관리하는 사내 시스템입니다. 대학·병원 전산실이 매일 쓰는 업무를 옮겨, Java·Spring으로 만듭니다.

## 핵심 포인트

- **상태 전이를 도메인에서 관리**: 8개 상태, 11개 이벤트. 허용되지 않은 변경은 서버가 거부하고 모든 변경을 이력으로 남깁니다.
- **권한을 두 단계로 확인**: 역할 확인에 더해 서비스 계층에서 "이 요청의 요청자·배정 담당자인지" 확인하고, 개인정보가 담길 수 있는 요청은 열람 범위를 좁힙니다.
- **동시 변경 감지**: 화면에서 받은 버전으로 낙관적 락 충돌을 409로 알려 줍니다.
- **JPA + MyBatis**: 쓰기는 JPA, 목록 검색·통계·엑셀은 MyBatis로 SQL을 직접 씁니다.
- **실측 기반 성능 개선**: 요청 10만 건으로 인덱스 전후 실행 계획을 비교해 기록합니다.

## 기술 스택

Java 21 · Spring Boot 4.1 · Spring Security 7 · Spring Data JPA · MyBatis · MySQL 8.4 · Flyway · JUnit 5 · Testcontainers · React · TypeScript · Docker · AWS EC2

## 문서

| 문서 | 내용 |
|---|---|
| [기획·화면설계](docs/01-기획-화면설계.md) | 기능, 권한, 상태 흐름, 화면, 정책, 일정 |
| [테이블 설계](docs/02-테이블-설계.md) | ERD, 테이블, 코드값, 인덱스, MySQL 검증 결과 |
| [API 목록](docs/03-API-목록.md) | 27개 API 요약 ([OpenAPI 원본](docs/api/openapi.yaml)) |
| [개발 환경 세팅](docs/SETUP.md) | 처음 시작할 때 |

## 빠른 시작

```bash
cp .env.example .env
docker compose up -d
# 백엔드 프로젝트 생성은 docs/SETUP.md 3단계 참고
```

## 저장소 구조

```
.
├── CLAUDE.md            # Claude Code 작업 규칙 (학습 모드)
├── docker-compose.yml   # MySQL 8.4
├── backend/             # Spring Boot (SETUP.md 3단계에서 생성)
├── frontend/            # React (화면 단계에서 생성)
├── db/
│   ├── migration/       # Flyway V1(스키마), V2(테스트 데이터) → backend로 옮길 파일
│   └── verify/          # 설계 검증 SQL과 데이터 생성 스크립트
├── docs/                # 기획, 테이블 설계, API
└── tools/               # API 문서 점검(check_api.py), API 표 생성(api_table.py)
```

## 진행 상황

- [x] 기획·화면설계
- [x] 와이어프레임 (요청 목록, 요청 상세)
- [x] 테이블 설계와 MySQL 실행 검증
- [x] API 목록과 자동 점검
- [ ] 0주차: Java 기초
- [ ] 1주차: 프로젝트 세팅, 로그인, 요청 등록·목록·상세, 오류 응답
- [ ] 2주차: 배정, 상태 변경과 이력, 승인·반려, 댓글, 권한 확인, 첫 배포
- [ ] 3주차: 통계, 성능 개선 기록, 엑셀, 테스트, N+1 해결
- [ ] 4주차: 화면 다듬기, 배포 마무리, README 정리
