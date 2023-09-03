//
//  Actions.swift
//  Quasi-3D-Reconstruction
//
//  Created by nibuiro on 2023/07/29.
//

/*
クラスを管理するためのなんちゃってクラスをやめましょう。
golangのようにDIで書いていくスタイルでいきましょう。簡潔なコードに必要なシンプルさです。
果たして、利用する側にとって最適な関数名であった場合、異なるライブラリで名前が衝突することなどあり得るのでしょうか？
*/

import Foundation
import simd
import ARKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Euclid


func setupScaleMesure(sceneView: ARSCNView, referencePosition: SIMD3<Float>) -> () -> Float {
    
    guard let camera = sceneView.pointOfView else { abort() }
    
    let left = SIMD3<Float>(0.05, 0 ,0)
    
    let measure = (simd_float3(sceneView.projectPoint(SCNVector3(referencePosition))) - simd_float3(sceneView.projectPoint(SCNVector3(referencePosition + left))))
    let referenceLength = length(simd_make_float2(measure.x, measure.y))
    let referenceEulerAngles = camera.eulerAngles
    
    return {
        let rotate = camera.eulerAngles - referenceEulerAngles
        print("rotate: ", rotate)
        let R = simd_make_rotate3(x: rotate.x, y: rotate.y, z: rotate.z)
        print("rotated left", R * left)
        let measure = simd_float3(sceneView.projectPoint(SCNVector3(referencePosition))) - simd_float3(sceneView.projectPoint(SCNVector3(referencePosition + R * left)))
        let currentLength = length(simd_make_float2(measure.x, measure.y))
        
        let currentScale = currentLength / referenceLength
        return currentScale
    }
}

let deg2rad = (Float.pi * 2) / 360
/*
 ,
                                  fieldOfView: Float,
                                  explicitCenterPosition: SIMD3<Float>,
                                  useExplicitCenterPosition: Bool
 */
func makeGenerallyAccurate3dMesh(imageData :ImageData) -> SCNGeometry
{
    //let centerPosition = useExplicitCenterPosition ? explicitCenterPosition : imageData.centerPosition
    let relativePositions : [SIMD3<Float>] = convertToRelativePositions(imageData.positions, imageData.centerPosition)
    let referenceCoodinate : SIMD3<Float> = relativePositions[0]
    let referenceLength : Float = simd.length(referenceCoodinate)
    
    //let referenceFrustumHeight = 2.0 * referenceLength * tan(fieldOfView * 0.5 * deg2rad);
    
    
    let extractObjectOutlines = setupExtractObjectOutlines()
    
    //for i in 1..<imageData.nSamples {}
    
    let i = 0
    let srcImage : CIImage = imageData.images[i]
    
   // print(srcImage.extent.size.height, srcImage.extent.size.width)
    
    let outlines : [VNContoursObservation] = extractObjectOutlines(srcImage)
    let targetOutline: CGPath = selectLongestPath(observations: outlines)
    //print(targetOutline)
    //let mesh: Mesh = extrudePath(shapePath: targetOutline)
    let polygon = Mesh(SCNShape(path: UIBezierPath(cgPath: targetOutline), extrusionDepth:2.0))?.translated(by: Vector(-1,0,0))
    return SCNGeometry(polygon!)
}






