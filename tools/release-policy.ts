/** #83: Godot addon acceptance. No obsolete UI or standalone-app requirements. */
import type { Stage } from './compat-kit.ts';
export const REQUIRED = [
    'profiling.build', 'profiling.import', 'profiling.runtime',
    'twoway.build', 'twoway.import', 'twoway.runtime', 'twoway.editor', 'twoway.visual',
    'lists.build', 'lists.import', 'lists.runtime', 'lists.rejection', 'lists.editor', 'lists.visual',
    'conditional.build', 'conditional.import', 'conditional.runtime', 'conditional.rejection', 'conditional.editor', 'conditional.visual',
    'composition.build', 'composition.import', 'composition.runtime', 'composition.editor', 'composition.visual',
    'reactive.build', 'reactive.import', 'reactive.runtime', 'reactive.editor', 'reactive.visual',
    "bindable.build", "bindable.import", "bindable.runtime", "bindable.editor",
    'compiler.import', 'compiler.frontend', 'compiler.registered', 'compiler.positive', 'compiler.rollback', 'compiler.fresh_failure',
    'runtime.core', 'runtime.runtime', 'runtime.import', 'runtime.editor-1', 'runtime.editor-2', 'runtime.visual',
    'ggx.build', 'ggx.import', 'ggx.runtime', 'ggx.editor', 'ggx.visual',
    'ui.build', 'ui.import', 'ui.runtime', 'ui.editor', 'ui.visual',
    'metadata', 'distribution.package_layout', 'distribution.import', 'distribution.scenes', 'distribution.cold_editor', 'distribution.cold_build', 'distribution.cold_scenes', 'distribution.pack_export', 'distribution.pack_runtime'
] as const;
export function assessRelease(stages: Record<string, Stage>) {
    const missing = REQUIRED.filter(name => stages[name]?.status !== 'PASS');
    const failed = Object.keys(stages).filter(name => stages[name]!.status !== 'PASS');
    return { status: missing.length || failed.length ? 'BLOCKED' : 'PASS', missing, failed };
}
