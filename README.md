matloss
=======

Matlab code for accessing and processing PAGER loss model input data.

Installation:
Download gitinstall (https://github.com/mhearne-usgs/mgitinstall)

Then (in Matlab):

gitinstall https://github.com/mhearne-usgs/mgitinstall

Functions:
<pre>
  readexpocat - Load ExpoCat events from XML file OR structure array.
  allevents = readexpocat(xmlfile,param,value);
  Input:
   - xmlfile Full path to the expocat.xml file OR structure array (see output)
   - param Query method, currently supported are:
           - ccode Get all events with epicenter in input two letter ISO country code.
           - allccode Get all events that have any exposure in input two letter ISO country code.
   - value Query parameter (currently two letter ISO country code).
  Output:
   Structure array of events matching query, containing the following fields:
    - time Matlab datenum representing the time of the event.
    - lat Hypocentral latitude.
    - lon Hypocentral longitude.
    - depth Hypocentral depth.
    - originsource Source of above origin information.
    - mag Magnitude of the event.
    - magsource Source of magnitude.
    - ccode Country code of epicenter.
    - exposum 10 element array of total population exposure to shaking (MMI I - X)
    - exposures (Possibly empty) Structure array of per-country exposures, containing fields:
      - ccode Country code where exposure occurred.
      - exposure 10 element array of country population exposure to shaking (MMI I - X)
      - time Event time (duplicated here to make searches efficient).
    - impacts Structure containing earthquake impact structures:
       -injured
       -buildingsDestroyed
       -missing
       -buildingsDamaged
       -shakingDeaths
       -tsunamiDeaths
       -totalDeaths
       -displaced
       -dollars
       -tsunamiBuildingsDestroyed
       -tsunamiInjured
       -tsunamiBuildingsDamaged
       -buildingsDamagedOrDestroyed
    - effects Structure containing earthquake effect structures:
       -fire
       -liquefaction
       -damage
       -tsunami
       -landslide
       -casualty
    Each impact and effect field is also structure containing two fields:
      - source Source for impact/effect data.
      - value Value for impact/effect.
  Usage:
  To read in all events from the expocat.xml file:
  allevents = readexpocat(allevents);
  (You can save this structure in a MAT file and quickly re-load it later.)
  To retrieve all events where epicenter is in Ecuador:
  inevents = readexpocat(allevents,'ccode','EC');
  To retrieve all events where there is *population exposure* in Ecuador:
  inevents = readexpocat(allevents,'allccode','EC');
</pre>

<pre>
  readimpact - Read impact XML data file.
  [origin,impacts] = readimpact(filename);
  Input:
   - filename is a valid filename for a impact product XML file.
  Output:
   - origin is a Matlab structure, containing time,lat,lon,depth,and mag.
   - impacts is a structure array, where each element contains information
             about an impact.  The fields are:
       - type (shakingDeaths,totalDeaths,injuries,economicLoss)
       - value (number of people or dollars)
       - quality (few,some,many,nearly,at least,unconfirmed,
                  estimate,exact,range)
       - source (pde,htd,noaa,etc.)

</pre>
