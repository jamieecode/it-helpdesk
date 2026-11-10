CREATE TABLE department (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  name       VARCHAR(50) NOT NULL,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_department_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE users (
  id            BIGINT       NOT NULL AUTO_INCREMENT,
  login_id      VARCHAR(50)  COLLATE utf8mb4_bin NOT NULL,
  password      VARCHAR(100) NOT NULL,
  name          VARCHAR(50)  NOT NULL,
  role          VARCHAR(20)  NOT NULL,
  department_id BIGINT       NOT NULL,
  extension     VARCHAR(20)  NULL,
  enabled       BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_login_id (login_id),
  CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES department (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE request_type (
  id                BIGINT      NOT NULL AUTO_INCREMENT,
  code              VARCHAR(30) NOT NULL,
  name              VARCHAR(50) NOT NULL,
  approval_required BOOLEAN     NOT NULL DEFAULT FALSE,
  sort_order        INT         NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_request_type_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE service_request (
  id                 BIGINT       NOT NULL AUTO_INCREMENT,
  type_id            BIGINT       NOT NULL,
  approval_required  BOOLEAN      NOT NULL,
  requester_id       BIGINT       NOT NULL,
  department_id      BIGINT       NOT NULL,
  assignee_id        BIGINT       NULL,
  title              VARCHAR(200) NOT NULL,
  content            TEXT         NOT NULL,
  due_date           DATE         NOT NULL,
  status             VARCHAR(20)  NOT NULL,
  segment_started_at DATETIME     NULL,
  processing_minutes INT          NOT NULL DEFAULT 0,
  last_completed_at  DATETIME     NULL,
  version            BIGINT       NOT NULL DEFAULT 0,
  created_at         DATETIME     NOT NULL,
  updated_at         DATETIME     NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_request_type       FOREIGN KEY (type_id)       REFERENCES request_type (id),
  CONSTRAINT fk_request_requester  FOREIGN KEY (requester_id)  REFERENCES users (id),
  CONSTRAINT fk_request_department FOREIGN KEY (department_id) REFERENCES department (id),
  CONSTRAINT fk_request_assignee   FOREIGN KEY (assignee_id)   REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE request_history (
  id               BIGINT        NOT NULL AUTO_INCREMENT,
  request_id       BIGINT        NOT NULL,
  event_type       VARCHAR(30)   NOT NULL,
  from_status      VARCHAR(20)   NULL,
  to_status        VARCHAR(20)   NOT NULL,
  from_assignee_id BIGINT        NULL,
  to_assignee_id   BIGINT        NULL,
  content          VARCHAR(1000) NULL,
  actor_id         BIGINT        NOT NULL,
  created_at       DATETIME      NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_history_request       FOREIGN KEY (request_id)       REFERENCES service_request (id),
  CONSTRAINT fk_history_from_assignee FOREIGN KEY (from_assignee_id) REFERENCES users (id),
  CONSTRAINT fk_history_to_assignee   FOREIGN KEY (to_assignee_id)   REFERENCES users (id),
  CONSTRAINT fk_history_actor         FOREIGN KEY (actor_id)         REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE request_comment (
  id         BIGINT        NOT NULL AUTO_INCREMENT,
  request_id BIGINT        NOT NULL,
  writer_id  BIGINT        NOT NULL,
  content    VARCHAR(2000) NOT NULL,
  deleted    BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at DATETIME      NOT NULL,
  updated_at DATETIME      NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_comment_request FOREIGN KEY (request_id) REFERENCES service_request (id),
  CONSTRAINT fk_comment_writer  FOREIGN KEY (writer_id)  REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
