//
//  FocusMarker.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/07/29.
//

import Foundation
import ARKit

class FocusMarker {
    //willScanObjectMarker
    var focusMarker :SCNNode = SCNNode()
    var currentFocusMarkerPosition :SIMD3<Float> = SIMD3(Float.infinity, Float.infinity, Float.infinity)
    
    func initialize(parentNode: SCNNode) {
        let redDotGeometry = SCNSphere(radius: 0.003)
        let redDotMaterial = SCNMaterial()
        redDotMaterial.diffuse.contents = UIColor.red
        redDotGeometry.materials = [redDotMaterial]
        focusMarker.geometry = redDotGeometry
        focusMarker.isHidden = true
        //expected parentNode: sceneView.scene.rootNode
        parentNode.addChildNode(focusMarker)
    }

    func update(at position:SIMD3<Float>) {
        defer {
            currentFocusMarkerPosition = position
        }
        
        let scnPosition :SCNVector3 = SCNVector3(position)
        //hide focusMarker if nearly point are selected two-time
        let oldNewDistance = length(position - currentFocusMarkerPosition)
        if !focusMarker.isHidden && oldNewDistance <= 0.01 {
            focusMarker.isHidden = true
            return
        }
        //placeFocusMarker
        focusMarker.isHidden = false
        focusMarker.position = scnPosition
    }
}
