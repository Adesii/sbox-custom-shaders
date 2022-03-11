A lot of this shader was inspired and adapted from this youtube video: 

https://www.youtube.com/watch?v=MeyW_aYE82s

it was a great learning experience and this shader wouldn't have been possible without their great explanation of shaders.

# Notice:
The Shader is sampling lightprobes and isn't using the Lightmap because of Issues with Tessellation and Lightmaps. so make sure there is a lightprobe around the mesh so it can accurately sample light data.
this will hopefully be a option later on once i figure out how to fix the lightmap data uv's
