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

/*
class binarizer: CIFilter, CIColorThreshold {
    
    var inputImage: CIImage?
    var threshold: Float
    
    init(_ inputImage: CIImage, threshold : Float)
    {
        self.inputImage = inputImage
        self.threshold = threshold
        super.init(name: "CIColorThreshold")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}*/
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
    
    print(srcImage.extent.size.height, srcImage.extent.size.width)
    
    let outlines : [VNContoursObservation] = extractObjectOutlines(srcImage)
    let targetOutline: CGPath = selectLongestPath(observations: outlines)
    print(targetOutline)
    //let mesh: Mesh = extrudePath(shapePath: targetOutline)
    let polygon = Mesh(SCNShape(path: UIBezierPath(cgPath: targetOutline), extrusionDepth:2.0))?.translated(by: Vector(-1,0,0))
    return SCNGeometry(polygon!)
}



