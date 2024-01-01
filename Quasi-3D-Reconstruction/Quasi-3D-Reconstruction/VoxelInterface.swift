//
//  VoxelInterface.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/25.
//

import Foundation
import SceneKit
import SceneKit.ModelIO

func geometryToVoxelIndices(inp: SCNGeometry) -> (x: [Int32], y: [Int32], z: [Int32]) {
    let mesh = MDLMesh(scnGeometry: inp)
    let asset = MDLAsset()
    asset.add(mesh)
    let voxelArray = MDLVoxelArray(asset: asset, divisions: 42, patchRadius: 0)
    //64: 683
    //32: 341
    //24: 162
    let data = voxelArray.voxelIndices()
    var xs: [Int32] = []
    var ys: [Int32] = []
    var zs: [Int32] = []
    //print(data!.count)
    var counter = 0
    var maxIndex: Int32 = 0
    // データをSCNVector3の配列に変換
    for i in 0..<data!.count / MemoryLayout<vector_int3>.stride {

        let vertexData = data!.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) ->vector_int3 in
            let bufferPointer = ptr.bindMemory(to: vector_int3.self)
            return bufferPointer[i]
        }
        counter += 1
        //print(vertexData, counter)
        let maxCoordinate = max(max(abs(vertexData.x), abs(vertexData.y)), abs(vertexData.z))
        if 256 <= maxCoordinate { continue }
        maxIndex = max(maxCoordinate, maxIndex)
        xs.append(vertexData.x)
        ys.append(vertexData.y)
        zs.append(vertexData.z)
    }
    print("geometryToVoxelIndices(): ", powf(Float(counter), 1/3))
    print("maxIndex: ",  maxIndex)
    
    return (x: xs, y: ys, z: zs)
}
