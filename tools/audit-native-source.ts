/** C4 retirement inventory and canonical source/UID/reference consistency. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT } from './compat-kit.ts';
export function auditNativeSource() {
    const scripts: string[] = [];
    const identities = new Set<string>();
    function walk(dir: string) { if (fs.existsSync(path.join(dir, '.gdignore')))
        return; for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const file = path.join(dir, item.name);
        if (item.isDirectory())
            walk(file);
        else if (file.endsWith('.gd'))
            scripts.push(file);
    } }
    for (const dir of ['addons', 'examples', 'tests'])
        walk(path.join(ROOT, dir));
    for (const file of scripts) {
        const uid = fs.readFileSync(file + '.uid', 'utf8').trim();
        if (!/^uid:\/\/[a-z0-9]+$/.test(uid) || identities.has(uid))
            throw Error('Missing/duplicate canonical script UID: ' + file);
        identities.add(uid);
        const text = fs.readFileSync(file, 'utf8');
        if (/Estragon(?:Surface|DisplayObject|Container)|runtime\/(?:surface|display_object|gogo_view)\.gd|Estragon(?:Rect|Text|Button|HBox|VBox)2D/.test(text))
            throw Error('Obsolete production consumer: ' + file);
        if (file.startsWith(path.join(ROOT, 'addons')) || file.startsWith(path.join(ROOT, 'examples'))) {
            for (const match of text.matchAll(/(?:preload\(|extends\s+)"res:\/\/([^"\n]+)"/g))
                if (!fs.existsSync(path.join(ROOT, match[1]!)))
                    throw Error('Dangling native source reference: ' + file + ' -> ' + match[1]);
        }
    }
    for (const name of ['counter/Counter', 'ggx/TwoD', 'ggx/ThreeD','bindable/Model','bindable/Derived','bindable/Demo','reactive/Model','reactive/State','reactive/Demo','composition/Model','composition/Counter']) {
        const [dir, base] = name.split('/');
        const source = path.join(ROOT, 'examples', dir!, base! + '.gogo');
        const map = JSON.parse(fs.readFileSync(path.join(ROOT, 'examples', dir!, 'generated', base! + '.gd.map.json'), 'utf8'));
        if (map.sourceContent !== fs.readFileSync(source, 'utf8') || map.sourceName !== 'examples/' + name + '.gogo')
            throw Error('Stale native generated source map: ' + name);
    }
    for (const old of ['addons/estragon/runtime/surface.gd', 'addons/estragon/runtime/display_object.gd', 'addons/estragon/compiler/node_proof', 'addons/estragon/layout_proof', 'addons/estragon/adapter_proof', 'examples/hello', 'tools/gogo.ts', 'tools/gogo'])
        if (fs.existsSync(path.join(ROOT, old)))
            throw Error('Retired path returned: ' + old);
    return { active_scripts: scripts.length, canonical_uids: identities.size };
}
