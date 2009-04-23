function [data]=divideomega(data)
%DIVIDEOMEGA    Integrate SEIZMO records in the frequency domain
%
%    Usage:    data=divideomega(data)
%
%    Description: DIVIDEOMEGA(DATA) basically divides each point in the 
%     dependent component(s) of spectral files by:
%       OMEGA=2.0 * PI * FREQ
%     to perform the equivalent of integration in the time domain.  This is
%     particularly handy when working with spectral data as it avoids
%     the forward and inverse fourier transform necessary for time domain 
%     integration.  It is also useful for reducing the dynamic range of 
%     spectral data.
%
%    Notes:
%     - Read the source code below for a better description of the
%       operations performed for frequency-domain integration.
%
%    Tested on: Matlab r2007b
%
%    Header Changes: DEPMEN, DEPMIN, DEPMAX
%
%    Examples:
%     Integrate spectral data in the time domain vs frequency domain:
%      data=dft(integrate(idft(data)))
%      data=divideomega(data)
%
%    See also: multiplyomega, dft, idft

%     Version History:
%        May  12, 2008 - initial version
%        June 11, 2008 - doc cleanup
%        July  8, 2008 - doc update, single ch call, .dep rather than .x
%        July 19, 2008 - doc update, dataless support
%        Oct.  7, 2008 - minor code cleaning
%        Nov. 22, 2008 - update for new name schema (now DIVIDEOMEGA),
%                        changes idep field
%        Apr. 23, 2009 - fix nargchk and seizmocheck for octave,
%                        move usage up
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Apr. 23, 2009 at 20:10 GMT

% todo:

% check nargin
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data,'dep');
if(~isempty(msg)); error(msg.identifier,msg.message); end

% turn off struct checking
oldseizmocheckstate=get_seizmocheck_state;
set_seizmocheck_state(false);

% check headers
data=checkheader(data);

% retreive header info
leven=getlgc(data,'leven');
idep=getenumid(data,'idep');
iftype=getenumdesc(data,'iftype');
[e,delta,npts]=getheader(data,'e','delta','npts');
npts2=npts/2;
npts21=npts2-1;

% check leven,iftype
if(any(~strcmpi(leven,'true')))
    error('seizmo:divideomega:illegalOperation',...
        'Illegal operation on unevenly spaced record!');
elseif(any(~strcmpi(iftype,'Spectral File-Real/Imag')...
        & ~strcmpi(iftype,'Spectral File-Ampl/Phase')))
    error('seizmo:divideomega:illegalOperation',...
        'Illegal operation on a non-spectral file!');
end

% number of records
nrecs=numel(data);

% loop through records
depmen=nan(nrecs,1); depmin=depmen; depmax=depmen;
for i=1:nrecs
    % skip dataless
    if(isempty(data(i).dep)); continue; end
    
    % save class and convert to double precision
    oclass=str2func(class(data(i).dep));
    data(i).dep=double(data(i).dep);
    
    % integrate
    cols=size(data(i).dep,2);
    omega=[0 1./(2*pi*[linspace(delta(i),e(i),npts2(i)) ...
        linspace(e(i)-delta(i),delta(i),npts21(i))])].';
    if(strcmp(iftype(i),'Spectral File-Real/Imag'))
        % rlim %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 0Hz real/imag == 0 else
        % real=imag/omega & imag=-real/omega
        data(i).dep(:,[1:2:end 2:2:end])=oclass(...
            [data(i).dep(:,2:2:end).*omega(:,ones(1,cols/2))...
            -data(i).dep(:,1:2:end).*omega(:,ones(1,cols/2))]);
    else
        % amph %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % amp at 0Hz == 0 else amp=amp/omega
        % phase=phase+pi/2 at -Hz and 0Hz else phase=phase-pi/2
        data(i).dep(:,1:2:end)=...
            data(i).dep(:,1:2:end).*omega(:,ones(1,cols/2));
        data(i).dep(2:(npts2+1),2:2:end)=...
            data(i).dep(2:(npts2+1),2:2:end)-pi/2;
        data(i).dep([1 npts2+2:end],2:2:end)=...
            data(i).dep([1 npts2+2:end],2:2:end)+pi/2;
        data(i).dep=oclass(data(i).dep);
    end
    
    % dep*
    depmen(i)=mean(data(i).dep(:));
    depmin(i)=min(data(i).dep(:));
    depmax(i)=max(data(i).dep(:));
end

% change idep
vel=strcmpi(idep,'ivel');
acc=strcmpi(idep,'iacc');
if(any(vel)); idep(vel)={'idisp'}; end
if(any(acc)); idep(acc)={'ivel'}; end
if(any(~vel & ~acc)); idep(~vel & ~acc)={'iunkn'}; end

% update header
data=changeheader(data,'idep',idep,...
    'depmax',depmax,'depmin',depmin,'depmen',depmen);

% toggle checking back
set_seizmocheck_state(oldseizmocheckstate);

end