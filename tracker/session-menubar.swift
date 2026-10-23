// Menubar: heutige Anwesenheit (Gesamtzeit, Sessions, Start) und Sprung ins Dashboard.
// Build: swiftc -O -o ~/.local/bin/session-menubar session-menubar.swift
import AppKit

// Zahlen kommen aus session-report, damit Menubar, CLI und Dashboard dieselbe Block-Logik nutzen.
// Liegt neben diesem Binary (install.sh: ~/.local/bin), so lässt sich ein Checkout testen, ohne die Installation anzufassen.
let report = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().deletingLastPathComponent().appendingPathComponent("session-report").path
let dashboard = URL(string: "http://127.0.0.1:8765")!

func heute() -> [String: Any]? {
    let p = Process(), out = Pipe()
    p.executableURL = URL(fileURLWithPath: report)
    p.arguments = ["--heute", "--json"]
    p.standardOutput = out
    guard (try? p.run()) != nil else { return nil }
    let data = out.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return p.terminationStatus == 0 ? (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] : nil
}

func dauer(_ s: Int) -> String { String(format: "%d:%02d h", s / 3600, s % 3600 / 60) }

let uhr = DateFormatter()
uhr.dateFormat = "HH:mm"
func zeit(_ v: Any?) -> String {
    guard let t = v as? Double else { return "–" }
    return uhr.string(from: Date(timeIntervalSince1970: t))
}

final class App: NSObject, NSMenuDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let zeilen = (0..<3).map { _ in NSMenuItem(title: "", action: nil, keyEquivalent: "") }

    override init() {
        super.init()
        let menu = NSMenu()
        menu.autoenablesItems = false
        zeilen.forEach { $0.isEnabled = false; menu.addItem($0) }
        menu.addItem(.separator())
        let open = NSMenuItem(title: "Dashboard öffnen", action: #selector(oeffnen), keyEquivalent: "d")
        open.target = self
        menu.addItem(open)
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.delegate = self
        item.menu = menu
        aktualisieren()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.aktualisieren() }
    }

    func menuWillOpen(_ menu: NSMenu) { aktualisieren() }

    func aktualisieren() {
        guard let h = heute() else {
            item.button?.title = "– h"
            zeigen(["session-report nicht erreichbar", "", ""])
            return
        }
        let gesamt = dauer(h["gesamt_s"] as? Int ?? 0)
        item.button?.title = gesamt
        // Kein "Ende": wer das Menü sieht, ist eingeloggt, der letzte Block läuft also immer noch.
        zeigen(["Heute: \(gesamt)", "Sessions: \(h["sessions"] as? Int ?? 0)", "Start: \(zeit(h["start"]))"])
    }

    // Deaktivierte Zeilen zeichnet AppKit blass; Textfarbe explizit, damit die Werte lesbar bleiben.
    func zeigen(_ texte: [String]) {
        for (z, t) in zip(zeilen, texte) {
            z.attributedTitle = NSAttributedString(string: t, attributes: [.foregroundColor: NSColor.labelColor, .font: NSFont.menuFont(ofSize: 0)])
        }
    }

    // Dashboard läuft per LaunchAgent; ist es nicht erreichbar, erst den Agent anstoßen, dann öffnen.
    @objc func oeffnen() {
        URLSession.shared.dataTask(with: dashboard) { _, resp, _ in
            var warten = 0.0
            if resp == nil {
                let k = Process()
                k.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                k.arguments = ["kickstart", "gui/\(getuid())/dev.hpmartini.session-dashboard"]
                try? k.run()
                k.waitUntilExit()
                warten = 2  // shortcut: feste Startzeit statt Polling; reicht für den Python-Server, sonst Seite neu laden
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + warten) { NSWorkspace.shared.open(dashboard) }
        }.resume()
    }
}

NSApplication.shared.setActivationPolicy(.accessory)
let app = App()
NSApp.run()
