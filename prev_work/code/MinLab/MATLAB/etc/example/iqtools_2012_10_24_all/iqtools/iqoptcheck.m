function result = iqoptcheck(arbConfig, model, feature)
% check connection and installed options
% returns 0 if fail, 1 if pass
result = 0;
found = 0;
arbConfig = loadArbConfig(arbConfig);

% first, check if the necessary options are available
f = iqopen(arbConfig);
if (isempty(f))
    return;
end
opts = query(f, '*OPT?');
if (~isempty(feature))
    if (~iscell(feature))
        feature = { feature };
    end
    for i = 1:length(feature)
        if (isempty(strfind(opts, feature{i})))
            errordlg({['This utility requires a software license for option "' feature{i} '"'] ...
                       'to be installed on the M8190A.'});
            return;
        end
    end
end
needOpt = [];
switch (arbConfig.model)
    case 'M8190A_12bit'
        needOpt = '12G';
    case 'M8190A_14bit'
        needOpt = '14B';
end
if (~isempty(needOpt) && (isempty(strfind(opts, needOpt))))
    errordlg({['You have selected ' arbConfig.model ' mode'] ...
        ['but you are missing the associated license (' needOpt ')'] ...
        'Please choose another mode in the "Configure' ...
        'Instrument Connection" window'});
    return;
end

% check if the correct model is selected
if (~isempty(model))
    if (~iscell(model))
        model = { model };
    end
    for i = 1:length(model)
        if (~isempty(strfind(arbConfig.model, model{i})))
            found = 1;
        end
    end
    if (~found)
        switch (model{1})
            case 'bit'
                errordlg({'This utility only works with the M8190A in 14bit' ...
                    'or 12bit mode. Please select one of these modes' ...
                    'in the "Configure Instrument Connection" window'});
                return;
            case 'DUC'
                errordlg({'This utility only works with the M8190A in' ...
                    'DUC mode. Please select one of DUC modes' ...
                    'in the "Configure Instrument Connection" window'});
                return;
            otherwise
                errordlg({['This utility will only work with instrument model ' model{1} '.'] ...
                    'Please select the appropriate instrument in the' ...
                    '"Configure Instrument Connection" window'});
                return;
        end
    end
end
% everything is fine --> return success
result = 1;
