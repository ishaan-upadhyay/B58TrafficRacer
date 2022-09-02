
# Traffic Racer
A simple 2D implementation of a traffic racer game written using the MIPS architecture with the MARS MIPS simulator.
## Features
- Display number of remaining lives
- Randomized car spawns with varying speeds
- Display live score at bottom of screen
- Add hard mode; cars spawn more often and with greater minimum speed
## Configuration
- Clone this repository and open TrafficRacer.asm in the MARS simulator.
- From Tools, select "Keyboard and Display MMIO Simulator" and press "Connect to MIPS."
- From Tools, open the Bitmap Display, set unit width and unit height to 8, and display width/height to 256. Set the base address for the display to 0x10008000 ($gp). Connect to MIPS.
- Assemble and run.
### Controls
- W: Increase car speed (select between 3 different speeds)
- A: Move left
- S: Decrease car speed
- D: Move right
> Written with [StackEdit](https://stackedit.io/).
