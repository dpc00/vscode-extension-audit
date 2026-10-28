'use strict';
// Bulk static triage of VS Code extensions: downloads each .vsix into MEMORY (nothing is written to disk except the
// result TSV), reads the zip directly, and records facts about the extension's own code. Nothing from an extension is run.
// Usage: node tools\bulk_triage.js <list.tsv> <out.tsv> [--offset N] [--limit N] [--concurrency N]
// The list is the output of tools\list_extensions.ps1 (columns order, installs, pkg, ...).
const https = require('https');
const zlib = require('zlib');
const crypto = require('crypto');
const fs = require('fs');

const [listFile, outFile] = process.argv.slice(2, 4);
const opt = (name, def) => { const i = process.argv.indexOf('--' + name); return i > 0 ? Number(process.argv[i + 1]) : def; };
const OFFSET = opt('offset', 0), LIMIT = opt('limit', 1e9), CONC = opt('concurrency', 6);
if (!listFile || !outFile) { console.error('usage: node bulk_triage.js list.tsv out.tsv [--offset N] [--limit N] [--concurrency N]'); process.exit(2); }

const QUIET_HOSTS = /(^|\.)(w3\.org|github\.com|githubusercontent\.com|npmjs\.(com|org)|nodejs\.org|mozilla\.org|mozilla\.github\.io|mdn\.io|microsoft\.com|visualstudio\.com|stackoverflow\.com|wikipedia\.org|json-schema\.org|ietf\.org|ecma-international\.org|apache\.org|opensource\.org|creativecommons\.org|example\.com|localhost|127\.0\.0\.1|paypal\.com|twitter\.com|x\.com|patreon\.com|ko-fi\.com|lodash\.com|underscorejs\.org|jquery\.org|openjsf\.org|mths\.be|mathiasbynens\.be|feross\.org|whatwg\.org|spec\.whatwg\.org|chromium\.org|webkit\.org|w3schools\.com|readthedocs\.io|gitlab\.com|bitbucket\.org|marketplace\.visualstudio\.com|aka\.ms|vscode\.dev|eslint\.org|prettier\.io|typescriptlang\.org)$/i;
const NATIVE = /\.(exe|dll|node|so|dylib|bat|cmd|ps1|sh|vbs|jar|msi|app)$/i;

function get(url, tries = 3, redirects = 5) {
    return new Promise((resolve, reject) => {
        const req = https.get(url, { headers: { 'Accept-Encoding': 'gzip', 'User-Agent': 'vscode-extension-audit' } }, (res) => {
            if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location && redirects > 0) {
                res.resume(); return resolve(get(new URL(res.headers.location, url).toString(), tries, redirects - 1));
            }
            if (res.statusCode !== 200) { res.resume(); return tries > 1 ? resolve(get(url, tries - 1, redirects)) : reject(new Error('HTTP ' + res.statusCode)); }
            const chunks = []; res.on('data', (c) => chunks.push(c));
            res.on('end', () => {
                let buf = Buffer.concat(chunks);
                try { if (res.headers['content-encoding'] === 'gzip') buf = zlib.gunzipSync(buf); } catch (e) { return reject(e); }
                resolve(buf);
            });
            res.on('error', reject);
        });
        req.setTimeout(120000, () => req.destroy(new Error('timeout')));
        req.on('error', (e) => tries > 1 ? resolve(get(url, tries - 1, redirects)) : reject(e));
    });
}

// "latest" on the marketplace is often a pre-release that VS Code's installer does not pick. Ask for the version list and
// choose what the installer would: the newest non-pre-release version that fits VS Code 1.144 and this platform.
const VSCODE = [1, 144, 0];
function engineOk(engine) {
    const m = /(\d+)\.(\d+)(?:\.(\d+))?/.exec(engine || '');
    if (!m) return true; // "*" or missing
    const need = [Number(m[1]), Number(m[2]), Number(m[3] || 0)];
    for (let i = 0; i < 3; i++) { if (need[i] < VSCODE[i]) return true; if (need[i] > VSCODE[i]) return false; }
    return true;
}
function postJson(url, body) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify(body);
        const u = new URL(url);
        const req = https.request({ host: u.host, path: u.pathname, method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json;api-version=7.1-preview.1', 'Content-Length': Buffer.byteLength(data), 'Accept-Encoding': 'gzip' }, timeout: 60000 }, (res) => {
            const chunks = []; res.on('data', (c) => chunks.push(c));
            res.on('end', () => { try { let b = Buffer.concat(chunks); if (res.headers['content-encoding'] === 'gzip') b = zlib.gunzipSync(b); resolve(JSON.parse(b.toString('utf8'))); } catch (e) { reject(e); } });
        });
        req.on('error', reject); req.on('timeout', () => req.destroy(new Error('timeout')));
        req.end(data);
    });
}
async function pickVersion(id) {
    const resp = await postJson('https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery', { filters: [{ criteria: [{ filterType: 7, value: id }], pageNumber: 1, pageSize: 1 }], assetTypes: [], flags: 17 });
    const ext = resp.results && resp.results[0] && resp.results[0].extensions && resp.results[0].extensions[0];
    if (!ext) return { version: 'latest', why: 'not found by name' };
    const prop = (v, k) => { const p = (v.properties || []).find((x) => x.key === k); return p ? p.value : ''; };
    for (const v of ext.versions || []) {
        if (prop(v, 'Microsoft.VisualStudio.Code.PreRelease') === 'true') continue;
        if (v.targetPlatform && v.targetPlatform !== 'win32-x64') continue;
        if (!engineOk(prop(v, 'Microsoft.VisualStudio.Code.Engine'))) continue;
        return { version: v.version, platform: v.targetPlatform || '', why: '' };
    }
    return { version: 'latest', why: 'no release version fits' };
}

// Minimal zip reader (central directory + inflateRaw); no ZIP64 needed for extensions.
function zipEntries(buf) {
    let eocd = -1;
    for (let i = buf.length - 22; i >= Math.max(0, buf.length - 65557); i--) if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
    if (eocd < 0) throw new Error('not a zip');
    const count = buf.readUInt16LE(eocd + 10);
    let p = buf.readUInt32LE(eocd + 16);
    const out = [];
    for (let n = 0; n < count; n++) {
        if (buf.readUInt32LE(p) !== 0x02014b50) throw new Error('bad central directory');
        const method = buf.readUInt16LE(p + 10), csize = buf.readUInt32LE(p + 20), usize = buf.readUInt32LE(p + 24);
        const nlen = buf.readUInt16LE(p + 28), elen = buf.readUInt16LE(p + 30), clen = buf.readUInt16LE(p + 32), off = buf.readUInt32LE(p + 42);
        out.push({ name: buf.toString('utf8', p + 46, p + 46 + nlen), method, csize, usize, off });
        p += 46 + nlen + elen + clen;
    }
    return out;
}
function entryData(buf, e) {
    const nlen = buf.readUInt16LE(e.off + 26), elen = buf.readUInt16LE(e.off + 28);
    const start = e.off + 30 + nlen + elen;
    const raw = buf.subarray(start, start + e.csize);
    return e.method === 0 ? raw : zlib.inflateRawSync(raw);
}

const PATTERNS = {
    exec: /child_process|\bspawn(Sync)?\(|\bexecFile(Sync)?\(|\bexec(Sync)?\(/g,
    evalx: /\beval\(|new Function\(/g,
    net: /require\(['"]https?['"]\)|require\(['"]net['"]\)|\bfetch\(|XMLHttpRequest|WebSocket\(|\baxios\b|node-fetch|got\(/g,
    env: /process\.env/g,
    cred: /\.ssh|\.aws|\.npmrc|credentials|keytar|\.gitconfig|id_rsa|homedir\(\)/g,
    enc: /atob\(|btoa\(|fromCharCode|Buffer\.from\([^)]*base64/g,
    telem: /applicationinsights|segment\.io|telemetry-reporter|vscode-extension-telemetry|sentry|mixpanel|amplitude|google-analytics|posthog/gi,
};

function analyse(id, buf) {
    const entries = zipEntries(buf);
    const pkgEntry = entries.find((e) => e.name === 'extension/package.json');
    if (!pkgEntry) throw new Error('no package.json');
    const pkg = JSON.parse(entryData(buf, pkgEntry).toString('utf8').replace(/^﻿/, ''));
    const row = { version: pkg.version, size: buf.length, sha256: crypto.createHash('sha256').update(buf).digest('hex').slice(0, 16) };
    const files = entries.filter((e) => !e.name.endsWith('/'));
    const isJs = (n) => /\.(js|cjs|mjs)$/i.test(n);
    const own = files.filter((e) => isJs(e.name) && !/\/node_modules\//.test(e.name) && e.usize < 60e6);
    const deps = files.filter((e) => isJs(e.name) && /\/node_modules\//.test(e.name));
    const counts = {}, hosts = new Map();
    for (const k of Object.keys(PATTERNS)) counts[k] = 0;
    for (const e of own) {
        const text = entryData(buf, e).toString('latin1');
        for (const [k, re] of Object.entries(PATTERNS)) { re.lastIndex = 0; const m = text.match(re); if (m) counts[k] += m.length; }
        for (const m of text.matchAll(/https?:\/\/([A-Za-z0-9.-]+\.[A-Za-z]{2,})/g)) { const h = m[1].toLowerCase(); hosts.set(h, (hosts.get(h) || 0) + 1); }
    }
    const loudHosts = [...hosts.keys()].filter((h) => !QUIET_HOSTS.test(h)).slice(0, 8);
    const natives = files.filter((e) => NATIVE.test(e.name) && !/\/node_modules\//.test(e.name)).map((e) => e.name.replace(/^extension\//, ''));
    const nativesDeps = files.filter((e) => NATIVE.test(e.name) && /\/node_modules\//.test(e.name)).length;
    const act = [].concat(pkg.activationEvents || []);
    const c = pkg.contributes || {};
    const hooks = Object.keys(pkg.scripts || {}).filter((s) => /^(pre|post)?install$/.test(s));
    const flags = [];
    if (counts.exec) flags.push('EXEC');
    if (counts.evalx) flags.push('EVAL');
    if (counts.net) flags.push('NET');
    if (counts.cred) flags.push('CRED');
    if (counts.telem) flags.push('TELEM');
    if (natives.length) flags.push('BIN');
    if (loudHosts.length) flags.push('HOSTS');
    if ([].concat(pkg.extensionPack || [], pkg.extensionDependencies || []).length) flags.push('PACK');
    if (act.includes('*')) flags.push('ALWAYS');
    if (deps.length > 400) flags.push('FATDEPS');
    if (!pkg.main && !pkg.browser) flags.push('NOCODE');
    return Object.assign(row, {
        publisher: pkg.publisher, main: pkg.main || '', activation: act.slice(0, 6).join(','), pack: [].concat(pkg.extensionPack || [], pkg.extensionDependencies || []).join(','),
        own_js: own.length, own_bytes: own.reduce((s, e) => s + e.usize, 0), dep_js: deps.length, natives: natives.slice(0, 5).join(','), native_deps: nativesDeps,
        exec: counts.exec, evalx: counts.evalx, net: counts.net, env: counts.env, cred: counts.cred, enc: counts.enc, telem: counts.telem,
        hosts: loudHosts.join(','), hooks: hooks.join(','),
        contributes: ['commands', 'languages', 'grammars', 'themes', 'iconThemes', 'debuggers', 'snippets', 'configuration', 'views', 'customEditors', 'taskDefinitions', 'terminal'].filter((k) => c[k]).join(','),
        flags: flags.join(' '),
    });
}

const COLUMNS = ['order', 'pkg', 'installs', 'version', 'flags', 'size', 'sha256', 'publisher', 'main', 'activation', 'pack', 'own_js', 'own_bytes', 'dep_js', 'natives', 'native_deps', 'exec', 'evalx', 'net', 'env', 'cred', 'enc', 'telem', 'hosts', 'hooks', 'contributes', 'error'];
const clean = (v) => String(v === undefined ? '' : v).replace(/[\t\r\n]+/g, ' ');

async function main() {
    const lines = fs.readFileSync(listFile, 'utf8').replace(/^﻿/, '').split(/\r?\n/).filter(Boolean);
    const head = lines.shift().split('\t');
    const rows = lines.map((l) => { const f = l.split('\t'); const o = {}; head.forEach((h, i) => { o[h] = f[i]; }); return o; }).slice(OFFSET, OFFSET + LIMIT);
    const done = new Set();
    if (fs.existsSync(outFile)) for (const l of fs.readFileSync(outFile, 'utf8').split(/\r?\n/).slice(1)) { const f = l.split('\t'); if (f[1]) done.add(f[1].toLowerCase()); }
    else fs.writeFileSync(outFile, COLUMNS.join('\t') + '\n');
    const todo = rows.filter((r) => !done.has(r.pkg.toLowerCase()));
    console.log(`${rows.length} in range, ${done.size} already in ${outFile}, ${todo.length} to do, concurrency ${CONC}`);
    let next = 0, finished = 0, failedNet = 0; const t0 = Date.now();
    async function worker() {
        while (next < todo.length) {
            const r = todo[next++];
            const [pub, name] = r.pkg.split('.');
            const rec = { order: r.order, pkg: r.pkg, installs: r.installs };
            const NETERR = /ENOTFOUND|EAI_AGAIN|ECONNRESET|ECONNREFUSED|ETIMEDOUT|EHOSTUNREACH|ENETUNREACH|timeout|socket hang up|HTTP 429|HTTP 5\d\d/;
            let netFail = false;
            for (let attempt = 1; attempt <= 6; attempt++) {
                try {
                    const pick = await pickVersion(r.pkg);
                    const buf = await get(`https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${pub}/vsextensions/${name}/${pick.version}/vspackage` + (pick.platform ? '?targetPlatform=' + pick.platform : ''));
                    Object.assign(rec, analyse(r.pkg, buf));
                    if (pick.why) rec.error = 'version: ' + pick.why;
                    netFail = false; break;
                } catch (e) {
                    if (NETERR.test(e.message) && attempt < 6) { netFail = true; await new Promise((res) => setTimeout(res, 5000 * attempt)); continue; }
                    if (NETERR.test(e.message)) { netFail = true; break; }
                    rec.error = e.message; rec.flags = 'ERROR'; netFail = false; break;
                }
            }
            if (netFail) { failedNet++; if (failedNet % 10 === 1) console.log(`network trouble on ${r.pkg} (not recorded; rerun to resume), ${failedNet} so far`); continue; }
            fs.appendFileSync(outFile, COLUMNS.map((c) => clean(rec[c])).join('\t') + '\n');
            finished++;
            if (finished % 10 === 0) console.log(`${finished}/${todo.length} done, ${Math.round((Date.now() - t0) / 1000)} s`);
        }
    }
    await Promise.all(Array.from({ length: CONC }, worker));
    console.log(`finished ${finished} in ${Math.round((Date.now() - t0) / 1000)} s` + (failedNet ? `; ${failedNet} not recorded because of network errors: rerun the same command to resume` : ''));
}
main().catch((e) => { console.error(e); process.exit(1); });
