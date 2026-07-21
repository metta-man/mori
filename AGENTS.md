## Mori UI Design Source of Truth

Before making any Mori UI, SwiftUI layout, styling, navigation-hierarchy, animation, or visual-component change:

1. Read `DesignReferences/MORI_DESIGN_SPEC.md`.
2. Open and inspect `DesignReferences/mori-approved-reference.jpeg`.
3. Treat the reference image as the approved visual source of truth.
4. Preserve all existing working functionality, persistence, FamilyControls, DeviceActivity, ManagedSettings, app-lock behaviour, and navigation unless the task explicitly requests a functional change.
5. For affected screens, run the app, capture screenshots, compare them against the approved reference, and perform at least two visual-refinement passes before declaring completion.

Do not reinterpret the reference loosely. Do not replace its layout with generic white cards, repeated “More…” rows, or a simplified settings-style interface.
