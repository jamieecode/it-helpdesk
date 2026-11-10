# 개발 환경 세팅

VS Code + Claude Code 기준입니다. 한 번만 하면 됩니다.

## 1. 설치

| 도구           | 버전                      | 비고                                                                                                                                                                                                                                                                                                            |
| -------------- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| JDK            | 21 (Eclipse Temurin 권장) | `JAVA_HOME`의 JDK로 확인: PowerShell `& "$env:JAVA_HOME\bin\java.exe" -version`, macOS/Linux `"$JAVA_HOME/bin/java" -version`. PATH에 다른 JDK가 먼저 있으면 `java -version`은 21이 아닐 수 있습니다. 백엔드 프로젝트를 만든 뒤에는 `backend` 폴더에서 `./gradlew -version`으로 Gradle이 쓰는 JVM도 확인합니다. |
| Docker Desktop | 최신                      | MySQL과 Testcontainers에 사용                                                                                                                                                                                                                                                                                   |
| VS Code        | 최신                      | 저장소를 열면 추천 확장 설치 안내가 뜹니다 (`.vscode/extensions.json`)                                                                                                                                                                                                                                          |
| Node.js        | LTS                       | React 화면용                                                                                                                                                                                                                                                                                                    |
| Python         | 3.10 이상                 | API 점검 도구용: `pip install -r tools/requirements.txt`                                                                                                                                                                                                                                                        |
| Claude Code    | 최신                      | 저장소 루트에서 `claude` 실행                                                                                                                                                                                                                                                                                   |

## 2. MySQL 실행

```bash
cp .env.example .env          # 비밀번호를 원하는 값으로 바꾸기
docker compose up -d
docker compose ps             # STATUS가 healthy면 준비 완료
```

## 3. 백엔드 프로젝트 만들기

VS Code 명령 팔레트(Cmd/Ctrl+Shift+P) → **Spring Initializr: Create a Gradle Project** 를 실행하고 아래처럼 고릅니다.

| 항목        | 값                                                                    |
| ----------- | --------------------------------------------------------------------- |
| Spring Boot | 4.1.x (목록의 최신 정식 버전)                                         |
| Language    | Java                                                                  |
| Group Id    | `com.jaewan`                                                          |
| Artifact Id | `helpdesk`                                                            |
| Packaging   | Jar                                                                   |
| Java        | 21                                                                    |
| 위치        | 이 저장소 루트 → 만들어진 `helpdesk/` 폴더 이름을 `backend/`로 바꾸기 |

의존성:

- Spring Web
- Spring Security
- Spring Data JPA
- MyBatis Framework
- MySQL Driver
- Flyway Migration
- Validation
- Lombok (선택. 쓰면 `@Getter`, `@RequiredArgsConstructor` 정도만)
- Testcontainers
- Spring Boot DevTools (선택)

엑셀 기능(3주차)에서 Apache POI를 추가합니다: `implementation 'org.apache.poi:poi-ooxml:<최신 버전>'`

`build.gradle`에서 확인할 것:

- `org.flywaydb:flyway-mysql`이 들어 있는지 (MySQL용 Flyway 모듈. 없으면 추가)
- MyBatis 스타터가 `4.x`인지 (Spring Boot 4를 지원하는 버전)

## 4. Flyway 파일 옮기기

설계 단계에서 검증한 SQL을 Spring이 읽는 위치로 옮깁니다.

```bash
mkdir -p backend/src/main/resources/db/migration
git mv db/migration/V1__init.sql db/migration/V2__seed.sql backend/src/main/resources/db/migration/
```

## 5. application.yml

`backend/src/main/resources/application.properties`를 지우고 `application.yml`을 만듭니다. 아래는 시작점입니다. 값의 의미는 직접 찾아보며 채워 보세요.

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3307/helpdesk?connectionTimeZone=Asia/Seoul&characterEncoding=UTF-8
    username: ${MYSQL_USER:helpdesk}
    password: ${MYSQL_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false
  flyway:
    enabled: true
  jackson:
    time-zone: Asia/Seoul

mybatis:
  configuration:
    map-underscore-to-camel-case: true
```

비밀번호는 실행할 때 환경 변수로 넘깁니다. VS Code에서는 실행 구성(`launch.json`)의 `env`나 `.env` 파일을 쓰면 됩니다.

## 6. 실행 확인

```bash
cd backend
./gradlew bootRun
```

로그에 Flyway가 V1, V2를 적용했다는 줄이 나오면 성공입니다. DB에서도 확인할 수 있습니다.

```bash
docker exec -it helpdesk-mysql mysql -uhelpdesk -p helpdesk -e "SELECT version, description, success FROM flyway_schema_history;"
```

테스트 계정은 `V2__seed.sql` 맨 위에 있습니다 (비밀번호 `test1234!`, 로컬 전용).

## 7. 프론트엔드 (React 단계에서)

```bash
npm create vite@latest frontend -- --template react-ts
```

개발 중에는 `vite.config.ts`의 `server.proxy`로 `/api`를 `http://localhost:8080`에 연결해 세션 쿠키를 그대로 씁니다.

## 8. MySQL 8.4에서 검증 다시 하기 (첫 주에 한 번)

설계 검증은 MySQL 8.0.46에서 했습니다. 8.4 컨테이너에서 같은 검증을 한 번 돌려 봅니다. 방법은 [db/verify/README.md](../db/verify/README.md)에 있습니다.

## 9. Claude Code 시작

```bash
claude
```

저장소 루트에서 실행하면 `CLAUDE.md`를 자동으로 읽습니다. 첫 질문 예시:

- "SETUP.md 3단계까지 했어. build.gradle 리뷰해 줘."
- "1주차 첫 작업으로 BaseTimeEntity를 만들고 싶어. 힌트부터 줘."
