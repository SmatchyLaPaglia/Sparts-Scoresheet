import Foundation
import SwiftUI
import Combine
import CoreMotion
import UIKit

// A simple enum that gives us exactly the two states we care about
enum LandscapeDirection {
    case landscapeLeft // Home button on the right
    case landscapeRight // Home button on the left
}

class OrientationManager: ObservableObject {
    
    // This is the published property your views will read.
    // It defaults to .landscapeRight as you requested.
    @Published var currentLandscapeDirection: LandscapeDirection = .landscapeRight
    
    private let motionManager = CMMotionManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupOrientationMonitoring()
    }
    
    private func setupOrientationMonitoring() {
        // 1. First, try to use UIDevice for initial state and updates.
        // This is efficient for most cases.
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateOrientationFromDevice()
            }
            .store(in: &cancellables)
        
        // Get the initial state
        updateOrientationFromDevice()
        
        // 2. For higher fidelity or if UIDevice is unreliable, use Core Motion as a backup.
        // This is particularly useful for getting continuous updates even if the interface is locked.
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 updates per second
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let motion = motion else { return }
            self?.updateOrientationFromMotion(motion)
        }
    }
    
    private func updateOrientationFromDevice() {
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .landscapeLeft:
            currentLandscapeDirection = .landscapeLeft
        case .landscapeRight:
            currentLandscapeDirection = .landscapeRight
        default:
            // For .portrait, .faceUp, etc., we don't change the landscape state.
            // It retains its last known value.
            break
        }
    }
    
    private func updateOrientationFromMotion(_ motion: CMDeviceMotion) {
        // Use the gravity vector to determine orientation.
        // This is more precise and works even if orientation lock is on.
        let gravity = motion.gravity
        
        // If the device is mostly horizontal (landscape)
        if abs(gravity.y) < abs(gravity.x) {
            if gravity.x > 0 {
                currentLandscapeDirection = .landscapeLeft
            } else {
                currentLandscapeDirection = .landscapeRight
            }
        }
        // If it's not landscape (portrait, etc.), we do nothing, maintaining the last state.
    }
    
    deinit {
        // Clean up
        motionManager.stopDeviceMotionUpdates()
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}



// MARK: - Combined Notch & Orientation View
struct SmartNotchLineView: View {
    @StateObject private var orientationManager = OrientationManager()
    @State private var safeAreaInsets: EdgeInsets = .init()
    @State private var screenWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color based on orientation (optional, for visual feedback)
                if orientationManager.currentLandscapeDirection == .landscapeRight {
                    Color.green.opacity(0.2) // Home button left, notch right
                } else {
                    Color.red.opacity(0.2) // Home button right, notch left
                }
                
                let (leftNotchPos, rightNotchPos) = NotchDetection.detectBothNotchPositions(
                    safeAreaInsets: safeAreaInsets,
                    screenWidth: geometry.size.width
                )
                
                let (leftEdgePos, rightEdgePos) = NotchDetection.detectBothPhysicalEdges(
                    screenWidth: geometry.size.width
                )
                
                let (leftColor, rightColor) = NotchDetection.getNotchIndicatorColors()
                let edgeColor = NotchDetection.getEdgeIndicatorColor()
                
                // Determine which lines to show based on orientation
                if orientationManager.currentLandscapeDirection == .landscapeRight {
                    // Home button on LEFT, notch on RIGHT
                    // Show RIGHT notch line and LEFT edge line
                    Rectangle() // Notch line (right side)
                        .fill(rightColor)
                        .frame(width: 4)
                        .position(x: rightNotchPos, y: geometry.size.height / 2)
                    
                    Rectangle() // Opposite edge line (left side)
                        .fill(edgeColor)
                        .frame(width: 4)
                        .position(x: leftEdgePos, y: geometry.size.height / 2)
                    
                } else {
                    // Home button on RIGHT, notch on LEFT
                    // Show LEFT notch line and RIGHT edge line
                    Rectangle() // Notch line (left side)
                        .fill(leftColor)
                        .frame(width: 4)
                        .position(x: leftNotchPos, y: geometry.size.height / 2)
                    
                    Rectangle() // Opposite edge line (right side)
                        .fill(edgeColor)
                        .frame(width: 4)
                        .position(x: rightEdgePos, y: geometry.size.height / 2)
                }
                
                // Debug information
                VStack {
                    Text(orientationManager.currentLandscapeDirection == .landscapeRight ?
                         "Notch: RIGHT • Home: LEFT" : "Notch: LEFT • Home: RIGHT")
                    Text("Screen: \(Int(geometry.size.width))×\(Int(geometry.size.height))")
                    Text("Safe Area: L:\(Int(safeAreaInsets.leading)) R:\(Int(safeAreaInsets.trailing))")
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .position(x: geometry.size.width / 2, y: 50)
            }
            .onAppear { updateGeometry(geometry) }
            .onChange(of: geometry.size) { _ in updateGeometry(geometry) }
        }
        .ignoresSafeArea()
    }
    
    private func updateGeometry(_ geometry: GeometryProxy) {
        safeAreaInsets = geometry.safeAreaInsets
        screenWidth = geometry.size.width
    }
}

// MARK: - Preview
struct SmartNotchLineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmartNotchLineView()
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape Left (Notch Left)")
            
            SmartNotchLineView()
                .previewInterfaceOrientation(.landscapeRight)
                .previewDisplayName("Landscape Right (Notch Right)")
        }
    }
}

// MARK: - Reusable Notch Detection Utilities (Keep this from your existing code)

struct NotchLineView: View {
    @State private var safeAreaInsets: EdgeInsets = .init()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Red background
                Color.red
                    .ignoresSafeArea()
                
                // Blue vertical line for potential left notch position
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 4)
                    .position(
                        x: detectLeftNotchPosition(safeAreaInsets: safeAreaInsets, screenWidth: geometry.size.width),
                        y: geometry.size.height / 2
                    )
                
                // Green vertical line for potential right notch position
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 4)
                    .position(
                        x: detectRightNotchPosition(safeAreaInsets: safeAreaInsets, screenWidth: geometry.size.width),
                        y: geometry.size.height / 2
                    )
                
                // Orange vertical lines at both physical edges
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 4)
                    .position(
                        x: 2, // Left physical edge
                        y: geometry.size.height / 2
                    )
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 4)
                    .position(
                        x: geometry.size.width - 2, // Right physical edge
                        y: geometry.size.height / 2
                    )
            }
            .onAppear { updateSafeAreaInsets(geometry.safeAreaInsets) }
            .onChange(of: geometry.size) { _ in updateSafeAreaInsets(geometry.safeAreaInsets) }
        }
    }
    
    // MARK: - Abstract Functions
    
    private func detectLeftNotchPosition(safeAreaInsets: EdgeInsets, screenWidth: CGFloat) -> CGFloat {
        // For landscape left: notch is on left, safeAreaInsets.leading has value
        // For landscape right: notch is on right, safeAreaInsets.leading is 0
        let leftPosition = safeAreaInsets.leading > 0 ? safeAreaInsets.leading : 44
        return leftPosition + 2
    }
    
    private func detectRightNotchPosition(safeAreaInsets: EdgeInsets, screenWidth: CGFloat) -> CGFloat {
        // For landscape left: notch is on left, safeAreaInsets.trailing is 0
        // For landscape right: notch is on right, safeAreaInsets.trailing has value
        let rightPosition = safeAreaInsets.trailing > 0 ? screenWidth - safeAreaInsets.trailing : screenWidth - 44
        return rightPosition + 2
    }
    
    private func updateSafeAreaInsets(_ insets: EdgeInsets) {
        safeAreaInsets = insets
    }
}

// Utility functions for notch detection
struct NotchDetection {
    static func detectBothNotchPositions(safeAreaInsets: EdgeInsets, screenWidth: CGFloat) -> (left: CGFloat, right: CGFloat) {
        let leftPosition = safeAreaInsets.leading > 0 ? safeAreaInsets.leading + 2 : 62 + 2
        let rightPosition = safeAreaInsets.trailing > 0 ? screenWidth - safeAreaInsets.trailing + 2 : screenWidth - 62 + 2
        return (leftPosition, rightPosition)
    }
    
    static func detectBothPhysicalEdges(screenWidth: CGFloat) -> (left: CGFloat, right: CGFloat) {
        return (2, screenWidth - 2)
    }
    
    static func getNotchIndicatorColors() -> (left: Color, right: Color) {
        return (Color.blue, Color.green)
    }
    
    static func getEdgeIndicatorColor() -> Color {
        return Color.orange
    }
}

// MARK: - OrientationManager (Keep this from your existing code)
// ... Your existing OrientationManager class goes here ...
