# @title Visualization
# Visualization

*Evoasm* provides means to visualize loss functions and found programs.

{include:file:docs/examples/vis.rb}


## Loss Functions

Loss functions can be visualized by using {Evoasm::Population#plot} which
will plot the loss function using [Gnuplot](https://gnuplot.sourceforge.net/).
If a filename is provided, the loss function graph is saved to file. Otherwise,
a window will open.

Each column represents a deme. The first row shows program losses, the following
rows kernel losses.

![Loss functions](examples/loss.gif)

