//
//  Shader.vsh
//  The Mobile Stage
//
//  Created by Remi Dufour on 2013-03-17.
//
//
//  Copyright (C) 2013 Remi Dufour & Mike Dai Wang
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

uniform mat4 mvp;
uniform vec4 color;

attribute vec4 position;
attribute vec3 normal;

varying vec4 colorVarying;

attribute vec2 TexCoordIn;
varying vec2 TexCoordOut;

void main()
{
    // Apply Model View Projection matrix
    gl_Position = mvp * position;
    
    // Output color
    colorVarying = color;
    
    // Forward texture coordinate
    TexCoordOut = TexCoordIn;
}
