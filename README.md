# volumetric.js

Volumetric is a JavaScript library to easily create scientific volumetric renderings using WebGL.  It uses raycasting as a technique to visualize depth.

Volumetric is meant to be a general tool for the scientific community, remaining agnostic to the multitude of file formats used to store .  Volumetric only requires a typed array representing the volume, and dimensions describing the volume.  Volumetric is built to handle high dynamic range images, which are common among scientific data (e.g. FITS in astronomy, GeoTIFF in geography, DICOM in medical).


# Dependencies

Volumetric only requires [`gl-matrix`](http://glmatrix.net/) by [toji](https://github.com/toji) and [sinisterchipmunk](https://github.com/sinisterchipmunk).  `gl-matrix` is used to perform matrix calculation required for the camera to navigate around the scene of the WebGL context.  Ensure that it is included in your application before initializing a Volumetric object.

    <script type="text/javascript" src="path/to/gl-matrix.js"></script>


# API

setTexture
setExtent
setSteps
draw


# References

  * http://www.intechopen.com/books/computer-graphics/volume-ray-casting-in-webgl

# TODO:

  * How to input any number of frames to generate a rendering?  Right now it is hard coded to be 100 images, tiled with 10 images on each axis.  The developer is left to input 100 frames.
  * Check for the maximum texture size and downsample if needed.
  