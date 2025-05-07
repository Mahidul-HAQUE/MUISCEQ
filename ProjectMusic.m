function audio_equalizer_UI
    clc; clear; close all;

    %% 1. Load Audio File
    [audio, fs] = audioread('2.mp3'); 
    audio = audio(:,1); % Use only the first channel if stereo
    global filtered_audio band_gains fs audio top_axes bottom_axes slider_handles gain_text_handles bands

    band_gains = ones(1,7); % Initialize gains for 7 bands
    filtered_audio = audio; % Initialize filtered audio

    %% 2. Define Frequency Bands
    bands = [20 60; 60 250; 250 500; 500 2000; 2000 4000; 4000 6000; 6000 20000];
    band_labels = ["Sub", "Bass", "Low Mid", "Mid", "Up Mid", "Presence", "Brilliance"];

    %% 3. Create UI Figure
    f = figure('Name', 'Real-Time Audio Equalizer', 'NumberTitle', 'off', ...
        'Position', [200, 100, 1000, 500], 'Color', [0.94 0.94 0.94]);

    %% 4. Add UI Controls on the Left Side
    slider_handles = gobjects(1,7);
    gain_text_handles = gobjects(1,7);

    for i = 1:7
        % Band labels
        uicontrol('Style', 'text', ...
            'Position', [40, 450-(i*50), 100, 20], ...
            'String', band_labels(i), ...
            'HorizontalAlignment', 'right', ...
            'BackgroundColor', [0.94 0.94 0.94]);

        % Gain sliders
        slider_handles(i) = uicontrol('Style', 'slider', ...
            'Position', [150, 450-(i*50), 300, 20], ...
            'Min', 0.5, 'Max', 2, ...
            'Value', band_gains(i), ...
            'Callback', @(src,~) update_gains(i, src.Value));

        % Gain value displays
        gain_text_handles(i) = uicontrol('Style', 'text', ...
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

    %% 5. Add Plots on the Right Side
    % Top Plot: Cumulative Frequency Response
    top_axes = axes('Parent', f, ...
        'Position', [0.58, 0.55, 0.38, 0.35], ... % [left, bottom, width, height]
        'XScale', 'log', 'XGrid', 'on', 'YGrid', 'on');
    title(top_axes, 'Cumulative Frequency Response');
    xlabel(top_axes, 'Frequency (Hz)');
    ylabel(top_axes, 'Magnitude (dB)');
    xlim(top_axes, [20, 20000]);

    % Bottom Plot: FFT of the Filtered Audio
    bottom_axes = axes('Parent', f, ...
        'Position', [0.58, 0.10, 0.38, 0.35], ... % [left, bottom, width, height]
        'XScale', 'log', 'XGrid', 'on', 'YGrid', 'on');
    title(bottom_axes, 'FFT of the Filtered Audio');
    xlabel(bottom_axes, 'Frequency (Hz)');
    ylabel(bottom_axes, 'Magnitude (dB)');
    xlim(bottom_axes, [20, 20000]);

    %% 6. Initial Processing
    apply_filters();
    update_plots();

    %% 7. Core Functions
    function apply_preset(src, ~)
        % Define presets
        presets = containers.Map(...
            {'Flat', 'Rock', 'Jazz', 'Bass Boost', 'Classical'}, ...
            {[1, 1, 1, 1, 1, 1, 1], ...         % Flat
             [0.8, 0.9, 1.2, 1.5, 1.4, 1.3, 1.2], ... % Rock
             [0.9, 1.1, 1.0, 1.3, 1.2, 1.1, 1.0], ... % Jazz
             [1.3, 1.0, 1.0, 0.9, 0.8, 0.8, 0.7], ... % Bass Boost
             [1.0, 1.0, 1.0, 1.1, 1.2, 1.3, 1.4]});   % Classical

        % Apply selected preset
        selected_preset = src.String{src.Value};
        band_gains = presets(selected_preset);

        % Update sliders and text displays
        for i = 1:7
            slider_handles(i).Value = band_gains(i);
            gain_text_handles(i).String = sprintf('%.1fx', band_gains(i)); 
        end
        apply_filters();
        update_plots();
    end

    function update_gains(band_idx, new_gain)
        band_gains(band_idx) = new_gain;
        gain_text_handles(band_idx).String = sprintf('%.1fx', new_gain);
        apply_filters();
        update_plots();
    end

    function apply_filters()

        if all(band_gains == 1)
            filtered_audio = audio; % Bypass processing
        else
            N = 100; % Filter order
            beta = 0.5; % Kaiser window parameter
            filtered_audio = zeros(size(audio));

            for i = 1:7
                f_range = bands(i,:); % Frequency range for the current band
                
                % Design the filter
                if f_range(1) == 20
                    b = fir1(N, f_range(2)/(fs/2), 'low', kaiser(N+1, beta)); % Low-pass filter
                elseif f_range(2) == 20000
                    b = fir1(N, f_range(1)/(fs/2), 'high', kaiser(N+1, beta)); % High-pass filter
                else
                    b = fir1(N, f_range/(fs/2), 'bandpass', kaiser(N+1, beta)); % Bandpass filter
                end
                
                % Apply the filter
                filtered_band = filtfilt(b, 1, audio); % Zero-phase filtering
                filtered_audio = filtered_audio + band_gains(i) * filtered_band; % Add to the output
            end
            
            % Normalize the audio
            filtered_audio = filtered_audio / max(abs(filtered_audio));
        end
    end

    function update_plots()

        % Length of the audio for analysis
        L = min(length(audio), 2^16); % Use consistent length
        win = hann(L); % Hann window for smoothing

        % Top Plot: Cumulative Frequency Response
        % Compute the frequency response of the filters
        [H, f] = freqz(1, 1, L, fs); % Placeholder for cumulative response
        cumulative_response = ones(size(f)); % Initialize cumulative response

        % Apply each filter's gain to the cumulative response
        for i = 1:7
            f_range = bands(i,:); % Frequency range for the current band
            if f_range(1) == 20
                b = fir1(100, f_range(2)/(fs/2), 'low'); % Low-pass filter
            elseif f_range(2) == 20000
                b = fir1(100, f_range(1)/(fs/2), 'high'); % High-pass filter
            else
                b = fir1(100, f_range/(fs/2), 'bandpass'); % Bandpass filter
            end
            [H, f] = freqz(b, 1, L, fs); % Frequency response of the current filter
            cumulative_response = cumulative_response .* (abs(H) * band_gains(i)); % Apply gain
        end

        % Plot cumulative frequency response
        plot(top_axes, f, 20*log10(cumulative_response), 'b', 'LineWidth', 1.5);
        title(top_axes, 'Cumulative Frequency Response');
        xlabel(top_axes, 'Frequency (Hz)');
        ylabel(top_axes, 'Magnitude (dB)');
        xlim(top_axes, [20, 20000]);
        grid(top_axes, 'on');

        % Bottom Plot: FFT of the Filtered Audio
        fft_filtered = abs(fft(filtered_audio(1:L) .* win)); % Apply window and compute FFT
        fft_filtered = fft_filtered(1:L/2+1); % Take one-sided spectrum
        fft_filtered(2:end-1) = 2 * fft_filtered(2:end-1); % Scale for one-sided
        freq = (0:L/2) * (fs / L); % Frequency vector

        % Plot FFT of the filtered audio
        plot(bottom_axes, freq, 20*log10(fft_filtered), 'r', 'LineWidth', 1.5);
        title(bottom_axes, 'FFT of the Filtered Audio');
        xlabel(bottom_axes, 'Frequency (Hz)');
        ylabel(bottom_axes, 'Magnitude (dB)');
        xlim(bottom_axes, [20, 20000]);
        grid(bottom_axes, 'on');

        drawnow; % Refresh the plots
    end

    %% 8. Audio Controls
    function play_audio(~, ~)
        sound(filtered_audio, fs); % Play the filtered audio
    end

    function stop_audio(~, ~)
        clear sound; % Stop audio playback
    end

    function save_audio(~, ~)
        [file, path] = uiputfile('*.mp3', 'Save Processed Audio');
        if file
            audiowrite(fullfile(path, file), filtered_audio, fs); % Save the audio
            msgbox('Audio saved successfully!', 'Success');
        end
    end
end