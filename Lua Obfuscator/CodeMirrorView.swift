import SwiftUI
import WebKit

// MARK: - CodeMirror Editor mit ECHTEM Syntax-Highlighting
struct CodeMirrorView: NSViewRepresentable {
    @Binding var code: String
    var isEditable: Bool = true
    let title: String
    let icon: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        
        let html = getHTML()
        webView.loadHTMLString(html, baseURL: nil)
        
        context.coordinator.webView = webView
        context.coordinator.setupMessageHandler()
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastCode != code && context.coordinator.isEditorReady {
            context.coordinator.lastCode = code
            let escaped = code
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
            
            webView.evaluateJavaScript("editor.setValue(`\(escaped)`);")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: CodeMirrorView
        weak var webView: WKWebView?
        var lastCode: String = ""
        var isEditorReady: Bool = false
        
        init(_ parent: CodeMirrorView) {
            self.parent = parent
        }
        
        func setupMessageHandler() {
            webView?.configuration.userContentController.add(self, name: "codeChanged")
            webView?.configuration.userContentController.add(self, name: "editorReady")
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "codeChanged", let code = message.body as? String {
                DispatchQueue.main.async {
                    self.lastCode = code
                    self.parent.code = code
                }
            } else if message.name == "editorReady" {
                DispatchQueue.main.async {
                    self.isEditorReady = true
                    // Initial code setzen
                    let escaped = self.parent.code
                        .replacingOccurrences(of: "\\", with: "\\\\")
                        .replacingOccurrences(of: "`", with: "\\`")
                        .replacingOccurrences(of: "$", with: "\\$")
                        .replacingOccurrences(of: "\n", with: "\\n")
                        .replacingOccurrences(of: "\r", with: "\\r")
                    self.webView?.evaluateJavaScript("editor.setValue(`\(escaped)`);")
                }
            }
        }
    }
    
    private func getHTML() -> String {
        return """
        <!DOCTYPE html>
        <html dir="ltr">
        <head>
            <meta charset="UTF-8">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css">
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/material-darker.min.css">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    background: #1e1e2e; 
                    overflow: hidden; 
                    direction: ltr !important;
                    text-align: left !important;
                }
                .CodeMirror {
                    height: 100vh;
                    font-family: 'SF Mono', 'Monaco', 'Menlo', monospace;
                    font-size: 13px;
                    line-height: 1.6;
                    background: #1e1e2e !important;
                    direction: ltr !important;
                    text-align: left !important;
                }
                .CodeMirror-scroll {
                    direction: ltr !important;
                }
                .CodeMirror-gutters {
                    background: #181825 !important;
                    border-right: 1px solid #313244 !important;
                }
                .CodeMirror-linenumber {
                    color: #6c7086 !important;
                }
                .cm-s-material-darker .cm-keyword { color: #c792ea !important; }
                .cm-s-material-darker .cm-operator { color: #89ddff !important; }
                .cm-s-material-darker .cm-builtin { color: #ffcb6b !important; }
                .cm-s-material-darker .cm-number { color: #f78c6c !important; }
                .cm-s-material-darker .cm-def { color: #82aaff !important; }
                .cm-s-material-darker .cm-string { color: #c3e88d !important; }
                .cm-s-material-darker .cm-comment { color: #546e7a !important; font-style: italic; }
            </style>
        </head>
        <body>
            <textarea id="editor"></textarea>
            
            <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/lua/lua.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/matchbrackets.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/edit/closebrackets.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/selection/active-line.min.js"></script>
            
            <script>
                const editor = CodeMirror.fromTextArea(document.getElementById('editor'), {
                    mode: 'lua',
                    theme: 'material-darker',
                    lineNumbers: true,
                    matchBrackets: true,
                    autoCloseBrackets: true,
                    styleActiveLine: true,
                    indentUnit: 4,
                    tabSize: 4,
                    indentWithTabs: false,
                    lineWrapping: false,
                    direction: 'ltr',
                    rtlMoveVisually: false
                });
                
                editor.on('change', function(cm) {
                    window.webkit.messageHandlers.codeChanged.postMessage(cm.getValue());
                });
                
                window.webkit.messageHandlers.editorReady.postMessage('ready');
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - EditorView mit LIQUID BUTTONS
struct EditorView: View {
    let title: String
    let icon: String
    @Binding var code: String
    var isEditable: Bool = true
    
    var onOpen: (() -> Void)?
    var onPaste: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onClear: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit LIQUID Buttons
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    if let onOpen {
                        LiquidButton(icon: "folder", tooltip: "Open", action: onOpen)
                    }
                    if let onPaste {
                        LiquidButton(icon: "doc.on.clipboard", tooltip: "Paste", action: onPaste)
                    }
                    if let onCopy {
                        LiquidButton(icon: "doc.on.doc", tooltip: "Copy", action: onCopy)
                    }
                    if let onSave {
                        LiquidButton(icon: "arrow.down.doc", tooltip: "Save", action: onSave)
                    }
                    if let onClear {
                        LiquidButton(icon: "trash", tooltip: "Clear", action: onClear, isDestructive: true)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            
            // CodeMirror Editor
            CodeMirrorView(
                code: $code,
                isEditable: isEditable,
                title: title,
                icon: icon
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary, lineWidth: 1))
        .padding(12)
    }
}

// MARK: - LIQUID BUTTON (Glassmorphism Style)
struct LiquidButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isHovered
                        ? (isDestructive ? Color.red : Color.white)
                        : Color.primary.opacity(0.6)
                )
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(
                            isHovered
                                ? (isDestructive
                                    ? AnyShapeStyle(Material.ultraThinMaterial)
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      )))
                                : AnyShapeStyle(Color.clear)
                        )
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .opacity(isHovered ? 0 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(
                            isHovered
                                ? (isDestructive ? Color.red.opacity(0.5) : Color.white.opacity(0.2))
                                : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isHovered
                        ? (isDestructive ? Color.red.opacity(0.3) : Color.blue.opacity(0.3))
                        : Color.clear,
                    radius: 8, x: 0, y: 2
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
    }
}
