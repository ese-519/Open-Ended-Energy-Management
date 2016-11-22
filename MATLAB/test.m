eval = load('logdata_eval.mat')
vanilla = load('logdata_vanilla.mat')


MAXSTEPS = 120
figure(1)
plot(1:MAXSTEPS,eval.logdata(:,1),'r')
hold on
plot(1:MAXSTEPS,vanilla.logdata(:,1),'b')
