//
//  Shader.fsh
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

// Surface color
varying lowp vec4 colorVarying;

// Texture coordinate
varying lowp vec2 TexCoordOut;

// Texture
uniform sampler2D Texture;

void main()
{
    // Output color is mix of surface color and texture
    gl_FragColor = colorVarying * texture2D(Texture, TexCoordOut);
    gl_FragColor.a = colorVarying.a;
    
    // Remove green screen
    if (gl_FragColor.g > 0.4 && gl_FragColor.r < 0.95 && gl_FragColor.b < 0.3)
    {
        gl_FragColor.g = 0.0;
        gl_FragColor.r = 0.0;
        gl_FragColor.b = 0.0;
        gl_FragColor.a = 1.0;
    }

    // Remove artefact at the top and bottom
    if (TexCoordOut.y > 0.95 || TexCoordOut.y < 0.05)
    {
        gl_FragColor.g = 0.0;
        gl_FragColor.r = 0.0;
        gl_FragColor.b = 0.0;
        gl_FragColor.a = 1.0;
    }
}
