## Simple R Application with Spatial Data

**Project description:** The chaos game is one of the classic geometric introductions into chaos theory. I always found it more beautiful than other simple examples like a double pendulum. Creating a Sierpinski triangle is extremely easy but I couldn't find an implementation in R into 3 dimensions. R is not the best programming language to generate dense 3D fractal point clouds but I thought it would be a fun exercise in optimization to see if I could not only build a 3D version of the 2D chaos game but also get it to render quickly in R. 

<img src="images/Waffle.gif?raw=true"/>

### The Chaos Game

The Chaos Game is a simple method of generating 2D fractals using a regular polygon. In the triangular case you choose a random point within an equilateral triangle, choose a random vertex, calculate the midpoint between that vertex and the random point, and repeat this using that midpoint as your new random point. After some number of iterations N, your points will begin to show a Sierpinski triangle like the one below:



```plaintext
1. Initialize:
   - Set the vertices of the triangle: A, B, C
   - Choose a starting point randomly within the triangle (P)

2. Set the number of iterations (N) for the algorithm

3. Repeat N times:
   a. Choose one of the vertices (A, B, C) randomly
   b. Move the current point (P) halfway towards the chosen vertex
   c. Update the current point (P) to this new position

4. Plot the points (P) as they are generated

5. Display the plot to visualize the Sierpiński triangle
Try out the app here. [Waffle House Index Simulator](https://edwardarchaeology.shinyapps.io/app_testing/).
