
import openpyxl
from openpyxl.styles import PatternFill, Font, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# ── Styling helpers ───────────────────────────────────────────
def fill(hex_color):
    return PatternFill("solid", fgColor=hex_color)

def bd(color="BDBDBD"):
    s = Side(border_style="thin", color=color)
    return Border(left=s, right=s, top=s, bottom=s)

def hfont(size=11, color="FFFFFF", bold=True):
    return Font(name="Calibri", size=size, bold=bold, color=color)

def dfont(size=10, bold=False, color="212121"):
    return Font(name="Calibri", size=size, bold=bold, color=color)

def al(h="left", v="center", wrap=True):
    return Alignment(horizontal=h, vertical=v, wrap_text=wrap)

# ── Colors ────────────────────────────────────────────────────
DARK_GREEN  = "1B5E20"
MID_GREEN   = "2E7D32"
LIGHT_GREEN = "C8E6C9"
WHITE       = "FFFFFF"
GRAY        = "F5F5F5"
DARK_GRAY   = "ECEFF1"

# Change type color map
CT_COLORS = {
    "ميزة جديدة / New Feature":       ("E8F5E9", "1B5E20"),
    "تعديل UI / UI Change":            ("E3F2FD", "0D47A1"),
    "إصلاح / Bug Fix":                 ("FFEBEE", "B71C1C"),
    "تحسين أداء / Performance":        ("FFF3E0", "E65100"),
    "تاسك / Task":                     ("F3E5F5", "4A148C"),
    "تغيير منطق / Logic Change":       ("FFF9C4", "827717"),
    "حذف / Removed":                   ("FAFAFA", "757575"),
    "ترجمة / Translation":             ("E8EAF6", "283593"),
}

# Screen color map
SCREEN_COLORS = {
    "Web Header & Navbar":      "1565C0",
    "Home Screen":              "2E7D32",
    "Product Details":          "6A1B9A",
    "Cart Screen":              "BF360C",
    "Checkout Screen":          "E65100",
    "Profile / Account":        "00695C",
    "Points Screen":            "4527A0",
    "Product Card":             "0277BD",
    "Bottom Navigation Bar":    "37474F",
    "App-Wide / General":       "455A64",
    "Tasks (Business Logic)":   "880E4F",
    "Announcements":            "558B2F",
    "Categories":               "6D4C41",
    "Banner":                   "00838F",
    "Address / Map":            "283593",
    "Orders":                   "1B5E20",
    "Wishlist":                 "AD1457",
}

# ── All changes data ──────────────────────────────────────────
# (Screen, Sub-feature, What Changed (Arabic), What Changed (English), Change Type, Notes)

CHANGES = [

    # ══════════════════════════════════════════════════════════
    # WEB HEADER & NAVBAR
    # ══════════════════════════════════════════════════════════
    ("Web Header & Navbar", "Header Style",
     "تغيير شكل الهيدر من floating (عايم) إلى solid (ثابت بخلفية صلبة)",
     "Changed header style from floating/transparent to solid fixed background",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Drawer Menu",
     "إضافة Slide Drawer (قائمة جانبية تنزلق) للتنقل في الموبايل",
     "Added slide-in drawer menu for mobile navigation",
     "ميزة جديدة / New Feature", ""),

    ("Web Header & Navbar", "Drawer → Mini Menu",
     "إزالة الـ Drawer واستبداله بقائمة مصغّرة (collapsed mini menu)",
     "Removed the drawer and replaced with a compact mini menu",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Search Bar",
     "تحويل السيرش لـ اقتراحات جاهزة (ready suggestions) مع قائمة منسدلة مصغّرة",
     "Upgraded search bar to show instant ready suggestions with mini dropdown",
     "ميزة جديدة / New Feature", ""),

    ("Web Header & Navbar", "Menu Animation",
     "إضافة animation على القائمة عند فتحها وإغلاقها",
     "Added open/close animation on the navigation menu",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Wishlist Module",
     "إضافة موديول المفضلة كاملاً (Wishlist) مع أيقونة في الهيدر وصفحة مستقلة",
     "Added full Wishlist module with header icon and dedicated wishlist page",
     "ميزة جديدة / New Feature", ""),

    ("Web Header & Navbar", "Sub Header",
     "إضافة Sub-header (شريط ثانوي تحت الهيدر) يحتوي على الأقسام والروابط السريعة",
     "Added a sub-header bar below the main header containing categories and quick links",
     "ميزة جديدة / New Feature", ""),

    ("Web Header & Navbar", "Categories Dropdown",
     "تغيير عرض الأقسام من شريط ثابت إلى Dropdown menu منسدلة في الهيدر",
     "Changed categories from static bar to a dropdown menu in the header",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Category Accordion",
     "تحويل الـ dropdown بتاع الأقسام إلى نمط Accordion (يتمد ويتقلص Piano-style)",
     "Converted the categories dropdown to accordion piano-style (no flyout submenu)",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Hover Effects",
     "تعديل تأثير الـ hover — بقى اللون الأخضر على أيتمز الأقسام فقط (مش كل الهيدر)",
     "Refined hover effects — green highlight only on category sub-items",
     "تعديل UI / UI Change", ""),

    ("Web Header & Navbar", "Verified Badge on Brand",
     "إضافة شارة التحقق (verified blue checkmark) جنب اسم الماركة في الهيدر",
     "Added verified blue checkmark badge beside the brand name in the header",
     "ميزة جديدة / New Feature", ""),

    ("Web Header & Navbar", "Tajawal Font",
     "تطبيق خط Tajawal كخط رئيسي في الهيدر بدلاً من Cairo",
     "Applied Tajawal as the global font for the web header (replaced Cairo)",
     "تعديل UI / UI Change", ""),

    # ══════════════════════════════════════════════════════════
    # HOME SCREEN
    # ══════════════════════════════════════════════════════════
    ("Home Screen", "App Bar → Country Selector",
     "تغيير الـ App Bar في الهوم — أصبح يعرض قائمة اختيار المنطقة/الفرع لإظهار المنتجات حسب الموقع",
     "Changed home app bar to a country/region selector — shows products based on selected location",
     "ميزة جديدة / New Feature", ""),

    ("Home Screen", "Shimmer Loading",
     "استبدال Loading Spinner بـ Shimmer Loading (تحميل بتأثير لمعان) في كل الصفحة الرئيسية",
     "Replaced loading spinner with shimmer skeleton loading effect across the home screen",
     "تحسين أداء / Performance", ""),

    ("Home Screen", "Banner — Full Width",
     "تغيير البانر ليأخذ عرض الشاشة كاملاً في نسخة الويب",
     "Changed the home banner to span full screen width on web",
     "تعديل UI / UI Change", ""),

    ("Home Screen", "Banner → Carousel",
     "تعديل البانر مرة ثانية — أصبح Carousel صغير (slideshow) بدلاً من Full Width",
     "Changed the banner again — became a smaller carousel/slideshow style",
     "تعديل UI / UI Change", ""),

    ("Home Screen", "Blog Section",
     "إضافة قسم المقالات (Blog Section) في الصفحة الرئيسية",
     "Added blog articles section to the home page",
     "ميزة جديدة / New Feature", ""),

    ("Home Screen", "Categories Section Removed",
     "إزالة قسم الأقسام الثابت من الهوم وتحويله إلى Dropdown Menu",
     "Removed the static categories section from home — converted to a dropdown menu",
     "تعديل UI / UI Change", ""),

    ("Home Screen", "Announcements Section",
     "إضافة قسم الإعلانات في الصفحة الرئيسية",
     "Added announcements section to the home screen",
     "ميزة جديدة / New Feature", ""),

    ("Home Screen", "Accordion Section Border",
     "تثبيت البوردر في قسم الـ Accordion وإزالة الأيقونات منه",
     "Fixed/stabilized the accordion section border and removed icons from accordion items",
     "تعديل UI / UI Change", ""),

    ("Home Screen", "Bundle in Accordion",
     "إضافة Bundle (باقة) داخل الـ Accordion Section",
     "Added bundle product type inside the accordion section",
     "ميزة جديدة / New Feature", ""),

    ("Home Screen", "AppBar Extended",
     "تمديد الـ AppBar (Extend) في صفحة الهوم",
     "Extended the AppBar height in the home screen",
     "تعديل UI / UI Change", ""),

    ("Home Screen", "Hide Empty Sections",
     "إخفاء الأقسام الفارغة تلقائياً (لو مفيش منتجات لا يتعرض القسم)",
     "Automatically hide empty home sections (no products = section hidden)",
     "تحسين أداء / Performance", ""),

    ("Home Screen", "Performance — Remove Heavy Animations",
     "إزالة كل الـ Animations الثقيلة من الصفحة الرئيسية (BoxShadow, AnimatedScale, Lottie) — كانت بتسبب وميض في الويب",
     "Removed all GPU-heavy animations from home (BoxShadow, AnimatedScale, Lottie) — were causing flickering on web",
     "تحسين أداء / Performance", ""),

    # ══════════════════════════════════════════════════════════
    # PRODUCT CARD
    # ══════════════════════════════════════════════════════════
    ("Product Card", "Cart Button Style",
     "تغيير شكل زر الإضافة لعربة التسوق في الكارت — أصبح شكله مختلف وأوضح",
     "Redesigned the add-to-cart button on the product card — new distinct style",
     "تعديل UI / UI Change", ""),

    ("Product Card", "Labels Design",
     "تغيير شكل الـ Labels (وفرت / خصم / جديد) على الكارت",
     "Redesigned product labels (discount/new/sale) on the product card",
     "تعديل UI / UI Change", ""),

    ("Product Card", "Cart Icon Size",
     "تظبيط وتكبير أيقونة العربة على الـ product card لتبقى بشكل أوضح وأفضل",
     "Fixed and enlarged the cart icon on the product card for better visibility",
     "تعديل UI / UI Change", ""),

    ("Product Card", "Quantity Field — Editable",
     "إضافة حقل الكمية قابل للتعديل مباشرةً على الكارت مع أزرار + و −",
     "Added editable quantity field directly on the product card with + / − controls",
     "ميزة جديدة / New Feature", ""),

    ("Product Card", "Performance — Remove Hover Animations",
     "إزالة تأثيرات الـ Hover والـ BoxShadow الثقيلة من الكارت (كانت بتسبب GPU overload في الويب)",
     "Removed heavy hover effects and BoxShadow from product cards (was causing GPU overload on web)",
     "تحسين أداء / Performance", ""),

    # ══════════════════════════════════════════════════════════
    # PRODUCT DETAILS
    # ══════════════════════════════════════════════════════════
    ("Product Details", "Layout V1 — Accordion Style",
     "تغيير شكل الصفحة الأول — بدلاً من الصورة فوق والمحتوى تحت في صفحة واحدة، أصبح المحتوى على شكل Accordion (يتفتح ويتقفل)",
     "First redesign: changed from single-page (image top, content below) to accordion-style collapsible sections",
     "تعديل UI / UI Change", ""),

    ("Product Details", "Layout V2 — Split View",
     "تعديل شكل الصفحة مرة ثانية — الصورة على اليمين والمحتوى على اليسار (تصميم Web Split-View)",
     "Second redesign: image on the right, content/details on the left (web split-view layout)",
     "تعديل UI / UI Change", ""),

    ("Product Details", "Image Gallery — Jump & Select",
     "الصور بقت تظهر من الـ Jump وتتحرك — تقدر تختار من بينها وهي بتتنقل بـ Animation",
     "Product images now display with jump/swipe animation — user can select from animated thumbnail strip",
     "ميزة جديدة / New Feature", ""),

    ("Product Details", "Accordion Sections — Collapsed Default",
     "كل أقسام التفاصيل (المكونات / التغذية / الوصف) بتبدأ مقفولة افتراضياً",
     "All product detail accordions (ingredients / nutrition / description) start collapsed by default",
     "تعديل UI / UI Change", ""),

    ("Product Details", "Verified Brand Badge",
     "إضافة شارة التحقق (علامة صح زرقاء) جنب اسم الماركة في صفحة التفاصيل",
     "Added verified blue checkmark badge beside the brand name on the product details page",
     "ميزة جديدة / New Feature", ""),

    ("Product Details", "Brand Circle Avatars",
     "عرض لوجو الماركة كـ Avatar دائري — لو مفيش لوجو يتعرض أول حرفين من الاسم بخلفية gradient",
     "Brands displayed as circular avatars — if no logo, shows 2-char gradient initials fallback",
     "تعديل UI / UI Change", ""),

    ("Product Details", "Nutrition Widget UI",
     "تحديث وتحسين شكل ويدجت معلومات التغذية (Nutrition Info Widget)",
     "Updated and improved the nutrition information widget UI design",
     "تعديل UI / UI Change", ""),

    ("Product Details", "Remove Heavy Animations",
     "إزالة الـ Animations الثقيلة (GPU) من صفحة التفاصيل — كانت بتسبب وميض في الويب",
     "Removed GPU-heavy animations from product details page — were causing screen flickering on web",
     "تحسين أداء / Performance", ""),

    # ══════════════════════════════════════════════════════════
    # CART SCREEN
    # ══════════════════════════════════════════════════════════
    ("Cart Screen", "Previous Orders Display",
     "إضافة عرض الطلبات السابقة في صفحة السلة — يقدر المستخدم يطلبها مجدداً بسهولة",
     "Added previous orders display in the cart — user can easily reorder previous purchases",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Coupon → Moved to Summary",
     "إزالة حقل الكوبون من السلة ونقله داخل قسم الـ Order Summary",
     "Removed the coupon/promo code field from the cart page and moved it inside the Order Summary section",
     "تعديل UI / UI Change", "إيذاؤه العميل ذكر ده تحديداً كتغيير مهم"),

    ("Cart Screen", "Wishlist Button",
     "إضافة زر المفضلة (❤️) على كل منتج في السلة — تقدر تحفظه لو مش عايز تشتريه دلوقتي",
     "Added wishlist button (❤️) on each cart item — user can save items for later",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Express Toggle per Item",
     "إضافة زر Express على كل كارت في السلة — لو المنتج يدعم التوصيل السريع، تقدر تختار إنك عايزه Express أو لا",
     "Added an Express toggle button per cart item — if the product supports express delivery, user can opt in/out per item",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Cold Storage Indicator",
     "إضافة أيقونة ❄️ ونص توضيحي على المنتجات المحتاجة تبريد (Cold Storage) مباشرة على الكارت",
     "Added ❄️ icon and cold-storage hint directly on applicable cart items",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "You Saved Banner",
     "إضافة سيكشن 'وفّرت كام' يظهر فوق زر الانتقال إلى الدفع — يبيّن إجمالي التوفير للمستخدم",
     "Added 'You Saved' section above the checkout button showing total savings amount",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Summary Section — Discount Field",
     "إضافة قسم الخصم داخل سيكشن الـ Order Summary (حقل الكوبون / الخصومات الإضافية)",
     "Added a discount section inside the Order Summary card (coupon code + extra discounts)",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Remove Cash on Delivery",
     "إلغاء خيار 'الدفع عند الاستلام' (Cash on Delivery) من الدفع",
     "Removed the Cash on Delivery payment option",
     "حذف / Removed", ""),

    ("Cart Screen", "Points Payment in Cart",
     "تفعيل استخدام النقاط للدفع مباشرة من السلة — تقدر تحوّل النقاط ودفع منها",
     "Enabled loyalty points payment directly from the cart — user can convert and pay using points",
     "ميزة جديدة / New Feature", ""),

    ("Cart Screen", "Layout Update",
     "تعديل Layout الكامل لصفحة السلة — إعادة ترتيب الأقسام وتحسين الشكل العام",
     "Full layout update for the cart page — reorganized sections and improved overall design",
     "تعديل UI / UI Change", ""),

    # ══════════════════════════════════════════════════════════
    # CHECKOUT SCREEN
    # ══════════════════════════════════════════════════════════
    ("Checkout Screen", "Proceed to Payment Flow",
     "تطوير تدفق 'اتمام الشراء' — انتقال سلس من صفحة السلة إلى صفحة الدفع",
     "Developed the 'Complete Purchase' flow — smooth transition from cart to payment screen",
     "ميزة جديدة / New Feature", ""),

    ("Checkout Screen", "Split Order by Shipping Company",
     "إضافة ميزة تقسيم الأوردر تلقائياً لو المنتجات من شركات شحن مختلفة — مثلاً 2 منتج بشركتين شحن هيتقسموا على أوردرين منفصلين",
     "Added automatic order splitting — if products have different shipping companies, they are split into separate orders automatically (e.g., 2 products = 2 separate orders)",
     "ميزة جديدة / New Feature", "ميزة مهمة جداً للعميل"),

    ("Checkout Screen", "Split Order UI",
     "تغيير شكل الـ UI الخاص بصفحة الـ Checkout ليعكس ميزة تقسيم الأوردر",
     "Updated the Checkout UI design to visually reflect the order splitting feature",
     "تعديل UI / UI Change", ""),

    ("Checkout Screen", "Points Exchange UI — Converter",
     "تغيير شكل قسم استبدال النقاط — بقى Converter ذكي: تكتب النقاط يحسب الريالات، أو تكتب الريالات يحسب النقاط اللازمة",
     "Redesigned the points exchange section — smart converter: enter points → see SAR value, or enter SAR → see required points",
     "تعديل UI / UI Change", ""),

    ("Checkout Screen", "BNPL — Buy Now Pay Later",
     "إضافة خيار 'اشتري دلوقتي وادفع بعدين بدون رسوم' (BNPL) في شاشة الدفع",
     "Added 'Buy Now Pay Later – No Fees' (BNPL) payment option in checkout",
     "ميزة جديدة / New Feature", ""),

    ("Checkout Screen", "Guest Checkout",
     "إضافة إمكانية إتمام الشراء بدون تسجيل دخول (Guest Checkout)",
     "Added guest checkout flow — purchase without requiring login/registration",
     "ميزة جديدة / New Feature", ""),

    ("Checkout Screen", "Express Delivery Selection",
     "دمج اختيار التوصيل السريع (Express) داخل صفحة الـ Checkout",
     "Integrated express delivery selection inside the checkout flow",
     "ميزة جديدة / New Feature", ""),

    # ══════════════════════════════════════════════════════════
    # PROFILE / ACCOUNT
    # ══════════════════════════════════════════════════════════
    ("Profile / Account", "Remove Icon Containers",
     "إزالة الـ Container (الخلفية) من خلف الأيقونات في صفحة الحساب — أيقونات نظيفة بدون خلفية",
     "Removed the container/background behind icons in the account page — clean icon-only style",
     "تعديل UI / UI Change", ""),

    ("Profile / Account", "My Orders Section Title",
     "إضافة عنوان 'طلباتي' كـ Section Title واضح في صفحة الحساب",
     "Added 'My Orders' as a clear section title in the account/profile page",
     "تعديل UI / UI Change", ""),

    ("Profile / Account", "Rewards Section Title",
     "إضافة عنوان 'المكافآت' كـ Section Title في صفحة الحساب",
     "Added 'Rewards / My Rewards' as a section title in the account page",
     "تعديل UI / UI Change", ""),

    ("Profile / Account", "Branch Addresses Map",
     "إضافة خريطة بمواقع كل الفروع في صفحة الحساب",
     "Added an interactive map showing all branch addresses in the account/profile page",
     "ميزة جديدة / New Feature", ""),

    ("Profile / Account", "Change Password Fix",
     "إصلاح وظيفة 'تغيير كلمة المرور' على الموبايل والويب",
     "Fixed 'Change Password' functionality on both mobile and web",
     "إصلاح / Bug Fix", ""),

    ("Profile / Account", "Responsive Layout Fix",
     "إصلاح الـ Layout والـ Responsive Design لصفحة الملف الشخصي في نسخة الويب",
     "Fixed the layout and responsive design for the profile/account screen on web",
     "إصلاح / Bug Fix", ""),

    # ══════════════════════════════════════════════════════════
    # POINTS SCREEN
    # ══════════════════════════════════════════════════════════
    ("Points Screen", "UI Refactor",
     "إعادة تصميم صفحة النقاط بالكامل — تحسين الشكل وتوضيح كيفية كسب وصرف النقاط",
     "Full redesign of the loyalty points screen — improved layout and clearer points earn/redeem display",
     "تعديل UI / UI Change", ""),

    ("Points Screen", "SAR Symbol Fix",
     "إصلاح ظهور رمز الريال السعودي (﷼) في صفحة النقاط",
     "Fixed the Saudi Riyal (SAR) symbol display on the points screen",
     "إصلاح / Bug Fix", ""),

    # ══════════════════════════════════════════════════════════
    # BOTTOM NAVIGATION BAR
    # ══════════════════════════════════════════════════════════
    ("Bottom Navigation Bar", "Tabs Update",
     "تحديث الـ Bottom Navigation Bar — التبويبات بقت: الرئيسية / السلة / النقاط / الحساب",
     "Updated the Bottom Navigation Bar tabs to: Home / Cart / Points / Account",
     "تعديل UI / UI Change", ""),

    # ══════════════════════════════════════════════════════════
    # APP-WIDE / GENERAL
    # ══════════════════════════════════════════════════════════
    ("App-Wide / General", "SAR Currency Symbol",
     "تطبيق رمز الريال السعودي الرسمي (﷼) باستخدام خط مخصص في كل الأماكن في التطبيق",
     "Implemented the official Saudi Riyal symbol (﷼) via custom font across the entire app",
     "ميزة جديدة / New Feature", ""),

    ("App-Wide / General", "Tajawal Global Font",
     "تطبيق خط Tajawal كخط رسمي للتطبيق بالكامل (عوض خط Cairo)",
     "Set Tajawal as the global font for the entire app (replaced Cairo)",
     "تعديل UI / UI Change", ""),

    ("App-Wide / General", "Font Icons Change",
     "تغيير خط الأيقونات (Icon Font) المستخدم في التطبيق",
     "Changed the icon font used throughout the app",
     "تعديل UI / UI Change", ""),

    ("App-Wide / General", "Full Translation — Arabic & English",
     "ترجمة كامل النصوص في التطبيق — استبدال كل النصوص الـ Hardcoded بـ Translation Keys عربي/إنجليزي",
     "Full app translation — replaced all hardcoded strings with Arabic/English translation keys",
     "ترجمة / Translation", ""),

    ("App-Wide / General", "Language Switcher",
     "إضافة زر تبديل اللغة (عربي / English) في التطبيق",
     "Added Arabic/English language switcher toggle",
     "ميزة جديدة / New Feature", ""),

    ("App-Wide / General", "API Error Messages",
     "تحسين رسائل الأخطاء — بقت بتظهر رسالة عربي/إنجليزي واضحة من السيرفر بدلاً من كود خطأ تقني",
     "Improved error messages — now shows clear Arabic/English messages from server instead of raw error codes",
     "تحسين أداء / Performance", ""),

    ("App-Wide / General", "Performance — Remove All Heavy Animations",
     "إزالة كل الـ Animations الثقيلة من كل صفحات التطبيق (GPU-heavy: Lottie, BackdropFilter, BoxShadow, Matrix4 transforms)",
     "Eliminated all GPU-heavy animations across all app pages (Lottie, BackdropFilter, BoxShadow, Matrix4 transforms)",
     "تحسين أداء / Performance", ""),

    ("App-Wide / General", "Responsive Web — Wide Screens",
     "إصلاح الشاشات العريضة (27 بوصة) — تحديد عرض أقصى 1440px لمنع المساحات البيضاء الكبيرة على الجوانب",
     "Fixed wide screen (27-inch) dead whitespace — constrained content to 1440px max width",
     "إصلاح / Bug Fix", ""),

    ("App-Wide / General", "CI/CD — AWS ECS Auto Deploy",
     "إعداد Pipeline نشر تلقائي على AWS ECS — كل تحديث يتنشر تلقائياً على السيرفر",
     "Set up automatic deployment pipeline on AWS ECS — every update auto-deploys to server",
     "ميزة جديدة / New Feature", ""),

    # ══════════════════════════════════════════════════════════
    # TASKS (BUSINESS LOGIC)
    # ══════════════════════════════════════════════════════════
    ("Tasks (Business Logic)", "Task 1 — Sub-Renting (تكملة من الخارج)",
     "تجاوز حدود المخزون (Sub-Renting): إضافة Checkbox 'تكملة من الخارج' على كل صنف — يسمح بكمية أكبر من المتاح مع تعليم الصنف is_sub_rented في قاعدة البيانات",
     "Override inventory limits (sub-renting): added 'Sub-rented' checkbox per item — allows quantity beyond available stock, marked as is_sub_rented in DB",
     "تاسك / Task", "Task 1 of 6 — involves UI, Logic, Database RPC"),

    ("Tasks (Business Logic)", "Task 2 — Editable Invoice Date (تعديل تاريخ الفاتورة)",
     "إضافة DatePicker لاختيار تاريخ الفاتورة عند الإنشاء/التعديل — مع ضبط اليوم الحالي كافتراضي وتمرير التاريخ لـ SQL بدلاً من now()",
     "Added invoice date picker in create/edit screens — defaults to today, passes selected date to SQL instead of forcing now()",
     "تاسك / Task", "Task 2 of 6 — involves UI, Logic, Database RPC"),

    ("Tasks (Business Logic)", "Task 3 — Case-Insensitive Search (تحسين البحث)",
     "إصلاح البحث في الأصناف — يتجاهل الأحرف الكبيرة/الصغيرة والمسافات الزائدة، مع دعم اختياري لتجاهل الهمزات في البحث العربي",
     "Fixed item search to be case-insensitive and trim-aware; optional Arabic hamza normalization for faster Arabic search",
     "تاسك / Task", "Task 3 of 6 — Logic fix in RawAutocomplete optionsBuilder"),

    ("Tasks (Business Logic)", "Task 4 — Multi-Tier Pricing (نظام تسعير 3 في 1)",
     "نظام تسعير ذكي: 3 أسعار لكل صنف (فيلم / مسلسل / إعلان) — عند اختيار نوع العمل في الفاتورة يتعبأ السعر تلقائياً مع إمكانية التعديل اليدوي",
     "Smart multi-tier pricing: 3 prices per item (Film / Series / Ad) — selecting job type auto-fills price field, manual override still allowed",
     "تاسك / Task", "Task 4 of 6 — involves Database new fields + UI Dropdown + Logic"),

    ("Tasks (Business Logic)", "Task 5 — Delete Items in Edit Mode (حذف صنف من فاتورة محفوظة)",
     "تفعيل حذف الأصناف القديمة من الفاتورة في وضع التعديل — مع إرجاع الكمية للمخزون تلقائياً عند الحذف",
     "Enabled deleting existing items from saved invoices in edit mode — automatically returns quantity to inventory on delete",
     "تاسك / Task", "Task 5 of 6 — involves UI, Cubit list tracking, Database RPC"),

    ("Tasks (Business Logic)", "Task 6 — Save as Draft (حفظ كمسودة)",
     "إضافة زر 'حفظ كمسودة' — تحفظ الفاتورة بدون إتمام الدفع، وتظهر شارة 'مسودة' في القائمة، وعند النقر تفتح للتعديل وإضافة الدفعة وتأكيدها",
     "Added 'Save as Draft' button — saves invoice without payment, shows 'Draft' badge in list, opens in edit mode to complete later",
     "تاسك / Task", "Task 6 of 6 — involves UI status chip, Cubit status enum, Listing screen"),

    # ══════════════════════════════════════════════════════════
    # ORDERS
    # ══════════════════════════════════════════════════════════
    ("Orders", "Order Tracking Fix",
     "إصلاح شاشة تتبع الطلب — عرض حالة الطلب والشحن بشكل صحيح",
     "Fixed order tracking screen — correct order status and shipping display",
     "إصلاح / Bug Fix", ""),

    ("Orders", "SAR Symbol in Orders",
     "إصلاح ظهور رمز الريال السعودي (﷼) في صفحة الطلبات وكارت الطلب",
     "Fixed SAR symbol display in orders list and order card",
     "إصلاح / Bug Fix", ""),

    # ══════════════════════════════════════════════════════════
    # WISHLIST
    # ══════════════════════════════════════════════════════════
    ("Wishlist", "Wishlist Module — Full Feature",
     "إضافة موديول المفضلة كاملاً — أيقونة في الهيدر، صفحة المفضلة، إضافة وحذف المنتجات من المفضلة",
     "Added full Wishlist module — header icon, dedicated wishlist page, add/remove products from wishlist",
     "ميزة جديدة / New Feature", ""),

    ("Wishlist", "Hide on Out of Stock",
     "إخفاء زر المفضلة تلقائياً لو المنتج غير متاح (Out of Stock)",
     "Automatically hide wishlist button when product is out of stock",
     "تغيير منطق / Logic Change", ""),

    ("Wishlist", "Wishlist Design",
     "إعادة تصميم صفحة المفضلة — تحسين الشكل والـ Layout",
     "Redesigned the wishlist page — improved layout and visual design",
     "تعديل UI / UI Change", ""),

    # ══════════════════════════════════════════════════════════
    # ANNOUNCEMENTS / CATEGORIES
    # ══════════════════════════════════════════════════════════
    ("Announcements", "Announcements Feature",
     "إضافة ميزة الإعلانات (Announcements) — عرض الإعلانات في الهوم والتطبيق",
     "Added announcements feature — announcements displayed on home and throughout the app",
     "ميزة جديدة / New Feature", ""),

    ("Categories", "Category Page — Brand & Subcategory",
     "تحسين صفحة الأقسام والأقسام الفرعية — إضافة عرض الماركات (Brands) مع الأقسام",
     "Enhanced the category and sub-category page — added brand display alongside categories",
     "تعديل UI / UI Change", ""),

    ("Address / Map", "Address Screen Fix",
     "إصلاح شاشة العناوين — إدخال وعرض العنوان بشكل صحيح مع GPS",
     "Fixed the address screen — correct address input and GPS-based detection",
     "إصلاح / Bug Fix", ""),

    ("Address / Map", "Address Dropdown in Navbar",
     "إضافة Dropdown في الـ Navbar لاختيار عنوان التوصيل / نقطة الاستلام",
     "Added address/pickup dropdown in the navbar for quick delivery address selection",
     "ميزة جديدة / New Feature", ""),
]

# ══════════════════════════════════════════════════════════════
# Build Excel Workbook
# ══════════════════════════════════════════════════════════════
wb = openpyxl.Workbook()

# ─── SHEET 1: Main Client Report ──────────────────────────────
ws1 = wb.active
ws1.title = "Client Report"
ws1.freeze_panes = "A3"
ws1.sheet_view.rightToLeft = False  # LTR

# ── Title Row ──────────────────────────────────────────────
ws1.merge_cells("A1:G1")
tc = ws1.cell(row=1, column=1,
    value="FastWay Mobile App — Full Change Log  |  سجل التعديلات الكامل")
tc.fill = fill(DARK_GREEN)
tc.font = Font(name="Calibri", size=15, bold=True, color=WHITE)
tc.alignment = Alignment(horizontal="center", vertical="center")
ws1.row_dimensions[1].height = 50

# ── Column Headers ─────────────────────────────────────────
headers = ["#", "Screen / الشاشة", "Feature / الميزة",
           "What Changed — Arabic\nايه اللي اتغير (عربي)",
           "What Changed — English",
           "Change Type\nنوع التعديل", "Notes / ملاحظات"]
ws1.row_dimensions[2].height = 45
for col, h in enumerate(headers, 1):
    c = ws1.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN)
    c.font = hfont(10)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

# ── Data Rows ──────────────────────────────────────────────
prev_screen = None
screen_start_row = 3
idx = 1

for i, (screen, feature, ar, en, ct, notes) in enumerate(CHANGES):
    r = i + 3

    # Screen color
    screen_hex = SCREEN_COLORS.get(screen, "455A64")

    # Change type colors
    ct_bg, ct_fg = CT_COLORS.get(ct, ("F5F5F5", "424242"))

    # Row zebra
    row_bg = "FFFFFF" if i % 2 == 0 else "F9FBF9"

    vals = [idx, screen, feature, ar, en, ct, notes]
    for col, val in enumerate(vals, 1):
        c = ws1.cell(row=r, column=col, value=val)
        c.border = bd()

        if col == 1:  # index
            c.font = dfont(bold=True, color=screen_hex)
            c.fill = fill(row_bg)
            c.alignment = Alignment(horizontal="center", vertical="center")

        elif col == 2:  # screen
            c.fill = fill(screen_hex)
            c.font = Font(name="Calibri", size=9, bold=True, color=WHITE)
            c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

        elif col == 3:  # feature
            c.fill = fill("EFF6EF" if i % 2 == 0 else "E8F5E9")
            c.font = dfont(bold=True, color=screen_hex)
            c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)

        elif col == 4:  # Arabic description
            c.fill = fill(row_bg)
            c.font = Font(name="Calibri", size=10, color="1A1A1A")
            c.alignment = Alignment(horizontal="right", vertical="center", wrap_text=True, readingOrder=2)

        elif col == 5:  # English description
            c.fill = fill(row_bg)
            c.font = dfont(size=10)
            c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)

        elif col == 6:  # change type
            c.fill = fill(ct_bg)
            c.font = Font(name="Calibri", size=9, bold=True, color=ct_fg)
            c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

        elif col == 7:  # notes
            c.fill = fill("FFFDE7" if notes else row_bg)
            c.font = dfont(size=9, color="5D4037" if notes else "BDBDBD")
            c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)

    ws1.row_dimensions[r].height = 55
    idx += 1

# ── Column Widths ──────────────────────────────────────────
for i, w in enumerate([4, 20, 24, 52, 52, 22, 30], 1):
    ws1.column_dimensions[get_column_letter(i)].width = w

ws1.auto_filter.ref = f"A2:{get_column_letter(7)}{len(CHANGES)+2}"


# ─── SHEET 2: Grouped by Screen ──────────────────────────────
ws2 = wb.create_sheet("By Screen")
ws2.freeze_panes = "A3"

ws2.merge_cells("A1:F1")
t2 = ws2.cell(row=1, column=1,
    value="FastWay Mobile — Changes by Screen  |  التعديلات مقسمة حسب الشاشة")
t2.fill = fill(DARK_GREEN); t2.font = hfont(14)
t2.alignment = Alignment(horizontal="center", vertical="center")
ws2.row_dimensions[1].height = 45

h2 = ["#", "Screen", "Feature", "What Changed (Arabic)", "What Changed (English)", "Type"]
ws2.row_dimensions[2].height = 35
for col, h in enumerate(h2, 1):
    c = ws2.cell(row=2, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont(10)
    c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    c.border = bd()

# Group by screen
from collections import defaultdict, OrderedDict
grouped = defaultdict(list)
for item in CHANGES:
    grouped[item[0]].append(item)

row_num = 3
grand_idx = 1
for screen, items in sorted(grouped.items(), key=lambda x: list(SCREEN_COLORS.keys()).index(x[0]) if x[0] in SCREEN_COLORS else 99):
    screen_hex = SCREEN_COLORS.get(screen, "455A64")

    # Section header
    ws2.merge_cells(f"A{row_num}:F{row_num}")
    sh = ws2.cell(row=row_num, column=1,
        value=f"  ►  {screen}  —  {len(items)} changes")
    sh.fill = fill(screen_hex)
    sh.font = Font(name="Calibri", size=11, bold=True, color=WHITE)
    sh.alignment = Alignment(horizontal="left", vertical="center")
    sh.border = bd()
    ws2.row_dimensions[row_num].height = 30
    row_num += 1

    for j, (_, feature, ar, en, ct, _) in enumerate(items):
        ct_bg, ct_fg = CT_COLORS.get(ct, ("F5F5F5", "424242"))
        row_bg = "FFFFFF" if j % 2 == 0 else "F4FAF4"

        vals = [grand_idx, screen, feature, ar, en, ct]
        for col, val in enumerate(vals, 1):
            c = ws2.cell(row=row_num, column=col, value=val)
            c.border = bd(); c.font = dfont()

            if col == 1:
                c.font = dfont(bold=True, color=screen_hex)
                c.fill = fill(row_bg)
                c.alignment = Alignment(horizontal="center", vertical="center")
            elif col == 2:
                c.fill = fill(screen_hex)
                c.font = Font(name="Calibri", size=8, bold=True, color=WHITE)
                c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            elif col == 3:
                c.fill = fill(row_bg)
                c.font = dfont(bold=True, color=screen_hex)
                c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
            elif col == 4:
                c.fill = fill(row_bg)
                c.font = Font(name="Calibri", size=10)
                c.alignment = Alignment(horizontal="right", vertical="center", wrap_text=True, readingOrder=2)
            elif col == 5:
                c.fill = fill(row_bg)
                c.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
            elif col == 6:
                c.fill = fill(ct_bg)
                c.font = Font(name="Calibri", size=9, bold=True, color=ct_fg)
                c.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

        ws2.row_dimensions[row_num].height = 52
        row_num += 1
        grand_idx += 1

for i, w in enumerate([4, 20, 24, 52, 52, 22], 1):
    ws2.column_dimensions[get_column_letter(i)].width = w


# ─── SHEET 3: Stats Overview ─────────────────────────────────
ws3 = wb.create_sheet("Stats Overview")

ws3.merge_cells("A1:E1")
t3 = ws3.cell(row=1, column=1, value="FastWay Mobile — Project Stats  |  إحصائيات المشروع")
t3.fill = fill(DARK_GREEN); t3.font = hfont(14)
t3.alignment = Alignment(horizontal="center", vertical="center")
ws3.row_dimensions[1].height = 45

# Count by type
type_counts = defaultdict(int)
screen_counts = defaultdict(int)
for item in CHANGES:
    type_counts[item[4]] += 1
    screen_counts[item[0]] += 1

total = len(CHANGES)
kpis = [
    ("Total Changes", total, "1B5E20"),
    ("New Features", type_counts.get("ميزة جديدة / New Feature", 0), "2E7D32"),
    ("UI Changes", type_counts.get("تعديل UI / UI Change", 0), "0D47A1"),
    ("Bug Fixes", type_counts.get("إصلاح / Bug Fix", 0), "B71C1C"),
    ("Performance Fixes", type_counts.get("تحسين أداء / Performance", 0), "E65100"),
]

# KPI row
ws3.row_dimensions[2].height = 32
ws3.row_dimensions[3].height = 50
for col, (label, value, color) in enumerate(kpis, 1):
    lc = ws3.cell(row=2, column=col, value=label)
    lc.fill = fill(color); lc.font = hfont(10); lc.border = bd()
    lc.alignment = Alignment(horizontal="center", vertical="center")
    vc = ws3.cell(row=3, column=col, value=value)
    vc.fill = fill("FAFAFA")
    vc.font = Font(name="Calibri", size=22, bold=True, color=color)
    vc.alignment = Alignment(horizontal="center", vertical="center")
    vc.border = bd()
    ws3.column_dimensions[get_column_letter(col)].width = 24

# By screen table
ws3.row_dimensions[5].height = 30
for col, h in enumerate(["Screen / الشاشة", "# Changes", "% of Total"], 1):
    c = ws3.cell(row=5, column=col, value=h)
    c.fill = fill(MID_GREEN); c.font = hfont(10)
    c.alignment = Alignment(horizontal="center", vertical="center"); c.border = bd()

for i, (screen, count) in enumerate(sorted(screen_counts.items(), key=lambda x: -x[1]), 6):
    sc = SCREEN_COLORS.get(screen, "455A64")
    pct = f"{round(count/total*100,1)}%"
    for col, val in enumerate([screen, count, pct], 1):
        c = ws3.cell(row=i, column=col, value=val)
        c.border = bd(); c.font = dfont()
        c.alignment = Alignment(horizontal="left" if col==1 else "center", vertical="center")
        if col == 1: c.fill = fill(sc); c.font = Font(name="Calibri", size=10, bold=True, color=WHITE)
        elif col == 2: c.font = Font(name="Calibri", size=11, bold=True, color=sc)
        if i % 2 == 0 and col != 1: c.fill = fill("FAFAFA")
    ws3.row_dimensions[i].height = 22

ws3.column_dimensions["A"].width = 32
ws3.column_dimensions["B"].width = 15
ws3.column_dimensions["C"].width = 15


# ─── Save ─────────────────────────────────────────────────────
out_path = r"e:\fastway\FastWay_Client_Change_Log.xlsx"
wb.save(out_path)
print(f"Saved: {out_path}")
print(f"  Total changes: {len(CHANGES)}")
print(f"  Screens covered: {len(screen_counts)}")
print(f"  Sheets: {[s.title for s in wb.worksheets]}")
