# Implementation notes (Flutter SDK)

Summary of features added to match the web bug-report SDK so behavior is consistent across platforms.

---

## 1. Auto-capture network

- **Goal:** Log all HTTP requests (URL, method, status, duration) when the app uses Dio.
- **How:** App adds the SDK’s Dio interceptor when creating the client. In init, the SDK does not patch a global HTTP client; the app must add `CaldaBug.dioInterceptor(redactUrl: ...)` to its Dio instance.
- **Config:** `enableNetworkCapture` (default `true`). `CaldaBug.dioInterceptor()` returns `null` when this is false, so the app can do `if (interceptor != null) dio.interceptors.add(interceptor)`.
- **Usage:** `final interceptor = CaldaBug.dioInterceptor(redactUrl: (u) => u.split('?').first); if (interceptor != null) dio.interceptors.add(interceptor);`

---

## 2. User breadcrumbs

- **Goal:** Record a light trail of user taps to help reproduce issues.
- **How:** Wrap the app (e.g. the `MaterialApp` child) in `CaldaBugBreadcrumbScope`. It uses a transparent `Listener` and, on pointer down, runs a hit test to get the target type and pushes a `breadcrumb` event (action, target, route). Route comes from the navigator observer (`lastRoute`).
- **Config:** `enableBreadcrumbCapture` (default `true`). Configured in init via `configureBreadcrumbCapture`; the scope checks the flag and skips the listener when false.
- **Events:** Same ring buffer as logs/errors; type `breadcrumb` with `action`, `target`, `route`.

---

## 3. Reproduction summary

- **Goal:** One short string summarizing “what the user did before the error” for the report payload and UI.
- **How:** `getReproductionSummaryFromEvents()` in `reproduction_summary.dart` walks the event buffer and builds a sentence from `nav`, `breadcrumb`, and `err` events (e.g. “Started on /dashboard. Navigated /dashboard → /settings. Tapped. Error: Failed to load.”).
- **Output:** String added to report JSON as `reproductionSummary` and shown in the report sheet under “Reproduction”.
- **API:** `CaldaBug.getReproductionSummary()` returns the string for the current event snapshot.

---

## 4. Multiple attachments (images + video)

- **Goal:** Allow multiple images and one session recording (video) per report.
- **Report API:** `CaldaBug.report(..., screenshotPng: Uint8List?, attachments: List<ReportAttachment>)`. `ReportAttachment` has `type: 'image' | 'video'`, `data: Uint8List`, optional `filename`.
- **Upload:** Multipart with payload (gzip JSON), then `screenshot.png`, then `attachment_0.webm`, `attachment_1.png`, etc. in `upload/uploader.dart`.
- **UI:** Report sheet accepts `screenshotPng` and `attachments`. Renders primary screenshot, then a horizontal list of attachment thumbnails (images as `Image.memory`, video as placeholder with icon). Enforce limits (e.g. 5 images, 1 video) in the caller if desired.

---

## 5. Floating button: dialog + recording

- **Goal:** First tap opens a menu; user chooses “screenshot” or “start recording”. Recording has a 30s max and a visible “stop” state.
- **Flow:**
  1. **Idle:** Single floating button.
  2. **Dialog:** If a `CaldaViewportRecorder` is provided to `CaldaBugFloatingButton(recorder: ...)`, the first tap shows a bottom sheet with “Take screenshot and report” and “Start recording (max 30s)”. Without a recorder, the first tap goes straight to the screenshot flow.
  3. **Screenshot:** Same as before: capture, open report sheet with screenshot, on send upload.
  4. **Recording:** On “Start recording”, the button switches to a red “stop” style. Optional `CaldaViewportRecorder` (abstract class in `recording/viewport_recorder.dart`) can be implemented using a package like `screen_record_plus` or platform channels. SDK starts a 30s timer; on “stop” tap or timeout, calls `recorder.stop()`, then opens the report sheet with the video as an attachment (no screenshot unless the app adds both).
- **Widget:** `CaldaBugFloatingButton(repaintKey: key, enabled: true, recorder: myRecorder?)`. Implement `CaldaViewportRecorder` (e.g. with `screen_record_plus`) and pass it to enable the menu and recording.

---

## File / module mapping

| Feature              | Files |
|----------------------|--------|
| Network capture      | `config.dart`, `calda_bug_sdk.dart` (`dioInterceptor()`), `collectors/dio_interceptor.dart` |
| Breadcrumbs          | `config.dart`, `calda_bug_sdk.dart` (init), `collectors/breadcrumb_capture.dart`, `models.dart` (`BugEvent.breadcrumb`) |
| Reproduction summary | `reproduction_summary.dart`, `calda_bug_sdk.dart` (`getReproductionSummary` + payload), `models.dart` (payload field), `ui/report_sheet.dart` |
| Attachments          | `models.dart` (`ReportAttachment`), `upload/uploader.dart`, `calda_bug_sdk.dart` (report params), `ui/report_sheet.dart` |
| Dialog + recording    | `recording/viewport_recorder.dart`, `ui/floating_button.dart` |

---

## Config flags added

- `enableNetworkCapture` (default `true`)
- `enableBreadcrumbCapture` (default `true`)

Events: same ring buffer; new type `breadcrumb`. Payload: `reproductionSummary` string; multiple `attachments` in upload body.
