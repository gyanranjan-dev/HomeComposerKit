// HomeComposerKit
//
// Architecture:
//
//   Host App
//       ↓  (owns networking, authentication, caching, logging)
//   JSON / Data
//       ↓
//   Decoding          (HomePageDecoder — unknown section types preserved)
//       ↓
//   Models            (HomePage + optional schemaVersion / configurationVersion)
//       ↓
//   Validation        (optional HomePageValidator → HomeValidationResult)
//       ↓
//   Diagnostics       (HomeComposerDiagnosticReporting — silent by default)
//       ↓
//   Integration       (HomeRenderContextBuilder / HomePageProviding)
//       ↓
//   Composition       (HomeComposer — skips invalid/disabled; keeps ordering)
//       ↓
//   SwiftUI Rendering (HomeComposerView + HomeSectionRendererRegistry)
//                     Unregistered renderers → EmptyView (safe fallback)
//
// HomeComposerKit does not perform networking or authentication.
// Backend configuration changes must not crash an existing host app.
