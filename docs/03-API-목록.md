# API 목록

> 이 파일은 `python3 tools/api_table.py`로 `docs/api/openapi.yaml`에서 자동 생성합니다. 직접 고치지 마세요.

공통 규칙(인증, CSRF, 오류 형식, version)은 [openapi.yaml](api/openapi.yaml)의 description에 있습니다.

## 인증

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `GET /api/auth/csrf` | CSRF 토큰 받기 (앱 시작·로그인·로그아웃 직후) | 비로그인, 요청자, 담당자, 관리자 |  |  |
| `POST /api/auth/login` | 로그인 | 비로그인 |  | 400, 401 |
| `POST /api/auth/logout` | 로그아웃 | 요청자, 담당자, 관리자 |  | 401, 403 |
| `GET /api/auth/me` | 현재 로그인 사용자 (새로고침 시 로그인 상태 확인, 역할별 메뉴) | 요청자, 담당자, 관리자 |  | 401, 403 |

## 요청

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `GET /api/requests` | 요청 목록 (탭 + 필터 + 페이지, id 역순) | 요청자, 담당자, 관리자 (요청자는 MY 탭만, 결과는 본인 요청만) |  | 400, 401, 403 |
| `POST /api/requests` | 요청 등록 | 요청자 | CREATED: - → 승인 대기·접수 대기 | 400, 401, 403 |
| `GET /api/requests/tab-counts` | 관리자 대기 탭 건수 (필터와 무관) | 관리자 |  | 401, 403 |
| `GET /api/requests/export` | 요청 목록 엑셀 다운로드 (탭 + 필터 조건, '내용' 열 제외) | 관리자 |  | 400, 401, 403 |
| `GET /api/requests/{requestId}` | 요청 상세 (version, 처리 결과, 지금 가능한 동작 포함) | 요청자, 담당자, 관리자 (요청자는 본인 요청만) |  | 401, 403, 404 |
| `PUT /api/requests/{requestId}` | 요청 수정 (제목·내용·희망 완료일, 유형은 수정 불가) | 요청자 (본인 요청만) | UPDATED: 승인 대기·접수 대기 → 그대로 (승인 필요 요청은 승인 대기에서만) | 400, 401, 403, 404, 409 |
| `GET /api/requests/{requestId}/history` | 처리 이력 (최신순) | 요청자, 담당자, 관리자 (요청자는 본인 요청만) |  | 401, 403, 404 |

## 요청 처리

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `POST /api/requests/{requestId}/approve` | 승인 | 관리자 | APPROVED: 승인 대기 → 접수 대기 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/reject` | 반려 (사유 필수) | 관리자 | REJECTED: 승인 대기·접수 대기 → 반려 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/assign` | 담당자 배정·변경 | 관리자 | ASSIGNED: 접수 대기·배정됨·처리 중·보류 → 배정됨·그대로 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/start` | 처리 시작 | 담당자 (배정된 담당자 본인만) | STARTED: 배정됨 → 처리 중 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/hold` | 보류 (사유 필수) | 담당자 (배정된 담당자 본인만) | HELD: 처리 중 → 보류 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/resume` | 처리 재개 | 담당자 (배정된 담당자 본인만) | RESUMED: 보류 → 처리 중 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/complete` | 처리 완료 (처리 결과 필수) | 담당자 (배정된 담당자 본인만) | COMPLETED: 처리 중 → 완료 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/reopen` | 재요청 (최종 완료 후 7일 이내, 사유 필수) | 요청자 (본인 요청만) | REOPENED: 완료 → 처리 중 | 400, 401, 403, 404, 409 |
| `POST /api/requests/{requestId}/cancel` | 요청 취소 (처리 시작 전) | 요청자 (본인 요청만) | CANCELED: 승인 대기·접수 대기·배정됨 → 취소 | 400, 401, 403, 404, 409 |

## 댓글

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `GET /api/requests/{requestId}/comments` | 댓글 목록 (작성순, 삭제된 댓글은 deleted=true와 빈 내용) | 요청자, 담당자, 관리자 (요청자는 본인 요청만, 승인 필요 요청은 요청자·배정 담당자·관리자만) |  | 401, 403, 404 |
| `POST /api/requests/{requestId}/comments` | 댓글 작성 | 요청자, 담당자, 관리자 (요청자는 본인 요청만, 승인 필요 요청은 요청자·배정 담당자·관리자만) |  | 400, 401, 403, 404, 409 |
| `DELETE /api/requests/{requestId}/comments/{commentId}` | 댓글 삭제 (작성자 본인만, 실제로는 deleted=true) | 요청자, 담당자, 관리자 (작성자 본인만) |  | 401, 403, 404 |

## 기준 정보

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `GET /api/request-types` | 요청 유형 목록 (등록 화면, 목록 필터) | 요청자, 담당자, 관리자 |  | 401, 403 |
| `GET /api/users/assignees` | 배정 가능한 담당자 (enabled 담당자 + 처리 중 건수) | 관리자 |  | 401, 403 |

## 통계

| API | 설명 | 권한 | 상태 규칙 | 오류 |
|---|---|---|---|---|
| `GET /api/stats/processing-time` | 유형별 평균 처리 시간 (기간 = 최종 완료 시각, 상태 COMPLETED만) | 관리자 |  | 400, 401, 403 |
| `GET /api/stats/open-status` | 미처리·지연 현황 (현재 시점, 오늘은 서버 LocalDate.now()) | 관리자 |  | 401, 403 |
