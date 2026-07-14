const express = require('express');
const cors = require('cors');
const { exec } = require('child_process');
const fs = require('fs').promises;
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 5000;

// ===== KONFIGURATION =====
// CORS für GitHub Pages erlauben
const allowedOrigins = [
    'https://lzhenweidev.github.io/Lua-Obfuscator/',  // Deine GitHub Pages URL
    'http://localhost:5500',           // Für lokale Tests
    'http://127.0.0.1:5500'
];

app.use(cors({
    origin: function (origin, callback) {
        // Erlaube Anfragen ohne Origin (z.B. Postman)
        if (!origin) return callback(null, true);
        if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
            callback(null, true);
        } else {
            callback(new Error('CORS nicht erlaubt für: ' + origin));
        }
    },
    methods: ['POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type']
}));

app.use(express.json({ limit: '10mb' }));

// ===== PROMETHEUS KONFIGURATION =====
// Render verwendet den Prometheus-Ordner aus dem Repository
const PROMETHEUS_PATH = path.join(__dirname, 'prometheus', 'lua');

// ===== OBFUSCATION ENDPOINT =====
app.post('/obfuscate', async (req, res) => {
    const { code, minify = false, encrypt = false, rename = true } = req.body;
    
    // Validierung
    if (!code || typeof code !== 'string' || code.length > 500000) {
        return res.status(400).json({
            success: false,
            error: 'Ungültiger Code (max. 500KB)'
        });
    }
    
    // Sicherheitscheck
    const dangerous = ['os.execute', 'io.popen', 'dofile', 'loadstring', 'debug.'];
    for (const term of dangerous) {
        if (code.includes(term)) {
            return res.status(400).json({
                success: false,
                error: `Sicherheitsverletzung: ${term} ist nicht erlaubt`
            });
        }
    }
    
    let tempFile = null;
    
    try {
        // Temporäre Datei erstellen
        const tempDir = os.tmpdir();
        const fileName = `lua_${Date.now()}_${Math.random().toString(36).substring(7)}.lua`;
        tempFile = path.join(tempDir, fileName);
        await fs.writeFile(tempFile, code);
        
        // Obfuscation Script
        const script = `
            local code = io.open("${tempFile}", "r"):read("*a")
            
            local function obfuscate(input)
                -- 1. Kommentare entfernen (optional)
                ${true ? 'input = input:gsub("%-%-[^\\n]*", "")' : ''}
                
                -- 2. Variablen umbenennen (optional)
                ${rename ? `
                local vars = {}
                local counter = 0
                local reserved = {
                    "and","break","do","else","elseif","end","false",
                    "for","function","goto","if","in","local","nil",
                    "not","or","repeat","return","then","true","until",
                    "while","print","require","dofile","loadstring"
                }
                local function isReserved(w)
                    for _,v in ipairs(reserved) do if v == w then return true end end
                    return false
                end
                input = input:gsub("([%w_]+)", function(word)
                    if not isReserved(word) and word:match("^[a-zA-Z_][%w_]*$") then
                        if not vars[word] then
                            counter = counter + 1
                            -- Generiere kurze Namen
                            local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                            local name = ""
                            local num = counter
                            repeat
                                name = chars:sub(num % 52 + 1, num % 52 + 1) .. name
                                num = math.floor(num / 52)
                            until num == 0
                            vars[word] = "_" .. name
                        end
                        return vars[word]
                    end
                    return word
                end)
                ` : ''}
                
                -- 3. String Encryption (optional)
                ${encrypt ? `
                input = input:gsub('"([^"]*)"', function(str)
                    if #str > 0 then
                        local bytes = {}
                        for i = 1, #str do
                            bytes[i] = string.byte(str, i)
                        end
                        return 'string.char(' .. table.concat(bytes, ",") .. ')'
                    end
                    return '""'
                end)
                ` : ''}
                
                -- 4. Minification (optional)
                ${minify ? `
                input = input:gsub("%s+", " ")
                input = input:gsub("^%s+", "")
                input = input:gsub("%s+$", "")
                ` : ''}
                
                return input
            end
            
            local result = obfuscate(code)
            io.write(result)
        `;
        
        // Prometheus ausführen
        const result = await new Promise((resolve, reject) => {
            // Prüfe ob Prometheus existiert
            if (!fs.existsSync(PROMETHEUS_PATH)) {
                reject(new Error(`Prometheus nicht gefunden: ${PROMETHEUS_PATH}`));
                return;
            }
            
            exec(`"${PROMETHEUS_PATH}" -e "${script}"`, {
                timeout: 10000,
                maxBuffer: 10 * 1024 * 1024
            }, (error, stdout, stderr) => {
                if (error) {
                    reject(new Error(stderr || error.message));
                } else {
                    resolve(stdout);
                }
            });
        });
        
        // Aufräumen
        await fs.unlink(tempFile);
        
        // Ergebnis senden
        res.json({
            success: true,
            obfuscated: result || '-- Code erfolgreich obfuscated',
            stats: {
                originalSize: code.length,
                obfuscatedSize: result.length,
                compression: ((1 - (result.length / code.length)) * 100).toFixed(2) + '%'
            }
        });
        
    } catch (error) {
        // Aufräumen
        if (tempFile) {
            try { await fs.unlink(tempFile); } catch (e) {}
        }
        
        console.error('Obfuscation Fehler:', error);
        
        res.status(500).json({
            success: false,
            error: error.message || 'Obfuscation fehlgeschlagen'
        });
    }
});

// ===== HEALTH CHECK =====
app.get('/health', (req, res) => {
    res.json({
        status: 'online',
        timestamp: new Date().toISOString(),
        prometheus: fs.existsSync(PROMETHEUS_PATH) ? 'found' : 'not found'
    });
});

// ===== SERVER START =====
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server läuft auf Port ${PORT}`);
    console.log(`📁 Prometheus Pfad: ${PROMETHEUS_PATH}`);
    console.log(`✅ Prometheus ${fs.existsSync(PROMETHEUS_PATH) ? 'gefunden' : 'NICHT gefunden!'}`);
});
