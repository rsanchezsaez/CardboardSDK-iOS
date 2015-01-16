precision mediump float;
varying vec4 v_Color;

void main() {
    gl_FragColor = min(v_Color + vec4(0.2, 0.2, 0.2, 0.0), 1.0);
}
