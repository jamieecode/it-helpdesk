"""API 목록(openapi.yaml) 자동 점검.

기획서·테이블 설계의 규칙을 기준값으로 두고, API 문서가 빠짐없이 맞는지 확인한다.
기준값이 바뀌면 이 파일의 EXPECTED_* 만 고친다.

실행: python3 tools/check_api.py   (필요: pip install pyyaml openapi-spec-validator)
"""
import sys
from pathlib import Path

import yaml
from openapi_spec_validator import validate

SPEC = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent.parent / "docs" / "api" / "openapi.yaml"
ROLES = {"ANONYMOUS", "REQUESTER", "ASSIGNEE", "ADMIN"}
STATUSES = {"PENDING_APPROVAL", "RECEIVED", "ASSIGNED", "IN_PROGRESS", "ON_HOLD",
            "COMPLETED", "REJECTED", "CANCELED"}

# 테이블 설계 > 코드값 > 이력 이벤트 표 (공식 상태 전이 규칙)
EXPECTED_EVENTS = {
    # event: (역할, 허용 이전 상태, 이후 상태, 사유·결과 필수)
    "CREATED":   ("REQUESTER", [], ["PENDING_APPROVAL", "RECEIVED"], False),
    "UPDATED":   ("REQUESTER", ["PENDING_APPROVAL", "RECEIVED"], ["SAME"], False),
    "APPROVED":  ("ADMIN", ["PENDING_APPROVAL"], ["RECEIVED"], False),
    "REJECTED":  ("ADMIN", ["PENDING_APPROVAL", "RECEIVED"], ["REJECTED"], True),
    "ASSIGNED":  ("ADMIN", ["RECEIVED", "ASSIGNED", "IN_PROGRESS", "ON_HOLD"], ["ASSIGNED", "SAME"], False),
    "STARTED":   ("ASSIGNEE", ["ASSIGNED"], ["IN_PROGRESS"], False),
    "HELD":      ("ASSIGNEE", ["IN_PROGRESS"], ["ON_HOLD"], True),
    "RESUMED":   ("ASSIGNEE", ["ON_HOLD"], ["IN_PROGRESS"], False),
    "COMPLETED": ("ASSIGNEE", ["IN_PROGRESS"], ["COMPLETED"], True),
    "REOPENED":  ("REQUESTER", ["COMPLETED"], ["IN_PROGRESS"], True),
    "CANCELED":  ("REQUESTER", ["PENDING_APPROVAL", "RECEIVED", "ASSIGNED"], ["CANCELED"], False),
}

# 와이어프레임·기획서 화면 구성에 있는 사용자 동작
EXPECTED_SCREENS = {
    "app.start", "login.submit", "header.logout", "header.user",
    "list.tab.my", "list.tab.assignedToMe", "list.tab.pendingApproval", "list.tab.received", "list.tab.all",
    "list.tab.counts", "list.filter", "list.filter.type", "list.search", "list.page", "list.excel",
    "list.newRequest", "list.openDetail",
    "register.type", "register.submit",
    "detail.view", "detail.edit", "detail.history", "detail.comments",
    "detail.comment.create", "detail.comment.delete",
    "detail.approve", "detail.reject", "detail.assign", "detail.reassign", "detail.assign.dropdown",
    "detail.start", "detail.hold", "detail.resume", "detail.complete", "detail.reopen", "detail.cancel",
    "stats.processingTime", "stats.periodFilter", "stats.overdueCount", "stats.openStatus",
}

failures = []


def fail(rule, msg):
    failures.append(f"[{rule}] {msg}")


def resolve(spec, node):
    while isinstance(node, dict) and "$ref" in node:
        cur = spec
        for part in node["$ref"].lstrip("#/").split("/"):
            cur = cur[part]
        node = cur
    return node


def body_schema(spec, op):
    rb = op.get("requestBody")
    if not rb:
        return None
    rb = resolve(spec, rb)
    return resolve(spec, rb["content"]["application/json"]["schema"])


def main():
    spec = yaml.safe_load(SPEC.read_text(encoding="utf-8"))

    # R1 OpenAPI 3.1 문법
    try:
        validate(spec)
    except Exception as e:  # noqa: BLE001
        fail("R1", f"OpenAPI 문법 오류: {e}")

    ops = []
    for path, item in spec["paths"].items():
        path_params = [resolve(spec, p)["name"] for p in item.get("parameters", [])]
        for method in ("get", "post", "put", "patch", "delete"):
            if method in item:
                op = item[method]
                params = path_params + [resolve(spec, p)["name"] for p in op.get("parameters", [])]
                ops.append((f"{method.upper()} {path}", op, params))

    # R9 operationId 중복
    ids = [op.get("operationId") for _, op, _ in ops]
    for i in set(ids):
        if ids.count(i) > 1:
            fail("R9", f"operationId 중복: {i}")

    seen_events, seen_screens = {}, set()
    for name, op, params in ops:
        roles = op.get("x-roles")
        # R4 역할과 인증 응답
        if not roles or not set(roles) <= ROLES:
            fail("R4", f"{name}: x-roles 없음 또는 알 수 없는 역할 {roles}")
            roles = []
        authed = op.get("security", None) != []
        codes = set(op.get("responses", {}).keys())
        if authed and not {"401", "403"} <= codes:
            fail("R4", f"{name}: 로그인이 필요한 API인데 401/403 응답이 없음")
        # R5 요청 번호를 받는 API는 404
        if "requestId" in params and "404" not in codes:
            fail("R5", f"{name}: requestId를 받는데 404 응답이 없음")
        # R10 요청자가 요청 번호로 접근하면 본인 확인 조건이 있어야 함
        if "requestId" in params and "REQUESTER" in roles and not op.get("x-owner"):
            fail("R10", f"{name}: 요청자가 접근하는데 x-owner(본인 확인)가 없음")
        # R8 오류 응답 형식
        for code, resp in op.get("responses", {}).items():
            if code.startswith("4"):
                r = resolve(spec, resp)
                sch = r.get("content", {}).get("application/json", {}).get("schema")
                if not sch or resolve(spec, sch) is not resolve(spec, {"$ref": "#/components/schemas/ErrorResponse"}):
                    fail("R8", f"{name} {code}: ErrorResponse 형식이 아님")
        # 화면 동작
        for s in op.get("x-screens", []):
            if s not in EXPECTED_SCREENS:
                fail("R3", f"{name}: 기준 목록에 없는 화면 동작 '{s}'")
            seen_screens.add(s)
        # R2 이벤트 규칙
        ev = op.get("x-event")
        if ev:
            if ev in seen_events:
                fail("R2", f"이벤트 {ev}가 두 API에 있음: {seen_events[ev]}, {name}")
            seen_events[ev] = name
            if ev not in EXPECTED_EVENTS:
                fail("R2", f"{name}: 알 수 없는 이벤트 {ev}")
                continue
            role, frm, to, text_required = EXPECTED_EVENTS[ev]
            if roles != [role]:
                fail("R2", f"{ev}: 역할이 {roles}, 기준은 [{role}]")
            if sorted(op.get("x-from", [])) != sorted(frm):
                fail("R2", f"{ev}: 이전 상태 {op.get('x-from')} ≠ 기준 {frm}")
            if sorted(op.get("x-to", [])) != sorted(to):
                fail("R2", f"{ev}: 이후 상태 {op.get('x-to')} ≠ 기준 {to}")
            for s in op.get("x-from", []) + op.get("x-to", []):
                if s not in STATUSES | {"SAME"}:
                    fail("R2", f"{ev}: 알 수 없는 상태 {s}")
            body = body_schema(spec, op) or {}
            req = set(body.get("required", []))
            # R6 상태 변경은 version + 409
            if ev != "CREATED":
                if "version" not in req:
                    fail("R6", f"{ev}: 요청 본문에 필수 version이 없음")
                if "409" not in codes:
                    fail("R6", f"{ev}: 409 응답이 없음")
            # R7 사유·처리 결과 필수
            if text_required and "text" not in req:
                fail("R7", f"{ev}: 사유·처리 결과(text)가 필수가 아님")
            if not text_required and "text" in req:
                fail("R7", f"{ev}: 기준에 없는 필수 text")

    for ev in EXPECTED_EVENTS:
        if ev not in seen_events:
            fail("R2", f"이벤트 {ev}를 처리하는 API가 없음")
    for s in sorted(EXPECTED_SCREENS - seen_screens):
        fail("R3", f"화면 동작 '{s}'에 연결된 API가 없음")

    print(f"API {len(ops)}개, 이벤트 {len(seen_events)}/{len(EXPECTED_EVENTS)}, "
          f"화면 동작 {len(seen_screens & EXPECTED_SCREENS)}/{len(EXPECTED_SCREENS)}")
    if failures:
        print(f"실패 {len(failures)}건")
        for f in failures:
            print(" -", f)
        sys.exit(1)
    print("모든 점검 통과 (R1~R10)")


if __name__ == "__main__":
    main()
