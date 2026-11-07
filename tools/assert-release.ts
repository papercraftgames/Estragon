/** Require clean matching native-addon artifacts, exact engines, logs and hashes. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { assessRelease, REQUIRED_FAST_RELEASE } from './release-policy.ts';
import { sha256, readJSON, writeJSON } from './compat-kit.ts';
import type { Stage } from './compat-kit.ts';
export type AddonEvidence = {
    profile?: 'full' | 'fast-release';
    source_commit: string;
    source_dirty: boolean;
    label: string;
    version: string;
    binary_sha256: string;
    stages: Record<string, Stage>;
    files: Record<string, string>;
};
export function assessFile(file: string) {
    const report = readJSON<AddonEvidence>(file);
    const profile = report.profile ?? 'full';
    if(profile !== 'full' && profile !== 'fast-release')throw Error('Unknown release evidence profile');
    const fast = profile === 'fast-release';
    const pins = readJSON<Array<{
        version: string;
        binary_sha256: string;
    }>>(path.join(import.meta.dirname, '../tests/compatibility/linux-engines.json'));
    if (!report.source_commit || report.source_dirty !== false || !['4.0.4', '4.7'].includes(report.label))
        throw Error('Clean current source and approved engine required');
    if (!pins.some(p => p.version === report.version && p.binary_sha256 === report.binary_sha256) || !report.version.startsWith(report.label + '.stable.'))
        throw Error('Engine evidence identity mismatch');
    if (!report.files || !Object.keys(report.files).length)
        throw Error('Execution evidence missing');
    for (const [name, hash] of Object.entries(report.files)) {
        if (path.isAbsolute(name) || name.split(/[\\/]/).includes('..'))
            throw Error('Invalid evidence path');
        const target = path.join(path.dirname(file), name);
        if (!fs.existsSync(target) || sha256(target) !== hash)
            throw Error('Missing or mismatched evidence: ' + name);
        if (name.endsWith('provenance.json')) {
            const p = readJSON<any>(target);
            if (p.sourceHead !== report.source_commit || p.sourceDirty !== false || p.version !== report.version || p.original_binary_sha256 !== report.binary_sha256)
                throw Error('Source/engine provenance mismatch: ' + name);
        }
    }
    // Bind the summary to the hashed execution reports, not hand-entered PASSes.
    const observed: Record<string, Stage> = {};
    for (const group of fast ? ['package'] : ['compiler', 'runtime', 'ggx', 'ui', 'metadata', 'distribution', 'bindable', 'reactive', 'composition', 'conditional', 'lists', 'twoway', 'profiling', 'package']) {
        const relative = group + '/' + report.label + '/results.json';
        if (!report.files[relative])
            throw Error('Missing required group evidence: ' + group);
        const result = readJSON<any>(path.join(path.dirname(file), relative));
        if (group === 'metadata') {
            if (result.sourceHead !== report.source_commit || result.sourceDirty !== false || result.version !== report.version || result.original_binary_sha256 !== report.binary_sha256)
                throw Error('Metadata source/engine mismatch');
            observed.metadata = { status: result.status };
        }
        else {
            if (!report.files[group + '/' + report.label + '/provenance.json'])
                throw Error('Missing source/engine provenance: ' + group);
            for (const [key, value] of Object.entries(result)) {
                const stage = value as Stage;
                observed[group + '.' + key] = stage;
                if(group==='package' && key!=='pack') {
                    const runs=stage.runs as Stage[] | undefined;
                    const layouts = fast ? ['direct'] : ['direct', 'relocated', 'standard'];
                    if(!Array.isArray(runs) || runs.length!==layouts.length || layouts.some(layout=>runs.filter(run=>run.layout===layout).length!==1))throw Error('Missing package installation layout proof: '+key);
                    for(const run of runs) {
                        if(run.status!=='PASS' || run.exit_code!==0 || run.timeout || run.aborted_on_error || !run.command?.length || !run.log || path.basename(run.log)!==run.log || !report.files[group+'/'+report.label+'/'+run.log])throw Error('Missing successful package layout execution: '+key);
                    }
                }
                if (stage.command && (!stage.log || path.basename(stage.log) !== stage.log || !report.files[group + '/' + report.label + '/' + stage.log]))
                    throw Error('Missing stage execution log: ' + key);
                if (!['package_layout', 'engine_identity'].includes(key) && (!stage.command?.length || stage.exit_code !== 0 || stage.timeout || stage.aborted_on_error))
                    throw Error('Missing successful native execution: ' + key);
            }
        }
    }
    if(fast && JSON.stringify(Object.keys(observed).sort()) !== JSON.stringify([...REQUIRED_FAST_RELEASE].sort()))throw Error('Incomplete fast release stage inventory');
    if (JSON.stringify(observed) !== JSON.stringify(report.stages))
        throw Error('Stage evidence summary mismatch');
    return { ...report, assessment: assessRelease(report.stages, profile) };
}
if (import.meta.url === 'file://' + process.argv[1]) {
    try {
        const files = process.argv.slice(2);
        if (!files.length || files.length > 2)
            throw Error('Usage: assert-release.ts REPORT [REPORT]');
        const reports = files.map(assessFile);
        if (new Set(reports.map(r => r.label)).size !== reports.length || reports.some(r => r.source_commit !== reports[0]!.source_commit))
            throw Error('Release engine/source sets mismatch');
        for (const report of reports) {
            writeJSON(path.join(path.dirname(files[reports.indexOf(report)]!), 'release-assessment.json'), { source_commit: report.source_commit, label: report.label, ...report.assessment });
            if (report.assessment.status !== 'PASS')
                process.exitCode = 1;
        }
        console.log(JSON.stringify(reports.map(r => ({ label: r.label, ...r.assessment })), null, 2));
    }
    catch (e) {
        console.error(e);
        process.exitCode = 1;
    }
}
