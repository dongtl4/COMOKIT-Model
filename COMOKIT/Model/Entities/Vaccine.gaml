/**
* Name: Vaccine
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model Vaccine

import "Virus.gaml"
import "Biological Entity.gaml"

global {
	
	
	/*
	 * The list of mRNA based vaccines
	 */
	list<covax> ARNm;
	
	/*
	 * The list of modified adenovirus based vaccines
	 */
	list<covax> Adeno;
	
	/*
	 * The whole list of available vaccines
	 */
	list<covax> vaccines;
	
	/*
	 * Create vaccine against sarscov2
	 * TODO : there is a 3rd injection possible for people with co-morbidities ... but it will required to change a little bit the way vaccins work - see covax
	 * TODO : find information on symptomatic and sever case reduction !!!
	 */
	 covax create_covid19_vaccine(string vax_name, int doses, list<pair<float,float>> vax_schedul,
	 	list<float> protection_level, list<float> symptomatic_reduction, list<float> sever_case_reduction,
	 	virus virus_target <- original_strain
	 ) {
	 	if length(protection_level) != doses or length(vax_schedul)+1 != doses
	 		{error "There is a mismatch between the number of doses and protection characteristic per doses";}
	 	create covax with:[
	 		name::vax_name,
	 		target::virus_target,
	 		vax_schedul::vax_schedul,
	 		infection_prevention::protection_level,
	 		symptomatic_prevention::symptomatic_reduction,
	 		hospitalisation_prevention::sever_case_reduction
	 	] returns: vacs;
	 	return first(vacs);
	 }
	 
}

/*
 * General expression of vaccine
 */
species vax { 
	virus target;
	list<pair<float,float>> vax_schedul; 
}

/*
 * Vaccine against Sars-Cov-2. They give protection against three dimension of Covid-19 disease:
 * 
 * 1 - immunity level : how much the vaccin prevent from an infection after a succeful contact happen | static variable of the characteristic is IMMUNE_CHAR
 * 2 - symptomatic factor : how the vaccine will change the probability to be symptomatic after the infection occure | static variable of the characteristic is SYMPT_CHAR
 * 3 - severity factor : how the vaccin will change the probability to require hostpitalisation when getting in the symptomatic state  | static variable of the characteristic is CARE_CHAR
 * 
 * TODO : for now all those characteristic are intrinsic to the vaccine, but should be a conjunction of the biological entity characteritics (e.g. age, gender, co-morbidities, previous infection) and vaccine abilities
 */
species covax parent:vax {
	
	list<float> infection_prevention;
	list<float> symptomatic_prevention;
	list<float> hospitalisation_prevention;

	/*
	 * Returns the expected immunity level after 'dose' number of injection and against 'v' sarscov2 variant
	 * 
	 * TODO : make immunity level depend over individual variable - e.g. people with co-morbidities need 3 injection
	 */
	float get_immunity_level(int dose, sarscov2 v <- original_strain, BiologicalEntity e <- nil) { return get_protection(dose, v, e, vaccine_infection_prevention); }
	
	/*
	 * Returns the factor that should affect the probability of being symptomatic when getting infected by v sarscov2 variant and after 'n' doses
	 */
	float get_symptomatic_factor(int dose, sarscov2 v <- original_strain, BiologicalEntity e <- nil) { return get_protection(dose, v, e, vaccine_symptomatic_prevention); }
	
	/*
	 * Returns the factor that should affect the probability of requiring hospitalization when being in a symptomatic state, after 'n' doses and with 'v' sarscov2 variant
	 */
	float get_sever_factor(int dose, sarscov2 v <- original_strain, BiologicalEntity e <- nil) { return get_protection(dose, v, e, vaccine_sever_cases_prevention); }
	
	/*
	 * Inner purpose function to retrieve a protective characteristic of the vaccine after 'n' doses against a given sars-cov-2 strain
	 */
	float get_protection(int dose, sarscov2 v, BiologicalEntity e, string vax_characteristic) {
		list<float> protection;
		switch vax_characteristic {
			match vaccine_infection_prevention { protection <- infection_prevention; }
			match vaccine_symptomatic_prevention { protection <- symptomatic_prevention; }
			match vaccine_sever_cases_prevention { protection <- hospitalisation_prevention; }
			default {error "You asked for "+vax_characteristic+" protective characteristic of covid19 vaccin "+name+" but it does not exist";}
		}
		dose <- dose <= 1 ? 0 : (dose >= length(protection) ? length(protection)-1 : dose);
		if target = v or target.source_of_mutation = v { return  protection[dose]; }
		if target = v.source_of_mutation { return protection[dose] * v.get_value_for_epidemiological_aspect(nil,epidemiological_immune_evasion); }
		return 0.0;
	}
	
}

