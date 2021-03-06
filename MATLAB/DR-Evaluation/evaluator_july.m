function evaluator_july
close all
clear all
% addpath(genpath('../MLE+'))
% addpath(genpath('../matlab_json_iax'))
% input_evaluator = []
% input_evaluator.start =13
% input_evaluator.end= 20
% input_evaluator.clgsetp = 28
% input_evaluator.cwsetp = 8
% input_evaluator.lil = 0.2
% savejson('',input_evaluator,'input_evaluator.json')
% Load the tree and the linear models
load drtree12.mat
load dr12control.mat
input_evaluator= loadjson('input_evaluator.json')
load './baseline_july.mat';
load './MATLAB/DR-Evaluation/drtree12.mat';
load './MATLAB/DR-Baselining/XDR.mat';
load './MATLAB/DR-Evaluation/dr12.mat';

% 4pm: 57216


leafout = predict(drtree12,XDR);
            % idx is the leaf index for the model.
y_predict = baseline_july.y_predict;
idx_dr=[];

for day = 1:31
idx_dr = horzcat(idx_dr, day*((input_evaluator.start*12): ((input_evaluator.end*12)-1)));   
end

for i = 1: numel(idx_dr)
   leafout_dr= leafout(idx_dr(i));
   for idx = 1:length(dr12)
    if(leafout_dr == dr12(idx).mean)
       break;
    end
   end
    predicted_av = dr12(idx).mdl{1,1}.Coefficients{1,1} + ...
                    (dr12(idx).mdl{1,1}.Coefficients{2,1}*input_evaluator.clgsetp) + ...
                    (dr12(idx).mdl{1,1}.Coefficients{3,1}*input_evaluator.cwsetp)+ ...
                    (dr12(idx).mdl{1,1}.Coefficients{4,1}*input_evaluator.lil);
    y_predict(idx_dr(i))=predicted_av;
end

response =[];
response.y_predict = y_predict;
response.time = time;
savejson('',response,'Filename',['response.json']);
% figure(1)
% plot(time,baseline_july.y_predict,'r');
% hold on
% plot(time,y_predict,'b');

%%%%% plot%%%%%%%%%%

end
