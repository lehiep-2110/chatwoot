# Image Chatwoot custom cho EasyHire

**Đã phát hành Community RC2 cho nhóm kiểm thử ngày 30/10/2026.**
[Workflow phát hành](https://github.com/lehiep-2110/chatwoot/actions/runs/40970920664)
đã thành công và đẩy chính image đã kiểm thử lên GHCR.

| Thành phần | Giá trị |
| --- | --- |
| Phiên bản | `4.18.0-easyhire.1-ce-rc.2` |
| Source commit | `c9b670d2c29fb101a2c6682e64a9fe2d645479f5` |
| Registry digest | `sha256:85026ee814d7943f977125fd1cc62468bde22b30b0d8abebc48141f44cc2c08b` |
| EasyHire tương thích | `b10ebc3f568a531f18472178862ad2dfd85bb008` trên `dev_Hiep` |
| Platform | Linux amd64 |

Reference đã ghim:

```text
ghcr.io/lehiep-2110/easyhire-chatwoot:4.18.0-easyhire.1-ce-rc.2@sha256:85026ee814d7943f977125fd1cc62468bde22b30b0d8abebc48141f44cc2c08b
```

CI đã đối chiếu 6.226 file source/license, 212 assets và 3 script Linux; tạo
database mới, eager-load Rails, chạy web/worker và đạt 9 kiểm tra API HR/Inbox,
assignment, gửi tin, chặn Private Note, SSO. Chưa kiểm thử provider thật trên
image RC này. Đã tải image bằng Docker theo digest trong chế độ không đăng nhập
và đối chiếu metadata phát hành; thành viên không cần tài khoản registry.

RC2 giữ cookie hội thoại riêng cho từng Website Inbox và cho phép chuyển công
ty trên cùng trang mà vẫn khôi phục đúng lịch sử. EasyHire chỉ ẩn widget khi
rời Career Site. Đã đạt thêm 9 luồng trình duyệt trên chính image tải từ GHCR,
không mount SDK bên ngoài. Cần cập nhật đồng thời frontend EasyHire và image
Chatwoot; frontend tải SDK với phiên bản RC2 để tránh dùng lại bản cũ trong bộ
nhớ đệm trình duyệt. Dữ liệu và schema không đổi.

Workflow `Publish EasyHire Chatwoot image` build từ commit được push lên nhánh
`easyhire-custom` khi thay `docker/easyhire-release.json`, `docker/Dockerfile`,
workflow hoặc hai script `verify_easyhire_image.rb` / `verify_easyhire_runtime.rb`.
Image dùng registry `ghcr.io/lehiep-2110/easyhire-chatwoot`; bản hiện tại dành cho
nhóm kiểm thử là `4.18.0-easyhire.1-ce-rc.2`, nền Chatwoot v4.18.0, Linux amd64.

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
