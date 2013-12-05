volumetric.prototype.loadShader = function(source, type) {
  var gl, shader, compiled, error;
  
  gl = this.gl;
  
  shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  
  compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  if (!compiled) {
    gl.deleteShader(shader);
    error = gl.getShaderInfoLog(shader);
    throw "Error compiling shader " + shader + ": " + error;
    return null;
  }
  
  return shader;
};

volumetric.prototype.createProgram = function(vertexShader, fragmentShader) {
  var gl, linked, program;
  
  gl = this.gl;
  
  program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  
  linked = gl.getProgramParameter(program, gl.LINK_STATUS);
  if (!linked) {
    gl.deleteProgram(program);
    throw "Error in program linking: " + (gl.getProgramInfoLog(program));
    return null;
  }
  
  program.vertexPositionAttribute = gl.getAttribLocation(program, "aVertexPosition")
  gl.enableVertexAttribArray(program.vertexPositionAttribute)

  program.vertexColorAttribute = gl.getAttribLocation(program, "aVertexColor")
  gl.enableVertexAttribArray(program.vertexColorAttribute)

  program.uPMatrix = gl.getUniformLocation(program, "uPMatrix")
  program.uMVMatrix = gl.getUniformLocation(program, "uMVMatrix")
  
  return program;
};

volumetric.prototype.initializeFrameBuffer = function(width, height) {
  var gl, frameBuffer;
  
  gl = this.gl;
  
  frameBuffer = gl.createFramebuffer();
  gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
  frameBuffer.depthbuffer = gl.createRenderbuffer();
  gl.bindRenderbuffer(gl.RENDERBUFFER, frameBuffer.depthbuffer);
  gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);
  gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, frameBuffer.depthbuffer);
  
  frameBuffer.texture = gl.createTexture();
  
  gl.bindTexture(gl.TEXTURE_2D, frameBuffer.texture);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(4 * width * height));
  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, frameBuffer.texture, 0);
  
  this.frameBuffer = frameBuffer;
  return (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) ? false : true;
};

volumetric.prototype.initializeCubeBuffer = function() {
  var gl, cubeBuffer, positionVertices, colorVerticies, indexVertices;
  
  gl = this.gl;
  cubeBuffer = {};
  
  // Vertex Position Buffer
  cubeBuffer.vertexPositionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, cubeBuffer.vertexPositionBuffer);
  positionVertices = new Float32Array([
    // Front face
    0.0, 0.0, 1.0,
    1.0, 0.0, 1.0,
    1.0, 1.0, 1.0,
    0.0, 1.0, 1.0,
    
    // Back face
    0.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    1.0, 1.0, 0.0,
    1.0, 0.0, 0.0,
    
    // Top face
    0.0, 1.0, 0.0,
    0.0, 1.0, 1.0,
    1.0, 1.0, 1.0,
    1.0, 1.0, 0.0,
    
    // Bottom face
    0.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    1.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    
    // Right face
    1.0, 0.0, 0.0,
    1.0, 1.0, 0.0,
    1.0, 1.0, 1.0,
    1.0, 0.0, 1.0,
    
    // Left face
    0.0, 0.0, 0.0,
    0.0, 0.0, 1.0,
    0.0, 1.0, 1.0,
    0.0, 1.0, 0.0
  ]);
  gl.bufferData(gl.ARRAY_BUFFER, positionVertices, gl.STATIC_DRAW);
  cubeBuffer.vertexPositionBuffer.itemSize = 3;
  cubeBuffer.vertexPositionBuffer.numItems = 24;
  
  // Vertex Color Buffers
  cubeBuffer.vertexColorBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, cubeBuffer.vertexColorBuffer);
  colorVerticies = new Float32Array([
    // Front face
    0.0, 0.0, 1.0, 1.0,
    1.0, 0.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    0.0, 1.0, 1.0, 1.0,
    
    // Back face
    0.0, 0.0, 0.0, 1.0,
    0.0, 1.0, 0.0, 1.0,
    1.0, 1.0, 0.0, 1.0,
    1.0, 0.0, 0.0, 1.0,
    
    // Top face
    0.0, 1.0, 0.0, 1.0,
    0.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 1.0, 0.0, 1.0,
    
    // Bottom face
    0.0, 0.0, 0.0, 1.0,
    1.0, 0.0, 0.0, 1.0,
    1.0, 0.0, 1.0, 1.0,
    0.0, 0.0, 1.0, 1.0,
    
    // Right face
    1.0, 0.0, 0.0, 1.0,
    1.0, 1.0, 0.0, 1.0,
    1.0, 1.0, 1.0, 1.0,
    1.0, 0.0, 1.0, 1.0,
    
    // Left face
    0.0, 0.0, 0.0, 1.0,
    0.0, 0.0, 1.0, 1.0,
    0.0, 1.0, 1.0, 1.0,
    0.0, 1.0, 0.0, 1.0
  ]);
  gl.bufferData(gl.ARRAY_BUFFER, colorVerticies, gl.STATIC_DRAW);
  cubeBuffer.vertexColorBuffer.itemSize = 4;
  cubeBuffer.vertexColorBuffer.numItems = 24;
  
  // Vertex Index Buffer
  cubeBuffer.vertexIndexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, cubeBuffer.vertexIndexBuffer);
  // TODO: Try using a Uint8Array
  indexVertices = new Uint16Array([
    0, 1, 2, 0, 2, 3,       // Front face
    4, 5, 6, 4, 6, 7,       // Back face
    8, 9, 10, 8, 10, 11,    // Top face
    12, 13, 14, 12, 14, 15, // Bottom face
    16, 17, 18, 16, 18, 19, // Right face
    20, 21, 22, 20, 22, 23  // Left face
  ]);
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexVertices, gl.STATIC_DRAW);
  cubeBuffer.vertexIndexBuffer.itemSize = 1;
  cubeBuffer.vertexIndexBuffer.numItems = 36;
  
  // TODO: Check initialization status of buffers
  this.cubeBuffer = cubeBuffer;
};

// TODO: Restructure storage of uniforms when new GL programs are added.

volumetric.prototype.setMatrixUniforms = function(program) {
  this.gl.uniformMatrix4fv(program.uPMatrix, false, this.pMatrix);
  this.gl.uniformMatrix4fv(program.uMVMatrix, false, this.mvMatrix);
};

volumetric.prototype.getRaycastUniforms = function() {
  var gl = this.gl;
  
  this.uMinimum = gl.getUniformLocation(this.programs.raycast, "uMinimum");
  this.uMaximum = gl.getUniformLocation(this.programs.raycast, "uMaximum");
  this.uRange = gl.getUniformLocation(this.programs.raycast, "uRange");
  
  this.uTileWidth = gl.getUniformLocation(this.programs.raycast, "uTileWidth");
  this.uTileHeight = gl.getUniformLocation(this.programs.raycast, "uTileHeight");
  this.uDimension = gl.getUniformLocation(this.programs.raycast, "uDimension");
  this.uTiles = gl.getUniformLocation(this.programs.raycast, "uTiles");
  
  this.uBackCoord = gl.getUniformLocation(this.programs.raycast, "uBackCoord");
  this.uVolData = gl.getUniformLocation(this.programs.raycast, "uVolData");
  
  this.uOpacity = gl.getUniformLocation(this.programs.raycast, "uOpacity");
  this.uLighting = gl.getUniformLocation(this.programs.raycast, "uLight");
};

volumetric.prototype.toRadians = function(deg) {
  return deg * 0.017453292519943295;
};

volumetric.prototype.toPower2 = function(v) {
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  return v++;
};

volumetric.prototype.setupControls = function() {
  var target = this;
  
  this.drag = false;
  this.xOldOffset = null;
  this.yOldOffset = null;
  
  this.canvas.onmousedown = function(e) {
    target.drag = true;
    target.xOldOffset = e.clientX;
    target.yOldOffset = e.clientY;
  };
  
  this.canvas.onmouseup = function() {
    target.drag = false;
  };
  
  this.canvas.onmousemove = function(e) {
    var x, y, dx, dy, rotationMatrix;
    
    if (!target.drag) return;
    
    x = e.clientX, y = e.clientY;
    dx = x - target.xOldOffset, dy = y - target.yOldOffset;
    
    rotationMatrix = mat4.create();
    mat4.identity(rotationMatrix);
    mat4.rotateY(rotationMatrix, rotationMatrix, target.toRadians(dx / 4));
    mat4.rotateX(rotationMatrix, rotationMatrix, target.toRadians(dy / 4));
    
    mat4.multiply(target.rotationMatrix, rotationMatrix, target.rotationMatrix);
    target.xOldOffset = x;
    target.yOldOffset = y;
    target.draw();
  };
  
  this.canvas.onmouseout = function() {
    target.drag = false;
  };
  
  this.canvas.onmouseover = function() {
    target.drag = false;
  };
};

function volumetric(el, dimension) {
  var ext, shaders, vertexShader, fragmentShader, raycastVertexShader, raycastFragmentShader;
  
  this.el = el;
  this.canvas = document.createElement('canvas');
  this.canvas.setAttribute('width', dimension);
  this.canvas.setAttribute('height', dimension);
  this.canvas.setAttribute('class', 'volumetric');
  this.el.appendChild(this.canvas);
  
  this.gl = this.canvas.getContext('webgl') || this.canvas.getContext('experimental-webgl');
  if (!this.gl) return false;
  
  ext = this.gl.getExtension('OES_texture_float');
  if (!ext) return false;
  
  this.viewportWidth = this.viewportHeight = dimension;
  this.gl.viewport(0, 0, dimension, dimension);
  
  shaders = volumetric.shaders;
  
  vertexShader = this.loadShader(volumetric.shaders.vertex, this.gl.VERTEX_SHADER);
  fragmentShader = this.loadShader(volumetric.shaders.fragment, this.gl.FRAGMENT_SHADER);
  raycastVertexShader = this.loadShader(volumetric.shaders.raycastVertex, this.gl.VERTEX_SHADER);
  raycastFragmentShader = this.loadShader(volumetric.shaders.raycastFragment("70.0"), this.gl.FRAGMENT_SHADER);
  
  if (!vertexShader || !fragmentShader || !raycastVertexShader || !raycastFragmentShader) return false;
  
  this.programs = {};
  this.programs["back"] = this.createProgram(vertexShader, fragmentShader);
  this.programs["raycast"] = this.createProgram(raycastVertexShader, raycastFragmentShader);
  
  this.getRaycastUniforms();
  this.initializeFrameBuffer(dimension, dimension);
  this.initializeCubeBuffer();
  
  this.pMatrix = mat4.create();
  this.mvMatrix = mat4.create();
  this.rotationMatrix = mat4.create();
  mat4.perspective(this.pMatrix, 45.0, 1.0, 0.1, 100.0);
  mat4.identity(this.rotationMatrix);
  
  this.setOpacity(2.0);
  this.setLighting(0.3);
  
  this.zoom = 2.0;
  this.setupControls();
  
  this.hasTexture = false;
};

volumetric.prototype.setExtent = function(minimum, maximum) {
  this.minimum = minimum, this.maximum = maximum
  
  this.gl.useProgram(this.programs.raycast);
  this.gl.uniform1f(this.uMinimum, minimum);
  this.gl.uniform1f(this.uMaximum, maximum);
  
  // TODO: Check if we need the absolute value
  this.gl.uniform1f(this.uRange, maximum - minimum);
  this.draw();
};

volumetric.prototype.setSteps = function(value) {
  var gl, program, shader, shaders, _i, _len, _ref;
  
  gl = this.gl;
  program = this.programs.raycast;
  
  attachedShaders = gl.getAttachedShaders(program);
  for (i = 0; i < attachedShaders.length; i += 1) {
    shader = attachedShaders[i];
    gl.detachShader(program, shader);
    gl.deleteShader(shader);
  }
  gl.deleteProgram(program);
  
  shaders = volumetric.shaders;
  
  this.programs["raycast"] = this.createProgram(shaders.raycastVertex, shaders.raycastFragment(parseInt(value) + '.0'));
  this.getRaycastUniforms();
  
  gl.useProgram(this.programs.raycast);
  gl.activeTexture(gl.TEXTURE0);
  
  gl.uniform1f(this.uTiles, this.depth);
  gl.uniform1f(this.uTileWidth, this.width);
  gl.uniform1f(this.uTileHeight, this.height);
  gl.uniform1f(this.uDimension, this.dimension);
  gl.uniform1f(this.uMinimum, this.minimum);
  gl.uniform1f(this.uMaximum, this.maximum);
  
  // Update to absolute value?
  gl.uniform1f(this.uRange, this.maximum - this.minimum);
  gl.uniform1f(this.uOpacity, this.opacity);
  gl.uniform1f(this.uLighting, this.lighting);
  this.draw();
};

volumetric.prototype.setOpacity = function(opacity) {
  this.opacity = opacity;
  this.gl.useProgram(this.programs.raycast);
  this.gl.uniform1f(this.uOpacity, opacity);
  this.draw();
};

volumetric.prototype.setLighting = function(lighting) {
  this.lighting = lighting;
  this.gl.useProgram(this.programs.raycast);
  this.gl.uniform1f(this.uLighting, lighting);
  this.draw();
};

volumetric.prototype.setTexture = function(arr, width, height, depth) {
  var dimension, length, pixels;
  
  length = arr.length;
  
  this.width = width;
  this.height = height;
  this.depth = depth;
  this.gl.uniform1f(this.uTiles, depth);
  
  dimension = Math.sqrt(length);
  dimension = this.toPower2(dimension);
  this.dimension = dimension;
  
  while (length--) {
    arr[length] = isNaN(arr[length]) ? 0 : arr[length];
  }
  pixels = new arr.constructor(dimension * dimension);
  pixels.set(arr, 0);
  
  if (!this.hasTexture) {
    this.gl.uniform1f(this.uTileWidth, width);
    this.gl.uniform1f(this.uTileHeight, height);
    this.gl.uniform1f(this.uDimension, dimension);
    
    this.texture = this.gl.createTexture();
    this.gl.bindTexture(this.gl.TEXTURE_2D, this.texture);
    this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_S, this.gl.CLAMP_TO_EDGE);
    this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_WRAP_T, this.gl.CLAMP_TO_EDGE);
    this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MIN_FILTER, this.gl.NEAREST);
    this.gl.texParameteri(this.gl.TEXTURE_2D, this.gl.TEXTURE_MAG_FILTER, this.gl.NEAREST);
  }
  
  // TODO: Cast to Float32Array?
  this.gl.texImage2D(this.gl.TEXTURE_2D, 0, this.gl.LUMINANCE, dimension, dimension, 0, this.gl.LUMINANCE, this.gl.FLOAT, pixels);
  this.gl.bindTexture(this.gl.TEXTURE_2D, null);
  
  this.hasTexture = true;
};

volumetric.prototype.drawCube = function(program) {
  var gl = this.gl;
  
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  
  mat4.identity(this.mvMatrix);
  mat4.translate(this.mvMatrix, this.mvMatrix, [0.0, 0.0, -this.zoom]);
  mat4.multiply(this.mvMatrix, this.mvMatrix, this.rotationMatrix);
  mat4.translate(this.mvMatrix, this.mvMatrix, [-0.5, -0.5, -0.5]);
  
  gl.bindBuffer(gl.ARRAY_BUFFER, this.cubeBuffer.vertexPositionBuffer);
  gl.vertexAttribPointer(program.vertexPositionAttribute, this.cubeBuffer.vertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);
  
  gl.bindBuffer(gl.ARRAY_BUFFER, this.cubeBuffer.vertexColorBuffer);
  gl.vertexAttribPointer(program.vertexColorAttribute, this.cubeBuffer.vertexColorBuffer.itemSize, gl.FLOAT, false, 0, 0);
  
  gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.cubeBuffer.vertexIndexBuffer);
  this.setMatrixUniforms(program);
  gl.drawElements(gl.TRIANGLES, this.cubeBuffer.vertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0);
};

volumetric.prototype.draw = function() {
  this.gl.clearColor(0.0, 0.0, 0.0, 0.0);
  this.gl.enable(this.gl.DEPTH_TEST);
  
  this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, this.frameBuffer);
  
  this.gl.useProgram(this.programs.back);
  this.gl.clearDepth(-50.0);
  this.gl.depthFunc(this.gl.GEQUAL);
  this.drawCube(this.programs.back);
  this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, null);
  
  this.gl.useProgram(this.programs.raycast);
  this.gl.clearDepth(50.0);
  this.gl.depthFunc(this.gl.LEQUAL);
  
  this.gl.activeTexture(this.gl.TEXTURE0);
  this.gl.bindTexture(this.gl.TEXTURE_2D, this.frameBuffer.texture);
  
  this.gl.activeTexture(this.gl.TEXTURE1);
  this.gl.bindTexture(this.gl.TEXTURE_2D, this.texture);
  
  // TODO: This should not need constant updating. Don't remember if this
  //       is a hot function.
  this.gl.uniform1i(this.uBackCoord, 0);
  this.gl.uniform1i(this.uVolData, 1);
  
  this.drawCube(this.programs.raycast);
};
