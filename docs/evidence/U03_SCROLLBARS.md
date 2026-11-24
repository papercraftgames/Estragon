# U03 — source-qualified scrollbar evidence

Issue [#222](https://github.com/papercraftgames/Estragon/issues/222) follows merged
L12/UI-04 PR #221 (`f4072716c91c4636325457a9c4b401b7c75236d7`).

Baseline: official Linux4.7 `5b4e0cb0f`, repository-owned
`tests/scrollbars/baseline.gd` over that unmodified main addon. Outer400×300,
clip/child400px, bar starts388px: the right12px overlay content. Capture/log are
under `tests/scrollbars/evidence/baseline`. No external GogoDemo changes.

Focused development checks: pure geometry39, native rendered/input34 and retained
GGX30 assertions passed on Linux4.7. Static checks initially caught the two new
untracked helpers/missing UID sidecars; sidecars were generated once with official
Godot ResourceUID and added with the scripts before the final check. These dirty
iteration results are not clean-source paired acceptance.

Final paired commands, source identity, exact outcomes and limitations will be
recorded here after the clean-source collector completes. Only approved official
Linux4.0.4 and pinned4.7.0 are used. No manual interactive smoke, physical keypress,
OS-level pointer/IME, other platform, extra minor or measured monitor-DPI proof is
claimed. Viewport/reference units are logical pixels at the documented96px/in
scale. Synthetic native input and rendered Xvfb/software-GL evidence are distinct
from manual interaction.
