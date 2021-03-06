fire_MG = func {
        if(getprop("controls/armament/stick-selector")==1){
          setprop("/controls/armament/trigger", 1);
        }
        if(getprop("controls/armament/stick-selector")==2){
           var pylon = getprop("controls/armament/missile/current-pylon");
           load.dropLoad(pylon);
        }
}

stop_MG = func {
        setprop("/controls/armament/trigger", 0); 
}
var flash_trigger = props.globals.getNode("controls/armament/trigger", 0);

reload_Cannon = func {
        setprop("ai/submodels/submodel/count",75);
        setprop("ai/submodels/submodel[1]/count",75);
        setprop("ai/submodels/submodel[2]/count",75);
        setprop("ai/submodels/submodel[3]/count",75);
}

    var searchCmd = func
                    {
                        var results = [];
                        var loadedModels = props.globals.getNode("models").getChildren();
                       
                        foreach (var model; loadedModels)
                            if (cmp(substr(model.getValue("path"), 0, 10), "Scenery/Models/LFGG-WWI/AA/") == 0)  # only process models loaded from $FG_ROOT/Models/AA/
                                append(results, model);

                        return results;
                    };


var RadarStandby      = props.globals.getNode("instrumentation/radar/radar-standby");

MPjoin = func(n) {
   #print(n.getValue(), " added");
   setprop("instrumentation/radar",n.getValue(),"radar/y-shift",0);
   setprop("instrumentation/radar",n.getValue(),"radar/x-shift",0);
   setprop("instrumentation/radar",n.getValue(),"radar/rotation",0);
   setprop("instrumentation/radar",n.getValue(),"radar/in-range",0);
   setprop("instrumentation/radar",n.getValue(),"radar/h-offset",180);
   setprop("instrumentation/radar",n.getValue(),"joined",1);
}
MPleave= func(n) {
   #print(n.getValue(), " removed");
   setprop("instrumentation/radar",n.getValue(),"radar/in-range",0);
   setprop("instrumentation/radar",n.getValue(),"joined",0);
}


#need to copy the properties so that we never try to access a non-existent property in XML
MPradarProperties = func {
   #print("t0tO dans les bois");
   var Estado = RadarStandby.getValue();
   if ( Estado != 1 ) {
      targetList = props.globals.getNode("ai/models/").getChildren("multiplayer");
      foreach (d; props.globals.getNode("ai/models/").getChildren("aircraft")) {
         append(targetList,d);
      }
      foreach (d; props.globals.getNode("ai/models/").getChildren("tanker")) {
         append(targetList,d);
      }
      foreach (m; targetList) {
         var string = "instrumentation/radar/ai/models/"~m.getName()~"["~m.getIndex()~"]/";
         if (getprop(string,"joined")==1 or m.getName()=="aircraft") {
            factor = getprop("instrumentation/radar/range-factor"); ## if (factor == nil) { factor=0.001888};
            setprop(string,"radar/y-shift",m.getNode("radar/y-shift").getValue() * factor);
            setprop(string,"radar/x-shift",m.getNode("radar/x-shift").getValue() * factor);
            setprop(string,"radar/rotation",m.getNode("radar/rotation").getValue());
            setprop(string,"radar/h-offset",m.getNode("radar/h-offset").getValue());
   
            if (getprop("instrumentation/radar/selected")==2){
               if (getprop(string~"radar/x-shift") < -0.04 or 
                   getprop(string~"radar/x-shift") > 0.04) {
                  setprop(string,"radar/in-range",0);
               } else {
                  setprop(string,"radar/in-range",m.getNode("radar/in-range").getValue());
               }
            } else {
               setprop(string,"radar/in-range",m.getNode("radar/in-range").getValue());
            }
         } 
      }


# ===================
# Boresight Detecting
# ===================
locking=0;
found=-1;

boreSightLock = func {
   var Estado = RadarStandby.getValue();

   if ( Estado != 1 ) {

   if(getprop("instrumentation/radar/selected") == 1){

      targetList= props.globals.getNode("ai/models/").getChildren("multiplayer");
      foreach (d; props.globals.getNode("ai/models/").getChildren("aircraft")) {
         append(targetList,d);
      }
      foreach (d; props.globals.getNode("ai/models/").getChildren("tanker")) {
         append(targetList,d);
      }

      foreach (m; targetList) {
          var string = "instrumentation/radar/ai/models/"~m.getName()~"["~m.getIndex()~"]";
          var string1 = "ai/models/"~m.getName()~"["~m.getIndex()~"]";
          if (getprop(string1~"radar/in-range")) {

            hOffset = getprop(string1~"radar/h-offset");
            vOffset = getprop(string1~"radar/v-offset");

            #really should be a cone, but is a square pyramid to avoid trigonemetry
            if(hOffset < 120 and hOffset > -120 and vOffset < 90 and vOffset > -10) {
               if (locking == 11){
                  setprop(string~"radar/boreLock",2);
                  setprop("instrumentation/radar/lock",2);
                  # setprop("sim[0]/hud/current-color",1);
                  locking -= 1;
               }
               elsif (locking ==1 or locking ==3 or locking ==5 or locking ==7 or locking ==9 ) {
                  setprop("instrumentation/radar/lock",1);
                  setprop(string1~"radar/boreLock",1);
               }
               else {
                  setprop("instrumentation/radar/lock",0);
                  setprop(string~"radar/boreLock",1);
               }

               if (found != m.getIndex()) {
                  found=m.getIndex();
                  locking=0;
               }
               else {
                  locking += 1;
               }
               settimer(boreSightLock, 0.2);
               return;
            }
         }
      }
      setprop(string~"radar/boreLock",0);
      locking=0;
      # setprop("sim[0]/hud/current-color",0);
   } # from getprop
   } # from Estado

   locking=0;
   # setprop("sim[0]/hud/current-color",0);
   found =-1;
   setprop("instrumentation/radar/lock",0);

   settimer(boreSightLock, 0.2);
}


setlistener("ai/models/model-added", MPjoin);
setlistener("ai/models/model-removed", MPleave);
settimer(MPradarProperties,1.0);
settimer(boreSightLock, 1.0);

