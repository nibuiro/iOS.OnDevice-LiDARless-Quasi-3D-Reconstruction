//
//  MeshClipping3.swift
//  polygonClipping
//
//  Created by user01 on 2023/09/07.
//

import Foundation
import SceneKit
import Euclid

func rigidTransform3(mesh: SCNGeometry,
                     translateX: Float, translateY: Float, translateZ: Float,
                     rotateX: Float, rotateY: Float, rotateZ: Float,
                     scaleX: Float, scaleY: Float, scaleZ: Float,
                     doClip: Bool = false,
                     minX: Float = -Float.infinity, maxX: Float = Float.infinity,
                     minY: Float = -Float.infinity, maxY: Float = Float.infinity,
                     minZ: Float = -Float.infinity, maxZ: Float = Float.infinity,
                     d: SIMD3<Float> = SIMD3<Float>()) -> SCNGeometry {
    
    assert((scaleX != 0)&&(scaleY != 0)&&(scaleZ != 0))
    var geometrySources = mesh.sources
    var src :SCNGeometrySource
    var positions: [SCNVector3] = []
    
    let R = simd_make_rotate3(x: rotateX, y: rotateY, z: rotateZ)
    
    if let vertexSource = geometrySources.first(where: { $0.semantic == .vertex }) {
        let data = vertexSource.data
        for i in 0..<data.count / MemoryLayout<SCNVector3>.stride {
            
            var vertexData = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> SCNVector3 in
                let bufferPointer = ptr.bindMemory(to: SCNVector3.self)
                return bufferPointer[i]
            }
            let transformedVertex = R * SIMD3<Float>(scaleX * vertexData.x + translateX,
                                                     scaleY * vertexData.y + translateY,
                                                     scaleZ * vertexData.z + translateZ)
            
            if doClip {
                var clampingTarget: SIMD3<Float> = transformedVertex
                
                if maxX < clampingTarget.x {
                    clampingTarget = calcPointAtTargetXOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetX: maxX)
                } else if clampingTarget.x < minX {
                    clampingTarget = calcPointAtTargetXOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetX: minX)
                }
                
                if maxY < clampingTarget.y {
                    clampingTarget = calcPointAtTargetYOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetY: maxY)
                } else if clampingTarget.y < minY {
                    clampingTarget = calcPointAtTargetYOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetY: minY)
                }
                
                if maxZ < clampingTarget.z {
                    clampingTarget = calcPointAtTargetZOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetZ: maxZ)
                } else if clampingTarget.z < minZ {
                    clampingTarget = calcPointAtTargetZOnTheLineThroughPoint03(p0: clampingTarget, v: d, targetZ: minZ)
                }
                
                let clampedVertex = SCNVector3(clampingTarget)
                vertexData = clampedVertex
            } else {
                vertexData.x = transformedVertex.x
                vertexData.y = transformedVertex.y
                vertexData.z = transformedVertex.z
            }
            
            positions.append(vertexData)
        }
    }
    
    let newData = Data(bytes: positions, count: positions.count * MemoryLayout<SCNVector3>.size)
    
    src = SCNGeometrySource(data: newData,
                            semantic: SCNGeometrySource.Semantic.vertex,
                            vectorCount: geometrySources[0].vectorCount,
                            usesFloatComponents: true,
                            componentsPerVector: geometrySources[0].componentsPerVector,
                            bytesPerComponent: geometrySources[0].bytesPerComponent,
                            dataOffset: geometrySources[0].dataOffset,
                            dataStride: geometrySources[0].dataStride)
    
    geometrySources[0] = src
    
    let scnGeometry = SCNGeometry(sources: geometrySources, elements: mesh.elements)
    return scnGeometry
}
