import Cocoa
import Vision

let skip = Set(["Window Server", "Dock", "SystemUIServer", "Control Center", "Notification Center", "Spotlight"])

func getWindows() -> [(id: UInt32, app: String, title: String)] {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    return list.compactMap { w in
        guard let id = w[kCGWindowNumber as String] as? UInt32,
              let app = w[kCGWindowOwnerName as String] as? String,
              let layer = w[kCGWindowLayer as String] as? Int, layer == 0, !skip.contains(app),
              let b = w[kCGWindowBounds as String] as? [String: Any],
              (b["Width"] as? Int ?? 0) > 50, (b["Height"] as? Int ?? 0) > 50
        else { return nil }
        return (id, app, w[kCGWindowName as String] as? String ?? "")
    }
}

func find(_ q: String) -> (id: UInt32, app: String, title: String)? {
    let q = q.lowercased()
    return getWindows().first { $0.app.lowercased().contains(q) || $0.title.lowercased().contains(q) }
}

func capture(_ id: UInt32, to path: String) -> Bool {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    p.arguments = ["-x", "-l\(id)", path]
    p.standardOutput = FileHandle.nullDevice
    p.standardError = FileHandle.nullDevice
    try? p.run(); p.waitUntilExit()
    return FileManager.default.fileExists(atPath: path)
}

func ocr(_ path: String) -> String {
    guard let img = NSImage(contentsOfFile: path)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return "" }
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate
    try? VNImageRequestHandler(cgImage: img, options: [:]).perform([req])
    return (req.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

func json(_ dict: [String: Any]) {
    if let d = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
       let s = String(data: d, encoding: .utf8) { print(s) }
}

@main struct Look {
    static func main() {
        var args = Array(CommandLine.arguments.dropFirst())
        let asJson = isatty(STDOUT_FILENO) == 0 || args.contains("--json")
        args.removeAll { $0 == "--json" }
        
        if args.first == "-h" || args.first == "--help" {
            print("look [app|list] - capture window content\n  look chrome    OCR from Chrome\n  look list      list windows\n  look --json    JSON output")
            return
        }
        
        if args.first == "list" {
            let wins = getWindows()
            if asJson { json(["windows": wins.map { ["id": $0.id, "app": $0.app, "title": $0.title] }]) }
            else { for w in wins { print("\(w.id)\t\(w.app)\t\(w.title)") } }
            return
        }
        
        let query = args.first ?? NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
        guard let win = find(query) else { fputs("error: window not found\n", stderr); exit(1) }
        
        let path = "/tmp/look-\(win.app.lowercased().replacingOccurrences(of: " ", with: "-")).png"
        guard capture(win.id, to: path) else { fputs("error: capture failed\n", stderr); exit(1) }
        
        let text = ocr(path)
        if asJson { json(["app": win.app, "title": win.title, "image": path, "text": text]) }
        else { print(text) }
    }
}
