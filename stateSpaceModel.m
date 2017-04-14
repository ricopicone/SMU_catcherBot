%% State-Space catcher thing
clear; close all

%% define vars
% motor parameters
    Kt = 0.0967;        % Nm/A torque (from ServoSysCo spec sheet)
    %Kv = 105;          % V/rad/s back-emf constant
    L = .0041;          % H motor inductance  (from ServoSysCo spec sheet)
    R = 1.6;            % ohms  motor resistance (from ServoSysCo spec sheet)
    Jm = .05648;        % kgm^2 moment of inertial (from ServoSysCo spec sheet)
    b3 = 1.7e-5;        % Nms/rad motor damping (from ServoSysCo spec sheet)
    Tau_m = .0089;      % s untill 62.3% to Vfinal 
% physical parameters    
    m1 = 3;             % kg mass of puck
    m2 = 5;             % kg mass of platform
    k1 = 18500;         % N/m mechanical spring element 
    k2 = 1000410;       % Nm/rad rotational spring element  
    r = .013;           % m   radius of screw
    rho_al = 2.70;      % kg/m3  density of alluminum
    Vol_al = pi*r^2*.013;    % vol of pulley
    mp = rho_al*Vol_al;      % mass of pulley
    Jp = mp*r^2/2;           % inertia of pulleys
    J = 2*Jp + Jm;           % inertia of rotational system
    nb = 3;                  % number of bearings
    b1 = 250;                % Ns/m   damping coeff for pad
    b2 = nb*r*500;           % Nms/rad guide bearing friction  
    %pitch = .005/(2*pi);     % m/rads  pitch of ball screw
% transformer 
    TF12 = 2*pi*r;           % transformer translation to rotation
    TF34 = Kt;               % transformer rotation to electrical

% time
dt=.0001;
t = 0:dt:1;                  % time array

%% define matricies
x0 = [...
    -2.445;...    % Vm1
    0;...         % Vm2
    0;...         % Fk1
    0;...         % Tk2
    0;...         % Wj
    1;];          % iL

A = [...
    -b1/m1, b1/m1, 1/m1, 0, 0, 0;...
    b1/m2, (-b1*TF12 - b2)/(TF12*m2), -1/m1, 1/(TF12*m2), 0, 0;...
    -k1, k1, 0, 0, 0, 0;...
    0, -k2/TF12, 0, 0, k2, 0;...
    0, 0, 0, -1/J, -b3/J, TF34/J;...
    0, 0, 0, 0, -TF34/L, - R/L ];
    
B = [...
    0;...
    0;...
    0;...
    0;...
    0;...
    1/L];

C = [1,0,0,0,0,0;...    % Vm1
    0,1,0,0,0,0;...     % Vm2
    0,0,1,0,0,0;...     % Fk1
    0,0,0,1,0,0;...     % Tk2
    0,0,0,0,1,0;...     % Wj 
    0,0,0,0,0,1];       % iL
          
D = 0;                  %   

%% create state-space
sys = ss(A,B,C,D);
sys.InputName = 'Vs';
sys.OutputName = {'Vm1';'Vm2';'Fk1';'Tk2';'Wj';'iL'};
u = zeros(1,length(t));
for j = 1:length(u)         % uncomment for step input
    if u(j) < median(u)
        u(j) = 24;
    else
        u(j) = 0;
    end
end
y = lsim(sys,u,t,x0);
a = cat(1,NaN, diff(y(:,1))/dt);

% plot things
figure
plot(t,y(:,1));    % velocity
% impulse(sys,t);
grid on
hold on
plot(t,y(:,2));
title('Velocity Response');
xlabel('time (s)')
ylabel('velocity of puck (m/s)')
legend('Vm1','Vm2')
save2pdf('VelRes',gcf,300);

% take "integral" of Vm1 for x position
x = cumtrapz(t,y(:,1));

figure
plot(t,x);      % position
grid on
title('position')
xlabel('time (s)')
ylabel('position (m)')
save2pdf('PosRes',gcf,300);

figure
plot(t,a);      % acceleration
grid on
title('Acceleration Response');
xlabel('time (s)')
ylabel('acceleration of puck (m/s^2)')
save2pdf('AccelRes',gcf,300);

%% closed loop transfer functions
Gp = tf(sys);

Gspuck = Gp(1);
Gsplatform = Gp(2);

% requirements
osTarget = 0.10;       % overshoot 
tsTarget = 0.1;        % sec  

%%  PID compensator Design for V1r -> Vm1 
figure
rlocus(Gspuck); grid on
KP = 1000;
sP = -33.2+97.2*1i;   % initial design point

% simulate 
sysP = feedback(KP*Gspuck,1);
tt = 0:dt:1;
yP = step(sysP,tt);
Pinfo = stepinfo(yP,tt,yP(end));
Pinfo 

figure;
plot(tt,yP);
grid on;
xlabel('time (s)')
ylabel('unit step response')
legend('P controller')

%% add derivative to speed up response
s = tf('s');
tsP = Pinfo.SettlingTime;
tsFactor = tsP/tsTarget; 

sPD = tsFactor*sP;              % new design point
theta = pi - angle(evalfr(Gspuck,sPD));  % required angle contribution
zc = imag(sPD)/tan(theta)+real(sPD);
GcD = (s-zc);                   % derivative compensator
GsPD = GcD*Gspuck;              % create compensated system

figure;
rlocus(GsPD);
grid on

KPD = 2;

%% simulate PD 
sysPD = feedback(KPD*GsPD,1);
yPD = step(sysPD,tt);
PDinfo = stepinfo(yPD,tt,yPD(end));
PDinfo

figure;
plot(tt,yP,'r'); hold on;
plot(tt,yPD,'b');
grid on;
xlabel('time (s)')
ylabel('unit step response')
legend('P controller','PD controller')

%% add integrator to drive to setpoint
GcI = (s+50)/s;  % integrator compensator
GsPID = GcI*GsPD;

figure;
rlocus(GsPID)
grid on

KPID = 2;

%% simulate PID
sysPID = feedback(KPID*GsPID,1); % Vm1 veclocity command
yPID = step(sysPID,tt);
PIDinfo = stepinfo(yPID,tt,yPID(end));
PIDinfo 

figure;
plot(tt,yP,'r'); hold on;
plot(tt,yPD,'b');
plot(tt,yPID,'g');
grid on;
xlabel('time (s)')
ylabel('unit step response')
title('puck step response')
legend('P controller','PD controller','PID controller')

%% build compensator  (C1) for puck
Gc1 = tf(KPID*GcI*GcD);  % total PID compensator

Kp = KPID;
Ki = Gc1.num{:}(3)/Kp;
Kd = Gc1.num{:}(2)/Kp;
disp(['Kp = ',num2str(Kp),' | Ki = ',num2str(Ki),' | Kd = ', num2str(Kp)]);
disp(' ');
disp('total compensating controller:');
disp(['Gc = ',num2str(Kp),' + ',num2str(Ki),'/s + s',num2str(Kd)]);

%%  PID compensator Design for V2r -> Vm2  (platform)
figure
rlocus(Gsplatform); grid on
KP2 = 3700;
sP2 = -43.9+61.5*1i;   % initial design point

%% simulate P gain for platform
sysP2 = feedback(KP*Gsplatform,1);
yP2 = step(sysP2,tt);
P2info = stepinfo(yP2,tt,yP2(end));
P2info 

figure;
plot(tt,yP2);
grid on;
xlabel('time (s)')
ylabel('unit step response')
legend('P controller')

%% add integrator to drive to setpoint
GcI2 = (s+35)/s;  % integrator compensator
GsPID2 = GcI2*Gsplatform;

figure;
rlocus(GsPID2)
grid on

KPID2 = 200;

%% simulate PID
sysPID2 = feedback(KPID2*GsPID2,1); % Vm1/veclocity command
yPID2 = step(sysPID2,tt);
PIDinfo2 = stepinfo(yPID2,tt,yPID2(end));
PIDinfo2 

sys_accel = max(yPID2)/tt(find(yPID2 == max(yPID2)));

figure;
plot(tt,yP2,'r'); hold on;
plot(tt,yPID2,'g');
grid on;
title('Platform Step Response');
xlabel('time (s)')
ylabel('unit step response')
legend('P controller','PID controller')

%% build compensator (C2)
Gc2 = tf(KPID2*GcI2);  % total PID compensator

Kp2 = KPID2;
Ki2 = Gc1.num{:}(3)/Kp2;
Kd2 = Gc1.num{:}(2)/Kp2;
disp(['Kp2 = ',num2str(Kp2),' | Ki2 = ',num2str(Ki2),' | Kd2 = ', num2str(Kp2)]);
disp(' ');
disp('total compensating controller:');
disp(['Gc2 = ',num2str(Kp2),' + ',num2str(Ki2),'/s + s',num2str(Kd2)]);

%% build platform to puck command relationship
Gspp = Gc1/Gc2*(1+Gc2*GsPID2);
Hspp = (Gc2*GsPID)/(1+Gc2*GsPID2);

Vrchng = tf(Gspp/(1+Hspp*Gspp));

%% velocity command formation
g = 9.8;                 % m/s2
pltfrmDelay = .215;       % s
catchTime = pltfrmDelay + .25;   % s
VpuckCmd = importdata('Vpuckcmd.mat');
Vinit = -4.5;             % m/s
decelRate = 4*g;

% puck params
puckInit = .3048;       % m puck initial position
puckVfall = -g.*tt;
xpuckfrf = cumtrapz(tt,puckVfall) + puckInit;
VCmnd = NaN*ones(1,length(tt));
for j = 1:length(tt)
    if tt(j) < pltfrmDelay
        VCmnd(j) = 0;
    elseif tt(j) >= pltfrmDelay
        VCmnd(j) = Vinit;
    end
end
yCmnd = lsim(sysPID2,VCmnd,tt);
t0 = 0;
for j = 1:length(tt)
    if yCmnd(j) < puckVfall(j)
        index = j;
        break
    end
end
for k = index:length(tt)
        VCmnd(k) = Vinit + decelRate*(t0*dt);
        t0 = t0+1;
       if VCmnd(k) > 0;
            VCmnd(k:end) = 0;
       end
end
figure;
plot(tt,VCmnd)
grid on;
title('Velocity Command')
xlabel('time (s)')
ylabel('velocity (m/s)')

yCmnd = lsim(sysPID2,VCmnd,tt);     % re populate ysimulation

%% simulate with velocity command


% take "integral" for x position
xCmnd = cumtrapz(tt,yCmnd);
xCmnd = transpose(xCmnd);

figure;
plot(tt,yCmnd); grid on; hold on
plot(tt,puckVfall);
xlabel('time (s)')
ylabel('velocity (m/s)')
title('velocity response of platform')
legend('platform velocity','puck freefall','location','southeast')

figure;
plot(tt,xCmnd,'LineWidth',1.5); grid on; hold on;
plot(tt,xpuckfrf)
%plot(tc,puckCtch,'--r','LineWidth', 1.5);
xlabel('time (s)')
ylabel('position (m)')
title('position response of platform')
legend('platform','puck')





