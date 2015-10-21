

    ################################
    ## English Electric Lightning F6
    ## Master Nasal

	
	###
    # Main Initialise Function
    var init = func {
	    print("Initialising EE Lightning Master Nasal:");
		eno.init();
		engines.engine1.init();
		engines.engine2.init();
	}
	
	
	###
	# Engines
	
	var engines = { 
	     # Args: ( number, running, idle_throttle, max_start_n1, start_threshold, spool_time, start_time, shutdown_time)
	     engine1: yasimengines.Jet.new(0 , 0 , 0.005 , 6 , 5 , 1.6 , 1.2 , 1),
		 engine2: yasimengines.Jet.new(1 , 0 , 0.005 , 6 , 5 , 1.6 , 1.2 , 1),
		};
	
	
	###
	# Doors (Canopy)
	
	# Args: ( property path, seconds, start position )
	var canopy = aircraft.door.new("canopy", 5, 1);
	
	
	###
	# Lights
	var lightpath = "sim/model/lights";
	var lights = {
	     anticoll: aircraft.light.new(lightpath~"/anti-coll", [0.05, 1.8], lightpath~"/anti-coll/powered"),
		};	
	
	
	###
	# Go!
	
	setlistener("sim/signals/fdm-initialized", func {
	     settimer( init, 2);
	    });
	
	