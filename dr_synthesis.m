function dr_synthesis
clc
clear all
close all

%% Create an mlepProcess instance and configure it

ep = mlepProcess;
ep.arguments = {'LargeOfficeDR', 'USA_IL_Chicago-OHare.Intl.AP.725300_TMY3'};
ep.acceptTimeout = 20000; % in milliseconds

VERNUMBER = 2;  % version number of communication protocol (2 as of
                % E+ 8.1.0)
                
% Load the tree and the linear models
load drtree12.mat
load dr12control.mat

t1 = datetime('17-Jul-2014 00:00');
t2 = datetime('17-Jul-2014 23:55');
timevec = t1:minutes(5):t2;


%% Start EnergyPlus cosimulation
[status, msg] = ep.start;

if status ~= 0
    error('Could not start EnergyPlus: %s.', msg);
end

%% The main simulation loop

EPTimeStep = 12;
SimDays = 1;
deltaT = EPTimeStep*60;  % time step = 12 minutes
kStep = 1;  % current simulation step
MAXSTEPS = SimDays*24*EPTimeStep;  % max simulation time = 7 days

clglow = 24;
clghigh = 28;
cwlow = 6.7;
cwhigh = 10;
lilow = 0.8;
lihigh = 1;
minchange = 0.5;

% variables for plotting:
xx = 1:MAXSTEPS;
yyclg = nan(1,MAXSTEPS);
yycw = nan(1,MAXSTEPS);
yylit = nan(1,MAXSTEPS);
listofidx = zeros(1,MAXSTEPS);
baseest = zeros(1,MAXSTEPS);

% logdata stores set-points, outdoor temperature, and zone temperature at
% each time step.
numoutvars = 32;
logdata = zeros(MAXSTEPS,numoutvars);

while kStep <= MAXSTEPS    
    % Read a data packet from E+
    packet = ep.read;
    if isempty(packet)
        error('Could not read outputs from E+.');
    end
    
    % Parse it to obtain building outputs
    [flag, eptime, outputs] = mlepDecodePacket(packet);
    if flag ~= 0, break; end
    
    % decode outputs
    tpower = outputs(1);
    tod = outputs(2);
    dow = outputs(3);
    chws1 = outputs(4);
    chws2 = outputs(5);
    boiler = outputs(6);
    basezat = outputs(7);
    corebzat = outputs(8);
    coremzat = outputs(9);
    coretzat = outputs(10);
    gfplenum = outputs(11);
    mfplenum = outputs(12);
    peribot1zat = outputs(13);
    peribot2zat = outputs(14);
    peribot3zat = outputs(15);
    peribot4zat = outputs(16);
    perimid1zat = outputs(17);
    perimid2zat = outputs(18);
    perimid3zat = outputs(19);
    perimid4zat = outputs(20);
    peritop1zat = outputs(21);
    peritop2zat = outputs(22);
    peritop3zat = outputs(23);
    peritop4zat = outputs(24);
    topplenum = outputs(25);
    outdry = outputs(26);
    outwet = outputs(27);
    winspeed = outputs(28);
    windir = outputs(29);
    outhum = outputs(30);
    htgsetp = outputs(31);
    hwsetp = outputs(32);
    
    forecast = [basezat,boiler,chws1,chws2,corebzat,coremzat...
    ,coretzat,dow,gfplenum,htgsetp,hwsetp,mfplenum,outdry,outhum...
    ,outwet,peribot1zat,peribot2zat,peribot3zat,peribot4zat,perimid1zat...
    ,perimid2zat,perimid3zat,perimid4zat,peritop1zat,peritop2zat...
    ,peritop3zat,peritop4zat,tod,topplenum,windir,winspeed];
        
    % BEGIN Compute next set-points
    dayTime = mod(eptime, 86400);  % time in current day
    if (dayTime >= 6*3600) && (dayTime <= 18*3600)
        % It is day time (6AM-6PM)
        
       % SP = [Zone ChWater Light]
        
        SP = [24 6.7 1];
        
        % DR event (4PM-5PM)
        if(dayTime >= 16*3600) && (dayTime <= 17*3600)
            
            
            leafout = predict(drtree12,forecast);
            % idx is the leaf index for the model.
            for idx = 1:length(dr12)
                if(leafout == dr12(idx).mean)
                    break;
                end
            end
            
            % keep track of whihc model is being used
            listofidx(kStep) = idx;
            baseest(kStep) = dr12(idx).mean;
            
            cvx_begin
                variables clgset cwset litset;
                minimize (dr12(idx).mdl{1,1}.Coefficients{1,1} + ...
                    (dr12(idx).mdl{1,1}.Coefficients{2,1}*clgset) + ...
                    (dr12(idx).mdl{1,1}.Coefficients{3,1}*cwset)+ ...
                    (dr12(idx).mdl{1,1}.Coefficients{4,1}*litset));
            subject to
                clglow <= clgset <= clghigh;
                cwlow <= cwset <= cwhigh;
                lilow <= litset <= lihigh;
            cvx_end
            
            clgset = clghigh;
            cwset = cwhigh;
            SP = [clgset cwset litset];
            
        end
        
        % recovery
        if(dayTime > 17*3600) && (dayTime <= 18*3600)
            
            clgset = 26;
            cwset = 8.5;
            litset = 0.7;
            
            SP = [clgset cwset litset];
            
        end
    else
        % The Heating set-point: day -> 20, night -> 16
        % The Cooling set-point: night -> 30
        SP = [27 6.7 0.5];
    end
    % END Compute next set-points
    
%     if(idx~=0)
%         listofidx(kStep) = idx;
%     end
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

plotdur = 150:246;
ptimevec = timevec(plotdur);

% figure(1);
% plot(ptimevec,logdata(plotdur,1)/1e6);
% hold on
% ylim([0 0.85])
% vline(datetime(ptimevec(44)),'-r','Start');
% vline(datetime(ptimevec(56)),'-r','End');
% vline(datetime(ptimevec(68)),'-b','Recovery');
% datetick('x','HH:MM');
% hold off
% grid on;
% 
% figure(2);
% plot(ptimevec,yyclg(plotdur));
% hold on
% [AX,H1,H2] = plotyy(ptimevec,yycw(plotdur),ptimevec,yylit(plotdur));
% set(AX(1),'YLim',[0 30])
% set(AX(2),'YLim',[0 1.2])
% ylabel('Temperature')
% set(get(AX(2),'Ylabel'),'string','Light Level (ratio)')
% %plot(ptimevec,yylit(plotdur));
% vline(datetime(ptimevec(44)),'-r','Start');
% vline(datetime(ptimevec(56)),'-r','End');
% vline(datetime(ptimevec(68)),'-b','Recovery');
% legend('CLGSETP','CWSETP','LIGHT');
% datetick('x','HH:MM');
% grid on;
% hold off

response=[];
response.yyclg = yyclg(plotdur);
response.yycw = yycw(plotdur);
response.yylit = yylit(plotdur);
response.optimal_clg = 28;
response.optimal_cw = 10;
response.optimal_lit = 0.8;
response.time = plotdur;
savejson('',response,'Filename',['response.json']);
plotdur = 193:206;
ptimevec = timevec(plotdur);

% figure(3);
% plot(ptimevec,logdata(plotdur,1)/1e6);
% ylim([0 0.85])
% vline(datetime(ptimevec(1)),'-r','Start');
% vline(datetime(ptimevec(13)),'-r','End');
% datetick('x','HH:MM');
% grid on;
end
