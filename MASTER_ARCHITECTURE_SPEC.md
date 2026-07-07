# Master System Architecture Rules & Defaults

**גרסה: 1.1.0** | עדכון אחרון: 2026-07-07

*הנחיות פיתוח קשיחות עבור סוכני קוד (Claude Code / Cursor / Lovable)*

מסמך זה מגדיר את חוקי הבסיס, הארכיטקטורה, מבנה מסדי הנתונים ותצורת ממשק המשתמש עבור הפרויקט. כל פיצ'ר, רכיב, או שינוי בקוד ובמסד הנתונים שנוצרים על ידי סוכן ה-AI חייבים להתבצע בהתאמה מלאה למפרט זה.

## היסטוריית גרסאות (Document Changelog)

| גרסה | תאריך | שינויים |
|------|--------|---------|
| 1.1.0 | 2026-07-07 | הוספת מספר גרסה למסמך + סעיף תחולה (סעיף 0): הכללים חלים על כל מערכת, קיימת או חדשה |
| 1.0.0 | 2026-07-07 | גרסת בסיס — המסמך המקורי (PDF) |

---

## 0. תחולה (Scope of Applicability)

- **הכללים במסמך זה חלים על כל מערכת, ללא יוצא מן הכלל** — לא משנה מה מטרת המערכת, גודלה, או הסטאק הטכנולוגי שלה.
- **מערכת חדשה**: המסמך הוא נקודת הפתיחה. אין לכתוב שורת קוד ראשונה לפני שהתשתיות בסעיפים 1–5 קיימות (סכמת בסיס, RTL, חוזה שגיאות, RBAC).
- **מערכת קיימת**: הכללים חלים גם עליה. אימוץ מתבצע **בהדרגה ודרך Migrations** — כל טבלת ליבה חסרה (`system_changelog`, `activity_logs`, `feature_flags`, `app_settings`) תתווסף בקובץ migration אינקרמנטלי, וכל קוד חדש או קוד שנוגעים בו יעמוד בכללים. אין לשבור פונקציונליות קיימת לצורך התאמה רטרואקטיבית בבת אחת.
- **התאמה לסטאק**: כאשר המערכת אינה בסטאק המתואר במסמך (למשל Python/Flask במקום Node.js), העקרונות מחייבים והמימוש מתורגם לכלי המקבילים באותו סטאק (למשל: client רשמי של Turso לאותה שפה, או שכבת ה-DB הקיימת; הצגת גרסה מקובץ הגרסה של הפרויקט במקום `package.json`).

---

## 1. תשתית טכנולוגית ובסיס נתונים (Turso / SQLite)

- **ספק בסיס הנתונים:** שימוש בלעדי ב-**Turso** באמצעות חבילת `@libsql/client`.
- **סינטקס:** כתיבת קוד ושאילתות בסינטקס SQLite סטנדרטי התואם ל-Turso.
- **טיפוסי נתונים:** שימוש ב-`TEXT` עבור UUIDs וכתובות זמן (ISO Timestamps). עבור אובייקטים מורכבים יש להשתמש ב-`TEXT` עם ולידציית JSON.
- **ניהול שינויים (Migrations):** כל שינוי או הוספה של סכמה יתבצעו אך ורק כקובצי SQL אינקרמנטליים בתוך תיקיית `/migrations`.

### סכמת בסיס הנתונים המרכזית (גרסאות, לוגים ודגלים)

```sql
-- 1. System Version & Deployment Changelog
CREATE TABLE IF NOT EXISTS system_changelog (
    id TEXT PRIMARY KEY,
    version TEXT NOT NULL, -- e.g., "1.0.0"
    title TEXT NOT NULL,
    description TEXT,
    type TEXT CHECK(type IN ('feature', 'fix', 'security', 'perf')) NOT NULL,
    released_at TEXT DEFAULT (CURRENT_TIMESTAMP)
);

-- 2. Master Activity & Audit Logging (יומן פעילות מלא)
CREATE TABLE IF NOT EXISTS activity_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT, -- Nullable עבור פעולות בדפי נחיתה ציבוריים
    action TEXT NOT NULL, -- e.g., "user.login", "lead.captured", "invoice.created"
    entity_type TEXT NOT NULL, -- e.g., "users", "billing"
    entity_id TEXT,
    metadata TEXT, -- ייצוג מחרוזת JSON של השינוי, IP או מאפיינים נוספים של הלקוח
    created_at TEXT DEFAULT (CURRENT_TIMESTAMP)
);

-- 3. Feature Flag & Toggle Controls
CREATE TABLE IF NOT EXISTS feature_flags (
    id TEXT PRIMARY KEY,
    flag_key TEXT UNIQUE NOT NULL,
    is_enabled INTEGER CHECK(is_enabled IN (0, 1)) DEFAULT 0,
    rollout_percentage INTEGER CHECK(rollout_percentage BETWEEN 0 AND 100) DEFAULT 100,
    description TEXT,
    updated_at TEXT DEFAULT (CURRENT_TIMESTAMP)
);

-- 4. Dynamic App Settings Table
CREATE TABLE IF NOT EXISTS app_settings (
    setting_key TEXT PRIMARY KEY,
    setting_value TEXT NOT NULL,
    updated_at TEXT DEFAULT (CURRENT_TIMESTAMP)
);
```

---

## 2. חוקי ממשק גלובליים (RTL & Navigation)

- **כיווניות (RTL):** האפליקציה כולה תעוצב ותורנדר ב-**מלא RTL** (`dir="rtl"`) על תגית ה-`html` או ה-`body`. עברית היא שפת ברירת המחדל לכל רכיבי הממשק.
- **עיצוב וסטייל:** שימוש בנכסים לוגיים של Tailwind CSS (כגון `ms-*`, `pe-*`, `space-x-reverse`) כדי להבטיח זרימת ממשק תקינה וחסינה ב-RTL.
- **ניווט בריחוף עכבר (Hover Navigation):** מערכת הניווט המרכזית (תפריטים, מעברי טאבים) חייבת להחליף תצוגות או לפתוח תתי-תפריטים באופן מיידי בעת **ריחוף עכבר (MouseOver)** לחוויית משתמש מהירה וזורמת.
- **תמיכה במובייל:** יש לספק מנגנון גיבוי נקי (Click/Tap) עבור מכשירי מגע בהם ריחוף עכבר אינו קיים.

---

## 3. מסך ותהליך התחברות אחיד (Login Flow)

- **שער כניסה אחיד:** שימוש במסך התחברות/הרשמה רספונסיבי בעיצוב מינימליסטי ויוקרתי (Minimalist Luxury) כשער כניסה קבוע לכל הנתיבים המאובטחים. המבנה נשאר זהה בין הפרויקטים השונים.
- **תיעוד כניסות:** כל יצירת סשן מוצלחת של משתמש חייבת להוסיף באופן אוטומטי שורה לטבלת ה-`activity_logs` עם הפעולה `"user.login"`.

---

## 4. חוזה שגיאות אחיד (Unified Error Schema)

כל ה-API Interceptors, ה-Controllers, ובלוקי ה-try/catch הגלובליים בצד השרת חייבים להחזיר מבנה JSON אחיד וקבוע לקליינט במקרה של שגיאה:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE_STRING",
    "message": "הסבר ידידותי למשתמש בעברית תקינה",
    "timestamp": "2026-07-07T13:08:00Z"
  }
}
```

---

## 5. דרישות ארכיטקטורה נוספות

### ניהול הרשאות ותפקידים (Multi-Tenant RBAC)

רשומות המשתמשים חייבות לכלול הגדרת תפקיד `'member'`, `'admin'`, `'super_admin'`, `'viewer'`. יש לייצר שכבת הגנה (Guard/Middleware) בצד השרת החוסמת גישה לנתיבי API על בסיס תפקידים אלו.

### שמירת מצב ממשק גלובלי (UI State Persistence)

קלטים זמניים של משתמשים, סינונים פעילים בטבלאות ומצבי ניווט נוכחיים יישמרו אוטומטית ב-`localStorage` או ב-URL Query States. הדבר מבטיח ששום מידע או הקשר לא יאבדו כאשר המשתמש מרחף ועובר בין תפריטים במהירות.

---

## 6. הנחיות לעבודה וזרימת פיתוח (Workflow Instructions)

1. **בדיקת גרסאות:** כל תהליך Deploy חייב לקרוא את הגרסה הנוכחית מתוך קובץ ה-`package.json` ולהציג אותה באופן קבוע וסמוי בממשק (למשל, ב-Footer של האפליקציה).
2. **בדיקת דגלים:** לפני מימוש או שינוי של פיצ'ר, יש לעטוף את הלוגיקה בבדיקה מול טבלת ה-`feature_flags`.
3. **תיעוד פעילות:** כל שינוי בנתונים, שינוי מצב קריטי או אירוע התחברות חייבים להפעיל את פונקציית העזר הגלובלית כדי לכתוב רשומה חדשה ב-`activity_logs`.
4. **בטיחות ב-RTL:** אין להשתמש בעיצובי כיווניות מוחלטים (כמו `left-4` או `pl-2`) ללא בדיקת התנהגותם ב-RTL. יש להעדיף תמיד תכונות לוגיות (Logical Utilities).

---

*Master System Architecture Spec — v1.1.0*
