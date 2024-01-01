//
//  VoxelOperation.metal
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/09/25.
//

#include <metal_stdlib>
using namespace metal;


kernel void testFunction(device float* outputData [[ buffer(0) ]],
                         const device float *xs [[ buffer(1) ]],
                         const device float *ys [[ buffer(2) ]],
                         const device float *zs [[ buffer(3) ]],
                         uint gid [[thread_position_in_grid]] // Gridにおけるthreadの位置
) {
    int targetIndex = xs[gid] + 512 * ys[gid] + 262144 * zs[gid];
    outputData[targetIndex] += 1;
}
