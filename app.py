"""START-SYS admin dashboard: Flask backend. The browser only talks to this API;
database credentials live in .env and are never sent to the client."""
import os, datetime as dt
from decimal import Decimal
import pymysql
from dotenv import load_dotenv
from flask import Flask, jsonify, request, render_template

load_dotenv()
app = Flask(__name__)
app.json.sort_keys = False  # keep SQL column order
app.json.default = lambda o: (float(o) if isinstance(o, Decimal) else
                              o.isoformat(sep=" ") if isinstance(o, dt.datetime) else
                              o.isoformat() if isinstance(o, dt.date) else str(o))

TABLES = {"members": "START_ID", "membership_record": "Record_ID"}  # editable tables -> primary key
CATS = {  # Analytics categories -> existing vw_* views (any view not listed appears under "Other Views")
 "Member Demographics": ["vw_gender_distribution", "vw_member_age_group_distribution", "vw_avg_member_age",
    "vw_avg_male_member_age", "vw_avg_female_member_age", "vw_member_current_age"],
 "Geographic Distribution": ["vw_members_per_region", "vw_region_highest_member_count", "vw_region_lowest_member_count",
    "vw_top_10_provinces_by_member_count", "vw_gender_distribution_by_region", "vw_scholarship_distribution_by_region",
    "vw_year_level_distribution_by_region", "vw_accredited_program_distribution_by_region", "vw_lowest_member_program_by_region"],
 "Academic Profile": ["vw_members_per_university", "vw_top_5_universities_by_member_count", "vw_bottom_5_universities_by_member_count",
    "vw_university_highest_member_count", "vw_university_lowest_member_count", "vw_members_by_year_level", "vw_avg_age_by_year_level",
    "vw_start_accredited_programs", "vw_members_per_accredited_program", "vw_top_5_accredited_programs_by_member_count",
    "vw_accredited_program_highest_member_count", "vw_accredited_program_lowest_member_count"],
 "Scholarship Analytics": ["vw_members_per_scholarship_type", "vw_most_common_scholarship_type", "vw_least_common_scholarship_type",
    "vw_scholars_per_year_awarded", "vw_scholarship_type_by_award_year"],
 "Committee and Organizational": ["vw_members_per_role", "vw_role_category_distribution_by_region"],
 "Membership Status": ["vw_membership_status_totals", "vw_membership_status_distribution", "vw_membership_acceptance_rate",
    "vw_membership_rejection_rate", "vw_membership_status_by_region"],
 "Combined and Comparative": ["vw_university_membership_decision_rates", "vw_university_highest_acceptance_rate",
    "vw_male_female_ratio_by_accredited_program", "vw_avg_age_by_accredited_program", "vw_gender_distribution_by_scholarship_type",
    "vw_gender_distribution_by_year_level"],
}
RECORD_SQL = """SELECT r.Record_ID, r.START_ID, CONCAT_WS(' ', m.First_Name, m.Last_Name) AS Member, r.Committee_ID,
  c.Committee_Name AS Committee, d.Department_Name AS Department, r.Role_ID, ro.Role_Title AS `Role`, r.Academic_Year, r.Status
  FROM membership_record r JOIN members m ON m.START_ID = r.START_ID
  LEFT JOIN committee c ON c.Committee_Id = r.Committee_ID
  LEFT JOIN department d ON d.Department_ID = c.Department_Id
  LEFT JOIN `role` ro ON ro.Role_Id = r.Role_ID"""


# ---------- database helpers ----------
def db():
    return pymysql.connect(host=os.getenv("DB_HOST", "127.0.0.1"), port=int(os.getenv("DB_PORT", 3306)),
                           user=os.getenv("DB_USER", "root"), password=os.getenv("DB_PASSWORD", ""),
                           database=os.getenv("DB_NAME", "startsys"), charset="utf8mb4",
                           cursorclass=pymysql.cursors.DictCursor, autocommit=True)

def q(sql, args=None, one=False):
    with db() as c, c.cursor() as cur:
        cur.execute(sql, args)
        rows = cur.fetchall() if cur.description else []
    return (rows[0] if rows else None) if one else rows

def x(sql, args=None):
    with db() as c, c.cursor() as cur:
        cur.execute(sql, args)
        return cur.lastrowid

def views():
    return [r["TABLE_NAME"] for r in q("SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_SCHEMA = DATABASE() "
                                       "AND LEFT(TABLE_NAME, 3) = 'vw_' ORDER BY TABLE_NAME")]

def get_meta(t):
    return q("SELECT COLUMN_NAME AS name, DATA_TYPE AS type, IS_NULLABLE AS nullable, EXTRA AS extra "
             "FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s "
             "ORDER BY ORDINAL_POSITION", (t,))

def clean(t, data, creating):
    """Keep only real, writable columns; blank -> NULL (or '' for NOT NULL text columns)."""
    out = {}
    for c in get_meta(t):
        n, ex = c["name"], (c["extra"] or "").upper()
        if n not in data or "GENERATED" in ex or "AUTO_INCREMENT" in ex or (n == TABLES[t] and not creating):
            continue
        v = data[n].strip() if isinstance(data[n], str) else data[n]
        if v in ("", None):
            v = None if c["nullable"] == "YES" else ("" if c["type"] in ("varchar", "char", "text") else None)
        out[n] = v
    return out

def fix_age(d):
    if "Age" in d and d["Age"] is None and d.get("Date_of_Birth"):
        b, t = dt.date.fromisoformat(d["Date_of_Birth"]), dt.date.today()
        d["Age"] = t.year - b.year - ((t.month, t.day) < (b.month, b.day))

def insert(t, d):
    cols = ", ".join(f"`{k}`" for k in d); marks = ", ".join(["%s"] * len(d))
    return x(f"INSERT INTO `{t}` ({cols}) VALUES ({marks})", list(d.values()))

def update(t, pk, d):
    sets = ", ".join(f"`{k}` = %s" for k in d)
    x(f"UPDATE `{t}` SET {sets} WHERE `{TABLES[t]}` = %s", [*d.values(), pk])

def paging():
    pg = max(int(request.args.get("page", 1)), 1); per = min(max(int(request.args.get("per", 10)), 1), 100)
    return pg, per, (pg - 1) * per

@app.errorhandler(pymysql.MySQLError)
def db_error(e):
    code = e.args[0] if e.args else 0
    friendly = {1451: "This row is still referenced by other records (for example membership records), so it cannot be deleted.",
                1452: "Invalid reference: the member, committee or role does not exist.",
                1062: "Duplicate entry: that ID already exists."}
    down = isinstance(e, pymysql.err.OperationalError) and code in (2002, 2003, 2006, 1045, 1049)
    return jsonify(error=("Cannot reach the database: " if down else "") + friendly.get(code, str(e.args[-1]))), (503 if down else 400)

@app.errorhandler(ValueError)
def bad_value(e):
    return jsonify(error=f"Invalid value: {e}"), 400


# ---------- pages & read-only data ----------
@app.route("/")
def index():
    return render_template("index.html")

@app.get("/api/health")
def health():
    return jsonify(q("SELECT DATABASE() AS db, VERSION() AS v, USER() AS user", one=True))

@app.get("/api/summary")
def summary():
    return jsonify(q("""SELECT (SELECT COUNT(*) FROM members) AS members,
      (SELECT COUNT(*) FROM membership_record) AS records,
      (SELECT COUNT(DISTINCT START_ID) FROM membership_record) AS members_with_records,
      (SELECT COUNT(*) FROM department) AS departments, (SELECT COUNT(*) FROM committee) AS committees,
      (SELECT COUNT(*) FROM `role`) AS roles, (SELECT COUNT(*) FROM membership_record_audit) AS audit_entries""", one=True))

@app.get("/api/view/<name>")
def view(name):
    if name not in views():
        return jsonify(error="Unknown view"), 404
    with db() as c, c.cursor() as cur:
        cur.execute(f"SELECT * FROM `{name}` LIMIT 501")
        rows, cols = cur.fetchall(), [d[0] for d in cur.description]
    return jsonify(name=name, cols=cols, rows=rows[:500], truncated=len(rows) > 500)

@app.get("/api/reports")
def reports():
    have = set(views()); out = {k: [n for n in v if n in have] for k, v in CATS.items()}
    rest = sorted(have - {n for v in out.values() for n in v})
    if rest: out["Other Views"] = rest
    return jsonify({k: v for k, v in out.items() if v})

@app.get("/api/meta/<t>")
def meta_route(t):
    return (jsonify(get_meta(t)) if t in TABLES else (jsonify(error="Unknown table"), 404))

@app.get("/api/options")
def options():
    d = lambda t, c: [r["v"] for r in q(f"SELECT DISTINCT `{c}` AS v FROM `{t}` WHERE `{c}` IS NOT NULL AND `{c}` <> '' ORDER BY 1")]
    return jsonify(
        members={k: d("members", k) for k in ("Sex", "Region", "Province", "University", "Year_Level", "Program", "Scholarship Type")},
        statuses=d("membership_record", "Status"), years=d("membership_record", "Academic_Year"),
        committees=q("SELECT c.Committee_Id AS id, c.Committee_Name AS name, d.Department_Name AS dept FROM committee c "
                     "LEFT JOIN department d ON d.Department_ID = c.Department_Id ORDER BY c.Committee_Name"),
        roles=q("SELECT Role_Id AS id, Role_Title AS name FROM `role` ORDER BY Role_Level, Role_Title"),
        people=q("SELECT START_ID AS id, CONCAT_WS(' ', First_Name, Last_Name) AS name FROM members ORDER BY Last_Name, First_Name"))


# ---------- members ----------
@app.get("/api/members")
def members_list():
    a, w, p = request.args, ["1=1"], []
    if a.get("q"):
        w.append("(CONCAT_WS(' ', m.First_Name, m.Middle_Name, m.Last_Name) LIKE %s OR m.START_ID LIKE %s "
                 "OR m.Email_Address LIKE %s OR m.Program LIKE %s)"); p += [f"%{a['q']}%"] * 4
    for k, col in (("sex", "Sex"), ("region", "Region"), ("university", "University"), ("year_level", "Year_Level")):
        if a.get(k): w.append(f"m.`{col}` = %s"); p.append(a[k])
    where, (pg, per, off) = " AND ".join(w), paging()
    total = q(f"SELECT COUNT(*) AS n FROM members m WHERE {where}", p, one=True)["n"]
    rows = q(f"""SELECT m.START_ID, CONCAT_WS(' ', m.First_Name, m.Middle_Name, m.Last_Name, m.Suffix) AS Name, m.Sex,
        m.University, m.Year_Level, m.Program, m.Region,
        (SELECT COUNT(*) FROM membership_record r WHERE r.START_ID = m.START_ID) AS Records
        FROM members m WHERE {where} ORDER BY m.Last_Name, m.First_Name LIMIT %s OFFSET %s""", p + [per, off])
    return jsonify(total=total, rows=rows)

@app.get("/api/members/<id>")
def member_get(id):
    m = q("SELECT * FROM members WHERE START_ID = %s", (id,), one=True)
    if not m: return jsonify(error="Member not found"), 404
    return jsonify(member=m, records=q(RECORD_SQL + " WHERE r.START_ID = %s ORDER BY r.Academic_Year DESC", (id,)))

@app.post("/api/members")
def member_add():
    d = clean("members", request.json, True); fix_age(d); insert("members", d)
    return jsonify(message="Member added.")

@app.put("/api/members/<id>")
def member_edit(id):
    d = clean("members", request.json, False); fix_age(d); update("members", id, d)
    return jsonify(message="Member updated.")

@app.delete("/api/members/<id>")
def member_del(id):
    x("DELETE FROM members WHERE START_ID = %s", (id,))  # FK blocks this while membership records exist
    return jsonify(message="Member deleted.")


# ---------- membership records (inserts/updates/deletes fire the audit triggers) ----------
@app.get("/api/records")
def records_list():
    a, w, p = request.args, ["1=1"], []
    if a.get("q"):
        w.append("(CONCAT_WS(' ', m.First_Name, m.Last_Name) LIKE %s OR r.START_ID LIKE %s)"); p += [f"%{a['q']}%"] * 2
    for k, col in (("status", "r.Status"), ("year", "r.Academic_Year"), ("committee", "r.Committee_ID"), ("role", "r.Role_ID")):
        if a.get(k): w.append(f"{col} = %s"); p.append(a[k])
    where, (pg, per, off) = " AND ".join(w), paging()
    total = q(f"SELECT COUNT(*) AS n FROM membership_record r JOIN members m ON m.START_ID = r.START_ID WHERE {where}", p, one=True)["n"]
    rows = q(f"{RECORD_SQL} WHERE {where} ORDER BY r.Record_ID DESC LIMIT %s OFFSET %s", p + [per, off])
    return jsonify(total=total, rows=rows)

@app.get("/api/records/<int:id>")
def record_get(id):
    r = q("SELECT * FROM membership_record WHERE Record_ID = %s", (id,), one=True)
    return jsonify(record=r) if r else (jsonify(error="Record not found"), 404)

@app.post("/api/records")
def record_add():
    insert("membership_record", clean("membership_record", request.json, True))
    return jsonify(message="Membership record added. The insert was logged by the database trigger.")

@app.put("/api/records/<int:id>")
def record_edit(id):
    update("membership_record", id, clean("membership_record", request.json, False))
    return jsonify(message="Membership record updated. Status changes are logged by the database trigger.")

@app.delete("/api/records/<int:id>")
def record_del(id):
    x("DELETE FROM membership_record WHERE Record_ID = %s", (id,))
    return jsonify(message="Membership record deleted. The deletion was logged by the database trigger.")


# ---------- organization, audit, database info ----------
@app.get("/api/org")
def org():
    return jsonify(
        departments=q("""SELECT d.Department_ID, d.Department_Name, COUNT(DISTINCT c.Committee_Id) AS Committees,
            COUNT(r.Record_ID) AS Membership_Records FROM department d
            LEFT JOIN committee c ON c.Department_Id = d.Department_ID
            LEFT JOIN membership_record r ON r.Committee_ID = c.Committee_Id
            GROUP BY d.Department_ID, d.Department_Name ORDER BY d.Department_ID"""),
        committees=q("""SELECT c.Committee_Id, c.Committee_Name, d.Department_Name AS Department,
            COUNT(r.Record_ID) AS Membership_Records, COUNT(DISTINCT r.START_ID) AS Unique_Members FROM committee c
            LEFT JOIN department d ON d.Department_ID = c.Department_Id
            LEFT JOIN membership_record r ON r.Committee_ID = c.Committee_Id
            GROUP BY c.Committee_Id, c.Committee_Name, d.Department_Name ORDER BY d.Department_Name, c.Committee_Name"""),
        roles=q("""SELECT ro.Role_Id, ro.Role_Title, ro.Role_Level, COUNT(r.Record_ID) AS Membership_Records,
            COUNT(DISTINCT r.START_ID) AS Unique_Members FROM `role` ro
            LEFT JOIN membership_record r ON r.Role_ID = ro.Role_Id
            GROUP BY ro.Role_Id, ro.Role_Title, ro.Role_Level ORDER BY ro.Role_Id"""))

@app.get("/api/audit")
def audit():
    a, w, p = request.args, ["1=1"], []
    if a.get("action"): w.append("Action_Type = %s"); p.append(a["action"])
    if a.get("q"):
        w.append("(CAST(Record_ID AS CHAR) LIKE %s OR START_ID LIKE %s OR Changed_By LIKE %s)"); p += [f"%{a['q']}%"] * 3
    where, (pg, per, off) = " AND ".join(w), paging()
    total = q(f"SELECT COUNT(*) AS n FROM membership_record_audit WHERE {where}", p, one=True)["n"]
    rows = q(f"SELECT * FROM membership_record_audit WHERE {where} ORDER BY Changed_At DESC, Audit_ID DESC LIMIT %s OFFSET %s", p + [per, off])
    return jsonify(total=total, rows=rows)

def procs():
    out = q("SELECT ROUTINE_NAME AS name FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA = DATABASE() "
            "AND ROUTINE_TYPE = 'PROCEDURE' ORDER BY ROUTINE_NAME")
    for p in out:
        p["params"] = q("SELECT PARAMETER_MODE AS mode, PARAMETER_NAME AS name, DTD_IDENTIFIER AS type "
                        "FROM information_schema.PARAMETERS WHERE SPECIFIC_SCHEMA = DATABASE() AND SPECIFIC_NAME = %s "
                        "AND PARAMETER_NAME IS NOT NULL ORDER BY ORDINAL_POSITION", (p["name"],))
    return out

@app.get("/api/dbinfo")
def dbinfo():
    tabs = [{"Table": t, "Rows": q(f"SELECT COUNT(*) AS n FROM `{t}`", one=True)["n"]}
            for t in ("members", "department", "committee", "role", "membership_record", "membership_record_audit")]
    trig = q("SELECT TRIGGER_NAME AS Trigger_Name, ACTION_TIMING AS Timing, EVENT_MANIPULATION AS Event, EVENT_OBJECT_TABLE AS On_Table "
             "FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = DATABASE() ORDER BY TRIGGER_NAME")
    return jsonify(tables=tabs, views=len(views()), procedures=procs(), triggers=trig)

@app.post("/api/procedures/<name>")
def run_proc(name):
    pr = next((p for p in procs() if p["name"] == name), None)
    if not pr: return jsonify(error="Unknown stored procedure"), 404
    it, marks, vals, outs = iter((request.json or {}).get("args", [])), [], [], []
    for i, pm in enumerate(pr["params"]):
        if pm["mode"] == "OUT":
            marks.append(f"@o{i}"); outs.append(f"@o{i} AS `{pm['name']}`")
        else:
            v = next(it, ""); marks.append("%s"); vals.append(v if v != "" else None)
    sets = []
    with db() as c, c.cursor() as cur:
        cur.execute(f"CALL `{name}`({', '.join(marks)})", vals or None)
        while True:
            if cur.description: sets.append({"cols": [d[0] for d in cur.description], "rows": cur.fetchall()})
            if not cur.nextset(): break
        if outs:
            cur.execute("SELECT " + ", ".join(outs)); sets.append({"cols": [d[0] for d in cur.description], "rows": cur.fetchall()})
    return jsonify(results=sets, message=f"Procedure {name} executed.")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.getenv("PORT", 5000)), debug=False)
