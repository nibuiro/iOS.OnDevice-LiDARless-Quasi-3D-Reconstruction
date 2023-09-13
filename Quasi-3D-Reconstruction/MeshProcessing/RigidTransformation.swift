//
//  MeshClipping3.swift
//  polygonClipping
//
//  Created by user01 on 2023/09/07.
//

import Foundation
import SceneKit


func rigidTransform3(mesh: SCNGeometry,
                     translateX: Float, translateY: Float, translateZ: Float,
                     rotateX: Float, rotateY: Float, rotateZ: Float,
                     scaleX: Float, scaleY: Float, scaleZ: Float,
                     minX: Float32, maxX: Float32,
                     minY: Float32, maxY: Float32,
                     minZ: Float32, maxZ: Float32,
                     translateFirst: Bool) -> SCNGeometry {
    var geometrySources = mesh.sources
    var src :SCNGeometrySource
    var positions: [SCNVector3] = []
    
    let R = simd_make_rotate3(x: rotateX, y: rotateY, z: rotateZ)
    
    var maxZ: Float = 0.0
    
    if let vertexSource = geometrySources.first(where: { $0.semantic == .vertex }) {
        let data = vertexSource.data
        for i in 0..<data.count / MemoryLayout<SCNVector3>.stride {
            
            var vertexData = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> SCNVector3 in
                let bufferPointer = ptr.bindMemory(to: SCNVector3.self)
                return bufferPointer[i]
            }
            let transformedVertex = R * SIMD3<Float>(scaleX * (vertexData.x + translateX),
                                                     scaleY * (vertexData.y + translateY),
                                                     scaleZ * (vertexData.z + translateZ))
            
            maxZ = max(maxZ, vertexData.z)
            vertexData.x = transformedVertex.x//min(max(transformedVertex.x, minX), maxX)
            vertexData.y = transformedVertex.y//min(max(transformedVertex.y, minY), maxY)
            vertexData.z = transformedVertex.z//min(max(transformedVertex.z, minZ), maxZ)
            
            positions.append(vertexData)
        }
    }
    print("maxZ: ", maxZ)
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
    
    let clippedMesh = SCNGeometry(sources: geometrySources, elements: mesh.elements)
    
    return clippedMesh
}
