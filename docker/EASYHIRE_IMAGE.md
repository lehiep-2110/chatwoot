# Image Chatwoot custom cho EasyHire

**Bản Community đang chờ build và kiểm chứng trước khi công bố.** Chỉ dùng image
khi workflow thành công và đã có digest trong artifact phát hành. Lượt build
Enterprise trước đó đã hủy trước publish. Source/license vẫn giữ nguyên trong
repo; build context phát hành loại Enterprise theo cách đóng gói CE chính thức.

Workflow `Publish EasyHire Chatwoot image` build từ commit được push lên nhánh
`easyhire-custom` khi thay `docker/easyhire-release.json` hoặc chính workflow.
Image dùng registry `ghcr.io/lehiep-2110/easyhire-chatwoot`; bản đầu dành cho
nhóm kiểm thử là `4.18.0-easyhire.1-ce-rc.1`, nền Chatwoot v4.18.0, Linux amd64.

Workflow giữ nguyên license và edition detection trong source. Enterprise
không được đưa vào image; image có `CW_EDITION=ce`. Không dùng workflow CE/EE
gốc để phát hành bản EasyHire. Không có token Meta/Telegram, database, CV,
`.env` hoặc thông tin đăng nhập EasyHire trong image.

Trước khi push image, workflow đối chiếu source, assets, script Linux, khởi tạo
PostgreSQL mới, eager-load Rails, khởi động web/Sidekiq, kiểm tra HTTP và kiểm tra
quyền HR/Inbox, phân công, gửi tin, SSO qua Platform API. Sau khi
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
