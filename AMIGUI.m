function varargout = AMIGUI(varargin)
% AMIGUI MATLAB code for AMIGUI.fig
%      AMIGUI, by itself, creates a new AMIGUI or raises the existing
%      singleton*.
%
%      H = AMIGUI returns the handle to a new AMIGUI or the handle to
%      the existing singleton*.
%
%      AMIGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AMIGUI.M with the given input arguments.
%
%      AMIGUI('Property','Value',...) creates a new AMIGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AMIGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AMIGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AMIGUI

% Last Modified by GUIDE v2.5 31-Aug-2017 15:22:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AMIGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @AMIGUI_OutputFcn, ...
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


% --- Executes just before AMIGUI is made visible.
function AMIGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AMIGUI (see VARARGIN)

% Choose default command line output for AMIGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AMIGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- MYCODE ---
% Initializes objects to inactive (until the user loads data)
set(handles.calculate,'Enable','off');
set(handles.savenpmiplot,'Enable','off');
set(handles.savenpmidisplay,'Enable','off');
set(handles.shownpmiplot,'Enable','off');
set(handles.showscatterplot,'Enable','off');
% Initializes the plot axes
% Merge display axes
axes(handles.axes1); %Selects the axes to be modified
box 'off';
grid 'off';
xticklabels({}); % curly braces because it has to be a string array
yticklabels({});
hold 'on'; % maintains formatting when new data is graphed

% NPMI plot axes
axes(handles.axes2);
box 'on';
grid 'on';
set(handles.axes2,'FontSize',8,'LineWidth',2);
xlim(handles.axes2,[0 255]);
ylim(handles.axes2,[0 255]);
xlabel('Ch1 Pixel Intensity');
ylabel('Ch2 Pixel Intensity');
map = colormap(parula(256)); %colormap is an array that holds the color LUT
map(1,:) = 1;
colormap(handles.axes2, map);
% The colorbar is displayed WITHIN the axes so you have to make space for it in GUIDE
colorbar('eastoutside');
hold 'on';
% Npmi display axes
axes(handles.axes3);
box 'off';
grid 'off';
xticklabels({});
yticklabels({});
map = colormap(parula(256)); %colormap is an array that holds the color LUT
map(1,:) = 0;
colormap(handles.axes3, map);
hold 'on';

% --- Outputs from this function are returned to the command line.
function varargout = AMIGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ch1img.
function ch1img_Callback(hObject, eventdata, handles)
% hObject    handle to ch1img (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
[file1,path1] = uigetfile('*.tif','Choose Channel 1 Image (.tif)');
set(handles.ch1imgpath,'String',fullfile(path1,file1)); % displays the path
img1 = tiffreader2(file1,path1);
setappdata(handles.ch1img,'img1',img1); % makes the data available to other callbacks
colormap(handles.axes1,'gray');
fuimg1  = flipud(img1);
imagesc(handles.axes1,fuimg1);

% Allows calculation once two images are open
if isappdata(handles.ch1img,'img1') && isappdata(handles.ch2img,'img2') 
	% Enables calculation
	set(handles.calculate,'Enable','on'); 
	% Displays a merge image
	img2 = getappdata(handles.ch2img,'img2'); % Gets img1 from the other callback
	merge = imfuse(img1,img2,'falsecolor'); % Makes green/magenta merge
	imshow(merge, 'Parent', handles.axes1); % displays img on axes1; imshow automatically does flipud
end

% --- Executes on button press in ch2img.
function ch2img_Callback(hObject, eventdata, handles)
% hObject    handle to ch2img (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
[file2,path2] = uigetfile('*.tif','Choose Channel 2 Image (.tif)');
set(handles.ch2imgpath,'String',fullfile(path2,file2)); % displays the path
img2 = tiffreader2(file2,path2);
setappdata(handles.ch2img,'img2',img2); % makes the data available to other callbacks
colormap(handles.axes1,'gray');
fuimg2  = flipud(img2);
imagesc(handles.axes1,fuimg2);

% Allows calculation once two images are open
if isappdata(handles.ch1img,'img1') && isappdata(handles.ch2img,'img2') 
	% Enables calculation
	set(handles.calculate,'Enable','on'); 
	% Displays a merge image
	img1 = getappdata(handles.ch1img,'img1'); % Gets img1 from the other callback
	merge = imfuse(img1,img2,'falsecolor'); % Makes green/magenta merge
	imshow(merge, 'Parent', handles.axes1); % displays img on axes1; imshow automatically does flipud
end

% --- Executes on button press in calculate.
function calculate_Callback(hObject, eventdata, handles)
% hObject    handle to calculate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
% Collects data for calculations
img1 = getappdata(handles.ch1img,'img1');
img2 = getappdata(handles.ch2img,'img2');
ch1gain = str2double(get(handles.ch1gain,'String')); % gets the value of property string
ch2gain = str2double(get(handles.ch2gain,'String'));

% *** DOES THE AMI and NPMI CALCULATIONS ***
% ami is the ami value
% disppmis is the NPMI Plot
[ami, disppmis] = fMI6EST4(img1, img2, ch1gain, ch2gain); 
% Shows the AMI result in the GUI
set(handles.amiout,'String',num2str(round(ami,3)));
% Shows the NPMI Plot in the GUI
view(handles.axes2,2);
surf(disppmis,'Parent',handles.axes2,'EdgeColor','none'); % refers the plot to axes1
setappdata(handles.calculate,'npmiplot',disppmis); % makes available

% *** CREATES THE NPMI Display ***
[pmiimg] = fPMI_Image7(img1, img2, disppmis);
fupmiimg  = flipud(pmiimg);
view(handles.axes3,2);
surf(fupmiimg,'Parent',handles.axes3,'EdgeColor','none'); % refers the plot to axes1
setappdata(handles.calculate,'npmidisp',fupmiimg); % makes available

% Enables saving of results etc
set(handles.savenpmiplot,'Enable','on');
set(handles.savenpmidisplay,'Enable','on');
set(handles.shownpmiplot,'Enable','on');
set(handles.showscatterplot,'Enable','on');


% --- Executes on button press in shownpmiplot.
function shownpmiplot_Callback(hObject, eventdata, handles)
% hObject    handle to shownpmiplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
cla(handles.axes2); %clears the axes
% Draws graph
npmiplot = getappdata(handles.calculate,'npmiplot');
view(handles.axes2,2);
surf(npmiplot,'Parent',handles.axes2,'EdgeColor','none'); % refers the plot to axes1
% Turns off other button
set(handles.showscatterplot,'Value',0);


% --- Executes on button press in showscatterplot.
function showscatterplot_Callback(hObject, eventdata, handles)
% hObject    handle to showscatterplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
% Calculates and displays the scatterplot
img1 = getappdata(handles.ch1img,'img1');
img2 = getappdata(handles.ch2img,'img2');
% Removes saturated pixels (255,y) or (x,255)
img1(img1 == 255) = 0;
img2(img2 == 255) = 0;
% Takes the intersection of the images (keeps only pairs where both values are > 0)
img1(img2 == 0) = 0;	
img2(img1 == 0) = 0;
% Makes the plot
[scatplot,Xedges,Yedges] = histcounts2(img1,img2,'BinWidth',[1 1],'XBinLimits',[0 255],'YBinLimits',[0 255]); % inherently graphs unless you work with the object
scatplot(1,1) = 0;
cla(handles.axes2); %clears the axes
view(handles.axes2,2);
surf(scatplot,'Parent',handles.axes2,'EdgeColor','none'); % refers the plot to axes2
setappdata(handles.showscatterplot,'scatter',scatplot); % makes available
% Turns off other button
set(handles.shownpmiplot,'Value',0);


% --- Executes on button press in savenpmiplot.
function savenpmiplot_Callback(hObject, eventdata, handles)
% hObject    handle to savenpmiplot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
% Saves the data behind the graph that is currently shown
if get(handles.shownpmiplot,'Value') == 1
	npmiplot = getappdata(handles.calculate,'npmiplot');
	npmiplot = flipud(npmiplot);
	[filename,path] = uiputfile('NPMI_Plot.tif','Save Results As...');
	tiffwrite2(npmiplot,path,filename,32,0);
else
	scatplot = getappdata(handles.showscatterplot,'scatter');
	scatplot = flipud(scatplot);
	[filename,path] = uiputfile('Scatter_Plot.tif','Save Results As...');
	tiffwrite2(scatplot,path,filename,32,0);
end

% --- Executes on button press in savenpmidisplay.
function savenpmidisplay_Callback(hObject, eventdata, handles)
% hObject    handle to savenpmidisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- MYCODE ---
npmidisplay = getappdata(handles.calculate,'npmidisp');
npmidisplay = flipud(npmidisplay);
[filename,path] = uiputfile('NPMI_Display.tif','Save Results As...');
tiffwrite2(npmidisplay,path,filename,32,0);


function amiout_Callback(hObject, eventdata, handles)
% hObject    handle to amiout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of amiout as text
%        str2double(get(hObject,'String')) returns contents of amiout as a double


% --- Executes during object creation, after setting all properties.
function amiout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to amiout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch1imgpath_Callback(hObject, eventdata, handles)
% hObject    handle to ch1imgpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch1imgpath as text
%        str2double(get(hObject,'String')) returns contents of ch1imgpath as a double


% --- Executes during object creation, after setting all properties.
function ch1imgpath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch1imgpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch2imgpath_Callback(hObject, eventdata, handles)
% hObject    handle to ch2imgpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch2imgpath as text
%        str2double(get(hObject,'String')) returns contents of ch2imgpath as a double


% --- Executes during object creation, after setting all properties.
function ch2imgpath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch2imgpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ch1gain_Callback(hObject, eventdata, handles)
% hObject    handle to ch1gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch1gain as text
%        str2double(get(hObject,'String')) returns contents of ch1gain as a double


% --- Executes during object creation, after setting all properties.
function ch1gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch1gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ch2gain_Callback(hObject, eventdata, handles)
% hObject    handle to ch2gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ch2gain as text
%        str2double(get(hObject,'String')) returns contents of ch2gain as a double


% --- Executes during object creation, after setting all properties.
function ch2gain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ch2gain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
