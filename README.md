matloss
=======

Matlab code for accessing and processing PAGER loss model input data.

Functions:
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
