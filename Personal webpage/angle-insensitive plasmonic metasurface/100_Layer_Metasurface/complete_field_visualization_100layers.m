% Load gold refractive index data
Au_data = dlmread('Au_nk.txt');                  % Reads the gold optical properties data file
wavelength_Au = Au_data(:,1);                    % First column: wavelength in nm
n_Au = Au_data(:,2) + 1i*Au_data(:,3);          % Complex refractive index: n + ik

% Simulation parameters
wavelength_range = 450:5:750;                    % Wavelength range with 5nm steps
angle_range = 0:1:30;                           % Incident angles from 0° to 30°
n_quartz = 1.52;                                % Refractive index of quartz (superstrate)
n_sog = 1.45;                                   % Refractive index of SOG (substrate)
layer_thickness = 0.2;                          % Thickness of each layer in nm
num_layers = 100;                               % Total number of layers
total_thickness = layer_thickness * num_layers;  % Should equal 20nm
angle_delta = 0;                                % Azimuthal angle

% Initialize parameters
parm = res0;                                    % Get default RCWA parameters
parm.res1.champ = 1;                           % Enable accurate field calculation
nn = [5,5];                                    % Fourier harmonics from -5 to 5 in x and y

% Load pattern data
load('optimized_result.mat', 'Pattern', 'Period');
if length(Pattern) ~= num_layers
    error('Number of patterns (%d) does not match expected number of layers (%d)', ...
          length(Pattern), num_layers);
end

% Define common period for RCWA calculation
period = [Period(1), Period(1)];  % Define square unit cell period

% Initialize transmission matrix
num_wavelengths = length(wavelength_range);
num_angles = length(angle_range);
transmission_map = zeros(num_angles, num_wavelengths);

% Main calculation loop
fprintf('Calculating transmission map...\n');
for a = 1:num_angles
    curr_angle = angle_range(a);
    k_parallel = n_quartz*sin(curr_angle*pi/180);
    fprintf('Processing angle %.1f° (%d/%d)\n', curr_angle, a, num_angles);
    
    for w = 1:num_wavelengths
        wavelength = wavelength_range(w);
        
        % Interpolate gold refractive index
        n_Au_curr = interp1(wavelength_Au, n_Au, wavelength);
        
        % Define textures
        textures = cell(1, num_layers + 2);
        textures{1} = n_quartz;              % Top layer
        textures{end} = n_sog;               % Bottom layer
        
        % Define each intermediate layer texture
        for layer = 1:num_layers
            pattern_idx = layer;
            binary_pattern = Pattern{pattern_idx};
            period_curr = [Period(pattern_idx), Period(pattern_idx)];
            
            textures{layer + 1} = {n_sog};   % Initialize layer with SOG background
            
            % Add gold elements
            for ix = 1:size(binary_pattern,1)
                for iy = 1:size(binary_pattern,2)
                    if binary_pattern(ix,iy) == 1
                        x_pos = (ix/size(binary_pattern,1) - 0.5) * period_curr(1);
                        y_pos = (iy/size(binary_pattern,2) - 0.5) * period_curr(2);
                        dx = period_curr(1)/size(binary_pattern,1);
                        dy = period_curr(2)/size(binary_pattern,2);
                        textures{layer + 1}{end+1} = [x_pos, y_pos, dx, dy, n_Au_curr, 1];
                    end
                end
            end
        end
        
        % Define layer profile
        thicknesses = [0];  % Top layer
        for layer = 1:num_layers
            thicknesses = [thicknesses, layer_thickness];
        end
        thicknesses = [thicknesses, 0];  % Bottom layer
        layer_sequence = 1:(num_layers + 2);
        profile = {thicknesses, layer_sequence};
        
        % Calculate transmission
        aa = res1(wavelength, period, textures, nn, k_parallel, angle_delta, parm);
        result = res2(aa, profile);
        
        % Store average polarization transmission
        te_trans = result.TEinc_top_transmitted.efficiency(1);
        tm_trans = result.TMinc_top_transmitted.efficiency(1);
        transmission_map(a,w) = (te_trans + tm_trans) / 2;  % Average polarization
    end
end

% Create figure
figure('Position', [100 100 800 500]);

% Create 2D color plot
imagesc(wavelength_range, angle_range, transmission_map);
axis xy;  % Put zero angle at bottom
colormap(jet);
colorbar;
caxis([0 1]);  % Set color limits to 0-1 for transmission

% Add labels and title
xlabel('Wavelength (nm)');
ylabel('Incident angle (°)');
title('Average Polarization Transmission');

% Optional: Add gridlines
grid on;
set(gca, 'Layer', 'top');  % Ensure gridlines appear above the image

% Save the calculated data
save('transmission_map.mat', 'transmission_map', 'wavelength_range', 'angle_range');