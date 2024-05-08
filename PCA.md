## PCA to Identify Missing Data Values

**Project description:** I was interested in looking at some osteological data. Howells craniometric data set is [freely available](https://web.utk.edu/~auerbach/HOWL.htm) and relatively large: 2524 human individuals over 28 populations. There is supposed to be a description of the structure of the data available on the source site but when I accessed it that link was broken. Knowing little else than that the data had 82 separate craniological measurements, I ran a PCA to see if any clustering or trends evolved in PC space so I could analyze a reduced number of dimensions. This resulted in the biplot below and motivated me to run down the cause of such extreme clustering behavior.  

<img src="images/PCA/PC1_2.png?raw=true"/>


### Howells' Data Set

The data from the source site is downloadable as two groups. One is the normal Howells crania (2524 crania) and the other is the so-called test set (524 crania). The latter is a collection of crania that were either not whole or had some other deficiency that differentiated them from the normative homo sapien skull. I worked with the normal data set as it had more individuals and as a novice to the world of craniometry I wanted to keep my data as representative of the norm as possible. The Howells set has 82 craniometric measurements in mm, variables for Population in both numeric and string form, Sex, and an individual ID.

<img src="images/PCA/Data_desc.png?raw=true"/>


### PCA

After generating the first biplot I created the following figure to see if this behavior continued with other PC components:

<img src="images/PCA/4PCA.png?raw=true"/>

At this point it was obvious that PC2 was driving the clustering so I made the variable vector plot below to see if anything jumped out:

<img src="images/PCA/color_var.png?raw=true"/>

The cluster of highly positive vectors seemed to be the cause of the clustering but there were too many variables in the plot to figure out their names visually. From here I looked into the loadings on PC2 and discovered that the 11 largest were an order of magnitude larger than all the rest. As I was new to craniometrics I didn't know the conversion from the three letter codes to what the measurements actually meant. I found [this](https://scholarworks.umt.edu/cgi/viewcontent.cgi?article=11691&context=etd) publication that described the codes and even mentioned that the variables I was interested in apparently came from a later study. I converted the pdf to .csv tables, read them into R, and added them to the Howells set:

<img src="images/loadings.png?raw=true"/>

From here, I separated the original data set by their position along the PC2 axis in order to grab the two clusters. I then ran a Welch's t-test to check for significant differences in the means of the different variables. This resulted in some strange results where the t-tests reported means of zero for some variable columns. Looking at the smaller groups data frame I was able to see that there were missing values represented as 0 in those variable columns. The missing data columns were the same variables that had the high loading values in PC space so everything started making sense.

<img src="images/missing.png?raw=true"/>

The missing data was causing a ton of variability. However, there were only 662 individuals with missing values and 1862 individuals with complete data. I believe this is why the variation effect was captured in PC2 as the missing data individuals comprised only roughly 1/5 of the total data. I am excited to play around with this and see the behavior of PCA with more and less missing values, but that is an experiment for another day. For now, this will stay as a really interesting way to quickly and visually inspect a data set for missing values.

###Further Considerations

Ok so what? Why should we care about missing data like this when there are tons of ways to find missing values. To me this opens the door for some fun experiments in PC space. Why does the clustering for missing values show up in PC2 and not PC1? Is that a function of the amount of individuals with missing data, the amount of columns with missing data, or both? Regardless of the answers, the 4x4 comparison of PC components is a super quick visual way to see if you are missing any data values, though this depends on your expected clustering behavior. Here the data should be describing human characteristics that have variation but shouldn't be so different to clearly cluster in the manner seen here.

Imagine you have a file directory with many different data sets. You need to check for a statistically significant number of missing data values across these sets. Sure you could resort to statistical tests that output numbers and heck you could even sort the files based on that. However, to me at least there is something beautiful about a visual solution to a numbers based problem.


This map shows the most probable areas for human habitation in Red. From this we can draw conclusions about ancient human settlement behavior! There are various other analyses that can help to provide further insight into the past. PCA can help determine what covariates may need to be dropped in order to reduce correlation bias errors. Variable importance within the model itself can help archaeologists understand what environmental factors most affected ancient peoples' habitation decisions. We even looked into the distribution of habitation patterns across different epochs as well as the distributions by site types e.g. settlement, burial ground, etc. I'd love to go further in depth on what we discovered but this page is already getting a little long for an overview, so feel free to contact me for more details if this piques your interest. 


