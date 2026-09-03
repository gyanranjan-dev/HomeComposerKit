# Changelog

All notable changes to HomeComposerKit are documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-09-03

First public release of HomeComposerKit.

### Capabilities

- **API contract** — `HomeAPIResponse`, `HomeAPIResponseDecoder`, forward-compatible section type decoding
- **Models and decoding** — `HomePage`, `HomeSection`, `HomeSectionType`, `HomeSectionContent`, presentation configuration
- **Validation** — `HomePageValidator`, `HomeValidationResult`, safe composition fallback
- **Composition** — `HomeComposer`, `ComposedHomeSection`, ordering and duplicate-ID handling
- **Integration** — `HomeRenderContext`, `HomeRenderContextBuilder`, `HomePageProviding`
- **Actions** — `HomeAction`, `HomeActionHandler`, environment injection
- **Theme** — `HomeComposerTheme`, spacing, typography, semantic colors
- **Content and images** — `HomeImageProvider`, `HomeContentProvider`, `HomeImageSource`
- **Transformation** — `HomeSectionContentTransformerPipeline`, hide/replace/unchanged semantics
- **Personalization** — `HomePersonalizationContext`, `HomePersonalizationTransformer`
- **Renderer registry** — `HomeSectionRendererRegistry`, `HomeSectionRendering`, built-in section catalog
- **Section states** — `HomeSectionState`, loading/empty/error/skeleton presentation
- **Accessibility** — Dynamic Type, VoiceOver labels, adaptive grid layouts
- **Performance** — lazy rendering, stable IDs, identity pipeline short-circuit
- **Diagnostics** — `HomeDiagnostic`, `HomeComposerDiagnosticReporting`, `CollectingHomeDiagnosticReporter`
- **AI-ready engine** — `HomeAIConfigurationEngine`, `HomeAIProvider`, validated configuration suggestions

### Built-in section catalog

Banner, Categories, Products, Popular Products, Favorite Products, Recently Viewed, Recommendations, Brands, Promotions, Live Stream, Social.

### Architecture highlights

- Infrastructure-neutral: no networking, persistence, analytics, or third-party dependencies
- Host-owned providers for images, content, personalization, and AI
- Unknown backend section types preserved for custom renderer registration
- Additive public API with default no-op reporters and identity pipelines

### Demo

Companion demo app (`HomeComposerKitDemo`) demonstrates the full architecture flow from backend-style JSON fixture through rendering, including custom `flash_sale` renderer registration.

### Testing

- **321** deterministic framework unit tests
- No network calls, no secrets, no machine-specific paths
- `swift test` and `swift build` verified on macOS

[1.0.0]: https://github.com/gyanranjan-dev/HomeComposerKit/releases/tag/v1.0.0
