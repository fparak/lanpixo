import SwiftUI
import UniformTypeIdentifiers

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var ads: AdService
    var body: some View {
        TabView(selection: Binding(get: { model.selectedTab }, set: { model.changeTab($0) })) {
            NavigationStack { NetworkView() }
                .tabItem { Label(model.text("Network", "Ağ"), systemImage: "network") }
                .tag(0)
            NavigationStack { SpeedView() }
                .tabItem { Label(model.text("Speed", "Hız testi"), systemImage: "speedometer") }
                .tag(1)
            NavigationStack { HistoryView() }
                .tabItem { Label(model.text("History", "Geçmiş"), systemImage: "clock.arrow.circlepath") }
                .tag(2)
            NavigationStack { SettingsView() }
                .tabItem { Label(model.text("Settings", "Ayarlar"), systemImage: "gearshape") }
                .tag(3)
        }
    }
}

struct StatusView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Text(message).font(.subheadline).foregroundStyle(.secondary)
            .accessibilityAddTraits(.updatesFrequently)
    }
    var message: String {
        switch model.status {
        case "scanning": return model.text("Discovering responding devices…", "Yanıt veren cihazlar aranıyor…")
        case "complete": return model.text("Completed", "Tamamlandı")
        case "partial": return model.text("Time limit reached. Results are partial.", "Süre sınırına ulaşıldı. Sonuçlar kısmidir.")
        case "cancelled": return model.text("Stopped. Results may be partial.", "Durduruldu. Sonuçlar kısmi olabilir.")
        case "wifi": return model.text("Connect to Wi-Fi and try again. VPNs may restrict discovery.", "Wi-Fi’ye bağlanıp tekrar dene. VPN keşfi sınırlayabilir.")
        case "subnet": return model.text("Only IPv4 /22–/30 networks are supported.", "Yalnızca IPv4 /22–/30 ağları desteklenir.")
        case "changed": return model.text("Network changed. Run a new scan.", "Ağ değişti. Yeni bir tarama başlat.")
        case "permission": return model.text("Bonjour discovery is unavailable. Check Local Network access in iOS Settings, then scan again.", "Bonjour keşfi kullanılamıyor. iOS Ayarlar’dan Yerel Ağ erişimini kontrol edip tekrar tara.")
        case "latency": return model.text("Measuring HTTPS latency…", "HTTPS gecikmesi ölçülüyor…")
        case "download": return model.text("Measuring download…", "İndirme ölçülüyor…")
        case "upload": return model.text("Measuring upload…", "Yükleme ölçülüyor…")
        case "measurementError": return model.text("Measurement failed. Check Wi-Fi and try again.", "Ölçüm başarısız. Wi-Fi’yi kontrol edip tekrar dene.")
        case "ports": return model.text("Checking 16 TCP ports…", "16 TCP portu kontrol ediliyor…")
        case "credit": return model.text("A rewarded ad gives one extended check credit.", "Ödüllü reklam bir ayrıntılı kontrol kredisi verir.")
        default: return model.text("Ready to discover your network", "Ağını keşfetmeye hazır")
        }
    }
}

struct NetworkView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""
    @State private var exporting = false
    @State private var exportError = false
    var filtered: [Device] {
        model.devices.filter { query.isEmpty || $0.ip.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        List {
            Section {
                HStack {
                    Image("Brand").resizable().scaledToFit().frame(width: 42, height: 42).accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text("Lanpixo").font(.title2.bold())
                        Text(model.subnet).font(.subheadline.monospaced()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(model.devices.count)").font(.largeTitle.bold()).monospacedDigit()
                }
                StatusView()
                if model.busy { ProgressView(value: model.progress) }
                Button { model.busy ? model.stop() : model.scan() } label: {
                    Text(model.busy ? model.text("Stop", "Durdur") : model.text("Scan network", "Ağı tara"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }.buttonStyle(.borderedProminent)
            }
            Section(model.text("Devices", "Cihazlar")) {
                if model.stale {
                    Label(model.text("Saved results. Scan again before recognizing devices.", "Kaydedilmiş sonuçlar. Cihaz tanımadan önce tekrar tara."), systemImage: "clock")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if filtered.isEmpty {
                    ContentUnavailableView(model.text("No devices yet", "Henüz cihaz yok"), systemImage: "network", description: Text(model.text("Start a scan on your Wi-Fi network.", "Wi-Fi ağında bir tarama başlat.")))
                }
                ForEach(filtered) { device in
                    NavigationLink { DeviceView(ip: device.ip) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: device.isSelf ? "iphone" : "desktopcomputer").font(.title2).foregroundStyle(.tint).frame(width: 30)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(device.name.isEmpty ? model.text("Network device", "Ağ cihazı") : device.name).font(.headline)
                                Text(device.ip).font(.subheadline.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if device.known { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).accessibilityLabel(model.text("Recognized", "Tanıdık")) }
                        }.padding(.vertical, 5)
                    }
                }
            }
            Section {
                Text(model.text("Only scan networks you are authorized to use. Sleeping devices and isolated clients may not respond. A recognized mark is your note, not proof of security or permanent identity.", "Yalnızca yetkili olduğun ağları tara. Uyuyan cihazlar ve yalıtılmış istemciler yanıt vermeyebilir. Tanıdık işareti kişisel notundur; güvenlik veya kalıcı kimlik kanıtı değildir."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(model.text("Your network", "Ağın"))
        .searchable(text: $query, prompt: model.text("Name or IP address", "Ad veya IP adresi"))
        .toolbar {
            Button { exporting = true } label: { Image(systemName: "square.and.arrow.up") }
                .disabled(model.devices.isEmpty || model.busy).accessibilityLabel(model.text("Export CSV", "CSV dışa aktar"))
        }
        .fileExporter(isPresented: $exporting, document: CSVDocument(text: CSVReport.render(model.devices)), contentType: .commaSeparatedText, defaultFilename: "Lanpixo-devices") { result in
            if case .failure = result { exportError = true }
        }
        .alert(model.text("Export failed", "Dışa aktarma başarısız"), isPresented: $exportError) { Button("OK", role: .cancel) {} }
    }
}

struct DeviceView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var ads: AdService
    let ip: String
    @State private var name = ""
    var device: Device? { model.devices.first { $0.ip == ip } }
    var body: some View {
        Form {
            if let device {
                Section(model.text("Device", "Cihaz")) {
                    LabeledContent("IP", value: ip)
                    Text(device.evidence).font(.caption.monospaced())
                    TextField(model.text("Device name", "Cihaz adı"), text: $name)
                    Button { model.recognize(ip, name: name) } label: {
                        Label(model.text("I recognize this device", "Bu cihazı tanıyorum"), systemImage: "checkmark.seal")
                    }.disabled(model.busy || model.stale)
                    Text(model.text("Recognition applies to this scan observation. A new scan does not transfer trust using only an IP address.", "Tanıma bu tarama gözlemine aittir. Yeni tarama yalnızca IP adresine göre güven aktarmaz."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(model.text("TCP port check", "TCP port kontrolü")) {
                    Button(model.text("Check 16 ports", "16 portu kontrol et")) { model.ports(ip: ip) }.disabled(model.busy || model.stale)
                    StatusView()
                    ForEach(model.portResults.keys.sorted(), id: \.self) { port in
                        LabeledContent(String(port), value: portLabel(model.portResults[port]!))
                    }
                    Text(model.text("A timeout does not mean a port is closed. No passwords, exploits or device blocking are used.", "Zaman aşımı portun kapalı olduğu anlamına gelmez. Parola denemesi, açık sömürüsü veya cihaz engelleme yapılmaz."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(model.text("Extended TCP check", "Ayrıntılı TCP kontrolü")) {
                    Text(model.text("Credits: ", "Kredi: ") + String(ads.credits)).font(.headline)
                    Text(model.text("One completed rewarded ad earns one extended check on this device. Basic discovery and the 16-port check remain free. Cancelled checks refund the credit.", "Tamamlanan bir ödüllü reklam, bu cihazda bir ayrıntılı kontrol kredisi kazandırır. Temel keşif ve 16 port kontrolü ücretsizdir. Yarıda kalan kontrolde kredi iade edilir."))
                        .font(.footnote)
                    Button(model.text("Watch an ad · earn 1 credit", "Reklam izle · 1 kredi kazan")) { ads.watchReward() }
                        .disabled(model.busy || ads.busy || !ads.canRequest)
                    Button(model.text("Start extended check · 1 credit", "Ayrıntılı kontrol · 1 kredi")) { model.ports(ip: ip, advanced: true) }
                        .disabled(model.busy || model.stale || ads.busy || ads.credits == 0)
                    AdStatusView()
                }
            } else { Text(model.text("Run a new scan.", "Yeni bir tarama başlat.")) }
        }
        .navigationTitle(ip)
        .onAppear { name = device?.name ?? ""; model.portResults = [:] }
        .onDisappear { if model.status == "ports" { model.stop() } }
    }
    func portLabel(_ state: PortState) -> String {
        switch state {
        case .open: return model.text("Open", "Açık")
        case .closed: return model.text("Refused", "Reddedildi")
        case .noResponse: return model.text("No response", "Yanıt yok")
        }
    }
}

struct SpeedView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        List {
            Section {
                Label(model.text("Connection speed", "Bağlantı hızı"), systemImage: "speedometer").font(.title2.bold())
                Text(model.text("Clouvider Frankfurt · HTTPS · single connection", "Clouvider Frankfurt · HTTPS · tek bağlantı")).font(.caption).foregroundStyle(.secondary)
                Text(model.text("Uses approximately 5.3 MB plus protocol overhead. The server sees your internet IP. No cellular fallback. This short test estimates transfer speed, not your line’s maximum capacity.", "Protokol ek yükü dışında yaklaşık 5,3 MB kullanır. Sunucu internet IP adresini görür. Hücresel bağlantıya geçmez. Bu kısa test aktarım hızını tahmin eder; hattın azami kapasitesini ölçmez."))
                    .font(.footnote)
                Button { model.busy ? model.stop() : model.speed() } label: {
                    Text(model.busy ? model.text("Stop", "Durdur") : model.text("Start speed test", "Hız testini başlat"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }.buttonStyle(.borderedProminent)
                StatusView()
            }
            ForEach(model.speeds) { result in
                Section(result.date.formatted(date: .abbreviated, time: .shortened)) {
                    metric(model.text("Download", "İndirme"), result.download, "Mbps")
                    metric(model.text("Upload", "Yükleme"), result.upload, "Mbps")
                    metric(model.text("HTTPS latency", "HTTPS gecikmesi"), result.latency, "ms")
                }
            }
        }.navigationTitle(model.text("Speed test", "Hız testi"))
    }
    func metric(_ title: String, _ value: Double, _ unit: String) -> some View {
        LabeledContent(title) { Text(value, format: .number.precision(.fractionLength(1))) + Text(" " + unit) }
    }
}

struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var ads: AdService
    var body: some View {
        List {
            if model.history.isEmpty { ContentUnavailableView(model.text("No scans yet", "Henüz tarama yok"), systemImage: "clock") }
            ForEach(model.history) { record in
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.subnet).font(.headline.monospaced())
                    Text(record.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    Text("\(record.count) " + model.text("devices", "cihaz") + " · " + (record.complete ? model.text("Completed", "Tamamlandı") : model.text("Partial", "Kısmi")))
                }.padding(.vertical, 4)
            }
        }.navigationTitle(model.text("History", "Geçmiş"))
            .safeAreaInset(edge: .bottom) { AdBannerSlot(ads: ads) }
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var ads: AdService
    @State private var confirming = false
    var body: some View {
        Form {
            Section(model.text("Appearance", "Görünüm")) {
                Picker(model.text("Language", "Dil"), selection: $model.language) {
                    Text(model.text("System", "Sistem")).tag("system")
                    Text("Türkçe").tag("tr"); Text("English").tag("en")
                }
                Picker(model.text("Theme", "Tema"), selection: $model.theme) {
                    Text(model.text("System", "Sistem")).tag("system")
                    Text(model.text("Light", "Açık")).tag("light")
                    Text(model.text("Dark", "Koyu")).tag("dark")
                }
            }
            Section(model.text("Privacy and support", "Gizlilik ve destek")) {
                NavigationLink(model.text("Privacy information", "Gizlilik bilgileri")) { PrivacyView() }
                if ads.privacyRequired {
                    Button(model.text("Ad privacy choices", "Reklam gizlilik tercihleri")) { ads.privacyOptions() }
                        .disabled(model.busy || ads.busy)
                }
                Button(model.text("Refresh ad consent", "Reklam izinlerini yenile")) { ads.updateConsent() }
                    .disabled(model.busy || ads.busy)
                Text(model.text("Basic discovery is free. Optional rewarded ads earn extended-check credits.", "Temel keşif ücretsizdir. İsteğe bağlı ödüllü reklamlar ayrıntılı kontrol kredisi verir."))
                    .font(.footnote)
                if AdConfiguration.testMode { Text(model.text("Test ads", "Test reklamları")).font(.caption) }
                AdStatusView()
                Link(model.text("Contact EPX Studio", "EPX Studio ile iletişim"), destination: URL(string: "mailto:fatih.parak@hotmail.com")!)
                Link(model.text("Open iOS settings", "iOS ayarlarını aç"), destination: URL(string: UIApplication.openSettingsURLString)!)
                Button(model.text("Delete local records", "Yerel kayıtları sil"), role: .destructive) { confirming = true }.disabled(model.busy)
            }
            Section {
                Text("Lanpixo · EPX Studio\n\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")) · iOS").font(.footnote).foregroundStyle(.secondary)
                Text(model.text("Contains Google ads. No in-app purchases.", "Google reklamları içerir. Uygulama içi satın alma yoktur."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(model.text("Settings", "Ayarlar"))
        .safeAreaInset(edge: .bottom) { AdBannerSlot(ads: ads) }
        .confirmationDialog(model.text("Delete device records, scan history and speed results?", "Cihaz kayıtları, tarama geçmişi ve hız sonuçları silinsin mi?"), isPresented: $confirming, titleVisibility: .visible) {
            Button(model.text("Delete records", "Kayıtları sil"), role: .destructive) { model.clearRecords() }
        }
    }
}

struct AdStatusView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var ads: AdService
    var body: some View {
        if !ads.message.isEmpty { Text(message).font(.footnote).foregroundStyle(.secondary).accessibilityAddTraits(.updatesFrequently) }
    }
    var message: String {
        switch ads.message {
        case "loading": return model.text("Loading rewarded ad…", "Ödüllü reklam yükleniyor…")
        case "earned": return model.text("1 credit earned.", "1 kredi kazanıldı.")
        case "closed": return model.text("Ad closed before a reward. No credit used.", "Ödül kazanılmadan kapatıldı. Kredi harcanmadı.")
        case "consentError": return model.text("Ad privacy information is unavailable. Retry in Settings. Basic scanning still works.", "Reklam gizlilik bilgileri alınamadı. Ayarlar’dan tekrar dene. Temel tarama çalışmaya devam eder.")
        default: return model.text("Ad unavailable. Try later; no credit was used.", "Reklam kullanılamıyor. Sonra tekrar dene; kredi harcanmadı.")
        }
    }
}

struct PrivacyView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ScrollView {
            Text(model.text(
                "Lanpixo iOS 0.2.0 — 19 November 2026\n\nDeveloper: Fatih Parak / EPX Studio. Contact: fatih.parak@hotmail.com.\n\nLocal network discovery sends TCP requests and browses the declared Bonjour service types on your connected Wi-Fi. Responding IP addresses, advertised names and your recognition notes stay on this device in the app’s local preferences. Names are not verified identities. A new scan resets recognition rather than trusting an IP address. No MAC addresses or manufacturers are invented.\n\nThe optional speed test transfers about 5.3 MB, excluding protocol overhead, to fra.speedtest.clouvider.net over HTTPS. That service sees your public IP and normal request metadata, from which approximate location may be inferred. Device lists and notes are not sent to it. Its own connection logs follow that service’s retention practices.\n\nThis version uses Google Mobile Ads and Google consent messaging. There is no account or in-app purchase. Google may process IP-derived coarse location, app/device identifiers, ad interactions, usage and crash/performance/diagnostic data for advertising, measurement, analytics and fraud prevention. Requests are non-personalized; publisher first-party ID and OS location collection are disabled. No ATT permission or IDFA access is requested. Non-personalized ads still process data. Manage required ad privacy choices in Settings. Google policy: https://policies.google.com/privacy. Basic discovery and the 16-port check are free. An optional completed rewarded ad earns one extended TCP-check credit. Cancelling an extended check refunds the reserved credit; a failed or early-closed ad earns nothing. Credits remain when local scan records are cleared. Banners appear in History/Settings. Interstitials can appear when leaving completed results after at least three completed checks and three minutes, never during an active measurement or immediately after a rewarded ad. EPX Studio does not receive your scan inventory. Up to 20 scan summaries and 20 speed results are stored locally. Delete local records in Settings to erase these records; theme and language remain. Exported CSV files are only written where you choose in the Files picker and are not deleted by clearing app records. A cloud destination may transfer the export to that provider.\n\nLocal Network permission is required; camera, microphone, contacts and GPS are not requested. Operations stop in the background or when Wi-Fi changes. Local discovery packets are not end-to-end encrypted. Only scan networks you are authorized to use. Silent devices may be absent. This app does not block devices or certify network security.\n\nSupport email contains whatever you choose to send. Avoid sharing unnecessary sensitive network details. Device backups are managed by iOS and your backup provider and may include local app records. Manage those copies in the relevant system or provider settings.",
                "Lanpixo iOS 0.2.0 — 19 Kasım 2026\n\nGeliştirici: Fatih Parak / EPX Studio. İletişim: fatih.parak@hotmail.com.\n\nYerel ağ keşfi bağlı olduğun Wi-Fi’de TCP istekleri gönderir ve beyan edilen Bonjour servislerini arar. Yanıt veren IP adresleri, duyurulan adlar ve tanıdık notların bu cihazdaki uygulama tercihlerinde saklanır. Adlar doğrulanmış kimlik değildir. Yeni tarama IP’ye güvenmek yerine tanıdık işaretini sıfırlar. MAC veya üretici bilgisi uydurulmaz.\n\nİsteğe bağlı hız testi, protokol ek yükü dışında yaklaşık 5,3 MB veriyi HTTPS ile fra.speedtest.clouvider.net sunucusuna aktarır. Bu hizmet genel IP adresini ve normal istek bilgilerini görür; bunlardan yaklaşık konum çıkarılabilir. Cihaz listesi ve notlar gönderilmez. Dış hizmetin bağlantı kayıtları kendi saklama uygulamalarına tabidir.\n\nBu sürüm Google Mobile Ads ve Google izin mesajlaşmasını kullanır. Hesap veya uygulama içi satın alma yoktur. Google; IP’den yaklaşık konum, uygulama/cihaz tanımlayıcıları, reklam etkileşimleri, kullanım ve çökme/performans/tanı verilerini reklam, ölçüm, analiz ve sahtekarlık önleme için işleyebilir. İstekler kişiselleştirilmemiştir; yayıncı birinci taraf kimliği ve sistem konum toplaması kapalıdır. ATT izni veya IDFA erişimi istenmez. Kişiselleştirilmemiş reklamlar da veri işler. Gerekli reklam gizlilik tercihlerini Ayarlar’dan yönetebilirsin. Google politikası: https://policies.google.com/privacy. Temel keşif ve 16 port kontrolü ücretsizdir. İsteğe bağlı tamamlanan ödüllü reklam bir ayrıntılı TCP kontrol kredisi verir. İptal edilen kontrolde ayrılmış kredi iade edilir; başarısız veya erken kapatılan reklam kredi kazandırmaz. Yerel tarama kayıtları temizlenince krediler korunur. Banner Geçmiş/Ayarlar’da gösterilir. Geçiş reklamı en az üç tamamlanmış kontrol ve üç dakikadan sonra tamamlanan sonuçlardan çıkışta gösterilebilir; aktif ölçüm sırasında veya ödüllü reklamın hemen ardından gösterilmez. EPX Studio cihaz envanterini almaz. En fazla 20 tarama özeti ve 20 hız sonucu yerelde tutulur. Ayarlar’daki yerel kayıtları sil bunları temizler; dil ve tema korunur. CSV yalnız Dosyalar seçicisinde seçtiğin konuma yazılır; dışa aktarılan dosyalar yerel kayıtları temizleyince silinmez. Bulut konumu dosyayı ilgili sağlayıcıya aktarabilir.\n\nYerel Ağ izni gerekir; kamera, mikrofon, kişiler ve GPS izni istenmez. İşlemler arka planda veya Wi-Fi değişince durur. Yerel keşif paketleri uçtan uca şifreli değildir. Yalnızca yetkili olduğun ağları tara. Sessiz cihazlar bulunamayabilir. Uygulama cihaz engellemez veya ağ güvenliğini onaylamaz.\n\nDestek e-postası seçtiğin bilgileri içerir; gereksiz hassas ağ verilerini paylaşma. Cihaz yedekleri iOS ve yedekleme sağlayıcın tarafından yönetilir; yerel uygulama kayıtlarını içerebilir. Bu kopyaları ilgili sistem veya sağlayıcı ayarlarından yönetebilirsin."
            )).frame(maxWidth: 700, alignment: .leading).padding()
        }.navigationTitle(model.text("Privacy", "Gizlilik"))
    }
}
