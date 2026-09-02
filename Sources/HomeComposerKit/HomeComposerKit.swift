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
//   Personalization   (HomePersonalizationContext — host-provided opaque signals)
//       ↓
//   Actions           (HomeAction — host interprets user interactions)
//       ↓
//   Theme             (HomeComposerTheme — host-customizable visual styling)
//       ↓
//   Content           (HomeImageProvider / HomeContentProvider — host loading)
//       ↓
//   State             (HomeSectionState — host presentation; loading/empty/error)
//       ↓
//   Accessibility     (Dynamic Type, VoiceOver labels, adaptive layout)
//       ↓
//   Performance       (lazy rendering, stable IDs, deterministic pipelines)
//       ↓
//   SwiftUI Rendering (HomeComposerView + HomeSectionRendererRegistry)
//                     Built-in catalog: banner, categories, products, popular,
//                     favorites, recently viewed, recommendations, brand,
//                     promotion, live, social
//                     Custom sections: host registration via HomeSectionRendering
//                     Unregistered renderers → EmptyView (safe fallback)
//
// HomeComposerKit does not perform networking or authentication.
// HomeComposerKit does not provide an AI vendor implementation.
// HomeComposerKit does not download images; hosts supply HomeImageProvider.
// HomeComposerKit does not collect or store personalization data.
// HomeComposerKit does not perform section data loading; hosts supply section state.
// Section loading, empty, and error UI are presentation-only; retry uses HomeAction.
// Built-in views support Dynamic Type; custom renderers own their accessibility.
// Stable section/model IDs and lazy containers improve SwiftUI diff performance.
// The framework intentionally avoids global caches; pipelines remain deterministic.
// The host application supplies HomeAIProvider; the SDK validates structured output.
// Backend configuration changes must not crash an existing host app.
