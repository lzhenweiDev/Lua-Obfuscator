import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputCode: String = """
-- Example Lua Code
-- Press ⌘↵ to obfuscate

local function greet(name)
    print("Hello, " .. name .. "!")
end

local function calculate(a, b)
    local result = a + b
    return result * 2
end

greet("Developer")
print("Result:", calculate(10, 42))
"""
    @State private var outputCode: String = ""
    @State private var isProcessing: Bool = false
    @State private var selectedPreset: Preset = .medium
    @State private var flattenEnabled: Bool = false
    @State private var lua52Enabled: Bool = false
    @State private var antiDebugEnabled: Bool = false
    @State private var consoleOutput: String = ""
    @State private var statusMessage: String = "Ready"
    @State private var statusType: StatusType = .info
    @State private var showFileImporter: Bool = false
    @State private var showFileExporter: Bool = false
    @State private var layoutMode: LayoutMode = .horizontal
    @State private var showConsole: Bool = true
    @State private var originalSize: Int = 0
    @State private var obfuscatedSize: Int = 0
    @State private var duration: Double = 0
    
    enum Preset: String, CaseIterable {
        case minify = "Minify"
        case weak = "Weak"
        case medium = "Medium"
        case strong = "Strong"
        case maximum = "Maximum"
        
        var icon: String {
            switch self {
            case .minify: return "arrow.down.circle"
            case .weak: return "lock.open"
            case .medium: return "lock"
            case .strong: return "lock.shield"
            case .maximum: return "shield"
            }
        }
    }
    
    enum StatusType {
        case info, success, warning, error
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
    
    enum LayoutMode: String, CaseIterable {
        case horizontal = "Horizontal"
        case vertical = "Vertical"
    }
    
    var body: some View {
        HSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Protection Level", systemImage: "shield")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                    
                    ForEach(Preset.allCases, id: \.self) { preset in
                        PresetButton(
                            preset: preset,
                            isSelected: selectedPreset == preset,
                            action: { selectedPreset = preset }
                        )
                    }
                }
                .padding(.horizontal, 8)
                
                Divider().padding(.vertical, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Options", systemImage: "slider.horizontal.below.rectangle")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                    
                    Toggle(isOn: $flattenEnabled) {
                        Label("Flatten", systemImage: "arrow.triangle.merge")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    
                    Toggle(isOn: $lua52Enabled) {
                        Label("Lua 5.2", systemImage: "archivebox")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    
                    Toggle(isOn: $antiDebugEnabled) {
                        Label("Anti-Debug", systemImage: "ant")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                }
                
                Divider().padding(.vertical, 16)
                
                if originalSize > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Statistics", systemImage: "chart.bar")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                        
                        StatRow(label: "Original", value: formatBytes(originalSize))
                        StatRow(label: "Obfuscated", value: formatBytes(obfuscatedSize))
                        StatRow(label: "Duration", value: String(format: "%.2fs", duration))
                    }
                }
                
                Spacer()
            }
            .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)
            .background(.ultraThinMaterial)
            
            // Main Content
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    Button(action: { layoutMode = layoutMode == .horizontal ? .vertical : .horizontal }) {
                        Image(systemName: layoutMode == .horizontal ? "square.split.1x2" : "square.split.2x1")
                    }
                    .help("Toggle Layout")
                    
                    Button(action: { showConsole.toggle() }) {
                        Image(systemName: showConsole ? "apple.terminal.fill" : "apple.terminal")
                    }
                    .help("Toggle Console")
                    
                    Button(action: clearAll) {
                        Image(systemName: "trash")
                    }
                    .help("Clear All")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
                
                if layoutMode == .horizontal {
                    HStack(spacing: 0) {
                        EditorView(
                            title: "Source Code",
                            icon: "doc",
                            code: $inputCode,
                            isEditable: true,
                            onOpen: { showFileImporter = true },
                            onPaste: { pasteFromClipboard(into: \.inputCode) },
                            onClear: { inputCode = "" }
                        )
                        
                        Divider()
                        
                        EditorView(
                            title: "Obfuscated Code",
                            icon: "lock.doc",
                            code: $outputCode,
                            isEditable: false,
                            onCopy: { copyToClipboard(outputCode) },
                            onSave: { showFileExporter = true },
                            onClear: { outputCode = "" }
                        )
                    }
                } else {
                    VStack(spacing: 0) {
                        EditorView(
                            title: "Source Code",
                            icon: "doc",
                            code: $inputCode,
                            isEditable: true,
                            onOpen: { showFileImporter = true },
                            onPaste: { pasteFromClipboard(into: \.inputCode) },
                            onClear: { inputCode = "" }
                        )
                        
                        Divider()
                        
                        EditorView(
                            title: "Obfuscated Code",
                            icon: "lock.doc",
                            code: $outputCode,
                            isEditable: false,
                            onCopy: { copyToClipboard(outputCode) },
                            onSave: { showFileExporter = true },
                            onClear: { outputCode = "" }
                        )
                    }
                }
                
                if showConsole {
                    ConsoleView(output: consoleOutput)
                        .frame(height: 150)
                        .background(Color.black.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(12)
                }
                
                HStack {
                    Image(systemName: statusType.icon)
                        .foregroundStyle(statusType.color)
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: performObfuscation) {
                    Label("Obfuscate", systemImage: "play.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || inputCode.isEmpty)
                .padding(20)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.plainText, .sourceCode],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first,
                      let content = try? String(contentsOf: url, encoding: .utf8) else { return }
                inputCode = content
                statusMessage = "Loaded: \(url.lastPathComponent)"
                statusType = .success
            case .failure(let error):
                statusMessage = error.localizedDescription
                statusType = .error
            }
        }
        .fileExporter(
            isPresented: $showFileExporter,
            document: TextDocument(text: outputCode),
            contentType: .plainText,
            defaultFilename: "obfuscated_\(Date().formatted(.iso8601)).lua"
        ) { _ in }
    }
    
    func performObfuscation() {
        isProcessing = true
        statusMessage = "Obfuscating..."
        statusType = .info
        consoleOutput = ""
        
        Task {
            let startTime = Date()
            
            do {
                let result = try await ObfuscatorService.shared.obfuscate(
                    code: inputCode,
                    preset: selectedPreset.rawValue,
                    flatten: flattenEnabled,
                    lua52: lua52Enabled,
                    antiDebug: antiDebugEnabled
                )
                
                let durationValue = Date().timeIntervalSince(startTime)
                
                await MainActor.run {
                    outputCode = result.code
                    consoleOutput = result.output
                    originalSize = inputCode.utf8.count
                    obfuscatedSize = result.code.utf8.count
                    duration = durationValue
                    statusMessage = "Obfuscation complete!"
                    statusType = .success
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    consoleOutput = "Error: \(error.localizedDescription)"
                    statusMessage = "Obfuscation failed"
                    statusType = .error
                    isProcessing = false
                }
            }
        }
    }
    
    func pasteFromClipboard(into keyPath: ReferenceWritableKeyPath<ContentView, String>) {
        guard let content = NSPasteboard.general.string(forType: .string) else { return }
        self[keyPath: keyPath] = content
        statusMessage = "Pasted from clipboard"
        statusType = .success
    }
    
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        statusMessage = "Copied to clipboard"
        statusType = .success
    }
    
    func clearAll() {
        inputCode = ""
        outputCode = ""
        consoleOutput = ""
        originalSize = 0
        obfuscatedSize = 0
        duration = 0
        statusMessage = "Cleared"
        statusType = .info
    }
    
    func formatBytes(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0
        return String(format: "%.2f KB", kb)
    }
}
