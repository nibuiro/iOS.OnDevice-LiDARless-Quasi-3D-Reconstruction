//
//  ViewController.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/06/29.
//

import UIKit
import SceneKit
import ARKit
import Foundation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    let focusMarker : FocusMarker = FocusMarker()
    let imageData : ImageData = ImageData()
    var objectCenterPosition :SIMD3<Float> = SIMD3<Float>(0,0,0)
    let startTime: Int64 = Int64(NSDate().timeIntervalSince1970)
    
    var dbgMem001 = true
    var dbgMeM002: Int64 = Int64(NSDate().timeIntervalSince1970)
    
    var visonRequest: VNCoreMLRequest?
    var arPlaneAnchorPosition :SIMD3<Float> = SIMD3(0,0,0)
    var isARPlaneAnchorPositionObtained: Bool = false
    
    var measureRelativeObjectScale: (() -> Float)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        focusMarker.initialize(parentNode: sceneView.scene.rootNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // 平面の検出を有効化する
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - Touch Delegates
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if currentSessionStatus != .ready {
//            print("Unable to place objects when the planes are not ready...")
//            return
//        }
        var isTouchedPositionObtained :Bool = false
        var touchedPosition :SIMD3<Float> = SIMD3(0, 0, 0)
        
        if let touchedLocation = touches.first?.location(in: sceneView) {
            guard let query = sceneView.raycastQuery(from: touchedLocation, allowing: .estimatedPlane, alignment: .any) else { return }
            let results = sceneView.session.raycast(query)
            if let hitTestResult = results.first {
                isTouchedPositionObtained = true
                touchedPosition = simd_make_float3(hitTestResult.worldTransform.columns.3)
                //print(touchedPosition)
            }
            
        }
        
        if isTouchedPositionObtained {
            focusMarker.update(at: touchedPosition)
        }
        
        if isTouchedPositionObtained && isARPlaneAnchorPositionObtained {
            objectCenterPosition = SIMD3<Float>(
                touchedPosition.x,
                //plane+(tap-plane)/2
                arPlaneAnchorPosition.y + (touchedPosition.y - arPlaneAnchorPosition.y) / 2, 
                touchedPosition.z
            )
            measureRelativeObjectScale = setupScaleMesure(sceneView: sceneView, referencePosition: objectCenterPosition)
            //print("objectCenterPosition: ", objectCenterPosition)
        }

        
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        if 2 > (Int64(NSDate().timeIntervalSince1970) - dbgMeM002) {
            return
        }
        dbgMeM002 = Int64(NSDate().timeIntervalSince1970)
        if let planeAnchor = anchor as? ARPlaneAnchor {
            //World coordinates of ARPlaneAnchor
            self.arPlaneAnchorPosition = simd_make_float3(anchor.transform.columns.3) + simd_make_float3(planeAnchor.center)
            self.isARPlaneAnchorPositionObtained = true
            //print(self.arPlaneAnchorPosition, simd_make_float3(anchor.transform.columns.3), simd_make_float3(planeAnchor.center))
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
