import SwiftUI

/// Adaptive layout helpers for built-in section renderers.
///
/// Explicit ``SectionConfiguration/columns`` values are always respected.
/// When columns are omitted, layout adapts to available width and Dynamic Type.
public enum HomeAdaptiveLayout {

    /// Resolves grid column count from configuration and environment.
    public static func gridColumnCount(
        configuredColumns: Int?,
        defaultColumns: Int,
        horizontalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize
    ) -> Int {
        if let configuredColumns {
            return max(configuredColumns, 1)
        }

        var count = max(defaultColumns, 1)

        if horizontalSizeClass == .regular {
            count = min(count + 2, 4)
        }

        if dynamicTypeSize.isAccessibilitySize {
            count = max(count - 1, 1)
        }

        return count
    }

    /// Minimum width for horizontally scrolling section items.
    public static func horizontalItemMinWidth(
        base: CGFloat = 160,
        dynamicTypeSize: DynamicTypeSize
    ) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? base * 1.25 : base
    }

    /// Preferred banner height that scales with Dynamic Type.
    public static func bannerHeight(dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 240 : 200
    }

    /// Preferred circular item size for category and brand chips.
    public static func circularItemSize(dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 84 : 72
    }
}

extension DynamicTypeSize {

    /// Whether the current setting is an accessibility text size.
    public var isAccessibilitySize: Bool {
        self >= .accessibility1
    }
}

extension SectionConfiguration {

    /// Whether the backend explicitly configured a column count.
    public var hasExplicitColumns: Bool {
        columns != nil
    }

    /// Adaptive grid column count using environment when columns are not explicit.
    public func adaptiveColumns(
        default defaultColumns: Int = 2,
        horizontalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize
    ) -> Int {
        HomeAdaptiveLayout.gridColumnCount(
            configuredColumns: columns,
            defaultColumns: defaultColumns,
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }
}
