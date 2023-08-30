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
        let devicePosition : SIMD3<Float> = simd_make_float3(frame.camera.transform.columns.3)
        let timestamp : Int64 = Int64(NSDate().timeIntervalSince1970)
        
        if ((startTime + 10) < timestamp) && (timestamp < (startTime + 12)) {
            let objectCenterPositionOnScreen = sceneView.projectPoint(SCNVector3(objectCenterPosition))
            print(objectCenterPositionOnScreen)
            imageData.append(position: devicePosition, image: image, timestamp: timestamp)
            return
        }
        if ((startTime + 12) < timestamp) && dbgMem001 {
            let generated = makeGenerallyAccurate3dMesh(imageData: imageData)
            //focusMarker.focusMarker.geometry = generated
            //exportMesh(generated, withName: "generated")
            //sceneView.scene.rootNode.addChildNode(focusMarker.focusMarker)
            //focusMarker.focusMarker.scale=SCNVector3(1,1,1)
            dbgMem001 = false
        }
        
    }
}



func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first! // paths[0]
}
