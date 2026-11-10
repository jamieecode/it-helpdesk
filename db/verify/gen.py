"""Generate seed data + 100k requests (and history) as SQL for verification.

Distribution (기획서 기준): 최근 2년, 부서 20개, 완료 위주.
'today' is fixed so results are reproducible.
"""
import random
from datetime import datetime, timedelta, date

random.seed(42)
TODAY = date(2026, 11, 10)
NOW = datetime(2026, 11, 10, 10, 0, 0)
N = 100_000

out = []
w = out.append

depts = ["전산팀"] + [f"부서{i:02d}" for i in range(1, 20)]
w("INSERT INTO department (name) VALUES " + ",".join(f"('{d}')" for d in depts) + ";")

# request types: id 1..4
w("""INSERT INTO request_type (code, name, approval_required, sort_order) VALUES
('PROGRAM_CHANGE','프로그램 수정',FALSE,1),('ACCESS','권한 요청',FALSE,2),
('INCIDENT','장애 신고',FALSE,3),('DATA_EXTRACT','데이터 추출',TRUE,4);""")

users = []  # (login, name, role, dept_id, enabled)
users.append(("admin", "김관리", "ADMIN", 1, 1))
for i in range(1, 7):
    users.append((f"staff{i}", f"담당{i}", "ASSIGNEE", 1, 0 if i == 6 else 1))  # staff6 = 퇴사자
for d in range(2, 21):
    for k in range(1, 6):
        users.append((f"u{d:02d}{k}", f"요청{d:02d}{k}", "REQUESTER", d, 1))
pw = "$2a$10$abcdefghijklmnopqrstuuabcdefghijklmnopqrstuvwxyzABCD"  # dummy 60-char bcrypt-like
w("INSERT INTO users (login_id, password, name, role, department_id, extension, enabled) VALUES " +
  ",".join(f"('{l}','{pw}','{n}','{r}',{d},'{2000+i}',{e})" for i, (l, n, r, d, e) in enumerate(users)) + ";")
user_ids = {u[0]: i + 1 for i, u in enumerate(users)}
assignees = [user_ids[f"staff{i}"] for i in range(1, 6)]  # enabled ones (6 is disabled but has old work)
requesters = [(user_ids[u[0]], u[3]) for u in users if u[2] == "REQUESTER"]
admin = user_ids["admin"]

def dt(x):
    return x.strftime("%Y-%m-%d %H:%M:%S")

req_rows, hist_rows = [], []
start = NOW - timedelta(days=730)
for rid in range(1, N + 1):
    created = start + timedelta(seconds=int((NOW - start).total_seconds() * rid / N))  # id order == time order
    type_id = random.choices([1, 2, 3, 4], weights=[40, 25, 25, 10])[0]
    appr = 1 if type_id == 4 else 0
    req_id, dept = random.choice(requesters)
    due = (created + timedelta(days=random.randint(0, 14))).date()
    age_days = (NOW - created).days
    r = random.random()
    # older requests are almost all finished; recent ones may be open
    if age_days > 30:
        status = "COMPLETED" if r < 0.94 else ("CANCELED" if r < 0.97 else "REJECTED")
    else:
        status = random.choices(
            ["PENDING_APPROVAL" if appr else "RECEIVED", "RECEIVED", "ASSIGNED", "IN_PROGRESS", "ON_HOLD",
             "COMPLETED", "CANCELED", "REJECTED"],
            weights=[8, 8, 8, 12, 4, 52, 5, 3])[0]
        if status == "PENDING_APPROVAL" and not appr:
            status = "RECEIVED"
    assignee = "NULL"
    seg = "NULL"; minutes = 0; last_done = "NULL"
    hist_rows.append((rid, "CREATED", "NULL", "PENDING_APPROVAL" if appr else "RECEIVED", "NULL", "NULL", "NULL", req_id, dt(created)))
    if status in ("ASSIGNED", "IN_PROGRESS", "ON_HOLD", "COMPLETED"):
        a = random.choice(assignees + ([user_ids["staff6"]] if age_days > 365 else []))
        assignee = str(a)
        if status == "IN_PROGRESS":
            seg = f"'{dt(NOW - timedelta(minutes=random.randint(10, 600)))}'"
        if status == "COMPLETED":
            minutes = random.randint(10, 60 * 24 * 3)
            done = created + timedelta(minutes=minutes + random.randint(30, 600))
            if done > NOW:
                done = NOW - timedelta(minutes=5)
            last_done = f"'{dt(done)}'"
            hist_rows.append((rid, "COMPLETED", "'IN_PROGRESS'", "COMPLETED", "NULL", "NULL", "'처리 완료 결과 예시'", a, dt(done)))
    updated = created
    req_rows.append(f"({rid},{type_id},{appr},{req_id},{dept},{assignee},'요청 제목 {rid}','요청 내용 {rid}','{due}','{status}',{seg},{minutes},{last_done},0,'{dt(created)}','{dt(updated)}')")

B = 2000
for i in range(0, len(req_rows), B):
    w("INSERT INTO service_request (id,type_id,approval_required,requester_id,department_id,assignee_id,title,content,due_date,status,segment_started_at,processing_minutes,last_completed_at,version,created_at,updated_at) VALUES " + ",".join(req_rows[i:i + B]) + ";")
for i in range(0, len(hist_rows), B):
    w("INSERT INTO request_history (request_id,event_type,from_status,to_status,from_assignee_id,to_assignee_id,content,actor_id,created_at) VALUES " +
      ",".join(f"({a},'{b}',{c},'{d}',{e},{f},{g},{h},'{i2}')" for a, b, c, d, e, f, g, h, i2 in hist_rows[i:i + B]) + ";")
w("ANALYZE TABLE service_request, request_history;")
print("\n".join(out))
