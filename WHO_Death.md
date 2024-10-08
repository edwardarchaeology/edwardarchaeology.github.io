## Advanced Data Visualization: A 2D Chaos Game Played in 3 Dimensions

**Project description:** With Tableau being all the rage in data informatics these days, I can't hide behind my mastery of ggplot and matplotlib. As wonderful as those tools are for bespoke data visualization, 9/10 times in industry you just need some nice charts for a meeting with surface level user interaction. As such, I've joined the masses and, in addition to the arcane skills of bespoke script based graphics, I'm now proficient in Tableau. I found a fascinating data set from the World Health Organization (WHO) that consists of all the major causes of death across the globe for six different years between 2000 and 2021 and managed to make a dashboard that integrates some really cool functionalities of Tableau without being too overwhelming. 

[Link to the Tableau Dashboard](https://public.tableau.com/views/WHO_Death/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

### The Data

![image](https://github.com/user-attachments/assets/a617b05c-da10-494f-8d33-503efaf995e3)

All the data used in this project can be found [here](https://www.who.int/data/gho/data/themes/mortality-and-global-health-estimates/ghe-leading-causes-of-death). The WHO provides six excel workbooks of tracked causes of death for each country they monitor. Each workbook corresponds to a different year and the years available are 2000, 2010, 2015, 2019, 2020, 2021. Each workbook is divided into 9 sheets with the first being a notes page, the second a collection of all causes of deaths across all ages, and the rest are causes of death broken down by age categories. As I was interested in the top causes of death per country I used the second page of each workbook as my data source. 

Each second page was a massive, 661x192, and formatted to be human readable with a lot of white space bullet point style organization. Additionally, these pages used conditional formatting to highlight countries with differing levels of statistical verification of their reported numbers. Green was high completeness/quality and transitioned through yellow to orange then finally red as the data became less complete/verified. As such, I chose to focus on the verified countries as any interesting visual trends seen in the final Tableau dashboard would have more statistical weight and meaning behind them. 





### A 3D Chaos Game
I use Tableau Public which doesn't come with the visually based Tableau Prep data manipulation tool, all of my pre-processing was done in R. This required importing each excel workbook into R, grabbing the sheet with the data we want AND EXPLAIN MORE LATER
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
