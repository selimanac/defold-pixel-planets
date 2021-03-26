# Pixel Planets
![](https://raw.githubusercontent.com/selimanac/defold-pixel-planets/master/assets/raw/Screen%20Shot%202021-03-26%20at%2016.37.20.png)



Pixel Planet shaders originally created by [Deep-Fold](https://deep-fold.itch.io/), ported to [Defold](https://defold.com/) game engine by [me](https://twitter.com/selimanac).  

See it in action: https://selimanac.itch.io/defold-pixel-planet-generator

Please visit his itch.io project page here: https://deep-fold.itch.io/pixel-planet-generator
All credit geos to Deep-Fold

### Uniforms
No logic here...

```glsl
/*
x = size
y = pixels
z = rotation
w = stretch
*/
uniform lowp vec4 transform;

/*
x = seed
y = time
z = time_speed
w = OCTAVES
*/
uniform lowp vec4 generic;

/*
x = light_border_1
y = light_border_2
z = bands
w =
*/
uniform lowp vec4 border;

/*
x = cover (cloud)
y = curve (cloud)
z = dither_size
w = scale (scale_rel_to_planet)
*/
uniform lowp vec4 modify;


/*
x = light_origin.x 
y = light_origin.y 
z = light_distance1
w = light_distance2
*/
uniform lowp vec4 lights;

/*
x = ring_width
y = ring_perspective
z = cutoff (lake_cutoff / land_cutoff / river_cutoff)
w = TILES
*/
uniform lowp vec4 extras;

/*
x = circle_amount
y = circle_size
z =  storm_width
w =  storm_dither_width
*/
uniform lowp vec4 circles;

```