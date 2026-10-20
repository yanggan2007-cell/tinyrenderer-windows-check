#include <algorithm>
#include <cmath>
#include "our_gl.h"
#include "model.h"
extern mat<4,4> ModelView, Perspective, Viewport;
extern std::vector<double> zbuffer;
#include "s7_tangent.inc"
#include "s7_shadow_main.inc"
