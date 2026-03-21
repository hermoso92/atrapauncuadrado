import CoreGraphics

extension CGVector {
    static var randomUnit: CGVector {
        let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
        return CGVector(dx: cos(angle), dy: sin(angle))
    }

    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    var normalized: CGVector {
        let value = magnitude
        guard value > 0 else {
            return .zero
        }
        return CGVector(dx: dx / value, dy: dy / value)
    }

    func scaled(by scalar: CGFloat) -> CGVector {
        CGVector(dx: dx * scalar, dy: dy * scalar)
    }

    func clampedMagnitude(max: CGFloat) -> CGVector {
        guard magnitude > max else {
            return self
        }
        return normalized.scaled(by: max)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
}
