# Clean up directories
rm examples/lib/*
rm examples/data/*

mkdir -vp examples/lib
mkdir -vp examples/data

# TODO Register fitsjs with Bower
curl -k "https://raw.github.com/astrojs/fitsjs/master/lib/fits.js" -o 'examples/lib/fits.js'
curl -k "http://astrojs.s3.amazonaws.com/sample/L1448_13CO.fits" -o 'examples/data/L1448_13CO.fits'