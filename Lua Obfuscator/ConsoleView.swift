import SwiftUI
import WebKit

// MARK: - Console View mit CodeMirror Styling
struct ConsoleView: View {
    let output: String
    
    var body: some View {
        ConsoleWebView(output: output)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.06, green: 0.08, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(12)
    }
}

// MARK: - WebView für Console (mit ANSI-Farben Unterstützung)
struct ConsoleWebView: NSViewRepresentable {
    let output: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        
        let html = getConsoleHTML()
        webView.loadHTMLString(html, baseURL: nil)
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastOutput != output {
            context.coordinator.lastOutput = output
            
            let escaped = output
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "$", with: "\\$")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
            
            let js = """
            (function() {
                const consoleEl = document.getElementById('console-content');
                consoleEl.innerHTML = '';
                const lines = `\(escaped)`.split('\\n');
                lines.forEach(line => {
                    const lineEl = document.createElement('div');
                    lineEl.className = 'console-line';
                    lineEl.textContent = line;
                    consoleEl.appendChild(lineEl);
                });
                window.scrollTo(0, document.body.scrollHeight);
            })();
            """
            
            webView.evaluateJavaScript(js)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var webView: WKWebView?
        var lastOutput: String = ""
    }
    
    private func getConsoleHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    background: #0d0d15;
                    color: #cdd6f4;
                    font-family: 'SF Mono', 'Monaco', 'Menlo', 'Courier New', monospace;
                    font-size: 11px;
                    line-height: 1.6;
                    padding: 12px 16px;
                    min-height: 100%;
                    overflow-y: auto;
                }
                
                #console-content {
                    display: flex;
                    flex-direction: column;
                }
                
                .console-line {
                    white-space: pre-wrap;
                    word-break: break-all;
                    padding: 1px 0;
                }
                
                /* ANSI-Farben */
                .console-line:has(.error) { color: #f38ba8; }
                .console-line:has(.warning) { color: #f9e2af; }
                .console-line:has(.success) { color: #a6e3a1; }
                .console-line:has(.info) { color: #89b4fa; }
                
                /* Scrollbar Styling */
                ::-webkit-scrollbar {
                    width: 8px;
                    height: 8px;
                }
                
                ::-webkit-scrollbar-track {
                    background: #181825;
                    border-radius: 4px;
                }
                
                ::-webkit-scrollbar-thumb {
                    background: #313244;
                    border-radius: 4px;
                }
                
                ::-webkit-scrollbar-thumb:hover {
                    background: #45475a;
                }
            </style>
        </head>
        <body>
            <div id="console-content">
                \(generateInitialContent())
            </div>
            
            <script>
                function addLine(text) {
                    const lineEl = document.createElement('div');
                    lineEl.className = 'console-line';
                    lineEl.textContent = text;
                    document.getElementById('console-content').appendChild(lineEl);
                    window.scrollTo(0, document.body.scrollHeight);
                }
                
                function clearConsole() {
                    document.getElementById('console-content').innerHTML = '';
                }
                
                // Auto-scroll to bottom when content changes
                const observer = new MutationObserver(() => {
                    window.scrollTo(0, document.body.scrollHeight);
                });
                observer.observe(document.getElementById('console-content'), { 
                    childList: true, 
                    subtree: true 
                });
            </script>
        </body>
        </html>
        """
    }
    
    private func generateInitialContent() -> String {
        if output.isEmpty {
            return "<div class='console-line' style='color: #6c7086;'>Ready</div>"
        }
        
        return output
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                var lineStr = String(line)
                
                // Einfaches ANSI-Farb-Highlighting
                if lineStr.contains("❌") || lineStr.contains("Error") || lineStr.contains("error") {
                    return "<div class='console-line' style='color: #f38ba8;'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                } else if lineStr.contains("⚠️") || lineStr.contains("Warning") || lineStr.contains("warning") {
                    return "<div class='console-line' style='color: #f9e2af;'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                } else if lineStr.contains("✅") || lineStr.contains("Success") || lineStr.contains("success") {
                    return "<div class='console-line' style='color: #a6e3a1;'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                } else if lineStr.contains("🚀") || lineStr.contains("📁") || lineStr.contains("⚙️") {
                    return "<div class='console-line' style='color: #89b4fa;'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                } else if lineStr.contains("═") || lineStr.contains("─") {
                    return "<div class='console-line' style='color: #6c7086;'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                } else {
                    return "<div class='console-line'>\(lineStr.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</div>"
                }
            }
            .joined(separator: "")
    }
}
