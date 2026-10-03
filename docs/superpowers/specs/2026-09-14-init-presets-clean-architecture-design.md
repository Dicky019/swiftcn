# Desain Init Preset Clean Architecture

## Status

Implementasi kedua plan selesai dan diverifikasi pada 3 Oktober 2026. Preset Native/MVVM/TCA, transaksi init, dan Offline-First Core tersedia di branch `feat/init-presets-offline-first`. [Hasil implementasi dan verifikasi](../reports/2026-10-03-init-presets-offline-first.md). Distribusi CLI menunggu release baru beserta source tag yang cocok.

## Tujuan

`swiftcn init` menyediakan tepat tiga preset SwiftUI:

- `native`
- `mvvm`
- `tca`

Semua preset memakai Clean Architecture. `--offline-first` adalah capability opt-in yang dapat dipadukan dengan ketiganya, bukan preset keempat.

## Keputusan utama

| Area | Keputusan |
|---|---|
| Default | `native` tanpa Offline-First |
| Navigation Native/MVVM | Reuse `Router<Route>` dari PR #7 yang sudah merged; jangan membuat Router baru |
| Navigation TCA | `StackState` dan `@Presents`; jangan memasang `Router<Route>` |
| Offline-First | Local source of truth + durable outbox + single-flight sync melalui inner ports |
| External Systems | Database, API, CloudKit, dan sync SDK hanya boleh muncul sebagai adapter luar |
| VIPER | Dikeluarkan dari scope |

## Batas produk

`swiftcn` tetap alat copy-owned template, bukan application framework atau pengganti generator project Xcode/Tuist. `init` mengonfigurasi aplikasi SwiftUI yang sudah ada dan hanya memasang fondasi yang dipilih pengguna.

CLI tidak membuat empty protocol, service spekulatif, global service locator, atau abstraction tunggal yang menyembunyikan Native, MVVM, dan TCA di balik runtime API yang sama.

### Output `init` v1

Project yang sudah ada adalah trust boundary. Karena `init` tidak mengetahui nama app, target membership, composition root, atau domain pengguna, v1 tidak mengubah `App.swift`, `.xcodeproj`, `Package.swift`, `Project.swift`, entitlement, dan source feature yang sudah ada. V1 juga tidak menyalin dummy `ExampleFeature` atau folder layer kosong.

Output yang benar-benar dimiliki `init` adalah:

| Pilihan | File/config yang dihasilkan |
|---|---|
| Semua preset | Theme seperti perilaku sekarang, `swiftcn.json`, serta terminal next steps yang menautkan recipe repo spesifik preset |
| `--navigation` + Native/MVVM | Satu `Navigation/Router.swift` dari registry item PR #7 |
| `--navigation` + TCA | Tidak memasang Router; config dan recipe memakai navigation state TCA |
| `--offline-first` | Shared Offline-First Core yang sama untuk ketiga preset; tidak memasang persistence/network adapter |
| `--sdui` | SDUI seperti perilaku sekarang, orthogonal terhadap preset |

Preset bukan runtime framework. Nilai preset adalah kebijakan project-owned untuk recipe dan penambahan feature pada pekerjaan terpisah. Feature scaffolding bernama (`swiftcn add feature ...`) tidak termasuk v1 ini; menambahnya tanpa kontrak nama/domain akan menghasilkan placeholder yang bertentangan dengan filosofi repo.

## Kontrak Clean Architecture

Setiap feature adalah vertical slice:

```text
Features/<Feature>/
  Domain/
  Application/
  Infrastructure/
  Presentation/
```

Arah source dependency selalu menuju layer dalam:

```text
Presentation ──> Application ──> Domain
Infrastructure ────────────────> Application / Domain ports
Composition Root ──────────────> concrete assembly only
```

Domain berisi entity, value type, dan business invariant dalam pure Swift. Domain tidak boleh mengimpor SwiftUI, Composable Architecture, SwiftData, networking, analytics, Router, atau vendor SDK.

Application memiliki use case dan dependency port yang dibutuhkan use case. Infrastructure mengimplementasikan port tersebut. Composition Root adalah satu-satunya tempat yang memilih implementasi live.

Struktur layer bersifat konseptual dan hanya dibuat ketika memiliki source nyata. Sebuah feature tanpa I/O tidak dipaksa memiliki folder `Infrastructure/` kosong. Compliance yang dapat dijamin tooling adalah terhadap template/recipe yang dikirim swiftcn; CLI tidak mengklaim dapat memigrasikan atau memvalidasi seluruh source aplikasi pengguna.

## Perbedaan flow preset

### Native

```text
SwiftUI View + @State ──> Use Case ──> Domain
```

View memiliki UI state lokal dan memanggil use case secara langsung. Tidak ada ViewModel. Hasil use case dikembalikan sebagai value lalu diterapkan ke `@State` pada MainActor.

Pilih Native untuk feature sederhana. Ketika loading/data/error state, cancellation, dan orchestration asynchronous memerlukan owner terpisah, pilih atau migrasikan feature ke MVVM.

Diagram: [Native Clean Architecture](../../init-preset-native.html)

### MVVM

```text
SwiftUI View ──> Observable ViewModel ──> Use Case ──> Domain
```

`@MainActor @Observable` ViewModel memiliki `ScreenState`, lifecycle pekerjaan asynchronous, dan translasi intent. View hanya merender state serta mengirim intent. Business rule tetap berada di Domain.

ViewModel mengirim typed navigation outcome. Flow owner memvalidasi outcome lalu menjadi satu-satunya pemilik yang memutasi `Router<Route>`.

Diagram: [MVVM Clean Architecture](../../init-preset-mvvm.html)

### TCA

```text
SwiftUI View ──> Store ──> Reducer<State, Action> ──> Use Case ──> Domain
```

Reducer adalah state machine dan effect orchestrator. Dependency client menjadi boundary menuju use case atau Infrastructure. Domain tidak mengetahui `Store`, `Reducer`, `Effect`, atau dependency runtime TCA.

Navigation menjadi bagian dari reducer state menggunakan `StackState`/`StackActionOf` dan `@Presents`/`PresentationAction`.

Diagram: [TCA Clean Architecture](../../init-preset-tca.html)

## Navigation baseline: PR #7

[PR #7](https://github.com/Dicky019/swiftcn/pull/7) sudah merged pada 14 September 2026 melalui commit `efc12cbc5419b734bc2b481706c805e0cd475522` dan menjadi baseline navigation. PR tersebut menyediakan template dependency-free `Router<Route: Hashable>` dengan operasi `push`, `pop`, `popToRoot`, `replace`, dan `replaceLast`.

- Native: root memiliki `@State Router<AppRoute>` dan memasukkannya ke SwiftUI environment.
- MVVM: flow owner memiliki Router; ViewModel hanya melaporkan typed outcome dan tidak membuat View.
- TCA: gunakan navigation state TCA secara langsung; registry item Router tidak dipasang.
- Route hanya membawa stable identifier, bukan View, ViewModel, service, credential, atau mutable domain object.
- Deep link/restoration divalidasi penuh sebelum `replace(with:)`; path tidak diterapkan sebagian.
- Setiap tab memiliki path sendiri.

`--navigation` bersifat opt-in dan default-nya `false` agar `swiftcn init -y` tetap backward-compatible. Interactive init menawarkan pilihan yang sama. Untuk Native/MVVM, init harus mendelegasikan instalasi ke registry item yang sama dengan `swiftcn add navigation`; tidak boleh ada salinan Router khusus preset. Untuk TCA, flag tersebut hanya mengaktifkan recipe/config navigation TCA dan tidak menyalin file Router.

`swiftcn add navigation` pada config TCA ditolak dengan pesan yang mengarahkan pengguna ke `StackState`/`@Presents`, agar init tidak menciptakan dua source of truth navigation. Aplikasi mixed-architecture berada di luar v1 dan dapat menyalin template secara manual sebagai keputusan eksplisit pemilik aplikasi.

## Capability Offline-First

CLI:

```text
swiftcn init --preset native --offline-first
swiftcn init --preset mvvm --offline-first
swiftcn init --preset tca --offline-first
```

`--offline-first` default-nya `false`. Config lama tanpa field tersebut diperlakukan sebagai disabled. Menjalankan ulang init tanpa flag tidak boleh menghapus Offline-First Core yang sudah dimiliki pengguna.

Diagram: [Offline-First Clean Architecture](../../init-option-offline-first.html)

### Tanggung jawab

| Bagian | Tanggung jawab |
|---|---|
| Feature Domain | Entity `Sendable`, invariant, dan conflict policy yang benar-benar merupakan keputusan bisnis |
| Feature Application | Local-first use case, arti saved-locally/server-accepted, repository dan external gateway ports |
| Shared Sync Core | `SyncCoordinator` actor, sync state/outcome, trigger coalescing, cancellation, retry scheduling |
| Feature Sync Worker | Push pending mutation, pull remote changes, reconciliation, dan checkpoint melalui ports |
| Local Adapter | Transaksi entity + outbox + cursor, observation, tombstone, migration, durable retry metadata |
| External Adapter | API/SDK mapping ke accepted, retryable, rejected, atau conflict tanpa membocorkan HTTP/SDK type |
| Platform Adapter | Lifecycle, optional connectivity hint, BackgroundTasks, sanitized logging, clock |
| Composition Root | Memasang adapter konkret sekali untuk setiap account/store scope |

Shared Sync Core sama untuk ketiga preset dan tidak mengimpor SwiftUI, TCA, Router, persistence framework, networking framework, atau SDK vendor. Perbedaannya hanya presentation bridge dan composition.

### Public contract v1

Core yang disalin terdiri dari tiga file agar tanggung jawabnya tetap kecil:

```text
OfflineFirst/
  SyncTypes.swift
  RetryPolicy.swift
  SyncCoordinator.swift
```

API publiknya dikunci pada bentuk berikut; detail payload/domain tidak masuk Core:

```swift
public struct SyncScope: Hashable, Sendable {
  public let rawValue: String
  public init(rawValue: String)
}

public enum SyncTrigger: Hashable, Sendable {
  case launch, foreground, manual, localMutation, connectivityHint
}

public enum RetryReason: Equatable, Sendable {
  case transport, timeout, serverBusy
}

public enum SyncBlockReason: Equatable, Sendable {
  case authentication, conflict, permanentRejection, storage, migration
}

public enum SyncPassResult: Equatable, Sendable {
  case noWork
  case completed
  case retry(reason: RetryReason, serverHint: Duration?)
  case blocked(SyncBlockReason)
  case expired
}

public enum SyncOutcome: Equatable, Sendable {
  case noWork
  case completed
  case deferred(RetryReason)
  case blocked(SyncBlockReason)
  case cancelled
  case expired
}

public protocol SyncWorker: Sendable {
  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult
}

public struct RetryPolicy: Equatable, Sendable {
  public init(maximumAttempts: Int, baseDelay: Duration, maximumDelay: Duration)
  public func delay(
    forAttempt attempt: Int,
    serverHint: Duration?,
    jitter: Double
  ) -> Duration?
}

public typealias SyncSleeper = @Sendable (Duration) async throws -> Void
public typealias SyncJitter = @Sendable () -> Double

public actor SyncCoordinator<Worker: SyncWorker> {
  public init(scope: SyncScope, worker: Worker, retryPolicy: RetryPolicy)
  public init(
    scope: SyncScope,
    worker: Worker,
    retryPolicy: RetryPolicy,
    sleep: @escaping SyncSleeper,
    jitter: @escaping SyncJitter
  )
  public func request(_ trigger: SyncTrigger) async -> SyncOutcome
  public func cancel()
}
```

Satu instance coordinator hanya memiliki satu `SyncScope`. Trigger yang datang saat pass aktif digabungkan menjadi satu set dan menghasilkan paling banyak satu follow-up pass; coordinator tidak berjalan sebagai singleton lintas account. `jitter` harus diinjeksi sebagai nilai `0...1` pada boundary scheduling agar test deterministik; nilai di luar range di-clamp oleh `RetryPolicy`. Satu request menjalankan initial attempt lalu maksimal `maximumAttempts` retry. Setelah budget habis, coordinator mengembalikan `.deferred` dan durable work tetap berada di adapter untuk trigger berikutnya. Worker memiliki outbox/gateway/reconciliation feature dan mengembalikan kategori hasil, bukan transport error mentah.

### Read flow

```text
Presentation ──> Use Case ──> Repository Port ──> Local Adapter
                                                   │
                                                   └── observed local snapshots
```

UI selalu membaca local source of truth. Remote refresh masuk melalui reconciliation dan menulis ke local store yang sama. Data yang tersedia tidak dihapus hanya karena refresh gagal.

### Write flow

```text
intent ──> validate ──> atomic(local projection + durable outbox)
       ──> saved locally ──> request sync pass
```

`saveEntity()` dan `enqueueMutation()` tidak boleh menjadi dua commit terpisah. Outbox menyimpan stable operation ID, account/entity scope, versioned command payload, base revision bila tersedia, ordering/dependency, dan retry metadata. Token, closure, `URLRequest`, serta SDK object tidak disimpan dalam outbox.

### Sync flow

- Maksimal satu sync pass aktif untuk satu account/store scope.
- Trigger launch, foreground, manual refresh, local commit, dan connectivity change hanya menggabungkan permintaan kerja.
- Retry memakai operation ID yang sama, capped exponential backoff + jitter, timeout, server retry hint, dan retry budget.
- Outbox dihapus hanya setelah acknowledgment/reconciliation committed secara atomik.
- Remote page dan cursor diterapkan dalam satu transaksi; cursor tidak maju jika apply gagal.
- Conflict, permanent rejection, auth wait, cancellation, disk full, migration failure, dan background expiration memiliki outcome berbeda.
- Connectivity hanyalah scheduling hint, bukan bukti backend dapat dijangkau.
- Background sync bersifat best effort dan harus dapat dilanjutkan setelah expiration atau process termination.
- Conflict resolution dan delete-vs-update policy dimiliki feature/domain; default aman adalah mendeteksi conflict dan mempertahankan local intent.
- Tombstone dipertahankan sampai protokol sync membuktikan delete telah tercakup.

### External-system agnosticism

Core hanya mengenal ports dan value outcomes. SwiftData, GRDB, Core Data, CloudKit, PowerSync, REST, GraphQL, dan vendor SDK adalah pilihan adapter aplikasi. Init tidak memasang vendor, endpoint palsu, in-memory production store, atau background entitlement secara otomatis.

Jika aplikasi membutuhkan capability yang langsung runnable, adapter konkret harus dipilih pada tahap integrasi terpisah. Engine agnostic dan aplikasi production-ready tanpa persistence adapter bukan klaim yang sama.

V1 yang dikirim ke pengguna hanya berisi kontrak/value types, `RetryPolicy`, dan `SyncCoordinator` actor. Push, pull, reconciliation, repository, outbox schema, dan conflict resolver tetap feature-owned melalui satu `SyncWorker` boundary; Core tidak menyediakan universal CRUD/payload model.

Requirement durabilitas diverifikasi oleh reference SwiftData adapter yang hanya hidup di test fixture repo. Adapter tersebut membuktikan kontrak atomic entity/outbox/cursor dan crash/reopen pada iOS 17+, tetapi tidak ikut disalin oleh `--offline-first`. Pemilihan adapter production tetap keputusan aplikasi.

Navigation tetap orthogonal: route membawa stable entity ID dan destination membaca local repository. Sync worker tidak melakukan push/pop route.

## Init experience

Interactive init menanyakan satu preset serta menawarkan Navigation dan Offline-First sebagai opt-in. Automation memakai:

```text
swiftcn init --preset <native|mvvm|tca> [--navigation] [--offline-first]
```

Fresh `swiftcn init -y` memilih `native`, `navigation: false`, dan `offlineFirst: false`. Flag negasi `--no-navigation` dan `--no-offline-first` tersedia untuk automation yang ingin menonaktifkan nilai existing secara eksplisit; flag yang tidak diberikan mempertahankan nilai config existing.

Selection disimpan sebagai data sederhana di `swiftcn.json` dengan field `preset`, `navigation`, dan `offlineFirst`; tidak ada runtime plugin registry. Schema lama tetap valid dan dibaca sebagai `native`, `false`, `false`.

Destination root untuk fondasi nonvisual mengikuti pola PR #7 dan dihitung sekali sebagai `dirname(componentsPath)`. Contoh: `App/Components` menghasilkan `App/Navigation` dan `App/OfflineFirst`; default `Components` menghasilkan `Navigation` dan `OfflineFirst`. Tidak ada option path baru pada v1.

TCA adalah satu-satunya preset dengan architecture dependency eksternal. CLI tidak boleh mengedit project/package manifest aplikasi atau menganggap package sudah terpasang. Recipe dan compile fixture dipin ke `swift-composable-architecture` 1.26.1, yang memakai Swift tools 6.1 dan mendukung iOS 16+; karena itu preset TCA v1 memerlukan toolchain Swift 6.1+ sementara minimum aplikasi tetap iOS 17. Sebelum implementasi, version pin ini diperiksa ulang terhadap release resmi dan hanya berubah melalui spec amendment.

Rerun init memuat config existing sebagai baseline. Opsi eksplisit mengubah nilai; opsi yang tidak diberikan mempertahankan nilai. Menonaktifkan capability hanya mengubah config dan next-step output—CLI tidak menghapus source copy-owned. Mengubah preset tidak memigrasikan feature source existing dan harus menampilkan peringatan tersebut sebelum menulis config.

Sebelum menulis, init memuat satu registry/source snapshot lalu membangun operation plan immutable: source, destination, action `create|replace|skip`, config result, dan conflict. Semua source/path/config divalidasi sebelum mutasi pertama. `--force` mengubah file conflict menjadi `replace`; tanpa force file existing menjadi `skip` dan tidak pernah ditimpa.

Apply memakai staging dan backup di filesystem project yang sama. Error yang tertangkap me-rollback file baru, mengembalikan backup, dan mempertahankan config lama. Journal tersisa akibat process termination dipulihkan sebelum init berikutnya. Jaminan lintas-file berarti recoverable transaction, bukan klaim bahwa filesystem menyediakan satu atomic rename untuk seluruh project. Config ditulis terakhir dengan atomic temp-file rename.

Download, registry validation, invalid preset/path, dan TCA compatibility guidance selesai sebelum apply. Cancellation prompt sebelum apply tidak membuat file; cancellation atau error saat apply mengikuti rollback yang sama.

### Compatibility matrix

| Input | Hasil |
|---|---|
| Fresh tanpa `--preset` | `native` |
| Existing config tanpa field baru | Dibaca sebagai Native, Navigation off, Offline-First off |
| Rerun tanpa capability flags | Pertahankan nilai existing dan source copy-owned |
| `--no-*` | Ubah config menjadi false, jangan hapus source |
| Existing destination tanpa `--force` | Skip |
| Existing destination dengan `--force` | Backup lalu replace; rollback memulihkan original |
| Unknown preset | Gagal sebelum clone/copy/config write |
| TCA + navigation | Recipe TCA; Router tidak di-install |
| `add navigation` pada TCA | Gagal dengan guidance; tidak menulis file |

## Verification requirements

- CLI tests mencakup tiga preset, default opt-out Navigation/Offline-First, positive/negative flags, invalid input, legacy config, repeat init, conflict, rollback, dan stale-journal recovery.
- Native/MVVM recipe fixture serta Shared Sync Core dikompilasi dengan Swift 6 strict concurrency dan iOS 17+; TCA fixture dikompilasi dengan Swift 6.1+, TCA 1.26.1, dan iOS 17+.
- Architecture check menolak forbidden imports pada Domain dan Shared Sync Core.
- Native test membuktikan View-facing state dapat memakai use case tanpa ViewModel.
- MVVM test membuktikan ViewModel memiliki state/orchestration dan mengirim typed navigation outcome.
- TCA test membuktikan reducer state/effect/navigation tanpa Router kedua.
- Crash/reopen contract test membuktikan entity dan outbox tidak pernah berbeda hasil commit.
- Server commit lalu response hilang tidak menggandakan side effect ketika operation ID di-retry.
- Edit kedua tidak hilang ketika acknowledgment edit pertama datang terlambat.
- Concurrent triggers menghasilkan maksimal satu sync pass per scope.
- Partial batch, duplicate page, apply failure, cursor expiry, conflict, tombstone, account switch, migration, dan background expiration tidak kehilangan pending work.
- Minimal satu persistence adapter menjalani durable transactional tests; in-memory fake saja tidak cukup.
- Navigation dari PR #7 dapat dipasang/dihapus terpisah dari Offline-First.
- Real registry test memastikan Native/MVVM init memakai persis `Navigation/Router.swift`, sedangkan TCA init tidak meminta registry item tersebut.
- Config write memakai atomic replacement dan kegagalan pada file ke-N tidak meninggalkan partial init setelah rollback/recovery.

## Explicitly excluded

- VIPER preset
- Universal storage/network/CRUD abstraction untuk semua backend
- Cache-only flow yang diberi label Offline-First
- Exactly-once guarantee dari client tanpa server idempotency contract
- Reachability gate sebelum mencoba request
- Global `SyncCoordinator` lintas account
- Retry bertumpuk di coordinator, repository, URL client, dan SDK
- Device-clock last-write-wins sebagai conflict policy universal
- Router dipanggil dari sync worker
- Automatic migration dari architecture aplikasi yang sudah ada
- Project/workspace generation
- Sample feature yang harus dihapus/rename pengguna
- Editing `App.swift`, Xcode/Tuist/SPM manifests, target membership, atau entitlements
- Automatic feature scaffolding; memerlukan desain `add feature` terpisah

## Research references

- [PR #7 — typed SwiftUI Router](https://github.com/Dicky019/swiftcn/pull/7)
- [TCA 1.26.1 Package.swift](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.1/Package.swift)
- [TCA 1.26.1 NavigationStack case study](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.1/Examples/CaseStudies/SwiftUICaseStudies/04-NavigationStack.swift)
- [Apple sample-cloudkit-sync-engine](https://github.com/apple/sample-cloudkit-sync-engine)
- [Apple SchemaMigrationPlan](https://developer.apple.com/documentation/SwiftData/SchemaMigrationPlan)
- [Apple background task strategies](https://developer.apple.com/documentation/BackgroundTasks/choosing-background-strategies-for-your-app)
- [Apple waitsForConnectivity](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/waitsforconnectivity)
- [Swift 6 data-race safety](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/dataracesafety/)
- [AWS idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)
- [AWS exponential backoff and jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
- [CouchDB replication protocol](https://docs.couchdb.org/en/stable/replication/protocol.html)
- [PowerSync client architecture](https://docs.powersync.com/architecture/client-architecture)
- [GRDB.swift](https://github.com/groue/GRDB.swift)

Research was curated and the repository contract was re-audited on 14 September 2026. Moving documentation and GitHub default branches must be rechecked before implementation; dependency adapters require an explicit pinned version.
