"""openapi.yaml 에서 사람이 읽는 API 목록(docs/03-API-목록.md)을 만든다.

실행: python3 tools/api_table.py
API를 고치면 openapi.yaml 만 고치고 이 스크립트로 표를 다시 만든다.
"""
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
spec = yaml.safe_load((ROOT / "docs/api/openapi.yaml").read_text(encoding="utf-8"))

ROLE = {"ANONYMOUS": "비로그인", "REQUESTER": "요청자", "ASSIGNEE": "담당자", "ADMIN": "관리자"}
STATUS = {"PENDING_APPROVAL": "승인 대기", "RECEIVED": "접수 대기", "ASSIGNED": "배정됨",
          "IN_PROGRESS": "처리 중", "ON_HOLD": "보류", "COMPLETED": "완료",
          "REJECTED": "반려", "CANCELED": "취소", "SAME": "그대로"}

rows_by_tag = {}
for path, item in spec["paths"].items():
    for method in ("get", "post", "put", "patch", "delete"):
        if method not in item:
            continue
        op = item[method]
        roles = ", ".join(ROLE[r] for r in op.get("x-roles", []))
        if op.get("x-owner"):
            roles += f" ({op['x-owner']})"
        rule = ""
        if op.get("x-event"):
            frm = "·".join(STATUS[s] for s in op.get("x-from", [])) or "-"
            to = "·".join(STATUS[s] for s in op.get("x-to", []))
            rule = f"{op['x-event']}: {frm} → {to}"
            if op.get("x-note"):
                rule += f" ({op['x-note']})"
        errors = ", ".join(c for c in op["responses"] if c.startswith("4"))
        rows_by_tag.setdefault(op["tags"][0], []).append(
            f"| `{method.upper()} {path}` | {op['summary']} | {roles} | {rule} | {errors} |")

out = ["# API 목록", "",
       "> 이 파일은 `python3 tools/api_table.py`로 `docs/api/openapi.yaml`에서 자동 생성합니다. 직접 고치지 마세요.", "",
       "공통 규칙(인증, CSRF, 오류 형식, version)은 [openapi.yaml](api/openapi.yaml)의 description에 있습니다.", ""]
for tag in [t["name"] for t in spec["tags"]]:
    out += [f"## {tag}", "", "| API | 설명 | 권한 | 상태 규칙 | 오류 |", "|---|---|---|---|---|"]
    out += rows_by_tag.get(tag, []) + [""]
(ROOT / "docs/03-API-목록.md").write_text("\n".join(out), encoding="utf-8")
print("docs/03-API-목록.md 생성")
