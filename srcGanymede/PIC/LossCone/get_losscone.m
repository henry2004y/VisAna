function [particle] = get_losscone(particle,angle,B_P,nP)
%GET_LOSSCONE
%
%INPUTS
%
%
%OUTPUTS
%

Dir = '~/Ganymede/MOP2018/runG8_PIC_1200s/EnergeticFlux';
fnameGM = 'box_var_2_t00000557_n00250489.out';
% Particle data
[filehead,data] = read_data(fullfile(Dir,fnameGM));
data = data.file1;

status_ = strcmpi('status',filehead.wnames);
theta1_ = strcmpi('theta1',filehead.wnames);
phi1_ = strcmpi('phi1',filehead.wnames);
theta2_ = strcmpi('theta2',filehead.wnames);
phi2_ = strcmpi('phi2',filehead.wnames);

xGM = data.x(:,:,:,1);       % [Rg]
yGM = data.x(:,:,:,2);       % [Rg]
zGM = data.x(:,:,:,3);       % [Rg]

theta1 = data.w(:,:,:,theta1_);
phi1 = data.w(:,:,:,phi1_);

Ftheta1 = griddedInterpolant(xGM,yGM,zGM,theta1);
Fphi1 = griddedInterpolant(xGM,yGM,zGM,phi1);

[FBxSurf,FBySurf,FBzSurf] = get_Bsurface(true);

BxSurf = Inf(nP,1); BySurf = Inf(nP,1); BzSurf = Inf(nP,1);
% Find Bsurface for each particle position that the field connects to
for iP=1:nP
   % Find theta1, phi1 for each particle
   theta1_p = Ftheta1(particle(1,iP),particle(2,iP),particle(3,iP));
   phi1_p = Fphi1(particle(1,iP),particle(2,iP),particle(3,iP));
   
   BxSurf(iP) = FBxSurf(phi1_p,theta1_p);
   BySurf(iP) = FBySurf(phi1_p,theta1_p);
   BzSurf(iP) = FBzSurf(phi1_p,theta1_p);
end

Bsurf = sqrt(BxSurf.^2 + BySurf.^2 + BzSurf.^2);


% Mirror ratios
r_mirror = Bsurf ./ B_P;

theta_loss = asind(1./sqrt(r_mirror));


end