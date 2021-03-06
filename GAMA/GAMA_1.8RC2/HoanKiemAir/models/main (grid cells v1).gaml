/***
* Name: maingridcells
* Author: minhduc0711
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model main

import "agents/traffic.gaml"
import "agents/pollution_grid_v1.gaml"
import "misc/remotegui.gaml"
import "misc/visualization.gaml"
import "misc/utils.gaml"


global {
	float step <- 16#s;
	date starting_date <- date(starting_date_string,"HH mm ss");

	geometry shape <- envelope(roads_shape_file);
	list<pollutant_cell> active_cells;
	
	init {
		do init_traffic;
		
		geometry road_geometry <- union(road accumulate (each.shape));
		active_cells <- pollutant_cell overlapping road_geometry;
		
		ask active_cells {
			color <- rgb(#yellow, 0.5);
		}
		
		create pollutant_manager;

		loop s over: sensor {
			save ["time", "co", "nox", "so2", "pm"] to: "../output/sensor_readings/" + s.name + ".csv" type: csv rewrite: true;
		}
		
		do init_visualization;
	}
	
//	reflex read_sensors when: every(5#mn) {
//		string t <- get_time();
//		loop s over: sensor {
//			pollutant_cell cell <- pollutant_cell(s.connected_pollutant_cell);
//			save [t, cell.co, cell.nox, cell.so2, cell.pm] to: "../output/sensor_readings/" + s.name + ".csv" type: csv rewrite: false;
//		}	
//	}
}

species scheduler schedules: intersection + road + vehicle + pollutant_manager + pollutant_cell {}

species pollutant_manager schedules: [] {
	reflex produce_pollutants {
		float start <- machine_time;
		// Absorb pollutants emitted by vehicles
		ask active_cells {
			list<vehicle> vehicles_in_cell <- vehicle inside self;
			loop v over: vehicles_in_cell {
				if (is_number(v.real_speed)) {
					float dist_traveled <- v.real_speed * step/ 1000;

					co <- co + dist_traveled * EMISSION_FACTOR[v.type]["CO"] / grid_cell_volume;
					nox <- nox + dist_traveled * EMISSION_FACTOR[v.type]["NOx"] / grid_cell_volume;
					so2 <- so2 + dist_traveled * EMISSION_FACTOR[v.type]["SO2"] / grid_cell_volume; 
				    pm <- pm + dist_traveled * EMISSION_FACTOR[v.type]["PM"] / grid_cell_volume;
				}
			}
		}
		time_absorb_pollutants <- machine_time - start;
		if (debug_scheduling) {
			write "Pollutants absorbed";	
		}
	}
		
	matrix<float> mat_diff <- matrix([
						[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion],
						[pollutant_diffusion, (1 - 8 * pollutant_diffusion) * pollutant_decay_rate, pollutant_diffusion],
						[pollutant_diffusion,pollutant_diffusion,pollutant_diffusion]]);
						
	reflex disperse_pollutants {
		// Diffuse pollutants to neighbor cells
		float start <- machine_time;
		diffuse var: co on: pollutant_cell matrix: mat_diff;
		diffuse var: nox on: pollutant_cell matrix: mat_diff;
		diffuse var: so2 on: pollutant_cell matrix: mat_diff;
		diffuse var: pm on: pollutant_cell matrix: mat_diff;
		time_diffuse_pollutants <- machine_time - start;
		if (debug_scheduling) {
			write "Pollutants dispersed";
		}
	}
	
	reflex calculate_aqi when: every(refreshing_rate_plot) and !empty(line_graph_aqi) {
 		float aqi <- max(pollutant_cell accumulate each.aqi);
		ask line_graph_aqi {
			do update(aqi);
		}
	}
	
	reflex update_building_colors {
		ask building {
			aqi <- pollutant_cell(connected_pollutant_cell).aqi;
		}
	}
}

experiment exp type: gui autorun: false keep_seed: true {
	parameter "Number of cars" var: n_cars <- max_number_of_cars min: 0 max: max_number_of_cars;
	parameter "Number of motorbikes" var: n_motorbikes <- max_number_of_motorbikes min: 0 max: max_number_of_motorbikes;
	parameter "Close roads" var: road_scenario <- 0 min: 0 max: 2;
	parameter "Display mode" var: display_mode <- 0 min: 0 max: 1;
	parameter "Refreshing time plot" var: refreshing_rate_plot init: 2#mn min:1#mn max: 1#h;
	
	output {
		display main type: opengl background: #black {
//			grid pollutant_cell lines: rgb(#grey, 0.8);
			species boundary;
			species road;
			species vehicle;
			species intersection;
			species building;

			species progress_bar;
			species param_indicator;
			species line_graph_aqi;
		}
	}
}
