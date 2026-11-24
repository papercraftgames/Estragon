# U04 — scrollbar placement evidence

Issue #224 follows owner-merged U03 PR #223 at base
`fc8931eb79dd769043a8129121ef183fb4edcea3`. This is a coordinate-only change:
B owns native chrome placement; P retains thickness resolution/caps; V retains
all existing layout/clip/range semantics. No content-inset model is changed.

The repository-owned `placement_baseline.gd` captures the old padded/bordered
native controls. For400×300/border5/padding20 and vertical12/horizontal16, before
tracks were vertical `(363,25,12,234)` and horizontal `(25,259,338,16)`. After they
are `(383,5,12,274)` and `(5,279,378,16)`, with corner `(383,279,12,16)`. V remains
`(25,25,338,234)`. Single-axis vertical moves from `(363,25,12,250)` to
`(383,5,12,290)`; V stays `(25,25,338,250)`.

Focused Linux4.7 checks: geometry28 and native44 PASS, including asymmetric/fractional
P-based percentages, new-position native hover/press/drag/track clicks, old-track
padding-band rejection, edge clicks, native/teal/custom textures and minimum fitting,
nested wheel exhaustion, responsive Wrap/runtime/GGX/retained focus/caret/offset,
scene reload and idle. The first reload fixture incorrectly used a participant
without an Entry; it was corrected to a native independent Entry, with the failure
retained. It was a fixture setup error, not a changed product contract.

Offset observations confirm fixed clip/padding/chrome at0/235/470: first content
top25/−210/−445, last bottom745/510/275, range470 from720 content and250 viewport.
The alternative moving leading/trailing-inset model is a separate future owner
decision, not selected or implemented here.

Final clean source identity, paired direct-Yarn outcomes, exact commands and
rendered evidence will be recorded after acceptance. Only official Linux4.0.4 and
pinned4.7.0 are used. Manual interactive smoke, actual OS pointer/IME, other
platforms/minors and measured-monitor DPI are not claimed. Synthetic native input,
headless geometry and rendered software-GL/Xvfb captures are distinct proofs.
