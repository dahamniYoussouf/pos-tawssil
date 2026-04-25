# WordPress Admin Automation

Scripts to keep the WordPress menu aligned with `Produit > Categories` and to audit or trigger WordPress automation jobs.

## Files

- `auditProductCategoryMenu.mjs`: read-only audit of missing items, hierarchy mismatches, and duplicates.
- `syncProductCategoryMenu.mjs`: adds missing product categories to the target menu and fixes the canonical hierarchy.
- `installWpMenuSyncScheduledTask.ps1`: registers a daily Windows Task Scheduler job for the menu sync script.
- `auditFeedAutomation.mjs`: audits feed automation, cron hooks, and site health from WordPress admin.
- `triggerWpCron.mjs`: triggers `wp-cron.php` without logging into WordPress.
- `installWpCronScheduledTask.ps1`: registers a recurring Windows Task Scheduler job to trigger `wp-cron.php`.

## Env

Create `backend/.env.wp-menu-sync.local` from `backend/.env.wp-menu-sync.example`.

Required variables for admin automation:

- `WP_BASE_URL`
- `WP_ADMIN_USER`
- `WP_ADMIN_PASS`

Optional variables:

- `WP_MENU_ID`
- `WP_MENU_NAME`
- `WP_BROWSER_PATH`
- `WP_HEADLESS`
- `WP_CRON_TIMEOUT_MS`

## Commands

```powershell
cd backend
node .\scripts\wordpress\auditProductCategoryMenu.mjs
node .\scripts\wordpress\syncProductCategoryMenu.mjs
node .\scripts\wordpress\auditFeedAutomation.mjs
node .\scripts\wordpress\triggerWpCron.mjs --base-url "https://example.com"
```

## Schedule

Example: install a daily menu sync at `03:00`.

```powershell
cd backend
powershell -ExecutionPolicy Bypass -File .\scripts\wordpress\installWpMenuSyncScheduledTask.ps1 -Time "03:00"
```

Example: trigger WordPress cron every `5` minutes from Windows Task Scheduler.

```powershell
cd backend
powershell -ExecutionPolicy Bypass -File .\scripts\wordpress\installWpCronScheduledTask.ps1 -BaseUrl "https://example.com" -IntervalMinutes 5
```
