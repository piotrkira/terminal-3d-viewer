# Terminal 3D Viewer
Simple terminal 3D object viewer written in Assembly Language (NASM x86).

Features:
* object always in center of terminal window
* automatic rotation 

Compiled and tested on x86 Ubuntu 19.10

# Usage
To download:  
`https://github.com/piotrkira/terminal-3d-viewer.git`  

To view 3D object:  
`./t3dv filename`  

To exit press:  
`Ctrl+C`

# Compilation:
```
nasm -g -f elf64 main.asm
ld main.o -o t3dv
```

# 3D object file syntax
Example:
```
2,1,-10,0,1,5,5,5,0,1

```
This is the correct example of object file.
First number defines number of nodes, second one defines number of connections. Knowing that there are two nodes (each consists of x,y,z coordinates) we can read positon of first node (-10, 0, 1) and second node (5, 5, 5). There are two nodes so after these number we have defined connections. In this file we have just one connection between first and second node. Note that nodes are indexed from 0. Each file has to end with newline character.

# License
[MIT](https://github.com/piotrkira/terminal-3d-viewer/blob/master/LICENSE)
