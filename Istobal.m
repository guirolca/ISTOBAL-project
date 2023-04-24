function varargout = Istobal(varargin)
% ISTOBAL MATLAB code for Istobal.fig
%      ISTOBAL, by itself, creates a new ISTOBAL or raises the existing
%      singleton*.
%
%      H = ISTOBAL returns the handle to a new ISTOBAL or the handle to
%      the existing singleton*.
%
%      ISTOBAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ISTOBAL.M with the given input arguments.
%
%      ISTOBAL('Property','Value',...) creates a new ISTOBAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Istobal_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Istobal_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Istobal

% Last Modified by GUIDE v2.5 28-Nov-2019 18:56:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Istobal_OpeningFcn, ...
                   'gui_OutputFcn',  @Istobal_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Istobal is made visible.
function Istobal_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Istobal (see VARARGIN)
global SerPIC TamPaquete Distancia Potencia 

Distancia(1:6)=0;
Potencia(1:6)=0;


% Cierra los puertos que se hayan podido quedar abiertos
Puertos_Activos=instrfind; % Lee los puertos activos
if isempty(Puertos_Activos)==0 % Comprueba si hay puertos activos
    fclose(Puertos_Activos); % Cierra los puertos activos
    delete(Puertos_Activos) % Borra la variable Puertos_Activos
    clear Puertos_Activos % Destruye la variable Puertos_Activos
end

TamPaquete=9;

SerPIC = serial('COM10');
set(SerPIC,'BaudRate',115200);
set(SerPIC,'DataBits',8);
set(SerPIC,'Parity','none');
set(SerPIC,'StopBits',1);
set(SerPIC,'FlowControl','none');
fopen(SerPIC);

% Se configura en lidar en modo de disparo externo
Datos=[hex2dec('42') hex2dec('57') hex2dec('02') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('40')];
fwrite(SerPIC, Datos);
% Se espera la respuesta del lidar
pause(0.2);
% Se lee la respuesta del lidar para que no interfiera con la recepción de
% los datos
Nada=fread(SerPIC,8);
fclose(SerPIC);

fopen(SerPIC);
%Modo fijo del serLidar
Datos=[hex2dec('42') hex2dec('57') hex2dec('02') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('01') hex2dec('14')];
fwrite(SerPIC, Datos);
% Se esperan 0.2 sec antes de enviar el siguiente comando por precaución
pause(0.2);
Nada=fread(SerPIC,8);
%Modo distancia X (FALTA DETERMINAR EL MODO) del SerLidar 
Datos=[hex2dec('42') hex2dec('57') hex2dec('02') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('03') hex2dec('11')];
fwrite(SerPIC, Datos);
pause(0.2);
Nada=fread(SerPIC,8);
fclose(SerPIC);


set(SerPIC,'BytesAvailableFcnCount',TamPaquete); % Se configura en nº de bytes que debe haber en el buffer de recepción para disparar el evento Rx_Callback
set(SerPIC, 'BytesAvailableFcnMode' ,'byte');
set(SerPIC,'BytesAvailableFcn',{@procesamiento, handles});
fopen(SerPIC);
% Choose default command line output for Istobal
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);










% UIWAIT makes Istobal wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Istobal_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global SerPIC



pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Create the webcam object.

cam = webcam(1);
% Capture one frame to get its size.
videoFrame = snapshot(cam);
frameSize = size(videoFrame);

% Create the video player object. 
videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);



numPts = 0;
frameCount = 0;
cla
% Hint: get(hObject,'Value') returns toggle state of start
while get(hObject,'Value')
    videoFrame = snapshot(cam);
    videoFrameGray = rgb2gray(videoFrame);
    frameCount = frameCount + 1;
    
    if numPts < 10
        % Detection mode.
        bbox = detectPeopleACF(videoFrame);

        
        if ~isempty(bbox)
            % Find corner points inside the detected region.
            points = detectMinEigenFeatures(videoFrameGray, 'ROI', bbox(1, :));

            
            % Re-initialize the point tracker.
            xyPoints = points.Location;
            numPts = size(xyPoints,1);           
            release(pointTracker);
            initialize(pointTracker, xyPoints, videoFrameGray);
            
            % Save a copy of the points.
            oldPoints = xyPoints;           
            
            % Convert the rectangle represented as [x, y, w, h] into an
            % M-by-2 matrix of [x,y] coordinates of the four corners. This
            % is needed to be able to transform the bounding box to display
            % the orientation of the person.
            bboxPoints = bbox2points(bbox(1, :));            
            
            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4] 
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);           
            
            % Display a bounding box around the detected person.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);
            
            % Display detected corners.
            videoFrame = insertMarker(videoFrame, xyPoints, '+', 'Color', 'white');
        end
        
    else
        % Tracking mode.
        [xyPoints, isFound] = step(pointTracker, videoFrameGray);
        visiblePoints = xyPoints(isFound, :);
        oldInliers = oldPoints(isFound, :);
                
        numPts = size(visiblePoints, 1);       
        
        if numPts >= 10
            % Estimate the geometric transformation between the old points
            % and the new points.
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);            
            
            % Apply the transformation to the bounding box.
            bboxPoints = transformPointsForward(xform, bboxPoints);
            
            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4] 
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);
            
            % Calculate center of box            
            center = [(bboxPolygon(1)+bboxPolygon(5))/2,(bboxPolygon(2)+bboxPolygon(6))/2];
            
            % Display a bounding box around the person being tracked.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);
            
            % Display tracked points.
            videoFrame = insertMarker(videoFrame, visiblePoints, '+', 'Color', 'white');
            
            % Display tracked center of box.
            videoFrame = insertMarker(videoFrame,center , '+', 'Color', 'red');
            
            % Reset the points.
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
        end

    end
        
    % Display the annotated video frame using the video player object.
%     step(videoPlayer, videoFrame);
    imshow(videoFrame, 'Parent', handles.axes1);
    set(hObject,'String','STOP','BackgroundColor','red');
    set(handles.text2, 'String', 'Aqui distancia');
    
    Datos=[hex2dec('42') hex2dec('57') hex2dec('02') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('41')];
    fwrite(SerPIC, Datos);

   
   
end
clear cam;
release(videoPlayer);
release(pointTracker);
set(hObject,'String','START','BackgroundColor','green');
set(handles.text2, 'String', '');
cla

function procesamiento (hObject, eventdata, handles, varargin)
 global SerPIC TamPaquete Distancia Potencia

num=SerPIC.BytesAvailable;
if num>TamPaquete-1
    
    % Se leen los datos
    Datos=fread(SerPIC,TamPaquete);
    % Se busca en incio de trama
    k=find(Datos==89,1,'first');
    % Se comprueba el segundo byte de inicio de trama
    if Datos(k+1)== 89        
        % Se comrpueba el chksum
        if mod(sum(Datos(k:k+7)),256)==Datos(k+8)
            % Si todo es correcto se toma la 
            Distancia=Datos(k+2)+Datos(k+3)*256;
            Potencia=Datos(k+4)+Datos(k+5)*256;
            Distancia
        end 
        
    end
end



