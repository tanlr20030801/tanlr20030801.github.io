% Load data
load('optimized_result.mat', 'Pattern', 'Period');
load('simulated_T.mat', 'T_all');

% Load refractive index of gold (n and k values from Au_nk.txt)
Au_data = readmatrix('Au_nk.txt'); % Adjust range based on actual data rows
wavelengths_Au = Au_data(:, 1);
n_Au_data = Au_data(:, 2);
k_Au_data = Au_data(:, 3);

% Define constants
wavelengths = 450:750; % in nm
n_superstrate = 1.52;
n_substrate = 1.45;
thickness = 20e-9; % in meters

% Interpolate Au refractive index data for simulation wavelengths
n_Au = interp1(wavelengths_Au, n_Au_data, wavelengths, 'linear', 'extrap');
k_Au = interp1(wavelengths_Au, k_Au_data, wavelengths, 'linear', 'extrap');
n_complex_Au = n_Au + 1i * k_Au;

% Loop over each metasurface unit to analyze and plot
for i = 1:100
    pattern = Pattern{i};
    period = Period(i) * 1e-9; % Convert nm to meters
    
    % Define textures based on the binary pattern (0 for dielectric, 1 for gold)
    textures = cell(1, 3);
    textures{1} = n_substrate; % Substrate layer (SOG)
    textures{2} = {pattern, n_substrate, n_complex_Au}; % Metasurface layer
    textures{3} = n_superstrate; % Superstrate layer (quartz)
    
    % Define profile for the metasurface layer
    profile = {thickness, [1, 2, 3]}; % Define layer profile based on structure

    % Calculate transmission for each incident angle and wavelength
    % (Using RCWA or equivalent function)
    T_angle0 = squeeze(T_all(i, 1, :));
    T_angle15 = squeeze(T_all(i, 2, :));
    
    % Plot transmission curves
    figure;
    plot(wavelengths, T_angle0, 'r', 'DisplayName', '0° Incident Angle');
    hold on;
    plot(wavelengths, T_angle15, 'b', 'DisplayName', '15° Incident Angle');
    xlabel('Wavelength (nm)');
    ylabel('Transmission');
    title(['Transmission Curves for Metasurface Unit ', num2str(i)]);
    legend show;
    hold off;
    
    % Define a specific wavelength for field plotting, e.g., 600.75 nm
    % (requires a function like `res3` for actual field computation)
    wavelength = 600.75e-9; % in meters
    x = linspace(-period/2, period/2, 51); % x-coordinates
    y = 0; % y = 0 for 2D calculation
    einc = [0, 1]; % E-field components for illumination from the top layer
    parm.res3.trace = 1;
    parm.res3.npts = [50, 50, 50]; % Number of points per layer

    % Calculate fields at specific wavelength
    % Assuming `res3` is available for field computation
    [e, z, index] = res3(x, y, aa, profile, einc, parm);

    % Plot the real part of the Ey field
    figure;
    pcolor(x, z, real(squeeze(e(:, :, :, 2))));
    shading flat;
    xlabel('x (m)');
    ylabel('z (m)');
    axis equal;
    title(['Real(E_y) Field for Metasurface Unit ', num2str(i)]);
end
