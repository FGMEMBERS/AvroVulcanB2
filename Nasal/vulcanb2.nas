
var config_dialog = nil;

setprop("controls/doors/chute-switch-pos", 0);

toggle_cockpit_door = func {
  if(getprop("controls/doors/cockpit-door-pos-norm") > 0) {
    interpolate("controls/doors/cockpit-door-pos-norm", 0, 4);
  } else {
    interpolate("controls/doors/cockpit-door-pos-norm", 1, 4);
  }
}

toggle_chute = func {
  
  chute_state = getprop("/controls/doors/chute-switch-pos");
  
  if (chute_state == nil)
  {
    chute_state = 0;
  }
  
  if (chute_state == 0)
  {
    # Open the door and stream the chute - 2 second.
    interpolate("controls/chute-pos-norm", 1, 2);
    interpolate("controls/doors/chute-door-pos-norm", 1, 2);
    chute_state = 1;
  }
  
  if ((chute_state == 1) and 
      (getprop("controls/chute-pos-norm") == 1.0))
  {
    # Jettison the chute, leaving the door open
    setprop("controls/chute-pos-norm", 0.0);
    chute_state = 2;
  }
  
  if (chute_state == 2) 
  {
    # Close the door and reset the switch
    interpolate("controls/doors/chute-door-pos-norm", 0, 2);
    chute_state = 0;
  }
  
  setprop("/controls/doors/chute-switch-pos", chute_state);
}

# Normal BB doors have 3 positions - Close, Auto, Open.
# controls/doors/bb-doors therefore has 3 values:
# Close : -1
# Auto  : 0
# Open  : 1
# Note that the toggle_bb_doors function only selects Close and Open

open_doors = func { interpolate("controls/doors/bb-door-pos-norm", 1, 5) };
close_doors = func { interpolate("controls/doors/bb-door-pos-norm", 0, 5) };

toggle_bb_doors = func {
  if(getprop("controls/doors/bb-door-pos") > 0.1) {
    setprop("controls/doors/bb-door-pos", -1);
    close_doors();
  } else {
    setprop("controls/doors/bb-door-pos", 1);
    open_doors();
  }
}

incr_bb_doors = func {
  if (getprop("controls/doors/bb-door-pos") < 0.0) {
    # Close to Auto
    setprop("controls/doors/bb-door-pos", 0);
  } else if (getprop("controls/doors/bb-door-pos") < 0.1) {
    # Auto to Open
    setprop("controls/doors/bb-door-pos", 1);
    open_doors()
  } else {
    # Open to Close
    setprop("controls/doors/bb-door-pos", -1);
    close_doors()
  }
}

emerg_toggle_bb_doors = func {
  if (getprop("controls/doors/emergency-bb-door-pos") > 0) {
    setprop("controls/doors/emergency-bb-door-pos", 0);
    close_doors();
  } else {
    setprop("controls/doors/emergency-bb-door-pos", 1);
    open_doors();
  }
}

# Emergency jettison function:
# 1) Opens the BB doors
# 2) Jettisons all stores
# 3) Closes the BB doors
#
# Over-ride is possible by selecting the switch.
# Note that this is not available for nuclear weapons (see pilots notes)
# or Shrikes, which are mounted on the wings.
emerg_jettison = func {
  if (getprop("/sim/armament") == "BlackBuck1") {
    if (getprop("controls/doors/emergency-bb-jettison-pos") > 0) {
      # Over-ride
      setprop("controls/doors/emergency-bb-jettison-pos", 0);
      interpolate("controls/doors/bb-door-pos-norm", 0, 5);
    } else {
      # Jettison
      setprop("controls/doors/emergency-bb-jettison-pos", 1);
      interpolate("controls/doors/bb-door-pos-norm", 1, 5);
      settimer(func {
        if (getprop("controls/doors/emergency-bb-jettison-pos")) {
          setprop("/controls/armament/triggerbomb", 1);
          interpolate("controls/doors/bb-door-pos-norm", 0, 5);
          setprop("controls/doors/emergency-bb-jettison-pos", 0);
        }
      }, 6);
    }
  }
}

# Radar Altimeter Limiter Lights
var radar_low_pass = aircraft.lowpass.new(1.5);
var radar_alt = props.globals.getNode("/instrumentation/radar-altimeter/radar-altitude-ft", 1);
var radar_alt_lowpass = props.globals.getNode("/instrumentation/radar-altimeter/radar-altitude-lowpass-ft", 1);
var red = props.globals.getNode("/controls/radar/limiter-light-red", 1);
var amber = props.globals.getNode("/controls/radar/limiter-light-amber", 1);
var green = props.globals.getNode("/controls/radar/limiter-light-green", 1);
var limit = props.globals.getNode("/controls/radar/limiter-height");
var limit_active = props.globals.getNode("/controls/radar/limiter-active");
var limit_5k = props.globals.getNode("/controls/radar/sensitivity-five-thousand");
var limit_test =  props.globals.getNode("/controls/radar/limiter-light-test");

radar_altimeter = func {

  if ((limit_test.getValue() != nil) and (limit_test.getValue() == 1))
  {
    # Test switch set
    green.setValue(1);
    amber.setValue(1);
    red.setValue(1);
  }
  else
  {
    if (radar_alt.getValue() != nil)
    {
      radar_low_pass.filter(radar_alt.getValue());
      radar_alt_lowpass.setValue(radar_low_pass.get());

      var l = limit.getValue();
      var band = 25.0;
      
      if ((limit_5k.getValue() != nil) and (limit_5k.getValue()))
      {
        # Sensitivity is 5000 rather than 500, so adjust limit and green zone.
        l = l * 10;
        band = 250.0;
      }

      var delta = radar_alt.getValue() != nil ? radar_low_pass.get() - l : 0;

      if (limit_active.getValue()) {
        if (delta > band) {
          green.setValue(0);
          amber.setValue(1);
          red.setValue(0);
        } else if (delta < 0) {
          green.setValue(0);
          amber.setValue(0);
          red.setValue(1);
        } else {
          green.setValue(1);
          amber.setValue(0);
          red.setValue(0);
        }
      } else {
          green.setValue(0);
          amber.setValue(0);
          red.setValue(0);
      }
    }
  }

  settimer(radar_altimeter, 0);
}

settimer(radar_altimeter, 0);

# =============================== Pilot G stuff (taken from hurricane.nas) =================================
pilot_g = props.globals.getNode("fdm/jsbsim/accelerations/a-pilot-z-ft_sec2", 1);
pilot_g.setDoubleValue(0);

var g_damp = 0;
var g_max = 0;
var g_min = 0;

updatePilotG = func {
  var g = pilot_g.getValue() ;
  
  # Change value from ft/sec^2 to g
  g =  - g / 32;
  
  #if (g == nil) { g = 0; }
  g_damp = ( g * 0.2) + (g_damp * 0.8);
  
  setprop("accelerations/pilot-g", g_damp);
  
  if (g_damp > g_max)
  {
    g_max = g_damp;
    setprop("accelerations/pilot-gmax", g_max);
  }
  
  if (g_damp < g_min)
  {
    g_min = g_damp;
    setprop("accelerations/pilot-gmin", g_min);
  }

  settimer(updatePilotG, 0.2);
}

updatePilotG();


updateRollingSpeed = func {
  #nose = getprop("/gear/gear[0]/wow");
  lmain = getprop("/gear/gear[1]/wow");
  #rmain = getprop("/gear/gear[1]/wow");

  # Get the straight forward speed of the a/c. This is sufficient
  # for our purposes.  
  speed = getprop("/velocities/uBody-fps"); 
  
  # Work out how much to slow the wheels in the air down. Depends on
  # whether brakes are applied.
  
  # OK, we have the speed, now apply it to all the wheels on the ground.
  # For wheels in the air we look at whether brakes are applied or simply
  # reduce the speed.
  vfriction = 5;
  
  if (lmain)
  {
    setprop("/gear/gear[0]/groundspeed-fps", speed)
  }
  else
  {
    # Wheel is in the air - brake.
    if (getprop("/controls/gear/brake-right") > 0.5)
    {
      # Brakes, reduce speed to 0
      setprop("/gear/gear[0]/groundspeed-fps", 0);
    }
    else
    {
      gs = getprop("/gear/gear[0]/groundspeed-fps");
      
      if (gs != nil)
      {
        if (gs < vfriction)
        {
          setprop("/gear/gear[0]/groundspeed-fps", 0.0);
        }
        else
        {
          setprop("/gear/gear[0]/groundspeed-fps", gs - vfriction);
        }
      }
    }
  }
  
  settimer(updateRollingSpeed, 0);
}

settimer(updateRollingSpeed, 0);

# Functions for fuel cross-feed and calculations. Only updates once per second;

updateFuel = func {

  # Calculate the fuel group totals.
  var tank1 = props.globals.getNode("/consumables/fuel/tank[0]/level-lbs", 1);
  var tank2 = props.globals.getNode("/consumables/fuel/tank[1]/level-lbs", 1);
  var tank3 = props.globals.getNode("/consumables/fuel/tank[2]/level-lbs", 1);
  var tank4 = props.globals.getNode("/consumables/fuel/tank[3]/level-lbs", 1);
  var tank5 = props.globals.getNode("/consumables/fuel/tank[4]/level-lbs", 1);
  var tank6 = props.globals.getNode("/consumables/fuel/tank[5]/level-lbs", 1);
  var tank7 = props.globals.getNode("/consumables/fuel/tank[6]/level-lbs", 1);
  var tank8 = props.globals.getNode("/consumables/fuel/tank[7]/level-lbs", 1);
  var tank9 = props.globals.getNode("/consumables/fuel/tank[8]/level-lbs", 1);
  var tank10 = props.globals.getNode("/consumables/fuel/tank[9]/level-lbs", 1);
  var tank11 = props.globals.getNode("/consumables/fuel/tank[10]/level-lbs", 1);
  var tank12 = props.globals.getNode("/consumables/fuel/tank[11]/level-lbs", 1);
  var tank13 = props.globals.getNode("/consumables/fuel/tank[12]/level-lbs", 1);
  var tank14 = props.globals.getNode("/consumables/fuel/tank[13]/level-lbs", 1);

  # The tanks are split into 4 groups, each of which by default feeds one engine
  setprop("/consumables/fuel/group1-lbs",
          tank1.getValue() + tank4.getValue() + tank5.getValue() + tank7.getValue());
  setprop("/consumables/fuel/group2-lbs", tank2.getValue() + tank3.getValue() + tank6.getValue());
  setprop("/consumables/fuel/group3-lbs", tank9.getValue() + tank10.getValue() + tank13.getValue());
  setprop("/consumables/fuel/group4-lbs",
          tank8.getValue() + tank11.getValue() + tank12.getValue() + tank14.getValue());

  settimer(updateFuel, 1.0);
}

setlistener("sim/signals/fdm-initialized", updateFuel);

fire = func {

  var armament = getprop("/sim/armament");
  var bbpos = getprop("controls/doors/bb-door-pos-norm");
  
  # Check if the bomb-bay doors are open if required.
  if((armament != "BlackBuck6") and (armament != "BlueSteel") and (bbpos != 1))
  {
    setprop("/sim/messages/copilot", "Sir, the bomb bay doors are still closed!");
    return;
  }    
  
  if (armament == "BlackBuck6")
  {
    var fired = 0;  
    for (var i = 1; (i <= 4) and (fired == 0); i=i+1)
    {
      var prop = "/controls/armament/triggershrike" ~ i;
      
      if (getprop(prop) != 1)
      {
        setprop(prop, 1);
        fired = 1;
        setprop("/sim/messages/copilot", "Shrike " ~ i ~ " fired");
      }
    }
  }
  elsif ((armament == "BlackBuck1") and
         (getprop("/controls/armament/triggerbomb") != 1))
  {
    setprop("/controls/armament/triggerbomb", 1);
    setprop("/sim/messages/copilot", "Bomb number 1 dropped");
    
    settimer(func {
      # Bombing completed
      setprop("/sim/messages/copilot", "Bombs away");
      }, 21);
  }
  elsif ((armament == "WE177A") and
         (getprop("/controls/armament/triggerwe177a") != 1))
  {
    setprop("/controls/armament/triggerwe177a", 1);
    setprop("/sim/messages/copilot", "Bombs away");
  }
  elsif ((armament == "WE177B") and
         (getprop("/controls/armament/triggerwe177b") != 1))
  {
    setprop("/sim/messages/copilot", "Bombs away");
    setprop("/controls/armament/triggerwe177b", 1);
  }
  elsif ((armament == "RedBeard") and
         (getprop("/controls/armament/triggerredbeard") != 1))
  {
    setprop("/controls/armament/triggerredbeard", 1);
    setprop("/sim/messages/copilot", "Bombs away");
  }
  elsif ((armament == "BlueSteel") and
         (getprop("/controls/armament/triggerbluesteel") != 1))
  {
    setprop("/controls/armament/triggerbluesteel", 1);
    setprop("/sim/messages/copilot", "Bombs away");
  }
}

# Function to re-load armaments
reload = func {

 # Reload bombs - 21 of them.
 setprop("ai/submodels/submodel[0]/count", 21);
 
 # Shrike missiles
 setprop("ai/submodels/submodel[1]/count", 1);
 setprop("ai/submodels/submodel[2]/count", 1);
 setprop("ai/submodels/submodel[3]/count", 1);
 setprop("ai/submodels/submodel[4]/count", 1);
 
 # Red Beard
 setprop("ai/submodels/submodel[5]/count", 1);

 # Blue Steel
 setprop("ai/submodels/submodel[6]/count", 1);

 # WE177A
 setprop("ai/submodels/submodel[7]/count", 1);

 # WE177B
 setprop("ai/submodels/submodel[8]/count", 1);
 
 # Make them visible on the aircraft by "untriggering" them
 setprop("/controls/armament/triggerbomb", 0);
 setprop("/controls/armament/triggershrike1", 0);
 setprop("/controls/armament/triggershrike2", 0);
 setprop("/controls/armament/triggershrike3", 0);
 setprop("/controls/armament/triggershrike4", 0);
 setprop("/controls/armament/triggerredbeard", 0);
 setprop("/controls/armament/triggerbluesteel", 0);
 setprop("/controls/armament/triggerwe177a", 0);
 setprop("/controls/armament/triggerwe177b", 0);
}

settimer(func {
  #
	config_dialog = gui.Dialog.new("/sim/gui/dialogs/vulcanb2/config/dialog",
			"Aircraft/vulcanb2/Dialogs/config.xml");
  
  # Update the aircraft texture based on the variant    
  setlistener("sim/variant", func(n) {
	  setprop("sim/model/livery/material/texture", n.getValue() ~  ".rgb");
  });

  # Add listener for bomb impact
  setlistener("sim/armament/weapons/impact", func(n) {
    var impact = n.getValue();
    var solid = getprop(impact ~ "/material/solid");
    
    if (solid)
    {
      var long = getprop(impact ~ "/impact/longitude-deg");    
      var lat = getprop(impact ~ "/impact/latitude-deg");

      geo.put_model(
              "Aircraft/vulcanb2/Models/crater.ac",
              lat, 
              long
            );
    }
  });

}, 0);


