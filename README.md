# Directional Blur Shader
A Unity shader for directional blur effects.

## Credits:
Special thanks to Liindy for commissioning this effect! (check out his VRChat assets at https://liindy.gumroad.com/)

Blue noise texture provided by Christoph Peters under the CC0 license. (http://momentsingraphics.de/BlueNoise.html)

## Instructions:

**Using the shader on particles:**
* Enable *Custom Vertex Streams* in the renderer panel and make sure UV, Color, Normal, and Tangent streams are all enabled.
* If you want the blur to be relative to the direction the particles are moving, use *Stretched Billboard* mode.

**Using the shader on trail renderers:**
* Check the *Generate Lighting Data* box to generate normals and tangents.
* For some reason the tangents of trails are backwards, so you will need rotate the blur direction around 180 degrees to have the blur face the direction of the trail.
* If using the *Transform Z* alignment mode, note that the mesh normals and tangents may not be aligned with the shape of the mesh itself, particularly if the trail is moving in the same direction as the transform Z, which can make the blur direction look wrong.

**General Info:**
* The shader should be rendered in the transparent material queue in order to minimize draw order issues.
* For perf reasons, the grabpass is only done once when the first blur is rendered, so make sure all the materials render at similar times in the queue. For this reason directional blur effects will also not be cumulative.

## Material Properties Guide:

**Blur Size:** How wide the blur is at max strength. On a camera with a 90 degree FOV, this value directly corresponds to the amount of the screen the blur covers. (e.g. at 0.2 the blur would cover 1/5th of the screen's width.)

**Apply Perspective To Blur Size:** If enabled, the size of the blur depends on how far away the surface is from the camera. Recomended to leave this enabled for everything but screen overlay style effects. Automatically disabled for orthographic cameras.

**Max Blur Size:** If *Apply Perspective To Blur Size* is enabled, this controls the absolute maximum blur size as the camera gets close to the surface.

**Texture Mode:** Determines if a texture should control the blur, and if that texture is a monochrome texture that only controls the blur strength, or a Red+Green texture that controls both blur strength and direction.

**Strength Texture:** The red channel of this texture controls how strong the blur should be, with 0 being no blur and 1 being max blur.

**Direction Texture:** The red and green channels control the x and y direction of the blur vector respectively, similarly to a normal map. A (0.5, 0.5) yellow is neutral, with 1 being positive direction and 0 being negative direction for each channel. The length of the Red/Green color from (0.5, 0.5) controls the strength of the blur implicitly, with a length of 0.5 being max strength.

**Texture Tiling/Offset/Scroll Speed:** Controls the texture's size, position, and animation.

**Blur Direction Rotation:** Rotates the blur direction counterclockwise by the specified degrees.

**Use Worldspace Orientation For Direction:** If enabled, the blur direction will be relative to the mesh's tangent/bitangent in world space, with the tangent being the default direction. If disabled, the blur direction ignores the mesh's orientation and the blur direction is relative to the screen, with the default direction being rightward. Recomended to leave this enabled for everything but screen overlay style effects.

**Vertex Alpha Affects Blur Strength:** Should the mesh's vertex alpha modulate the strength of the blur. Mainly useful for particles and trail renderers.

**Blur Center Offset:** How far offset from the center pixel should the blur be. At 0, the blur is centered on the pixel it is rendering at. Positive values push the blur samples forward (relative to the blur direction), moving the blur visually backward. Vice versa for negative values.

**Blur Type:** Selects the blur mode. Gaussian is a smooth blur with a bell curve falloff. Dispersion is a prism-like effect that refracts different colors different amounts.

**Gaussian Falloff:** Controls how wide the blur is, with 0 being a completely even blur, and higher values having a more concentrated peak at a specific point.

**Gaussian Peak Offset:** Controls where the peak of the blur occurs. 0 is right in the center, 0.5 is all the way forward in the direction of the blur, and -0.5 is all the way backward.

**Dispersion Intensity:** Controls how strong the color separation effect is.

**Base Tint:** Controls what color the blur should be tinted by. It is recommended not to use tint colors with 100% saturation, as real world tints are not that perfect and that can cause unnatural looking images as a result.

**Tint With Vertex Color:** Applies the vertex color as a tint on top of the Base Tint. Mainly useful for applying tints from particle and trail colors.

**Min Tint Strength:** The strength of the tint is controlled by the blur strength. This setting determines how strong the tint should be when blur strength is 0. Leave this setting at 0 if you want particles and trails to be able to fade out without popping.

**Max Sample Count:** The maximum number of texture samples the blur can use. Increasing this value will make the blur higher quality and less grainy, but will decrease performance. The blur will only use as many samples as it needs, so small blurs won't necessarily use the max sample count. It is recommended to increase this value just until the quality of the blur is acceptable in motion.

**Dither Texture:** This is a greyscale texture that offsets the blur sample locations for each pixel to make low sample counts less noticeable. It is recommended to use the included blue noise or any other low discrepancy noise, but any dither texture will work.

**Cull:** Allows the option to not render triangle front-faces or back-faces.

**ZTest:** Allows the option to only render the blur in front of, or behind opaque objects. This should normally be left at LessEqual for standard depth testing.

**ZWrite:** Controls if the blur writes its depth to the depth buffer. If this is on, objects won't render behind the blur after it is rendered, and if multiple blurs are overlapping the closest one will be the one that is visible.

**Depth Offset:** Prevent Z-fighting by offsetting the blur mesh's depth slightly. -1 moves it closer to the camera and 1 moves if further away. Useful when rendering a trail effect with multiple materials on it, for instance.