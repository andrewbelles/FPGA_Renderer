---
title: Project Brainstorm

---

## Project Brainstorm 

+ 16 bit CPU. Implement a very small instruction set and run several test programs Implement pointers (most likely as integer addresses) and store values in memorys with simple arrays. 
+ MIDI audio synthesizer with reverb, chords, filter control. Potential VGA to display user input options 
+ HFT, unstructured test market data to operable, packed arrays representing order-book 
+ Still image ray tracer
    + Diffuse rendering 
+ Cube renderer
    + Keyboard input
    + Potential to implement the ray tracer over top if it isn't too much effort 
+ Oscilloscope with VGA


### Cube Renderer 

First implementation target features: 
+ Single cube shape rendered with VGA to screen 
    + Only explictly render region around cube so memory buffer is not massive
+ UART Keyboard inputs allow for rotation of cube on screen 
    + 50/50 Combination of inputs 
    + Negation of input 
    + Stack Implemented 


## Parts of the project:
#### Array multiplication
- Systolic array vs von neumann architecture
    * 1. Direct combinational or pipelined multiplier blocks
    * Implement a simple 3×3 matrix × 3×1 vector multiply per vertex using:
        * A few DSP slices for multipliers
        * Adders to sum the products
    * Pipeline the multiplications so you can feed one vertex every few clock cycles.
- Or could use fsm to do them all sequentially, which would save hardware

#### User input module
- Read from keyboard, update rotation angles and compute rotation matrix based on input, trigger rotation

#### Matrix Update Logic
- Use LUTs to implement sin/cos since trig functions are floating point, which is difficult in hardware

#### Projection module:
- Project 3d coords to 2d for VGA display
- Do we want to do orthographic or perspective projection? Could be really cool to do perspective

#### VGA control
- Timing signals like Hsynch, Vsynch
- Use 2d projection to draw cube edges using Bresenham’s line algorithm or something similar

#### Top level
- Coordinates everything
- Synch operations with VGA refresh rate


##### Potential issues to consider:
- Timing issues
    - vga timing vs system clock
    - Consider setup and hold time violations
    - Consider button debouncing and synchronization to avoid metastability
    - Need to consider physical routing issues on FPGA — use BUFG or ODDR?
    - How to account for delay introduced from pipelining?
- Do we want to do 3x3 or 4x4 multiplication? 
    - 4x4 would allow us to have an extra “homogeneous” dimension to translate the cube rather than just rotate it
    - Looks like this is good because it unifies rotation and translation into a single transformation matrix
