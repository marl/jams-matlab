classdef JAMS

    % static methods
    methods(Static = true)
        
        function jams = load(filepath)
        %%LOAD Load jams data into a struct from jams filepath.
        %
        % SYNOPSIS
        %
        %   value = JAMS.load(filepath)
            jams = matjams_parse(filepath);
        end
        
    end
    
end

function jam_data = matjams_parse(jams_file)
%matjams_parse Parse a jams file into a more sane data structure.
%   Returns a struct with annotation types as fields.
%
% SYNOPSIS
%
%   jam_data = matjams_parse(filename)
%

    jams_struct = matjams_read(jams_file);


    beat = get_data(jams_struct,'beat');
    chord = get_data(jams_struct,'chord');
    genre = get_data(jams_struct, 'genre');
    key = get_data(jams_struct, 'key');
    melody = get_data(jams_struct, 'melody');
    mood = get_data(jams_struct, 'mood');
    note = get_data(jams_struct,'note');
    onset = get_data(jams_struct, 'onset');
    pattern = get_data(jams_struct, 'pattern');
    pitch = get_data(jams_struct, 'pitch');
    segment = get_data(jams_struct, 'segment');
    source = get_data(jams_struct, 'source');
    tag = get_data(jams_struct, 'tag');

    metadata = jams_struct.file_metadata;

    if isfield(jams_struct, 'sandbox')
        sandbox = jams_struct.sandbox;
    else
        sandbox = [];
    end

    jam_data = struct;

    jam_data.beats = beat;
    jam_data.chords = chord;
    jam_data.genre = genre;
    jam_data.key = key;
    jam_data.melody = melody;
    jam_data.mood = mood;
    jam_data.note = note;
    jam_data.onset = onset;
    jam_data.pattern = pattern;
    jam_data.pitch = pitch;
    jam_data.segment = segment;
    jam_data.source = source;
    jam_data.tag = tag;

    jam_data.metadata = metadata;
    jam_data.sandbox = sandbox;


%% Parsing Function %%

    function annot_data = get_data(jams_struct,annotation_type)
        % If field is not in the jams file, skip it %
        if ~isfield(jams_struct, annotation_type)
            annot_data = [];

        else
            annot_data = cell2mat(jams_struct.(annotation_type));
            n = size(annot_data,2);
            for i=1:n
                annot_data(i).data = cell2mat(annot_data(i).data);
            end
        end
    end

end

function value = matjams_read(filename, varargin)
%READ Load a matlab value from a JSON file.
%
% SYNOPSIS
%
%   value = json.read(filename)
%   value = json.read(..., optionName, optionValue, ...)
%
% The function parses a JSON file and load into a matlab value. By default,
% numeric literals are converted to double, string is converted to a char
% array, logical literals are converted to logical. A JSON array is converted
% to either a double array, a logical array, a cell array, or a struct
% array. A JSON object is converted to a struct array.
%
% The function takes the same options as json.load.
%
% See also json.load

  fid = 0;
  try
    fid = fopen(filename, 'r');
%     value = json.load(fscanf(fid, '%c', inf));
    value = matjams_load(fscanf(fid, '%c', inf));
    fclose(fid);
  catch e
    if fid ~= 0, fclose(fid); end
    rethrow(e);
  end

end

function value = matjams_load(str, varargin)
%LOAD Load matlab value from a JSON string.
%
% from: https://github.com/kyamagu/matlab-json
%
% SYNOPSIS
%
%   value = json.load(str)
%   value = json.dump(..., optionName, optionValue, ...)
%
% The function parses a JSON string into a matlab value. By default,
% numeric literals are converted to double, string is converted to a char
% array, logical literals are converted to logical. A JSON array is converted
% to either a double array, a logical array, a cell array, or a struct
% array. A JSON object is converted to a struct array.
%
% OPTIONS
%
% The function takes following options.
%
%   'MergeCell'   Try to convert a JSON array into a double, a logical, or
%                 a struct array when possible. Default true.
%
%   'ColMajor'    Represent matrix in column-major order. Default false.
%
% EXAMPLE
%
%   >> value = json.load('{"char":"hello","matrix":[[1,3],[4,2]]}')
%   value = 
% 
%         char: 'hello'
%       matrix: [2x2 double]
%
%   >> value = json.load('[[1,2,3],[4,5,6]]')
%   value =
%
%        1     2     3
%        4     5     6
%
%   >> value = json.load('[[1,2,3],[4,5,6]]', 'ColMajor', true)
%   value =
%        1     4
%        2     5
%        3     6
%
%   >> value = json.load('[[1,2,3],[4,5,6]]', 'MergeCell', false)
%   value = 
%
%       {1x3 cell}    {1x3 cell}
%
% NOTE
%
% Since any matlab values are an array, it is impossible to uniquely map
% all JSON primitives to matlab values. This implementation aims to have
% better interoperability across platforms. Therefore, some matlab values
% cannot be represented in a JSON string. For example, '[1,2,3]' is mapped to
% either [1, 2, 3] or {{1}, {2}, {3}} depending on 'MergeCell' option, but
% cannot produce {1, 2, 3}.
%
% See also json.dump json.read

%     'MergeCell', true,...

%   json.startup('WarnOnAddpath', true);
  matjams_startup('WarnOnAddpath', true);
  options = get_options_(struct(...
    'MergeCell', false,...
    'ColMajor', false...
    ), varargin{:});

  str = strtrim(str);
  assert(~isempty(str), 'Empty JSON string.');
  singleton = false;
  if str(1)=='{'
    node = org.json.JSONObject(java.lang.String(str));
  else
    singleton = str(1) ~= '[' && str(end) ~= ']';
    if singleton, str = ['[',str,']']; end
    node = org.json.JSONArray(java.lang.String(str));
  end
  value = parse_data_(node, options);
  if singleton, value = value{:}; end
end

function value = parse_data_(node, options)
%LOAD_DATA_
  if isa(node, 'char')
    value = char(node);
  elseif isa(node, 'double')
      value = double(node);
  elseif isa(node, 'logical')
    value = logical(node);
  elseif isa(node, 'org.json.JSONArray')
      node.debug = 0;
      if isa(node.get(0),'double')
          value = double(node.toDouble());
          return;
      end
        value = cell(node.length() > 0, node.length());
        for i = 1:node.length()
%             if isfloat(node.get(i-1))
%             double(node.getDouble(i-1))
%             end
            value{i} = parse_data_(node.get(i-1), options);
        end
        if options.MergeCell
          value = merge_cell_(value, options);  
        end
  elseif isa(node, 'org.json.JSONObject')
    value = struct;
    itr = node.keys();
    while itr.hasNext()
      key = itr.next();
      field = char(key);
      safe_field = field;
      if strcmp(field,'start') || strcmp(field,'end') %|| strcmp(field,'value')
          safe_field = strcat(field,'_t');
      end
%       safe_field = genvarname(char(key), fieldnames(value));
%       if ~strcmp(field, safe_field)
%         warning('json:fieldNameConflict', ...
%                 'Field %s renamed to %s', field, safe_field);
%       end
%     v = node.get(java.lang.String(key))
    
% node.get(java.lang.String(key));

      value.(safe_field) = parse_data_(node.get(java.lang.String(key)), ...
                                       options);
    end
  elseif isa(node, 'org.json.JSONObject$Null')
    value = [];
  else
    error('json:typeError', 'Unknown data type: %s', class(node));
  end
end

function value = merge_cell_(value, options)
%MERGE_CELL_
  if isempty(value) || all(cellfun(@isempty, value))
    return;
  end
  if isscalar(value)
    return;
  end
  if ~all(cellfun(@isscalar, value)) && all(cellfun(@ischar, value))
    return;
  end

  if is_mergeable_(value);
    dim = ndims(value)+1;
    mergeable = true;
    if options.ColMajor
      if all(cellfun(@isscalar, value))
        dim = 1;
        if all(cellfun(@iscell, value)) % Singleton row vector [[a],[b]].
          value = cat(2, value{:});
          mergeable = is_mergeable_(value);
          dim = 2;
        end
      elseif all(cellfun(@iscolumn, value))
        dim = 2;
      end
    else
      if all(cellfun(@isscalar, value))
        dim = 2;
        if all(cellfun(@iscell, value)) % Singleton col vector [[a],[b]].
          value = cat(1, value{:});
          mergeable = is_mergeable_(value);
          dim = 1;
        end
      elseif all(cellfun(@isrow, value))
        dim = 1;
      end
    end
    if mergeable
      value = cat(dim, value{:});
    end
  end
end

function flag = is_mergeable_(value)
%CHECK_MERGEABLE_ Check if the cell array is mergeabhe.
  signature = type_info_(value{1});
  flag = true;
  for i = 2:numel(value)
    vec = type_info_(value{i});
    flag = numel(signature) == numel(vec) && all(signature == vec);
    if ~flag, break; end
  end
end

function vec = type_info_(value)
%TYPE_INFO_ Return binary encoding of type information
  vec = [uint8(class(value)), typecast(size(value), 'uint8')];
  if isstruct(value)
    fields = fieldnames(value);
    vec = [vec, uint8([fields{:}])];
  end
end

function matjams_startup(varargin)
%STARTUP Initialize runtime environment.
%
% SYNOPSIS
%
%   json.startup(optionName, optionValue, ...)
%
% The function internally adds dynamic java class path. This process clears
% any matlab internal states, such as global/persistent variables or mex
% functions. To avoid unexpected state reset, execute this function once before
% using other json API functions.
% 
% OPTIONS
%
% The function takes a following option.
%
%   'WarnOnAddPath'   Warn when javaaddpath is internally called. Default false.
%
% EXAMPLE
%
%   >> json.startup
%
% See also javaaddpath javaclasspath
  error(javachk('jvm'));

  WARN_ON_ADDPATH = false;
  for i = 1:2:numel(varargin)
    switch varargin{i}
      case 'WarnOnAddpath', WARN_ON_ADDPATH = logical(varargin{i+1});
    end
  end
  jar_file = fullfile(fileparts(mfilename('fullpath')), 'java', 'json.jar');
  if ~any(strcmp(jar_file, javaclasspath))
    javaaddpath(jar_file);
    if WARN_ON_ADDPATH
      warning('json:startup', ['Adding json.jar to the dynamic Java class ' ...
        'path. This has cleared matlab internal states, such as global '...
        'variables, persistent variables, or mex functions. To avoid this, '...
        'call json.startup before using other json API functions. See '...
        '<a href="matlab:doc javaaddpath">javaaddpath</a> for more ' ...
        'information.' ...
        ]);
    end
  end
end