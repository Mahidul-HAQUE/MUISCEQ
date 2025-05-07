function audio_equalizer_UI
    clc; clear; close all;

    %% 1. Load Audio File
    [audio, fs] = audioread('2.mp3'); 
    audio = audio(:,1); 
    global filtered_audio band_gains fs audio f_axes slider_handles gain_text_handles player% Modified
    
    band_gains = ones(1,7);
    filtered_audio = audio;

    %% 2. Define Frequency Bands
    bands = [20 60; 60 250; 250 500; 500 2000; 2000 4000; 4000 6000; 6000 20000];
    band_labels = ["Sub", "Bass", "Low Mid", "Mid", "Up Mid", "Presence", "Brilliance"];

    %% 3. Create UI Figure
    f = figure('Name', 'Real-Time Audio Equalizer', 'NumberTitle', 'off', ...
        'Position', [200, 100, 1000, 500], 'Color', [0.94 0.94 0.94]);

    %% Store handles for all UI elements
    slider_handles = gobjects(1,7);
    gain_text_handles = gobjects(1,7); % Added handle storage

    for i = 1:7
        %% Band labels
        uicontrol('Style', 'text', ...
            'Position', [40, 450-(i*50), 100, 20], ...
            'String', band_labels(i), ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', [0.94 0.94 0.94]);

        %% Gain sliders
        slider_handles(i) = uicontrol('Style', 'slider', ...
            'Position', [150, 450-(i*50), 300, 20], ...
            'Min', 0.5, 'Max', 2, ...
            'Value', band_gains(i), ...
            'Callback', @(src,~) update_gains(i, src.Value));

        %% Gain value displays
        gain_text_handles(i) = uicontrol('Style', 'text', ... % Store handle
            'Position', [460, 450-(i*50), 60, 20], ...
            'String', sprintf('%.1fx', band_gains(i)), ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', [0.94 0.94 0.94]);
    end
    % Preset Selector
    uicontrol('Style', 'text', ...
        'Position', [600, 450, 150, 20], ...
        'String', 'Select Preset:', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.94 0.94 0.94]);
    preset_menu = uicontrol('Style', 'popupmenu', ...
        'Position', [600, 420, 150, 30], ...
        'String', {'Flat', 'Rock', 'Jazz', 'Bass Boost', 'Classical'}, ...
        'Callback', @apply_preset, ...
        'BackgroundColor', 'white');

    % Action Buttons
    btn_ypos = 50;
    uicontrol('Style', 'pushbutton', ...
        'String', 'Play', ...
        'Position', [40, btn_ypos, 100, 40], ...
        'Callback', @play_audio, ...
        'BackgroundColor', [0.47 0.67 0.19], ...
        'ForegroundColor', 'white');
    
    uicontrol('Style', 'pushbutton', ...
        'String', 'Stop', ...
        'Position', [180, btn_ypos, 100, 40], ...
        'Callback', @stop_audio, ...
        'BackgroundColor', [0.77 0.12 0.23], ...
        'ForegroundColor', 'white');
    
    uicontrol('Style', 'pushbutton', ...
        'String', 'Save Audio', ...
        'Position', [320, btn_ypos, 100, 40], ...
        'Callback', @save_audio, ...
        'BackgroundColor', [0.12 0.47 0.77], ...
        'ForegroundColor', 'white');

    %% Frequency Spectrum Visualization
    f_axes = axes('Parent', f, ...
        'Position', [0.58, 0.15, 0.38, 0.75], ... % [left bottom width height]
        'XScale', 'log', ... % Better frequency representation
        'XGrid', 'on', 'YGrid', 'on');
    title('Real-Time Frequency Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    xlim([20 20000]); % Human hearing range

    %% Initial Processing
    apply_filters();
    % Compare original vs processed
    difference = audio(1:length(filtered_audio)) - filtered_audio;
    fprintf('Max difference: %.10f\n', max(abs(difference)));
    %% Preset Application Function
    function apply_preset(src, ~)
        presets = containers.Map(...
            {'Flat', 'Rock', 'Jazz', 'Bass Boost', 'Classical'}, ...
            {[1, 1, 1, 1, 1, 1, 1], ...         % Flat
             [0.8, 0.9, 1.2, 1.5, 1.4, 1.3, 1.2], ... % Rock
             [0.9, 1.1, 1.0, 1.3, 1.2, 1.1, 1.0], ... % Jazz
             [1.3, 1.0, 1.0, 0.9, 0.8, 0.8, 0.7], ... % Bass Boost
             [1.0, 1.0, 1.0, 1.1, 1.2, 1.3, 1.4]});   % Classical

        selected_preset = src.String{src.Value};
        band_gains = presets(selected_preset);

        for i = 1:7
            slider_handles(i).Value = band_gains(i);
            % Direct handle access instead of findobj
            gain_text_handles(i).String = sprintf('%.1fx', band_gains(i)); 
        end
        apply_filters();
        % Compare original vs processed
        difference = audio(1:length(filtered_audio)) - filtered_audio;
        fprintf('Max difference: %.10f\n', max(abs(difference)));
    end

    %% Core Audio Processing
    function update_gains(band_idx, new_gain)
        band_gains(band_idx) = new_gain;
        % Direct handle access
        gain_text_handles(band_idx).String = sprintf('%.1fx', new_gain);
        apply_filters();
        % Compare original vs processed
        difference = audio(1:length(filtered_audio)) - filtered_audio;
        fprintf('Max difference: %.10f\n', max(abs(difference)));
    end

function apply_filters()
    % Access global variables (without redeclaring them)

    if all(band_gains == 1)
        filtered_audio = audio; % Bypass processing
    else
        N = 100; 
        beta = 0.5;
        filtered_audio = zeros(size(audio));

        for i = 1:7
            f_range = bands(i,:);
            
            if f_range(1) == 20
                b = fir1(N, f_range(2)/(fs/2), 'low', kaiser(N+1, beta));
            elseif f_range(2) == 20000
                b = fir1(N, f_range(1)/(fs/2), 'high', kaiser(N+1, beta));
            else
                b = fir1(N, f_range/(fs/2), 'bandpass', kaiser(N+1, beta));
            end
            
            filtered_band = filtfilt(b, 1, audio);
            filtered_audio = filtered_audio + band_gains(i) * filtered_band;
        end
        
        filtered_audio = filtered_audio / max(abs(filtered_audio));
    end

    % If the audio is playing, update it in real-time
    if isvalid(player) && isplaying(player)
        stop(player);   % Stop the current playback
        player = audioplayer(filtered_audio, fs);
        play(player);   % Restart playback with new filtered audio
    end

    update_fft();
end

    %% Visualization Update
    function update_fft()
        % Calculate spectra
        L = min(length(audio), 2^16); % Use consistent length
        win = hann(L);
        
        [P_orig, f] = pwelch(audio(1:L), win, 0.5*L, L, fs);
        P_filt = pwelch(filtered_audio(1:L), win, 0.5*L, L, fs);

        % Convert to dB scale
        P_orig_db = 10*log10(P_orig);
        P_filt_db = 10*log10(P_filt);

        % Update plot
        plot(f_axes, f, P_orig_db, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
        hold(f_axes, 'on');
        plot(f_axes, f, P_filt_db, 'b', 'LineWidth', 1.5);
        hold(f_axes, 'off');
        legend(f_axes, 'Original', 'Filtered', 'Location', 'southwest');
        drawnow;
    end

    %% Audio Controls
    function play_audio(~, ~)
        sound(filtered_audio, fs);
    end

    function stop_audio(~, ~)
        clear sound;
    end

    function save_audio(~, ~)
        [file, path] = uiputfile('*.mp3', 'Save Processed Audio');
        if file
            audiowrite(fullfile(path, file), filtered_audio, fs);
            msgbox('Audio saved successfully!', 'Success');
        end
    end
end