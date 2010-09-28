precision mediump float;

varying lowp vec4 vColor;
varying mediump vec2 vTextureCoordinate[2];

uniform lowp sampler2D sPaperTexture;
uniform lowp sampler2D sContentsTexture;

uniform bool uInvertContentsLuminance;

uniform bool uDisableContentsTexture;

varying lowp float vBackContentsBleed;
varying lowp float vBackContentsBleedAddition;

lowp vec4 invertLuminance(in mediump vec4 rgba)
{   
    mediump float oldCombined = dot(rgba.rgb, vec3(1, 1, 1));
    return vec4(min(rgba.rgb * ((3.0 - oldCombined) / oldCombined), 1.0), rgba.a);
}

void main()
{
    lowp float contentsDisablingAddition = float(uDisableContentsTexture);

    lowp vec4 paperColor = texture2D(sPaperTexture, vTextureCoordinate[0]);
    lowp vec4 contentsColor = min(texture2D(sContentsTexture, vTextureCoordinate[1]) + contentsDisablingAddition, 1.0);
    
    contentsColor = contentsColor * vBackContentsBleed + vBackContentsBleedAddition;

    if(uInvertContentsLuminance) {       
        gl_FragColor = vColor * invertLuminance(invertLuminance(paperColor) * contentsColor);
    } else {
        gl_FragColor = vColor * paperColor * contentsColor;
    }
}