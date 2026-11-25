import Foundation

/// Arc's named springs: `ARCUI.SpringAnimationStyle` (Arc 1.174.3), read from two tables of seven
/// doubles in its `__TEXT,__const` (response at 0x103725f98, damping ratio at 0x103725fd0, indexed
/// by the case in declaration order). Arc turns a style into SwiftUI's
/// `spring(response:dampingFraction:)` or into a `CASpringAnimation` with stiffness
/// (2π / response)² and damping 4π · ratio / response, mass 1. docs/arc-reverse-engineering.md,
/// "Arc's spring presets", has the addresses.
public enum ArcSpring: CaseIterable, Sendable {
    case firm, firmSlow, firmExtraSlow, firmFast, springy, springyFast, springyExtraFast

    /// Seconds for one undamped oscillation (Arc's `frequencyResponse`).
    public var response: Double {
        switch self {
        case .firm: 0.25
        case .firmSlow: 0.35
        case .firmExtraSlow: 1.25
        case .firmFast: 0.15
        case .springy: 0.28
        case .springyFast: 0.18
        case .springyExtraFast: 0.08
        }
    }

    /// 1 settles without overshoot; under 1 bounces (Arc's `dampingRatio`).
    public var dampingRatio: Double {
        switch self {
        case .firm, .firmSlow, .firmExtraSlow: 0.9
        case .firmFast: 0.95
        case .springy: 0.63
        case .springyFast, .springyExtraFast: 0.8
        }
    }

    /// Core Animation's stiffness for mass 1.
    public var stiffness: Double { pow(2 * .pi / response, 2) }
    /// Core Animation's damping for mass 1.
    public var damping: Double { 4 * .pi * dampingRatio / response }
}
