// ===== KONFIGURATION =====
// WICHTIG: Hier muss die URL deines Render-Backends rein!
// Nach dem Deploy auf Render: https://dein-service.onrender.com
const API_URL = 'https://lua-obfuscator-backend.onrender.com/obfuscate';
// Für lokale Tests: const API_URL = 'http://localhost:5000/obfuscate';

// ===== BEISPIELE =====
const examples = {
    basic: `-- Einfache Funktion
local function greet(name)
    print('Hello, ' .. name .. '!')
    return 'Welcome, ' .. name
end

local result = greet('World')
print(result)`,

    table: `-- Table Operations
local data = {
    name = 'Lua',
    version = '5.4',
    features = {'fast', 'lightweight', 'powerful'}
}

for key, value in pairs(data) do
    print(key .. ': ' .. tostring(value))
end`,

    class: `-- Klassensimulation
local Person = {}
Person.__index = Person

function Person:new(name, age)
    local obj = {name = name, age = age}
    setmetatable(obj, Person)
    return obj
end

function Person:introduce()
    print('Hi, I am ' .. self.name)
end

local john = Person:new('John', 25)
john:introduce()`
};

// ===== FUNKTIONEN =====
function loadExample(name) {
    const input = document.getElementById('luaInput');
    input.value = examples[name] || '';
    updateCharCount();
    clearStatus();
}

function updateCharCount() {
    const input = document.getElementById('luaInput');
    document.getElementById('charCount').textContent = input.value.length + ' Zeichen';
}

function showStatus(message, type = 'info') {
    const status = document.getElementById('status');
    status.textContent = message;
    status.className = 'status ' + type;
    status.style.display = 'block';
}

function clearStatus() {
    document.getElementById('status').style.display = 'none';
}

async function obfuscateCode() {
    const input = document.getElementById('luaInput');
    const output = document.getElementById('luaOutput');
    const btn = document.getElementById('obfuscateBtn');
    const stats = document.getElementById('stats');
    
    const code = input.value.trim();
    if (!code) {
        showStatus('❌ Bitte Lua Code eingeben!', 'error');
        return;
    }
    
    // Button deaktivieren
    btn.disabled = true;
    btn.textContent = '⏳ Obfuscating...';
    showStatus('⏳ Sende Code an Render Backend...', 'info');
    
    const options = {
        code: code,
        minify: document.getElementById('minify').checked,
        encrypt: document.getElementById('encrypt').checked,
        rename: document.getElementById('rename').checked
    };
    
    try {
        // Anfrage an Render Backend
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(options)
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.error || 'Serverfehler');
        }
        
        const data = await response.json();
        
        if (data.success) {
            output.value = data.obfuscated;
            showStatus('✅ Code erfolgreich obfuscated!', 'success');
            
            // Stats anzeigen
            if (data.stats) {
                document.getElementById('origSize').textContent = data.stats.originalSize;
                document.getElementById('obfSize').textContent = data.stats.obfuscatedSize;
                document.getElementById('compression').textContent = data.stats.compression;
                stats.style.display = 'flex';
            }
        } else {
            showStatus('❌ ' + (data.error || 'Obfuscation fehlgeschlagen'), 'error');
        }
    } catch (error) {
        console.error('Fehler:', error);
        showStatus('❌ Fehler: ' + error.message, 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = '⚡ Obfuscate (Ctrl+Enter)';
    }
}

function copyOutput() {
    const output = document.getElementById('luaOutput');
    if (!output.value) {
        showStatus('❌ Kein Code zum Kopieren', 'error');
        return;
    }
    
    navigator.clipboard.writeText(output.value).then(() => {
        showStatus('📋 In Zwischenablage kopiert!', 'success');
    }).catch(() => {
        output.select();
        document.execCommand('copy');
        showStatus('📋 Kopiert!', 'success');
    });
}

function downloadOutput() {
    const output = document.getElementById('luaOutput');
    if (!output.value) {
        showStatus('❌ Kein Code zum Download', 'error');
        return;
    }
    
    const blob = new Blob([output.value], {type: 'text/plain'});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'obfuscated_' + Date.now() + '.lua';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showStatus('💾 Download gestartet!', 'success');
}

// ===== EVENT LISTENER =====
document.addEventListener('DOMContentLoaded', () => {
    const input = document.getElementById('luaInput');
    
    // Zeichen zählen
    input.addEventListener('input', updateCharCount);
    
    // Ctrl+Enter Shortcut
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.key === 'Enter') {
            e.preventDefault();
            obfuscateCode();
        }
    });
});

// ===== CORS TEST =====
// Teste, ob das Backend erreichbar ist
async function testBackend() {
    try {
        const response = await fetch(API_URL, {
            method: 'OPTIONS'
        });
        console.log('✅ Backend erreichbar');
    } catch (error) {
        console.warn('⚠️ Backend nicht erreichbar. Stelle sicher, dass Render läuft.');
        console.log('API_URL:', API_URL);
    }
}

// Test beim Laden
setTimeout(testBackend, 1000);
