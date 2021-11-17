/**
* Name: gamit
* Author: Arnaud Grignard, Tri Nguyen Huu, Patrick Taillandier, Benoit Gaudou
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model trial1116ver2

global {
	
	//PARAMETERS
	//**Percentage of similar wanted for segregation
	int number_amenity_wanted <- 5 min: 0 max: 20 parameter: "Desired density of amenity:" category: "Amenity";
	//**Walkable distance for the perception of the agents
	int walking_distance <- 100 max: 300 min: 1 parameter: "Distance of amenity:" category: "Amenity";
	//**Square meters per people in m2
	int square_feets_per_people <- 120 parameter: "Occupancy of people (in sqft):" category: "GIS specific";
	
	
	//bool updatePollution <-false parameter: "Pollution:" category: "Simulation";
	//bool updateDensity <-false parameter: "Density:" category: "Simulation";
	//bool weatherImpact <-true parameter: "Weather impact:" category: "Simulation";
		
		
	// DATA
	//**
	file income_profile <- file("C:/Users/Youngju/Desktop/Gama_yj/Trial_11_14/includes/income_profile.csv");
		
		//map<string,map<string,int>> activity_data;
	
	
	map<string, int> number_of_amenity_needed;
	map<string, float> proportion_per_income;
	map<string, int> income_from_chart;
	//map<string, float> proba_car_per_type;	
	//map<string,rgb> color_per_mobility;
	//map<string,float> width_per_mobility ;
	//map<string,float> speed_per_mobility;
	//map<string,graph> graph_per_mobility;
	//map<string,float> weather_coeff_per_mobility;
	//map<string,list<float>> charact_per_mobility;
	//map<road,float> congestion_map;  
	//map<string,map<string,list<float>>> weights_map <- map([]);
	//list<list<float>> weather_of_month;
	
	// INDICATOR
	//**Number of the people
	int number_of_people <- 50;
	//**Number of settled people
	int sum_settle_people <- 0 update: all_people count (each.is_settle);
	
	map<int,rgb> color_per_rent <- [ 3000::rgb("#424242"), 3200::rgb("#616161"),3300::rgb("#757575"), 3400::rgb("#9E9E9E"), 3500::rgb("#BDBDBD"), 3600::rgb("#E0E0E0"), 3800::rgb("#EEEEEE"), 0::rgb("#FAFAFA")];
	map<int,rgb> color_per_income <- [ 1000::rgb("#FFDCA2"), 2000::rgb("#FFBD71"), 3000::rgb("#FD8F52"),4000::rgb("#FE676E"),5000::rgb("#C73866")];
	
	//**
	list<people> all_people;  
	//**List of all the free places
	list<space> free_places  ;  
	//**List of all the places
	list<space> all_places ;

	//**Shapefile to load
	file kendallbdgs <- file("C:/Users/Youngju/Desktop/Gama_yj/Trial_11_14/includes/11_15/Buildings.shp") parameter: "Shapefile to load:" category: "GIS specific";
	file roads_shapefile <- file("C:/Users/Youngju/Desktop/Gama_yj/Trial_11_14/includes/11_15/Roads.shp");

	//**Shape of the environment
	geometry shape <- envelope(kendallbdgs);
	geometry shape_road <- envelope(roads_shapefile);
	
	//**
	init {
		//Initialization of the places
		do initialize_people;
		number_of_people <- 50;
		do initialize_places;
	}
	
		
	//Action to initialize people agents
	action initialize_places { 
		//**Create all the places with a surface given within the shapefile
		create space from: kendallbdgs with: [usage::string(read("Usage")),scale::string(read("Scale")),category::string(read("Category")),rent::int(read("PRICE")),area::float(read("Shape_area")),MaxHeight::float(read("Max_Height")),FAR::float(read("FAR"))]{
			color_places <- color_per_rent[rent];
		}
		list<space> all_res_places <- all_places where (each.category = "R");
		list<space> amenities <- all_places where (each.category = "cultural" or "HS" or "Night" or "Park" or "Restaurant" or "Shopping");
		list<space> office <- all_places where (each.category = "O");
	} 
	
	action initialize_people  {
		create people number: number_of_people{ 
		//income_level <- proportion_per_income.keys[rnd_choice(proportion_per_income.values)]; 
		income <- income_from_chart[income_level];
	    income_level <- rnd_choice(["Income 1"::0.2, "Income 2"::0.1, "Income 3"::0.2, "Income4"::0.3, "Income 5"::0.2]);
		start_location <- point(0,0,0);
		
		location <- start_location.location;
		//living_place <- one_of(free_spaces where(each.usage = "R"));
		//current_place <- living_place;//(check)
		//** color of the people agent
	    all_people <- people as list ; 	 
	    }
	    //(check)all_people <- people as list ; 
	    //Move all the people to a new place
		//ask people  {  			do move_to_new_place;       }   
	}  
	
	action profils_data_import {
		matrix profile_matrix <- matrix(income_profile);
		loop i from: 0 to:  profile_matrix.rows - 1 {
			string income_level <- profile_matrix[0,i];
			if(income_level != "") {
				number_of_amenity_needed[income_level] <- float(profile_matrix[3,i]);
				proportion_per_income[income_level] <- float(profile_matrix[2,i]);
				income_from_chart[income_level] <- int(profile_matrix[1,i]);
			}
		}
	}    

} 


//Species people representing the people
species people skills: [moving]{
	int income; 
	int rent;
	string income_level;
	rgb color; 
	float size<-5#m;	
	geometry starting_place <- self at_location {10, 20};
	list<space> amenities <- all_places where (each.category = "cultural" or "HS" or "Night" or "Park" or "Restaurant" or "Shopping");
	//list<space> my_amenities -> {amenities at_distance walking_distance}; 
	bool is_settle;
	space res_space_option;
	space all_res_places; 
	space living_place;
	point start_location;

	//Reflex to migrate to another place if the agent isn't happy
	reflex compare when: (location=start_location.location) {
		//res_space_option <- (shuffle(all_res_places) first_with (((each).capacity) > 0));
		res_space_option <- one_of(all_res_places);
		//if (rent <= income*0.4) and (length(my_amenities)>=number_amenity_wanted){
		if (rent <= income*0.4){
			living_place <- res_space_option;
			do goto target: living_place.location;
			}
		}
	aspect simple {
		draw circle(5) color:color_per_income[income];
	}
}

//Species space representing a space for a people agent to live in
species space {	

	//List of all the people agents living within
	list<people> insiders;
	rgb color_places;//**(check) 
	string usage;
	string scale;
	string category;
	float MaxHeight <- 0.0;//50.0 + rnd(50);
	float FAR;
	//Surface of the place
	float area;
	int rent;
	
	//Capacity of the place
	int capacity  <- 1 + int(area / square_feets_per_people);
	
	//Action to accept a people agent  
	action accept (people one_people) {
		add one_people to: insiders;
		location of one_people <- any_location_in(shape);
		capacity <- capacity - 1;
	}
	//Action to remove a people agent

	aspect gis {
		color <- color_per_rent[rent];
		draw shape color: color border: #black;
	} 
	aspect highlighted {
		color <- #blue;
		draw shape+10 color: color;
	}
}

experiment schelling type: gui {	
	output {
		display Town_display  {
			species space aspect: gis;
			species people  aspect: simple;
		}
		display Charts {
			chart "Proportion of settled" type: histogram background: #lightgray gap:0.05 position: {0,0} size: {1.0,0.5}{
				data "Unhappy" value: number_of_people - sum_settle_people color: #green;
				data "Happy" value: sum_settle_people color: #yellow ;
			}
		}
	}
}	