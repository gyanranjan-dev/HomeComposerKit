// HomeComposerKit
//
// Architecture:
//
//   Host App
//       ↓  (owns networking, authentication, caching)
//   JSON / Data
//       ↓
//   Decoding          (HomePageDecoder)
//       ↓
//   Models            (HomePage, HomeSection, …)
//       ↓
//   Integration       (HomeRenderContextBuilder / HomePageProviding)
//       ↓
//   Composition       (HomeComposer → ComposedHomeSection)
//       ↓
//   SwiftUI Rendering (HomeComposerView + HomeSectionRendererRegistry)
//
// HomeComposerKit does not perform networking or authentication.
