/***
* Name: cityScopableHousingChoice 
* Author: mireia yurrita + GameIt
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model trial1123

global{
	
	
	/////////////////////////////////       SHAPEFILES          /////////////////////////////////////////////////
	
	file<geometry>buildings_shapefile<-file<geometry>("./../includes/City/volpe/Buildings.shp");
	file<geometry> roads_shapefile<-file<geometry>("./../includes/City/volpe/Roads_big.shp");
	
	//geometry shape<-envelope(roads_kendall_shapefile);
	geometry shape<-envelope(roads_shapefile);
	
	
	
	////////////////////////////////        CSV FILES         ///////////////////////////////////////////////////////
	
	// result files where granularity has been improved through ML techniques (can be used as an alternative to the results obtained directly through GAMA batch experiments in each case)
	// each file corresponding to the results obtained when people's behavioural criteria change (calibrated criteria with real data or when some behavioural placeholder incentives are applied)
	
	file income_profile <- file("C:/Users/Youngju/Desktop/Gama_yj/Trial_11_14/includes/income_profile.csv");
	file rent_subsidized_per_profile <- file("C:/Users/Youngju/Desktop/Gama_yj/Trial_11_14/includes/Rent_subsidize.csv");
	
		
	////////////////////////////////        PARAMETERS         ///////////////////////////////////////////////////////
	
	
	//parameters to be manipulated on the GAMA user interface (t=0 scenario thus changed)
	//Policy Interventions
	float Rent_Subsidy <- 1.0 min: 1.0 max: 2.0 parameter: "Level of rent subsidy:" category: "Policy Intervention";
	int Developer_incentive <- 0 min: 0 max: 1.0 parameter: "Level of developer incentive:" category: "Policy Intervention";
	float Density_Residential <- 1.0 min: 1.0 max: 5.0 parameter: "Density of Residential Areas:" category: "Policy Intervention";
	float Density_Amenity <- 1.0 min: 1.0 max: 5.0 parameter: "Density of Amenities:" category: "Policy Intervention";
	//Technologies
	bool green_buildings <- false parameter: "Green Building Construction:" category: "Technology";
	bool compact_housing <- false parameter: "Compact Housing:" category: "Technology";
	
	//Parameters for environment
	//Walkable distance for the perception of the agents
	int walking_distance <- 100 max: 300 min: 1 parameter: "Distance of amenity:" category: "Amenity";
	//Unit Size
	int square_feets_per_people <- 120 parameter: "Unit Size (in sqft):" category: "GIS specific";
	int nb_people <- 1000 min: 1000 max: 50000 parameter: "Number of People"; 
	

	
	////////////////////////////////        VARIABLES         ///////////////////////////////////////////////////////
	
	float proportion_apart_reduction <- 0.008; //residential vacancy rate in cambridge 
	float proportion_office_reduction <- 0.07; //office vacancy rate in cambridge
	int nbPeopleKendall;
	float builtArea<- 0.0; //amount of m2 built in the grid
	float propInKendall <- 0.0; //proportion of people working in the area of interest that live within a 20-minute walking dist
	int minRentPrice;
	int maxRentPrice;
	int nb_unsettled; 


	//point startingPoint <- {1025, 1160}; //kendall_roads

	list<string> prof_list; //income profile list
	map<string,int> listAreasApartment <- ["S"::15,"M"::55,"L"::89];
	int microUnitArea <- 40; //m2
	map<string,float> profileMap; //proportion of people working and living within the area of interest (in CAMBRIDGE, Kendall) f(income profile)
	map<string,float> originalProportions; //total proportions of workers from the area of interest f(income profile)
	map<string,int> amenity_preference;
	map<string,int> fancy_preference;
	map<string,int> size_preference;
	map<string,float> outKendallProportions; //prop of people f(income profile) that work in the area of interest but do not live within the area
	map<string,rgb> colorMap;
	list<apartment> gridApartments <- []; //list of apartments created within the grid
	
	init{
		do createBuildings;
		do createRoads;
		do characteristic_file_import;
		do normaliseRents;
		do importOriginalValues;
		do createPopulation;	
		
	}
	
	action createBuildings{ //creation of buildings of the area of interest from the shapefile (those that are not being built in the grid). 
		create building from: buildings_shapefile with:[usage::string(read("Usage")), rentPrice::float(read("PRICE")), category::read("Category"), scale::string(read("Scale")), heightValue::float(read("Max_Height"))]{
			if(usage != "R" or "O"){
				rentPrice <- 0.0;
			}
			//heightValue <- 15;
			float rentPriceBuilding <- rentPrice;
			float areaBuilding <- shape.area;
			float areaApartment <- listAreasApartment[scale];
			building ImTheBuilding <- self;
			int nbFloors <- heightValue/5;

			//out of the people who live and work within the area of interest, there are certain that live within the grid apartments (according to the Volpe occcupancy for Cambridge) 
			// but those who live outside the grid need to be located in a building from the shapefile. This geolocation is not known, so a reduced number of apartments is created in 
			// the buildings with Residential usage f(number of floors) to scatter the people throughout the area of interest
			if(Density_Residential = 1){
				if(usage = "R"){
				create apartment number: int(areaBuilding / areaApartment*nbFloors *proportion_apart_reduction){
					int numberApartment <- int(areaBuilding / areaApartment*nbFloors *proportion_apart_reduction);
					rent <- rentPriceBuilding/(Developer_incentive+1);
					associatedBuilding <- ImTheBuilding;
					location <- associatedBuilding.location;
				}
			}
			else{
				if(usage = "R"){
				create apartment number: int(areaBuilding / areaApartment*nbFloors *proportion_apart_reduction*Density_Residential*0.9){
					int numberApartment <- int(areaBuilding / areaApartment*nbFloors *proportion_apart_reduction);
					rent <- rentPriceBuilding/(Developer_incentive+1);
					associatedBuilding <- ImTheBuilding;
					location <- associatedBuilding.location;
					}
				}
				if(usage = "O"){
					numberApartment_current <- 0;
					loop i over: numberApartment_current > numberApartment_o {
						create apartment number: int(one_of(areaBuilding) / microUnitArea *nbFloors*proportion_office_reduction){
							int numberApartment_current <- numberApartment_current + int(one_of(areaBuilding) / microUnitArea *nbFloors*proportion_office_reduction);
							rent <- rentPriceBuilding/(Developer_incentive+1);
							associatedBuilding <- ImTheBuilding;
							location <- associatedBuilding.location;
						}
					}
				}
			}
		}
	
	
	action normaliseRents{
		maxRentPrice <- max(building collect each.rentPrice);
		minRentPrice <- min(building where(each.usage="R") collect each.rentPrice);
		float geometricMean <- geometric_mean(building collect(each.rentPrice));
		ask building where(each.usage="R" or "O"){
			do normaliseRentPrice;
		}
	}
	
	action importOriginalValues{ //import the original occupancy values from all the precooked what-if scenarios
		matrix data_matrix <- matrix(income_profile);
		
		loop i from: 0 to: data_matrix.rows - 1{
			prof_list << data_matrix[0,i];
			color_per_tier[data_matrix[0,i]] <- data_matrix[1,i];
			proportion_per_tier[data_matrix[0,i]] <- data_matrix[2,i];
			amenity_pref_per_tier[data_matrix[0,i]] <- data_matrix[3,i];
			fancy_pref_per_tier[data_matrix[0,i]] <- data_matrix[4,i];
			size_pref_per_tier[data_matrix[0,i]] <- data_matrix[5,i];
			income_per_tier[data_matrix[0,i]] <- data_matrix[6,i];
		} 
	}
	


	action createRoads{
		create road from:roads_shapefile{
		}
	}
	
	
	
	action createPopulation{
		int numberApartmentsVolpe <- count(apartment); //number of extra dwelling units available (built area is translated into dwelling units based on the CS vision -micro units are built 40m2 each-)
		int nb_unsettled <- int(nb_people);
		int countRemaining <- nb_unsettled;
		create people number: int(nb_people){
			liveInKendall <- false;	
			tier <- prof_list.keys[rnd_choice(prof_list.values)]; //random choice based on the proportions of people present f (income profile)
			income <- income_per_tier[tier];
			color <- color_per_tier[tier]; 
			all_people <- people as list; 
			all_building <- building as list; 
			current_place <- one_of(all_building where (each.category = "O")); 
			ask people  {  
			do move_to_new_place;       
		}
		}
}

species apartment{
	int rent;
	building associatedBuilding;
}

species building{
	int nbFloors;
	string usage;
	string category;
	float rentPriceBuilding;
	float normalisedRentPrice;
	float heightValue;
	string scale;
	int numberApartment;
	
	//Action to accept a people agent  
	action accept (people one_people) {
		add one_people to: insiders;
		location of one_people <- livingPlace.associatedBuilding.location;
		numberApartment <- numberApartment - 1;
	}

	aspect simple {
		color <- empty(insiders) ? #white : rgb ([mean (insiders collect each.red), mean (insiders collect each.green), mean (insiders collect each.blue)]);
		draw  square(40) color: color;
	}
	aspect gis {
		color <- empty(insiders) ? #white : rgb( [mean (insiders collect each.red), mean (insiders collect each.green), mean (insiders collect each.blue)]);
		draw shape color: color border: #black;
	} 
	aspect highlighted {
		color <- #blue;
		draw shape+10 color: color;
	}
}
	action normaliseRentPrice{
		normalisedRentPrice <- (rentPrice - minRentPrice)/(maxRentPrice - minRentPrice);
	}
	
}


species road{

	aspect default{
		draw shape color: #grey;
	}
}



species people skills: [moving]{
	string tier;
	rgb color;
	apartment livingPlace;
	apartment option_place; 
	float normalisedRentPrice;
	int income_per_tier; 
	int near_amenities; 
	int number_of_amenity_needed; 
	float Rent_Subsidy;
	float Density_Amenity;
	building current_place;
	bool liveInKendall;	
	list<building> amenities <- all_building where (each.category = "cultural" or "HS" or "Night" or "Park" or "Restaurant" or "Shopping");
	list<building> near_amenities <- amenities within walking_distance;
	action move_to_new_places{
		if(liveInKendall=false){
			option_place <- one_of(apartment); 
			if ((normalisedRentPrice <= income_per_tier*0.4*Rent_Subsidy) and (near_amenities*Density_Amenity>=number_of_amenity_needed){
			living_place <- option_place;
			ask living_place {
			do accept one_people: myself;   
     		}
			nb_unsettled <- nb_unsettled - 1; 
			bool liveInKendall -> True;//remaining available dwelling units within the grid
			}
	
}}
	
	


experiment visual type:gui{

	output{
		display map type: opengl draw_env: false  autosave: false background: #black 
			{
			species building aspect: default;
			species road aspect: default;
			species minor_road aspect: default;
			//species entry_point aspect: default;
			species people aspect: default;
			
	    	}
	    	
		}    
}


