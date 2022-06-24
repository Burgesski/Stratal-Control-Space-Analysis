function strataSpaceGUI

%     clear all;
    
    gui.main = 0;
    gui.f1 = 0;
    
    const.VERBOSE = uint8(1); % Flag to determine volume of text output produced - 0 is terse, 1 is verbose
    const.LENPDF = uint32(1000); % Maximum length of the PDF records
    const.N = uint32(1000000); % the number of iterations performed in Monte Carlo methods to populate the control volume and area
    
    data.trajLoaded = 0;
    
    data.inputEustasyPDF = zeros(1,1);
    data.eustasyPDF = zeros(1,const.LENPDF);
    data.inputSubsidPDF = zeros(1,1);
    data.subsidPDF = zeros(1,const.LENPDF);
    data.inputSupplyPDF = zeros(1,1);
    data.supplyPDF = zeros(1,const.LENPDF);
    data.supplyReferenceArea = 6.05E10; % Area in km2 used to convert the supply volume in km3 to a thickness in km. 6.05E10 is the area of Holocene Mississippi delta and shelf topset deposition
    data.lenSubsidPDF = 0;
    data.subsidRange = 0;
    data.subsidPDF = 0; % Function to convert the PDF into the correct required format
    data.subsidValuesCount = 0;
    data.subsidIncrement = 0; % Assumes that bin spacing is constant through PDF
    data.subsidMin = 1000000; % - subsidIncrement;
    data.subsidMax = 0;
    data.lenSupplyPDF = 0;
    data.supplyRange = 0;
    data.supplyPDF = 0; % Function to convert the PDF into the correct required format
    data.supplyValuesCount = 0;
    data.supplyIncrement = 0; % Assumes that bin spacing is constant through PDF
    data.supplyMin = 0; % - subsidIncrement;
    data.supplyMax = 0;
    data.lenEustasyPDF = 0;
    data.eustasyRange = 0;
    data.eustasyPDF = 0; % Function to convert the PDF into the correct required format
    data.eustasyValuesCount = 0; 
    data.eustasyIncrement = 0; 
    data.eustasyMin = 1000000;
    data.eustasyMax = 0;
    
    volPlotVars.test = 0; % Make sure that the data structure is created and exists before being referenced
    
    areaPlotVars.test = 0; % Make sure that the data structure is created and exists before being referenced
    
    flags.PDFsLoaded = 0;
    flags.trajectoriesLoaded = 0;
    flags.controlVolumePlotted = 0;
    flags.controlAreaPlotted = 0;

    initializeGUI(gui, const, flags, data, volPlotVars, areaPlotVars);
end

function initializeGUI(gui, const, flags, data, volPlotVars, areaPlotVars)
    
    %  Create and then hide the GUI window as it is being constructed.
    
    % ScreenSize is a four-element vector: [left, bottom, width, height]:
    gui.scrsz = get(0,'ScreenSize'); % vector 
    scrWidthProportion = 0.75;
    scrHeightIncrement = gui.scrsz(4)/20; % Use this to space controls down right side of the main window
    controlStartY = (gui.scrsz(4) * 0.8) - (scrHeightIncrement / 2);
    controlStartX = (gui.scrsz(3) * scrWidthProportion) - 420;
    
    % position requires left bottom width height values. screensize vector
    % is in this format 1=left 2=bottom 3=width 4=height
    gui.main = figure('Visible','off','Position',[1 gui.scrsz(4)*scrWidthProportion gui.scrsz(3)*scrWidthProportion gui.scrsz(4)*0.8]);
   
    
   %  Construct the control panel components.
  
   hDataFnamePathLabel = uicontrol('style','text','string','PDF data files path:','Position',[controlStartX+45, controlStartY-scrHeightIncrement, 200, 15]);
   hDataFnamePath = uicontrol('Style','edit','String','../controlPDFs/','Position',[controlStartX+200, controlStartY-scrHeightIncrement, 200, 25]);
   
   % Control PDF data files
   hSubsidenceFnameLabel = uicontrol('style','text','string','Subsidence PDF filename:','Position',[controlStartX+30, (controlStartY-scrHeightIncrement*2), 200, 15]);
   hSubsidenceFname = uicontrol('Style','edit','String','subsidencePDF.txt','Position',[controlStartX+200, (controlStartY-scrHeightIncrement*2), 200, 25]);
   hSupplyFnameLabel = uicontrol('style','text','string','Supply PDF filename:','Position',[controlStartX+40, (controlStartY-scrHeightIncrement*3), 200, 15]);
   hSupplyFname = uicontrol('Style','edit','String','supplyPDF.txt','Position',[controlStartX+200, (controlStartY-scrHeightIncrement*3), 200, 25]);
   hEustasyFnameLabel = uicontrol('style','text','string','Eustasy PDF filename:','Position',[controlStartX+40, (controlStartY-scrHeightIncrement*4), 200, 15]);
   hEustasyFname = uicontrol('Style','edit','String','eustasyPDF.txt','Position',[controlStartX+200, (controlStartY-scrHeightIncrement*4), 200, 25]);
   
   % Trajectory data file
   hTrajectoryFnameLabel = uicontrol('style','text','string','Control trajectory filename:','Position',[controlStartX+30, (controlStartY-scrHeightIncrement*5), 200, 15]);
   hTrajectoryFname = uicontrol('Style','edit','String','trajectory.txt','Position',[controlStartX+200, (controlStartY-scrHeightIncrement*5), 200, 25]);
   
   hLoadPDFData = uicontrol('Style','pushbutton','String','Load and plot PDF data',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*6),200,25],...
          'BackgroundColor',[0.6 1.0 0.6],...
          'Callback',{@loadPDFButton_callback});
      
   hLoadTrajectoryData = uicontrol('Style','pushbutton','String','Load trajectory data',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*7),200,25],...
          'BackgroundColor',[0.6 1.0 0.6],...
          'Callback',{@loadTrajectoryButton_callback});
      
    hCalculateAndPlot3DControlVolume = uicontrol('Style','pushbutton','String','Plot 3D Control Volume',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*8),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@calculateAndPlot3DControlVolume_callback});
      
    hPlot3DControlTrajectories = uicontrol('Style','pushbutton','String','Plot 3D Control Trajectories',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*9),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@plot3DControlTrajectories_callback});
      
    hCalculateAndPlot2DControlArea = uicontrol('Style','pushbutton','String','Plot 2D Control Area',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*10),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@calculateAndPlot2DControlArea_callback});

    hPlot2DControlTrajectories = uicontrol('Style','pushbutton','String','Plot 2D Control Trajectories',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*11),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@plot2DControlTrajectories_callback});
      
    hCalculateASTRRValues = uicontrol('Style','pushbutton','String','Calculate ASTRR values',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*12),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@calculateASTRRValues_callback});
      
    hplotTrajectoryProbabilities = uicontrol('Style','pushbutton','String','Plot trajectory probabilities',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*13),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@plotTrajectoryProbabilities_callback});
      
    hplotFigureKeyElements = uicontrol('Style','pushbutton','String','Plot figure key elements',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*14),200,25],...
          'BackgroundColor',[0.8 0.9 1.0],...
          'Callback',{@plotFigureKeyElements_callback});
      
    hplotTrajectoryProbabilities = uicontrol('Style','pushbutton','String','Close windows & reset',...
          'Position',[controlStartX+200,controlStartY-(scrHeightIncrement*15),200,25],...
          'BackgroundColor',[0.972 0.513 0.474],...
          'Callback',{@resetButton_callback});
      
   % Assign the GUI a name to appear in the window title.
   set(gui.main,'Name','Stratal-Control-Space Plots')
   % Move the GUI to the center of the screen.
   movegui(gui.main,'center')
   % Make the GUI visible.
   set(gui.main,'Visible','on');
   
   % NB because the following callback functions are declared within initializeGUI they can see all the variables passed to
   % initializeGUI, so constant, flags, and data, and these can then be passed on as required to the functions that the buttons call

    function loadPDFButton_callback(source, eventdata)
               
         subsidenceFileNameAndPath = strcat(get(hDataFnamePath,'String'),get(hSubsidenceFname,'String'));
         supplyFileNameAndPath = strcat(get(hDataFnamePath,'String'),get(hSupplyFname,'String'));
         eustasyFileNameAndPath = strcat(get(hDataFnamePath,'String'),get(hEustasyFname,'String'));

         fprintf('\n\n===================================================== Loading PDF Data =====================================================\n');
         fprintf('Subsidence data from %s\nSupply data from %s\nEustasy data from %s\n', subsidenceFileNameAndPath, supplyFileNameAndPath, eustasyFileNameAndPath);

        [data, success] = loadPDFData(const, data, subsidenceFileNameAndPath, supplyFileNameAndPath, eustasyFileNameAndPath);
        if success == 1
            gui = plotControlPDFs(gui, const, data);
            flags.PDFsLoaded = 1; % Set flag to enable rest of the button functions
        end
    end

    function loadTrajectoryButton_callback(source, eventdata)
        
         trajectoryDataFileNameAndPath = strcat(get(hDataFnamePath,'String'),get(hTrajectoryFname,'String'));

         [data, success] = loadTrajectoryData(const, data, trajectoryDataFileNameAndPath);
         if success == 1
            flags.trajectoriesLoaded = 1; % Set flag to enable rest of the button functions
            message = sprintf('Trajectories successfully loaded from %s\n', trajectoryDataFileNameAndPath);
            m1 = msgbox(message,'Trajectory data loaded');
         end
    end

    function calculateAndPlot3DControlVolume_callback(source,eventdata)
        
        if flags.PDFsLoaded && ~flags.controlVolumePlotted % Only plot if PDFs loaded and plot not already plotted
            fprintf('\n\n===================================================== Plot 3D Stratal-Control Volume =====================================================\n');
            
            volPlotVars = calculate3DControlVolume(const, data, volPlotVars);
            gui = plot3DControlVolume(gui, data, volPlotVars);
            
            flags.controlVolumePlotted = 1; % Set flag to enable follow-on button functions
        else
            if ~flags.PDFsLoaded
                message = sprintf('Controls PDF data not loaded\nPlease use the load PDF data button first\n');
                m1 = msgbox(message,'No PDF data loaded');
            end
            
            if flags.controlVolumePlotted
                message = sprintf('Control volume already plotted\nPlease shut down current plot before plotting new\n');
                m1 = msgbox(message,'Control volume already plotted');
            end
        end
    end

    function plot3DControlTrajectories_callback(source,eventdata)
        
        if flags.trajectoriesLoaded && flags.controlVolumePlotted
            fprintf('\n\n===================================================== Plot 3D Control Trajectories =====================================================\n');
            
            volPlotVars = plot3DControlTrajectories(gui, const, data, volPlotVars);
            
        else
            message = sprintf('Control trajectories not loaded or control volume not plotted\nUsed the load trajectories and plot control volume buttons first\n');
            m1 = msgbox(message,'No traj loaded/vol plotted');
        end
    end

    function calculateAndPlot2DControlArea_callback(source,eventdata)
        
        if flags.PDFsLoaded && ~flags.controlAreaPlotted % Only plot if PDFs loaded and plot not already plotted
            fprintf('\n\n===================================================== Plot 2D Stratal-Control Area =====================================================\n');
            
            areaPlotVars = calculate2DControlArea(const, data, volPlotVars, areaPlotVars);
            gui = plot2DControlArea(gui, data, areaPlotVars);
            
            flags.controlAreaPlotted = 1; % Set flag to enable follow-on button functions
        else
            if ~flags.PDFsLoaded
                message = sprintf('Controls PDF data not loaded\nUse the load PDF data button first\n');
                m1 = msgbox(message,'No PDF data loaded');
            end
            
            if flags.controlAreaPlotted
                message = sprintf('Control area already plotted\nPlease shut down current plot before plotting new\n');
                m1 = msgbox(message,'Control area already plotted');
            end
        end
    end

    function plot2DControlTrajectories_callback(source,eventdata)
        
        if flags.trajectoriesLoaded && flags.controlAreaPlotted
            fprintf('\n\n===================================================== Plot 2D Control Trajectories =====================================================\n');
            
            areaPlotVars = plot2DControlTrajectories(gui, const, data, areaPlotVars);
            
        else
            message = sprintf('Control trajectories not loaded or control area not plotted\nUsed the load trajectories and plot control area buttons first\n');
            m1 = msgbox(message,'No traj loaded/area plotted');
        end
    end

    function calculateASTRRValues_callback(source,eventdata)
        
        if flags.trajectoriesLoaded && flags.controlAreaPlotted
            fprintf('\n\n===================================================== Plot 2D Control Trajectories =====================================================\n');
            
            calculateASTRRValues(data, areaPlotVars);
            
        else
            message = sprintf('Control trajectories not loaded or control area not plotted\nUsed the load trajectories and plot control area buttons first\n');
            m1 = msgbox(message,'No traj loaded/area plotted');
        end
    end

    function plotTrajectoryProbabilities_callback(source,eventdata)
        
        if flags.trajectoriesLoaded && flags.controlAreaPlotted
            fprintf('\n\n===================================================== Plot 2D Control Trajectories =====================================================\n');
            
            gui = plotTrajectoryProbabilities(gui, data, volPlotVars, areaPlotVars);
            
        else
            message = sprintf('Control trajectories not loaded or control area not plotted\nUse the load trajectories, plot control volume and plot control area buttons first\n');
            m1 = msgbox(message,'No traj loaded, volume or area plotted');
        end
    end

    function plotFigureKeyElements_callback(source,eventdata)
        
        gui = plotFigureKeyElements(gui, areaPlotVars);
    end

    function resetButton_callback(source, eventdata) 
      
        if isfield(gui,'f1')
           close(gui.f1);
           gui = rmfield(gui,'f1');
           flags.controlVolumePlotted = 0;
        end

        if isfield(gui,'f2')
           close(gui.f2);
           gui = rmfield(gui,'f2');
           flags.controlAreaPlotted = 0;
        end
        
        if isfield(gui,'f3')
           close(gui.f3);
           gui = rmfield(gui,'f3');
        end
        
        if isfield(gui,'f4')
           close(gui.f4);
           gui = rmfield(gui,'f4');
        end

        if isfield(gui,'sp1')
           cla(gui.s1);
        end

        if isfield(gui,'sp2')
           cla(gui.s2);
        end

        if isfield(gui,'sp3')
           cla(gui.s3);
        end
        
       % Reset data arrays here
    end
end

function [data, success] = loadPDFData(const, data, subsidenceFileNameAndPath, supplyFileNameAndPath, eustasyFileNameAndPath)
   
    success = 1; % Assume files will all load, but if they don't set this flag to 0 before the end of this function

    % Read in the subsidence PDF file and calculate useful values from the PDF to be used in the rest of the code
    if exist(subsidenceFileNameAndPath, 'file')
        data.inputSubsidPDF = load(subsidenceFileNameAndPath);
    else
        messageStr = sprintf('Subsidence PDF data file %s does not exist. Please ensure the named file is in the controlPDFs folder and try again\n', subsidenceFileNameAndPath);
        msgbox(messageStr);
        success = 0;
        return;
    end
    data.lenSubsidPDF = length(data.inputSubsidPDF);
    data.subsidRange = data.inputSubsidPDF(:,1);
    data.subsidPDF = definePDF(data.inputSubsidPDF, const.LENPDF); % Function to convert the PDF into the correct required format
    data.subsidValuesCount = length(data.subsidRange);
    data.subsidIncrement = data.subsidRange(2) - data.subsidRange(1); % Assumes that bin spacing is constant through PDF
    data.subsidMin = data.subsidRange(1); % - subsidIncrement;
    data.subsidMax = data.subsidRange(data.subsidValuesCount); 
    
    % Read in the supply PDF file and calculate useful values from the PDF to be used in the rest of the code
    if exist(supplyFileNameAndPath, 'file')
        data.inputSupplyPDF = load(supplyFileNameAndPath);
    else
        messageStr = sprintf('Sediment supply PDF data file %s does not exist. Please ensure the named file is in the controlPDFs folder and try again\n', supplyFileNameAndPath);
        msgbox(messageStr);
        success = 0;
        return;
    end
    data.lenSupplyPDF = length(data.inputSupplyPDF);
    data.supplyRange = data.inputSupplyPDF(:,1);
    data.supplyPDF = definePDF(data.inputSupplyPDF, const.LENPDF); % Function to convert the PDF into the correct required format
    data.supplyValuesCount = length(data.supplyRange);
    data.supplyIncrement = data.supplyRange(2) - data.supplyRange(1); % Assumes that bin spacing is constant through PDF
    data.supplyMin = data.supplyRange(1); % - subsidIncrement;
    data.supplyMax = data.supplyRange(data.supplyValuesCount); 
    
    % Read in the eustasy PDF file and calculate useful values from the PDF to be used in the rest of the code
    if exist(eustasyFileNameAndPath, 'file')
        % Read section data, thickness and facies
        data.inputEustasyPDF = load(eustasyFileNameAndPath);
    else
        messageStr = sprintf('Eustasy PDF data file %s does not exist. Please ensure the named file is in the controlPDFs folder and try again\n', eustasyFileNameAndPath);
        msgbox(messageStr);
        success = 0;
        return;
    end
    data.lenEustasyPDF = length(data.inputEustasyPDF);
    data.eustasyRange = data.inputEustasyPDF(:,1);
    data.eustasyPDF = definePDF(data.inputEustasyPDF, const.LENPDF); % Function to convert the PDF into the correct required format
    data.eustasyValuesCount = length(data.eustasyRange); %data.eustasyValuesCount
    data.eustasyIncrement = data.eustasyRange(2) - data.eustasyRange(1); % Assumes that bin spacing is constant through PDF
    data.eustasyMin = data.eustasyRange(1); % - eustasyIncrement;
    data.eustasyMax = data.eustasyRange(data.eustasyValuesCount);
end

function finalPDF = definePDF(dataPDF, standardLenPDF)
% Convert the input PDF into the correct format for this code. Needs to be an array of length 1000 with number of elements with each value from the PDF proportional to the specified probability
% This PDF is then sampled in the Monte Carlo bootstrapping method
     
    finalPDF = zeros(1, standardLenPDF);
    dataPDFLength = length(dataPDF);
    i = 1; % Index to loop through the PDFdata array
    j = 1; % Index to loop through the final PDF array. 
    start = round(j);
    
    while i <= dataPDFLength
        p = dataPDF(i,2); % p is probability of control having amplitude dataPDF(i,1)
        range = round(standardLenPDF * p); % number of elemtns of this amplitude in the array proportional to p
        if range > 0 
            for j = start:start+range; % note range - 1 because start+range so need the -1
                finalPDF(j) = dataPDF(i,1);
            end
            start = j+1; % start next range in next array element
        end
        i = i+1;
    end
end

%%   First plot the PDF for each variable
function gui = plotControlPDFs(gui, const, data)

    figure(gui.main);
   
    gui.s1 = subplot('Position', [0.05 0.70 0.6 0.25]);
    axisPos = data.subsidMin:data.subsidIncrement:data.subsidMax;
    h2 = bar(axisPos,data.inputSubsidPDF(:,2));
    xlabel('Rate of subsidence (m per 100ky)');
    ylabel('Relative frequency');
    grid on;
    grid minor;
    
    gui.s2 = subplot('Position', [0.05 0.37 0.6 0.25]);
    % NB x-axis labelling for supply PDF complicated because log scale needed, so increments irregular, so just number series dont label values
    axisPos = 1:length(data.inputSupplyPDF(:,2));  % So axis is effectively unlabeled - add labels in drawing package
    h3 = bar(axisPos, data.inputSupplyPDF(:,2));
    xlabel('Rate of sediment supply (m3 per 100ky)');
    set(gca,'TickDir', 'out', 'XTickLabelRotation',90);
    ylabel('Relative frequency');
    grid on;
    grid minor;
    
    gui.s3 = subplot('Position', [0.05 0.05 0.6 0.25]);
    axisPos = data.eustasyMin:data.eustasyIncrement:data.eustasyMax;
    h1 = bar(axisPos,data.inputEustasyPDF(:,2));
    xlabel('Rate of eustatic change (m per 100ky)');
    ylabel('Relative frequency');
    grid on;
    grid minor;
end

function [data, success] = loadTrajectoryData(const, data, trajectoryDataFileNameAndPath)

    success = 1;
     % Read in the control volume trajectory data file 
     % Check first that the named file exists and if it does not, exit with flag set to failure
    if exist(trajectoryDataFileNameAndPath, 'file') == 0
        fprintf('Stratal control volume trajectory data file %s does not exist. Please ensure the named file is in the controlPDFs folde and try again\n', trajectoryDataFileNameAndPath);
        success = 0;
        return;
    end
    
    trajFileIn = fopen(trajectoryDataFileNameAndPath);
    data.numberOfTrajectories = fscanf(trajFileIn,'%d', 1); % Read the first value from the file, should be the number of trajectories
    dummyLabel = fgetl(trajFileIn); % Read to the end of the line to skip any label text
    data.lenControlTraj = zeros(1, 3);
    
    for j = 1:data.numberOfTrajectories
        tempInput = fscanf(trajFileIn,'%d', 1); % read the dimensions paramater for trajectory j
        dummyLabel = fgetl(trajFileIn); % Read to the end of the line to skip any label text
        data.trajectoryDimensions(j) = tempInput;
        
        tempInput = fscanf(trajFileIn,'%f%f%f', 3);
        dummyLabel = fgetl(trajFileIn); % Read to the end of the line to skip any label text
        data.trajectoryColours(j,1:3) = tempInput;
        
        tempInput = fscanf(trajFileIn,'%d', 1); % read the number of data points for trajectory j
        dummyLabel = fgetl(trajFileIn); % Read to the end of the line to skip any label text
        lenControlTraj(j) = tempInput;
        readBlockSize = [3 lenControlTraj(j)];
        inputOneTrajData = fscanf(trajFileIn,'%f%f%f', readBlockSize); % read the data block according to the number of data points
        
        data.subsidTraj(j,1:lenControlTraj(j)) = inputOneTrajData(1, 1:lenControlTraj(j));
        data.supplyTraj(j,1:lenControlTraj(j)) = inputOneTrajData(2, 1:lenControlTraj(j));
        data.eustasyTraj(j,1:lenControlTraj(j)) = inputOneTrajData(3, 1:lenControlTraj(j));
    end
    
    if const.VERBOSE
    fprintf('Read %d trajectories, properties as follows:\n',data.numberOfTrajectories);
%     for j = 1:data.numberOfTrajectories
%         fprintf('Trajectory %d Subsidence min:%5.4f max%5.4f Supply min:%5.4f max%5.4f Eustasy min:%5.4f max%5.4f\n',...
%             min(subsidTraj(j,1:lenControlTraj(j))), max(subsidTraj(j,1:lenControlTraj(j))), ...
%             min(supplyTraj(j,1:lenControlTraj(j))), max(supplyTraj(j,1:lenControlTraj(j))), ...
%             min(eustasyTraj(j,1:lenControlTraj(j))), max(eustasyTraj(j,1:lenControlTraj(j))) );
%       end
     end
end

function volPlotVars = calculate3DControlVolume(const, data, volPlotVars)

    eustasyVals = zeros(1,const.N); % These arrays will contain the PDFs in the final form to be used, different from what is input
    subsidVals = zeros(1,const.N);
    supplyVals = zeros(1,const.N);
    volPlotVars.stratalControlVolumeN = data.lenEustasyPDF * data.lenSubsidPDF * data.lenSupplyPDF; % Number of points in the defined stratal control volume
    volPlotVars.stratalControlVolume = zeros(data.lenEustasyPDF, data.lenSubsidPDF, data.lenSupplyPDF); % The solution set volume array will contain the relative frequency at each defined point in the solution set space
    volPlotVars.RSLRiseVolume = zeros(data.lenEustasyPDF, data.lenSubsidPDF, data.lenSupplyPDF); % boolean flag indicating whether position in control volume is an RSL rise (TRUE,1) or RSL fall (FALSE, 0), or, possibly RSL constant (FALSE, 0)
    volPlotVars.progStacking3DVolume = zeros(data.lenEustasyPDF, data.lenSubsidPDF, data.lenSupplyPDF); % boolean flag TRUE if position in control volume has enough supply for progradation
    volPlotVars.progUnforced3DVolume = zeros(data.lenEustasyPDF, data.lenSubsidPDF, data.lenSupplyPDF); % boolean flag TRUE is position in control volume is rising RSL and supply > accommodation
    
    volPlotVars.RSLMax = data.eustasyMax + data.subsidMax;
    volPlotVars.RSLMin = data.eustasyMin + data.subsidMin;
    volPlotVars.RSLRange = volPlotVars.RSLMax - volPlotVars.RSLMin;
    volPlotVars.RSLIncrement = volPlotVars.RSLRange / 20.0;
    
    % Monte-carlo or bootstrapping loop to sample the eustasy, subsidence and supply PDFs and for each value of eustasy, subsidence and supply sampled, 
    % increment the frequency at the appropriate point in the solution set volume
    j = 1;
    maxn1 = 0;
    maxn2 = 0;
    while j <= const.N

        n = rand * const.LENPDF; % Rand range 0-1 but n is array subscript so make sure n >=1 by looping until it is
        while n < 1 
            n = rand * const.LENPDF;
        end
        data.eustasyVals(j) = data.eustasyPDF(n); % Sample a value from the input PDF and put it at element j in the eustasyVals array
        if n > maxn1 maxn1=n;end
        
        n = rand * const.LENPDF;
        while n < 1 
            n = rand * const.LENPDF;
        end
        data.subsidVals(j) = data.subsidPDF(n);
        if n > maxn2 maxn2=n;end
        
        n = rand * const.LENPDF;
        while n < 1 
            n = rand * const.LENPDF;
        end
        data.supplyVals(j) = data.supplyPDF(n);
        
        % Need to generate an index value for each of the three axes to access the correct cell in the control volume for the values of eustasy, subsidence and supply selected
        % Will then increment the frequency count at this x,y,z element in the stratalControlVolume array
        k=1;
        while k < length(data.eustasyRange) && data.eustasyVals(j) > data.eustasyRange(k) % This could probably simplied to just a division of the value by the increment, but this method more flexible if increment varies
            k=k+1;
        end
        eustasyIndex = k;
        
        k=1;
        while k < length(data.subsidRange) && data.subsidVals(j) > data.subsidRange(k) 
            k=k+1;
        end
        subsidIndex = k;
        
        k=1;
        while k < length(data.supplyRange) && data.supplyVals(j) > data.supplyRange(k) 
            k=k+1;
        end
        supplyIndex = k;
        
        volPlotVars.stratalControlVolume(eustasyIndex, subsidIndex, supplyIndex) = volPlotVars.stratalControlVolume(eustasyIndex, subsidIndex, supplyIndex) + 1; % increment the frequency at the appropriate cell in the solutions space
        
        j = j + 1;
    end
    
    % Find the minimum, mean and maximum frequency values in the control volume
    volPlotVars.minControlVolFreq = min(min(min(volPlotVars.stratalControlVolume)));
    volPlotVars.meanControlVolFreq = mean(mean(mean(volPlotVars.stratalControlVolume)));
    volPlotVars.maxControlVolFreq = max(max(max(volPlotVars.stratalControlVolume)));
  
    % Convert solution set volume to relative frequency by dividing by the total number of bootstrap iterations which is therefore the maximum possible frequency if all values were at one point in the control volume
    volPlotVars.stratalControlVolume = volPlotVars.stratalControlVolume / double(const.N);
    
    % Find the minimum, mean and maximum relative frequency values in the control volume
    volPlotVars.minControlVolRelativeFreq = min(min(min(volPlotVars.stratalControlVolume)));
    volPlotVars.meanControlVolRelativeFreq = mean(mean(mean(volPlotVars.stratalControlVolume)));
    volPlotVars.maxControlVolRelativeFreq = max(max(max(volPlotVars.stratalControlVolume)));
    
    nonZeroElementCount = length(nonzeros(volPlotVars.stratalControlVolume));
    stratControlVolSize = size(volPlotVars.stratalControlVolume);

    if const.VERBOSE
        fprintf('%d samples taken from supply, subsidence and eustasy PDFs to create solution set frequency volume with %d recorded points\n',j-1, volPlotVars.stratalControlVolumeN);
        fprintf('Dimensions of volume in grid cells are x:%d y:%d z:%d\n', stratControlVolSize(1), stratControlVolSize(2), stratControlVolSize(3));
        fprintf('Subsidence range has %d values from min:%d to max:%d giving grid cell increment %d\n', data.subsidValuesCount, data.subsidMin, data.subsidMax, data.subsidIncrement);
        fprintf('Supply range has %d values from min:%3.2e to max:%3.2e giving grid cell increment %3.2e\n', data.supplyValuesCount, data.supplyMin, data.supplyMax, data.supplyIncrement);
        fprintf('Eustasy range has %d values from min:%d to max:%d giving grid cell increment %d\n', data.eustasyValuesCount, data.eustasyMin, data.eustasyMax, data.eustasyIncrement);
        fprintf('3D solution set volume frequency per bin: min %5.4f mean %5.4f max %5.4f\n', volPlotVars.minControlVolFreq, volPlotVars.meanControlVolFreq, volPlotVars.maxControlVolFreq);
        fprintf('3D solution set volume relative frequency per bin: min %5.4f mean %5.4f max %5.4f values >0 in %d cells\n', ...
            volPlotVars.minControlVolRelativeFreq, volPlotVars.meanControlVolRelativeFreq, volPlotVars.maxControlVolRelativeFreq, nonZeroElementCount);
    end
    
     % Loop through the stratal control volume and calculate RSL and stacking pattern that each cell represents
     % Mark each cell as either RSL rising (True) or falling (False), progradation stacking where supply>rate of accommodation creation (TRUE) or supply< rate of accommodation creation (FALSE)
     % and unforced progradation where supply>accomm but RSL is rising so accomm is being created
     for x=1:data.eustasyValuesCount
        for y = 1:data.subsidValuesCount
            
            % Note that -eustasy is falling, so also -RSL, and -subsidence is uplift, so also falling RSL, therefore eusasy + subsidence is always correct -100 eustasy + -50 subsidence (which is
            % uplift) gives -150 RSL, so bigger RSL fall than just eustatic fall
            RSLVal = (data.eustasyMin + ((x-1) * data.eustasyIncrement)) + (data.subsidMin + ((y-1) * data.subsidIncrement));

            for z = 1:data.supplyValuesCount
                
                % Need to put this in the z loop because although supply is independent of RSL we want to able to count all the control volume values across the range of supply values
                if RSLVal >= 0 % Rate of change >= 0 means rising RSL
                    RSLRiseVolume(x, y, z) = 1;
                end

                supply1D = data.supplyRange(z) / data.supplyReferenceArea; % Divide supply volume by area of Holocene Mississippi delta deposition to convert supply to 1D thickness rate
                  
                if supply1D > RSLVal % rate of supply exceeds rate of accommodation creation
                    progStacking3DVolume(x,y,z) = 1; % Set progStackVolume in cell x y z to true
                    if RSLVal > 0 % rate of accommodation creation is positive, and from previous if less than rate of supply, so this must be unforced regression
                        progUnforced3DVolume(x,y,z) = 1; % Set unforced regression record in cell x y z to true  
                    end
                end
            end
        end
     end
     
     
     % These volume arrays are copies to the 3D control volume matrix but currently contain ones or zeros to code RSL rise etc - see above
     % Calculate what proportion of the total solution set volume each class of cell represents
     progStackProportion3D = sum(sum(sum(progStacking3DVolume))) / double(volPlotVars.stratalControlVolumeN);
     RSLRiseProportion3D = sum(sum(sum(RSLRiseVolume))) / double(volPlotVars.stratalControlVolumeN);
   
     % Now use the same volume arrays to calculate the probabiity of sample data that occurs in the various fields e.g. what probability of timeseries sample data being in the falling RSL field?
     RSLRiseProbability3D = RSLRiseVolume .* volPlotVars.stratalControlVolume; % NB element-by-element multiplication operator .*
     RSLRiseProbability3D = sum(sum(sum(RSLRiseProbability3D)));
     progStackProbability3D = progStacking3DVolume .* volPlotVars.stratalControlVolume;
     progStackProbability3D = sum(sum(sum(progStackProbability3D)));
     progUnforcedProbability3D = progUnforced3DVolume .* volPlotVars.stratalControlVolume;
     progUnforcedProbability3D = sum(sum(sum(progUnforcedProbability3D))) / RSLRiseProbability3D; % because we need the probability only within the rising RSL volume
   
     if const.VERBOSE
         fprintf('3D stratigraphic control volume proportions:\n');
         fprintf('%5.4f of stratigraphic control volume is RSL rise, so %5.4f of volume is RSL fall\n', RSLRiseProportion3D, 1.0-RSLRiseProportion3D);
         fprintf('%5.4f of stratigraphic control volume is progradation (supply > accommodation), so %5.4f of volume is retrogradation (supply < accommodation)\n', progStackProportion3D, 1.0-progStackProportion3D);
         
         fprintf('3D solution volume outcome probabilities:\n');
         fprintf('Probability of RSL fall and forced regression %5.4f\nProbability of RSL rise %5.4f\n',  1-RSLRiseProbability3D, RSLRiseProbability3D);
         fprintf('Probability of progradational %5.4f\nProbabiity of retrogradational %5.4f\n',  progStackProbability3D, 1-progStackProbability3D);
         fprintf('When RSL rise, probability of unforced regression %5.4f\nWhen RSL rise, probability of transgression %5.4f\n', progUnforcedProbability3D, 1-progUnforcedProbability3D);
     end
end

function gui = plot3DControlVolume(gui, data, volPlotVars)
    
    gui.f1 = figure('Visible','on','Position',[1 100 (gui.scrsz(3)/2) (gui.scrsz(4)/1.3)]);
    gui.ax1 = gca;
    set(gui.ax1,'ZScale','log');
 
     % Draw a grid of bin boundaries on the basal plane of the solution parameter space colour coded by the magnitude of RSL change for the cell
     for x=1:data.eustasyValuesCount
        for y = 1:data.subsidValuesCount
              xcoCorner = data.eustasyMin + ((x-1) * data.eustasyIncrement);
              ycoCorner = data.subsidMin + ((y-1) * data.subsidIncrement);
              xco = [xcoCorner xcoCorner xcoCorner+data.eustasyIncrement xcoCorner+data.eustasyIncrement];
              yco = [ycoCorner ycoCorner+data.subsidIncrement ycoCorner+data.subsidIncrement ycoCorner];
              zco = [data.supplyMin data.supplyMin data.supplyMin data.supplyMin];
              RSL = (data.eustasyMin + ((x-1) * data.eustasyIncrement)) + (data.subsidMin + ((y-1) * data.subsidIncrement));
              
              patch(xco, yco, zco, [(volPlotVars.RSLMax - RSL) / volPlotVars.RSLRange 0 (RSL - volPlotVars.RSLMin) / volPlotVars.RSLRange]);
        end
     end
      
     % Now plot the frequency values as a cuboid in each bin, scaled and coloured according to relative frequency
     % Do this before further plotting because it's a useful way to set the appropriate limits of the plot to guide how planar surfaces are then drawn into the volume
     for x=1:data.eustasyValuesCount
         for y = 1:data.subsidValuesCount 
             for z = 1:data.supplyValuesCount-1
                 if volPlotVars.stratalControlVolume(x,y,z) > 0
                     
                    scaleFactor = volPlotVars.stratalControlVolume(x,y,z) / volPlotVars.maxControlVolRelativeFreq; % Scale relative freq in each cell by maximum relative frequency, otherwise will plot too small
                    if scaleFactor > 0.01    
                           plotCuboid(x,y,z, data.eustasyMin, data.eustasyIncrement, data.subsidMin, data.subsidIncrement, data.supplyRange(z), data.supplyRange(z+1)-data.supplyRange(z), scaleFactor);
                     end
                 end
                 supplyZco = data.supplyRange(z+1) - data.supplyRange(z);
             end
         end
     end
     
      %% Subdivide the volume according to progradation, retrogradation, RSL fall-rise etc
     
     % Force the plot line from lowest to highest values
     g1 = line([data.eustasyMin data.eustasyMax],  [data.subsidMin data.subsidMax], [data.supplyMin data.supplyMax]);
     g1.LineStyle = 'none'; % Want line to define axis limits but dont want it to be actually drawn and visible
     
      % Make a planar surface that runs along the RSL = 0 plane in the volume
      % Loop through the eustasy values at min and max subsidence rates to find the values where RSL ~ 0
      % Draw a vertical planar surface here to partition rising and falling RSL
      y1 = data.subsidMin;
      y2 = data.subsidMax;
      for x=data.eustasyMin:data.eustasyMax
          RSL1 = x + y1;
          RSL2 = x + y2;
          if RSL1 > -1 && RSL1 < 1
                xco1 = x;
                yco1 = y1;
          end
          if RSL2 > -1 && RSL2 < 1
                xco2 = x;
                yco2 = y2;
          end
      end
      zcoLimits = get(gca,'ZLim');
      patch([xco1 xco1 xco2 xco2], [yco1 yco1 yco2 yco2], [zcoLimits(1) zcoLimits(2) zcoLimits(2) zcoLimits(1)], [0.9 0.9 0.9], 'FaceAlpha',0.50,'EdgeAlpha',0.50);

      % Make a planar surface that runs along the plane where rate of supply adjusted to a Holocene Mississippi area thickness value
      % matches the rate of potential accommodation creation following Mutti & Steel definition
      j1=1;
      j2=1;
      y1 = data.subsidMin;
      y2 = data.subsidMax;
      for x=data.eustasyMin:data.eustasyMax
          
              RSL1 = x + y1; % Rate of RSL change is eustasy x + subsidence y1 or y2
              RSL2 = x + y2;
              for z=zcoLimits(1):data.supplyIncrement:data.supplyMax
                  supply1D = z / data.supplyReferenceArea; % Divide supply volume by area of Holocene Mississippi delta deposition to convert supply to 1D thickness rate
                  
                  if abs(RSL1 - supply1D) < 1.0 % rate of supply equal to rate of accommodation creation with error threshold 1.0
                      xco1(j1)= x;
                      yco1(j1) = y1;
                      zco1(j1) = z;
                      j1=j1+1;
                  end
                  
                  if abs(RSL2 - supply1D) < 1.0 % rate of supply equal to rate of accommodation creation with error threshold 1.0
                      xco2(j2)= x;
                      yco2(j2) = y2;
                      zco2(j2) = z;
                      j2=j2+1;
                  end
              end
      end
  
      xco = cat(2, xco1, fliplr(xco2));
      yco = cat(2, yco1, fliplr(yco2));
      zco = cat(2, zco1, fliplr(zco2));
      patch(xco, yco, zco, [0.9 0.9 0.9], 'FaceAlpha',0.50,'EdgeAlpha',0.50);
     
     % Draw zero value lines
     xco = [0 0 0 0];
     yco = [data.subsidMin data.subsidMin data.subsidMax data.subsidMax];
     zco = [data.supplyMin data.supplyMin data.supplyMin data.supplyMin];
     line(xco, yco, zco, 'LineWidth',1);
     xco = [data.eustasyMin data.eustasyMin data.eustasyMax data.eustasyMax];
     yco = [0 0 0 0];
     line(xco, yco, zco, 'LineWidth',1);
     
     % Draw zero value lines on basal plane
     xco = [0 0 0 0];
     yco = [data.subsidMin data.subsidMin data.subsidMax data.subsidMax];
     zco = [0 0 0 0];
     line(xco, yco, zco, 'LineWidth',1);
     xco = [data.eustasyMin data.eustasyMin data.eustasyMax data.eustasyMax];
     yco = [0 0 0 0];
     line(xco, yco, zco, 'LineWidth',1);
     
     % Draw vertical line up through the center of the parameter space
     xco = [0 0 0 0];
     yco = [0 0 0 0];
     zco = [data.supplyMin data.supplyMin data.supplyMax+data.supplyIncrement data.supplyMax+data.supplyIncrement];
     line(xco, yco, zco);
    
     grid on;
     grid minor;
     view(70,15);
     
     xlabel('Rate of eustatic change (m per 100ky)');
     ylabel('Rate of subsidence (m per 100ky)');
     zlabel('Rate of sediment supply (m3 per 100ky)');
     
%    Create a high-resultion 600dpi transparent background png file for this figure using export_fig which is an .m file in the Matlab folder  
%   Usually commented out because it is slow and not necessary to do everytime code is run
%         export_fig ../figures/f2_3dSolutionVolume.png -r600 -transparent
     
end

function volPlotVars = plot3DControlTrajectories(gui, const, data, volPlotVars)
 %% Find the probability values along the 3D volume trajectories and draw the trajectories
     
   fprintf('\n3D solution volume trajectory probabilities:\n');
     
   figure(gui.f1);  % Activate the stratal control volume figure since this is where we want to plot these 3D trajectories
    
   volPlotVars.sVolPValsTraj = zeros(1,1);
   trajPVectors = cell(data.numberOfTrajectories,1); % trajPVectors is a cell array, each cell element will contain a different length vector of doubles that is the p values along the trajectory
   
     for j = 1:data.numberOfTrajectories
         
         if data.trajectoryDimensions(j) == 3 % only plot those trajectories tagged in the input file as 3D
%              trajN = length(data.subsidTraj(j, :)); % Set variables to the length of each of the two input control volume trajectories
            trajN = nnz(data.subsidTraj(j, :)); % Set variables to the number of non-zero elements in trajectory j
            

             % Copy into a convenient data structures to use in the trajectory probability calculation
             traj.eustasy = data.eustasyTraj(j, :)
             traj.subsid = data.subsidTraj(j, :)
             traj.supply = data.supplyTraj(j, :)
             
             % Find the probabilites for trajectory j and at the same time, record interpolation between trajectory points as x,y,z coordinates to plot
             [trajPVectors{j}, accommTrajXco, accommTrajYco, accommTrajZco] = find3DsolutionVolumeTrajectoryProbabilities(data, traj, volPlotVars.stratalControlVolume, trajN, 'Trajectory');
             
             % Plot trajectory j
             line(accommTrajXco, accommTrajYco, accommTrajZco, 'Color', data.trajectoryColours(j,1:3), 'LineWidth', 5.0);
             line(accommTrajXco(1:1), accommTrajYco(1:1), accommTrajZco(1:1), 'LineStyle','none','Marker','o','MarkerSize',12, 'Color', data.trajectoryColours(j,1:3)); % lines needs at least 2 coord points? but make them the same to plot single market symbol at start and end of the line
             line(accommTrajXco(trajN:trajN), accommTrajYco(trajN:trajN), accommTrajZco(trajN:trajN), 'LineStyle','none','Marker','x','MarkerSize',12, 'Color', data.trajectoryColours(j,1:3));
         end
     end
     
     trajLengths = cellfun('length',trajPVectors); % Put the trajectory lengths into the trajLengths vector
     maxTrajLength = max(trajLengths); % Find the maximum trajectory length
     for j = 1:data.numberOfTrajectories
        trajPVectors{j}(trajLengths(j)+1:maxTrajLength) = 0; % Pad each trajectory to the maximum length
     end
     volPlotVars.sVolPValsTraj = cell2mat(trajPVectors); % Copy the P value trajectories into a matrix in the volPlotVars structure to pass back to calling function
end

function [sVolPValsTrajFinal, xco, yco, zco] = find3DsolutionVolumeTrajectoryProbabilities(data, traj, stratalControlVolume, lenTrajectory, label)
% Find the probabilites along a control volume trajectory, using interpolation
% Code calculates the unit step length then for each section of the trajectory but then checks to remove adjacent duplicate cells 
% that may occur if the interpolation step is small

     sVolTrajCoords = zeros(1, 5000);  % Length of this is unknown at this point because number of points depends on interpolation, so preallocate a large number
     preservePoint = zeros(1, 5000);
     sVolPValsTraj = zeros(1, lenTrajectory);
     sVolPValsTrajFinal = zeros(1, lenTrajectory);
     ptsPerCell = 500;
     trajPos = 1; % Records position in the sVolPValsTraj array as it is filled in the code below
     
     if lenTrajectory < 2
        fprintf('Stratal control trajectory too short to process and draw.\n');
        return;
     end
     
     % loop through all the points in the trajectory, -1 because need to use a j+1 in the calculations
     for j = 1:lenTrajectory-1

        % Calculate the x,y, and z increments in the j to j+1 steps in the trajectory assuming 10 interpolation steps per trajectory line segment
        trajDeltaX = (traj.eustasy(j+1) - traj.eustasy(j)) / ptsPerCell;
        trajDeltaY = (traj.subsid(j+1) - traj.subsid(j)) / ptsPerCell;
        trajDeltaZ = (traj.supply(j+1) - traj.supply(j)) / ptsPerCell;
        trajPointsSeparation = (sqrt((trajDeltaX * trajDeltaX) + (trajDeltaY * trajDeltaY) + (trajDeltaZ + trajDeltaZ))); % May be negative so nb abs in while condition below
        trajStepLength = trajPointsSeparation / ptsPerCell;
          
        xco(trajPos) = traj.eustasy(j);
        yco(trajPos) = traj.subsid(j);
        zco(trajPos) = traj.supply(j);
        dist = 0;
        oneSegmentCount = 0;
        
%         fprintf('Trajectory point %d from %1.0f %1.0f %5.4e to %1.0f %1.0f %5.4e\n', j, traj.eustasy(j), traj.subsid(j), traj.supply(j), traj.eustasy(j+1), traj.subsid(j+1), traj.supply(j+1))
        
        while abs(dist) < abs(trajPointsSeparation) && oneSegmentCount < ptsPerCell % Two checks, dist to catch bad interpolation and oneSegmentCount to mitigate rounding errors on dist
            
            % Calculate the x y z matrix coordinates needed to get a probability out of the control volume
            x(trajPos) = round((xco(trajPos) - data.eustasyMin) / data.eustasyIncrement) + 1; % +1 because PDF bins range upwards, so +1 ensures cell selection honours this
            y(trajPos) = round((yco(trajPos) - data.subsidMin) / data.subsidIncrement) + 1;
            z(trajPos) = findSupplyTrajIndex(zco(trajPos), data.supplyRange);
            
            % Check if the coords are within the control volume limits and if so, retrieve probability, store probability & increment counts
            if x(trajPos) > 0 && x(trajPos) <= data.eustasyValuesCount && y(trajPos) > 0 && y(trajPos) <= data.subsidValuesCount && z(trajPos) > 0 && z(trajPos) <= data.supplyValuesCount
                sVolPValsTraj(trajPos) = stratalControlVolume(x(trajPos),y(trajPos),z(trajPos));
            else
%               fprintf('Trajectory error - x=%1.0f (%d) y=%1.0f (%d) z=%5.4e (%d) out of control volume range at point %d in trajectory called %s\n',xco, x(trajPos),yco, y(trajPos),zco, z(trajPos),j, label);
                sVolPValsTraj(trajPos) = 0.0; % Outside the control volume so probability must be zero
            end
            
            % Add the interpolation increments to the control values and record increase in distance interpolated along line segment
            xco(trajPos+1) = xco(trajPos) + trajDeltaX;
            yco(trajPos+1) = yco(trajPos) + trajDeltaY;
            zco(trajPos+1) = zco(trajPos) + trajDeltaZ;
            trajPos = trajPos + 1; 
           
            dist = dist + trajStepLength;
            oneSegmentCount = oneSegmentCount + 1;
            
            if oneSegmentCount >= ptsPerCell % If the oneSegmentCount increment indicates the end of trajectory line segment...
                preservePoint(trajPos) = 1; % Set the flag to force point to be copied into final interpolated coordinates, even if it is a replicate
            else
                preservePoint(trajPos) = 0; % otherwise set the flat to zero and treat like any other point
            end
%             fprintf('Interpolation %1.0f %1.0f %5.4e\n', xco(trajPos), yco(trajPos), zco(trajPos));
        end
     end
     
     % Interpolation routine may have recorded the same cell from the stratal control volume consecutviely more than once, especially if the interpolation step was small
     % So need to find adjacent duplicates and remove them, and also count the nonzero values in the interpolated trajectory
     % Note that if the trajectory repeats the same coord cells, this is fine, so long as they are not adjacent in the trajectory
     k = 1;
     nonZeroPathCount = 0;
     for j=2:trajPos-1;
         if ~(x(j) == x(j-1) && y(j) == y(j-1) && z(j) == z(j-1)) || preservePoint(j) ==1 % If the j & j-1 x,y,zcoords are not equal point j on trajectory is not a duplicate of point j-1
            sVolPValsTrajFinal(k) = sVolPValsTraj(j);      
            if sVolPValsTrajFinal(k) > 0 
                nonZeroPathCount = nonZeroPathCount + 1; 
            end
            k=k+1;
          end
     end
     
    fprintf('%s trajectory %d points long interpolated to give total length %d points, %d points have p>0, mean p %6.5f\n', label, lenTrajectory, k, nonZeroPathCount, mean(sVolPValsTrajFinal));
end

function areaPlotVars = calculate2DControlArea(const, data, volPlotVars, areaPlotVars)

     areaPlotVars.RSLMax = data.eustasyMax + data.subsidMax;
     areaPlotVars.RSLMin = data.eustasyMin + data.subsidMin;
     areaPlotVars.RSLRange = areaPlotVars.RSLMax - areaPlotVars.RSLMin;
     areaPlotVars.RSLIncrement = areaPlotVars.RSLRange / 20.0;
     areaPlotVars.RSLValuesCount = areaPlotVars.RSLRange / areaPlotVars.RSLIncrement;
    
         % Create the 2D matrix for the supply-RSL control volume initially as a 1D vector because RSL axis size is not know apriori - will be redimensioned repeatedly in the loop below  
     lenRSLRateOfChange = 2 + ((areaPlotVars.RSLMax - areaPlotVars.RSLMin) / areaPlotVars.RSLIncrement);
    
     areaPlotVars.stratalControlArea = zeros(lenRSLRateOfChange,data.lenSupplyPDF);
     
     RSLRiseArea = zeros(lenRSLRateOfChange,data.supplyValuesCount);
     progStacking2DVolume = zeros(lenRSLRateOfChange,data.supplyValuesCount);
     progUnforced2DVolume = zeros(lenRSLRateOfChange,data.supplyValuesCount);
     
     % Make a 2D version of the probabilistic control volume with RSL and supply on the axes
     % NB SolutionSetVolume is already relative frequency so should just be able to add values at appropriate eustasy and subsidence points to collapse 3D to 2D without any scaling...
     for x=1:data.eustasyValuesCount
        for y = 1:data.subsidValuesCount
            
            RSLVal = (data.eustasyMin + ((x-1) * data.eustasyIncrement)) + (data.subsidMin + ((y-1) * data.subsidIncrement));
            xIndex =  1 + int16((RSLVal - areaPlotVars.RSLMin) / areaPlotVars.RSLIncrement); % the RSL plot x axis value
            
            if RSLVal > 0 % Mark part of the area with rising RSL
                RSLRiseArea(xIndex,:) = 1;
            end
            
            for z = 1:data.supplyValuesCount

                % Need to put this in the z loop because although supply is independent of RSL we want to able to count all the control volume frequency values across the range of supply values
                areaPlotVars.stratalControlArea(xIndex,z) = areaPlotVars.stratalControlArea(xIndex,z) + volPlotVars.stratalControlVolume(x,y,z);
                
                supply1D = (data.supplyMin + ((z-1) * data.supplyIncrement)) / data.supplyReferenceArea; % Divide supply volume by area of Holocene Mississippi delta deposition to convert supply to 1D thickness rate
                  
                if supply1D > RSLVal % rate of supply exceeds rate of accommodation creation
                    progStacking2DVolume(xIndex,z) = 1; % Set progStackVolume in cell x y z to true
                    if RSLVal > 0 % rate of accommodation creation is positive, and from previous if less than rate of supply, so this must be unforced regression
                        progUnforced2DVolume(xIndex, z) = 1; % Set unforced regression record in cell x y z to true  
                    end
                end
            end
        end
     end
     
    % Find the minimum, mean and maximum frequency values in the control volume
    minSolSetAreaFreq = min(min(min(areaPlotVars.stratalControlArea)));
    meanSolSetAreaFreq = mean(mean(mean(areaPlotVars.stratalControlArea)));
    maxSolSetAreaFreq = max(max(max(areaPlotVars.stratalControlArea)));
    
    % Find the minimum, mean and maximum relative frequency values in the control volume
    minSolSetAreaRelativeFreq = min(min(min(areaPlotVars.stratalControlArea)));
    meanSolSetAreaRelativeFreq = mean(mean(mean(areaPlotVars.stratalControlArea)));
    maxSolSetAreaRelativeFreq = max(max(max(areaPlotVars.stratalControlArea)));
    
    nonZeroSolSetAreaElementCount = length(nonzeros(areaPlotVars.stratalControlArea));
    
    if const.VERBOSE
        fprintf('\n2D solution set area frequency per bin: min %5.4f mean %5.4f max %5.4f\n', minSolSetAreaFreq, meanSolSetAreaFreq, maxSolSetAreaFreq);
        fprintf('2D solution set area relative frequency per bin: min %5.4f mean %5.4f max %5.4f values >0 in %d cells\n',  minSolSetAreaRelativeFreq, meanSolSetAreaRelativeFreq, maxSolSetAreaRelativeFreq, nonZeroSolSetAreaElementCount);
    end
     
     % These area arrays are copies to the 2D control volume matrix but currently contain ones or zeros to code RSL rise etc - see above
     % Calculate what proportion of the total solution set volume each class of cell represents
     progStackProportion2D = sum(sum(progStacking2DVolume)) / double(lenRSLRateOfChange*data.supplyValuesCount);
     RSLRiseProportion2D = sum(sum(RSLRiseArea)) / double(lenRSLRateOfChange*data.supplyValuesCount);
     
    % Now use the same volume arrays to calculate the probabiity of sample data that occurs in the various fields e.g. what probability of timeseries sample data being in the falling RSL field?
     RSLRiseProbability2D = RSLRiseArea .* areaPlotVars.stratalControlArea; % NB element-by-element multiplication operator .*
     RSLRiseProbability2D = sum(sum(sum(RSLRiseProbability2D)));
     progStackProbability2D = progStacking2DVolume .* areaPlotVars.stratalControlArea;
     progStackProbability2D = sum(sum(sum(progStackProbability2D)));
     progUnforcedProbability2D = progUnforced2DVolume .* areaPlotVars.stratalControlArea; 
     progUnforcedProbability2D = sum(sum(sum(progUnforcedProbability2D))) / RSLRiseProbability2D; % because we need the probability only within the rising RSL volume
     
     if const.VERBOSE
         fprintf('2D stratigraphic control area proportions:\n');
         fprintf('%5.4f of stratigraphic control area is RSL rise, so %5.4f of area is RSL fall\n', RSLRiseProportion2D, 1.0-RSLRiseProportion2D);
         fprintf('%5.4f of stratigraphic control area is progradation (supply > accommodation), so %5.4f of area is retrogradation (supply < accommodation)\n', progStackProportion2D, 1.0-progStackProportion2D);
         
         fprintf('2D stratigraphic control area outcome probabilities:\n');
         fprintf('Probability of RSL fall and forced regression %5.4f\nProbability of RSL rise %5.4f\n',  1-RSLRiseProbability2D, RSLRiseProbability2D);
         fprintf('Probability of progradational %5.4f\nProbabiity of retrogradational %5.4f\n',  progStackProbability2D, 1-progStackProbability2D);
         fprintf('When RSL rise, probability of unforced regression %5.4f\nWhen RSL rise, probability of transgression %5.4f\n', progUnforcedProbability2D, 1-progUnforcedProbability2D);
     end
end

function gui = plot2DControlArea(gui, data, areaPlotVars)

     gui.f2 = figure('Visible','on','Position',[10 10 (gui.scrsz(3)/3) (gui.scrsz(4)/2)]);
     ax = gca;
     set(ax,'YScale','log');
     hold on; 
 
     maxControlAreaRSL = max(max(areaPlotVars.stratalControlArea));
     
     for x=1:areaPlotVars.RSLValuesCount
         yco = data.supplyMin;
         for y = 1:data.supplyValuesCount-1
             
             oneSupplyIncrement = data.supplyRange(y+1)- data.supplyRange(y); % Get values for increment from data.supplyRange because probably vary in size across range
             xco = areaPlotVars.RSLMin + ((x-1) * areaPlotVars.RSLIncrement);

             scaleFactor = areaPlotVars.stratalControlArea(x,y) / maxControlAreaRSL;
             colour = makeColourMap(scaleFactor);
             
             if areaPlotVars.stratalControlArea(x,y) > 0
                  patch([xco xco xco+areaPlotVars.RSLIncrement xco+areaPlotVars.RSLIncrement], [yco, yco + oneSupplyIncrement, yco + oneSupplyIncrement, yco], colour, 'LineStyle','none');
             end
             yco = yco + oneSupplyIncrement;
         end
         
     end
     
     % Draw the rate of RSL change = 0 line
     ycoLimits = get(gca,'YLim');
     line([0, 0], ycoLimits, 'LineWidth',2,'LineStyle', '--', 'Color',[0 0.3 0.8]);
     
     % Now calculate and draw the line seperating progradation (supply > accomm) from retrogradation (supply < accomm)
      j = 1;
      xco = zeros(1,data.supplyValuesCount);
      yco = zeros(1,data.supplyValuesCount);
      
      for x = 1 : areaPlotVars.RSLValuesCount

          RSL = areaPlotVars.RSLMin + ((x-1) * areaPlotVars.RSLIncrement); % Rate of RSL change is eustasy x + subsidence y1 or y2
          oneSupply = data.supplyMin;
          progPointFound = 0;
          y=1;
          
           while y <= data.supplyValuesCount-1 && ~progPointFound

              supply1D = oneSupply / data.supplyReferenceArea; % Divide supply volume by area of Holocene Mississippi delta deposition to convert supply to 1D thickness rate
              oneSupplyIncrement = data.supplyRange(y+1) - data.supplyRange(y);
              
              if supply1D >= RSL
                progPointFound = 1;
                xco(j) = RSL;
                yco(j) = oneSupply;
                j = j + 1;
              end
                 
              oneSupply = oneSupply + oneSupplyIncrement;
              y = y + 1;
          end
      end
      
      % Use the calculated coordinates to draw the line separating progradation from retrogradation
      line(xco, yco, 'LineWidth',2,'LineStyle', '--', 'Color',[0.5 0 0]);
end

function areaPlotVars = plot2DControlTrajectories(gui, const, data, areaPlotVars)

   fprintf('\n3D solution volume trajectory probabilities:\n');
     
   figure(gui.f2);  % Activate the stratal control volume figure since this is where we want to plot these 3D trajectories
    
     trajPVectors = cell(data.numberOfTrajectories,1); % trajPVectors is a cell array, each cell element will contain a different length vector of doubles that is the p values along the trajectory
   
     for j = 1:data.numberOfTrajectories
         
         if data.trajectoryDimensions(j) == 2 % only plot those trajectories tagged in the input file as 3D
             trajN = length(data.subsidTraj(j, :)); % Set variables to the length of each of the two input control volume trajectories

             % Copy into a convenient data structures to use in the trajectory probability calculation - traj gets passed to find2dsolutionArea... function below
             traj.eustasy = data.eustasyTraj(j, :);
             traj.subsid = data.subsidTraj(j, :);
             traj.supply = data.supplyTraj(j, :);
             traj.RSL = data.eustasyTraj(j, :) + data.subsidTraj(j, :);
             
             % Find the probabilites for trajectory j and at the same time, record interpolation between trajectory points as x,y,z coordinates to plot
             [trajPVectors{j}, xco, zco] = find2DsolutionAreaTrajectoryProbabilities(data, traj, areaPlotVars, trajN, '2D accommodation dominated');
            
             % Plot trajectory j
             line(xco, zco, 'Color', data.trajectoryColours(j,1:3), 'LineWidth', 5.0);
             line(traj.RSL(1:1), data.supplyTraj(j,1:1), 'LineStyle','none','Marker','o','MarkerSize',12, 'Color', data.trajectoryColours(j,1:3)); % lines needs at least 2 coord points? but make them the same to plot single market symbol at start and end of the line
             line(traj.RSL(trajN:trajN), data.supplyTraj(j,trajN:trajN), 'LineStyle','none','Marker','x','MarkerSize',12, 'Color', data.trajectoryColours(j,1:3));

         end
     end

     grid on;
     grid minor;
     
     xlabel('Rate of relative sea-level change (m per 100ky)');
     ylabel('Rate of sediment supply (m3 per 100ky)');
     
%   Create a high-resultion 600dpi transparent background png file for this figure using export_fig which is an .m file in the Matlab folder  
%   Commented out because it is slow and not necessary to do everytime code is run
%   export_fig ../figures/f5_2dSolutionArea.png

     % Analyse the 2D control area trajectories - are they accommodation or supply dominated?
     
%     f10 = figure('Visible','on','Position',[50 10 (scrsz(3)/1.8) (scrsz(4)/2)]);
%     subplot(2,1,1); 

     trajLengths = cellfun('length',trajPVectors); % Put the trajectory lengths into the trajLengths vector
     maxTrajLength = max(trajLengths); % Find the maximum trajectory length
     for j = 1:data.numberOfTrajectories
        trajPVectors{j}(trajLengths(j)+1:maxTrajLength) = 0; % Pad each trajectory to the maximum length
     end
     areaPlotVars.sAreaPValsTraj = cell2mat(trajPVectors); % Copy the P value trajectories into a matrix in the volPlotVars structure to pass back to calling function
end

% [sAreaPValsTraj1, accommTrajXco, accommTrajZco] = find2DsolutionAreaTrajectoryProbabilities(data, traj, areaPlotVars, trajN, '2D accommodation dominated');

function [sAreaPValsTrajFinal, xco, zco] = find2DsolutionAreaTrajectoryProbabilities(data, traj, areaPlotVars, lenTrajectory, label)
% Find the probabilites along a control area trajectory, using interpolation
% Code calculates the unit step length then for each section of the trajectory but then checks to remove adjacent duplicate cells 
% that may occur if the interpolation step is small

     sAreaTrajCoords = zeros(1, 5000);  % Length of this is unknown at this point because number of points depends on interpolation
     preservePoint = zeros(1, 5000);
     sAreaPValsTraj = zeros(1, lenTrajectory);
     sAreaPValsTrajFinal = zeros(1, lenTrajectory);
     ptsPerCell = 500;
     trajPos = 1; % Records position in the sVolPValsTraj array as it is filled in the code below
     
     % loop through all the points in the trajectory, -1 because need to use a j+1 in the calculations
     for j = 1:lenTrajectory-1

        % Calculate the x,y, and z increments in the j to j+1 steps in the trajectory assuming 10 interpolation steps per trajectory line segment
        trajDeltaX = (traj.RSL(j+1) - traj.RSL(j)) / ptsPerCell;
        trajDeltaZ = (traj.supply(j+1) - traj.supply(j)) / ptsPerCell;
        trajPointsSeparation = (sqrt((trajDeltaX * trajDeltaX) + (trajDeltaZ + trajDeltaZ))); % May be negative so nb abs in while condition below
        trajStepLength = trajPointsSeparation / ptsPerCell;
          
        xco(trajPos) = traj.RSL(j);
        zco(trajPos) = traj.supply(j);
        dist = 0;
        oneSegmentCount = 0;
        
%         fprintf('Trajectory point %d from %1.0f %1.0f %5.4e to %1.0f %1.0f %5.4e\n', j, xco, yco, zco, data.eustasyTraj1(j+1), data.subsidTraj1(j+1), data.supplyTraj1(j+1));
        
        while abs(dist) < abs(trajPointsSeparation) && oneSegmentCount < ptsPerCell % Two checks, dist to catch bad interpolation and oneSegmentCount to mitigate rounding errors on dist
            
            % Calculate the x y z matrix coordinates needed to get a probability out of the control volume
            x(trajPos) = round((xco(trajPos) - areaPlotVars.RSLMin) / areaPlotVars.RSLIncrement) + 1;
            z(trajPos) = findSupplyTrajIndex(zco(trajPos), data.supplyRange);
   
            % Check if the coords are within the control volume limits and if so, retrieve probability & increment counts  
            if x(trajPos) > 0 && x(trajPos) <= areaPlotVars.RSLValuesCount && z(trajPos) > 0 && z(trajPos) <= data.supplyValuesCount
                sAreaPValsTraj(trajPos) = areaPlotVars.stratalControlArea(x(trajPos),z(trajPos));
            else
                sAreaPValsTraj(trajPos) = 0.0; % Outside the control area so probability must be zero
%               fprintf('Trajectory error - x=%1.0f (%d) y=%1.0f (%d) z=%5.4e (%d) out of control volume range at point %d in trajectory called %s\n',xco, x(trajPos),yco, y(trajPos),zco, z(trajPos),j, label);
            end

            % Add the interpolation increments to the control values and record increase in distance interpolated along line segment
            xco(trajPos+1) = xco(trajPos) + trajDeltaX;
            zco(trajPos+1) = zco(trajPos) + trajDeltaZ;
            trajPos = trajPos + 1;
            dist = dist + trajStepLength;
            oneSegmentCount = oneSegmentCount + 1;
            
            if oneSegmentCount >= ptsPerCell % If the oneSegmentCount increment indicates the end of trajectory line segment...
                preservePoint(trajPos) = 1; % Set the flag to force point to be copied into final interpolated coordinates, even if it is a replicate
            else
                preservePoint(trajPos) = 0; % otherwise set the flat to zero and treat like any other point
            end
            
%             fprintf('Interpolation %1.0f %1.0f %5.4e\n', xco,yco,zco);
        end
     end
     
     % Interpolation routine may have recorded the same cell from the stratal control volume consecutviely more than once, especially if the interpolation step was small
     % So need to find adjacent duplicates and remove them, and also count the nonzero values in the interpolated trajectory
     % Note that if the trajectory repeats the same coord cells, this is fine, so long as they are not adjacent in the trajectory
     k = 1;
     nonZeroPathCount = 0;
     for j=2:trajPos-1;
          if ~(x(j) == x(j-1) && z(j) == z(j-1)) || preservePoint(j) == 1 % If the j & j-1 x,y,zcoords are not equal point j on trajectory is not a duplicate
            sAreaPValsTrajFinal(k) = sAreaPValsTraj(j);
%             fprintf('%d x:%d z:%d p=%7.6f\n',k, x(j), z(j), sAreaPValsTrajFinal(k));
%             line(xco(j),zco(j), 'LineStyle','none','Marker','x','MarkerSize',8, 'Color', [0 0.0 0.0]); 
            if sAreaPValsTrajFinal(k) > 0 
                nonZeroPathCount = nonZeroPathCount + 1; 
            end
            k=k+1;
          end
     end
     
    fprintf('%s trajectory %d points long interpolated to give total length %d points, %d points have p>0, mean p %6.5f\n', label, lenTrajectory, k, nonZeroPathCount, mean(sAreaPValsTrajFinal));
end

function calculateASTRRValues(data, areaPlotVars)
  
    messageAll = sprintf('Accommodation Supply Trajectory Range Ratio (ASTRR) values for %d control space trajectories:\n', data.numberOfTrajectories);

    for j = 1:data.numberOfTrajectories
        
        RSLTraj = data.eustasyTraj(j, :) + data.subsidTraj(j, :);
        ASratioTraj = zeros(1,length(RSLTraj));
        accommTraj = zeros(1,length(RSLTraj));

        for k = 2:length(RSLTraj)
            accommTraj(k) = RSLTraj(k) -  RSLTraj(k-1);
            ASratioTraj(k) = accommTraj(k) / (data.supplyTraj(k) / data.supplyReferenceArea);
        end
        
        meanASratioTraj = mean(ASratioTraj);
        trajAccommRange = (max(accommTraj) - min(accommTraj)) / (areaPlotVars.RSLMax - areaPlotVars.RSLMin);
        trajSupplyRange = (max(data.supplyTraj(j,:)) - min(data.supplyTraj(j,:))) / (data.supplyMax - data.supplyMin);
        ASTRR = trajAccommRange / trajSupplyRange;

        message = sprintf('Trajectory %d: Mean A:S ratio %5.4f ASTRR %5.4f\n', j, meanASratioTraj, ASTRR);
        messageAll = strcat(messageAll, message);
    end
    
    m1 = msgbox(messageAll,'ASTRR Values');
end

%% stratal control volume and control area probability bar charts
function gui = plotTrajectoryProbabilities(gui, data, volPlotVars, areaPlotVars)

    gui.f3 = figure('Visible','on','Position',[10 10 (gui.scrsz(3)/3) (gui.scrsz(4)/2)]);
    subplot(2,1,1);
    
    volTrajLens = length(volPlotVars.sVolPValsTraj);
    maxVolTrajN = max(volTrajLens);
    areaTrajLens = length(areaPlotVars.sAreaPValsTraj);
    maxAreaTrajN = max(areaTrajLens);
    
    barPlotData = zeros(maxVolTrajN,data.numberOfTrajectories);
    for j = 1:data.numberOfTrajectories
        barPlotData(:,j) = volPlotVars.sVolPValsTraj(j,:);
        handle = bar(barPlotData, 2.0); % 1 is the width of the bars, as a decimal fraction of the maximum width
        handle(j).FaceColor = data.trajectoryColours(j,1:3);
        handle(j).EdgeColor = data.trajectoryColours(j,1:3);
    end

    xlabel('Point number along the trajectory');
    ylabel('Probability');
    title('Stratal Control Volume Trajectory probabilities');
    grid on;
    grid minor;
    
    subplot(2,1,2);
    
    barPlotData = zeros(maxAreaTrajN,data.numberOfTrajectories);
    for j = 1:data.numberOfTrajectories
        barPlotData(:,j) = areaPlotVars.sAreaPValsTraj(j,:);
        handle = bar(barPlotData, 2.0); % 1 is the width of the bars, as a decimal fraction of the maximum width
        handle(j).FaceColor = data.trajectoryColours(j,1:3);
        handle(j).EdgeColor = data.trajectoryColours(j,1:3);
    end
    
    xlabel('Point number along the trajectory');
    ylabel('Probability');
    title('Stratal Control Area Trajectory probabilities');
    grid on;
    grid minor;
    
%     export_fig ../figures/f6_trajectoryPvalues.png

end

function gui = plotFigureKeyElements(gui, areaPlotVars)

%     "manually" draw a colour bar for cuboid frequency colour coding
     gui.f4 =figure('Visible','on','Position',[100 10 (gui.scrsz(3)/5) (gui.scrsz(4)/1.2)]);
     
     subplot(1,2,1);
     
     scale = [0.1 0.25 0.5 0.75 1.0];
     
     for i=1:5
          plotCuboid(0.5, 0.5, i, 0,1, 0,1, 0,1, scale(i))
     end
     view([1 5 0.5]); % NB magnitude of the coords is not evaluated to define distance from axis area, only the direction of view they define
     axis off;
%      export_fig ../figures/f3_3dPCubes_key.png
     
%     "manually" draw a colour bar for frequency colour coding 
     
    subplot(1,2,2);
     i=1;
     for RSL= areaPlotVars.RSLMin: areaPlotVars.RSLIncrement: areaPlotVars.RSLMax
          colour = [(areaPlotVars.RSLMax - RSL) / areaPlotVars.RSLRange 0 (RSL - areaPlotVars.RSLMin) / areaPlotVars.RSLRange];
          patch([0.750 1.00 1.00 0.75], [i i i+1 i+1], colour);
          i=i+1;
     end
     
     
     for i=1:21 % 21 because going to start i at zero within the loop using i-1 because we want 0 value colour to be shown
          if i <= 10
             rgbColour = [1 (((i-1)/20.0)*2) 0]; % using i-1 because we want 0 value colour to be shown
          else
             rgbColour = [1 - ((((i-1)/20.0) - 0.5) * 2) 1 0];
          end
          patch([0 0.25 0.25 0], [i i i+1 i+1], rgbColour);
     end
     axis off;
%      export_fig ../figures/f4_RSL_prob_colourbars.png
end

function plotCuboid(x,y,z, plotEustasyStart, plotEustasyIncrement, plotSubsidStart, plotSubsidIncrement, plotSupplyStart, plotSupplyIncrement, scaleFactor)

     xcoCenterPoint = plotEustasyStart + ((x-1) * plotEustasyIncrement) + (plotEustasyIncrement * 0.5);
     xco1 = xcoCenterPoint - (plotEustasyIncrement * 0.5 * scaleFactor);
     xco2 = xcoCenterPoint + (plotEustasyIncrement * 0.5 * scaleFactor);

     ycoCenterPoint = plotSubsidStart + ((y-1) * plotSubsidIncrement) + (plotSubsidIncrement * 0.5);
     yco1 = ycoCenterPoint - (plotSubsidIncrement * 0.5 * scaleFactor);
     yco2 = ycoCenterPoint + (plotSubsidIncrement * 0.5 * scaleFactor);

     zcoCenterPoint = plotSupplyStart + (plotSupplyIncrement * 0.5);
     zco1 = zcoCenterPoint - (plotSupplyIncrement * 0.5 * scaleFactor);
     zco2 = zcoCenterPoint + (plotSupplyIncrement * 0.5 * scaleFactor);

     colour = makeColourMap(scaleFactor);

     % top face
     xco = [xco1 xco1 xco2 xco2];
     yco = [yco1 yco2 yco2 yco1];
     zco = [zco2 zco2 zco2 zco2];                     
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);

     % bottom face
     xco = [xco1 xco1 xco2 xco2];
     yco = [yco1 yco2 yco2 yco1];
     zco = [zco1 zco1 zco1 zco1];                     
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);

     %side - front face on y axis
     xco = [xco2 xco2 xco2 xco2];
     yco = [yco1 yco2 yco2 yco1];
     zco = [zco1 zco1 zco2 zco2];
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);

     %side - back face on y axis
     xco = [xco1 xco1 xco1 xco1];
     yco = [yco1 yco2 yco2 yco1];
     zco = [zco1 zco1 zco2 zco2];
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);

     %side - front face on x axis
     xco = [xco2 xco2 xco1 xco1];
     yco = [yco1 yco1 yco1 yco1];
     zco = [zco1 zco2 zco2 zco1];
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);

     %side - back face on x axis
     xco = [xco2 xco2 xco1 xco1];
     yco = [yco2 yco2 yco2 yco2];
     zco = [zco1 zco2 zco2 zco1];
     patch(xco, yco, zco, colour,'LineStyle','-', 'FaceAlpha',0.50,'EdgeAlpha',0.50);
end

function plotCuboidOutline(x,y,z, plotEustasyStart, plotEustasyIncrement, plotSubsidStart, plotSubsidIncrement, plotSupplyStart,plotSupplyIncrement)
    
     xcoCenterPoint = plotEustasyStart + ((x-1) * plotEustasyIncrement) + (plotEustasyIncrement * 0.5);
     xco1 = xcoCenterPoint - (plotEustasyIncrement*0.5);
     xco2 = xcoCenterPoint + (plotEustasyIncrement*0.5);

     ycoCenterPoint = plotSubsidStart + ((y-1) * plotSubsidIncrement) + (plotSubsidIncrement * 0.5);
     yco1 = ycoCenterPoint - (plotSubsidIncrement*0.5);
     yco2 = ycoCenterPoint + (plotSubsidIncrement*0.5);

     zcoCenterPoint = plotSupplyStart + ((z-1) * plotSupplyIncrement) + (plotSupplyIncrement * 0.5);
     zco1 = zcoCenterPoint - (plotSupplyIncrement*0.5);
     zco2 = zcoCenterPoint + (plotSupplyIncrement*0.5);
     
     line([xco1 xco1 xco2 xco2 xco1],[yco1 yco2 yco2 yco1 yco1],[zco1 zco1 zco1 zco1 zco1]);
     line([xco1 xco1 xco2 xco2 xco1],[yco1 yco2 yco2 yco1 yco1],[zco2 zco2 zco2 zco2 zco2]);
     
     line([xco1 xco1],[yco1 yco1], [zco1 zco2]);
end

function rgbColour = makeColourMap(dataValue)

     if dataValue <= 0.5
         rgbColour = [1 (dataValue*2) 0];
     else
         rgbColour = [1 - ((dataValue - 0.5) * 2) 1 0];
     end
end

function indexVal = findSupplyTrajIndex(supplyValue, supplyRange)
% SupplyRange is a vector of the values that are on the z/y axis of the stratal control volumes, as defined by the range of sediment supply values in the input PDF
% Function returns the index for the element of the supply range vector closest to supplyValue

    indexVal=1;
    while (indexVal < length(supplyRange) && supplyRange(indexVal+1) <= supplyValue)  % Because we want to stop in the cell points to by indexVal when the next cell value is larger or the same
        indexVal = indexVal + 1;
    end
end


