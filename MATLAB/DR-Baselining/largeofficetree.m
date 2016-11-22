%{

Variables:

DateTime     clgsetp      gfplenum     outwet       perimid2zat  peritop4zat  
basezat      corebzat     htgsetp      peribot1zat  perimid3zat  tod          
boiler1      coremzat     hwsetp       peribot2zat  perimid4zat  topplenum    
chws1        coretzat     mfplenum     peribot3zat  peritop1zat  tpower       
chws2        dom          outdry       peribot4zat  peritop2zat  windir       
chwsetp      dow          outhum       perimid1zat  peritop3zat  winspeed     


%}

clc 
clear 
%close all

%% Prepare Training data, i.e from 2012
disp('Preparing data..');

load large_office_all_data_2k12.mat

% Feature matrix with all 34 features as columns
Xtrain = [basezat,boiler1,chws1,chws2,chwsetp,clgsetp,corebzat,coremzat...
    ,coretzat,dom,dow,gfplenum,htgsetp,hwsetp,mfplenum,outdry,outhum...
    ,outwet,peribot1zat,peribot2zat,peribot3zat,peribot4zat,perimid1zat...
    ,perimid2zat,perimid3zat,perimid4zat,peritop1zat,peritop2zat...
    ,peritop3zat,peritop4zat,tod,topplenum,windir,winspeed];
Xtrain(1,:)=[];
% Output vector
Ytrain = tpower;
Ytrain(1,:)=[];

load date12num.mat

% Column names and indicies of the columns which are categorical

colnames={'basezat','boiler','chws1','chws2','chwsetp','clgsetp','corebzat','coremzat'...
    ,'coretzat','dom','dow','gfplenum','htgsetp','hwsetp','mfplenum','outdry','outhum'...
    ,'outwet','peribot1zat','peribot2zat','peribot3zat','peribot4zat','perimid1zat'...
    ,'perimid2zat','perimid3zat','perimid4zat','peritop1zat','peritop2zat'...
    ,'peritop3zat','peritop4zat','tod','topplenum','windir','winspeed'};
catcol = [10,11,31];

disp('Done.');

%% Start Tree Regression
disp('Learning Regression Tree on 2012 Annual Data');

minleaf = 10;   % minimium number of leaf node observations
tic
largetree12 = fitrtree(Xtrain,Ytrain,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
toc
% view the tree view(rtree);
%view(largetree12,'mode','graph');

% predict on training and testing data and plot the fits
Yfit = predict(largetree12,Xtrain);

% RMSE
[a,b]=rsquare(Ytrain,Yfit);
fprintf('2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak: %.4f, NRMSD: %.2f \n\n'...
    ,b,a,(b/max(Ytrain)),(100*b/(max(Ytrain)-min(Ytrain))));


%% Now train a model only for June index June from 43488 to 52127
disp('Learning Regression Tree on 2012 June Data');

junstart = 43488;
junend = 52127;
XtrainJun = Xtrain(junstart:junend,:);
YtrainJun = Ytrain(junstart:junend);
date12numJun = date12num(junstart:junend);

tic
largetree12Jun = fitrtree(XtrainJun,YtrainJun,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
toc
% predict on training and testing data and plot the fits
YfitJun = predict(largetree12Jun,XtrainJun);
% RMSE
[a,b]=rsquare(YtrainJun,YfitJun);
fprintf('June 2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtrainJun)),(100*b/(max(YtrainJun)-min(YtrainJun))));

%% Now train a model only for July index July from 52128 to 61055
disp('Learning Regression Tree on 2012 July Data');

julstart = 52128;
julend = 61055;
XtrainJul = Xtrain(julstart:julend,:);
YtrainJul = Ytrain(julstart:julend);
date12numJul = date12num(julstart:julend);

tic
largetree12Jul = fitrtree(XtrainJul,YtrainJul,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
toc
% predict on training and testing data and plot the fits
YfitJul = predict(largetree12Jul,XtrainJul);
% RMSE
[a,b]=rsquare(YtrainJul,YfitJul);
fprintf('July 2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtrainJul)),(100*b/(max(YtrainJul)-min(YtrainJul))));


%% Now prepare testing data, i.e from 2013.
disp('Evaluating on 2013 Testing Data');

load large_office_all_data_2k13.mat

% Feature matrix with all 34 features as columns
Xtest = [basezat,boiler1,chws1,chws2,chwsetp,clgsetp,corebzat,coremzat...
    ,coretzat,dom,dow,gfplenum,htgsetp,hwsetp,mfplenum,outdry,outhum...
    ,outwet,peribot1zat,peribot2zat,peribot3zat,peribot4zat,perimid1zat...
    ,perimid2zat,perimid3zat,perimid4zat,peritop1zat,peritop2zat...
    ,peritop3zat,peritop4zat,tod,topplenum,windir,winspeed];
Xtest(1,:)=[];
XtestJul = Xtest(julstart:julend,:);
XtestJun = Xtest(junstart:junend,:);
% Output vector
Ytest = tpower;
Ytest(1,:)=[];
YtestJul = Ytest(julstart:julend);
YtestJun = Ytest(junstart:junend);

% Ontain Predictions for the entire year and for just july
Ypredict = predict(largetree12,Xtest);  
YpredictJul = predict(largetree12Jul,XtestJul);
YpredictJun = predict(largetree12Jun,XtestJun);

% RMSE
[a,b]=rsquare(Ytest,Ypredict);
fprintf('2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(Ytest)),(100*b/(max(Ytest)-min(Ytest))));

% RMSE
[a,b]=rsquare(YtestJun,YpredictJun);
fprintf('June 2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(YtestJun)),(100*b/(max(YtestJun)-min(YtestJun))));

% RMSE
[a,b]=rsquare(YtestJul,YpredictJul);
fprintf('July 2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtestJul)),(100*b/(max(YtestJul)-min(YtestJul))));


%% Improve the tree by using k-fold cross validation
disp('Learning a  cross validated tree for 2012 annual data');

kf = 20;

tic
largetreeCV = fitrtree(Xtrain,Ytrain,'PredictorNames',colnames,...
    'ResponseName','Total Power','CategoricalPredictors',catcol,...
    'MinLeafSize',minleaf,'CrossVal','on','KFold',kf); % default is 10-fold
toc

YfitCV = kfoldPredict(largetreeCV);

% RMSE
[a,b]=rsquare(Ytrain,YfitCV);
fprintf('Cross Validated 2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak %.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(Ytrain)),(100*b/(max(Ytrain)-min(Ytrain))));

% Now use the cross validated trees to make predictions on the 2013 testing
% data
YpredictCVk=zeros(length(Xtest),kf);
for ii=1:kf
    YpredictCVk(:,ii)=predict(largetreeCV.Trained{ii,1},Xtest);
end
YpredictCV = sum(YpredictCVk,2)/kf;

% RMSE
[a,b]=rsquare(Ytest,YpredictCV);
fprintf('Cross Validated 2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(Ytest)),(100*b/(max(Ytest)-min(Ytest))));

%% Now use cross validated tree but just for June
disp('Learning a cross validated tree for 2012 June data');

tic
largetreeCVJun = fitrtree(XtrainJun,YtrainJun,'PredictorNames',colnames,...
    'ResponseName','Total Power','CategoricalPredictors',catcol,...
    'MinLeafSize',minleaf,'CrossVal','on','KFold',kf); % default is 10-fold
toc

YfitCVJun = kfoldPredict(largetreeCVJun);

% RMSE
[a,b]=rsquare(YtrainJun,YfitCVJun);
fprintf('Cross Validated June 2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak %.4f, NRMSD: %0.2f \n',...
    b,a,(b/max(YtrainJun)),(100*b/(max(YtrainJun)-min(YtrainJun))));

% Now use the cross validated trees to make predictions on the 2013 testing
% data
YpredictCVkJun=zeros(length(XtestJun),kf);
for ii=1:kf
    YpredictCVkJun(:,ii)=predict(largetreeCVJun.Trained{ii,1},XtestJun);
end
YpredictCVJun = sum(YpredictCVkJun,2)/kf;

% RMSE
[a,b]=rsquare(YtestJun,YpredictCVJun);
fprintf('Cross Validated June 2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtestJun)),(100*b/(max(YtestJun)-min(YtestJun))));

%% Now use cross validated tree but just for July
disp('Learning a cross validated tree for 2012 July data');

tic
largetreeCVJul = fitrtree(XtrainJul,YtrainJul,'PredictorNames',colnames,...
    'ResponseName','Total Power','CategoricalPredictors',catcol,...
    'MinLeafSize',minleaf,'CrossVal','on','KFold',kf); % default is 10-fold
toc
save largetreeCVJul.mat largetreeCVJul
YfitCVJul = kfoldPredict(largetreeCVJul);

% RMSE
[a,b]=rsquare(YtrainJul,YfitCVJul);
fprintf('Cross Validated July 2012(Training) RMSE(W): %.2f, R2: %.3f, RMSE/peak %.4f, NRMSD: %0.2f \n',...
    b,a,(b/max(YtrainJul)),(100*b/(max(YtrainJul)-min(YtrainJul))));

% Now use the cross validated trees to make predictions on the 2013 testing
% data
YpredictCVkJul=zeros(length(XtestJul),kf);
for ii=1:kf
    YpredictCVkJul(:,ii)=predict(largetreeCVJul.Trained{ii,1},XtestJul);
end
YpredictCVJul = sum(YpredictCVkJul,2)/kf;

% RMSE
[a,b]=rsquare(YtestJul,YpredictCVJul);
fprintf('Cross Validated July 2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtestJul)),(100*b/(max(YtestJul)-min(YtestJul))));


%% Plot the results
disp('Plotting results..');

figure();
plot(date12num,Ytrain);
title('Total Power Fit for Training Data (2012)');
hold on;
plot(date12num,Yfit);
plot(date12num,YfitCV);
datetick('x','mmm');
hold off;
legend('Ground Truth','Single Tree','CV Tree');

figure();
plot(date12numJun,YtrainJun);
title('Total Power Fit for June Training Data (2012)');
hold on;
plot(date12numJun,YfitJun);
plot(date12numJun,YfitCVJun);
datetick('x','dd');
hold off;
legend('Ground Truth','Single Tree','CV Tree');

figure();
plot(date12numJul,YtrainJul);
title('Total Power Fit for July Training Data (2012)');
hold on;
plot(date12numJul,YfitJul);
plot(date12numJul,YfitCVJul);
datetick('x','dd');
hold off;
legend('Ground Truth','Single Tree','CV Tree');

figure();
plot(date12num,Ytest);
title('Total Power Fit for Testing Data (2013)');
hold on;
plot(date12num,Ypredict);
plot(date12num,YpredictCV);
datetick('x','mmm');
hold off;
legend('Ground Truth','Single Tree','CV Tree');

figure();
plot(date12numJun,YtestJun);
title('Total Power Fit for June Testing Data (2013)');
hold on;
plot(date12numJun,YpredictJun);
plot(date12numJun,YpredictCVJun);
datetick('x','dd');
hold off;
legend('Ground Truth','Single Tree','CV Tree');

figure();
plot(date12numJul,YtestJul);
title('Total Power Fit for July Testing Data (2013)');
hold on;
plot(date12numJul,YpredictJul);
plot(date12numJul,YpredictCVJul);
datetick('x','dd');
hold off;
legend('Ground Truth','Single Tree','CV Tree');
save date12numJul.mat date12numJul
%%
pause on
disp('Press any key to continue to DR Policy Evaluation..');
pause
pause off

%%
disp('July 17th was a PLC day in 2013 for PJM.');
disp('Evaluating how well could we predict the baseline consumption');

% close all

% PLC day from 2013
% July 17th datemin[56736:57023] 
% 4pm: 57216
% 5pm: 57228
% 6pm: 57240
% 7pm: 57252
%XtestPlc17 = Xtrain(56736:57023,:);
XtestPlc17 = Xtest(56736:57023,:);
YtestPlc17 = Ytest(56736:57023);
date12numPlc17 = date12num(56736:57023);

save XtestPlc17.mat XtestPlc17
save YtestPlc17.mat YtestPlc17 
save date12numPlc17.mat date12numPlc17
save YpredictCVJul.mat YpredictCVJul
% Now use the cross validated trees to make predictions on the 2013 testing
% data

YpredictCVkPlc17=zeros(length(XtestPlc17),kf);
for ii=1:kf
    YpredictCVkPlc17(:,ii)=predict(largetreeCVJul.Trained{ii,1},XtestPlc17);
end
YpredictPlc17 = sum(YpredictCVkPlc17,2)/kf;

% RMSE
[a,b]=rsquare(YtestPlc17,YpredictPlc17);
fprintf('17th July 2013 RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YtestPlc17)),(100*b/(max(YtestPlc17)-min(YtestPlc17))));

figure();
plot(date12numPlc17,YtestPlc17);
title('17th July');
hold on;
plot(date12numPlc17,YpredictPlc17);
datetick('x','hh');
hold off;
legend('Ground Truth','Prediction');

%% Now load the data for the DR event
disp('Evaluating prediction of building`s response using July 2012 tree');

load large_office_july17_drtest

% Feature matrix with all 34 features as columns
XDR17 = [basezat17,boiler117,chws117,chws217,chwsetp17,clgsetp17,corebzat17,coremzat17...
    ,coretzat17,dom17,dow17,gfplenum17,htgsetp17,hwsetp17,mfplenum17,outdry17,outhum17...
    ,outwet17,peribot1zat17,peribot2zat17,peribot3zat17,peribot4zat17,perimid1zat17...
    ,perimid2zat17,perimid3zat17,perimid4zat17,peritop1zat17,peritop2zat17...
    ,peritop3zat17,peritop4zat17,tod17,topplenum17,windir17,winspeed17];
XDR17(1,:)=[];
% Output vector
YDR17 = tpower17;
YDR17(1,:)=[];

YpredictCVkDR17=zeros(length(XDR17),kf);
for ii=1:kf
    YpredictCVkDR17(:,ii)=predict(largetreeCVJul.Trained{ii,1},XDR17);
end
YpredictDR17 = sum(YpredictCVkDR17,2)/kf;

% RMSE
[a,b]=rsquare(YDR17,YpredictDR17);
fprintf('17th July 2013 RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YDR17)),(100*b/(max(YDR17)-min(YDR17))));

%% Use previous DR events training data to learn a new DRspecific tree
disp('Loading 5 days of DR data from 2012');

%{

The variables are :

BASEMENTZoneAirTemperatureCTimeStep                             
CLGSETP_SCHScheduleValueTimeStep                                
COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep     
COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep     
CORE_BOTTOMZoneAirTemperatureCTimeStep                          
CORE_MIDZoneAirTemperatureCTimeStep                             
CORE_TOPZoneAirTemperatureCTimeStep                             
CWLOOPTEMPSCHEDULEScheduleValueTimeStep                         
DateTime                                                        
EMScurrentDayOfMonthTimeStep                                    
EMScurrentDayOfWeekTimeStep                                     
EMScurrentHolidayTimeStep                                       
EMScurrentTimeOfDayTimeStep                                     
ElectricityFacilityJTimeStep                                    
EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep            
EnvironmentSiteOutdoorAirRelativeHumidityTimeStep               
EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep            
EnvironmentSiteWindDirectiondegTimeStep                         
EnvironmentSiteWindSpeedmsTimeStep                              
FansElectricityJTimeStep                                        
GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep                   
HEATSYS1BOILERBoilerOutletTemperatureCTimeStep                  
HTGSETP_SCHScheduleValueTimeStep                                
HWLOOPTEMPSCHEDULEScheduleValueTimeStep                         
MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep                      
PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep                   
PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep                   
PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep                   
PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep                   
PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep                   
PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep                   
PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep                   
PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep                   
PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep                   
PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep                   
PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep                   
PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep                   
TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep                      
WholeBuildingFacilityTotalBuildingElectricDemandPowerWTimeStep  
WholeBuildingFacilityTotalElectricDemandPowerWTimeStep          
WholeBuildingFacilityTotalHVACElectricDemandPowerWTimeStep      

%}

load jul5.mat

XDRjul5 = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfMonthTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];

YDRjul5 = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);

load jul6.mat

XDRjul6 = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfMonthTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];

YDRjul6 = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);


load jul16.mat

XDRjul16 = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfMonthTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];

YDRjul16 = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);


load jul17.mat

XDRjul17 = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfMonthTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];

YDRjul17 = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);


load jul18.mat

XDRjul18 = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfMonthTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];

YDRjul18 = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);

XDRtrain = [XDRjul5;XDRjul6;XDRjul16;XDRjul17;XDRjul18];
YDRtrain = [YDRjul5;YDRjul6;YDRjul16;YDRjul17;YDRjul18];
%% Now train a CV tree on this DR data
disp('Train aand evaluate a new DR Tree from 5 days of DR data');

kf=15;

tic
DRtree = fitrtree(XDRtrain,YDRtrain,'PredictorNames',colnames,...
    'ResponseName','Total Power','CategoricalPredictors',catcol,...
    'MinLeafSize',minleaf,'CrossVal','on','KFold',kf); % default is 10-fold
toc

YfitCVDR = kfoldPredict(DRtree);

% RMSE
[a,b]=rsquare(YDRtrain,YfitCVDR);
fprintf('Cross Validated DR Tree RMSE(W): %.2f, R2: %.3f, RMSE/peak %.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(YDRtrain)),(100*b/(max(YDRtrain)-min(YDRtrain))));

% Now use the cross validated trees to make predictions on the 2013 testing
% data
YpredictCVkDR17=zeros(length(XDR17),kf);
for ii=1:kf
    YpredictCVkDR17(:,ii)=predict(DRtree.Trained{ii,1},XDR17);
end
YpredictDR17 = sum(YpredictCVkDR17,2)/kf;

% RMSE
[a,b]=rsquare(YDR17,YpredictDR17);
fprintf('17th July 2013 RMSE(W) with CV DR Tree: %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
    ,b,a,(b/max(YDR17)),(100*b/(max(YDR17)-min(YDR17))));



%%
figure();
plot(date12numPlc17,YDR17);
title('17th July with DR');
hold on;
plot(date12numPlc17,YpredictDR17);
datetick('x','hh');
hold off;
legend('Ground Truth','Prediction');


