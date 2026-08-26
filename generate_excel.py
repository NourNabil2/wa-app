
import subprocess
import re
import openpyxl
from openpyxl.styles import PatternFill, Font, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from collections import defaultdict

# ============================================================
# 1. Parse git log
# ============================================================
result = subprocess.run(
    ["git", "log", "--pretty=format:%H|%ad|%an|%s", "--date=format:%Y-%m-%d %H:%M", "--name-status"],
    capture_output=True, text=True, encoding="utf-8", cwd=r"e:\fastway"
)

rows = []
commit_info = None

AREA_MAP = [
    ('cart',           'Cart (السلة)'),
    ('checkout',       'Checkout (الدفع)'),
    ('home',           'Home (الرئيسية)'),
    ('product_details','Product Details (تفاصيل المنتج)'),
    ('profile',        'Profile (الملف الشخصي)'),
    ('auth',           'Authentication (تسجيل الدخول)'),
    ('orders',         'Orders (الطلبات)'),
    ('wishlist',       'Wishlist (المفضلة)'),
    ('blog',           'Blog (المدونة)'),
    ('points',         'Points (النقاط)'),
    ('address',        'Address (العناوين)'),
    ('notifications',  'Notifications (الاشعارات)'),
    ('announcements',  'Announcements (الاعلانات)'),
    ('translations|ar.json|en.json', 'Translations (الترجمة)'),
    ('layout|header|shell|responsive|web_shell|web_header', 'Layout & Responsive'),
    ('api|dio',        'API & Backend'),
    ('assets',         'Assets (الاصول)'),
    ('.github|workflow|docker|Dockerfile', 'CI/CD'),
    ('pubspec',        'Dependencies (المكتبات)'),
]

CHANGE_LABELS = {
    'A': 'Added (اضافة)',
    'M': 'Modified (تعديل)',
    'D': 'Deleted (حذف)',
    'R': 'Renamed (اعادة تسمية)',
    'C': 'Copied',
    'T': 'Type Changed',
}

def get_area(filepath):
    for pattern, label in AREA_MAP:
        for p in pattern.split('|'):
            if re.search(p, filepath, re.IGNORECASE):
                return label
    return 'General (عام)'

for line in result.stdout.splitlines():
    line = line.strip()
    if not line:
        continue
    m = re.match(r'^([a-f0-9]{40})\|(.+?)\|(.+?)\|(.+)$', line)
    if m:
        commit_info = (m.group(1)[:7], m.group(2), m.group(3), m.group(4))
        continue
    fm = re.match(r'^([AMDRTC])\t(.+)$', line)
    if fm and commit_info:
        ct = CHANGE_LABELS.get(fm.group(1), fm.group(1))
        fp = fm.group(2)
        area = get_area(fp)
        rows.append((*commit_info, area, fp, ct))

print(f"Total file-change entries: {len(rows)}")

# ============================================================
# 2. Helpers
# ============================================================
DARK_GREEN  = "1B5E20"
MID_GREEN   = "2E7D32"
LIGHT_GREEN = "C8E6C9"
WHITE       = "FFFFFF"
GRAY        = "FAFAFA"

COLOR_POOL = [
    "C8E6C9","E3F2FD","FFF9C4","FFF3E0",
    "E8EAF6","FCE4EC","E0F7FA","F3E5F5",
    "F5F5F5","E8F5E9","F1F8E9","FBE9E7",
]

area_color_map = {}
def area_color(area):
    if area not in area_color_map:
        area_color_map[area] = COLOR_POOL[len(area_color_map) % len(COLOR_POOL)]
    return area_color_map[area]

def fill(hex_color):
    return PatternFill("solid", fgColor=hex_color)

def bd(style="thin"):
    s = Side(border_style=style, color="BDBDBD")
    return Border(left=s, right=s, top=s, bottom=s)

def hfont(size=11, color=WHITE):
    return Font(name="Calibri", size=size, bold=True, color=color)

def dfont(size=10, bold=False, color="212121"):
    return Font(name="Calibri", size=size, bold=bold, color=color)

# ============================================================
# 3. Build workbook
# ============================================================
wb = openpyxl.Workbook()


# ─── SHEET 1: All Changes ───────────────────────────────────
ws1 = wb.active
ws1.title = "All Changes"
ws1.freeze_panes = "A2"

headers1 = ["#", "Commit", "Date", "Author", "Description", "Feature Area", "File Path", "Change Type"]
ws1.row_dimensions[1].height = 35
for col, h in enumerate(headers1, 1):
    c = ws1.cell(row=1, column=col, value=h)
    c.fill = fill(DARK_GREEN); c.font = hfont(11)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

for idx, row in enumerate(rows, 1):
    commit, date, author, msg, area, fpath, ctype = row
    r = idx + 1
    bg = area_color(area)
    vals = [idx, commit, date, author, msg, area, fpath, ctype]
    for col, val in enumerate(vals, 1):
        c = ws1.cell(row=r, column=col, value=val)
        c.font = dfont()
        c.border = bd()
        c.alignment = Alignment(vertical="center", wrap_text=(col in (5, 7)))
        if col == 6:
            c.fill = fill(bg)
            c.font = dfont(bold=True)
        elif col == 8:
            if "Added" in str(val):
                c.fill = fill("E8F5E9"); c.font = dfont(color="1B5E20", bold=True)
            elif "Modified" in str(val):
                c.fill = fill("FFF8E1"); c.font = dfont(color="E65100", bold=True)
            elif "Deleted" in str(val):
                c.fill = fill("FFEBEE"); c.font = dfont(color="B71C1C", bold=True)
            elif "Renamed" in str(val):
                c.fill = fill("E3F2FD"); c.font = dfont(color="0D47A1", bold=True)
        elif idx % 2 == 0 and col not in (6, 8):
            c.fill = fill(GRAY)
    ws1.row_dimensions[r].height = 20

for i, w in enumerate([5, 10, 18, 16, 55, 30, 60, 26], 1):
    ws1.column_dimensions[get_column_letter(i)].width = w
ws1.auto_filter.ref = f"A1:{get_column_letter(len(headers1))}{len(rows)+1}"


# ─── SHEET 2: Summary by Feature Area ───────────────────────
ws2 = wb.create_sheet("Summary by Area")

ws2.merge_cells("A1:G1")
t = ws2.cell(row=1, column=1, value="FastWay Mobile App - Changes Summary by Feature Area")
t.fill = fill(DARK_GREEN); t.font = hfont(14)
t.alignment = Alignment(horizontal="center", vertical="center")
ws2.row_dimensions[1].height = 40

headers2 = ["Feature Area", "Total File Changes", "Added", "Modified", "Deleted", "Unique Commits", "% of Total"]
ws2.row_dimensions[2].height = 28
for col, h in enumerate(headers2, 1):
    c = ws2.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont()
    c.alignment = Alignment(horizontal="center", vertical="center"); c.border = bd()

area_stats = defaultdict(lambda: {"total":0,"added":0,"modified":0,"deleted":0,"commits":set()})
for commit, date, author, msg, area, fp, ct in rows:
    area_stats[area]["total"] += 1
    area_stats[area]["commits"].add(commit)
    if "Added" in ct:   area_stats[area]["added"] += 1
    elif "Modified" in ct: area_stats[area]["modified"] += 1
    elif "Deleted" in ct:  area_stats[area]["deleted"] += 1

total_files = len(rows)
for i, (area, s) in enumerate(sorted(area_stats.items(), key=lambda x: -x[1]["total"]), 3):
    pct = f"{round(s['total']/total_files*100,1)}%"
    bg = area_color(area)
    vals = [area, s["total"], s["added"], s["modified"], s["deleted"], len(s["commits"]), pct]
    for col, val in enumerate(vals, 1):
        c = ws2.cell(row=i, column=col, value=val)
        c.border = bd(); c.font = dfont()
        c.alignment = Alignment(horizontal="left" if col==1 else "center", vertical="center")
        if col == 1: c.fill = fill(bg); c.font = dfont(bold=True)
        elif col == 3: c.font = dfont(color="1B5E20", bold=True)
        elif col == 4: c.font = dfont(color="E65100", bold=True)
        elif col == 5: c.font = dfont(color="B71C1C", bold=True)

for i, w in enumerate([35, 22, 12, 14, 14, 18, 12], 1):
    ws2.column_dimensions[get_column_letter(i)].width = w


# ─── SHEET 3: Commits Timeline ──────────────────────────────
ws3 = wb.create_sheet("Commits Timeline")
ws3.freeze_panes = "A3"

ws3.merge_cells("A1:F1")
t3 = ws3.cell(row=1, column=1, value="FastWay Mobile App - All Commits Timeline")
t3.fill = fill(DARK_GREEN); t3.font = hfont(14)
t3.alignment = Alignment(horizontal="center", vertical="center")
ws3.row_dimensions[1].height = 40

headers3 = ["#", "Commit Hash", "Date", "Author", "Description (Commit Message)", "Files Changed"]
ws3.row_dimensions[2].height = 28
for col, h in enumerate(headers3, 1):
    c = ws3.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont()
    c.alignment = Alignment(horizontal="center", vertical="center"); c.border = bd()

seen_commits = set()
commit_list = []
for commit, date, author, msg, area, fp, ct in rows:
    if commit not in seen_commits:
        seen_commits.add(commit)
        commit_list.append((commit, date, author, msg))

files_per_commit = defaultdict(int)
for commit, *_ in rows:
    files_per_commit[commit] += 1

for i, (commit, date, author, msg) in enumerate(commit_list, 3):
    vals = [i-2, commit, date, author, msg, files_per_commit[commit]]
    for col, val in enumerate(vals, 1):
        c = ws3.cell(row=i, column=col, value=val)
        c.border = bd(); c.font = dfont()
        c.alignment = Alignment(vertical="center", wrap_text=(col==5))
        if i % 2 == 0: c.fill = fill("F9FBE7")
    ws3.row_dimensions[i].height = 22

for i, w in enumerate([5, 12, 18, 16, 70, 16], 1):
    ws3.column_dimensions[get_column_letter(i)].width = w
ws3.auto_filter.ref = f"A2:{get_column_letter(len(headers3))}{len(commit_list)+2}"


# ─── SHEET 4: Most Changed Files ────────────────────────────
ws4 = wb.create_sheet("Most Changed Files")
ws4.freeze_panes = "A3"

ws4.merge_cells("A1:D1")
t4 = ws4.cell(row=1, column=1, value="FastWay Mobile App - Most Frequently Changed Files")
t4.fill = fill(DARK_GREEN); t4.font = hfont(14)
t4.alignment = Alignment(horizontal="center", vertical="center")
ws4.row_dimensions[1].height = 40

headers4 = ["#", "File Path", "Feature Area", "Times Changed"]
ws4.row_dimensions[2].height = 28
for col, h in enumerate(headers4, 1):
    c = ws4.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont()
    c.alignment = Alignment(horizontal="center", vertical="center"); c.border = bd()

file_counts = defaultdict(lambda: {"count":0, "area":""})
for commit, date, author, msg, area, fp, ct in rows:
    file_counts[fp]["count"] += 1
    file_counts[fp]["area"] = area

sorted_files = sorted(file_counts.items(), key=lambda x: -x[1]["count"])
for i, (fp, info) in enumerate(sorted_files, 3):
    count = info["count"]
    heat = "D32F2F" if count >= 20 else ("F57C00" if count >= 10 else ("FBC02D" if count >= 5 else "388E3C"))
    bg = area_color(info["area"])
    for col, val in enumerate([i-2, fp, info["area"], count], 1):
        c = ws4.cell(row=i, column=col, value=val)
        c.border = bd(); c.font = dfont()
        c.alignment = Alignment(vertical="center", wrap_text=(col==2))
        if col == 3: c.fill = fill(bg); c.font = dfont(bold=True)
        elif col == 4: c.font = Font(name="Calibri", size=11, bold=True, color=heat)
        elif i % 2 == 0 and col not in (3,4): c.fill = fill(GRAY)
    ws4.row_dimensions[i].height = 20

for i, w in enumerate([5, 70, 32, 18], 1):
    ws4.column_dimensions[get_column_letter(i)].width = w
ws4.auto_filter.ref = f"A2:{get_column_letter(len(headers4))}{len(sorted_files)+2}"


# ============================================================
# Save
# ============================================================
out_path = r"e:\fastway\FastWay_Changes_Report.xlsx"
wb.save(out_path)
print(f"\nExcel report saved to: {out_path}")
print(f"  Sheets: {[s.title for s in wb.worksheets]}")
print(f"  Detail rows: {len(rows)}")
print(f"  Unique commits: {len(commit_list)}")
print(f"  Unique files: {len(file_counts)}")
