% Load gold refractive index data and pattern
Au_data = dlmread('Au_nk.txt');
wavelength_Au = Au_data(:,1);
n_Au = Au_data(:,2) + 1i*Au_data(:,3);

% Load the pattern data
load('optimized_result.mat', 'Pattern', 'Period');
binary_pattern = Pattern{93};  % Get the pattern
period = Period(93);  % Get period for the desired pattern

%% Single configuration plot
% Create figure with two subplots
figure('Position', [100 100 900 400]);

% Subplot 1: Top-down view
subplot(1,2,1);
imagesc([-period/2 period/2], [-period/2 period/2], binary_pattern);
colormap([1 1 1; 1 0.84 0]);  % White for SOG, gold color for Au
axis equal tight;
xlabel('x (nm)');
ylabel('y (nm)');
title('Top View of Metasurface Unit');
c = colorbar;
c.Ticks = [0.25 0.75];
c.TickLabels = {'SOG', 'Au'};

% Subplot 2: Side profile schematic
subplot(1,2,2);
hold on;

% Draw substrate (SOG)
rectangle('Position', [-period/2 -40 period 40], 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'k');
text(-period/2-20, -20, 'SOG', 'FontSize', 10);

% Draw metasurface layer
rectangle('Position', [-period/2 0 period 20], 'FaceColor', [1 0.84 0], 'EdgeColor', 'k');
text(-period/2-20, 10, '20nm Au', 'FontSize', 10);

% Draw superstrate (quartz)
rectangle('Position', [-period/2 20 period 40], 'FaceColor', [0.8 0.8 1], 'EdgeColor', 'k');
text(-period/2-20, 40, 'Quartz', 'FontSize', 10);

% Format plot
axis equal;
xlim([-period/2-50 period/2+50]);
ylim([-50 70]);
xlabel('x (nm)');
ylabel('z (nm)');
title('Side Profile of Metasurface Structure');
grid on;

% Add period annotation
arrow_y = -45;
arrow_x = period/2;
annotation('doublearrow', ...
    [(arrow_x-period/2)/period+0.3 (arrow_x)/period+0.3], ...
    [arrow_y/120+0.5 arrow_y/120+0.5]);
text(0, arrow_y, [num2str(period) ' nm'], ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

% Overall title
sgtitle('Metasurface Unit Structure', 'FontSize', 14);

% Make figure background white
set(gcf, 'Color', 'w');

%% Complete 100 layer plot
% Loop through 5 figures, each with 20 subplots
for fig = 1:5
    figure('Position', [100 100 1200 800]);
    
    for i = 1:20
        pattern_idx = (fig-1)*20 + i;
        binary_pattern = Pattern{pattern_idx};
        period = Period(pattern_idx);
        
        subplot(4,5,i);
        imagesc([-period/2 period/2], [-period/2 period/2], binary_pattern);
        colormap([1 1 1; 1 0.84 0]);  % White for SOG, gold color for Au
        axis equal tight;
        xlabel('x (nm)');
        ylabel('y (nm)');
        title(['Pattern ' num2str(pattern_idx)]);
    end
    
    sgtitle(['Metasurface Patterns ' num2str((fig-1)*20+1) ' - ' num2str(fig*20)], 'FontSize', 14);
    set(gcf, 'Color', 'w');
end
