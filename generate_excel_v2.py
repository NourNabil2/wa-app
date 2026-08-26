
import subprocess
import re
import openpyxl
from openpyxl.styles import PatternFill, Font, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from collections import defaultdict

# ============================================================
# 1. Parse git log with file changes
# ============================================================
result = subprocess.run(
    ["git", "log", "--pretty=format:COMMIT|%H|%ad|%an|%s", "--date=format:%Y-%m-%d", "--name-status"],
    capture_output=True, text=True, encoding="utf-8", cwd=r"e:\fastway"
)

commits = []  # list of dicts
current = None

for line in result.stdout.splitlines():
    line = line.strip()
    if not line:
        continue
    if line.startswith("COMMIT|"):
        if current:
            commits.append(current)
        parts = line.split("|", 4)
        current = {
            "hash": parts[1][:7],
            "date": parts[2],
            "author": parts[3],
            "raw_msg": parts[4] if len(parts) > 4 else "",
            "files": []
        }
    elif current:
        m = re.match(r'^([AMDRTC])\t(.+)$', line)
        if m:
            current["files"].append({"status": m.group(1), "path": m.group(2)})

if current:
    commits.append(current)

print(f"Total commits parsed: {len(commits)}")

# ============================================================
# 2. Smart description generator
# ============================================================

def get_screens(files):
    """Extract which screens/features were touched"""
    screens = set()
    for f in files:
        p = f["path"].lower()
        if "cart" in p:              screens.add("Cart Screen (صفحة السلة)")
        if "checkout" in p:          screens.add("Checkout Screen (صفحة الدفع)")
        if "home" in p:              screens.add("Home Screen (الصفحة الرئيسية)")
        if "product_detail" in p:    screens.add("Product Details Screen (تفاصيل المنتج)")
        if "product" in p and "card" in p: screens.add("Product Card (كارت المنتج)")
        if "profile" in p:           screens.add("Profile Screen (صفحة الملف الشخصي)")
        if "auth" in p or "login" in p or "register" in p:
                                     screens.add("Auth Screen (تسجيل الدخول/التسجيل)")
        if "order" in p:             screens.add("Orders Screen (صفحة الطلبات)")
        if "wishlist" in p:          screens.add("Wishlist Screen (صفحة المفضلة)")
        if "blog" in p:              screens.add("Blog Screen (صفحة المدونة)")
        if "points" in p:            screens.add("Points Screen (صفحة النقاط)")
        if "address" in p:           screens.add("Address Screen (صفحة العناوين)")
        if "notification" in p:      screens.add("Notifications (الاشعارات)")
        if "announcement" in p:      screens.add("Announcements (الاعلانات)")
        if "web_header" in p or "header" in p: screens.add("Web Header / Navbar (الهيدر)")
        if "web_shell" in p or "layout" in p or "shell" in p: screens.add("App Layout (التخطيط العام)")
        if "responsive" in p:        screens.add("Responsive Layout (التوافق مع الشاشات)")
        if "ar.json" in p or "en.json" in p or "translation" in p:
                                     screens.add("Translations (الترجمة)")
        if "api" in p or "datasource" in p or "remote" in p:
                                     screens.add("API & Data Layer (البيانات والـ API)")
        if ".github" in p or "workflow" in p or "docker" in p or "dockerfile" in p.lower():
                                     screens.add("CI/CD & DevOps (النشر والتوزيع)")
        if "pubspec" in p:           screens.add("Dependencies / Packages (المكتبات)")
        if "assets" in p and ("font" in p or "ttf" in p):
                                     screens.add("Fonts & Assets (الخطوط)")
        if "assets" in p and ("image" in p or "png" in p or "svg" in p):
                                     screens.add("Images & Icons (الصور والايقونات)")
    return sorted(screens) if screens else ["General (عام)"]


def humanize(raw_msg: str, files: list) -> str:
    """
    Turn a raw git commit message + file list into a clear human-readable description.
    """
    msg = raw_msg.lower()
    file_paths = " ".join(f["path"].lower() for f in files)
    statuses = [f["status"] for f in files]
    added = statuses.count("A")
    modified = statuses.count("M")
    deleted = statuses.count("D")

    # ── Cart ──────────────────────────────────────────────────
    if "cart" in file_paths or "cart" in msg:
        if "express" in msg and ("svg" in msg or "badge" in msg):
            return "Cart Screen: Added express delivery badge icon on each cart item + showed cold-storage hint per product (instead of global banner)"
        if "coupon" in msg or "promo" in msg:
            return "Cart Screen: Moved coupon / promo code section from Cart page into the Order Summary card"
        if "cold" in msg:
            return "Cart Screen: Added cold-storage indicator (❄️) on applicable cart items with informational hint"
        if "wallet" in msg or "toggle" in msg:
            return "Checkout Screen: Added wallet payment toggle inside the checkout summary section"
        if "fix cart" in msg or "fix(cart)" in msg:
            return "Cart Screen: Bug fixes and stability improvements"
        if "enhance" in msg or "ui" in msg:
            return "Cart Screen: UI / design improvements"
        return "Cart Screen: Updates and improvements"

    # ── Checkout ──────────────────────────────────────────────
    if "checkout" in file_paths or "checkout" in msg:
        if "bnpl" in msg or "pay later" in msg or "لاحقا" in msg:
            return "Checkout Screen: Added 'Buy Now Pay Later' (BNPL) payment option with no-fees label"
        if "express" in msg:
            return "Checkout Screen: Integrated express delivery option inside checkout flow"
        if "address" in msg:
            return "Checkout Screen: Fixed address selection and display in checkout"
        if "shipping" in msg:
            return "Checkout Screen: Updated shipping method picker / display"
        if "guest" in msg:
            return "Checkout Screen: Added guest checkout flow (no login required)"
        if "string" in msg or "text" in msg or "translation" in msg:
            return "Checkout Screen: Fixed text labels and translation keys"
        return "Checkout Screen: Updates and improvements"

    # ── Home ──────────────────────────────────────────────────
    if "home" in file_paths or "home" in msg:
        if "banner" in msg:
            return "Home Screen: Updated / fixed home page banners and carousel"
        if "blog" in msg:
            return "Home Screen: Added blog section to the home page"
        if "revamp" in msg or "rework" in msg:
            return "Home Screen: Full UI redesign / revamp of the home page"
        if "campaign" in msg or "categor" in msg:
            return "Home Screen: Updated categories and campaign tiles section"
        if "product card" in msg or "card" in msg:
            return "Home Screen: Redesigned product card UI (image, price, button layout)"
        if "animation" in msg or "animated" in msg:
            return "Home Screen: Removed heavy animations causing performance issues"
        if "gps" in msg or "location" in msg:
            return "Home Screen: Fixed GPS / location detection for delivery area"
        if "appbar" in msg or "app bar" in msg:
            return "Home Screen: Updated mobile app bar (top navigation bar)"
        if "skeleton" in msg:
            return "Home Screen: Fixed skeleton loader stuck issue in blog/sections"
        if "section" in msg and "hide" in msg or "empty" in msg:
            return "Home Screen: Hidden empty sections (no products shown when empty)"
        return "Home Screen: UI improvements and updates"

    # ── Product Details ───────────────────────────────────────
    if "product_detail" in file_paths or "product detail" in msg or "product-detail" in msg:
        if "accordion" in msg:
            return "Product Details Screen: Changed product info sections to accordion style (collapsed by default)"
        if "brand" in msg and ("badge" in msg or "verified" in msg or "checkmark" in msg):
            return "Product Details Screen: Added verified badge (blue checkmark) next to brand name"
        if "gallery" in msg or "image" in msg:
            return "Product Details Screen: Fixed product image gallery display"
        if "nutrition" in msg:
            return "Product Details Screen: Updated nutrition information widget UI"
        if "quantity" in msg:
            return "Product Details Screen: Made quantity field editable with max-quantity validation"
        if "animation" in msg or "gpu" in msg:
            return "Product Details Screen: Removed heavy GPU animations causing screen flickering"
        if "translate" in msg or "translation" in msg:
            return "Product Details Screen: Translated all text to Arabic/English"
        return "Product Details Screen: UI improvements and updates"

    # ── Product Card ──────────────────────────────────────────
    if "product card" in msg or ("card" in file_paths and "product" in file_paths):
        if "animation" in msg or "hover" in msg or "gpu" in msg:
            return "Product Card: Removed hover animations and shadow effects causing performance issues on web"
        if "overflow" in msg:
            return "Product Card: Fixed text / layout overflow issues in product card"
        if "quantity" in msg:
            return "Product Card: Added editable quantity input with + / - controls directly on card"
        return "Product Card: UI design updates"

    # ── Profile ───────────────────────────────────────────────
    if "profile" in file_paths or "profile" in msg:
        if "password" in msg or "change password" in msg:
            return "Profile Screen: Fixed 'Change Password' functionality on mobile and web"
        if "route" in msg or "header" in msg or "navigation" in msg:
            return "Profile Screen: Fixed screen routing and header navigation issues"
        if "layout" in msg or "responsive" in msg:
            return "Profile Screen: Fixed layout and responsive design for web version"
        if "points" in msg:
            return "Profile Screen: Added/updated loyalty points display in profile"
        return "Profile Screen: UI improvements and bug fixes"

    # ── Auth ──────────────────────────────────────────────────
    if "auth" in file_paths or "auth" in msg or "login" in msg or "register" in msg:
        if "fix" in msg:
            return "Auth Screen: Fixed authentication flow bugs (login / register)"
        return "Auth Screen: Authentication updates"

    # ── Orders ────────────────────────────────────────────────
    if "order" in file_paths or "order" in msg:
        if "tracking" in msg or "track" in msg:
            return "Orders Screen: Fixed order tracking screen and status display"
        if "list" in msg:
            return "Orders Screen: Updated orders list UI and data display"
        if "return" in msg:
            return "Orders Screen: Added/fixed return order functionality"
        if "sar" in msg or "price" in msg:
            return "Orders Screen: Fixed price/SAR currency symbol display in orders"
        return "Orders Screen: Updates and improvements"

    # ── Wishlist ──────────────────────────────────────────────
    if "wishlist" in file_paths or "wishlist" in msg:
        if "oos" in msg or "out of stock" in msg:
            return "Wishlist Screen: Hide wishlist button when product is out of stock"
        if "design" in msg or "ui" in msg:
            return "Wishlist Screen: Redesigned wishlist page layout"
        return "Wishlist Screen: Updates and improvements"

    # ── Blog ──────────────────────────────────────────────────
    if "blog" in file_paths or "blog" in msg:
        if "categor" in msg:
            return "Blog Screen: Added blog categories section"
        if "fix" in msg:
            return "Blog Screen: Fixed blog content loading and display"
        return "Blog Screen: Blog section updates"

    # ── Points ────────────────────────────────────────────────
    if "points" in file_paths or "point" in msg:
        if "refactor" in msg or "ui" in msg:
            return "Points Screen: Refactored / redesigned loyalty points screen UI"
        if "sar" in msg or "price" in msg:
            return "Points Screen: Fixed SAR currency symbol display"
        if "address" in msg:
            return "Points & Address: Fixed address and points display"
        return "Points Screen: Loyalty points feature updates"

    # ── Address ───────────────────────────────────────────────
    if "address" in file_paths or "address" in msg:
        if "dropdown" in msg or "drop down" in msg or "pickup" in msg:
            return "Address: Added dropdown selector for delivery address / pickup location in nav"
        if "gps" in msg:
            return "Address Screen: Fixed GPS-based address detection"
        if "fix" in msg:
            return "Address Screen: Fixed address input and display bugs"
        return "Address Screen: Updates and improvements"

    # ── Web Header / Navbar ───────────────────────────────────
    if "web_header" in file_paths or "header" in file_paths or "navbar" in msg or "header" in msg:
        if "accordion" in msg or "categor" in msg and "dropdown" in msg:
            return "Web Navbar: Converted categories menu to accordion style (piano-style, no flyout)"
        if "hover" in msg:
            return "Web Navbar: Updated hover effects (green highlight on category items only)"
        if "font" in msg or "tajawal" in msg:
            return "Web Navbar: Applied Tajawal font globally across the web header"
        if "arrow" in msg:
            return "Web Navbar: Removed arrow icons from category sub-items (plain text style)"
        if "menu" in msg or "fix" in msg:
            return "Web Navbar: Fixed header menu display and navigation"
        return "Web Header / Navbar: Design and navigation updates"

    # ── Layout / Responsive ───────────────────────────────────
    if "web_shell" in file_paths or "layout" in file_paths or "responsive" in file_paths:
        if "1440" in msg or "wide" in msg or "27" in msg or "whitespace" in msg:
            return "Web Layout: Fixed wide screen (27-inch) dead whitespace — constrained content to 1440px max width"
        if "responsive" in msg or "web responsive" in msg:
            return "Web Layout: Improved responsive design for different screen sizes"
        if "padding" in msg or "percentage" in msg:
            return "Web Layout: Switched to percentage-based padding on large desktop screens"
        return "App Layout: Layout and responsive design improvements"

    # ── SAR / Currency Symbol ─────────────────────────────────
    if "sar" in msg or "saudi riyal" in msg or "riyalsar" in file_paths or "sar_symbol" in file_paths:
        if "font" in msg or "ttf" in msg or "glyph" in msg:
            return "Price Display: Implemented official Saudi Riyal symbol (﷼) using custom font across the entire app"
        if "consistent" in msg or "entire app" in msg:
            return "Price Display: Unified SAR currency symbol display consistently across all screens"
        return "Price Display: Fixed Saudi Riyal currency symbol rendering"

    # ── Translations ──────────────────────────────────────────
    if "ar.json" in file_paths or "en.json" in file_paths or "translation" in msg or "localization" in msg or "i18n" in msg:
        if "hardcoded" in msg:
            return "Translations: Replaced all hardcoded Arabic/English text with translation keys"
        if "missing" in msg:
            return "Translations: Added missing translation keys (Arabic & English)"
        if "audit" in msg:
            return "Translations: Full translation audit — ensured all app text is translatable"
        if "api" in msg or "error" in msg:
            return "Translations: Added Arabic/English error messages from the API"
        if "bnpl" in msg or "cold" in msg:
            return "Translations: Added new translation keys for BNPL and cold-storage features"
        return "Translations: Updated Arabic/English translation files"

    # ── API / Backend ─────────────────────────────────────────
    if "api" in file_paths or "datasource" in file_paths or "dio" in msg or "api" in msg:
        if "error" in msg or "exception" in msg:
            return "API Layer: Improved error messages — now shows readable Arabic/English errors from server instead of raw code"
        if "circular" in msg or "import" in msg:
            return "API Layer: Fixed circular import issue in API error handler"
        if "navigator" in msg:
            return "API Layer: Fixed navigation key reference in API error handler"
        return "API & Backend: Data layer improvements and bug fixes"

    # ── Animation / GPU / Performance ─────────────────────────
    if "gpu" in msg or "animation" in msg or "canvas" in msg or "sparkling" in msg or "backdrop" in msg:
        if "sparkling" in msg or "canvas" in msg or "lottie" in msg:
            return "Performance Fix: Removed Lottie and BackdropFilter animations causing screen sparkling/flickering on web"
        if "boxshadow" in msg or "box shadow" in msg:
            return "Performance Fix: Removed BoxShadow and hover animations from product cards (was causing GPU overload)"
        if "matrix4" in msg or "hover" in msg:
            return "Performance Fix: Removed 3D Matrix hover transform from category cards (GPU layer thrashing)"
        if "eliminate" in msg or "all" in msg:
            return "Performance Fix: Eliminated all GPU-heavy animations across the entire app"
        return "Performance Fix: Removed heavy animations causing rendering issues on web"

    # ── Font ──────────────────────────────────────────────────
    if "font" in msg or "tajawal" in msg or "cairo" in msg:
        if "tajawal" in msg and "global" in msg:
            return "Typography: Set Tajawal as the global font for the entire app (removed Cairo overrides)"
        return "Typography: Font and typography updates"

    # ── Brand ─────────────────────────────────────────────────
    if "brand" in msg:
        if "circle" in msg or "avatar" in msg or "logo" in msg:
            return "Brands Section: Displayed brand logos as circular avatars with gradient initials fallback"
        if "verified" in msg or "checkmark" in msg or "badge" in msg:
            return "Brands Section: Added verified checkmark badge beside brand name"
        return "Brands Section: UI updates for brand display"

    # ── Category ──────────────────────────────────────────────
    if "categor" in msg or "categor" in file_paths:
        if "accordion" in msg:
            return "Categories: Changed category navigation to accordion / expandable style"
        if "sub" in msg or "submenu" in msg:
            return "Categories: Updated sub-category display and navigation"
        if "remove" in msg:
            return "Categories: Removed unused category sections"
        return "Categories: Category page and navigation updates"

    # ── CI/CD / Docker / Deploy ───────────────────────────────
    if ".github" in file_paths or "docker" in file_paths.lower() or "ecs" in msg or "deploy" in msg or "ci" in msg or "cd" in msg:
        if "ecs" in msg or "aws" in msg:
            return "CI/CD: Set up AWS ECS automatic deployment pipeline"
        if "docker" in msg or "dockerfile" in msg.lower():
            return "CI/CD: Fixed Docker configuration and health checks"
        if "cache" in msg:
            return "CI/CD: Added cache-busting mechanism for web deployments"
        if "workflow" in msg or "github action" in msg:
            return "CI/CD: Updated GitHub Actions deployment workflow"
        return "CI/CD & DevOps: Server deployment and pipeline updates"

    # ── Breadcrumb ───────────────────────────────────────────
    if "breadcrumb" in msg:
        return "Navigation: Added/fixed breadcrumb navigation on product and category pages"

    # ── Announcements ─────────────────────────────────────────
    if "announcement" in msg or "announcement" in file_paths:
        return "Announcements Feature: Added announcements/notifications display feature"

    # ── Language Switcher ────────────────────────────────────
    if "language" in msg or "lang" in msg:
        return "Language Switcher: Added Arabic/English language toggle switch"

    # ── Image optimization ────────────────────────────────────
    if "image optim" in msg or "image" in msg and "optim" in msg:
        return "Performance: Optimized images across all pages (faster loading)"

    # ── Onboarding ────────────────────────────────────────────
    if "onboard" in msg:
        return "Onboarding Screens: Initial onboarding / welcome screens setup"

    # ── Setup / Init ──────────────────────────────────────────
    if "setup" in msg or "first commit" in msg or "init" in msg:
        return "Project Setup: Initial project setup and configuration"

    # ── Generic fix patterns ──────────────────────────────────
    if "fix" in msg and "overflow" in msg:
        return "Bug Fix: Fixed UI overflow / layout overflow errors"
    if "fix" in msg and "navigation" in msg or "route" in msg:
        return "Bug Fix: Fixed screen navigation and routing issues"
    if "revert" in msg:
        return "Revert: Reverted a previous change (rolled back)"
    if "merge" in msg:
        return "Merge: Merged code branches together"

    # ── Fallback: smart from file + counts ───────────────────
    screens = get_screens(files)
    screen_str = ", ".join(screens[:2])
    if added > 0 and modified == 0:
        return f"{screen_str}: Added new files/features ({added} files added)"
    if deleted > 0 and modified == 0:
        return f"{screen_str}: Removed unused files ({deleted} files deleted)"
    return f"{screen_str}: Code updates and improvements ({modified} files modified)"


def get_primary_area(files):
    """Get the primary feature area for a commit"""
    area_priority = [
        ('cart',          'Cart (السلة)'),
        ('checkout',      'Checkout (الدفع)'),
        ('home',          'Home (الرئيسية)'),
        ('product_detail','Product Details (تفاصيل المنتج)'),
        ('profile',       'Profile (الملف الشخصي)'),
        ('auth',          'Authentication (تسجيل الدخول)'),
        ('orders',        'Orders (الطلبات)'),
        ('wishlist',      'Wishlist (المفضلة)'),
        ('blog',          'Blog (المدونة)'),
        ('points',        'Points (النقاط)'),
        ('address',       'Address (العناوين)'),
        ('notifications', 'Notifications (الاشعارات)'),
        ('announcements', 'Announcements (الاعلانات)'),
        ('web_header',    'Web Header & Navbar (الهيدر)'),
        ('web_shell|layout|responsive', 'Layout & Responsive (التخطيط)'),
        ('sar_symbol|sar',              'Price Display (عرض السعر)'),
        ('ar.json|en.json|translation', 'Translations (الترجمة)'),
        ('datasource|api|dio',          'API & Backend (البيانات)'),
        ('.github|workflow|docker',     'CI/CD & DevOps'),
        ('pubspec',       'Dependencies (المكتبات)'),
        ('assets',        'Assets (الاصول)'),
    ]
    path_str = " ".join(f["path"].lower() for f in files)
    for pattern, label in area_priority:
        for p in pattern.split("|"):
            if p in path_str:
                return label
    return "General (عام)"


def classify_change(raw_msg, files):
    """Classify the type of change for the client"""
    msg = raw_msg.lower()
    statuses = [f["status"] for f in files]
    if "revert" in msg:
        return "Revert (تراجع)"
    if "merge" in msg:
        return "Merge (دمج)"
    if "fix" in msg or "bug" in msg:
        return "Bug Fix (اصلاح)"
    if "feat" in msg or "feature" in msg or "add" in msg:
        return "New Feature (ميزة جديدة)"
    if "refactor" in msg:
        return "Refactor (اعادة هيكلة)"
    if "enhance" in msg or "improve" in msg or "update" in msg or "upgrade" in msg:
        return "Enhancement (تحسين)"
    if "perf" in msg or "gpu" in msg or "animation" in msg or "optim" in msg:
        return "Performance (تحسين أداء)"
    if "ci" in msg or "cd" in msg or "docker" in msg or "deploy" in msg or "ecs" in msg:
        return "DevOps / Deploy (نشر)"
    if "translation" in msg or "i18n" in msg or "locali" in msg:
        return "Translation (ترجمة)"
    if "A" in statuses and "M" not in statuses:
        return "New Feature (ميزة جديدة)"
    return "Enhancement (تحسين)"


# ============================================================
# 3. Build Excel
# ============================================================

DARK_GREEN = "1B5E20"
MID_GREEN  = "2E7D32"
WHITE      = "FFFFFF"
GRAY       = "FAFAFA"
LIGHT_GRAY = "F5F5F5"

COLOR_POOL = [
    "C8E6C9","E3F2FD","FFF9C4","FFF3E0",
    "E8EAF6","FCE4EC","E0F7FA","F3E5F5",
    "F5F5F5","E8F5E9","F1F8E9","FBE9E7",
    "E1F5FE","F9FBE7","EDE7F6","FFF8E1",
]
area_color_map = {}
def area_color(area):
    if area not in area_color_map:
        area_color_map[area] = COLOR_POOL[len(area_color_map) % len(COLOR_POOL)]
    return area_color_map[area]

CHANGE_COLORS = {
    "Bug Fix":        ("FFEBEE", "B71C1C"),
    "New Feature":    ("E8F5E9", "1B5E20"),
    "Enhancement":    ("FFF8E1", "E65100"),
    "Performance":    ("E3F2FD", "0D47A1"),
    "Translation":    ("F3E5F5", "4A148C"),
    "DevOps":         ("ECEFF1", "455A64"),
    "Refactor":       ("FFF3E0", "BF360C"),
    "Revert":         ("FCE4EC", "880E4F"),
    "Merge":          ("F5F5F5", "424242"),
}

def fill(hex_color):
    return PatternFill("solid", fgColor=hex_color)

def bd():
    s = Side(border_style="thin", color="BDBDBD")
    return Border(left=s, right=s, top=s, bottom=s)

def hfont(size=11, color=WHITE):
    return Font(name="Calibri", size=size, bold=True, color=color)

def dfont(size=10, bold=False, color="212121"):
    return Font(name="Calibri", size=size, bold=bold, color=color)

wb = openpyxl.Workbook()

# ──────────────────────────────────────────────────────────────
# SHEET 1: Client-Friendly Changes Summary (Main Sheet)
# ──────────────────────────────────────────────────────────────
ws1 = wb.active
ws1.title = "Changes Summary"
ws1.freeze_panes = "A3"

# Title banner
ws1.merge_cells("A1:H1")
title_cell = ws1.cell(row=1, column=1, value="FastWay Mobile App — Changes Report  |  تقرير التعديلات")
title_cell.fill = fill(DARK_GREEN)
title_cell.font = Font(name="Calibri", size=15, bold=True, color=WHITE)
title_cell.alignment = Alignment(horizontal="center", vertical="center")
ws1.row_dimensions[1].height = 45

headers1 = [
    "#",
    "Date\n(التاريخ)",
    "Screen / Feature\n(الصفحة / الميزة)",
    "What Changed\n(ايه اللي اتغير)",
    "Change Type\n(نوع التعديل)",
    "Files Changed\n(عدد الملفات)",
    "Commit",
    "Developer\n(المطور)"
]
ws1.row_dimensions[2].height = 40
for col, h in enumerate(headers1, 1):
    c = ws1.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont(10)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

# Filter out merge commits for cleaner report
display_commits = [c for c in commits if not c["raw_msg"].lower().startswith("merge")]

for idx, commit in enumerate(display_commits, 1):
    r = idx + 2
    area = get_primary_area(commit["files"])
    description = humanize(commit["raw_msg"], commit["files"])
    change_type = classify_change(commit["raw_msg"], commit["files"])
    num_files = len(commit["files"])
    bg_area = area_color(area)

    # Change type colors
    ct_bg, ct_fg = "F5F5F5", "424242"
    for key, (bg, fg) in CHANGE_COLORS.items():
        if key in change_type:
            ct_bg, ct_fg = bg, fg
            break

    vals = [idx, commit["date"], area, description, change_type, num_files, commit["hash"], commit["author"]]
    for col, val in enumerate(vals, 1):
        c = ws1.cell(row=r, column=col, value=val)
        c.border = bd()
        c.font = dfont()

        if col == 2:  # date
            c.alignment = Alignment(horizontal="center", vertical="center")
            if idx % 2 == 0: c.fill = fill(GRAY)
        elif col == 3:  # area
            c.fill = fill(bg_area)
            c.font = dfont(bold=True)
            c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
        elif col == 4:  # description (main column)
            c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
            if idx % 2 == 0: c.fill = fill("FFFDE7")
        elif col == 5:  # change type
            c.fill = fill(ct_bg)
            c.font = dfont(bold=True, color=ct_fg)
            c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        elif col == 6:  # file count
            c.alignment = Alignment(horizontal="center", vertical="center")
            if idx % 2 == 0: c.fill = fill(GRAY)
        elif col == 7:  # hash
            c.alignment = Alignment(horizontal="center", vertical="center")
            c.font = dfont(size=9, color="757575")
            if idx % 2 == 0: c.fill = fill(GRAY)
        elif col == 8:  # author
            c.alignment = Alignment(horizontal="center", vertical="center")
            if idx % 2 == 0: c.fill = fill(GRAY)
        else:
            c.alignment = Alignment(horizontal="center", vertical="center")
            if idx % 2 == 0: c.fill = fill(GRAY)

    ws1.row_dimensions[r].height = 38

col_widths1 = [5, 13, 32, 80, 26, 13, 10, 16]
for i, w in enumerate(col_widths1, 1):
    ws1.column_dimensions[get_column_letter(i)].width = w
ws1.auto_filter.ref = f"A2:{get_column_letter(len(headers1))}{len(display_commits)+2}"


# ──────────────────────────────────────────────────────────────
# SHEET 2: Changes Grouped by Screen
# ──────────────────────────────────────────────────────────────
ws2 = wb.create_sheet("By Screen")
ws2.freeze_panes = "A3"

ws2.merge_cells("A1:F1")
t2 = ws2.cell(row=1, column=1, value="FastWay Mobile — Changes Grouped by Screen  |  التعديلات حسب الصفحة")
t2.fill = fill(DARK_GREEN); t2.font = hfont(14)
t2.alignment = Alignment(horizontal="center", vertical="center")
ws2.row_dimensions[1].height = 45

headers2 = ["#", "Screen / Feature", "Date", "What Changed", "Change Type", "Commit"]
ws2.row_dimensions[2].height = 35
for col, h in enumerate(headers2, 1):
    c = ws2.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont()
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

# Group by area
grouped = defaultdict(list)
for commit in display_commits:
    area = get_primary_area(commit["files"])
    grouped[area].append(commit)

row_num = 3
grand_idx = 1
# Sort areas by number of commits (descending)
sorted_areas = sorted(grouped.items(), key=lambda x: -len(x[1]))

for area, area_commits in sorted_areas:
    bg = area_color(area)
    # Area header row
    ws2.merge_cells(f"A{row_num}:F{row_num}")
    header_cell = ws2.cell(row=row_num, column=1,
        value=f"  {area}  ({len(area_commits)} changes)")
    header_cell.fill = fill(bg)
    header_cell.font = Font(name="Calibri", size=11, bold=True, color=DARK_GREEN)
    header_cell.alignment = Alignment(horizontal="left", vertical="center")
    header_cell.border = bd()
    ws2.row_dimensions[row_num].height = 28
    row_num += 1

    for commit in area_commits:
        desc = humanize(commit["raw_msg"], commit["files"])
        change_type = classify_change(commit["raw_msg"], commit["files"])

        ct_bg, ct_fg = "F5F5F5", "424242"
        for key, (cbg, cfg) in CHANGE_COLORS.items():
            if key in change_type:
                ct_bg, ct_fg = cbg, cfg
                break

        vals = [grand_idx, area, commit["date"], desc, change_type, commit["hash"]]
        for col, val in enumerate(vals, 1):
            c = ws2.cell(row=row_num, column=col, value=val)
            c.border = bd(); c.font = dfont()
            c.alignment = Alignment(vertical="center", wrap_text=(col in (2, 4)))
            if col == 2:
                c.fill = fill(bg); c.font = dfont(bold=True, size=9)
            elif col == 3:
                c.alignment = Alignment(horizontal="center", vertical="center")
            elif col == 4:
                c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
            elif col == 5:
                c.fill = fill(ct_bg); c.font = dfont(bold=True, color=ct_fg)
                c.alignment = Alignment(horizontal="center", vertical="center")
            elif col == 6:
                c.font = dfont(size=9, color="9E9E9E")
                c.alignment = Alignment(horizontal="center", vertical="center")
        ws2.row_dimensions[row_num].height = 35
        row_num += 1
        grand_idx += 1

col_widths2 = [5, 32, 13, 85, 26, 10]
for i, w in enumerate(col_widths2, 1):
    ws2.column_dimensions[get_column_letter(i)].width = w


# ──────────────────────────────────────────────────────────────
# SHEET 3: Stats Summary
# ──────────────────────────────────────────────────────────────
ws3 = wb.create_sheet("Stats Overview")

ws3.merge_cells("A1:E1")
t3 = ws3.cell(row=1, column=1, value="FastWay Mobile — Project Stats Overview")
t3.fill = fill(DARK_GREEN); t3.font = hfont(14)
t3.alignment = Alignment(horizontal="center", vertical="center")
ws3.row_dimensions[1].height = 45

# KPI cards row
kpi_data = [
    ("Total Commits", len(commits), "1B5E20"),
    ("Total File Changes", sum(len(c["files"]) for c in commits), "1565C0"),
    ("Features Added", sum(1 for c in commits if classify_change(c["raw_msg"], c["files"]).startswith("New")), "2E7D32"),
    ("Bug Fixes", sum(1 for c in commits if classify_change(c["raw_msg"], c["files"]).startswith("Bug")), "B71C1C"),
    ("Enhancements", sum(1 for c in commits if classify_change(c["raw_msg"], c["files"]).startswith("Enhancement")), "E65100"),
]

for col, (label, value, color) in enumerate(kpi_data, 1):
    # Label
    lc = ws3.cell(row=2, column=col, value=label)
    lc.fill = fill(color); lc.font = hfont(10)
    lc.alignment = Alignment(horizontal="center", vertical="center")
    lc.border = bd(); ws3.row_dimensions[2].height = 30
    # Value
    vc = ws3.cell(row=3, column=col, value=value)
    vc.fill = fill("FAFAFA")
    vc.font = Font(name="Calibri", size=20, bold=True, color=color)
    vc.alignment = Alignment(horizontal="center", vertical="center")
    vc.border = bd(); ws3.row_dimensions[3].height = 45

for i in range(1, 6):
    ws3.column_dimensions[get_column_letter(i)].width = 24

# By area breakdown
ws3.row_dimensions[4].height = 15  # spacer

headers3b = ["Screen / Feature", "# Changes", "New Features", "Bug Fixes", "Enhancements", "Performance"]
ws3.row_dimensions[5].height = 30
for col, h in enumerate(headers3b, 1):
    c = ws3.cell(row=5, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont(10)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

area_type_stats = defaultdict(lambda: defaultdict(int))
for commit in display_commits:
    area = get_primary_area(commit["files"])
    ct = classify_change(commit["raw_msg"], commit["files"])
    area_type_stats[area]["total"] += 1
    if "New Feature" in ct:    area_type_stats[area]["new"] += 1
    elif "Bug Fix" in ct:      area_type_stats[area]["bug"] += 1
    elif "Enhancement" in ct:  area_type_stats[area]["enhance"] += 1
    elif "Performance" in ct:  area_type_stats[area]["perf"] += 1

for i, (area, s) in enumerate(sorted(area_type_stats.items(), key=lambda x: -x[1]["total"]), 6):
    bg = area_color(area)
    vals = [area, s["total"], s["new"], s["bug"], s["enhance"], s["perf"]]
    for col, val in enumerate(vals, 1):
        c = ws3.cell(row=i, column=col, value=val)
        c.border = bd(); c.font = dfont()
        c.alignment = Alignment(horizontal="left" if col==1 else "center", vertical="center")
        if col == 1: c.fill = fill(bg); c.font = dfont(bold=True)
        elif col == 3 and val > 0: c.font = dfont(color="1B5E20", bold=True)
        elif col == 4 and val > 0: c.font = dfont(color="B71C1C", bold=True)
        elif col == 5 and val > 0: c.font = dfont(color="E65100", bold=True)
        elif col == 6 and val > 0: c.font = dfont(color="0D47A1", bold=True)
        if i % 2 == 0 and col not in (1,): c.fill = fill(GRAY) if col != 1 else fill(bg)
    ws3.row_dimensions[i].height = 22


# ──────────────────────────────────────────────────────────────
# Save
# ──────────────────────────────────────────────────────────────
out_path = r"e:\fastway\FastWay_Changes_Report_v2.xlsx"
wb.save(out_path)
print(f"\nSaved: {out_path}")
print(f"  Sheets: {[s.title for s in wb.worksheets]}")
print(f"  Display commits (non-merge): {len(display_commits)}")
print(f"  Unique areas: {len(area_type_stats)}")
