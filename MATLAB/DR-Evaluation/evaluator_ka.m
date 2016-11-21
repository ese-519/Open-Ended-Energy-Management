function evaluator_ka

% This script simulates a supervisory controller for an HVAC system. The
% controller computes the zone temperature set-point based on the current
% time and the outdoor dry-bulb temperature. The building is simulated by
% EnergyPlus. This simulation is the same as that implemented in
% simple.mdl, but uses plain Matlab code instead of Simulink.
%
% This script illustrates the usage of class mlepProcess in the MLE+
% toolbox for feedback control which involves whole building simulation.
% It has been tested with Matlab R2009b and EnergyPlus 6.0.0.
%
% This example is taken from an example distributed with BCVTB version
% 0.8.0 (https://gaia.lbl.gov/bcvtb).
%
% This script is free software.
%
% (C) 2010-2014 by Truong Nghiem (nghiem@seas.upenn.edu)
%
% CHANGES:
%   2014-08-26  Update to E+ 8.1.0.
%   2012-04-23  Fix an error with E+ 7.0.0: Matlab must read data from E+
%               before sending any data to E+.
%   2011-07-13  Update to new version of MLE+ which uses mlepInit for
%               system settings.
%   2011-04-28  Update to new version of MLE+ which uses Java for running
%               E+.

%% Create an mlepProcess instance and configure it
close all
clear all
addpath(genpath('../MLE+'))
addpath(genpath('../matlab_json_iax'))
% input_evaluator = []
% input_evaluator.start =14
% input_evaluator.end= 15
% input_evaluator.clgsetp = 24
% input_evaluator.cwsetp = 8
% input_evaluator.lil = 0.1
% savejson('',input_evaluator,'input_evaluator.json')

input_evaluator= loadjson('input_evaluator.json')
ep = mlepProcess;
%ep.arguments = {'LargeOfficeFUN', 'USA_IL_Chicago-OHare.Intl.AP.725300_TMY3'};
ep.arguments = {'LargeOfficeFUN', 'SPtMasterTable_587017_2013_amy'};
ep.acceptTimeout = 20000; % in milliseconds

VERNUMBER = 2;  % version number of communication protocol (2 as of
                % E+ 8.1.0)


%% Start EnergyPlus cosimulation
[status, msg] = ep.start;
disp('status')
status
disp ('msg')
msg
if status ~= 0
    error('Could not start EnergyPlus: %s.', msg);
end

%% The main simulation loop

EPTimeStep = 5;
SimDays = 1;
%deltaT = EPTimeStep*60;  % time step = 12 minutes
deltaT = (60/EPTimeStep)*60;
kStep = 1;  % current simulation step
MAXSTEPS = SimDays*24*EPTimeStep;  % max simulation time = 7 days

clglow = 24-1;
clghigh = 28+1;
cwlow = 6.7-1;
cwhigh = 10+1;
lilow = 0;
lihigh = 1;
minchange = 0.5;

% variables for plotting:
xx = 1:MAXSTEPS;
yyclg = nan(1,MAXSTEPS);
yycw = nan(1,MAXSTEPS);
yylit = nan(1,MAXSTEPS);


% logdata stores set-points, outdoor temperature, and zone temperature at
% each time step.
logdata = zeros(MAXSTEPS,32);

while kStep <= MAXSTEPS    
    % Read a data packet from E+
    packet = ep.read;
    if isempty(packet)
        error('Could not read outputs from E+.');
    end
%     disp('kStep')
%     kStep
%     disp('packet')
%     packet
    % Parse it to obtain building outputs
    [flag, eptime, outputs] = mlepDecodePacket(packet);
    if flag ~= 0, break; end

    % BEGIN Compute next set-points
    dayTime = mod(eptime, 86400);  % time in current day
    dayTime
    SP = [26.7 6.7 0.7];

    
    % Baseline Schedule.
%     if(dayTime <= 5*3600)
%         
%         newclg = 27;
%         newcw = 6.7;
%         newlit = 0.05;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 5*3600)&&(dayTime <= 6*3600))
%         
%         newclg = 27;
%         newcw = 6.7;
%         newlit = 0.1;
%         SP = [newclg newcw newlit];
%     end
%     
%     if((dayTime > 6*3600)&&(dayTime <= 7*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.1;
%         SP = [newclg newcw newlit];
%     end
%     
%     if((dayTime > 7*3600)&&(dayTime <= 8*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.3;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 8*3600)&&(dayTime <= 9*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.9;
%         SP = [newclg newcw newlit];
%     end
 
    if(dayTime > 14*3600) && (dayTime <= 15*3600)
        
       if (input_evaluator.start==14 && input_evaluator.end ==15)
           newclg = input_evaluator.clgsetp;
           newcw = input_evaluator.cwsetp;
           newlit = input_evaluator.lil;
       SP = [newclg newcw newlit]; 
       end
    end
    if(dayTime > 16*3600) && (dayTime <= 17*3600)
        
       if (input_evaluator.start==16 && input_evaluator.end ==17)
           newclg = input_evaluator.clgsetp;
           newcw = input_evaluator.cwsetp;
           newlit = input_evaluator.lil;  
           SP = [newclg newcw newlit];
       end      
    end
%        if(dayTime > 17*3600) && (dayTime <= 18*3600)
%         
%        if (input.start==17 && input.end ==18)
%            newclg = input.clgsetp;
%            newcw = input.cwsetp;
%            newlit = input.lil;        
%         SP = [newclg newcw newlit];
%        end
%         
%     end
    
%     if((dayTime > 18*3600)&&(dayTime <= 19*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.7;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 18*3600)&&(dayTime <= 20*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.5;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 20*3600)&&(dayTime <= 22*3600))
%         
%         newclg = 24;
%         newcw = 6.7;
%         newlit = 0.3;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 22*3600)&&(dayTime <= 23*3600))
%         
%         newclg = 27;
%         newcw = 6.7;
%         newlit = 0.1;
%         SP = [newclg newcw newlit];
%     end
%     if((dayTime > 23*3600)&&(dayTime <= 24*3600))
%         
%         newclg = 27;
%         newcw = 6.7;
%         newlit = 0.05;
%         SP = [newclg newcw newlit];
%     end
    
    oldclg = SP(1);
    oldcw = SP(2);
    oldlit = SP(3);
    
    % also plot the set-points as they are sent ot E+.
    
    yyclg(kStep) = SP(1);
    yycw(kStep) = SP(2);
    yylit(kStep) = SP(3);
    
    % Write to inputs of E+
    ep.write(mlepEncodeRealData(VERNUMBER, 0, (kStep-1)*deltaT, SP));
    
    % Save to logdata
    logdata(kStep, :) = outputs;
    
    kStep = kStep + 1;
end

% Stop EnergyPlus
ep.stop;

disp(['Stopped with flag ' num2str(flag)]);

% Remove unused entries in logdata
kStep = kStep - 1;
if kStep < MAXSTEPS
    logdata((kStep+1):end,:) = [];
end

% save logdata_vanilla.mat logdata
response =[];
response.time = 1:MAXSTEPS;
response.y_predict = logdata(:,1);
savejson('',response,'response.json');
%figure
%plot(1:MAXSTEPS,yyclg);
%figure
%plot(1:MAXSTEPS,yycw);
%figure
%plot(1:MAXSTEPS,yylit);
%figure
%plot(1:MAXSTEPS,logdata(:,1));
end
