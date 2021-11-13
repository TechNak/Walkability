/**
* Name: WalkReal
* Based on the internal empty template. 
* Author: Naksha Satish
* Tags: 
*/


model NewModel

/* Insert your model definition here */
global {
	file Buildings <- file("C:/GamaNak/trial_real/includes/Buildings.shp") parameter: "Shapefile to load:" category: "GIS specific";
	geometry shape <- Buildings(shape_file_name);
		
	action initialize_Buildings {} 
}

experiment type: gui {	
	output {
		display Town_display  {
			species space aspect: gis;
			}
		}