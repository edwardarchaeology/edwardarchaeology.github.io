## Advanced Data Visualization: A 2D Chaos Game Played in 3 Dimensions

**Project description:** The chaos game is one of the classic geometric introductions into chaos theory. I always found it more beautiful than other simple examples like a double pendulum. Creating a Sierpinski triangle is extremely easy but I couldn't find an implementation in R into 3 dimensions. R is not the best programming language to generate dense 3D fractal point clouds but I thought it would be a fun exercise in optimization to see if I could not only build a 3D version of the 2D chaos game but also get it to render quickly in R. Additionally, I wanted to generalize the 2D chaos game, so rather than the traditional method of subtracting volumes, I wanted to calculate a 2D Sierpinski triangle over each face over a 3D Sierpinski Pyramid. If you want to skip straight to the final result click the link below to see an interactive R shiny app:

[2D Chaos Game in 3D](https://edwardarchaeology.shinyapps.io/3DChaosGameApp/)

### The Chaos Game in 2D

The Chaos Game is a simple method of generating 2D fractals using a regular polygon. In the triangular case you choose a random point within an equilateral triangle, choose a random vertex, calculate the midpoint between that vertex and the random point, and repeat this using that midpoint as your new random point. After some number of iterations N, your points will begin to show a Sierpinski triangle like the one below:

https://github.com/user-attachments/assets/936b2bcc-529a-473a-9dd9-2c6a857a5790

In pseudocode this would look like:

```
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
Try out the app here. [Waffle House Index Simulator](https://edwardarchaeology.shinyapps.io/app_testing/)
```
### A 3D Chaos Game
For my project I wanted to generalize this to 3D which required working with four sided triangular tetrahedrons. The process is quite similar to the 2D case. To start you create a regular triangular tetrahedron, you choose a random point and random vertex, and do the whole midpoint calculation process again. The pseudocode for this is below: 

```
1. Initialize:
   - Define the vertices of the tetrahedron: A, B, C, D
   - Choose a random starting point (P) within the tetrahedron

2. Set the number of iterations (N) for the algorithm

3. Repeat N times:
   a. Randomly select one of the vertices (A, B, C, D)
   b. Move the current point (P) halfway towards the chosen vertex
   c. Update the current point (P) to this new position

4. Plot the points (P) as they are generated

5. Display the plot to visualize the 3D fractal
```

### A 2D Chaos Game Played in 3D?
I quickly built both of these but found them kind of boring. I decided to go a little off the rails and iteratively play the 2D chaos game in 3D. To do this, I took the tetrahedron and calculated the midpoint along all of its edges. I created four subtetrahedrons using each vertex in combination with the three midpoints of its associated edges. I recursively iterated through this process to some arbitrary depth. This resulted in a massive list of all the vertices for each subtetrahedron the the original tetrahedron. From here I could play the 2D chaos game along each of the four faces of each subtetrahedron. This results in a "hollow" Sierpinski Pyramid with chaotic points delineating its faces. Now, the way I've implemented this was just for my own interest in the 2D chaos game being used to create a 3D fractal but the vertex generation procedure could easily be used to generate a triangular mesh over the vertex sets. This could be a fast way to generate 3D fractals as polygonal meshes. A small visual representation of the process and the pseudocode for my method are below:

https://github.com/user-attachments/assets/7800937e-f582-4e7d-84b1-3d9c650b661f

```
Function Main():
    // Initial tetrahedron vertices
    A = (ax, ay, az)
    B = (bx, by, bz)
    C = (cx, cy, cz)
    D = (dx, dy, dz)
    
    // Define recursion depth
    maxDepth = d
    
    // List to store vertices of all subtetrahedrons
    allVertices = []

    // Start the recursive subdivision
    RecursiveSubdivision(A, B, C, D, 0, maxDepth, allVertices)
    
    // Apply 2D Chaos Game on each face of each subtetrahedron
    For each tetrahedron in allVertices:
        Apply2DChaosGameOnTetrahedronFaces(tetrahedron)
    
End Function

Function RecursiveSubdivision(A, B, C, D, currentDepth, maxDepth, allVertices):
    // Base case: if maximum depth reached, add vertices to list
    If currentDepth == maxDepth:
        allVertices.append((A, B, C, D))
        Return
    
    // Calculate midpoints of all edges
    M_AB = Midpoint(A, B)
    M_AC = Midpoint(A, C)
    M_AD = Midpoint(A, D)
    M_BC = Midpoint(B, C)
    M_BD = Midpoint(B, D)
    M_CD = Midpoint(C, D)
    
    // Create four new subtetrahedrons
    SubTetra1 = (A, M_AB, M_AC, M_AD)
    SubTetra2 = (B, M_AB, M_BC, M_BD)
    SubTetra3 = (C, M_AC, M_BC, M_CD)
    SubTetra4 = (D, M_AD, M_BD, M_CD)
    
    // Recursively subdivide each new subtetrahedron
    RecursiveSubdivision(SubTetra1[1], SubTetra1[2], SubTetra1[3], SubTetra1[4], currentDepth + 1, maxDepth, allVertices)
    RecursiveSubdivision(SubTetra2[1], SubTetra2[2], SubTetra2[3], SubTetra2[4], currentDepth + 1, maxDepth, allVertices)
    RecursiveSubdivision(SubTetra3[1], SubTetra3[2], SubTetra3[3], SubTetra3[4], currentDepth + 1, maxDepth, allVertices)
    RecursiveSubdivision(SubTetra4[1], SubTetra4[2], SubTetra4[3], SubTetra4[4], currentDepth + 1, maxDepth, allVertices)

End Function

Function Midpoint(P1, P2):
    // Calculate the midpoint between two points in 3D space
    Return ((P1.x + P2.x) / 2, (P1.y + P2.y) / 2, (P1.z + P2.z) / 2)
End Function

Function Apply2DChaosGameOnTetrahedronFaces(tetrahedron):
    // Extract vertices of the tetrahedron
    (A, B, C, D) = tetrahedron
    
    // Apply 2D Chaos Game to each face (triangle) of the tetrahedron
    Apply2DChaosGame(A, B, C)
    Apply2DChaosGame(A, B, D)
    Apply2DChaosGame(A, C, D)
    Apply2DChaosGame(B, C, D)
End Function

Function Apply2DChaosGame(A, B, C):
    // Implement the 2D Chaos Game on a triangular face defined by vertices A, B, and C
    // (This involves a similar process as the traditional 2D Chaos Game, generating points within the triangle)
    // Initialize a random point within the triangle
    P = RandomPointInTriangle(A, B, C)
    
    // Define the number of iterations
    N = 10000  // Arbitrary number for illustration
    
    // Iteratively generate points
    For i from 1 to N:
        // Randomly select one of the vertices
        Vertex = RandomChoice([A, B, C])
        
        // Move the current point halfway towards the chosen vertex
        P = Midpoint(P, Vertex)
        
        // Store or plot the point as needed
        PlotPoint(P)  // This function would plot or store the point for visualization
    
End Function
```

This all resulted in the creation of a shiny app to show off the results of this kind of insane process. Check it out via the link below but be warned, depths 4 and 5 take a long time to render if you have a lot of points:

[2D Chaos Game in 3D](https://edwardarchaeology.shinyapps.io/3DChaosGameApp/)
