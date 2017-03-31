%% State-Space catcher thing
clear; close all

%% define vars
% motor parameters
    Kt = 0.0967;       % Nm/A torque (from ServoSysCo spec sheet)
    %Kv = 1;           % back-emf constant (incase have this instead)
    L = .0041;         % H motor inductance  (from ServoSysCo spec sheet)
    R = 1.6;           % ohms  motor resistance (from ServoSysCo spec sheet)
% physical parameters    
    m1 = 3;            % kg mass of puck
    m2 = 5;            % kg mass of platform
    k1 = 18500;        % N/m mechanical spring element 
    k2 = 410;          % Nm/rad rotational spring element  
    r = .008;          % m   radius of screw 
    nb = 3;            % number of bearings
    b1 = 250;          % Ns/m   damping coeff for pad
    b2 = nb*r*500;     % Nms/rad guide bearing friction
    J = .05649;        % kgm^2 moment of inertial (from ServoSysCo spec sheet)
    b3 = 1.7e-5;       % Nms/rad motor damping (from ServoSysCo spec sheet)
    pitch = .005/(2*pi);      % m/rev  pitch of ball screw
% transformer 
    TF12 = pitch;     % transformer translation to rotation
    TF34 = Kt;               % transformer rotation to electrical

% time
dt=.0001;
t = 0:dt:.25;  % time array

%% define matricies
x0 = [...
    -2.445;...    % Vm1
    0;...        % Vm2
    0;...        % Fk1
    0;...        % Tk2
    0;...        % Wj
    1;];         % iL

A = [...
    -b1/m1, b1/m1, 1/m1, 0, 0, 0;...
    b1/m2, (-b1*TF12 - b2)/(TF12*m2), -1/m1, 1/(TF12*m2), 0, 0;...
    -k1, k1, 0, 0, 0, 0;...
    0, -k2/TF12, 0, 0, k2, 0;...
    0, 0, 0, -1/J, -b3/J, TF34/J;...
    0, 0, 0, 0, 0, (TF34 - R)/L ];
    
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
          
D = 0;

%% create state-space
sys = ss(A,B,C,D);
% sys.InputName = 'Vs';
% sys.OutputName = {'Vm1';'Vm2'};
u = zeros(1,length(t));
% un-comment this for step response
for j = 1: length(t)
    if t(j) < median(t)
        u(j) = 0;
    else
        u(j) = 0;
    end
end
y = lsim(sys,u,t,x0);
a = cat(1,NaN, diff(y(:,1))/dt);

%% plot things
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
% take "inegral" of Vm2 for x position
x = cumtrapz(t,y(:,1));

figure
plot(t,x);      % position
% impulse(sys,t);
grid on
title('position');
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



