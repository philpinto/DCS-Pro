import Foundation

/// XYZ color space (intermediate for RGB to Lab conversion)
struct XYZColor {
    let x: Double
    let y: Double
    let z: Double
    
    /// Convert to CIELab color space
    /// Reference white: D65 illuminant (Xn=95.047, Yn=100.000, Zn=108.883)
    func toLab() -> LabColor {
        // D65 reference white point
        let xn = 95.047
        let yn = 100.000
        let zn = 108.883
        
        // Normalize by reference white
        let xr = x / xn
        let yr = y / yn
        let zr = z / zn
        
        // Apply f(t) transformation
        let epsilon = 0.008856  // (6/29)^3
        let kappa = 903.3       // (29/3)^3
        
        func f(_ t: Double) -> Double {
            if t > epsilon {
                return pow(t, 1.0/3.0)
            } else {
                return (kappa * t + 16.0) / 116.0
            }
        }
        
        let fx = f(xr)
        let fy = f(yr)
        let fz = f(zr)
        
        // Calculate Lab values
        let l = 116.0 * fy - 16.0
        let a = 500.0 * (fx - fy)
        let b = 200.0 * (fy - fz)
        
        return LabColor(l: l, a: a, b: b)
    }
}
