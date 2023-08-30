import SceneKit
import SceneKit.ModelIO

let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

func exportMesh(_ geometry: SCNGeometry, withName name:String, useTimestamp:Bool = false){
        // export geometry
        let mesh = MDLMesh(scnGeometry: geometry)
        let asset = MDLAsset()
        asset.add(mesh)
        
        let timestamp:String
        
        do{
            if useTimestamp {
                let dateFormatterGet = DateFormatter()
                dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
                timestamp = dateFormatterGet.string(from: Date())
                
                try asset.export(to: URL(fileURLWithPath:documentsPath + "/\(name)" + timestamp + ".obj"))
            }
            else {
                try asset.export(to: URL(fileURLWithPath:documentsPath + "/\(name)" + ".obj"))
            }
            print("Mesh with name \(name) exported")
        }
        catch{
            print("Can't write mesh to url")
        }
    }
