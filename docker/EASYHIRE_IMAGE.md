# Image Chatwoot custom cho EasyHire

**Đã phát hành bản Community RC cho nhóm kiểm thử ngày 27/10/2026.**
[Workflow phát hành](https://github.com/lehiep-2110/chatwoot/actions/runs/40526296866)
đã thành công và đẩy chính image đã kiểm thử lên GHCR.

| Thành phần | Giá trị |
| --- | --- |
| Phiên bản | `4.18.0-easyhire.1-ce-rc.1` |
| Source commit | `f54ceaadeed7d242a6ab510a6be452a214d97679` |
| Registry digest | `sha256:fe1e16eaf135b1b278f59c771bf327aee0b02848aafd488fb61f60773eab2170` |
| EasyHire tương thích | `da455c1afa931ec7f16330054b86c5d095bd37c4` và cập nhật cấu hình/tài liệu tiếp theo trên `dev_Hiep` |
| Platform | Linux amd64 |

Reference đã ghim:

```text
ghcr.io/lehiep-2110/easyhire-chatwoot:4.18.0-easyhire.1-ce-rc.1@sha256:fe1e16eaf135b1b278f59c771bf327aee0b02848aafd488fb61f60773eab2170
```

CI đã đối chiếu 6.226 file source/license, 212 assets và 3 script Linux; tạo
database mới, eager-load Rails, chạy web/worker và đạt 9 kiểm tra API HR/Inbox,
assignment, gửi tin, chặn Private Note, SSO. Chưa kiểm thử provider thật trên
image RC này. Đã tải image bằng Docker theo digest trong chế độ không đăng nhập
và đối chiếu metadata phát hành; thành viên không cần tài khoản registry.

Workflow `Publish EasyHire Chatwoot image` build từ commit được push lên nhánh
`easyhire-custom` khi thay `docker/easyhire-release.json`, workflow hoặc hai script
`verify_easyhire_image.rb` / `verify_easyhire_runtime.rb`.
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

Không ghi token registry vào Compose hoặc `.env.example`. Mỗi phiên bản phát
hành cần xác nhận quyền tải của nhóm và kiểm tra pull bằng digest.

Hướng dẫn cài mới:
[QUICKSTART_TEAM.md](https://github.com/hoangthaian04/DATN/blob/dev_Hiep/chatwoot/QUICKSTART_TEAM.md)
trong repo DATN, nhánh `dev_Hiep`. Thành viên cần quyền truy cập repo DATN;
chạy image đã công bố, không cần clone/build repo Chatwoot trừ khi muốn sửa source.
