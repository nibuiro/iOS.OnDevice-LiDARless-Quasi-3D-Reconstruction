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
        let image : CIImage = CIImage(cvPixelBuffer: frame.capturedImage, options: [:]).oriented(.right).resizeAffine(scaleX: 0.25, scaleY: 0.4)!
        let timestamp : Int64 = Int64(NSDate().timeIntervalSince1970)
        
        let screenRect = UIScreen.main.bounds
        let screenWidth = Float(screenRect.size.width)
        let screenHeight = Float(screenRect.size.height)
        
        let objectCenterPositionOnScreen = sceneView.projectPoint(SCNVector3(objectCenterPosition))
        let normalizedObjectCenterPositionOnScreen: SIMD2<Float> = SIMD2<Float>(
            x: (Float(image.extent.size.width) / screenWidth) * (objectCenterPositionOnScreen.x) / Float(image.extent.size.width),
            y: (Float(image.extent.size.height) / screenHeight) * (objectCenterPositionOnScreen.y) / Float(image.extent.size.height)
        )
        
        let rotation = frame.camera.eulerAngles - referenceDeviceEulerAngles
        
        if nil == measureRelativeObjectScale {
            return
        }
        
        let relativeObjectScale = measureRelativeObjectScale!()
        print(relativeObjectScale)
        
        if dbgmem005 {
            var normalizedKeyPoints: [SIMD2<Float>] = []
            for i in 0..<5 {
                let objectCenterPositionOnScreen = sceneView.projectPoint(SCNVector3(focusMarkers[i].currentMarkerPosition))
                let normalizedKeypointPositionOnScreen = SIMD2<Float>(
                    x: (Float(image.extent.size.width) / screenWidth) * (objectCenterPositionOnScreen.x) / Float(image.extent.size.width),
                    y: (Float(image.extent.size.height) / screenHeight) * (objectCenterPositionOnScreen.y) / Float(image.extent.size.height)
                )
                normalizedKeyPoints.append(normalizedKeypointPositionOnScreen)
            }
            print(timestamp - startTime)
            imageData.append(
                image: image,
                centerOfObject: normalizedObjectCenterPositionOnScreen,
                keypoints: normalizedKeyPoints,
                rotation: rotation,
                scale:relativeObjectScale,
                timestamp: timestamp
            )
            dbgmem005 = false
            return
        }
        if dbgmem006 {
            //SCNPlane(width: 0.1, height: 0.1)
            let generated = makeGenerallyAccurate3dMesh(imageData: imageData)
            //exportMesh(generated, withName: "generated", useTimestamp: true)
            
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            generated.materials = [material]
            dbgmem003 = SCNNode(geometry: generated)
            dbgmem003.position = SCNVector3(x: 0, y: 0, z: -0.5)
            sceneView.scene.rootNode.addChildNode(dbgmem003)
            
            //focusMarker.focusMarker.geometry = generated
            //sceneView.scene.rootNode.addChildNode(focusMarker.focusMarker)
            //focusMarker.focusMarker.scale=SCNVector3(1,1,1)
            dbgmem006 = false
        }
        
    }
}



