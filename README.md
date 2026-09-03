# HomeComposerKit

A Swift Package for building backend-driven, dynamically composable iOS home screens from JSON configuration — with validation, transformation, personalization hooks, and a pluggable SwiftUI renderer architecture.

## Features

- **Backend-driven home composition** — decode `HomeAPIResponse` JSON into ordered, renderable sections
- **Validation and safe fallback** — structural validation with diagnostics; invalid sections are skipped without crashing
- **Configurable layouts** — carousel, horizontal, grid, and lazy vertical layouts via `SectionConfiguration`
- **Actions** — framework-agnostic `HomeAction` events for product, category, banner, promotion, and custom interactions
- **Theme system** — host-customizable spacing, typography, colors, and corner radii via `HomeComposerTheme`
- **Image and content providers** — host-injected `HomeImageProvider` and `HomeContentProvider` abstractions
- **Content transformation** — sequential `HomeSectionContentTransformerPipeline` for hide, replace, and enrich
- **Personalization context** — opaque host-provided signals (`HomePersonalizationContext`) for deterministic transformers
- **Custom renderer / plugin architecture** — register host-owned SwiftUI renderers via `HomeSectionRendererRegistry`
- **Loading, empty, error, and skeleton states** — presentation-only `HomeSectionState` with retry through `HomeAction`
- **Accessibility and responsive layout** — Dynamic Type, VoiceOver labels, and adaptive column sizing
- **Performance characteristics** — lazy section lists, stable IDs, identity pipeline short-circuit, no global caches
- **Diagnostics** — structured, host-consumable developer observability (not analytics or telemetry)
- **AI-ready configuration engine** — `HomeAIConfigurationEngine` validates structured output from a host-injected `HomeAIProvider`

## Architecture

```text
Backend JSON
    ↓
HomeAPIResponseDecoder          (API contract)
    ↓
HomePageValidator               (optional validation + diagnostics)
    ↓
HomeRenderContextBuilder        (host-resolved section content)
    ↓
HomeComposer                    (ordering, filtering, safe fallback)
    ↓
HomeSectionContentTransformerPipeline   (host enrichment)
    ↓
HomePersonalizationContext      (opaque host signals)
    ↓
HomeSectionRendererRegistry     (built-in + custom renderers)
    ↓
HomeComposerView                (SwiftUI)
```

HomeComposerKit does **not** perform networking, download images, store customer data, or run recommendation algorithms. The host application owns those responsibilities.

## Built-in Sections

| Section type | Description |
|---|---|
| `banner` | Carousel or stacked promotional banners |
| `categories` | Horizontal or grid category list |
| `products` | Product grid or list |
| `popularProducts` | Popular products horizontal scroller |
| `favoriteProducts` | Favorite products horizontal scroller |
| `recentlyViewed` | Recently viewed products |
| `recommendations` | Recommendation product list |
| `brand` | Featured brands |
| `promotion` | Promotional offers |
| `liveStream` | Live stream cards |
| `social` | Community / social posts |

Unknown backend section types decode safely as `HomeSectionType.unknown(_:)` and can be rendered by host-registered custom renderers.

## Custom Sections

Register a renderer for a backend type string such as `"flash_sale"`:

```swift
import HomeComposerKit
import SwiftUI

let registry = HomeSectionRendererRegistry.makeDefault()
    .registering(type: "flash_sale") { section in
        FlashSaleSectionView(section: section)
    }

HomeComposerView(
    context: context,
    rendererRegistry: registry,
    onAction: handleAction
)
```

Unregistered section types render as `EmptyView` — they never crash the host app. A diagnostic is emitted when a reporter is configured.

## Host Responsibilities

The host application owns:

| Responsibility | HomeComposerKit provides |
|---|---|
| Networking and API clients | Decoding contract only (`HomeAPIResponseDecoder`) |
| Image downloading and caching | `HomeImageProvider` injection |
| Content fetching and persistence | `HomeContentProvider`, `contentBySectionID` map |
| Customer / session data | `HomePersonalizationContext` (opaque IDs only) |
| Recommendation algorithms | Deterministic reorder/filter utilities only |
| Analytics and telemetry | `HomeComposerDiagnosticReporting` (local, in-process) |

## AI

`HomeAIConfigurationEngine` accepts a host-injected `HomeAIProvider` and validates structured `HomeConfigurationSuggestion` output through `HomePageValidator`.

The framework does **not**:

- ship an AI vendor implementation
- generate executable Swift source
- call external model APIs directly

The host supplies the provider; the SDK validates and composes the resulting configuration.

## Installation

### Swift Package Manager

Add the package to your Xcode project (**File → Add Package Dependencies**) or `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gyanranjan-dev/HomeComposerKit.git", from: "1.0.0")
]
```

For local development alongside the demo app:

```swift
.package(path: "../HomeComposerKit")
```

## Quick Start

```swift
import HomeComposerKit

// 1. Host fetches JSON (networking is outside the framework)
let response = try HomeAPIResponseDecoder().decode(data)

// 2. Host resolves section content
let context = HomeRenderContextBuilder().makeContext(
    from: response,
    contentBySectionID: hostContent,
    validate: true,
    diagnosticReporter: myReporter
)

// 3. Render
HomeComposerView(context: context, onAction: handleAction)
    .homeImageProvider(hostImageProvider)
    .homePersonalizationContext(personalizationContext)
```

## Demo

See the companion **HomeComposerKitDemo** app in the sibling directory `../HomeComposerKitDemo` for a full showcase:

- Backend fixture decoding via `HomeAPIResponseDecoder`
- Personalization and transformation pipelines
- Custom `flash_sale` renderer registration
- Section state controls (loaded / loading / empty / failed)
- Theme toggle and diagnostics collection

```bash
open HomeComposerKitDemo.xcodeproj
# Select an iPhone Simulator → Run (⌘R)
```

## Testing

```bash
swift test    # 321+ deterministic tests, no network
swift build
```

Performance tests measure relative behavior (pipeline short-circuit, composition throughput). Timing baselines are environment-dependent and are not release gates.

## Requirements

| Requirement | Version |
|---|---|
| iOS | 16.0+ |
| Swift | 6.0+ (swift-tools-version 6.3) |
| Xcode | 16+ recommended |

macOS 13+ is supported for `swift test` on developer machines. The SwiftUI rendering layer targets iOS.

## Versioning

This project follows [Semantic Versioning](https://semver.org/). Release versions are tagged in Git (e.g. `v1.0.0`). The package does not expose a runtime version constant.

## License

A license file is required before publishing as an open-source project. See [License](#license) — **no license is currently included in this repository.**
