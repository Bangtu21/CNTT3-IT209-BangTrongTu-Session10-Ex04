## 1. Mục tiêu
- Tạo Custom Bridge Network `app-net`.
- Tạo Named Volume `db-data` để lưu dữ liệu PostgreSQL.
- Kết nối các container qua DNS nội bộ Docker.
- Kiểm tra Data Persistence khi xóa và tạo lại container database.

## 2. Môi trường
- Ubuntu Server trên VPS.
- Docker CLI.
- PostgreSQL 15 Alpine.
- Alpine Linux làm container kiểm thử phía Backend.

## 3. Các bước thực hiện
1. Tạo network `app-net` và volume `db-data`.
2. Khởi chạy PostgreSQL container `db-server`, mount volume vào `/var/lib/postgresql/data`.
3. Khởi chạy `app-container` trên cùng network và cấu hình `DB_HOST=db-server`.
4. Kiểm tra phân giải DNS bằng `ping -c 2 db-server`.
5. Tạo bảng và thêm dữ liệu kiểm thử.
6. Xóa container database, tạo lại với cùng Named Volume và truy vấn dữ liệu.

## 4. Kết quả
- Hai container tham gia cùng network `app-net`.
- Backend kiểm thử kết nối database thông qua hostname `db-server`.
- Volume `db-data` tồn tại độc lập với container database.
- Dữ liệu trong bảng `persistence_test` vẫn tồn tại sau khi tạo lại container.
