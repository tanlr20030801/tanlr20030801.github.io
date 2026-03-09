% Load gold refractive index data 
% (Assume normal incidence and 1 layer of metaelements)
Au_data = dlmread('Au_nk.txt');                  % Reads the gold optical properties data file
wavelength_Au = Au_data(:,1);                    % First column: wavelength in nm
n_Au = Au_data(:,2) + 1i*Au_data(:,3);          % Complex refractive index: n + ik

% Simulation parameters
wavelength_range = 450:750;                      % Wavelength range from 450nm to 750nm in steps of 1nm
n_quartz = 1.52;                                % Refractive index of quartz (superstrate)
n_sog = 1.45;                                   % Refractive index of SOG (substrate)
thickness = 20;                                 % Thickness of metasurface layer in nm
angle_theta = 0;                                % Incident angle (normal incidence)
angle_delta = 0;                                % Azimuthal angle

% Initialize parameters
parm = res0;                                    % Get default RCWA parameters
parm.res1.champ = 1;                           % Enable accurate field calculation
nn = [5,5];                                    % Fourier harmonics from -5 to 5 in x and y

% Initialize arrays for storing results
num_wavelengths = length(wavelength_range);     % Number of wavelength points
transmission = zeros(num_wavelengths, 1);       % Array to store transmission values

% Load pattern data
load('optimized_result.mat', 'Pattern', 'Period');  % Load the metasurface pattern
binary_pattern = Pattern{1};                    % Get first pattern (128x128 binary matrix)
period = [Period(1), Period(1)];               % Define square unit cell period

% Main simulation loop
for i = 1:num_wavelengths
    wavelength = wavelength_range(i);           % Current wavelength
    
    % Interpolate gold refractive index for current wavelength
    n_Au_curr = interp1(wavelength_Au, n_Au, wavelength);
    
    % Define textures
    textures = cell(1,3);                      % Create cell array for 3 layers
    textures{1} = n_quartz;                    % Top layer (quartz)
    textures{2} = n_sog;                       % Bottom layer (SOG)
    
    % Create metasurface texture
    textures{3} = {n_sog};                     % Background material of metasurface layer
    
    % Convert binary pattern to RCWA format
    for ix = 1:size(binary_pattern,1)
        for iy = 1:size(binary_pattern,2)
            if binary_pattern(ix,iy) == 1                               
                % If pixel is gold Calculate position and size of gold inclusion (rectangular)
                x_pos = (ix/size(binary_pattern,1) - 0.5) * period(1); % x position
                y_pos = (iy/size(binary_pattern,2) - 0.5) * period(2); % y position
                dx = period(1)/size(binary_pattern,1);                 % x dimension
                dy = period(2)/size(binary_pattern,2);                 % y dimension
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

% Plot transmission spectrum
figure;
plot(wavelength_range, transmission, 'LineWidth', 2);
xlabel('Wavelength (nm)');
ylabel('Transmission');
title('Metasurface Transmission Spectrum');
grid on;

% Field visualization section
wavelength_vis = 687;                          % Wavelength for field visualization
i_vis = find(wavelength_range == wavelength_vis);

% Interpolate gold refractive index for visualization
n_Au_vis = interp1(wavelength_Au, n_Au, wavelength_vis);

% Setup visualization textures (same as above but for single wavelength)
textures = cell(1,3);
textures{1} = n_quartz;
textures{2} = n_sog;
textures{3} = {n_sog};

% Convert binary pattern again for visualization
for ix = 1:size(binary_pattern,1)
    for iy = 1:size(binary_pattern,2)
        if binary_pattern(ix,iy) == 1
            x_pos = (ix/size(binary_pattern,1) - 0.5) * period(1);
            y_pos = (iy/size(binary_pattern,2) - 0.5) * period(2);
            dx = period(1)/size(binary_pattern,1);
            dy = period(2)/size(binary_pattern,2);
            textures{3}{end+1} = [x_pos, y_pos, dx, dy, n_Au_vis, 1];
        end
    end
end

% Calculate field distribution
k_parallel = n_quartz*sin(angle_theta*pi/180);
aa = res1(wavelength_vis, period, textures, nn, k_parallel, angle_delta, parm);

% Setup visualization parameters
x = linspace(-period(1)/2, period(1)/2, 100);  % x coordinates for visualization
y = 0;                                         % y-plane cross-section
einc = [1,0];                                  % TE polarization incident field
parm.res3.npts = [50,50,50];                   % Number of points in each layer
[e,z,index] = res3(x,y,aa,profile,einc,parm);  % Calculate field distribution

% Plot field distribution
figure;
pcolor(x,z,real(squeeze(e(:,:,1))));          % Plot real part of Ex field
shading interp;                                % Smooth shading
xlabel('x (nm)');
ylabel('z (nm)');
title(['Electric Field Distribution at \lambda = ' num2str(wavelength_vis) ' nm']);
colorbar;
axis equal;