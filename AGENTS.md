## Mori UI Design Source of Truth

Before making any Mori UI, SwiftUI layout, styling, navigation-hierarchy, animation, or visual-component change:

1. Read `DesignReferences/MORI_DESIGN_SPEC.md`.
2. Open and inspect `DesignReferences/mori-approved-reference.jpeg`.
3. Treat the reference image as the approved visual source of truth.
4. Read `MORI_DESIGN_SYSTEM_V2.md` for active product language and interaction constraints.
5. Use `DesignSystem/MoriDesignSystemDocumentation.md` and the current Swift files for component APIs.
6. Preserve all existing working functionality, persistence, FamilyControls, DeviceActivity, ManagedSettings, app-lock behaviour, and navigation unless the task explicitly requests a functional change.
7. For affected screens, run the app, capture screenshots, compare them against the approved reference, and perform at least two visual-refinement passes before declaring completion.

Do not reinterpret the reference loosely. Do not replace its layout with generic white cards, repeated “More…” rows, or a simplified settings-style interface.

## Source Precedence

Use `docs/CURRENT_SOURCES.md` to resolve documentation conflicts. In particular:

- Current source code and `project.yml` define runtime behaviour and target membership.
- `DesignReferences/` defines approved visual direction.
- `MORI_DESIGN_SYSTEM_V2.md` defines active product language and interaction constraints.
- `MORI_REDESIGN_RELEASE_AUDIT.md` is verification evidence, not a competing design specification.
- `docs/archive/` is historical provenance only.

## Naming Boundary

- Use **Life Grid** in UI copy, product prose, accessibility labels, screenshots, and current documentation.
- Keep `WeekArchive*` for internal Swift symbols, file paths, routes, stores, and persistence identifiers.
- Do not perform a broad internal rename solely to align the display name.
