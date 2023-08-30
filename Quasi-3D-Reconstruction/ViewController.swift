//
//  ViewController.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/06/29.
//

import UIKit
import SceneKit
import ARKit
import Foundation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    //willScanObjectMarker
    var focusMarker = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true

        initFocusMarker()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func initFocusMarker() {
        let redDotGeometry = SCNSphere(radius: 0.003)
        let redDotMaterial = SCNMaterial()
        redDotMaterial.diffuse.contents = UIColor.red
        redDotGeometry.materials = [redDotMaterial]
        focusMarker.geometry = redDotGeometry  
        focusMarker.isHidden = true   
        sceneView.scene.rootNode.addChildNode(focusMarker)     
    }

    func actFocusMarker(at hitResult:ARHitTestResult) {
        let position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        //hide focusMarker if nearly point are selected two-time
        let oldNewDistance = sqrt(pow(position.x - focusMarker.position.x, 2) + pow(position.y - focusMarker.position.y, 2) + pow(position.z - focusMarker.position.z, 2))
        if !focusMarker.isHidden && oldNewDistance <= 0.01 {
            focusMarker.isHidden = true
            return
        }
        //placeFocusMarker
        focusMarker.isHidden = false
        focusMarker.position = position
    }

    // MARK: - Touch Delegates
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if currentSessionStatus != .ready {
//            print("Unable to place objects when the planes are not ready...")
//            return
//        }       
        
        if let touchedLocation = touches.first?.location(in: sceneView) {
            let hitTestResults = sceneView.hitTest(touchedLocation, types: .featurePoint)
            
            if let hitResult = hitTestResults.first {
                actFocusMarker(at: hitResult)
            }
            
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
