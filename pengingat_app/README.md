# Pengingat App (MVP)

Flutter, offline-first. Fitur: pengingat sekali/harian/mingguan, kategori,
prioritas, notifikasi + popup layar penuh, tombol Selesai/Tunda, tetap bunyi
saat aplikasi ditutup dan setelah HP restart.

## Cara menjalankan
1. `flutter create pengingat_app` (buat proyek kosong).
2. Salin `pubspec.yaml` dan folder `lib/` dari sini, timpa yang lama.
3. Tempel isi `android_tambahan/AndroidManifest_tambahan.xml` ke
   `android/app/src/main/AndroidManifest.xml`.
4. Di `android/app/build.gradle`: `compileSdk 34`, `minSdk 21`, dan aktifkan
   core library desugaring (dibutuhkan flutter_local_notifications):
   `compileOptions { coreLibraryDesugaringEnabled true }` dan
   `dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4' }`.
5. `flutter pub get` lalu `flutter run` di HP asli (bukan emulator).

## Pengaturan wajib di vivo V29 (Funtouch OS)
Tanpa ini alarm sering mati saat aplikasi ditutup:
- Pengaturan > Baterai > Konsumsi daya latar belakang > Pengingat > *Izinkan*
- Pengaturan > Aplikasi > Pengingat > Izin > *Mulai otomatis* (Autostart) aktif
- Kunci aplikasi di Recent Apps (ikon gembok)
- Notifikasi > Pengingat > izinkan *popup layar penuh/layar kunci*
- Izin *Alarm & pengingat* aktif

## Langkah berikutnya
- Tugas + deadline bertahap (H-3, H-1, 1 jam)
- Modul manajemen kost (tagihan, jatuh tempo, penghuni)
- Sinkronisasi Supabase/Firebase
- Fitur AI (input bahasa natural)
