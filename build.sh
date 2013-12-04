
FILES='
  core.js
  shaders.js'
  
mkdir -vp tmp
for f in $FILES
do
  sed 's/^/  /' src/$f > tmp/$f
done
cat src/start.js ${FILES//  /tmp\/} src/end.js > volumetric.js
node_modules/.bin/uglifyjs volumetric.js -o volumetric.min.js
rm -rf tmp