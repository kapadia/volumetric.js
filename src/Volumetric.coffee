
class Volumetric
  
  
  _loadShader: (gl, source, type) ->
    
    shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    unless compiled
      lastError = gl.getShaderInfoLog(shader)
      throw "Error compiling shader #{shader}: #{lastError}"
      gl.deleteShader(shader)
      return null
    
    return shader
  
  _createProgram: (gl, vertexShader, fragmentShader) ->
    vertexShader = @_loadShader(gl, vertexShader, gl.VERTEX_SHADER)
    fragmentShader = @_loadShader(gl, fragmentShader, gl.FRAGMENT_SHADER)
    
    program = gl.createProgram()
    
    gl.attachShader(program, vertexShader)
    gl.attachShader(program, fragmentShader)
    
    gl.deleteShader(vertexShader)
    gl.deleteShader(fragmentShader)
    
    gl.linkProgram(program)
    
    linked = gl.getProgramParameter(program, gl.LINK_STATUS)
    unless linked
      throw "Error in program linking: #{gl.getProgramInfoLog(program)}"
      gl.deleteProgram(program)
      return null
    
    gl.useProgram(program)
    
    program.vertexPositionAttribute = gl.getAttribLocation(program, "aVertexPosition")
    gl.enableVertexAttribArray(program.vertexPositionAttribute)
    
    program.vertexColorAttribute = gl.getAttribLocation(program, "aVertexColor")
    gl.enableVertexAttribArray(program.vertexColorAttribute)
    
    program.uPMatrix = gl.getUniformLocation(program, "uPMatrix")
    program.uMVMatrix = gl.getUniformLocation(program, "uMVMatrix")
    
    return program
  
  _initFrameBuffer: (gl, width, height) ->
    frameBuffer = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer)
    
    frameBuffer.depthbuffer = gl.createRenderbuffer()
    gl.bindRenderbuffer(gl.RENDERBUFFER, frameBuffer.depthbuffer)
    
    gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height)
    
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, frameBuffer.depthbuffer)
    
    frameBuffer.tex = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, frameBuffer.tex)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.texImage2D( gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(4 * width * height) )
    
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, frameBuffer.tex, 0)
    
    unless gl.checkFramebufferStatus(gl.FRAMEBUFFER) is gl.FRAMEBUFFER_COMPLETE
      return null
    return frameBuffer
  
  _initCubeBuffer: (gl) ->
    cube = {}
    
    cube.vertexPositionBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, cube.vertexPositionBuffer)
    
    vertices = [
      
      # Front face
      0.0, 0.0, 1.0,
      1.0, 0.0, 1.0,
      1.0, 1.0, 1.0,
      0.0, 1.0, 1.0,
      
      # Back face
      0.0, 0.0, 0.0,
      0.0, 1.0, 0.0,
      1.0, 1.0, 0.0,
      1.0, 0.0, 0.0,
      
      # Top face
      0.0, 1.0, 0.0,
      0.0, 1.0, 1.0,
      1.0, 1.0, 1.0,
      1.0, 1.0, 0.0,
      
      # Bottom face
      0.0, 0.0, 0.0,
      1.0, 0.0, 0.0,
      1.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
      
      # Right face
      1.0, 0.0, 0.0,
      1.0, 1.0, 0.0,
      1.0, 1.0, 1.0,
      1.0, 0.0, 1.0,
      
      # Left face
      0.0, 0.0, 0.0,
      0.0, 0.0, 1.0,
      0.0, 1.0, 1.0,
      0.0, 1.0, 0.0
    
    ]
    
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW)
    cube.vertexPositionBuffer.itemSize = 3
    cube.vertexPositionBuffer.numItems = 24
    cube.vertexColorBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, cube.vertexColorBuffer)
    
    colors = [
      
      # Front face
      0.0, 0.0, 1.0, 1.0,
      1.0, 0.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      0.0, 1.0, 1.0, 1.0,
      
      # Back face
      0.0, 0.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      1.0, 1.0, 0.0, 1.0,
      1.0, 0.0, 0.0, 1.0,
      
      # Top face
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 1.0, 0.0, 1.0,
      
      # Bottom face
      0.0, 0.0, 0.0, 1.0,
      1.0, 0.0, 0.0, 1.0,
      1.0, 0.0, 1.0, 1.0,
      0.0, 0.0, 1.0, 1.0,
      
      # Right face
      1.0, 0.0, 0.0, 1.0,
      1.0, 1.0, 0.0, 1.0,
      1.0, 1.0, 1.0, 1.0,
      1.0, 0.0, 1.0, 1.0,
      
      # Left face
      0.0, 0.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,
      0.0, 1.0, 1.0, 1.0,
      0.0, 1.0, 0.0, 1.0
    
    ]
    
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW)
    cube.vertexColorBuffer.itemSize = 4
    cube.vertexColorBuffer.numItems = 24
    cube.vertexIndexBuffer = gl.createBuffer()
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube.vertexIndexBuffer)
    
    vertexIndices = [
      0, 1, 2, 0, 2, 3,       # Front face
      4, 5, 6, 4, 6, 7,       # Back face
      8, 9, 10, 8, 10, 11,    # Top face
      12, 13, 14, 12, 14, 15, # Botton face
      16, 17, 18, 16, 18, 19, # Right face
      20, 21, 22, 20, 22, 23  # Left face
    ]
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(vertexIndices), gl.STATIC_DRAW)
    cube.vertexIndexBuffer.itemSize = 1
    cube.vertexIndexBuffer.numItems = 36
    
    return cube
  
  _setMatrices: (program) ->
    @gl.uniformMatrix4fv(program.uPMatrix, false, @pMatrix)
    @gl.uniformMatrix4fv(program.uMVMatrix, false, @mvMatrix)
  
  _setRaycastUniforms: (gl) ->
    @uMinimum = gl.getUniformLocation(@programs.raycast, "uMinimum")
    @uMaximum = gl.getUniformLocation(@programs.raycast, "uMaximum")
    @uRange = gl.getUniformLocation(@programs.raycast, "uRange")
    
    @uTileWidth = gl.getUniformLocation(@programs.raycast, "uTileWidth")
    @uTileHeight = gl.getUniformLocation(@programs.raycast, "uTileHeight")
    @uDimension = gl.getUniformLocation(@programs.raycast, "uDimension")
    
    @uBackCoord = gl.getUniformLocation(@programs.raycast, "uBackCoord")
    @uVolData = gl.getUniformLocation(@programs.raycast, "uVolData")
    
    @uTiles = gl.getUniformLocation(@programs.raycast, "uTiles")
    
    @uOpacity = gl.getUniformLocation(@programs.raycast, "uOpacity")
    @uLighting = gl.getUniformLocation(@programs.raycast, "uLight")
  
  _toRadians: (deg) ->
    return deg * 0.017453292519943295
  
  _toPower2: (v) ->
    v--
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v++
    return v
  
  _setupMouseControls: ->
    
    @drag = false
    @xOldOffset = null
    @yOldOffset = null
    
    @canvas.onmousedown = (e) =>
      @drag = true
      @xOldOffset = e.clientX
      @yOldOffset = e.clientY
      
    @canvas.onmouseup = (e) =>
      @drag = false
      
    @canvas.onmousemove = (e) =>
      return unless @drag
      
      x = e.clientX
      y = e.clientY
      
      deltaX = x - @xOldOffset
      deltaY = y - @yOldOffset
      
      rotationMatrix = mat4.create()
      mat4.identity(rotationMatrix)
      mat4.rotateY(rotationMatrix, rotationMatrix, @_toRadians(deltaX / 4))
      mat4.rotateX(rotationMatrix, rotationMatrix, @_toRadians(deltaY / 4))
      mat4.multiply(@rotationMatrix, rotationMatrix, @rotationMatrix)
      
      @xOldOffset = x
      @yOldOffset = y
      
      @draw()
    
    @canvas.onmouseout = (e) =>
      @drag = false
    
    @canvas.onmouseover = (e) =>
      @drag = false
  
  constructor: (@el, dimension) ->
    
    @viewportWidth = @viewportHeight = dimension
    @programs = {}
    
    # Create and attach canvas to DOM
    @canvas = document.createElement('canvas')
    @canvas.setAttribute('width', @viewportWidth)
    @canvas.setAttribute('height', @viewportHeight)
    @canvas.setAttribute('class', 'volumetric')
    
    @el.appendChild(@canvas)
    
    # Initialize context
    for name in ['webgl', 'experimental-webgl']
      gl = @canvas.getContext(name)
      width = @canvas.width
      height = @canvas.height
      break if gl?
    return null unless gl
    
    gl.viewport(0, 0, width, height)
    @gl = gl
    
    # Get the floating point extension
    ext = gl.getExtension('OES_texture_float')
    return null unless ext
    
    shaders = @constructor.Shaders
    
    # Initialize programs from shaders
    @programs["back"] = @_createProgram(gl, shaders.vertex, shaders.fragment)
    @programs["raycast"] = @_createProgram(gl, shaders.raycastVertex, shaders.raycastFragment("70.0") )
    
    @_setRaycastUniforms(@gl)
    
    # Initialize buffers
    # TODO: Use packed buffers
    @frameBuffer = @_initFrameBuffer(gl, @viewportWidth, @viewportHeight)
    @cubeBuffer = @_initCubeBuffer(gl)
    
    # Set up camera parameters
    @zoom = 2.0
    @pMatrix = mat4.create()
    @mvMatrix = mat4.create()
    @rotationMatrix = mat4.create()
    
    mat4.perspective(@pMatrix, 45.0, 1.0, 0.1, 100.0)
    mat4.identity(@rotationMatrix)
    
    # Set defaults
    @setOpacity(2.0)
    @setLighting(0.3)
    
    @_setupMouseControls()
    
    @hasTexture = false
  
  setExtent: (@minimum, @maximum) ->
    @gl.useProgram( @programs.raycast )
    
    @gl.uniform1f(@uMinimum, @minimum)
    @gl.uniform1f(@uMaximum, @maximum)
    @gl.uniform1f(@uRange, @maximum - @minimum)
    
    @draw()
  
  # Updating steps requires rebuilding entire program since one shader value
  # is a constant. This alleviates GPU computation.
  setSteps: (steps) ->
    gl = @gl
    program = @programs.raycast
    
    # Detach and delete raycast shaders
    for shader in gl.getAttachedShaders(program)
      gl.detachShader(program, shader)
      gl.deleteShader(shader)
    
    # Delete program
    gl.deleteProgram(program)
    
    # Compile new vertex and fragment shader
    shaders = @constructor.Shaders
    @programs["raycast"] = @_createProgram(gl, shaders.raycastVertex, shaders.raycastFragment("#{steps}.0") )
    @_setRaycastUniforms(gl)
    
    gl.useProgram(@programs.raycast)
    
    gl.activeTexture(gl.TEXTURE0)
    
    gl.uniform1f(@uTiles, @depth)
    gl.uniform1f(@uTileWidth, @width)
    gl.uniform1f(@uTileHeight, @height)
    gl.uniform1f(@uDimension, @dimension)
    
    gl.uniform1f(@uMinimum, @minimum)
    gl.uniform1f(@uMaximum, @maximum)
    gl.uniform1f(@uRange, @maximum - @minimum)
    
    gl.uniform1f(@uOpacity, @opacity)
    gl.uniform1f(@uLighting, @lighting)
    
    @draw()
  
  setOpacity: (opacity) ->
    @opacity = opacity
    
    @gl.useProgram( @programs.raycast )
    @gl.uniform1f(@uOpacity, opacity)
    
    @draw()
  
  setLighting: (lighting) ->
    @lighting = lighting
    
    @gl.useProgram( @programs.raycast )
    @gl.uniform1f(@uLighting, lighting)
    
    @draw()
  
  setTexture: (arr, width, height, depth) ->
    length = arr.length
    
    dimension = Math.sqrt(length)
    dimension = @_toPower2(dimension)
    @gl.uniform1f(@uTiles, depth)
    
    # Replace NaNs here because OpenGL ES2.0 has no NaN check
    while length--
      arr[length] = if isNaN(arr[length]) then 0 else arr[length]
    
    # Create typed array with correct texture size
    pixels = new arr.constructor(dimension * dimension)
    pixels.set(arr, 0)
    
    # Send texture to GPU
    unless @hasTexture
      @gl.uniform1f(@uTileWidth, width)
      @gl.uniform1f(@uTileHeight, height)
      @gl.uniform1f(@uDimension, dimension)
      
      @texture = @gl.createTexture()
      @gl.bindTexture(@gl.TEXTURE_2D, @texture)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST)
    @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.LUMINANCE, dimension, dimension, 0, @gl.LUMINANCE, @gl.FLOAT, pixels)
    
    @gl.bindTexture(@gl.TEXTURE_2D, null)
    @hasTexture = true
    
    # TEMP: Setting variables here to test setStep program reconstruction.
    @width = width
    @height = height
    @depth = depth
    @dimension = dimension
  
  _drawCube: (program) ->
    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
    
    mat4.identity(@mvMatrix)
    mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -@zoom])
    mat4.multiply(@mvMatrix, @mvMatrix, @rotationMatrix)
    mat4.translate(@mvMatrix, @mvMatrix, [-0.5, -0.5, -0.5])
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @cubeBuffer.vertexPositionBuffer)
    @gl.vertexAttribPointer(program.vertexPositionAttribute, @cubeBuffer.vertexPositionBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @cubeBuffer.vertexColorBuffer)
    @gl.vertexAttribPointer(program.vertexColorAttribute, @cubeBuffer.vertexColorBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    
    @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, @cubeBuffer.vertexIndexBuffer)
    @_setMatrices(program)
    @gl.drawElements(@gl.TRIANGLES, @cubeBuffer.vertexIndexBuffer.numItems, @gl.UNSIGNED_SHORT, 0)
    
  draw: ->
    @gl.clearColor(0.0, 0.0, 0.0, 0.0)
    @gl.enable(@gl.DEPTH_TEST)
    
    @gl.bindFramebuffer(@gl.FRAMEBUFFER,  @frameBuffer)
    @gl.useProgram(@programs.back)
    @gl.clearDepth(-50.0)
    @gl.depthFunc(@gl.GEQUAL)
    
    @_drawCube(@programs.back)
    
    @gl.bindFramebuffer(@gl.FRAMEBUFFER, null)
    
    @gl.useProgram(@programs.raycast)
    @gl.clearDepth(50.0)
    @gl.depthFunc(@gl.LEQUAL)
    
    @gl.activeTexture(@gl.TEXTURE0)
    @gl.bindTexture(@gl.TEXTURE_2D, @frameBuffer.tex)
    
    @gl.activeTexture(@gl.TEXTURE1)
    @gl.bindTexture(@gl.TEXTURE_2D, @texture)
    
    @gl.uniform1i(@uBackCoord, 0)
    @gl.uniform1i(@uVolData, 1)
    
    @_drawCube(@programs.raycast)


@astro = {} unless @astro?
@astro.Volumetric = Volumetric
@astro.Volumetric.version = '0.2.0'