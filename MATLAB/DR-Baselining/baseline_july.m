function baseline_july

% disp('July 17th was a PLC day in 2013 for PJM.');
% disp('Evaluating how well could we predict the baseline consumption');

%close all tree trained on Jul 2012 data
% load 
load largetreeCVJul.mat
% PLC day from 2013
% July 17th datemin[56736:57023] 
% 4pm: 57216
% 5pm: 57228
% 6pm: 57240
% 7pm: 57252

load YpredictCVJul.mat
load date12numJul.mat
kf = 15
% XtestPlc17 = Xtrain(56736:57023,:);
% YtestPlc17 = Ytest(56736:57023);
% date12numPlc17 = date12num(56736:57023);

% Now use the cross validated trees to make predictions on the 2013 testing
% data

% YpredictCVkPlc17=zeros(length(XtestPlc17),kf);
% for ii=1:kf
%     YpredictCVkPlc17(:,ii)=predict(largetreeCVJul.Trained{ii,1},XtestPlc17);
% end
% YpredictPlc17 = sum(YpredictCVkPlc17,2)/kf;

response =[];
response.y_predict = YpredictCVJul;
response.time = date12numJul;
savejson('',response,'Filename','response.json');
% plot(response.time,response.y_predict)
% % 
% % RMSE
% [a,b]=rsquare(YtestPlc17,YpredictPlc17);
% fprintf('17th July 2013 RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n\n'...
%     ,b,a,(b/max(YtestPlc17)),(100*b/(max(YtestPlc17)-min(YtestPlc17))));
% 
% figure();
% plot(date12numPlc17,YtestPlc17);
% title('17th July');
% hold on;
% plot(date12numPlc17,YpredictPlc17);
% datetick('x','hh');
% hold off;
% legend('Ground Truth','Prediction');
end
