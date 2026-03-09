% Load and prepare data
Au_data = dlmread('Au_nk.txt');
wavelength_Au = Au_data(:,1);
n_Au = Au_data(:,2) + 1i*Au_data(:,3);

wavelength = 687;
n_quartz = 1.52;
n_sog = 1.45;
thickness = 20;
angle_delta = 0;
angle_theta_range = 0:30;
num_angles = length(angle_theta_range);
num_patterns = 100;

parm = res0;
parm.res1.champ = 1;
nn = [5,5];

load('optimized_result.mat', 'Pattern', 'Period');
n_Au_curr = interp1(wavelength_Au, n_Au, wavelength);

% Create figure with subplots
num_rows = 10;
num_cols = 10;
figure('Position', [50 50 1500 1500]);

% Loop through all patterns
for pattern_idx = 1:num_patterns
    transmission = zeros(num_angles, 1);
    binary_pattern = Pattern{pattern_idx};
    period = [Period(pattern_idx), Period(pattern_idx)];
    
    % Calculate transmission for each angle
    for i = 1:num_angles
        angle_theta = angle_theta_range(i);
        
        textures = cell(1,3);
        textures{1} = n_quartz;
        textures{2} = n_sog;
        textures{3} = {n_sog};
        
        % Convert binary pattern
        for ix = 1:size(binary_pattern,1)
            for iy = 1:size(binary_pattern,2)
                if binary_pattern(ix,iy) == 1
                    x_pos = (ix/size(binary_pattern,1) - 0.5) * period(1);
                    y_pos = (iy/size(binary_pattern,2) - 0.5) * period(2);
                    dx = period(1)/size(binary_pattern,1);
                    dy = period(2)/size(binary_pattern,2);
                    textures{3}{end+1} = [x_pos, y_pos, dx, dy, n_Au_curr, 1];
                end
            end
        end
        
        k_parallel = n_quartz*sin(angle_theta*pi/180);
        aa = res1(wavelength, period, textures, nn, k_parallel, angle_delta, parm);
        profile = {[thickness, thickness, thickness], [1,3,2]};
        result = res2(aa, profile);
        transmission(i) = result.TEinc_top_transmitted.efficiency(1);
    end
    
    % Create subplot
    subplot(num_rows, num_cols, pattern_idx);
    plot(angle_theta_range, transmission, 'LineWidth', 1);
    title(sprintf('Pattern %d', pattern_idx));
    ylim([0 1]);
    grid on;
    
    if mod(pattern_idx, num_cols) == 1
        ylabel('Transmission');
    end
    if pattern_idx > (num_rows-1)*num_cols
        xlabel('Angle (°)');
    end
    
    % Display progress
    fprintf('Completed pattern %d/100\n', pattern_idx);
end

sgtitle('Angular Transmission Response at \lambda = 687nm');
set(gcf, 'Color', 'w');

% Save figure
saveas(gcf, 'all_patterns_angular_response.png');