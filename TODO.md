# 🚀 Project Roadmap & Task Tracker

> **Status:** Active Development  
> **Current Sprint:** Week 1 (Refactoring & Documentation)

---

## 🗓️ This Week: Polishing & Foundation
*Fokus pada dokumentasi dan pembersihan UI sebelum masuk ke perubahan arsitektur besar.*

| Task | Priority | Category | Status |
| :--- | :--- | :--- | :--- |
| **Refactor Name View** | 🔴 High | UI Refactor | [ ] |
| **Create Web Documentation** | 🟡 Medium | Docs | [ ] |
| **Make Update Post** | 🟢 Low | Social | [ ] |

### Details:
- [ ] **Name View:** Pastikan logic dipisah dari UI (Stateless) untuk persiapan SDUI.
- [ ] **Web Doc:** Update API reference & component usage.
- [ ] **Social:** Draft konten update mingguan untuk komunitas/tim.

---

## 🏗️ Next Week: Architectural Overhaul
*Target: Mengubah sistem navigasi menjadi fully type-safe dan berbasis server (SDUI).*

### 1. Advanced Navigation System
*Implementasi navigasi yang robust dan aman.*
- [ ] **Type-Safety Layer:** Definisi rute menggunakan Sealed Classes/Enums untuk menghindari string-based routing.
- [ ] **Multi-Step Wizards:** Bangun logic state machine untuk form berjenjang.
- [ ] **Deep Linking:** Mapping URL eksternal langsung ke internal router.
- [ ] **Custom Nav Bar:** Reusable component yang terintegrasi dengan stack navigasi baru.

### 2. Clean Architecture & SDUI
*Memindahkan kontrol navigasi ke "Source" (Backend).*
- [ ] **SDUI Parser:** Buat engine untuk menerjemahkan JSON dari server menjadi aksi navigasi.
- [ ] **Clean Architecture Bridge:** Pastikan router tidak memiliki ketergantungan langsung pada UI (Decoupling).
- [ ] **Action Handling:** Implementasi handler untuk *remote-triggered actions*.

---

## 🪵 Backlog & Future Ideas
- [ ] Implementasi caching untuk Source SDUI.
- [ ] Unit Testing untuk Navigation Logic.
- [ ] Skeleton loading untuk transisi antar wizard.

---

## 💡 Notes
* **Reminder:** Selesaikan refactor `Name View` di awal minggu agar tidak menghambat transisi ke SDUI di minggu depan.
* **Goal:** Mencapai nol `runtime error` pada navigasi melalui *strict typing*.