# Clean up directories
rm examples/lib/*
rm examples/data/*

mkdir -vp examples/lib
mkdir -vp examples/data

curl -k "https://raw.github.com/astrojs/fitsjs/master/lib/fits.js" -o 'examples/lib/fits.js'
curl -k "https://raw.github.com/toji/gl-matrix/master/dist/gl-matrix.js" -o 'examples/lib/gl-matrix.js'
curl -k "https://raw.github.com/fryn/html5slider/master/html5slider.js" -o 'examples/lib/html5slider.js'
curl -k "http://astrojs.s3.amazonaws.com/sample/L1448_13CO.fits" -o 'examples/data/L1448_13CO.fits'