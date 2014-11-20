% readimpact - Read impact XML data file.
% [origin,impacts] = readimpact(filename);
% Input:
%  - filename is a valid filename for a impact product XML file.
% Output:
%  - origin is a Matlab structure, containing time,lat,lon,depth,and mag.
%  - impacts is a structure array, where each element contains information
%            about an impact.  The fields are:
%      - type (shakingDeaths,totalDeaths,injuries,economicLoss)
%      - value (number of people or dollars)
%      - quality (few,some,many,nearly,at least,unconfirmed,
%                 estimate,exact,range)
%      - source (pde,htd,noaa,etc.)
function [origin,impacts] = readimpact(impactfile)
    root = xmlread(impactfile);
    eventlink = root.getElementsByTagName('event').item(0);
    maglink = eventlink.getElementsByTagName('magnitude').item(0);
    vlink = maglink.getElementsByTagName('value').item(0);
    mag = str2double(char(vlink.getFirstChild().getData()));
    origin = getOrigin(eventlink);
    origin.mag = mag;
    impacts = getImpacts(eventlink);
end

function impacts = getImpacts(eventlink)
    losstypes = {'people','dollars'};
    %extents = {'killed','injured'};
    prefimpactlist = eventlink.getElementsByTagName('impact:preferredImpactEstimateID');
    npref = prefimpactlist.getLength();
    prefimpacts = cell(1,npref);
    for i=1:npref
        prefimpacts{i} = char(prefimpactlist.item(i-1).getFirstChild().getData());
    end
    impactlist = eventlink.getElementsByTagName('impact:loss');
    impacts = struct('type','','value','','quality',nan,'source','');
    for i=1:impactlist.getLength()
        impactlink = impactlist.item(i-1);
        impactref = char(impactlink.getAttribute('impact:publicID'));
        if ~ismember(impactref,prefimpacts) %for now only getting preferred values
            continue
        end
        typelink = impactlink.getElementsByTagName('impact:type').item(0);
        itype = char(typelink.getFirstChild().getData());
        if ~ismember(itype,losstypes)
            continue;
        end
        extent = '';
        extlink = impactlink.getElementsByTagName('impact:extent').item(0);
        if ~isempty(extlink)
            extent = char(extlink.getFirstChild().getData()); %killed, injured, etc.
        end
        cause = '';
        if impactlink.getElementsByTagName('impact:cause').getLength()
            causelink = impactlink.getElementsByTagName('impact:cause').item(0);
            cause = char(causelink.getFirstChild().getData());
        end
        switch itype
            case 'people'
                switch extent
                    case 'killed'
                        switch cause
                            case 'shaking'
                                losstype = 'shakingDeaths';
                            case ''
                                losstype = 'totalDeaths';
                            otherwise
                                continue %we don't care about other types of fatalities
                        end
                    case 'injured'
                        losstype = 'injuries';
                    otherwise
                        continue
                end
            case 'dollars'
                losstype = 'economicLoss';
            otherwise
                continue
        end
        ivaluelink = impactlink.getElementsByTagName('impact:value').item(0);
        vlink = ivaluelink.getElementsByTagName('value').item(0);
        lossvalue = str2double(char(vlink.getFirstChild().getData()));
        qualitylink = impactlink.getElementsByTagName('impact:qualifier').item(0);
        lossquality = char(qualitylink.getFirstChild().getData());
        source = getSource(impactlink);
        %%%%HACK ALERT!
        if ismember(source,{'htd','noaa'}) && strcmpi(itype,'dollars')
            lossvalue = lossvalue * 1e6;
        end
        %%%%HACK ALERT!
        impact = struct('type',losstype,'value',lossvalue,'quality',lossquality,'source',source);
        if i == 1
            impacts(end) = impact;
        else
            impacts(end+1) = impact;
        end
    end
end

function source = getSource(impactlink)
    creationlink = impactlink.getElementsByTagName('impact:creationInfo').item(0);
    authorlink = creationlink.getElementsByTagName('author').item(0);
    source = char(authorlink.getFirstChild().getData());
    return;
end

function origin = getOrigin(eventlink)
    orlink = eventlink.getElementsByTagName('origin').item(0);
    latlink = orlink.getElementsByTagName('latitude').item(0);
    vlink = latlink.getElementsByTagName('value').item(0);
    lat = str2double(char(vlink.getFirstChild().getData()));
    lonlink = orlink.getElementsByTagName('longitude').item(0);
    vlink = lonlink.getElementsByTagName('value').item(0);
    lon = str2double(char(vlink.getFirstChild().getData()));
    deplink = orlink.getElementsByTagName('depth').item(0);
    vlink = deplink.getElementsByTagName('value').item(0);
    depth = str2double(char(vlink.getFirstChild().getData()));
    timelink = orlink.getElementsByTagName('time').item(0);
    vlink = timelink.getElementsByTagName('value').item(0);
    timestr = char(vlink.getFirstChild().getData());
    time = datenum(timestr,'yyyy-mm-ddTHH:MM:SS');
    origin = struct('time',time,'lat',lat,'lon',lon,...
        'depth',depth);
    return
end