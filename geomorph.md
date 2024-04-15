## Why Standalone?

**Project description:** GIS is often constrained to a GUI. While this can provide a quick way to collate complex collection of features, it can become cumbersome when you need to perform the same task rapidly over large repositories of data. In order to solve this, it is possilbe to develop workflows in standalone Python that use QGIS tools. When used in combination with other processing libraries this gives researchers the ability to run complex analysis over lots of data quickly and efficiently without worrying about the RAM limitations inherent to the QGIS GUI. In fact, this system can be run within a Jupyter Notebook allowing for analysts to seemlessly combine .md style documentation with their code. This provides an accessible document useful for sharing with other researchers or for teaching those unfamiliar with your workflow. 

### Example: Geomorphons

[In recent years](https://www.sciencedirect.com/science/article/abs/pii/S0169555X12005028), geophysicists have constructed algorithms for processing digital elevation maps in order to categorize their features into the 10 most common geomorphometric features. QGIS offers an exceptionaly quick version of this via its use of the GRASS r.geomorphon processing method. One easily seen use of this is for the following archaeological application. In the satellite image below, nothing stands out:

<img src="images/morphons/SAT.png?raw=true"/>

Yet if we use r.geomorphon on a DEM of the area (in this case constructed via processing tiled LIDAR point clouds into one continuous surface) we see an interesting feature arise on the mountain top:

<img src="images/morphons/MORPH.tif?raw=true"/>

Extracting just the ridge features from the data set gives:

<img src="images/morphons/Ridge.tif?raw=true"/>

The circular ridge layers define a site of archaeological interest currently under study. This technique could be extended upon by running it over large DEM's and using a machine learning classifier to extract tiles where similar features are found. This could lead to an extremely quick method to discovering this type of hilltop archaeological site. 

### Standalone Code

Getting standalone python QGIS to run in a Jupyter Notebook is a complex process. I am currently looking at ways of simplifying the workflow so that I can post a simple tutorial in this section. If you have questions about getting it started for yourself feel free to reach out and I will help you set it up over a zoom call or email chain. 
