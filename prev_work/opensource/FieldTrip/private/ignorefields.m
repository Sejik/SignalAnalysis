function ignore = ignorefields(purpose)

% IGNOREFIELDS returns a list of fields that can be present in the cfg structure that
% should be ignored at various places in the code, e.g. for provenance, history,
% size-checking, etc.

switch purpose

    case 'pipeline'
    ignore = {
      % some fields that are always allowed to be present in the configuration
      'leadfield'
      'inside'
      'cfg'
      'previous'
      };

  case 'allowed'
    ignore = {
      % some fields that are always allowed to be present in the configuration
      'trackconfig'
      'checkconfig'
      'checksize'
      'trackusage'
      'trackdatainfo'
      'trackcallinfo'
      'showcallinfo'
      'callinfo'
      'version'
      'warning'
      'debug'
      'previous'
      'progress'
      'outputfilepresent'
      };
    
    
  case {'provenance', 'history'}
    ignore = {
      % these should not be included in the provenance or history
      'checkconfig'
      'checksize'
      'trackconfig'
      'trackusage'
      'trackdatainfo'
      'trackcallinfo'
      'showcallinfo'
      'callinfo'
      'warning'
      'debug'
      'progress'
      };
    
    
  case 'trackconfig'
    ignore = {
      % these fields from the user should be ignored
      'checksize'
      'trl'
      'trlold'
      'event'
      'artifact'
      'artfctdef'
      % these fields are for internal usage only
      'checkconfig'
      'checksize'
      'trackconfig'
      'trackusage'
      'trackdatainfo'
      'trackcallinfo'
      'showcallinfo'
      'callinfo'
      'version'
      'warning'
      'debug'
      'previous'
      };
    
  case 'checksize'
    ignore = {
      % the size of these fields should not be checked
      'checksize'
      'trl'
      'trlold'
      'event'
      'artifact'
      'artfctdef'
      'previous'
      };
    
  otherwise
    error('invalid purpose');
end % switch purpose