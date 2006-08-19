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
  vfriction = 1;
  
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
