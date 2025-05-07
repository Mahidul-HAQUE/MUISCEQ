function Sub = prioritize_gains(preset_gains, manual_gains, preset_selected)
    % Inputs:
    %   preset_gains: 1x7 vector (double)
    %   manual_gains: 1x7 vector (double)
    %   preset_selected: double (preset ID, e.g., 0=manual, 1-5=presets)
    %
    % Outputs:
    %   Sub: Prioritized gain for Sub band

    % Persistent variables to track state
    persistent prev_preset_selected;
    persistent prev_preset_gains;
    persistent prev_manual_gains;
    persistent manual_override; % Flag to track manual override

    % Initialize persistent variables
    if isempty(prev_preset_selected)
        prev_preset_selected = -1; % Invalid initial state
        prev_preset_gains = zeros(1,7);
        prev_manual_gains = zeros(1,7);
        manual_override = false; % No manual override initially
    end

    % Check if the PRESET has changed
    if preset_selected ~= prev_preset_selected
        % Preset changed: prioritize the new preset
        Sub = preset_gains(1);
        prev_preset_selected = preset_selected;
        prev_preset_gains = preset_gains;
        manual_override = false; % Reset manual override since preset changed
        prev_manual_gains = manual_gains; % Sync manual gains
        return; % Exit early to avoid further checks
    end

    % If preset is selected (1-5)
    if preset_selected ~= 0
        % Check if manual gain has changed
        if any(manual_gains ~= prev_manual_gains)
            % Manual gain changed: override preset
            Sub = manual_gains(1);
            prev_manual_gains = manual_gains;
            manual_override = true;
        else
            % Manual override stays active unless preset changes
            if manual_override
                Sub = prev_manual_gains(1); % Keep using manual gain
            else
                Sub = prev_preset_gains(1); % Default to preset gain
            end
        end
    else
        % Manual mode selected (preset_selected == 0)
        Sub = manual_gains(1); % Always prioritize manual in manual mode
        prev_manual_gains = manual_gains;
        manual_override = true;
    end
end
