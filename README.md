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