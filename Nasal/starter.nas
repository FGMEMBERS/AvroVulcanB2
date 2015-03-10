# Engine starter management. Currently selected engine for starter. Start only works on one engine at a time.
var currentEngine = props.globals.getNode("/controls/engines/starter-selected");
var master = props.globals.getNode("/controls/engines/master");
var engaged = props.globals.getNode("/controls/engines/starter-engaged");

# There is an interconnect between the starter selector and the starter button
var incStarter = func {
  if (! engaged.getValue())
  {
    currentEngine.setValue(math.mod(currentEngine.getValue() + 1, 4));
  }
}

var setMasterOff = func {
    # Toggle master off. All magnetos off.
    foreach (var e; controls.engines)
    {
      e.controls.getNode("magnetos").setValue(0);
      e.controls.getNode("cutoff").setBoolValue(1);
      e.controls.getNode("fuel-pump").setBoolValue(0);
    }
    master.setValue(0);
}

var setMasterOn = func {
    # Toggle master on. All magnetos to "both".
    foreach (var e; controls.engines)
    {
      e.controls.getNode("magnetos").setValue(3);
      e.controls.getNode("cutoff").setBoolValue(0);
      e.controls.getNode("fuel-pump").setBoolValue(1);
    }
    master.setValue(1);

}

# Toggle the main engine master switch.
var toggleMaster = func {
  if (master.getValue())
  {
    setMasterOff();
  }
  else
  {
    setMasterOn();
  }
}

# Function to release the starter, once the engine is running (approx 14 seconds)
var releaseStarter = func {
  engaged.setBoolValue(0);
  controls.engines[currentEngine.getValue()].controls.getNode("starter").setBoolValue(0);
}

# Function to disengage cut-off, once we reach 25% N2 (approx 14 seconds)
var disengageCutOff = func {
  controls.engines[currentEngine.getValue()].controls.getNode("cutoff").setBoolValue(0);
  settimer(releaseStarter, 20);
}

# Start the current engine. Note that we don't use the controls.nas methods
# as there is an interconnect between the engine starter and the selector.
var pressStarter = func {
  engaged.setBoolValue(1);
  controls.engines[currentEngine.getValue()].controls.getNode("cutoff").setBoolValue(1);
  controls.engines[currentEngine.getValue()].controls.getNode("starter").setBoolValue(1);
  settimer(disengageCutOff, 20);
}

# External auto-start of all engines
var autoStart = func {

    setprop("/sim/messages/ground", "External Engine start initiated.");

    # Toggle master on. All magnetos to "both".
    foreach (var e; controls.engines)
    {
      e.controls.getNode("magnetos").setValue(3);
      e.controls.getNode("cutoff").setBoolValue(1);
      e.controls.getNode("fuel-pump").setBoolValue(1);
    }
    
    master.setValue(1);

    # Series of starting events, as the engines start one by one.
    settimer( func { controls.engines[0].controls.getNode("starter").setBoolValue(1); }, 2);
    settimer( func { controls.engines[1].controls.getNode("starter").setBoolValue(1); }, 4);
    settimer( func { controls.engines[2].controls.getNode("starter").setBoolValue(1); }, 6);
    settimer( func { controls.engines[3].controls.getNode("starter").setBoolValue(1); }, 8);

    settimer( func {
      foreach (var e; controls.engines)
      {
        e.controls.getNode("cutoff").setBoolValue(0);
      }
    }, 20);

    # Switch off all the starters
    settimer( func {
      foreach (var e; controls.engines)
      {
        e.controls.getNode("starter").setValue(0);
      }
      
      setprop("/sim/messages/ground", "Engine start complete.");
    }, 40);
}

