//
//  Shader.fsh
//  glcube-shaders
//
//  Created by Ricardo Sánchez-Sáez on 12/01/2015.
//  Copyright (c) 2015 Ricardo Sánchez-Sáez. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
