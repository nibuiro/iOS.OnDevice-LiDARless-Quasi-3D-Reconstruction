# Quasi-3D-Reconstruction

## Build
1. Clone and install pods
```
git clone git@github.com:nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction.git
cd iOS.OnDevice-Quasi-3D-Reconstruction
pod install
xed .
```
2. Set Signing
3. Build

## demo
1. Recongnize plane  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/1.png?raw=true)
2. Mark top center of head  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/2.png?raw=true)
3. Mark left side  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/3.png?raw=true)
4. Mark right side  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/4.png?raw=true)
5. Capture the front side of object   
(Note: You need capture object in center of camera to suppress spherical aberration)  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/5.png?raw=true)
6. Capture the front side of object at shifted 45d position  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/6.png?raw=true)
7. Cpture the right side of object  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/7.png?raw=true)
8. Capture the upper side of object  
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/8.png?raw=true)
9. (꒪ཀ꒪)
![](https://github.com/nibuiro/iOS.OnDevice-Quasi-3D-Reconstruction/blob/planB/9.png?raw=true)

## Principle
Please let you imagine a sphere and a camera photographing it.  
The camera can get circle as a outline of sphere.   
Please place it extruded to imaginal space.  
By repeating this process more and more while aligning center of extruded object so at different camera position, overlapping space will be approximate to sphere.  
