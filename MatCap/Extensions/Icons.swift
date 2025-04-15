//
//  EnhancedPhotos.swift
//  Shapes
//
//  Created by Treata Norouzi on 3/7/23.
//

import SwiftUI

struct EnhacedPhotosIcon: View {
    @State static var angle: Array<Angle> = [
        .a0, .a45, .a90, .degrees(135), .a180, .degrees(225), .a270, .degrees(315)
    ]
//    @State var angle0: Angle = .a0
//    @State var angle1: Angle = .a45
//    @State var angle2: Angle = .a90
//    @State var angle3: Angle = .degrees(135)
//    @State var angle4: Angle = .a180
//    @State var angle5: Angle = .degrees(225)
//    @State var angle6: Angle = .a270
//    @State var angle7: Angle = .degrees(315)
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                var precededIndices = index
                Shape.capsules[index]
                    .onAppear() {
                        while precededIndices >= 0 {
                            withAnimation(dealAnimation(for: Shape.capsules[index], index: Shape.capsules[index].id)) {
                                EnhacedPhotosIcon.angle[precededIndices] += .a45
//                                Shape.capsules[precededIndices].rotation += .a45
                                    precededIndices -= 1
                            }
                        }
                    }
            }
        }
        .scaledToFit()
//        .padding()
//        .scaleEffect(0.7)
    }
    
    func dealAnimation(for shape: any View, index: Int) -> Animation {
        var delay = 0.0
        delay = Double(index * (AnimationConstats.totalDealDuration / 8))
        return Animation.easeInOut(duration: Double(AnimationConstats.dealDuration))
            .repeatForever(autoreverses: false)
            .delay(delay)
    }
    
    private struct Shape {
        static var capsules = [
            RotatedCapsule(id: 0, color: ColorConstants.colors[0], rotation: angle[0]),
            RotatedCapsule(id: 1, color: ColorConstants.colors[1], rotation: angle[1]),
            RotatedCapsule(id: 2, color: ColorConstants.colors[2], rotation: angle[2]),
            RotatedCapsule(id: 3, color: ColorConstants.colors[3], rotation: angle[3]),
            RotatedCapsule(id: 4, color: ColorConstants.colors[4], rotation: angle[4]),
            RotatedCapsule(id: 5, color: ColorConstants.colors[5], rotation: angle[5]),
            RotatedCapsule(id: 6, color: ColorConstants.colors[6], rotation: angle[6]),
            RotatedCapsule(id: 7, color: ColorConstants.colors[7], rotation: angle[7]),
        ]
    }
}

private struct RotatedCapsule: View, Identifiable {
    let id: Int
    let color: Color
    var rotation: Angle
    
    var animatableData: Angle {
        get { rotation }
        set { rotation = newValue }
    }
    
    var body: some View {
        NegarinCapsule()
            .rotationEffect(rotation, anchor: .center)
            .foregroundColor(color)
    }
}

private struct ColorConstants {
    static let colors = [
        Color(.orange),
        Color(.yellow),
        Color(.green),
        Color(red: 1 / 255, green: 50 / 255, blue: 32 / 255),
        Color(red: 40 / 255, green: 110 / 255, blue: 255 / 255),
        Color(red: 75 / 255, green: 1 / 255, blue: 128 / 255),
        Color(.systemPink),
        Color(.red)
    ]
}

private struct AnimationConstats {
    static let dealDuration = 0.5
    static let totalDealDuration = 4
}

struct EnhancedPhotos_Previews: PreviewProvider {
    static var previews: some View {
        EnhacedPhotosIcon()
    }
}

// MARK: -
extension Angle {
    /// Degrees
    static let a0 = Angle(degrees: 0)
    static let a45 = Angle(degrees: 45)
    static let a90 = Angle(degrees: 90)
    static let a180 = Angle(degrees: 180)
    static let a270 = Angle(degrees: 270)
    static let a360 = Angle(degrees: 360)
    ///Radians
    static let π = Angle(radians: .pi)
    static let r0 = Angle(radians: 0)
}

// MARK: - Vivid Capsule

private struct CapsuleParameters {
    static let α = CGPoint(x: 109, y: 26)
    static let β = CGPoint(x: 109, y: 52)
    static let γ = CGPoint(x: 57, y: 52)
    static let δ = CGPoint(x: 57, y: 26)
}

private struct NegarinCapsule: View {   // Negarin is the translation of Vivid in Persian
   
    // MARK: - ToDo
    // Use rainbowColor for ForEaching through
    // indecies in Photos.swift to make the
    // code much cleaner and easier to read.
///    static var rainbowColor = Color(red: 240 / 255, green: 175 / 255, blue: 80 / 255)
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height) / 166
            let height = width
        
            Path { path in
                path.move(to: CGPoint(
                    x: CapsuleParameters.α.x * width,
                    y: CapsuleParameters.α.y * height)
                )
                path.addLine(to: CGPoint(
                    x: CapsuleParameters.β.x * width,
                    y: CapsuleParameters.β.y * height)
                )
                path.addArc(
                    center: CGPoint(x: 83 * width, y: 52 * height),
                    radius: 26 * width,
                    startAngle: .degrees(0),
                    endAngle: .a180,
                    clockwise: false
                )
                path.addLine(to: CGPoint(
                    x: CapsuleParameters.δ.x * width,
                    y: CapsuleParameters.δ.y * height)
                )
                path.addArc(
                    center: CGPoint(x: 83 * width, y: 26 * height),
                    radius: 26 * width,
                    startAngle: .a180,
                    endAngle: .degrees(0),
                    clockwise: false
                )
            }
//            .fill(Self.rainbowColor)
        }
        .opacity(0.55)
        .shadow(radius: 12)
//        .saturation(1.12)
//        .contrast(1.1)
    }
}

struct NegarinCapsule_Previews: PreviewProvider {
    static var previews: some View {
        NegarinCapsule()
    }
}



// MARK: - Camera -

private struct CameraShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.41*width, y: 0.245*height))
        path.addLine(to: CGPoint(x: 0.59*width, y: 0.245*height))
        path.addCurve(to: CGPoint(x: 0.626*width, y: 0.263*height), control1: CGPoint(x: 0.602*width, y: 0.245*height), control2: CGPoint(x: 0.619*width, y: 0.253*height))
        path.addLine(to: CGPoint(x: 0.676*width, y: 0.336*height))
        path.addCurve(to: CGPoint(x: 0.697*width, y: 0.347*height), control1: CGPoint(x: 0.681*width, y: 0.343*height), control2: CGPoint(x: 0.689*width, y: 0.347*height))
        path.addLine(to: CGPoint(x: 0.804*width, y: 0.347*height))
        path.addCurve(to: CGPoint(x: 0.849*width, y: 0.392*height), control1: CGPoint(x: 0.829*width, y: 0.347*height), control2: CGPoint(x: 0.849*width, y: 0.367*height))
        path.addLine(to: CGPoint(x: 0.849*width, y: 0.722*height))
        path.addCurve(to: CGPoint(x: 0.804*width, y: 0.767*height), control1: CGPoint(x: 0.849*width, y: 0.747*height), control2: CGPoint(x: 0.829*width, y: 0.767*height))
        path.addLine(to: CGPoint(x: 0.196*width, y: 0.767*height))
        path.addCurve(to: CGPoint(x: 0.151*width, y: 0.722*height), control1: CGPoint(x: 0.171*width, y: 0.767*height), control2: CGPoint(x: 0.151*width, y: 0.747*height))
        path.addLine(to: CGPoint(x: 0.151*width, y: 0.392*height))
        path.addCurve(to: CGPoint(x: 0.196*width, y: 0.347*height), control1: CGPoint(x: 0.151*width, y: 0.367*height), control2: CGPoint(x: 0.171*width, y: 0.347*height))
        path.addLine(to: CGPoint(x: 0.303*width, y: 0.347*height))
        path.addCurve(to: CGPoint(x: 0.324*width, y: 0.336*height), control1: CGPoint(x: 0.311*width, y: 0.347*height), control2: CGPoint(x: 0.319*width, y: 0.343*height))
        path.addLine(to: CGPoint(x: 0.374*width, y: 0.263*height))
        path.addCurve(to: CGPoint(x: 0.41*width, y: 0.245*height), control1: CGPoint(x: 0.381*width, y: 0.253*height), control2: CGPoint(x: 0.397*width, y: 0.245*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.669*width, y: 0.405*height))
        path.addCurve(to: CGPoint(x: 0.692*width, y: 0.428*height), control1: CGPoint(x: 0.669*width, y: 0.418*height), control2: CGPoint(x: 0.679*width, y: 0.428*height))
        path.addCurve(to: CGPoint(x: 0.715*width, y: 0.405*height), control1: CGPoint(x: 0.704*width, y: 0.428*height), control2: CGPoint(x: 0.715*width, y: 0.418*height))
        path.addCurve(to: CGPoint(x: 0.692*width, y: 0.382*height), control1: CGPoint(x: 0.715*width, y: 0.392*height), control2: CGPoint(x: 0.705*width, y: 0.382*height))
        path.addCurve(to: CGPoint(x: 0.669*width, y: 0.405*height), control1: CGPoint(x: 0.679*width, y: 0.382*height), control2: CGPoint(x: 0.669*width, y: 0.392*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.342*width, y: 0.553*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.712*height), control1: CGPoint(x: 0.342*width, y: 0.641*height), control2: CGPoint(x: 0.413*width, y: 0.712*height))
        path.addCurve(to: CGPoint(x: 0.658*width, y: 0.553*height), control1: CGPoint(x: 0.587*width, y: 0.712*height), control2: CGPoint(x: 0.658*width, y: 0.641*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.394*height), control1: CGPoint(x: 0.658*width, y: 0.465*height), control2: CGPoint(x: 0.587*width, y: 0.394*height))
        path.addCurve(to: CGPoint(x: 0.342*width, y: 0.553*height), control1: CGPoint(x: 0.413*width, y: 0.394*height), control2: CGPoint(x: 0.342*width, y: 0.465*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.218*width, y: 0.268*height))
        path.addLine(to: CGPoint(x: 0.263*width, y: 0.268*height))
        path.addCurve(to: CGPoint(x: 0.285*width, y: 0.291*height), control1: CGPoint(x: 0.275*width, y: 0.268*height), control2: CGPoint(x: 0.285*width, y: 0.278*height))
        path.addLine(to: CGPoint(x: 0.285*width, y: 0.314*height))
        path.addLine(to: CGPoint(x: 0.195*width, y: 0.314*height))
        path.addLine(to: CGPoint(x: 0.195*width, y: 0.291*height))
        path.addCurve(to: CGPoint(x: 0.218*width, y: 0.268*height), control1: CGPoint(x: 0.196*width, y: 0.278*height), control2: CGPoint(x: 0.206*width, y: 0.268*height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.376*width, y: 0.553*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.428*height), control1: CGPoint(x: 0.376*width, y: 0.484*height), control2: CGPoint(x: 0.431*width, y: 0.428*height))
        path.addCurve(to: CGPoint(x: 0.624*width, y: 0.553*height), control1: CGPoint(x: 0.569*width, y: 0.428*height), control2: CGPoint(x: 0.624*width, y: 0.484*height))
        path.addCurve(to: CGPoint(x: 0.5*width, y: 0.678*height), control1: CGPoint(x: 0.624*width, y: 0.622*height), control2: CGPoint(x: 0.569*width, y: 0.678*height))
        path.addCurve(to: CGPoint(x: 0.376*width, y: 0.553*height), control1: CGPoint(x: 0.431*width, y: 0.678*height), control2: CGPoint(x: 0.376*width, y: 0.622*height))
        path.closeSubpath()
        
        return path
    }
}

struct CameraIcon: View {
    var cornerRadius: CGFloat = 64
    
    var body: some View {
        CameraShape()
            .scaledToFit()
            .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
            .shadow(radius: 12)
            .background {
                LinearGradient(
                    colors: [Color(red: 0.88, green: 0.88, blue: 0.88),
                             Color(red: 0.57, green: 0.57, blue: 0.57)],
                    startPoint: .top, endPoint: .bottom
                )
                    .clipShape(.rect(cornerRadius: cornerRadius))
            }
    }
}

#Preview("Camera Icon") { CameraIcon().scaledToFit() }
 
