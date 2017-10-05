# godot_1dollar 
gdscript 1dollar guesture recognizer implementation for the Godot engine!
Created by n31r0 (initial port) and Todor Imreorov (game logic aid features and port to addon state (wip))
n31r0 ported this from http://depts.washington.edu/madlab/proj/dollar/index.html

It can recognise the following shapes out of the box (in the json file):
- carret
- v
- pigtail
- lineH
- lineV
- heart
- circle
It can record shapes for recognition- and add them to a json file, which gets loaded on start

The developer can set limited ink - to limit the size of shapes that can be drawn
Upon recognising a shape, it also emits a signal of what shape it is and how much ink was left when it was completed
If the ink left is > 0, it will create a collision shape from the drawing, that can be used to interact with other parts of the game
You can limit how many colision shapes can be drawn optionally

Optional particle effect and ability to set line thickness and color
Ability to set the allowed drawing area and change the mouse cursor to a pencil then it is over it
