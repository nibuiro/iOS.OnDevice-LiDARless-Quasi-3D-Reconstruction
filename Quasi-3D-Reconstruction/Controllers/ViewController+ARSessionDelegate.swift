//
//  ViewController+ARSessionDelegate.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/07/29.
//

import ARKit

extension ViewController: ARSessionDelegate {
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if nil == measureRelativeObjectScale {
            return
        }
        let image : CIImage = CIImage(cvPixelBuffer: frame.capturedImage, options: [:]).oriented(.leftMirrored).resizeAffine(scaleX: 0.25, scaleY: 0.4)!
        let timestamp : Int64 = Int64(NSDate().timeIntervalSince1970)
        
        let screenRect = UIScreen.main.bounds
        let screenWidth = Float(screenRect.size.width)
        let screenHeight = Float(screenRect.size.height)
        let normalizedObjectCenterPositionOnScreen: SIMD2<Float>
        
        if let objectCenterPosition: SIMD3<Float> = objectCenterPosition {
            let objectCenterPositionOnScreen = sceneView.projectPoint(SCNVector3(objectCenterPosition))
            
            normalizedObjectCenterPositionOnScreen = SIMD2<Float>(
                x: (Float(image.extent.size.width) / screenWidth) * (objectCenterPositionOnScreen.x) / Float(image.extent.size.width),
                y: (Float(image.extent.size.height) / screenHeight) * (objectCenterPositionOnScreen.y) / Float(image.extent.size.height)
            )
        } else {
            abort()
        }
        
        var rotation = frame.camera.eulerAngles// - referenceDeviceEulerAngles
        //rotation.y *= -1
        //rotation.z *= -1
        
        let relativeObjectScale = measureRelativeObjectScale!()

        if dbgmem008.obtained {
            label.text = String(format: "scale: %.2f \n x: %.2f \n y: %.2f \n z: %.2f \n C: %d", relativeObjectScale, rotation.x - (~dbgmem008).x, rotation.y - (~dbgmem008).y, rotation.z - (~dbgmem008).z, dbgmem009)
        }

        if dbgmem005 {
            var normalizedKeyPoints: [SIMD2<Float>] = []
            for i in 0..<3 {
                let objectCenterPositionOnScreen = sceneView.projectPoint(SCNVector3(focusMarkers[i].currentMarkerPosition))
                let normalizedKeypointPositionOnScreen = SIMD2<Float>(
                    x: (Float(image.extent.size.width) / screenWidth) * (objectCenterPositionOnScreen.x) / Float(image.extent.size.width),
                    y: (Float(image.extent.size.height) / screenHeight) * (objectCenterPositionOnScreen.y) / Float(image.extent.size.height)
                )
                normalizedKeyPoints.append(normalizedKeypointPositionOnScreen)
            }
            imageData.append(
                image: image,
                centerOfObject: normalizedObjectCenterPositionOnScreen,
                keypoints: normalizedKeyPoints,
                rotation: rotation,
                scale:relativeObjectScale,
                timestamp: timestamp
            )
            if !dbgmem008.obtained {
                dbgmem008 ~= simd_make_float3(rotation)
            }
            dbgmem005 = false
            dbgmem009 += 1
        }
    }
}



