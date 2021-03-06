% Calculating cross polar cap magnetic flux change.
% 
% Note: I used to use electric potential, but later I realized that the
% potential is improper to describe a time-varying system like we have in
% our simulation. However, the integral of electric field is still useful
% physically: it can tell us the time derivative of magnetic flux through
% the region.
%
% I first tried doing integral in x=0 cuts; here I use line integrals along
% the magnetopause curve in a plane cut above the moon.
%
% Procedure:
% 1. E = -uxB from MHD output; if necessary, it should be more accurate to
%    to use ue x B, where ue = u - nJ/e. What I found from the simulation
%    is that this term is relatively small, so it is like a correction 
%    term.
% 2. Use status to find the region of half open field lines that have one
%    end connected to the polar cap; more specifically in this cut, I need
%    a line at a certain height within the region. I decide to pick the
%    upstream boundary curve for integration.
% 3. Integrate the electric field along the line.
%
% This script works for G8 and G28 Galileo flybys, and also runs with 
% mixed parameters mix1 and mix2.
%
% Hongyang Zhou, hyzhou@umich.edu 11/02/2017
%
% Modified on 01/04/2018

clear; clc
%% Parameters
% All the following sections need parameters here.
flyby = 'G8'; % default is G8

Rg = 2634000; %[m], radius of Ganymede
e  = 1.60217662e-19; % [C], electron charge

switch flyby
   case 'G8'
      disp('G8 flyby CPCP calculation')
      filename= '../../newPIC/run_G8_newPIC/box_CPCP_G8_1200s.outs';
      plotrange = [-5 5 -8 8];
      
      % Background
      % G8 B= -10 -6 -86 [nT], U=140 0 0 [km/s]
      Uxbk = 140; Bybk = -6; Bzbk = -86;
      TiltedAngle = sin(atan(86/6));
   case 'G28'
      disp('G28 flyby CPCP calculation')
      filename= '../../newPIC/run_G28_newPIC/box_CPCP_G28_1200s.outs';
      plotrange = [-8 8 -8 8];
      
      % Background
      % G28 B= 11 78 -76 [nT], U=140 0 0 [km/s]
      Uxbk = 140; Bybk = 78; Bzbk = -76;
      TiltedAngle = sind(atand(78/76));
   case 'mix1'
      disp('mix1 CPCP calculation')
      filename='../../newPIC/run_mix1/box_CPCP_mix1_1200s.outs';
      %plotrange = [-8 8 -8 8];
      % Background
      % G8 B= -10 -6 -86 [nT], U=140 0 0 [km/s]
      Uxbk = 140; Bybk = -6; Bzbk = -86;
      TiltedAngle = sin(atan(86/6));
   case 'mix2'
      disp('mix2 CPCP calculation')
      filename='../../newPIC/run_mix2/box_CPCP_mix2_1200s.outs';
      %plotrange = [-8 8 -8 8];  
      % Background
      % G28 B= 11 78 -76 [nT], U=140 0 0 [km/s]
      Uxbk = 140; Bybk = 78; Bzbk = -76;
      TiltedAngle = sind(atand(78/76));
end

[~,~,fileinfo] = read_data(filename,'verbose',false);
npict   = fileinfo.npictinfiles; % # of snapshot in the file
dsample = 1/32;                  % grid resolution in [Rg]

%% CPCP calculation by line integral along x=1, z=2

% CPCPt = Inf(npict,1);
% time = Inf(npict,1);
% Potential_bk = Inf(npict,1);
% 
% for ipict=1:npict
%    fprintf('ipict=%d\n',ipict);
%    [filehead,data] = read_data(filename,'verbose',false,'npict',ipict);
%    time(ipict) = filehead.time;
%    
%    %
%    data = data.file1;
%    x = data.x(:,:,:,1);
%    y = data.x(:,:,:,2);
%    status = data.w(:,:,:,14);
%    status(status>1) = 2;
%    status(status<1) = 0;
%   
%    % Get E field: E = -uexB
%    rho= data.w(:,:,:,1);rho = rho(:);
%    ux = data.w(:,:,:,2); ux = ux(:);
%    uy = data.w(:,:,:,3); uy = uy(:);
%    uz = data.w(:,:,:,4); uz = uz(:);
%    
%    %u = [ux uy uz];
%    
%    Bx = data.w(:,:,:,5); Bx = Bx(:);
%    By = data.w(:,:,:,6); By = By(:);
%    Bz = data.w(:,:,:,7); Bz = Bz(:);
%    
%    B = [Bx By Bz];
%    
%    jx = data.w(:,:,:,11); jx = jx(:);
%    jy = data.w(:,:,:,12); jy = jy(:);
%    jz = data.w(:,:,:,13); jz = jz(:);
%    
%    J = [jx jy jz];
%    
%    % Calculate electron bulk velocity in Hall MHD
%    % Transform the hall velocity into [km/s]
%    uex = ux - jx./rho * 1e-6 /e * 1e-3 * 1e-6;
%    uey = uy - jy./rho * 1e-6 /e * 1e-3 * 1e-6;
%    uez = uz - jz./rho * 1e-6 /e * 1e-3 * 1e-6;
%    
%    ue = [uex uey uez];
%    
%    E = -cross(ue,B);
%    E = reshape(E,size(data.w,1),size(data.w,2),3);
%    
%    Ex = E(:,:,1);
%    Ey = E(:,:,2);
%    Ez = E(:,:,3);
%    
%    row = find(x==1,1);
%    
%    k = find( status(row,:)==2 );
%    
%    CPCPt(ipict) = -dsample * trapz( Ey(row,k) )*Rg*1e3*1e-9;
%    
%    Potential_bk(ipict) = -(max(y(row,k))-min(y(row,k))) * ...
%       Rg * Uxbk*1e3 * (Bzbk-Bybk)*1e-9 * TiltedAngle;
% 
% end
% 
% figure
% plot(time,CPCPt,'*-');
% xlabel('Time [s]'); ylabel('CPCP [V]');
% set(gca,'FontSize',14,'LineWidth',1.2);


%% CPCP calculation by curve line integral
% Integrate along the upstream boundary curve and find the maximum
% difference as the potential drop.
% Following Gabor`s advice, I shouldn`t use x=1 to 'force' the cutoff. It
% would make more sense to integrate the closed curve and pick the
% difference between the maximum and minimum.
% Note: the x=1 condition is still there!

CPCPt = Inf(npict,1);
time = Inf(npict,1);
xCenter = 0; yCenter = 0; % coordinates of the center of points

for ipict=1:npict
   fprintf('ipict=%d\n',ipict);
   [filehead,data] = read_data(filename,'verbose',false,'npict',ipict);
   time(ipict) = filehead.time;
   
   %
   data = data.file1;
   x = data.x(:,:,:,1);
   y = data.x(:,:,:,2);
   status = data.w(:,:,:,14);
   status(status>1) = 2;
   status(status<1) = 0;
  
   % Get E field: E = -uexB
   rho= data.w(:,:,:,1);rho = rho(:);
   ux = data.w(:,:,:,2); ux = ux(:);
   uy = data.w(:,:,:,3); uy = uy(:);
   uz = data.w(:,:,:,4); uz = uz(:);
   
   %u = [ux uy uz];
   
   Bx = data.w(:,:,:,5); Bx = Bx(:);
   By = data.w(:,:,:,6); By = By(:);
   Bz = data.w(:,:,:,7); Bz = Bz(:);
   
   B = [Bx By Bz];
   
   jx = data.w(:,:,:,11); jx = jx(:);
   jy = data.w(:,:,:,12); jy = jy(:);
   jz = data.w(:,:,:,13); jz = jz(:);
   
   J = [jx jy jz];
   
   % Calculate electron bulk velocity in Hall MHD
   % Transform the hall velocity into [km/s]
   uex = ux - jx./rho * 1e-6 /e * 1e-3 * 1e-6;
   uey = uy - jy./rho * 1e-6 /e * 1e-3 * 1e-6;
   uez = uz - jz./rho * 1e-6 /e * 1e-3 * 1e-6;
   
   ue = [uex uey uez];
   
   E = -cross(ue,B);
   E = reshape(E,size(data.w,1),size(data.w,2),3);
   
   Ex = E(:,:,1);
   Ey = E(:,:,2);
   Ez = E(:,:,3);
   
   x = x(status==2);
   y = y(status==2);
   
   % Find the boundary of magnetosphere
   k = boundary(x,y,1);
   % Integrate along the boundary 
   x = x(k);
   y = y(k);
   Ex = Ex(status==2);
   Ex = Ex(k);
   Ey = Ey(status==2);
   Ey = Ey(k);
   
   % Pick the upstream half curve (use the line x==1 as boundary)
   k = x <= 1;
   x = x(k);
   y = y(k);
   Ex = Ex(k);
   Ey = Ey(k);
   
   % Re-order of boundary points in a counter-clockwise way
   angles = atan2d( y-yCenter,x-xCenter );
   sortIndexes = angles<0;
   angles(sortIndexes) = angles(sortIndexes) + 360;
   [sortAngles, sortIndexes] = sort(angles);
   x = x(sortIndexes);
   y = y(sortIndexes);
   Ex = Ex(sortIndexes);
   Ey = Ey(sortIndexes);
   
   Ediff = Inf(numel(x)-1,1);
   for iE=1:numel(x)-1
      Ediff(iE) = ( (Ex(iE)+Ex(iE+1))/2*(x(iE+1)-x(iE)) + ...
         (Ey(iE)+Ey(iE+1))/2*(y(iE+1)-y(iE)) )*Rg*1e3*1e-9;
   end
   
   EPotential = cumsum([0;Ediff]);
   
   CPCPt(ipict) = max(EPotential) - min(EPotential);

end

figure
plot(time,CPCPt,'*-');
xlabel('Time [s]'); ylabel('CPCP [V]');
set(gca,'FontSize',14,'LineWidth',1.2);

figure
plot(time,CPCPt./Potential_bk,'*-');
xlabel('Time [s]'); ylabel('Global reconnection rate');
set(gca,'FontSize',14,'LineWidth',1.2);
% 
% figure;
% plot(x,y,'x')
% figure;
% plot(EPotential);

%% FFT

% There are 2 ways of doing FFT:
% 1. using CPCP along;
% 2. using CPCP / background potential drop.
%
% If we think that background condition will only effect the amplitude but
% not the frequency, it is better to use method (1).

CPCPfft = fft(CPCPt);
%CPCPfft = fft(CPCPt./Potential_bk);
CPCPfft(1) = [];
n = length(CPCPfft);
power = abs(CPCPfft(1:floor(n/2))).^2; % power of first half of transform data
maxfreq = 1;                   % maximum frequency (sample freq = 1s)
freq = (1:n/2)/(n/2)*maxfreq;  % equally spaced frequency grid

figure
plot(freq,power)
xlabel('Cycles/Second')
ylabel('Power')

period = 1./freq;
figure;
plot(period,power);
xlim([0 100]); %zoom in on max power
xlabel('Seconds/Cycle')
ylabel('Power')
