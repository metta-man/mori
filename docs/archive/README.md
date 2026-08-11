# Mori Historical Archive

Everything under this directory is retained for provenance only. It is not current product direction, UI authority, implementation guidance, release status, or an approved backlog.

Start with `../CURRENT_SOURCES.md` for current sources.

## Archive Index

| Path | Contents |
| --- | --- |
| `design/` | Early UI briefs, personas, and DOSE reset design notes |
| `mockups/` | Historical HTML prototypes, previews, completion reports, and status notes |
| `research/` | Early market, architecture, pricing, sizing, persona, and technical research |
| `icon-concepts/` | Superseded icon explorations |
| `q2-prep/` | Historical Q2 briefs, handoffs, feature specs, and UI mockups |
| `product/` | Superseded DOSE reset and user-impact product research |
| `task-cards/` | Completed or superseded v2 implementation task cards |
| `quality/` | Historical design QA notes |

## Active Replacements

- Current source map: `../CURRENT_SOURCES.md`
- Approved UI direction: `../../DesignReferences/MORI_DESIGN_SPEC.md`
- Approved reference image: `../../DesignReferences/mori-approved-reference.jpeg`
- Product language and interaction: `../../MORI_DESIGN_SYSTEM_V2.md`
- SwiftUI component guide: `../../DesignSystem/MoriDesignSystemDocumentation.md`
- Brand identity: `../../brand-assets/MORI_BRAND_IDENTITY_SYSTEM.md`
- Active onboarding: `../../q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md`
- Release evidence: `../../MORI_REDESIGN_RELEASE_AUDIT.md`

## Reading Rules

- Expect obsolete product assumptions, names, screenshots, APIs, paths, and completion claims.
- Do not implement an archived task card without rewriting it against current source and current acceptance criteria.
- Do not use an archived mockup as visual authority.
- Do not infer current market facts from archived research.
- Historical documents are intentionally not rewritten to current terminology; this preserves what was decided at the time.
- Relative links and root-level commands inside archived files may be broken after relocation.

The current UI name is **Life Grid**. Current internal Swift symbols and paths keep `WeekArchive*`. Archived files may contain earlier variants of both names.

## Retained Active Exception

`q2-prep/onboarding/ONBOARDING_FLOW_DESIGN.md` was not archived. It remains at its original path because it is the active App Limit-first onboarding contract and is referenced by current design gates.
