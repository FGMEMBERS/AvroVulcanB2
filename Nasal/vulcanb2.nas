
var config_dialog = nil;
setprop("controls/doors/chute-switch-pos", 0);

toggle_cockpit_door = func {
  if(getprop("controls/doors/cockpit-door-pos-norm") > 0) {
    interpolate("controls/doors/cockpit-door-pos-norm", 0, 4);
  } else {
    interpolate("controls/doors/cockpit-door-pos-norm", 1, 4);
  }
}
#--------------------------------------------------------------------
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
#--------------------------------------------------------------------
toggle_bb_doors = func {
  if(getprop("controls/doors/bb-door-pos-norm") > 0) {
    interpolate("controls/doors/bb-door-pos-norm", 0, 5);
  } else {
    interpolate("controls/doors/bb-door-pos-norm", 1, 5);
  }
}
#--------------------------------------------------------------------

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

fire = func {

  var variant = getprop("/sim/variant");

  if (variant == "XM597")
  {
    var fired = 0;  
    for (var i = 1; (i <= 4) and (fired == 0); i=i+1)
    {
      var prop = "/controls/armament/triggershrike" ~ i;
      
      if (getprop(prop) != 1)
      {
        setprop(prop, 1);
        fired = 1;
      }
    }
  }
  elsif (variant == "XM607")
  {
    setprop("/controls/armament/triggerbomb1", 1);
  }
  elsif (variant == "XM603")
  {
    setprop("/controls/armament/triggerredbeard", 1);
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
 
 # Make them visible on the aircraft
 setprop("/controls/armament/triggerbomb1", 0);
 setprop("/controls/armament/triggershrike1", 0);
 setprop("/controls/armament/triggershrike2", 0);
 setprop("/controls/armament/triggershrike3", 0);
 setprop("/controls/armament/triggershrike4", 0);
 setprop("/controls/armament/triggerredbeard", 0);
}

settimer(func {
  #
	config_dialog = gui.Dialog.new("/sim/gui/dialogs/vulcanb2/config/dialog",
			"Aircraft/vulcanb2/Dialogs/config.xml");
  
  # Update the aircraft texture based on the variant    
  setlistener("sim/variant", func {
	  setprop("sim/texture", cmdarg().getValue() ~  ".rgb");
  });
}, 0);
