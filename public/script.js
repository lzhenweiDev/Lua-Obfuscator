let examples = {
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
end

local function getVersion()
    return data.version
end`,

    class: `-- Klassensimulation
local Person = {}
Person.__index = Person

function Person:new(name, age)
    local obj = {
        name = name,
        age = age
    }
    setmetatable(obj, Person)
    return obj
end

function Person:introduce()
    print('Hi, I am ' .. self.name .. ' and I am ' .. self.age .. ' years old')
end

local john = Person:new('John', 25)
john:introduce()`,

    api: `-- API Simulation
local api = {
    base_url = 'https://api.example.com',
    key = 'secret_key_123'
}

function api:request(endpoint, method)
    print('Making ' .. method .. ' request to ' .. self.base_url .. endpoint)
    return {
        status = 200,
        data = {result = 'success'}
    }
end

local response = api:request('/users', 'GET')
print('Status: ' .. response.status)`
};

function loadExample(name) {
    const input = document.getElementById('luaInput');
    input.value = examples[name] || '';
    document.getElementById('charCount').textContent = input.value.length + ' Zeichen';
    clearStatus();
}

async function obfuscateCode() {
    const input = document.getElementById('luaInput');
    const output = document.getElementById('luaOutput');
    const status = document.getElementById('status');
    const btn = document.getElementById('obfuscateBtn');
    const stats = document.getElementById('stats');
    
    const code = input.value.trim();
    if (!code) {
        showStatus('Bitte gib Lua Code ein!', 'error');
        return;
    }
    
    btn.disabled = true;
    btn.innerHTML = '<span class="btn-icon">⏳</span> Obfuscating...';
    showStatus('Obfuscation läuft...', 'info');
    
    const options = {
        code: code,
        minify: document.getElementById('minify').checked,
        encrypt: document.getElementById('encrypt').checked,
        renameVars: document.getElementById('renameVars').checked,
        removeComments: document.getElementById('removeComments').checked
    };
    
    try {
        // API Endpoint - Serverless oder Full Server
        const response = await fetch('/api/obfuscate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(options)
        });
        
        if (!response.ok) throw new Error('Server error');
        
        const data = await response.json();
        
        if (data.success) {
            output.value = data.obfuscated;
            showStatus('✅ Code erfolgreich obfuscated!', 'success');
            
            // Stats anzeigen
            if (data.stats) {
                document.getElementById('originalSize').textContent = data.stats.originalSize;
                document.getElementById('obfuscatedSize').textContent = data.stats.obfuscatedSize;
                document.getElementById('compression').textContent = data.stats.compression;
                stats.style.display = 'flex';
            }
        } else {
            showStatus('❌ ' + (data.error || 'Obfuscation fehlgeschlagen'), 'error');
        }
    } catch (error) {
        showStatus('❌ Fehler: ' + error.message, 'error');
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<span class="btn-icon">⚡</span> Obfuscate <span class="shortcut">(Ctrl+Enter)</span>';
    }
}

function copyOutput() {
    const output = document.getElementById('luaOutput');
    if (!output.value) {
        showStatus('Kein Code zum Kopieren vorhanden', 'error');
        return;
    }
    
    output.select();
    navigator.clipboard.writeText(output.value).then(() => {
        showStatus('📋 In Zwischenablage kopiert!', 'success');
    }).catch(() => {
        // Fallback
        document.execCommand('copy');
        showStatus('📋 Kopiert!', 'success');
    });
}

function downloadOutput() {
    const output = document.getElementById('luaOutput');
    if (!output.value) {
        showStatus('Kein Code zum Herunterladen', 'error');
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

function clearOutput() {
    document.getElementById('luaOutput').value = '';
    document.getElementById('stats').style.display = 'none';
    showStatus('Ausgabe gelöscht', 'info');
}

function showStatus(message, type = 'info') {
    const status = document.getElementById('status');
    status.textContent = message;
    status.className = 'status ' + type;
    status.style.display = 'block';
}

function clearStatus() {
    const status = document.getElementById('status');
    status.style.display = 'none';
}

// Keyboard Shortcuts
document.addEventListener('DOMContentLoaded', () => {
    const input = document.getElementById('luaInput');
    
    // Char Count
    input.addEventListener('input', () => {
        document.getElementById('charCount').textContent = input.value.length + ' Zeichen';
    });
    
    // Ctrl+Enter
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.key === 'Enter') {
            e.preventDefault();
            obfuscateCode();
        }
    });
});

// Lazy Load - Beispiele beim ersten Klick
document.addEventListener('click', (e) => {
    if (e.target.classList.contains('example-btn')) {
        // Beispiel wird bereits geladen
    }
});
