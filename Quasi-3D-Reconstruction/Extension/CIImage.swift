//
//  CIImage.swift
//  Quasi-3D-Reconstruction
//
//  Created by user01 on 2023/08/28.
//

import UIKit

extension CIImage {

   func resizeAffine(scaleX: CGFloat, scaleY: CGFloat) -> CIImage? {
        let matrix = CGAffineTransform(scaleX: scaleX, y: scaleY)
       return self.transformed(by: matrix)
    }
    
    func toCGImage() -> CGImage? {
        let context = { CIContext(options: nil) }()
        return context.createCGImage(self, from: self.extent)
    }
    
    func holizontalFlip() -> CIImage {
        
        // 入力画像の高さを取得します
        let inputHeight = self.extent.size.height
        
        // 垂直に反転させるための変換行列を作成します
        let transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        
        // 変換行列を適用して画像を反転させます
        let flippedImage = self.transformed(by: transform)
        
        return flippedImage
    }

    func toUIImage(orientation: UIImage.Orientation) -> UIImage? {
        guard let cgImage = self.toCGImage() else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}

import CoreImage
