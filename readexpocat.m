% readexpocat - Load ExpoCat events from XML file OR structure array.
% allevents = readexpocat(xmlfile,param,value);
% Input:
%  - xmlfile Full path to the expocat.xml file OR structure array (see output)
%  - param Query method, currently supported are:
%          - ccode Get all events with epicenter in input two letter ISO country code.
%          - allccode Get all events that have any exposure in input two letter ISO country code.
%  - value Query parameter (currently two letter ISO country code).
% Output:
%  Structure array of events matching query, containing the following fields:
%   - time Matlab datenum representing the time of the event.
%   - lat Hypocentral latitude.
%   - lon Hypocentral longitude.
%   - depth Hypocentral depth.
%   - originsource Source of above origin information.
%   - mag Magnitude of the event.
%   - magsource Source of magnitude.
%   - ccode Country code of epicenter.
%   - exposum 10 element array of total population exposure to shaking (MMI I - X)
%   - exposures (Possibly empty) Structure array of per-country exposures, containing fields:
%     - ccode Country code where exposure occurred.
%     - exposure 10 element array of country population exposure to shaking (MMI I - X)
%     - time Event time (duplicated here to make searches efficient).
%   - impacts Structure containing earthquake impact structures:
%      -injured
%      -buildingsDestroyed
%      -missing
%      -buildingsDamaged
%      -shakingDeaths
%      -tsunamiDeaths
%      -totalDeaths
%      -displaced
%      -dollars
%      -tsunamiBuildingsDestroyed
%      -tsunamiInjured
%      -tsunamiBuildingsDamaged
%      -buildingsDamagedOrDestroyed
%   - effects Structure containing earthquake effect structures:
%      -fire
%      -liquefaction
%      -damage
%      -tsunami
%      -landslide
%      -casualty
%   Each impact and effect field is also structure containing two fields:
%     - source Source for impact/effect data.
%     - value Value for impact/effect.
% Usage:
% To read in all events from the expocat.xml file:
% allevents = readexpocat(allevents);
% (You can save this structure in a MAT file and quickly re-load it later.)
% To retrieve all events where epicenter is in Ecuador:
% inevents = readexpocat(allevents,'ccode','EC');
% To retrieve all events where there is *population exposure* in Ecuador:
% inevents = readexpocat(allevents,'allccode','EC');
function events = readexpocat(events,varargin)
    if strcmpi(class(events),'char') && exist(events,'file')
        events = readevents(events);
    end
    if nargin == 1
        return;
    end
    if nargin ~= 3
        fprintf('Usage error.  Returning list of all events.\n');
        return
    end
    param = varargin{1};
    value = varargin{2};
    switch param
        case 'ccode',
            idx = find(strcmpi({events(:).ccode},value));
        case 'allccode',
            expo = [events(:).exposures];
            ccodes = {expo(:).ccode};
            times = [expo(:).time];
            alltimes = [events(:).time];
            idx = find(strcmpi(ccodes,value));
            rtimes = times(idx);
            [tmp,idx] = ismember(rtimes,alltimes);
        case 'impact'
            impact_type = value{1};
            impact_minimum = value{2};
            idx = [];
            for i=1:length(events)
                imp = events(i).impacts.(impact_type).value;
                if ~isnan(imp) && imp > impact_minimum
                    idx(end+1) = i;
                end
            end
        case 'effect'
            idx = [];
            for i=1:length(events)
                eff = events(i).effects.(value).value;
                if ~isnan(eff) && eff ~= 0
                    idx(end+1) = i;
                end
            end
    end
    events = events(idx);
end

function events = readevents(xmlfile)
    root = xmlread(xmlfile);
    %pre-allocate the fields for the structure array
    events = struct('lat',nan,'lon',nan,'depth',nan,'time',nan,'originsource','',...
        'mag',nan,'magsource','',...
        'exposures',struct(),...
        'impacts',struct());
    
    eventlist = root.getElementsByTagName('event');
    for i=0:eventlist.getLength-1
        event = eventlist.item(i);
        origins = event.getElementsByTagName('origin');
        ccode = char(event.getAttribute('ccode'));
        for j=0:origins.getLength-1
            origin = origins.item(j);
            if strcmpi(char(origin.getAttribute('preferred')),'True')
                time = datenum(char(origin.getAttribute('time')));
                lat = str2double(char(origin.getAttribute('lat')));
                lon = str2double(char(origin.getAttribute('lon')));
                depth = str2double(char(origin.getAttribute('depth')));
                originsource = char(origin.getAttribute('source'));
                break;
            end
        end
        magnitudes = event.getElementsByTagName('magnitude');
        for j=0:magnitudes.getLength-1
            magnitude = magnitudes.item(j);
            if strcmpi(char(magnitude.getAttribute('preferred')),'True')
                mag = str2double(char(magnitude.getAttribute('value')));
                magsrc = char(magnitude.getAttribute('source'));
                break;
            end
        end
        exposures = struct('ccode','','exposure',[],'time',nan);
        expolist = event.getElementsByTagName('exposure');
        exposum = zeros(1,10);
        for j=0:expolist.getLength-1
            expo = expolist.item(j);
            expostr = char(expo.getFirstChild.getData);
            exposure = str2double(regexpi(expostr,'\s+','split'));
            ccode = char(expo.getAttribute('ccode'));
            %per-country exposure
            %adding time field for use in faster retrieval of this exposure
            %data
            exposures(j+1) = struct('ccode',ccode,'exposure',exposure,'time',time);
            exposum = exposum + exposure; %rolled up exposure
        end
        
        impactlist = event.getElementsByTagName('impact');
        impacts = struct('injured', struct('source','','value',nan),...
            'buildingsDestroyed', struct('source','','value',nan),...
            'missing', struct('source','','value',nan),...
            'buildingsDamaged', struct('source','','value',nan),...
            'shakingDeaths', struct('source','','value',nan),...
            'tsunamiDeaths', struct('source','','value',nan),...
            'totalDeaths', struct('source','','value',nan),...
            'displaced', struct('source','','value',nan),...
            'dollars', struct('source','','value',nan),...
            'tsunamiBuildingsDestroyed', struct('source','','value',nan),...
            'tsunamiInjured', struct('source','','value',nan),...
            'tsunamiBuildingsDamaged', struct('source','','value',nan),...
            'buildingsDamagedOrDestroyed', struct('source','','value',nan));
        for j=0:impactlist.getLength-1
            impact = impactlist.item(j);
            if ~strcmpi(char(impact.getAttribute('preferred')),'True')
                continue;
            end
            type = char(impact.getAttribute('type'));
            source = char(impact.getAttribute('source'));
            value = str2num(char(impact.getAttribute('value')));
            impacts.(type) = struct('source',source,'value',value);
        end
        
        effectlist = event.getElementsByTagName('effect');
        effects = struct('fire', struct('source','','value',nan),...
            'liquefaction',struct('source','','value',nan),...
            'damage',struct('source','','value',nan),...
            'tsunami', struct('source','','value',nan),...
            'landslide', struct('source','','value',nan),...
            'casualty',struct('source','','value',nan));
        for j=0:effectlist.getLength-1
            effect = effectlist.item(j);
            if ~strcmpi(char(effect.getAttribute('preferred')),'True')
                continue;
            end
            type = char(effect.getAttribute('type'));
            source = char(effect.getAttribute('source'));
            value = str2num(char(effect.getAttribute('value')));
            effects.(type) = struct('source',source,'value',value);
        end
        
        events(i+1).time = time;
        events(i+1).lat = lat;
        events(i+1).lon = lon;
        events(i+1).depth = depth;
        events(i+1).originsource = originsource;
        events(i+1).ccode = ccode;
        events(i+1).mag = mag;
        events(i+1).magsource = magsrc;
        events(i+1).exposum = exposum;
        events(i+1).exposures = exposures;
        events(i+1).impacts = impacts;
        events(i+1).effects = effects;
    end
end