import Foundation

class ObfuscatorService {
    static let shared = ObfuscatorService()
    private init() {}
    
    struct ObfuscationResult {
        let code: String
        let output: String
    }
    
    func obfuscate(code: String, preset: String, flatten: Bool, lua52: Bool, antiDebug: Bool) async throws -> ObfuscationResult {
        
        print("\n" + String(repeating: "=", count: 50))
        print("🚀 STARTING OBFUSCATION")
        print(String(repeating: "=", count: 50))
        
        // 1. LuaJIT finden (Zuerst im Bundle!)
        guard let luaPath = findLua() else {
            throw NSError(domain: "Obfuscator", code: 1, userInfo: [NSLocalizedDescriptionKey: "LuaJIT not found!"])
        }
        print("✅ LuaJIT: \(luaPath)")
        
        // 2. Prometheus-Pfad
        let prometheusPath = findPrometheusPath()
        print("✅ Prometheus: \(prometheusPath)")
        
        // 3. cli.lua Pfad
        let cliPath = prometheusPath + "/cli.lua"
        if !FileManager.default.fileExists(atPath: cliPath) {
            throw NSError(domain: "Obfuscator", code: 2, userInfo: [NSLocalizedDescriptionKey: "cli.lua not found!"])
        }
        
        // 4. Temporäre Dateien
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("input_\(UUID().uuidString).lua")
        let outputFile = inputFile.deletingPathExtension().appendingPathExtension("obfuscated.lua")
        
        try code.write(to: inputFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: outputFile)
        }
        
        // 5. Befehl
        var arguments = [cliPath, "--preset", preset]
        if flatten { arguments.append("--flatten") }
        if lua52 { arguments.append("--lua52") }
        arguments.append(inputFile.path)
        
        print("⏳ Running Prometheus...")
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: luaPath)
        task.arguments = arguments
        task.currentDirectoryURL = URL(fileURLWithPath: prometheusPath)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        let startTime = Date()
        try task.run()
        task.waitUntilExit()
        let duration = Date().timeIntervalSince(startTime)
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        let combinedOutput = output + error
        
        print("⏱️ Duration: \(String(format: "%.2f", duration))s")
        
        // 6. Ergebnis lesen
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let obfuscatedCode = try String(contentsOf: outputFile, encoding: .utf8)
            var finalCode = obfuscatedCode
            if antiDebug && !finalCode.hasPrefix("(function()") {
                finalCode = "(function() \(finalCode))()"
            }
            print("✅ OBFUSCATION SUCCESSFUL!")
            print(String(repeating: "=", count: 50) + "\n")
            return ObfuscationResult(code: finalCode, output: combinedOutput)
        }
        
        throw NSError(domain: "Obfuscator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Obfuscation failed. Output:\n\(combinedOutput)"])
    }
    
    private func findLua() -> String? {
        // 1. ZUERST im Bundle (eingebettet)
        if let bundledPath = Bundle.main.path(forResource: "luajit", ofType: "") {
            print("   ✅ Using bundled LuaJIT")
            try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bundledPath)
            return bundledPath
        }
        
        // 2. Fallback: System
        let paths = ["/opt/homebrew/bin/luajit", "/usr/local/bin/luajit", "/usr/bin/luajit"]
        for path in paths {
            if FileManager.default.isReadableFile(atPath: path) {
                print("   ✅ Using system LuaJIT: \(path)")
                return path
            }
        }
        
        print("   ❌ LuaJIT not found!")
        return nil
    }
    
    private func findPrometheusPath() -> String {
        // 1. Im Bundle
        if let resourcePath = Bundle.main.resourcePath {
            let path = resourcePath + "/Prometheus"
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // 2. Fallback
        return "/Users/ZW/Library/Containers/lzhenwei.Lua-Obfuscator/Data/Prometheus"
    }
}
