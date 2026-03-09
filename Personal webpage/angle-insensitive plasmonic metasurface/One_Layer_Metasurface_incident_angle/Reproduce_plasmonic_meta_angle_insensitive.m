% Load gold refractive index data
Au_data = dlmread('Au_nk.txt');
wavelength_Au = Au_data(:,1);
n_Au = Au_data(:,2) + 1i*Au_data(:,3);

% Simulation parameters
wavelength = 687;                              % Fixed wavelength at 687nm
n_quartz = 1.52;                              % Refractive index of quartz (superstrate)
n_sog = 1.45;                                 % Refractive index of SOG (substrate)
thickness = 20;                               % Thickness of metasurface layer in nm
angle_delta = 0;                              % Azimuthal angle

% Angular range
angle_theta_range = 0:30;                     % Incident angles from 0 to 30 degrees
num_angles = length(angle_theta_range);

% Initialize parameters
parm = res0;                                  % Get default RCWA parameters
parm.res1.champ = 1;                         % Enable accurate field calculation
nn = [5,5];                                  % Fourier harmonics from -5 to 5 in x and y

% Initialize arrays for storing results
transmission = zeros(num_angles, 1);          % Array to store transmission values

%% Load pattern data （select desired pattern）
load('optimized_result.mat', 'Pattern', 'Period');
binary_pattern = Pattern{3};                  % Get first pattern (128x128 binary matrix)
period = [Period(3), Period(3)];             % Define square unit cell period

% Interpolate gold refractive index for 687nm
n_Au_curr = interp1(wavelength_Au, n_Au, wavelength);

% Main simulation loop over angles
for i = 1:num_angles
    angle_theta = angle_theta_range(i);       % Current incident angle
    
    % Define textures
    textures = cell(1,3);                    % Create cell array for 3 layers
    textures{1} = n_quartz;                  % Top layer (quartz)
    textures{2} = n_sog;                     % Bottom layer (SOG)
    
    % Create metasurface texture
    textures{3} = {n_sog};                   % Background material of metasurface layer
    
    % Convert binary pattern to RCWA format
    for ix = 1:size(binary_pattern,1)
        for iy = 1:size(binary_pattern,2)
            if binary_pattern(ix,iy) == 1     % If pixel is gold
                % Calculate position and size of gold inclusion
                x_pos = (ix/size(binary_pattern,1) - 0.5) * period(1);
                y_pos = (iy/size(binary_pattern,2) - 0.5) * period(2);
                dx = period(1)/size(binary_pattern,1);
                dy = period(2)/size(binary_pattern,2);
                textures{3}{end+1} = [x_pos, y_pos, dx, dy, n_Au_curr, 1];
            end
        end
    end
    
    % Calculate RCWA
    k_parallel = n_quartz*sin(angle_theta*pi/180);  % In-plane wavevector
    aa = res1(wavelength, period, textures, nn, k_parallel, angle_delta, parm);
    
    % Define layer profile
    profile = {[thickness, thickness, thickness], [1,3,2]};  % Thicknesses and layer sequence
    
    % Calculate transmission
    result = res2(aa, profile);                 % Perform RCWA calculation
    transmission(i) = result.TEinc_top_transmitted.efficiency(1);  % Get transmission
end

%% Plot angular transmission response
figure(1);
plot(angle_theta_range, transmission, 'LineWidth', 2);
xlabel('Incident Angle (degrees)');
ylabel('Transmission');
title('Angular Transmission Response at \lambda = 687nm');
grid on;

% Optional: Save the data
angular_data = [angle_theta_range', transmission];
save('angular_transmission.mat', 'angular_data');

%% Optional: Create a field distribution visualization at a specific angle (e.g., 15 degrees)
vis_angle = 15;
k_parallel = n_quartz*sin(vis_angle*pi/180);
aa = res1(wavelength, period, textures, nn, k_parallel, angle_delta, parm);

% Setup visualization parameters
x = linspace(-period(1)/2, period(1)/2, 100);
y = 0;
einc = [1,0];                                % TE polarization
parm.res3.npts = [50,50,50];
[e,z,index] = res3(x,y,aa,profile,einc,parm);
