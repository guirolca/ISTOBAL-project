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
global SerPIC TamPaquete 


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
Inic_Temporizador(handles)










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

function Inic_Temporizador(handles)
global Temporizador
Temporizador=timer;
set(Temporizador,'Period',0.2)
set(Temporizador,'ExecutionMode','fixedRate')
set(Temporizador,'TimerFcn',{@Timer,handles}) 
start(Temporizador)

function Timer(hObject, eventdata, handles)
global SerPIC

Datos=[hex2dec('42') hex2dec('57') hex2dec('02') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('00') hex2dec('41')];
    fwrite(SerPIC, Datos);



% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Temporizador
if get(hObject, 'start') == true
set(hObject,'String','START','BackgroundColor','green');
set(handles.text2, 'String', '');
else
stop(Temporizador);
delete(Temporizador);
clear Temporizador;
end

function procesamiento (hObject, eventdata, handles, varargin)
 global SerPIC TamPaquete Distancia Datos
 
 
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
            Distancia
        end 
        
    end
end



