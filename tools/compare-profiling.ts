/** Compare like-for-like F06 native samples; never turn timing into a gate. */
import * as fs from 'node:fs';
import * as path from 'node:path';
const [beforeDir, afterDir, output] = process.argv.slice(2);
if (!beforeDir || !afterDir || !output) throw Error('Usage: compare-profiling.ts BEFORE_DIR AFTER_DIR OUTPUT.md');
const read = (dir:string, name:string) => JSON.parse(fs.readFileSync(path.join(dir,name+'.json'),'utf8'));
const before=read(beforeDir,'profile'), after=read(afterDir,'profile');
const bp=read(beforeDir,'provenance'), ap=read(afterDir,'provenance');
if (bp.version!==ap.version || bp.original_binary_sha256!==ap.original_binary_sha256 || before.warmup!==after.warmup || before.samples!==after.samples || bp.sourceDirty || ap.sourceDirty || before.failures || after.failures) throw Error('Comparable successful clean native source/engine/sample evidence required');
function stat(entry:any, percentile:number) { const samples=entry.samples.map((s:any)=>s.mutation_drain_us).filter((n:any)=>n!==undefined).sort((a:number,b:number)=>a-b);return samples[Math.max(0,Math.ceil(samples.length*percentile)-1)] as number|undefined; }
const lines=[`# F06 measured comparison — ${bp.version}`,'',`Before source: \`${bp.sourceHead}\`. After source: \`${ap.sourceHead}\`.`,`Same official binary SHA256: \`${bp.original_binary_sha256}\`.`,`Warmup ${before.warmup}; measured samples ${before.samples} per timed operation. Instrumented debug-engine mutation/drain wall µs; frame/layout settling excluded. Run-to-run runner noise and instrumentation overhead apply. Signed change describes these samples, not a release CPU/throughput guarantee.`,'','| Case | Before median / p95 µs | After median / p95 µs | Median change | Order comparisons before → after |','| --- | ---: | ---: | ---: | ---: |'];
for (const entry of before.cases) {
    const next=after.cases.find((e:any)=>e.name===entry.name);
    if(!next) throw Error('Missing comparable case: '+entry.name);
    const b=entry.samples?stat(entry,0.5):undefined, a=next.samples?stat(next,0.5):undefined;
    if(b===undefined || a===undefined) continue;
    if(entry.samples.length!==next.samples.length) throw Error('Sample count mismatch: '+entry.name);
    lines.push(`| ${entry.name} | ${b} / ${stat(entry,0.95)} | ${a} / ${stat(next,0.95)} | ${b?((a-b)*100/b).toFixed(1)+'%':'n/a'} | ${entry.samples[0].counts.order_comparisons||0} → ${next.samples[0].counts.order_comparisons||0} |`);
}
lines.push('','All deterministic identity, minimal-move, idle, selective work, layout-cache and lifetime assertions must separately pass. Raw profile/provenance/environment/logs are in the linked CI artifacts; native engine rendering/GPU/physics costs are unmeasured.');
fs.writeFileSync(output,lines.join('\n')+'\n');
