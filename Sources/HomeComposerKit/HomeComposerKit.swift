// HomeComposerKit
//
// Architecture:
//
//   Host App
//       ↓  (owns networking, authentication, caching, logging)
//   JSON / Data  (HomeAPIResponse contract)
//       ↓
//   API               (HomeAPIResponseDecoder → HomeAPIResponse)
//       ↓
//   Decoding          (HomePageDecoder — also supports direct HomePage JSON)
//       ↓
//   Models            (HomePage + optional schemaVersion / configurationVersion)
//       ↓
//   Validation        (optional HomePageValidator → HomeValidationResult)
//       ↓
//   AI                (HomeAIConfigurationEngine — host-injected HomeAIProvider)
//       ↓
//   Diagnostics       (HomeComposerDiagnosticReporting — silent by default)
//       ↓
//   Integration       (HomeRenderContextBuilder / HomePageProviding)
//       ↓
//   Composition       (HomeComposer — skips invalid/disabled; keeps ordering)
//       ↓
//   Transformation    (HomeSectionContentTransformerPipeline — host enrichment)
//       ↓
//   Actions           (HomeAction — host interprets user interactions)
//       ↓
//   Theme             (HomeComposerTheme — host-customizable visual styling)
//       ↓
//   Content           (HomeImageProvider / HomeContentProvider — host loading)
//       ↓
//   SwiftUI Rendering (HomeComposerView + HomeSectionRendererRegistry)
//                     Host extensions via HomeSectionRendering registration
//                     Unregistered renderers → EmptyView (safe fallback)
//
// HomeComposerKit does not perform networking or authentication.
// HomeComposerKit does not provide an AI vendor implementation.
// HomeComposerKit does not download images; hosts supply HomeImageProvider.
// The host application supplies HomeAIProvider; the SDK validates structured output.
// Backend configuration changes must not crash an existing host app.
