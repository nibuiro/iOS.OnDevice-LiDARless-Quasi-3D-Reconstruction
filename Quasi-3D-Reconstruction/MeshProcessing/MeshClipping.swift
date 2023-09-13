//
//  MeshClipping3.swift
//  polygonClipping
//
//  Created by user01 on 2023/09/07.
//

import Foundation
import SceneKit


func clipMesh3(mesh: SCNGeometry,
               minX: Float32, maxX: Float32,
               minY: Float32, maxY: Float32,
               minZ: Float32, maxZ: Float32) -> SCNGeometry {
    var geometrySources = mesh.sources
    var src :SCNGeometrySource
    var positions: [SCNVector4] = []
    
    if let vertexSource = geometrySources.first(where: { $0.semantic == .vertex }) {
        let data = vertexSource.data
        for i in 0..<data.count / MemoryLayout<SCNVector4>.stride {
            
            var vertexData = data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> SCNVector4 in
                let bufferPointer = ptr.bindMemory(to: SCNVector4.self)
                return bufferPointer[i]
            }
            
            vertexData.x = min(max(vertexData.x, minX), maxX)
            vertexData.y = min(max(vertexData.y, minY), maxY)
            vertexData.z = min(max(vertexData.z, minZ), maxZ)
            
            positions.append(vertexData)
        }
    }
    
    let newData = Data(bytes: positions, count: positions.count * MemoryLayout<SCNVector4>.size)
    
    src = SCNGeometrySource(
        data: newData,
        semantic: SCNGeometrySource.Semantic.vertex,
        vectorCount: geometrySources[0].vectorCount,
        usesFloatComponents: true,
        componentsPerVector: geometrySources[0].componentsPerVector,
        bytesPerComponent: geometrySources[0].bytesPerComponent,
        dataOffset: geometrySources[0].dataOffset,
        dataStride: geometrySources[0].dataStride
    )
    
    geometrySources[0] = src
    
    let clippedMesh = SCNGeometry(sources: geometrySources, elements: mesh.elements)
    
    return clippedMesh
}
