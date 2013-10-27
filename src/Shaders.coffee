
Shaders =
  
  vertex: [
    "precision mediump float;"
    
    "attribute vec3 aVertexPosition;"
    "attribute vec4 aVertexColor;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "varying vec4 backColor;"
    
    "void main() {"
      "vec4 position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);"
      "backColor = aVertexColor;"
      "gl_Position = position;"
    "}"
  ].join("\n")
  
  fragment: [
    "precision mediump float;"
    "varying vec4 backColor;"
    
    "void main() {"
      "gl_FragColor = backColor;"
    "}"
  ].join("\n")
  
  raycastVertex: [
    "precision mediump float;"
    
    "attribute vec3 aVertexPosition;"
    "attribute vec4 aVertexColor;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "varying vec4 frontColor;"
    "varying vec4 position;"
    
    "void main() {"
      "position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);"
      "frontColor = aVertexColor;"
      "gl_Position = position;"
    "}"
  ].join("\n")
  
  raycastFragment: (STEPS) ->
    [
      "precision highp float;"
      
      "varying vec4 frontColor;"
      "varying vec4 position;"
      
      "uniform sampler2D uBackCoord;"
      "uniform sampler2D uVolData;"
      
      "uniform float uMinimum;"
      "uniform float uMaximum;"
      "uniform float uRange;"
      
      "uniform float uTiles;"
      "uniform float uTileWidth;"
      "uniform float uTileHeight;"
      "uniform float uDimension;" # TODO: this might be stored on texture
      
      "uniform float uOpacity;"
      "uniform float uLight;"
      
      "const float MAXSTEPS = #{STEPS};"
      
      "float getTextureValue(vec3 volumePosition) {"
        "vec2 texturePosition1;"
        "vec2 texturePosition2;"
        
        # Get volume pixel coordinates
        "float zp1 = floor(volumePosition.z * uTiles);"
        "float zp2 = zp1 + 1.0;"
        
        "float xp = floor(uTileWidth * volumePosition.x);"
        "float yp = floor(uTileHeight * volumePosition.y);"
        
        # Get 1D array index
        "float index1 = zp1 * uTileWidth * uTileHeight + yp * uTileWidth + xp;"
        "float index2 = zp2 * uTileWidth * uTileHeight + yp * uTileWidth + xp;"
        
        # Get 2D pixel texture coordinates
        "float xt1 = mod(index1, uDimension);"
        "float yt1 = floor(index1 / uDimension);"
        
        "float xt2 = mod(index2, uDimension);"
        "float yt2 = floor(index2 / uDimension);"
        
        # Get normalized 2D texture coordinates
        "texturePosition1.x = xt1 / uDimension;"
        "texturePosition1.y = yt1 / uDimension;"
        
        "texturePosition2.x = xt2 / uDimension;"
        "texturePosition2.y = yt2 / uDimension;"
        
        # Get texture values
        "float value1 = texture2D(uVolData, texturePosition1).x;"
        "float value2 = texture2D(uVolData, texturePosition2).x;"
        
        # Scale pixels
        "value1 = (value1 - uMinimum) / uRange;"
        "value2 = (value2 - uMinimum) / uRange;"
        
        # Interpolate value
        "return mix( value1, value2, (volumePosition.z * uTiles) - zp1 );"
      "}"
      
      "void main() {"
        "vec2 textureCoord = position.xy / position.w;"
        
        "textureCoord.x = 0.5 * textureCoord.x + 0.5;"
        "textureCoord.y = 0.5 * textureCoord.y + 0.5;"
        
        "vec4 backColor = texture2D(uBackCoord, textureCoord);"
        
        "vec3 color = backColor.rgb - frontColor.rgb;"
        "vec4 vpos = frontColor;"
        
        "vec3 step = color / MAXSTEPS;"
        
        "vec4 accum = vec4(0.0, 0.0, 0.0, 0.0);"
        "vec4 sample = vec4(0.0, 0.0, 0.0, 0.0);"
        "vec4 value = vec4(0.0, 0.0, 0.0, 0.0);"
        
        "vec2 transferPosition;"
        
        "for(float i = 0.0; i < MAXSTEPS; i += 1.0) {"
          
          "transferPosition.x = getTextureValue(vpos.xyz);"
          "transferPosition.y = 0.5;"
          
          "value = vec4(transferPosition.x);"
          
          "sample.a = value.a * uOpacity * (1.0 / MAXSTEPS);"
          "sample.rgb = value.rgb * sample.a * uLight;"
          
          "accum.rgb += (1.0 - accum.a) * sample.rgb;"
          "accum.a += sample.a;"
          
          "vpos.xyz += step;"
          
          "if (vpos.x > 1.0 || vpos.y > 1.0 || vpos.z > 1.0 || accum.a >= 1.0)"
            "break;"
        "}"
        
        "gl_FragColor = accum;"
        
      "}"
    ].join("\n")


@astro.Volumetric.Shaders = Shaders
