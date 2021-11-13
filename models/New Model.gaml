/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Youngju
* Tags: 
*/


model firstModel

global {
	int number_of_people_income_1 <- 30;
	int number_of_people_income_2 <- 30;
	int number_of_people_income_3 <- 30;
	int number_of_apt_rent_1 <- 30;
	int number_of_apt_rent_2 <- 30;
	int number_of_apt_rent_3 <- 30;
	
	init{
		create people_income_1 number:number_of_people_income_1;
		create people_income_2 number:number_of_people_income_2;
		create people_income_3 number:number_of_people_income_3;
		create apt_rent_1 number:number_of_apt_rent_1;
		create apt_rent_2 number:number_of_apt_rent_2;
		create apt_rent_3 number:number_of_apt_rent_3;
		}
}

species people_income_1 skills:[moving] {
	bool is_settled <-false;
	int income_1 <-1000;
	goto when: !is_settled {
		if (rent_1 < income_1*0.4) {
				ask apt_rent_1 
				do accept one_people: myself;
				myself.is_settled <-true;
			}
			else if (rent_2 < income_1*0.4) {
				ask apt_rent_2 
				do accept one_people: myself;
				myself.is_settled <-true;
			}
			else if (rent_3 < income_1*0.4) {
				ask apt_rent_3 
				do accept one_people: myself;
				myself.is_settled <-true;
			}
			else { 
				write "no place to live"
	
	aspect base {
		draw circle(2) color: (is_settled) ? #red : #green;
	}
	
}
species apt_rent_1 {
	bool is_occupied <- 0;
	int rent <-400; 
	//based on rat infection model and don't know how to modify 
	reflex occupy when: !empty(people at_distance attack_range){
		ask people at_distance attack_range {
			if (self.is_occupied) {
				myself.is_occupied <-true;
			}
			else if (myself.is_infected) {
				self.is_infected <-true;
			}
		}
	}
	aspect base {
		draw square(5) color: (is_occupied) ? #red : #green;
}


experiment my_experiment type:gui {
	output {
		display my_display {
			species people_income_1 aspect:base;
			species people_income_2 aspect:base;
			species people_income_3 aspect:base;
			species apt_rent_1 aspect:base;
			species apt_rent_2 aspect:base;
			species apt_rent_3 aspect:base;
		}
			
	}
}

