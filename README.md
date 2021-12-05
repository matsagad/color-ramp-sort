# Color Ramp Sort
An Aseprite extension that sorts palettes by way of color ramps. 

<p align='center'>
  <img width="50%" src="https://github.com/matsagad/color-ramp-sort/blob/main/demo.gif" alt="Demo Video"/>
</p>

As constrained by a one-dimensional palette display, it is far from perfect but has its own merits.

## Installation & Usage
- Download a zip file of this repository.
- Open Aseprite and head into **Settings/Preferences > Extensions**.
- Click on **Add Extension** and load the zip file.
- Under the Options panel, the **Sort By Color Ramp** option should now appear.
- Configure settings as desired and click on Sort.

## Algorithms & Design

### Assumptions
It is first important to note that, while there are no precise criteria for color ramps, methods such as linear RGB interpolation and hue-shifting are widely practiced and often considered when making ramps. 

However, the RGB color space is easier to work with than HSV. This is because RGB values can be translated directly as Cartesian coordinates, whereas HSV values are still of the cylindrical polar form. And so, only color ramps generated by linear RGB interpolation are considered.

There is also the problem that two color ramps can intersect. Although to simplify the clustering algorithm, ramps are assumed to be disjoint. This is a big assumption, but one that can be addressed for further extensions.

### How it Works
The entire process can be split into three parts: measuring similarity by collinearity of colors by 2D Hough Transforms, grouping colors into disjoint ramps by hierarchical clustering, and finally sorting the ramps internally and externally.

In the RGB color space, any set of collinear points define a color ramp. As not all palettes have precise ramps, we introduce the notion of being "collinear enough". First, the 3D points are projected onto the y=0 and z=0 planes, and both are parametrized onto a discrete Hough space. The accumulator space is traversed through a window whose dimensions dictate how collinear enough points have to be. The number of times two colors are contained in the same window is recorded onto a matrix, and this measure will be known as their similarity.

We call a tree "skewed-full" if every node except the leaves has exactly two children and at least one of them is a leaf. A dendrogram is constructed out of the similarity matrix by the average linkage method. It is then cut at certain points when a branch is skewed-full and the minimum ramp length is met. Outliers, colors that do not fit in a ramp, are also recorded and are considered individually or together as a ramp, based on the set configurations.

The colors in each ramp are first sorted, and then the ramps are sorted. These are based on the sorting configurations set. Finally, the colors are added to the active palette.


### Design Liberties
The Hough space is discrete and, oftentimes, there are not enough cells to indicate that two lines do intersect. There are a few ways to deal with this:
- Increase the granularity (cell density) of the accumulator space.
- Traverse the accumulator space in a larger window.
- Thicken the line width when drawn on the accumulator space.

I chose to add support for the first option as it was quite easy to integrate. Although, justification for the other two methods can definitely be made. The window dimension was set to 3 by default as it felt to me as the minimum size that could reliably tell the collinearity of points without falling prey to the problem mentioned above.

Another vague design choice was the way to combine the number of times colors are incident on a window. As two transforms are performed, there will be two counts for this measure. Currently, it simply adds the two counts together and records them to the matrix. I initially thought that there should be considerable weight in ensuring both counts are positive, as points appearing to be collinear in one dimension but not in the other can be misleadingly considered. But, using the geometric mean made the matrix sparse enough that clusterings could not be made - an overall lack of sensitivity. Another reason to favor a simple sum is that while colors aren't necessarily collinear in 3D space, appearing to be collinear in one projection seems to translate well visually.

One more is choosing where to cut the dendrogram. To give more freedom to the user, multiple configurable options in the dialog were added, but this simply is not enough to consider all ways in which branches can be pruned. The arbitrary "skewed-full" definition comes from observations I've had while going through example dendrograms. When trees are skewed-full, the leaves tend to be similar enough to be put in a ramp. It also avoids having too many outlier points (not belonging to a ramp).

### Further Extensions
1. Instead of projecting points onto 2D space and performing a Hough Transform twice, perhaps making use of a 3D Hough Transform parametrization (i.e. line detection for 3D point clouds) could yield a better sensitivity for the similarity measures.
2. A configurable option for allowing intersections can be added. This could be done through an overlapping clustering algorithm such as fuzzy k-means clustering, where k can also be configured from the dialog (i.e. number of ramps).
3. The sorting logic can be extracted to C to speed up the process.

## Reflection
For a long while, I've been looking for ways to make color palettes appear more visually digestible. This is the case as working with large palettes has often been overwhelming for me. Color ramps are perhaps the most intuitive in terms of understanding which colors work together with the best. As most palettes are often created with color ramps in mind, it was only natural to fantasize about a magical sorting algorithm. Although, as best explained [here](https://www.alanzucconi.com/2015/09/30/colour-sorting/), there is no perfect way to sort a palette.

While this plug-in offers some form of help, I still think a two-dimensional representation for palettes, whether by [tiles](https://tgstation13.org/phpBB/viewtopic.php?f=11&t=7444&start=50) or [graphs](http://eastfarthing.com/blog/2016-05-27-mapping/), is the best way to visualize colors.
