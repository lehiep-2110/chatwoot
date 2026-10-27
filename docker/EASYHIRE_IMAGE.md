# Image Chatwoot custom cho EasyHire

**Chưa có image phát hành.** Workflow đang tắt trong lúc chốt edition và điều
kiện phân phối. Lượt build đầu đã hủy trước bước đăng nhập GHCR/publish vì bản
đóng gói còn Enterprise overlay; xem `enterprise/LICENSE`. Không dùng tag bên
dưới như một image đã tồn tại. Phương án đề xuất là image Community custom,
kiểm chứng lại HR/Inbox/SSO trước khi công bố. Mã license và edition detection
trong ứng dụng chưa được thay đổi.

Workflow `Publish EasyHire Chatwoot image` build từ commit được push lên nhánh
`easyhire-custom` khi thay `docker/easyhire-release.json` hoặc chính workflow.
Image dùng registry `ghcr.io/lehiep-2110/easyhire-chatwoot`; bản đầu dành cho
nhóm kiểm thử là `4.18.0-easyhire.1-rc.1`, nền Chatwoot v4.18.0, Linux amd64.

Workflow giữ nguyên Enterprise overlay và license. Không dùng workflow CE/EE
gốc để phát hành bản EasyHire. Không có token Meta/Telegram, database, CV,
`.env` hoặc thông tin đăng nhập EasyHire trong image.

Trước khi push image, workflow đối chiếu source, assets, script Linux, khởi tạo
PostgreSQL mới, eager-load Rails, khởi động web/Sidekiq và kiểm tra HTTP. Sau khi
thành công, artifact `easyhire-image` chứa `easyhire-image.json` với revision,
phiên bản và digest thật. Ghi nguyên trường `reference` vào `CHATWOOT_IMAGE` của
EasyHire; web và worker phải dùng cùng reference.

Tag phiên bản không được ghi đè. Một bản source mới cần phiên bản mới. Đây là
bản thử nghiệm cho nhóm; chạy được web/worker không thay thế kiểm thử HR/SSO,
phân công, realtime và provider thật với phiên bản EasyHire tương ứng.

GHCR mặc định tạo package private lần đầu. Chủ repo cần mở package settings,
chuyển public nếu muốn thành viên tải không cần đăng nhập; sau đó xác nhận pull
ẩn danh bằng digest. Không ghi token registry vào Compose hoặc `.env.example`.

Hướng dẫn cài EasyHire nằm ở `chatwoot/INTEGRATION_CUSTOM.md` trong repo DATN,
nhánh `dev_Hiep`. Thành viên chạy image đã công bố, không cần clone/build repo
Chatwoot trừ khi muốn sửa mã nguồn.
