library('move2')
library('dplyr')

#min_act_change: minimum required activity change within the specified time interval
#time_itv and time_unit: time interval of how far back from the end of each track one shall have a look at the activity

rFunction = function(data, min_act_change=NULL,time_itv=NULL,time_unit="hours",volt.name="tag_voltage",volt_thr=NULL,activity.name="activity_count",circ=256) {
 
  if (is.null(min_act_change) | is.null(time_itv) | is.null(volt_thr))
  {
    logger.info("You have not defined the settings min_act_change (minimum change in activity count), volt_thr (voltage threshold) and/or time_itv (time interval to look at). This will lead to an error. Please go back and configure the App properly.")
  }
  
  data.split <- split(data,mt_track_id(data))
  
  datai.ends <- lapply(data.split, function(x) 
  {
    endtime <- max(mt_time(x))
    begtime <- endtime - as.difftime(time_itv, format="%X", units=time_unit)
    x[mt_time(x)>=begtime & mt_time(x)<=endtime,]
  }) #for each track at least the last row is kept (len>=1)
  
  if (!(volt.name %in% names(data)))
  {
    logger.info ("Your defined voltage attribute name does not exist in the data. Please check the spelling in the summary view's track attributes section of the preceding App. No voltage attributes are added.")
    result <- data
  } else
  {
    volt.i <- lapply(datai.ends, function(x)
    {
      #print(x)
      if (dim(x)[1]>=2)
      {
        eval(parse(text=paste0("voltage <- x$",volt.name))) 
        timestamp.end <- x$timestamp[length(voltage)]
        voltage.end <- voltage[length(voltage)]
        dtu <- difftime(mt_time(x),mt_time(x)[1],units=time_unit)
        len <- dim(x)[1]
        lin.slp <- coefficients(lm(voltage ~ dtu))[2] #slope is estimated change in voltage by the provided time_unit
        units(lin.slp) <- paste0(units(voltage),"/",time_unit)
        voltage_alert <- 0
        if (as.numeric(voltage.end) < volt_thr) voltage_alert <- 1
        data.frame("individual_local_identifier"=mt_track_id(x)[1],"number_of_measuremens"=len,"timestamp_end"=timestamp.end,"voltage_end"=voltage.end,"est_voltage_change_rate"=lin.slp,"voltage_alert"=voltage_alert)
      } else if (dim(x)[1]==1) #special case 1 measurement, no change rate possible
      {
        logger.info(paste("For the track",mt_track_id(x)[1],"only one measurement lies in the defined time interval. Therefore, no voltage slope can be calculated."))
        eval(parse(text=paste0("voltage <- x$",volt.name))) 
        timestamp.end <- x$timestamp
        voltage.end <- voltage
        voltage_alert <- 0
        if (as.numeric(voltage.end) < volt_thr) voltage_alert <- 1
        data.frame("individual_local_identifier"=mt_track_id(x)[1],"number_of_measuremens"=1,"timestamp_end"=timestamp.end,"voltage_end"=voltage.end,"est_voltage_change_rate"=NA,"voltage_alert"=voltage_alert)
      } else #should never reach this branch
      {
        logger.info("By some unforeseen circumstance, the data contains a track without measurements. This track is not integrated in the output.")
        data.frame("individual_local_identifier"=character(),"number_of_measuremens"=numeric(),"timestamp_end"=character(),"voltage_end"=numeric(),"est_voltage_change_rate"=numeric(),"voltage_alert"=numeric())
      }
    })
    volt <- Reduce(full_join,volt.i)
    
    alert_file <- volt
    ii <- which(names(alert_file) %in% c("voltage_end","est_voltage_change_rate","max_activity_dt"))
    names(alert_file)[ii] <- paste0(names(alert_file[,ii])," [",sapply(alert_file[,ii], function(x) as.character(units(x))),"]")
  }
  
  if (!(activity.name %in% names(data)))
  {
    logger.info ("Your defined activity attribute does not exist in the data. Please check the spelling in the summary view's track attributes section of the preceding App. No activity and mortality alert attributes are added.")
    result <- data
  } else
  {
    ch.act.i <- lapply(datai.ends, function(x)
    {
      if (dim(x)[1]>=2)
      {
        eval(parse(text=paste0("activity <- x$",activity.name))) 
        d0 <- dist(activity)  #diff of all pairs
        d <- pmin(d0 %% circ, (circ-d0) %% circ)
        maxdiff <- max(d)
        len <- dim(x)[1]
        ixs <- unique(c(which(as.matrix(d)==maxdiff,arr.ind=TRUE)))
        maxdt <- difftime(mt_time(x)[max(ixs)],mt_time(x)[min(ixs)])
        ts <- mt_time(x)[max(ixs)] #latest timestamp of maxdiff measurement
        alert <- 0
        if (maxdiff < min_act_change) alert <- 1
        data.frame("individual_local_identifier"=mt_track_id(x)[1],"number_of_measuremens"=len,"max_activity_timestamp"=ts,"max_activity_dt"=maxdt,"max_activity_difference"=maxdiff,"activity_alert"=alert)
      } else if (dim(x)[1]==1)
      {
        logger.info(paste("For the track",mt_track_id(x)[1],"only one measurement lies in the defined time interval. Therefore, no activity difference can be calculated and the activity alert is set to NA."))
        ts <- mt_time(x)
        data.frame("individual_local_identifier"=mt_track_id(x)[1],"number_of_measuremens"=1,"max_activity_timestamp"=ts,"max_activity_dt"=NA,"max_activity_difference"=NA,"activity_alert"=NA)
      } else
      {
        logger.info("By some unforeseen circumstance, the data contains a track without measurements. This track is not integrated in the output.")
        data.frame("individual_local_identifier"=character(),"number_of_measuremens"=numeric(),"max_activity_timestamp"=character(),"max_activity_dt"=numeric(),"max_activity_difference"=numneric(),"activity_alert"=numeric())
      }
    })
    ch.act <- Reduce(full_join,ch.act.i)
    
    if (volt.name %in% names(data)) alert_file <- full_join(volt,ch.act[,-2],by="individual_local_identifier") else alert_file <- ch.act
    ii <- which(names(alert_file) %in% c("voltage_end","est_voltage_change_rate","max_activity_dt"))
    names(alert_file)[ii] <- paste0(names(alert_file[,ii])," [",sapply(alert_file[,ii], function(x) as.character(units(x))),"]") #add units to column names
  }

  if (exists("alert_file")) 
  {
    write.csv(alert_file,appArtifactPath("Mortality_Alert_Infos.csv"),row.names=FALSE)
    result <- mt_set_track_data(data,left_join(mt_track_data(data),alert_file)) #add all warning data to track data of move2 results object
  } else result <- data
  
  return(result)
}

#return end time interval of tracks with alert