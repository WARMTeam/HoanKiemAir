/***
* Name: Expebaseline
* Author: ben
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Expebaseline

import "main (grid cells v1).gaml"
//import "main (road cells).gaml"

global {
	float pollutant_decay_rate <- 0.80;
	float pollutant_diffusion <- 0.05;
}

experiment exp2 type: gui autorun: false keep_seed: true {
	parameter "Number of cars" var: n_cars <- max_number_of_cars min: 0 max: max_number_of_cars;
	parameter "Number of motorbikes" var: n_motorbikes <- max_number_of_motorbikes min: 0 max: max_number_of_motorbikes;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: 2#mn min:1#mn max: 1#h;
	
	output {
		display main type: opengl background: #black {
			grid pollutant_cell lines: rgb(#grey, 0.8);
			species boundary;
			species road;
			species vehicle;
			species intersection;
			species building;

			species progress_bar;
			species param_indicator;
			species line_graph_aqi;
		}
		
		display plot {
			
		}
	}
}