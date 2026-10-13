# EasyHire Chatwoot Custom — Báo cáo Ngày 2

Ngày thực hiện: 13/10/2026, Asia/Saigon. Source gốc: Chatwoot `v4.18.0`, commit `9f920b549c14491a4e587687a3eed5d21c6ccc7d`.

## 1. Kết quả

Đã xóa thật phần frontend quản trị độc lập của **Reports, Campaigns và Help Center**: pages, routes, components, imports, stores và mutation constants chỉ phục vụ các trang đã bỏ. Menu, command palette, phím tắt Reports và các liên kết tới trang quản trị đã xóa cũng được gỡ.

Phần dùng chung với Conversations, Inbox, Automation, Website Widget và Captain được giữ. Vì vậy đây là **tinh giản frontend quản trị**, không phải ngừng toàn bộ backend hoặc mọi biểu hiện của ba tính năng trong Widget/Conversations.

Đã đối chiếu lại [báo cáo dependency Ngày 1](CUSTOMIZATION_ANALYSIS.md), đặc biệt mục 4.3–4.5, điều kiện xóa ở mục 6.3 và ngoại lệ shared drilldown/editor trong phụ lục. Phạm vi Ngày 2 theo yêu cầu mới bao gồm cả ba module; các caller dùng chung còn tồn tại được giữ thay vì xóa toàn bộ thư mục theo tên.

Không sửa Rails backend, schema, migrations, feature registry/bit positions, edition, license, package manifest hoặc lockfile. Không chỉnh `D:\easyhire\DATN`; không thay container, database hay volume baseline/EasyHire. Việc chuẩn bị database chỉ diễn ra trên database mới `easyhire_day2` trong project Docker riêng, sử dụng schema hiện hữu.

Thay đổi được làm trên worktree `D:\easyhire\chatwoot\tmp\codex-day2`, branch `easyhire-day2`, sau đó tích hợp commit lên `easyhire-custom` khi kiểm tra hoàn tất. Trạng thái commit được ghi ở cuối báo cáo.

## 2. Số lượng file và dòng giảm

| Chỉ số frontend | Kết quả |
| --- | ---: |
| File đã xóa | **219** |
| File đã sửa | **17** |
| Dòng xóa | 28.167 |
| Dòng thêm | 34 |
| Giảm ròng | **28.133 dòng** |
| Giảm ròng khi bỏ qua specs, tests, stories và fixtures | **21.922 dòng** |

Số liệu lấy từ `git diff --numstat -- app/javascript` đối với commit gốc, không tính báo cáo hoặc setup cục bộ. Dòng được tính theo file văn bản của Git, gồm JavaScript, Vue template/style và SVG; không phải thước đo tốc độ xử lý. Các stories/specs chỉ thuộc tính năng đã bỏ được xóa cùng module; tests của core và shared dependencies được giữ.

| Nhóm file đã xóa | Số lượng |
| --- | ---: |
| Reports và giao diện Year in Review độc lập | 103 |
| Campaigns dashboard | 28 |
| Help Center administration, editor riêng và generation-status UI | 88 |

Không dùng CSS hoặc `display: none` để thực hiện việc loại bỏ.

## 3. Những thay đổi quan trọng

### Routes, menu và navigation

- Gỡ đăng ký Help Center/Campaigns khỏi cây dashboard; gỡ Reports khỏi settings routes.
- Xóa ba nhóm menu khỏi Sidebar cùng helper tạo report navigation.
- Gỡ commands đi tới các trang đã xóa; gỡ `Alt+R` và mục hướng dẫn phím tắt tương ứng.
- Chuyển fallback sau đăng nhập sang Profile Settings khi người dùng không có quyền mở Conversations/Contacts. Điều này tránh dẫn custom role chỉ có quyền Reports/Knowledge Base tới trang đã bị gỡ hoặc vòng chuyển hướng dashboard.
- Giữ card drilldown dùng bởi Captain nhưng hiển thị tên agent dưới dạng nhãn; liên kết Agent Reports được bỏ. Liên kết Contact/Inbox/Conversation vẫn hoạt động.
- Giữ kết quả tìm kiếm bài viết trong Search dùng chung; bỏ liên kết chỉnh sửa tới Article Editor đã xóa và các props chỉ phục vụ liên kết đó.

### Components và state độc lập

- Xóa report pages/components riêng, report-only stores `reports`, `summaryReports`, `slaReports`, `csat` và các API clients không còn caller.
- Xóa Campaigns management pages/components. Store/API Campaigns vẫn phục vụ bộ lọc Conversations/Automation nên không bị xóa.
- Xóa Help Center management pages, `components-next/HelpCenter`, FullEditor riêng cho Article Editor, article/category management stores và category client không còn caller.
- Gỡ Help Center generation-status component, polling API method và phần hiển thị trong Inbox onboarding. Onboarding tạo Inbox Website và kết nối kênh vẫn được giữ.
- Xóa mutation constants riêng của các stores đã bỏ. `SET_UI_FLAG` dùng bởi store factory và các constants của Search/Portal/Campaigns được giữ.

`FullEditor.vue` đã được kiểm tra caller: implementation này chỉ được Article Editor của Help Center sử dụng. Ô soạn tin Conversations dùng WootWriter `Editor.vue`/ReplyBox, đã được giữ và kiểm thử thực tế.

## 4. Dependency được giữ và lý do

| File/nhóm | Bằng chứng và lý do giữ |
| --- | --- |
| [store/modules/campaigns.js](app/javascript/dashboard/store/modules/campaigns.js), [api/campaigns.js](app/javascript/dashboard/api/campaigns.js) | [ChatList.vue](app/javascript/dashboard/components/ChatList.vue) lấy/fetch campaigns; [useAutomationValues.js](app/javascript/dashboard/composables/useAutomationValues.js), [filter/provider.js](app/javascript/dashboard/components-next/filter/provider.js) và automation forms dùng campaign options |
| Website Widget Campaigns | [widget/App.vue](app/javascript/widget/App.vue), [widget/store/modules/campaign.js](app/javascript/widget/store/modules/campaign.js), widget router, timers, PreChat và unread components còn sử dụng; toàn bộ Widget/SDK source được giữ nguyên |
| Article Search trong Conversations | [ReplyBox.vue](app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue) import [SearchPopover.vue](app/javascript/dashboard/routes/dashboard/helpcenter/components/ArticleSearch/SearchPopover.vue); giữ cả Header, SearchResults, ArticleView và ArticleSearchResultItem của popover |
| Portal store/API và Article API | [ConversationView.vue](app/javascript/dashboard/routes/dashboard/conversation/ConversationView.vue) fetch portals; [Inbox Settings](app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue) dùng portal picker; ArticleSearch gọi articles client trực tiếp |
| Website Widget Help Center browsing | [Home.vue](app/javascript/widget/views/Home.vue) dùng [ArticleContainer.vue](app/javascript/widget/components/pageComponents/Home/Article/ArticleContainer.vue); giữ Widget ArticleViewer, article store/client, template Article và portal bootstrap backend |
| Search dùng chung | [SearchView.vue](app/javascript/dashboard/modules/search/components/SearchView.vue), [conversationSearch.js](app/javascript/dashboard/store/modules/conversationSearch.js) và Search API tiếp tục phục vụ tìm kiếm core; article result cards được giữ để không phá consumer chung |
| Reports drilldown shared | [useReportDrilldown.js](app/javascript/dashboard/routes/dashboard/settings/reports/composables/useReportDrilldown.js), [ReportDrilldownCard.vue](app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue) còn được Captain ConversationUsageDrawer, AssistantDrilldownDrawer và DocumentDetails import; giữ specs tương ứng |
| [api/reports.js](app/javascript/dashboard/api/reports.js) và specs | Composable drilldown shared có default fetcher gọi ReportsAPI.getDrilldown; client được giữ nguyên hợp đồng |
| Translations và feature flags | Report drilldown/ArticleSearch/Widget vẫn dùng các khóa i18n; không xóa locale theo tên module, không reorder/remove feature entries |
| Shared editors, design system, helpers, dependencies | Không xóa toàn bộ WootWriter/shared/filters hoặc gỡ npm packages theo tên tính năng; global/shared imports vẫn tồn tại |
| Backend ba module | Controllers, models, jobs, listeners, REST routes, public `/hc` pages và campaign execution scheduler không sửa trong Ngày 2 |

Các helper/API methods bên ngoài tập xóa đã được chứng minh an toàn được giữ; báo cáo này không xác nhận mọi phương thức còn lại đều đã được audit độc quyền. Captain, Calls, public Help Center, proactive Widget Campaigns, CSAT/SLA engines và dữ liệu lịch sử tiếp tục nằm ngoài phạm vi xóa toàn bộ.

## 5. Kết quả kiểm tra thực tế

| Kiểm tra | Kết quả cuối cùng |
| --- | --- |
| `git diff --check` | Pass |
| ESLint các frontend file sửa | Pass: 0 errors, 2 warnings |
| Script `pnpm eslint` toàn frontend trên snapshot Linux/LF | **Pass: 0 errors, 362 warnings** |
| Script `pnpm test ... --maxWorkers=2 --minWorkers=1` | **71 test files, 751 tests pass** |
| Production Docker build | **Pass**, image `easyhire-chatwoot:day2` |
| Khởi tạo schema hiện hữu trên database mới | Pass; chỉ database `easyhire_day2` |
| Web và Sidekiq Ngày 2 | Chạy trong project/network/volumes riêng |
| Chromium UI smoke | **9 checks pass**, không có uncaught browser JavaScript error |
| WebSocket | Xác nhận dashboard nhận incoming và Widget nhận agent reply bằng frames thực, không reload |
| Baseline image | ID giữ nguyên `sha256:2d92e6396cf7dcec4d6c2242fce2dcc5d769d781ac121cf1f39ae24169ccd56e` |

Phạm vi Vitest: Conversations/actions/getters/mutations/metadata/search/stats; ReplyBox; Inbox settings; Website Widget; onboarding channel flows; command palette/route helpers; shared drilldown; Campaigns/Portal stores được giữ; Automation và filter helpers; Captain usage/document components dùng shared Reports.

Đây là các tests liên quan tới thay đổi, không phải khẳng định toàn bộ mọi suite trong repository đã chạy. Không chạy RSpec backend hay kiểm thử gửi tin social thật trong Ngày 2.

Lệnh kiểm tra sử dụng đúng scripts trong `package.json`, thực thi trong snapshot Linux đã chuẩn hóa newline:

```sh
pnpm eslint
pnpm test \
  app/javascript/dashboard/helper/specs/routeHelpers.spec.js \
  app/javascript/dashboard/composables/commands/spec/useGoToCommandHotKeys.spec.js \
  app/javascript/dashboard/routes/dashboard/settings/reports \
  app/javascript/dashboard/components/widgets/conversation/specs/ReplyBox.spec.js \
  app/javascript/dashboard/routes/dashboard/settings/inbox/specs \
  app/javascript/dashboard/store/modules/specs/conversations \
  app/javascript/widget \
  app/javascript/dashboard/routes/dashboard/onboarding/specs/inbox-setup \
  app/javascript/dashboard/store/modules/specs/campaigns \
  app/javascript/dashboard/store/modules/helpCenterPortals \
  app/javascript/dashboard/composables/spec/useAutomation.spec.js \
  app/javascript/dashboard/components-next/filter/helper/filterHelper.spec.js \
  app/javascript/dashboard/components-next/captain/pageComponents/ConversationUsageDrawer.spec.js \
  app/javascript/dashboard/components-next/captain/pageComponents/document/DocumentDetails.spec.js \
  --maxWorkers=2 --minWorkers=1
```

### Các lỗi trong quá trình kiểm tra đã được xử lý

- Checkout Windows dùng CRLF khiến lần lint trực tiếp báo hàng loạt lỗi newline. Snapshot Linux được chuẩn hóa LF tương ứng nội dung Git; không normalize toàn bộ application working tree. Lint trên snapshot cuối cùng pass.
- Khi dùng symlink node_modules ra ngoài snapshot, Vite không load được setup `fake-indexeddb`. Đặt dependencies trong chính snapshot đã khắc phục; đợt cuối chạy đủ 751 tests, không bỏ setup hoặc tắt tests.
- Test chuyển hướng cũ thiếu trường `permissions` trong fixture agent. Fixture được cập nhật đúng shape API; assertions cho Conversations vẫn giữ.
- Những props chỉ dùng để mở Article Editor đã được bỏ khỏi cả item và caller sau khi ESLint chỉ ra unused props.
- Smoke harness ban đầu dùng response HTML giả, bị Chromium Private Network Access chặn SDK. Harness chuyển sang ngữ cảnh HTTP thực; không đổi SDK hoặc vô hiệu hóa cơ chế bảo vệ browser.
- Conversations mặc định mở tab Mine và email-collection template có thể chiếm card preview. Smoke chọn tab All, mở theo contact mới, đồng thời kiểm tra frame WebSocket chứa nội dung mới để tránh nhầm tin cũ.

Build có cảnh báo Dockerfile format, Browserslist, chunk size, RubyLLM và Git/Husky trong worktree; precompile cũng ghi log AI initializer không có database build. Build cuối cùng exit 0, web/worker và flow nhắn tin đều đã được xác minh. Các cảnh báo được giữ trong logs.

## 6. Image production và môi trường kiểm thử

| Hạng mục | Giá trị |
| --- | --- |
| Image mới | `easyhire-chatwoot:day2` |
| Image ID | `sha256:48cd9562e742f8cf1990a0e9724f6441b8336ae47877a9c59765da57ef04b122` |
| Kích thước logical do Docker báo | 745.893.663 bytes |
| Baseline logical size | 746.529.941 bytes |
| Giảm logical size | 636.278 bytes, khoảng 0,61 MiB |
| Project Compose | `easyhire-chatwoot-day2` |
| URL local | **http://localhost:4042** |
| Database | `easyhire_day2` |
| Volumes | `easyhire-chatwoot-day2_postgres`, `_redis`, `_storage`; tooling volumes cũng có prefix day2 riêng |
| Admin giả | `day2.admin@example.test` / `Day2Test!2026` |
| User kiểm tra fallback Reports-only | `day2.reports@example.test` / `Day2Test!2026` |

Các thông tin đăng nhập trên chỉ dành cho môi trường kiểm thử local, với dữ liệu giả. Cổng 4040 đã có dịch vụ khác nên môi trường Ngày 2 sử dụng 4042. Baseline 4030/4031 và các dịch vụ EasyHire/EasyTech đang chạy không bị dừng/thay thế.

Production build dùng recipe từ `docker/Dockerfile` của repository, Rails `assets:precompile` và Vite/SDK pipeline có sẵn. Trong bản Dockerfile tạm, duy nhất bước đọc `git rev-parse HEAD` được thay bằng ghi base SHA vì `.git` của worktree là pointer tới ngoài Docker context. Dockerfile tracked không bị sửa. Image được build trước commit nên `.git_sha` chứa base SHA nêu ở đầu; source frontend đã được đối chiếu và kiểm thử trước khi commit.

Kích thước image không giảm tương ứng số dòng source: các gems, icon bundles, i18n và shared code vẫn được giữ. Logical size không phải lượng disk thực sự thu hồi hoặc phép đo performance.

Setup/test harness cục bộ được lưu trong `.codex/day2/` của worktree theo AGENTS.md; thư mục này đang được gitignore. `.env.day2.local` chứa secrets test được tạo riêng, không commit và đã kiểm tra không có trong production image.

```powershell
# Chỉ thao tác project riêng Ngày 2, từ worktree:
docker compose -p easyhire-chatwoot-day2 -f .codex/day2/compose.yaml ps
docker compose -p easyhire-chatwoot-day2 -f .codex/day2/compose.yaml logs --tail 50 rails worker
```

## 7. Các smoke checks đã pass

1. Admin đăng nhập và mở Conversations dashboard.
2. Router thực không còn các route quản trị đã bỏ; Sidebar không còn ba menu; Vuex không còn sáu stores quản trị độc lập; core/Campaigns/Portal shared stores vẫn có.
3. Xem Inbox Website và tạo một Inbox API qua đầy đủ wizard giao diện, chọn agent, tới màn hình Inbox ready.
4. Load SDK production và mở Website Widget thực.
5. Gửi incoming từ Widget; dashboard nhận WebSocket và mở đúng contact/conversation mà không reload.
6. Agent soạn và gửi reply trong Conversations; Widget hiển thị reply qua WebSocket mà không reload.
7. REST Inbox API của account hiện tại trả 200; request tới account khác không có membership bị từ chối.
8. User custom role chỉ có `report_manage` đăng nhập tới Profile Settings còn tồn tại, không tới Reports.
9. Không có uncaught JavaScript error ở ba browser contexts.

## 8. Checklist bổ sung cho kiểm thử thủ công

Các mục này mở rộng phạm vi smoke; chưa được xác nhận chỉ bằng kết quả 751 tests/9 checks phía trên.

- [ ] Trên http://localhost:4042, đăng nhập admin giả; kiểm tra My Inbox, Conversations, Contacts, Agents, Teams, Assignment và Settings còn hoạt động.
- [ ] Vào Conversations → tab All/Unassigned; chọn hội thoại đã tạo, gửi reply và private note; private note không xuất hiện trong Widget.
- [ ] Nhúng SDK của **instance day2** với website token của Inbox test; dùng hai cửa sổ/browser riêng. Gửi text, emoji, ảnh và CV/PDF, tải file lại; gửi voice note nếu được bật. Không dùng token/callback của baseline.
- [ ] Resolve rồi gửi incoming mới; kiểm tra mở lại, unread, typing và reconnect. Kiểm tra assignment agent/team và campaign filter dùng chung còn đọc được metadata cũ.
- [ ] Kiểm tra Article Search trong ReplyBox/portal binding trong Inbox còn hoạt động khi cung cấp portal test; public Help Center và Widget article browsing được giữ theo dependency, không phải đã bỏ toàn bộ.
- [ ] Dùng tài khoản social test riêng để kiểm tra Messenger incoming/outgoing/media/read/echo; Telegram incoming/outgoing/edit/file/callback; Instagram direct login **và** qua Facebook Page. Xác minh đúng account/inbox, không trùng tin, không đổi callback của kênh đang dùng.
- [ ] Kiểm tra REST/Webhook/SSO theo luồng tích hợp EasyHire hiện có, bằng dữ liệu test; không sửa DATN hoặc dùng credentials production để seed.
- [ ] Kiểm tra direct URLs cũ của ba trang quản trị không mở được màn hình đã xóa; command palette và `Alt+R` không dẫn tới Reports.
- [ ] Đọc lại các conversation lịch sử có campaign_id, article/AI/call content; không xóa dữ liệu hoặc model backend để tạo kết quả đẹp.

## 9. Logs và bằng chứng local

Trong `tmp/` của worktree:

- `day2-eslint-changed-final.log`: lint các file sửa, 0 errors.
- `day2-eslint-linux-final.log`: script lint toàn frontend, 0 errors/362 warnings.
- `day2-vitest-linux-final.log`: 71 files/751 tests pass.
- `day2-docker-build-final.log`: production build hoàn tất.
- `day2-db-prepare.log`, `day2-seed.log`: khởi tạo dữ liệu riêng; có thể chứa thông tin test nên không commit logs.
- `day2-ui-smoke-verified.log`, `day2-smoke/results.json`: 9 smoke checks pass, cả hai WebSocket indicators true.
- `day2-smoke/conversations.png`, `day2-smoke/widget.png`: ảnh giao diện từ dữ liệu giả.

## 10. Danh sách file đã sửa

Các thay đổi đều nằm trong `app/javascript/dashboard/`; không có thay đổi source Widget/SDK hoặc Rails.

| File đã sửa | Lý do |
| --- | --- |
| [app/javascript/dashboard/api/onboarding.js](app/javascript/dashboard/api/onboarding.js) | Gỡ polling method Help Center generation đã hết caller. |
| [app/javascript/dashboard/components-next/sidebar/Sidebar.vue](app/javascript/dashboard/components-next/sidebar/Sidebar.vue) | Gỡ ba menu và report-route helper. |
| [app/javascript/dashboard/components-next/sidebar/useSidebarKeyboardShortcuts.js](app/javascript/dashboard/components-next/sidebar/useSidebarKeyboardShortcuts.js) | Gỡ phím tắt Reports Alt+R. |
| [app/javascript/dashboard/components/widgets/modal/constants.js](app/javascript/dashboard/components/widgets/modal/constants.js) | Gỡ hướng dẫn phím tắt đã bỏ. |
| [app/javascript/dashboard/composables/commands/spec/useGoToCommandHotKeys.spec.js](app/javascript/dashboard/composables/commands/spec/useGoToCommandHotKeys.spec.js) | Cập nhật assertions không còn navigation Reports/Help Center. |
| [app/javascript/dashboard/composables/commands/useGoToCommandHotKeys.js](app/javascript/dashboard/composables/commands/useGoToCommandHotKeys.js) | Gỡ commands, icons và report section đã hết caller. |
| [app/javascript/dashboard/helper/routeHelpers.js](app/javascript/dashboard/helper/routeHelpers.js) | Gỡ default routes đã xóa; fallback Profile cho custom role. |
| [app/javascript/dashboard/helper/specs/routeHelpers.spec.js](app/javascript/dashboard/helper/specs/routeHelpers.spec.js) | Kiểm tra fallback mới; sửa fixture permissions đúng hợp đồng API. |
| [app/javascript/dashboard/modules/search/components/SearchResultArticleItem.vue](app/javascript/dashboard/modules/search/components/SearchResultArticleItem.vue) | Giữ article result, bỏ liên kết và props mở Article Editor. |
| [app/javascript/dashboard/modules/search/components/SearchResultArticlesList.vue](app/javascript/dashboard/modules/search/components/SearchResultArticlesList.vue) | Gỡ props/caller chỉ phục vụ Article Editor navigation. |
| [app/javascript/dashboard/routes/dashboard/dashboard.routes.js](app/javascript/dashboard/routes/dashboard/dashboard.routes.js) | Gỡ Help Center/Campaigns imports và route registration. |
| [app/javascript/dashboard/routes/dashboard/onboarding/InboxSetup.vue](app/javascript/dashboard/routes/dashboard/onboarding/InboxSetup.vue) | Gỡ Help Center generation-status UI và state/import riêng. |
| [app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue](app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportDrilldownCard.vue) | Giữ shared card; bỏ liên kết Agent Reports. |
| [app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/ReportDrilldownCard.spec.js](app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/ReportDrilldownCard.spec.js) | Kiểm tra Contact/Inbox links và Agent label còn nguyên. |
| [app/javascript/dashboard/routes/dashboard/settings/settings.routes.js](app/javascript/dashboard/routes/dashboard/settings/settings.routes.js) | Gỡ Reports import và route registration. |
| [app/javascript/dashboard/store/index.js](app/javascript/dashboard/store/index.js) | Gỡ sáu report/article/category management store registrations. |
| [app/javascript/dashboard/store/mutation-types.js](app/javascript/dashboard/store/mutation-types.js) | Gỡ constants chỉ thuộc stores đã xóa; giữ shared state constants. |

## 11. Danh sách file đã xóa

Danh sách liệt kê từng file từ Git. File đã xóa có thể đối chiếu bằng `git show 9f920b549c14491a4e587687a3eed5d21c6ccc7d:<path>`.

### Reports — 103 file

- `app/javascript/dashboard/api/csatReports.js`
- `app/javascript/dashboard/api/liveReports.js`
- `app/javascript/dashboard/api/slaReports.js`
- `app/javascript/dashboard/api/specs/csatReports.spec.js`
- `app/javascript/dashboard/api/specs/slaReports.spec.js`
- `app/javascript/dashboard/api/summaryReports.js`
- `app/javascript/dashboard/api/yearInReview.js`
- `app/javascript/dashboard/components-next/year-in-review/ShareModal.vue`
- `app/javascript/dashboard/components-next/year-in-review/YearInReviewBanner.vue`
- `app/javascript/dashboard/components-next/year-in-review/YearInReviewModal.vue`
- `app/javascript/dashboard/components-next/year-in-review/slides/BusiestDaySlide.vue`
- `app/javascript/dashboard/components-next/year-in-review/slides/ConversationsSlide.vue`
- `app/javascript/dashboard/components-next/year-in-review/slides/IntroSlide.vue`
- `app/javascript/dashboard/components-next/year-in-review/slides/PersonalitySlide.vue`
- `app/javascript/dashboard/components-next/year-in-review/slides/ThankYouSlide.vue`
- `app/javascript/dashboard/composables/spec/useReportMetrics.spec.js`
- `app/javascript/dashboard/composables/useReportMetrics.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/AgentReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/AgentReportsIndex.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/AgentReportsShow.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/BotReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/CsatResponses.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/InboxReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/InboxReportsIndex.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/InboxReportsShow.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/Index.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/LabelReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/LabelReportsIndex.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/LabelReportsShow.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/LiveReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/ReportContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/SLAReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/TeamReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/TeamReportsIndex.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/TeamReportsShow.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/AgentLiveReportContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/BotMetrics.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ChartElements/ChartStats.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/Csat/CsatFilterHelpers.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/Csat/CsatFilters.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatContactCell.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatEmptyState.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatExpandedRow.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatMetricCard.story.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatMetricCard.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatMetrics.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatRatingDistribution.story.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatRatingDistribution.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatReviewNotesPaywall.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatTable.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/CsatTableLoader.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/Filters/v3/ActiveFilterChip.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/Filters/v3/AddFilterChip.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/OverviewReportFilters.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportDrilldownDrawer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportFilters.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportHeader.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportMetricCard.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/ReportsWrapper.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAFilter.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAMetricCard.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAMetrics.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAReportFilters.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAReportItem.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLATable.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/SLAViewDetails.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SLA/helpers/SLAFilterHelpers.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/StatsLiveReportsContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SummaryReportLink.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/SummaryReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/TeamLiveReportContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/WootReports.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/heatmaps/BaseHeatmap.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/heatmaps/BaseHeatmapContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/heatmaps/ConversationHeatmapContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/heatmaps/HeatmapDateRangeSelector.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/heatmaps/ResolutionHeatmapContainer.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/overview/AgentCell.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/overview/AgentTable.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/overview/MetricCard.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/overview/TeamTable.vue`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/CSATMetrics.spec.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/ReportDrilldownDrawer.spec.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/ReportMetricCard.spec.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/components/specs/SummaryReportLink.spec.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/constants.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/helpers/reportFilterHelper.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/helpers/reportFilterHelper.spec.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/reports.routes.js`
- `app/javascript/dashboard/routes/dashboard/settings/reports/specs/ReportContainer.spec.js`
- `app/javascript/dashboard/store/modules/SLAReports.js`
- `app/javascript/dashboard/store/modules/csat.js`
- `app/javascript/dashboard/store/modules/reports.js`
- `app/javascript/dashboard/store/modules/specs/csat/actions.spec.js`
- `app/javascript/dashboard/store/modules/specs/csat/getters.spec.js`
- `app/javascript/dashboard/store/modules/specs/csat/mutations.spec.js`
- `app/javascript/dashboard/store/modules/specs/reports/actions.spec.js`
- `app/javascript/dashboard/store/modules/specs/slaReports/actions.spec.js`
- `app/javascript/dashboard/store/modules/specs/slaReports/fixtures.js`
- `app/javascript/dashboard/store/modules/specs/slaReports/getters.spec.js`
- `app/javascript/dashboard/store/modules/specs/slaReports/mutations.spec.js`
- `app/javascript/dashboard/store/modules/specs/summaryReports.spec.js`
- `app/javascript/dashboard/store/modules/summaryReports.js`

### Campaigns — 28 file

- `app/javascript/dashboard/components-next/Campaigns/CampaignAnalyticsLayout.vue`
- `app/javascript/dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue`
- `app/javascript/dashboard/components-next/Campaigns/CampaignCard/LiveChatCampaignDetails.vue`
- `app/javascript/dashboard/components-next/Campaigns/CampaignCard/SMSCampaignDetails.vue`
- `app/javascript/dashboard/components-next/Campaigns/CampaignLayout.vue`
- `app/javascript/dashboard/components-next/Campaigns/EmptyState/CampaignEmptyStateContent.js`
- `app/javascript/dashboard/components-next/Campaigns/EmptyState/LiveChatCampaignEmptyState.vue`
- `app/javascript/dashboard/components-next/Campaigns/EmptyState/SMSCampaignEmptyState.vue`
- `app/javascript/dashboard/components-next/Campaigns/EmptyState/WhatsAppCampaignEmptyState.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignDeliveryBreakdown.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignDeliveryTable.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/CampaignMetricCard.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignAnalyticsPage/DeliveryStatusBadge.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/EditLiveChatCampaignDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/LiveChatCampaignDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/LiveChatCampaign/LiveChatCampaignForm.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/SMSCampaign/SMSCampaignForm.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignDialog.vue`
- `app/javascript/dashboard/components-next/Campaigns/Pages/CampaignPage/WhatsAppCampaign/WhatsAppCampaignForm.vue`
- `app/javascript/dashboard/routes/dashboard/campaigns/campaigns.routes.js`
- `app/javascript/dashboard/routes/dashboard/campaigns/pages/CampaignsPageRouteView.vue`
- `app/javascript/dashboard/routes/dashboard/campaigns/pages/LiveChatCampaignsPage.vue`
- `app/javascript/dashboard/routes/dashboard/campaigns/pages/SMSCampaignsPage.vue`
- `app/javascript/dashboard/routes/dashboard/campaigns/pages/WhatsAppCampaignAnalyticsPage.vue`
- `app/javascript/dashboard/routes/dashboard/campaigns/pages/WhatsAppCampaignsPage.vue`

### Help Center — 88 file

- `app/javascript/dashboard/api/helpCenter/categories.js`
- `app/javascript/dashboard/api/specs/helpCenter/categories.spec.js`
- `app/javascript/dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue`
- `app/javascript/dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/CategoryCard/CategoryCard.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Article/ArticleEmptyState.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Article/ArticleEmptyState.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Category/CategoryEmptyState.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Category/categoryEmptyStateContent.js`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Portal/PortalEmptyState.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Portal/PortalEmptyState.vue`
- `app/javascript/dashboard/components-next/HelpCenter/EmptyState/Portal/portalEmptyStateContent.js`
- `app/javascript/dashboard/components-next/HelpCenter/HelpCenterLayout.vue`
- `app/javascript/dashboard/components-next/HelpCenter/LocaleCard/LocaleCard.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/LocaleCard/LocaleCard.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleDiffPanel.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditor.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorControls.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorHeader.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditorProperties.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticlePendingChangesPopover.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleHeaderControls.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticleList.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticlesPage.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticlePage/ArticlesPage.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/ArticlePage/BulkTranslateDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoriesPage.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoriesPage.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryForm.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryHeaderControls.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/CategoryList.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/CategoryPage/EditCategoryDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/AddLocaleDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleContentDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/LocaleList.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/LocalesPage.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/LocalesPage.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/LocalePage/PopularContentDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/AddCustomDomainDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/ConfirmDeletePortalDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/DNSConfigurationDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalBaseSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalConfigurationSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalGeneralSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalIntegrationsSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalLayoutContentSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalSettings.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/PortalSettings.vue`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/classic-layout-preview.svg`
- `app/javascript/dashboard/components-next/HelpCenter/Pages/PortalSettingsPage/documentation-layout-preview.svg`
- `app/javascript/dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue`
- `app/javascript/dashboard/components-next/HelpCenter/PortalSwitcher/PortalSwitcher.story.vue`
- `app/javascript/dashboard/components-next/HelpCenter/PortalSwitcher/PortalSwitcher.vue`
- `app/javascript/dashboard/components/widgets/WootWriter/FullEditor.spec.js`
- `app/javascript/dashboard/components/widgets/WootWriter/FullEditor.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/components/UpgradePage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/helpcenter.routes.js`
- `app/javascript/dashboard/routes/dashboard/helpcenter/helpers/routeHelper.js`
- `app/javascript/dashboard/routes/dashboard/helpcenter/helpers/specs/routeHelper.spec.js`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/HelpCenterPageRouteView.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsArticlesEditPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsArticlesIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsArticlesNewPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsCategoriesIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsLocalesIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsNewPage.vue`
- `app/javascript/dashboard/routes/dashboard/helpcenter/pages/PortalsSettingsIndexPage.vue`
- `app/javascript/dashboard/routes/dashboard/onboarding/inbox-setup/HelpCenterCreationStatus.vue`
- `app/javascript/dashboard/routes/dashboard/onboarding/specs/inbox-setup/HelpCenterCreationStatus.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/actions.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/getters.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/index.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/mutations.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/specs/action.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/specs/fixtures.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/specs/getters.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterArticles/specs/mutation.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/actions.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/getters.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/index.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/mutations.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/specs/actions.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/specs/fixtures.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/specs/getters.spec.js`
- `app/javascript/dashboard/store/modules/helpCenterCategories/specs/mutations.spec.js`

## 12. Trạng thái commit

Tất cả kiểm tra cuối cùng trong phạm vi Ngày 2 đã pass. Commit được tạo riêng sau kiểm tra và tích hợp lên `easyhire-custom`; mã commit được cung cấp trong phản hồi hoàn tất và có thể lấy bằng `git log -1 --oneline`.
