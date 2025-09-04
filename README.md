# ENGS 31 Final Project

## Intro 

For our ENGS 31: Digital Electronics final project in August 2025, we chose a project that we thought would teach us as much as possible. The final result is an FPGA-based graphics engine that renders a 3D tetrahedron which can be rotated via the keyboard in real time. We learned a ton on this project, both about graphcis and linear algebra on the FPGA. 

## Abstract 

A hardware graphics engine that renders and interactively rotates a wireframe tetrahedron on a VGA display. Keyboard input (UART) controls single- and dual-axis rotations in real time. Fixed-point linear algebra performs two sequential 3×3 rotations and a perspective projection; edges are rasterized with Bresenham and drawn via a double-buffered framebuffer.

## Demo highlights

- Real-time rotation from keyboard over UART.
- Perspective projection with fixed-point math and a seeded Newton-Raphson reciprocal.
- Smooth line drawing using Bresenham; flicker-free swaps with dual BRAM buffers.
- VGA 640×480 timing with a centered 256×256 drawing window.

## Controls

Single-axis: 
- `W`: (+Z)
- `A`: (+Y)
- `S`: (−Z)
- `D`: (−Y)
- `Q`: (+X)
- `E`: (−X)  
Dual-axis: 
- `I`: (+X +Y)
- `J`: (+Y +Z),
- `K`: (−X −Y),
- `L`: (−Y −Z)
- `U`: (+X +Z),
- `O`: (−X −Z)  
Reset the tetrahedron with `R`
  
## System architecture (top-down)

**Top Level Controller**  
Orchestrates phases (input → math → draw), keeps packets stable, waits for blanking to swap buffers.

**Input path**  

- **UART Receiver**: 25 MHz system clock, 9600 baud, samples 8 data bits LSB-first with start/stop framing.  
- **Angle/Dir LUT**: Maps ASCII keys to two rotation axes + angles; emits a special reset code for `R`.

**Math Manager (Parallel Math)**  

- Two sequential **Rotation** units.  
- **Projection**: Perspective using constants m00=m11=1/tan(FOV/2) with `FOV = 70 deg`; divide by `−z` with a near-clip $\epsilon=8$; scale and recenter into a 256×256 viewport (add 128 to x,y).  
- **Reciprocal**: Normalize to [1,2), seed from ROM, iterate Newton $x_{n+1} = x_n(2 − m\cdot x_n)$, then de-normalize.  
- Outputs both updated 3D vertices and 4 packed 2D points (16-bit each: x in high 8, y in low 8).

**Graphics Manager**  

- **Bresenham Receiver** runs line draws for all 6 edges, clears back buffer before each frame, then signals done.  
- **Framebuffer** uses dual BRAMs (front/back). Read window is the centered `256×256` region; swap occurs in vertical blank to avoid tearing.  
- **VGA Controller** generates 640×480@60 Hz timing at a 25 MHZ pixel clock.

### Key modules (by function)

- `uart_receiver.vhd` — serial input through PUTTY.  
- `angle_dir_lut.vhd` — key $\mapsto$ (angles, axes).  
- `rotation.vhd`, `sine_lut.vhd`, `accumulate_rotation.vhd` — fixed-point rotation pipeline.  
- `projection.vhd`, `reciprocal.vhd`, `newton_lut.vhd` — perspective divide path.  
- `bresenham.vhd`, `bresenham_receiver.vhd` — line rasterization + draw control.  
- `framebuffer_v2.vhd` — dual-buffer memory, clear/receive/swap FSM.  
- `vga_controller.vhd` — sync and scan counters.

## Build & run

1. **Board**: Digilent Basys3 (Artix-7). Connect VGA monitor + USB-UART.
2. **Clocking**: Use onboard 100 MHz and clock divide to 25 MHz for the system.
3. **Synthesize** in Vivado and program the bitstream.
4. **Serial**: Open a terminal at 9600 baud rate (We used PUTTY). Press the specified keys to rotate. `R` resets.

## Implementation notes

- **Viewport & addressing**: The visible drawing region is a centered 256×256 window; read address:  
  `addr = (y − 112) * 256 + (x − 192)`; write address: `addr = y * 256 + x`.
- **Perspective**: `m00 = m11 = 1 / tan(FOV/2)` with FOV fixed to `70 deg`; divide by `−z`, clamp with $\epsilon=8$, scale and add 128 to recenter.
- **Fixed-point**: Coordinates use 11.12 fixed point notation; trig LUT uses 1.14 notation; reciprocal seed LUT is 1024×24 (Height 1024, width 24, manually created, not an IP-Core).

## Future work
- Fill shading / color, more complex meshes.
- Resource optimizations (e.g., serialize second rotation) to free LUTs/BRAM.
