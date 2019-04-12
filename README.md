# Contaminant-Cross-Prediction
2016 Summer Internship Project

GUI for glass contaminant cross prediction, part of work done at Cheyney design and development.

https://sapphire-inspection.com/cheyney-design/

## Theorum
If impurity is detected and viewed from two camera projections, its projection from the third camera can be predicted exactly, 
if only one camera projection is available,
there will be infinite numbers of positions which the contaminant can take on other camera projections.

## GUI implementation
* Project pacman is a Delphi demo used to demonstrate the cross contamination prediction algorithm
* GUI example output included in repository
* Actual code is implemented within the existing software framework at Cheyney

## Project conclusion and future work
* Achieves high theoretical accuracy and high tolerance to Type II errors
* Code in DLL can be further optimized such as using DFFT instead of image domain convolution
* Further indistrial tests should be conducted
