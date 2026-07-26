# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

Monorepo for a thesis (skripsi) project — an aqua-products distribution/stock system named **Aqua Japan**:

- `web_aqua/` — Express 5 backend. Serves **both** the server-rendered EJS admin/staff web UI **and** the `/api/v1/*` JSON API consumed by the Flutter app.
- `flutter_aqua/` — Flutter mobile client for all four roles.
- Root `package.json` only holds `docx`, for `generate_lampiran.js` (builds `Lampiran_Listing_Program.docx`, the thesis source-code appendix).

There is **one backend and two front-ends**. A feature usually needs an EJS view *and* an `/api/v1` endpoint *and* Flutter screens.

## Commands

```bash
# Backend (from web_aqua/)
npm run dev                      # nodemon src/app.js — port 3000 (PORT env)
node diag.js                     # boot app once; on crash writes stack to crash.log
node scripts/createUser.js       # seed a user (edit username/password/role in the file first)
node scripts/migrateUploads.js   # one-off: local uploads/ -> Cloudinary, rewrites Firestore URLs
start-tunnel.bat                 # backend + localtunnel, for phone access across networks

# Flutter (from flutter_aqua/)
flutter pub get
flutter run                      # or ./run_flutter.ps1 (also launches scrcpy)
flutter analyze                  # lint — flutter_lints via analysis_options.yaml
set_server_ip.bat                # rewrites ApiConfig.defaultBaseUrl to this PC's LAN IP
dart run flutter_launcher_icons  # regenerate icons from assets/logo.png
```

**There are no tests anywhere** — `web_aqua`'s `npm test` is a failing stub and `flutter_aqua/` has no `test/` directory. No CI, no typechecking, no pre-commit hooks. `flutter analyze` is the only automated check in the repo. Verify changes by running the app.

## Backend architecture (`web_aqua/`)

**Every router is mounted at `/` in `src/app.js`** — full paths live inside each route file, so route order in `app.js` matters. Grep for the path string, not the filename, to find a handler.

The filename↔content mapping is unreliable. Most notably `src/routes/shipments.route.js` (1555 lines) is a catch-all holding nearly the entire **Flutter cabang API surface**: `/api/v1/cabang/shipments`, `/products`, `/orders`, `/orders/:id/pay`, `/branch-products`, `/sales`, `/sales/report`. Meanwhile `src/routes/cabang/shipments.route.js` holds only the *web* `/cabang/shipments` pages (it ends with a comment pointing at the other file).

### Dual auth

`src/middleware/auth.js` exports three pieces, and which one you use determines the failure mode:

- `requireAuth` — web pages. Reads the `__session` cookie; on failure **redirects to `/login`**.
- `requireAuthApi` — `/api/v1/*`. Reads `Authorization: Bearer` with cookie fallback; on failure returns **401 JSON**.
- `requireRole([...])` — roles are `admin`, `cabang`, `sales`, `gudang`. Returns JSON 403 for `/api/` paths, plain text otherwise.

Both attach `req.user` (JWT payload: `uid`, `username`, `role`) and re-fetch `req.profile` from Firestore on every request.

**CSRF (`src/middleware/csrf.js`) applies to EJS form routes only** — never add `csrfProtection` to an `/api/v1` route, the Flutter client sends no CSRF token. Web forms must render `req.csrfToken()` into a `_csrf` hidden input.

### Firestore data model

`firebase-admin` initialized in `src/firebaseAdmin.js` (ADC via `GOOGLE_APPLICATION_CREDENTIALS`, else the three `FIREBASE_*` env vars; `\n` in the private key is unescaped there). No ORM — collections accessed directly:

| Collection | Doc ID | Notes |
|---|---|---|
| `users` | `randomUUID`/`uuidv4` | Also carries a redundant `id` field equal to the doc ID. `password_hash` via bcryptjs. Branch profile fields: `nama_cabang`, `provinsi`, `kota`, `jalan` |
| `products` | uuid | `stok` = **central/pusat** stock, `harga_jual`, `sku`, `barcode`, `satuan`, `gambar_url` (Cloudinary) |
| `branch_stocks` | **`{cabang_id}_{product_id}`** | Deterministic composite ID — per-branch shop stock, always written with `{merge:true}` + `FieldValue.increment` |
| `orders` | uuid | `kode_order`, `status`, `payment_status`, `items[]`, `history[]` audit trail |
| `shipments` | uuid | `kode_pengiriman` (resi), `po_number`, `pengirim`/`penerima` (uids), `data_barang[]`, GPS + photo proof |
| `sales` | uuid | Branch-local walk-in sales, `kode_penjualan` |
| `divisi` | uuid | Product categories |

Code generation (`src/utils/generateCode.js`) — `generateSequentialCode` scans today's docs and takes max+1, so it is **not concurrency-safe**:

- `PO-YYYYMMDD-NNN` → `orders.kode_order`
- `SO-YYYYMMDD-NNN` → `shipments.so_number`
- `SJ-YYYYMMDD-NNN` → `sales.kode_penjualan`
- `TRXID` + 10 random digits → `shipments.kode_pengiriman` (the resi the Flutter app scans)

### Order lifecycle — the core cross-file state machine

Each transition is guarded by the *previous* status, so changing one status string breaks the next step. Spread across four route files:

```
cabang/sales creates order            -> status: pending, payment_status: pending
                                         AND products.stok decremented immediately
Midtrans webhook settlement/capture   -> payment_status: settlement
admin approve (requires pending +
   payment_status==settlement)        -> approved_admin       [admin_api.route.js]
gudang pack (requires approved_admin) -> dipaket              [gudang_orders.route.js]
gudang send (requires dipaket |
   approved_admin)                    -> dikirim + creates the shipments doc
cabang confirms the shipment          -> diterima | ditolak   [shipments.route.js]
                                         (mirrored onto the order doc too)
```

`selesai` is a legacy status settable from the admin web form; reports treat it as equivalent to `diterima`.

### Stock invariants

Two independent ledgers, both maintained by hand with `FieldValue.increment` in non-atomic `db.batch()` calls whose failures are only logged — **never silently reorder or duplicate these**:

- `products.stok` (central): **−** on order creation; **+** on Midtrans `expire`/`cancel`/`deny` (webhook also sets `status: ditolak`); **+** when a branch *rejects* a shipment.
- `branch_stocks.stok` (per branch): **+** by each item's `qty_diterima` when a branch *accepts* a shipment (note: the received quantity, not the shipped quantity); **−** on a branch-local sale.

### Shipment confirmation (`POST /api/v1/cabang/shipments/:kode/confirm`)

The most intricate endpoint — multipart, and the Flutter app's critical path. Only `shipments.penerima === req.user.uid` may confirm; re-confirming an already `diterima`/`ditolak` shipment returns 409. Items are patched **by array index** (`items_json: [{idx, qty_diterima, catatan}]`), not by product ID.

Geofencing ("Opsi A") is accuracy-based only, with no radius check against the branch address: `lat`/`lng` must be finite (else 400 `invalid_location_coords`), and `accuracy > 100 m` is rejected with 400 `location_accuracy_too_low`. Passing sets `lokasi_terverifikasi: true`; the snapshot is stored as `lokasi_penerimaan` or `lokasi_penolakan` depending on the action.

### External services

- **Cloudinary** (`src/storageHelper.js`) is the image store. Multer uses `memoryStorage()` and buffers stream straight up — Vercel is serverless, so **never write to the local filesystem**. `public_id` is the destination path minus extension; deletion parses the `public_id` back out of the URL.
- **Midtrans Snap** (`src/midtransClient.js`) — sandbox unless `MIDTRANS_IS_PRODUCTION === 'true'`. `transaction_details.order_id` is `{kode_order}-{Date.now()}`, stored as `midtrans_order_id`, so retries don't collide with the original. `gross_amount` must be an integer. Token-generation failure is non-fatal: the order is still saved with `payment_status: 'failed_to_generate'`.
- **Webhook** `POST /api/v1/midtrans/notification` is intentionally unauthenticated and idempotent-guarded (skips orders already `selesai`/`dikirim`/`diterima`/`ditolak`).

Required `.env` in `web_aqua/`: `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` (or `GOOGLE_APPLICATION_CREDENTIALS`), `JWT_SECRET`, `SESSION_COOKIE_NAME`, `SESSION_COOKIE_EXPIRES_DAYS`, `CSRF_SECRET`, `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, `MIDTRANS_IS_PRODUCTION`, `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. Deployed to Vercel (`vercel.json` routes everything to `src/app.js`; `app.listen` is skipped there).

## Flutter architecture (`flutter_aqua/`)

- **`lib/services/api_client.dart` is the single HTTP surface** — one static method per endpoint, 18 s timeout, `Authorization: Bearer` from `AuthService`. Add new endpoints here rather than calling `http` from a screen. Most methods return the raw `http.Response` for the caller to decode.
- **`lib/config/api_config.dart`** — base URL is runtime-configurable: `SharedPreferences['api_base_url']` overrides `defaultBaseUrl`, editable in-app via Settings. `ApiConfig.init()` must run in `main()` before anything else. `set_server_ip.bat` rewrites the *compiled default* and leaves an `api_config.dart.backup` (which is committed — ignore it).
- **`lib/screens/auth/auth_gate.dart`** is the router: token presence → login vs. app, then the cached role string picks one of four home shells (`admin`/`sales`/`gudang`/ default `cabang`). Screens are organized per role under `lib/screens/<role>/`; there is no route table and no state-management package — plain `setState` plus `ThemeProvider` (a `ChangeNotifier` exposed via `ThemeProviderScope`).
- `lib/screens/linux/` is a stray copy of the Linux desktop runner scaffold sitting inside `lib/` — not Dart app code, ignore it.
- Native permissions matter for `mobile_scanner` (camera), `image_picker`, and `geolocator`/`geocoding` (location, required by shipment confirmation) — changes there need the Android/iOS manifests updated.

## Design system

**The web and the Flutter app are on two different design systems — do not sync colors between them blindly.**

### Web (`web_aqua/`) — lavender canvas + one violet accent

Defined entirely as `--oct-*` custom properties in `src/views/layouts/base.ejs` (the default layout: the whole stylesheet lives inline in its `<style>`, plus an anti-flash dark-mode script keyed on `localStorage['aqua-theme']`). Bootstrap 4, jQuery, SweetAlert2, and Font Awesome come from CDNs.

The shell is **floating white panels on a neutral canvas**: `body` is painted `--oct-frame` (`#EDECF5`, deliberately *not* the accent) with `--oct-frame-pad` padding, the sidebar is a `position: fixed` rounded card, and `.oct-main` is a second rounded card offset by `--oct-sidebar-w + --oct-gap`. Panels separate from the canvas by `--oct-shadow-panel`, not by colour.

- Canvas `#F5F4FA` (lavender-tinted), cards `#FFFFFF`, one neutral family carrying a faint violet tint, borders `#E4E1F0`.
- **`--oct-primary` is violet `#6E5DE7`** — the single UI accent: CTAs, active nav, focus rings, toggles. `--oct-primary-dark` `#5A48D6` is the hover.
- Green / amber / red / blue are **semantic only** (status pills, deltas). `--oct-series-1..5` are **data-only** — charts, never chrome.
- Radius scale `--oct-r-xl` / `--oct-r-lg` / `--oct-r` / `--oct-r-sm` (22/16/12/9px); shadows are tinted violet, never pure black.
- Fonts: **Plus Jakarta Sans** (display/headings, 800 with tight negative tracking) + **Inter** (body/UI) + **JetBrains Mono** (`.oct-mono` for SKU/resi/PO codes). Figures use `font-variant-numeric: tabular-nums`.

Shared components (all defined in `base.ejs` — extend, never redefine): `.oct-page-head*`, `.oct-card*`, `.oct-panel`/`-inset`, `.oct-kpi*`, `.oct-delta-up|down|flat|warn`, `.oct-stat-list`/`-row`, `.oct-dl*`, `.oct-pill-<status>`, `.oct-chip`, `.oct-kode`, `.oct-empty*`, `.oct-icon-btn`, `.oct-kebab`, `.oct-link`, `.oct-btn-dark`/`-ghost`, `.oct-skeleton`, `.oct-rise`, `.oct-seg*` (segmented filter), `.oct-listnav*` (master list), `.oct-timeline`/`.oct-tl-*`, `.oct-switch`, `.oct-bars*` (CSS bar chart), `.oct-drop` (file dropzone), `.oct-avatar`, `.oct-note`, `.oct-search`, `.oct-toolbar`, `.oct-grid-*`, `.oct-sr`.

**Tables use one system**: `.oct-tablewrap.oct-tablewrap-card` > `table.oct-table`, with `.num` on *both* `<th>` and `<td>` of numeric columns (right-aligned, tabular, nowrap), `.col-fit` on narrow ones, `.oct-cell-media`/`.oct-thumb`/`.oct-cell-stack` for record cells, `.oct-td-actions` + `.oct-icon-btn` for actions, and an empty-row fallback. `.oct-table-sm`/`.oct-table-nested` for dense nested tables. `.oct-tablewrap-scroll` adds a capped height + sticky header — **do not use it on tables containing dropdowns**, it clips overflow.

Shared JS helpers the layout exposes: `Aqua.flash({code: 'pesan'})` (reads `?ok=`/`?err=` then strips them), `Aqua.confirm({title, text, confirmText})`, `Aqua.filterTable(inputSel, tableSel, emptySel)`, `Aqua.dropzone()` (auto-runs). Views should not hand-roll `URLSearchParams` + `Swal` blocks, and must never pass `confirmButtonColor` (the layout themes SweetAlert).

Gotchas when editing views:

- Views render inside `<%- body %>`, so **a view's `<style>` comes after the layout's and wins**. Never declare a rule for a class or token the layout owns — prefix view-only CSS (`.ord-`, `.shp-`, `.prd-`, `.usr-`, …). No hardcoded hex colours; use tokens. Chart.js colours must be read at runtime via `getComputedStyle(document.documentElement).getPropertyValue('--oct-series-1')`.
- `[hidden] { display: none !important }` is set globally, because a component's `display: flex` would otherwise beat the UA `[hidden]` rule and break JS row filtering.
- `.oct-sidebar` must stay `overflow: visible` — the user dropdown escapes the rail.
- `login.ejs` and `admin/shipment-resi.ejs` are standalone (`layout: false`) and carry their own tokens; palette changes must be applied there too.
- `sales/history.ejs` is **not rendered by any route** — dead view.

### Flutter (`flutter_aqua/`) — still the older Octavia blue

`OctaviaColors` / `AppTheme` in `lib/config/theme.dart` (blue `#3B82F6` primary), persisted under `SharedPreferences['app_theme_mode']`. This is the system `web_aqua/design2.md` documents.

**Both `web_aqua/desaig.md` ("Twinkling Stardust") and `web_aqua/design2.md` ("Octavia") now describe only historical/Flutter styling — neither matches the web UI.** For the web, `base.ejs` is the source of truth.

## Conventions

- Comments, log messages, user-facing strings, and error `message` fields are **Indonesian**; identifiers and status values are Indonesian too (`stok`, `dipaket`, `diterima`, `pengirim`, `keterangan`). Match this when adding code.
- API errors are `{ error: 'snake_case_code' }`, optionally with a human-readable Indonesian `message`. Web form errors round-trip through query strings (`?ok=...` / `?err=<encoded>`).
- Body parsers are applied **per route**, not globally (`express.json()` / `express.urlencoded()` inline in the middleware chain) — a new route without one will see an empty `req.body`.
- CORS is wide open (`Access-Control-Allow-Origin: *`) in `src/app.js` for the mobile client.
- `web_aqua/API.md` documents the Flutter-facing endpoints; keep it in sync when changing them.
