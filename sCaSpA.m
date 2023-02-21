classdef sCaSpA < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        FileMenu
        FileMenuOpen
        FileMenuLoad
        FileMenuSave
        FileMenuLabelCondition
        FileMenuExport
        FileMenuDebug
        PlotInteractionPanel           matlab.ui.container.Panel
        ShowRawButton                  matlab.ui.control.Button
        CellNumberLabel                matlab.ui.control.Label
        ExporttraceButton              matlab.ui.control.Button
        LabelFeatButton                matlab.ui.control.Button
        LabelPeakButton                matlab.ui.control.Button
        FixYAxisButton                 matlab.ui.control.Button
        ZoomXMax                       matlab.ui.control.NumericEditField
        ZoomXMin                       matlab.ui.control.NumericEditField
        ZoomXButton                    matlab.ui.control.Button
        CellNumberEditField            matlab.ui.control.NumericEditField
        ButtonPreviousCell             matlab.ui.control.Button
        ButtonNextCell                 matlab.ui.control.Button
        PlotTypeButtonGroup            matlab.ui.container.ButtonGroup
        SingleTraceButton              matlab.ui.control.ToggleButton
        AllAndMeanButton               matlab.ui.control.ToggleButton
        DetectROIsButton               matlab.ui.control.Button
        AddROIsButton                  matlab.ui.control.StateButton
        DeleteROIsButton               matlab.ui.control.StateButton
        ImportROIsButton               matlab.ui.control.Button
        DropDownDIC                    matlab.ui.control.DropDown
        ButtonPreviousRecording        matlab.ui.control.Button
        ButtonNextRecording            matlab.ui.control.Button
        ShowFrameButton                matlab.ui.control.StateButton
        DropDownTimelapse              matlab.ui.control.DropDown
        ShowStDevButton                matlab.ui.control.StateButton
        ShowMovieButton                matlab.ui.control.StateButton
        NetworkActivityOptionsPanel    matlab.ui.container.Panel
        DefaultButton                  matlab.ui.control.Button
        CancelButton                   matlab.ui.control.Button
        SaveButton                     matlab.ui.control.Button
        DetrendingOptionsPanel         matlab.ui.container.Panel
        DetrendWindowfrEditField       matlab.ui.control.NumericEditField
        DetrendWindowfrEditFieldLabel  matlab.ui.control.Label
        DetrendingMethodDropDown       matlab.ui.control.DropDown
        DetrendingMethodDropDownLabel  matlab.ui.control.Label
        RegistrationOptionsPanel       matlab.ui.container.Panel
        ReferenceConditionEditField    matlab.ui.control.EditField
        ReferenceConditionLabel        matlab.ui.control.Label
        RegistrationCheckBox           matlab.ui.control.CheckBox
        ROIsOptionsPanel               matlab.ui.container.Panel
        ROISizepxsEditField            matlab.ui.control.NumericEditField
        ROISizepxsEditFieldLabel       matlab.ui.control.Label
        ROIShapeDropDown               matlab.ui.control.DropDown
        ROIShapeDropDownLabel          matlab.ui.control.Label
        DetectionOptionsPanel          matlab.ui.container.Panel
        TraceToUseDropDown             matlab.ui.control.DropDown
        TracetouseDropDownLabel        matlab.ui.control.Label
        MaxDurationframesEditField     matlab.ui.control.NumericEditField
        MaxDurationframesEditFieldLabel  matlab.ui.control.Label
        MinDurationframesEditField     matlab.ui.control.NumericEditField
        MinDurationframesEditFieldLabel  matlab.ui.control.Label
        MinDistanceframesEditField     matlab.ui.control.NumericEditField
        MinDistanceframesEditFieldLabel  matlab.ui.control.Label
        MinProminanceEditField         matlab.ui.control.NumericEditField
        MinProminanceEditFieldLabel    matlab.ui.control.Label
        ThresholdEditField             matlab.ui.control.NumericEditField
        ThresholdEditFieldLabel        matlab.ui.control.Label
        MethodDropDown                 matlab.ui.control.DropDown
        MethodDropDownLabel            matlab.ui.control.Label
        LoadOptionsPanel               matlab.ui.container.Panel
        FrequencyEditField             matlab.ui.control.NumericEditField
        FrequencyEditFieldLabel        matlab.ui.control.Label
        MicroscopeDropDown             matlab.ui.control.DropDown
        MicroscopeDropDownLabel        matlab.ui.control.Label
        StillConditionEditField        matlab.ui.control.EditField
        StillConditionEditFieldLabel   matlab.ui.control.Label
        SliderMovie                    matlab.ui.control.Slider
        SpikeDetectionPanel            matlab.ui.container.Panel
        RemovePeakButton               matlab.ui.control.Button
        AddPeakButton                  matlab.ui.control.Button
        QuantifyButton                 matlab.ui.control.Button
        DetectButton                   matlab.ui.control.Button
        DetectionButtonGroup           matlab.ui.container.ButtonGroup
        SelectedTraceButton            matlab.ui.control.ToggleButton
        SelectedFOVButton              matlab.ui.control.ToggleButton
        CurrentListButton              matlab.ui.control.ToggleButton
        AllFOVsButton                  matlab.ui.control.ToggleButton
        UIAxesDIC                      matlab.ui.control.UIAxes
        UIAxesMovie                    matlab.ui.control.UIAxes
        UIAxesPlot                     matlab.ui.control.UIAxes
        DICChannels                     matlab.ui.container.ButtonGroup
        DICCh1                          matlab.ui.control.ToggleButton
        DICCh2                          matlab.ui.control.ToggleButton
        DICCh3                          matlab.ui.control.ToggleButton
    end
    
    % File storage properties
    properties (Access = public)
        dicT % Table containing the information from the DIC image
        imgT % Table containing the information of the peaks
        currDIC % The DIC image that is display
        currStak % The stack that is selected
        currCell % The cell that is selected
        movieData % Temporary storage of the timelapse
        options % Store the options
        YMinMax % Store the minimum and maximum value of the Y axis in this FOV
        bSave % Toggle if there is new data that need to be saved
    end
    
    % Housekeeping properties
    properties (Access = private)
        cellsMask % B&W image as mask of the cells ROIs
        patchMask % container for the cells mask
        changeROI % Toggle is the ROI settings are changed. If so, load again the file
        hStack % Handle to movie image
        curSlice % The timelapse slice that is visible
        curTime % a line for the current position on the plot
        nChannel % number of DIC channels
        newChange = false; % to detect if there are changes that needs to be saved
        bZoom = false;
        keepColor = [219 68 55;...      % Google RED
                    15 157 88;...       % Google GREEN
                    66 133 244;...      % Google BLUE
                    244 180 0] / 255;	% Google YELLOW
    end
    
    % Callbacks methods
    methods
        function FileMenuOpenSelected(app)
            % Locate the folder with the images
            imgPath = uigetdir(app.options.LastPath, 'Select Image folder');
            togglePointer(app)
            if imgPath ~= 0
                % Save the path to the settings
                app.options.LastPath = imgPath;
                % Load the data starting from the DIC/BF/Still image
                hWait = waitbar(0, 'Loading images data');
                imgFiles = dir(fullfile(imgPath, '*.tif'));
                % Populate the DIC table
                dicFltr = contains({imgFiles.name}, app.options.StillCondition)';
                nameParts = regexp({imgFiles.name}, '_', 'split')';
                if isempty(dicFltr)
                    errordlg('No files have the selected "Still Condition".\nPlease adjust and rety', 'Loading failed');
                    return
                end
                tempT = table;
                tempT.Filename = fullfile({imgFiles(dicFltr).folder}', {imgFiles(dicFltr).name}');
                tempT.CellID = cellfun(@(x) x(1:end-4), {imgFiles(dicFltr).name}', 'UniformOutput', false);
                expIDs = cellfun(@(x) sprintf('%s_%s', x{1}, x{3}), nameParts, 'UniformOutput', false);
                tempT.ExperimentID = expIDs(dicFltr);
                % Check if it is a multichannel image and prepare the containing array
                dicInfo = imfinfo(tempT.Filename{1});
                app.nChannel = numel(dicInfo);
                dicWidth = dicInfo(1).Width;
                dicHeight = dicInfo(1).Height;
                tempDicImage = repmat({zeros(dicHeight, dicWidth, app.nChannel, 'uint8')}, height(tempT), 1);
                for i = 1:size(tempT,1)
                    waitbar(i/sum(dicFltr), hWait, sprintf('Loading DIC data %0.2f%%', i/sum(dicFltr)*100));
                    dicFile = tempT.Filename{i};
                    for c = 1:app.nChannel                   
                        tempDicImage{i,1}(:,:,c) = imread(dicFile,c);
                    end
                end
                tempT.RawImage = tempDicImage;
                tempT.RoiSet = repmat({[]}, size(tempT,1), 1);
                app.dicT = tempT;
                % Populate the imgT
                imgFltr = find(~dicFltr);
                tempT = cell(numel(imgFltr)+1, 15);
                tempT(1,:) = {'Filename', 'CellID', 'Week', 'CoverslipID', 'RecID', 'Condition', 'ExperimentID', 'ImgProperties', 'ImgByteStrip', 'RawIntensity', 'FF0Intensity', 'DetrendData', 'SpikeLocations', 'SpikeIntensities', 'SpikeWidths'};
                tempT(2:end,1) = fullfile({imgFiles(imgFltr).folder}, {imgFiles(imgFltr).name});
                tempT(2:end,2) = cellfun(@(x) x(1:end-4), {imgFiles(imgFltr).name}, 'UniformOutput', false);
                imgIDs = nameParts(imgFltr);
                % Check the informations on the name. In case there is something wrong, ask the user
                if numel(imgIDs{1}) ~= 4
                    warndlg('name missmatch, but I don''t know what to do');
                end
                for i = 1:numel(imgFltr)
                    waitbar(i/numel(imgFltr), hWait, sprintf('Loading movie data %0.2f%%', i/numel(imgFltr)*100));
                    tempT{i+1,3} = weeknum(datetime(imgIDs{i}{1}, 'InputFormat', 'yyMMdd'));
                    tempT{i+1,4} = imgIDs{i}{3};
                    tempT{i+1,5} = imgIDs{i}{4};
                    tempT{i+1,6} = imgIDs{i}{2};
                    tempT{i+1,7} = [imgIDs{i}{1} '_' imgIDs{i}{3}]; % use to link the DIC to the movies
                    % get the imaging period (T) and frequency (Fs) from the file
                    imgInfo = imfinfo(fullfile(imgFiles(imgFltr(i)).folder, imgFiles(imgFltr(i)).name));
                    switch app.options.Microscope
                        case {'Nikon A1' 'Nikon Ti2'}
                            T = imgInfo(1).ImageDescription;
                            T = regexp(T, '=', 'split');
                            T = sscanf(T{6}, '%f');
                            if isinf(T)
                                T = 1/(app.options.Frequency);
                            end
                        case 'Others'
                            if app.options.Frequency > 0
                                T = 1/(app.options.Frequency);
                            else
                                answerInfo = inputdlg({'Imaging frequecy (Hz)'}, 'Import data');
                                T = 1/str2double(answerInfo{1});
                            end
                    end
                    tempT{i+1,8} = [imgInfo(1).Width, imgInfo(1).Height, length(imgInfo), 1/T];
                    if strcmp(imgInfo(1).ByteOrder, 'big-endian')
                        tempT{i+1,9} = {[imgInfo.StripOffsets]+1};
                    else
                        tempT{i+1,9} = {[imgInfo.StripOffsets]};
                    end
                end
                delete(hWait);
                app.imgT = cell2table(tempT(2:end,:), 'VariableNames', tempT(1,:));
                % Populate tehe DIC dropdown menu and show the first image
                app.currDIC = app.dicT.CellID{1};
                updateDropDownDIC(app);
                updateDIC(app);
                % Populate the timelapse dropdown and show the first frame
                updateDropDownTimelapse(app);
                event.Source.Text = 'Show Frame';
                ShowTimelapseChanged(app, event)
                %detrendData(app);
                toggleInteractions(app, 'Loaded');
                %ListImagesChange(app)
                app.newChange = true;
            else
                togglePointer(app)
                return
            end
            togglePointer(app)
        end
        
        function FileMenuLoadSelected(app)
            [fileName, filePath] = uigetfile(app.options.LastPath, 'Select Network File');
            if filePath ~= 0
                % Save the path to the settings
                app.options.LastPath = filePath;
                togglePointer(app)
                networkFiles = load(fullfile(filePath, fileName));
                if isfield(networkFiles, 'options')
                    app.options = networkFiles.options;
                end
                if isfield(networkFiles, 'dicT')
                    if isempty(app.dicT)
                        app.dicT = networkFiles.dicT;
                    else
                        app.dicT = [app.dicT; networkFiles.dicT];
                    end
                end
                if isfield(networkFiles, 'imgT')
                    if isempty(app.imgT)
                        app.imgT = networkFiles.imgT;
                    else
                        if numel(app.imgT.Properties.VariableNames) ~= numel(networkFiles.imgT.Properties.VariableNames)
                            % We need to add columns
                            missVars = setdiff(app.imgT.Properties.VariableNames, networkFiles.imgT.Properties.VariableNames);
                            for missVar = missVars
                                networkFiles.imgT = addvars(networkFiles.imgT, nan(size(networkFiles.imgT,1), 1), 'NewVariableNames',missVar);
                            end
                        end
                        app.imgT = [app.imgT; networkFiles.imgT];
                    end
                end
                togglePointer(app)
            end
            % Populate tehe DIC dropdown menu and show the first image
            app.currDIC = app.dicT.CellID{1};
            updateDropDownDIC(app);
            % Populate the timelapse dropdown and show the first frame
            updateDropDownTimelapse(app);
            event.Source.Text = 'Show Frame';
            ShowTimelapseChanged(app, event)
            toggleInteractions(app, 'Loaded');
            updateDIC(app);
            if ~isempty(app.imgT.FF0Intensity{1})
                toggleInteractions(app, 'Detection');
            end
            if any(matches(app.imgT.Properties.VariableNames, 'SpikeLocations'))
                toggleInteractions(app, 'Quantification');
            end
        end
        
        function FileMenuSaveSelected(app)
            % First save the settings
            saveSettings(app)
            % Then save the data
            oldDir = cd(app.options.LastPath);
            [fileName, filePath] = uiputfile('*.mat', 'Save network data');
            togglePointer(app);
            savePath = fullfile(filePath, fileName);
            figure(app.UIFigure);
            imgT = app.imgT;
            dicT = app.dicT;
            options = app.options;
            save(savePath, 'imgT', 'dicT', 'options');
            cd(oldDir)
            togglePointer(app);
            app.newChange = false;
        end
        
        function ImportROIs(app)
            roiPath = uigetdir(app.options.LastPath, 'Select ROI folder');
            roiFiles = dir(fullfile(roiPath, '*.zip'));
            togglePointer(app);
            figure(app.UIFigure);
            try
                % Get the name info
                nameList = regexprep({roiFiles.name}, '.zip', '');
                nameParts = regexp(nameList, '_', 'split')';
                nFiles = numel(nameList);
                allRois = cell(size(app.imgT,1), 1);
                hWait = waitbar(0, 'Importing ROI data');
                for f = 1:nFiles
                    waitbar(f/nFiles, hWait, sprintf('Loading ROIs data: %d / %d', f, nFiles));
                    % Match the ROI to the expetimentID
                    expID = [nameParts{f}{2} '_' nameParts{f}{4}];
                    cellFltr = matches(app.dicT.ExperimentID, expID);
                    % Extract the ROIs
                    tempRoi = ReadImageJROI(fullfile({roiFiles(f).folder}, {roiFiles(f).name}));
                    tempRoi = cellfun(@(x) x.vnRectBounds, tempRoi{:}, 'UniformOutput', false);
                    % Get the center coordinate
                    tempRoi = cellfun(@(x) round([mean(x([2 4])), mean(x([1 3]))]), tempRoi, 'UniformOutput', false);
                    % Add the ROI to the right cells
                    allRois{cellFltr} = cell2mat(tempRoi');
                    % Load the data
                    getIntensity(app)
                end
                app.dicT.RoiSet = allRois;
                delete(hWait);
                togglePointer(app)
            catch ME
                delete(hWait);
                togglePointer(app);
                disp(ME)
                errordlg('Failed to import the RoiSet. Please check command window for details', 'Import ROIs failed');
            end
            modifyROIs(app, 'Modify')
        end
        
        function FileLabelConditionSelected(app)
        end
        
        function FileMenuExportSelected(app)
        end
        
        function SaveOptions(app)
            app.options.StillCondition = app.StillConditionEditField.Value;
            app.options.Microscope = app.MicroscopeDropDown.Value;
            app.options.Frequency = app.FrequencyEditField.Value;
            app.options.RoiSize = app.ROISizepxsEditField.Value;
            app.options.RoiShape = app.ROIShapeDropDown.Value;
            app.options.PeakMinHeight = app.MethodDropDown.Value;
            app.options.SigmaThr = app.ThresholdEditField.Value;
            app.options.PeakMinProminance = app.MinProminanceEditField.Value;
            app.options.PeakMinDistance = app.MinDistanceframesEditField.Value;
            app.options.PeakMinDuration = app.MinDurationframesEditField.Value;
            app.options.PeakMaxDuration = app.MaxDurationframesEditField.Value;
            app.options.DetectTrace = app.TraceToUseDropDown.Value;
            app.options.Registration = app.RegistrationCheckBox.Value;
            app.options.Reference = app.ReferenceConditionEditField.Value;
            if ~strcmp(app.options.Detrending, app.DetrendingMethodDropDown.Value) || (app.options.DetrendSize ~= app.DetrendWindowfrEditField.Value)
                app.options.Detrending = app.DetrendingMethodDropDown.Value;
                app.options.DetrendSize = app.DetrendWindowfrEditField.Value;
                detrendData(app);
            end
            if app.changeROI
                modifyROIs(app, 'Modify');
            end
            if ~isempty(app.imgT)
                updatePlot(app);
            end
        end
        
        function OptionMenuDebugSelected(app)
            disp(['You are now in debug mode. To exit the debug use "dbquit".',...
                ' Use "dbcont" to continue with the changes made'])
            keyboard
        end
        
        function SelectedDIC(app)
            app.currDIC = app.DropDownDIC.Value;
            updateDIC(app);
            updateDropDownTimelapse(app);
            button.Source.Text = 'Show Frame';
            if app.ShowStDevButton.Value
                button.Source.Text = 'Show StDev';
            end
            if app.ShowMovieButton.Value
                button.Source.Text = 'Show Movie';
            end
            ShowTimelapseChanged(app, button)
            updatePlot(app);
        end
        
        function ChangeRecordingPressed(app, event)
            switch event.Source.Text
                case '>'
                    tempDIC = find(contains(app.DropDownDIC.Items, app.DropDownDIC.Value));
                    tempDIC = tempDIC + 1;
                    if tempDIC > numel(app.DropDownDIC.Items)
                        tempDIC = 1;
                    end
                case '<'
                    tempDIC = find(contains(app.DropDownDIC.Items, app.DropDownDIC.Value));
                    tempDIC = tempDIC - 1;
                    if tempDIC < 1
                        tempDIC = numel(app.DropDownDIC.Items);
                    end
            end
            app.currDIC = app.DropDownDIC.Items(tempDIC);
            app.DropDownDIC.Value = app.DropDownDIC.Items(tempDIC);
            updateDropDownTimelapse(app);
            updateDIC(app);
            button.Source.Text = 'Show Frame';
            if app.ShowStDevButton.Value
                button.Source.Text = 'Show StDev';
            end
            if app.ShowMovieButton.Value
                button.Source.Text = 'Show Movie';
            end
            ShowTimelapseChanged(app, button)
        end
        
        function ShowTimelapseChanged(app, event)
            % Switch the button and load the movie accordingly
            switch event.Source.Text
                case 'Show Frame'
                    app.ShowFrameButton.BackgroundColor = app.keepColor(2,:);
                    app.ShowStDevButton.BackgroundColor = [.96 .96 .96];
                    app.ShowMovieButton.BackgroundColor = [.96 .96 .96];
                    app.ShowFrameButton.Enable = 'off';
                    app.ShowStDevButton.Enable = 'on';
                    app.ShowMovieButton.Enable = 'on';
                    app.ShowStDevButton.Value = 0;
                    app.ShowMovieButton.Value = 0;
                    tempImg = app.imgT.Filename{contains(app.imgT.CellID, app.DropDownTimelapse.Value)};
                    updateTimelapse(app, 'Frame', imread(tempImg))
                case 'Show StDev'
                    app.ShowFrameButton.BackgroundColor = [.96 .96 .96];
                    app.ShowStDevButton.BackgroundColor = app.keepColor(2,:);
                    app.ShowMovieButton.BackgroundColor = [.96 .96 .96];
                    app.ShowFrameButton.Enable = 'on';
                    app.ShowStDevButton.Enable = 'off';
                    app.ShowMovieButton.Enable = 'on';
                    app.ShowFrameButton.Value = 0;
                    app.ShowMovieButton.Value = 0;
                    imgIdx = contains(app.imgT.CellID, app.DropDownTimelapse.Value);
                    imgStack = loadTiff(app, imgIdx, 1);
                    tempImg = std(double(imgStack),[],3);
                    updateTimelapse(app, 'StDev', tempImg)
                case 'Show Movie'
                    app.ShowFrameButton.BackgroundColor = [.96 .96 .96];
                    app.ShowStDevButton.BackgroundColor = [.96 .96 .96];
                    app.ShowMovieButton.BackgroundColor = app.keepColor(2,:);
                    app.ShowFrameButton.Enable = 'on';
                    app.ShowStDevButton.Enable = 'on';
                    app.ShowMovieButton.Enable = 'off';
                    app.ShowFrameButton.Value = 0;
                    app.ShowStDevButton.Value = 0;
                    imgIdx = contains(app.imgT.CellID, app.DropDownTimelapse.Value);
                    imgStack = loadTiff(app, imgIdx, 1);
                    tempImg = std(double(imgStack),[],3);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    updateTimelapse(app, 'StDev', tempImg)
            end
            if ~isempty(app.patchMask)
                copyobj(app.patchMask, app.UIAxesMovie)
            end
        end
        
        function crosshairDIC(app, event)
            if strcmp(app.UIFigure.Pointer, 'arrow')
                app.UIFigure.Pointer = 'crosshair';
                app.AddROIsButton.Enable = app.AddROIsButton.Value;
                app.DeleteROIsButton.Enable = app.DeleteROIsButton.Value;
            else
                app.UIFigure.Pointer = 'arrow';
                app.AddROIsButton.Enable = 'on';
                app.DeleteROIsButton.Enable = 'on';
                app.AddROIsButton.Value = false;
                app.DeleteROIsButton.Value = false;
                modifyROIs(app, event.Source.Text);
            end
        end
        
        function ChangedROI(app)
            app.changeROI = true;
        end
    end
    
    % Detection methods
    methods
        function DetectClickDIC(app, event)
            if event.Button == 3
                if ~app.bZoom
                    zoomF = 50;
                    % Zoom in
                    zoomPoint = round(event.IntersectionPoint);
                    xMin = max(0, zoomPoint(1) - zoomF);
                    xMax = min(size(app.dicT.RawImage{1},1), zoomPoint(1) + zoomF);
                    yMin = max(0, zoomPoint(2) - zoomF);
                    yMax = min(size(app.dicT.RawImage{1},1), zoomPoint(2) + zoomF);
                    app.UIAxesDIC.XLim = [xMin xMax];
                    app.UIAxesDIC.YLim = [yMin yMax];
                else
                    % Zoom out
                    app.UIAxesDIC.XLim = [0 size(app.dicT.RawImage{1},1)];
                    app.UIAxesDIC.YLim = [0 size(app.dicT.RawImage{1},1)];
                end
                app.bZoom = ~app.bZoom;
                return
            end
            % Add or remove ROIs
            if app.AddROIsButton.Value
                % Get the new ROI fix it inside the image
                newRoi = round(event.IntersectionPoint(1:2));
                newRoi(newRoi <= app.options.RoiSize) = app.options.RoiSize + 1;
                newRoi(newRoi >= size(app.dicT.RawImage{1},1) - app.options.RoiSize) = size(app.dicT.RawImage{1},1) - app.options.RoiSize - 1;
                % Show the selected ROI
                hold(app.UIAxesDIC, 'on')
                if strcmp(app.options.RoiShape, 'Square')
                    tempRoi = [newRoi - app.options.RoiSize; newRoi + app.options.RoiSize];
                    roiX = [tempRoi(1,1) tempRoi(2,1) tempRoi(2,1) tempRoi(1,1)];
                    roiY = [tempRoi(1,2) tempRoi(1,2) tempRoi(2,2) tempRoi(2,2)];
                else
                    t = linspace(0, 2*pi);
                    roiX = newRoi(1) + app.options.RoiSize * cos(t);
                    roiY = newRoi(2) + app.options.RoiSize * sin(t);
                end
                hPatch = patch(app.UIAxesDIC, roiX, roiY, app.keepColor(1,:), 'FaceColor', 'none', 'HitTest', 'off');
                % Check that if there are already stored ROIs and store them
                tempDIC = contains(app.dicT.CellID, app.DropDownDIC.Value);
                if ~isempty(app.dicT.RoiSet{tempDIC})
                    newRoi = [app.dicT.RoiSet{tempDIC}; newRoi];
                end
                app.dicT.RoiSet{tempDIC} = newRoi;
                % Store the ROI on the image
                app.patchMask = [app.patchMask; hPatch];
            end
        end
        
        function modifyROIs(app, howTo)
            switch howTo
                case 'Add ROIs'
                    % Load the image and calculate the FF0 on the ROIs
                    getIntensity(app)
                    % Show the ROIs with colors, and in the timelapse image
                    nRoi = numel(app.patchMask);
                    for r = 1:nRoi
                        app.patchMask(r).EdgeColor = app.keepColor(4,:);
                    end
                    copyobj(app.patchMask, app.UIAxesMovie)
%                     hPatch = findobj(app.UIAxesMovie, 'Type', 'Patch'); % Use this to change color specifically on the timelapse
                    % Plot the data
                    updatePlot(app);
                    % Update the interface, now you can detect peaks
                    toggleInteractions(app, 'Detection');
                case 'Modify'
                    % First change the size/shape on the picture
                    tempDIC = contains(app.dicT.CellID, app.DropDownDIC.Value);
                    allRoi = app.dicT.RoiSet{tempDIC};
                    nRoi = size(allRoi,1);
                    % Delete the existing mask and replace it
                    app.patchMask = [];
                    delete(findobj(app.UIAxesDIC, 'Type', 'Patch'));
                    delete(findobj(app.UIAxesMovie, 'Type', 'Patch'));
                    for r=1:nRoi
                        if strcmp(app.options.RoiShape, 'Square')
                            tempRoi = [allRoi(r,:) - app.options.RoiSize; allRoi(r,:) + app.options.RoiSize];
                            roiX = [tempRoi(1,1) tempRoi(2,1) tempRoi(2,1) tempRoi(1,1)];
                            roiY = [tempRoi(1,2) tempRoi(1,2) tempRoi(2,2) tempRoi(2,2)];
                        else
                            t = linspace(0, 2*pi);
                            roiX = allRoi(r,1) + app.options.RoiSize * cos(t);
                            roiY = allRoi(r,2) + app.options.RoiSize * sin(t);
                        end
                        hPatch(r) = patch(app.UIAxesDIC, roiX, roiY, app.keepColor(1,:), 'EdgeColor', app.keepColor(4,:),'FaceColor', 'none', 'HitTest', 'off');
                    end
                    app.patchMask = hPatch';
                    copyobj(app.patchMask, app.UIAxesMovie)
                    % Load the new data
                    % Store that we are done
                    app.changeROI = false;
                case 'Import'
                    
            end
            app.newChange = true;
        end
        
        function detectSpikes(app, event)
            warning('off', 'all');
            % Get where to detect the events
            switch app.DetectionButtonGroup.SelectedObject.Text
                case 'All FOVs'
                    imgIdx = find(~cellfun(@isempty, app.imgT.FF0Intensity));
                case 'Current List'
                    expID = app.dicT{contains(app.dicT.CellID, app.DropDownDIC.Value), 'ExperimentID'};
                    imgIdx = find(~cellfun(@isempty, app.imgT.FF0Intensity) & contains(app.imgT.ExperimentID, expID));
                otherwise
                    imgIdx = find(contains(app.imgT.CellID, app.DropDownTimelapse.Value));
            end
            hWait = waitbar(0, 'Detecting spike in data');
            for idx = imgIdx'
                waitbar(idx/numel(imgIdx), hWait, sprintf('Detecting spike in data %0.2f%%', idx/numel(imgIdx)*100));
                % Gather the image data
                tempData = cell2mat(app.imgT{idx, 'DetrendData'});
                if strcmp(app.DetectionButtonGroup.SelectedObject.Text, 'Selected Trace')
                    cellN = app.CellNumberEditField.Value;
                    tempData = tempData(cellN,:);
                end
                [nTraces, nFrames] = size(tempData);
                Fs = app.imgT.ImgProperties(idx,4);
                % Check if the traces need modifications
                switch app.options.DetectTrace
                    case 'Raw'
                        useData = tempData;
                    case 'Gradient'
                        useData = gradient(tempData);
                    case 'Smooth'
                        useData = wdenoise(tempData', 'DenoisingMethod', 'BlockJS')'; % wdenoise only works on colums so inverted twice
                end
                % Get the parameters
                spikeInts = cell(nTraces, 1);
                spikeLocs = cell(nTraces, 1);
                spikeWidths = cell(nTraces, 1);
                spikeRaster = nan(nTraces, nFrames);
                spikeProm = app.options.PeakMinProminance;
                spikeDist = app.options.PeakMinDistance / Fs;
                spikeMinLeng = app.options.PeakMinDuration / Fs;
                spikeMaxLeng = app.options.PeakMaxDuration / Fs;
                % Select the threshold method
                switch app.options.PeakMinHeight
                    case 'MAD'
                        spikeThr = median(useData,2) + mad(useData,0,2) * app.options.SigmaThr;
                    case 'Normalized MAD'
                        spikeThr = median(useData,2) + mad(useData,0,2) * app.options.SigmaThr * (-1 / (sqrt(2) * erfcinv(3/2)));
                    case 'Rolling StDev'
                        winSize = spikeMaxLeng + spikeDist;
                        tempMean = movmean(useData, winSize, 2);
                        tempStDev = std(diff(useData,[],2),[],2);
                        spikeThr = tempMean + (app.options.SigmaThr*tempStDev);
                end
                % Use the find peak to detect the events
                for trace = 1:nTraces
                    [spikeInts{trace,1}, spikeLocs{trace,1}, spikeWidths{trace,1}] = findpeaks(useData(trace,:), Fs, 'MinPeakDistance', spikeDist, ...
                        'MinPeakHeight', spikeThr(trace), 'MinPeakProminence', spikeProm, 'MinPeakWidth', spikeMinLeng, 'MaxPeakWidth', spikeMaxLeng);
                end
                % Add the data according to where it needed to be detected
                if strcmp(app.DetectionButtonGroup.SelectedObject.Text, 'Selected Trace')
                    app.imgT.SpikeLocations{idx}(cellN) = spikeLocs;
                    app.imgT.SpikeIntensities{idx}(cellN) = spikeInts;
                    app.imgT.SpikeWidths{idx}(cellN) = spikeWidths;
                else
                    app.imgT.SpikeLocations{idx} = spikeLocs;
                    app.imgT.SpikeIntensities{idx} = spikeInts;
                    app.imgT.SpikeWidths{idx} = spikeWidths;
                end
            end
            % Add a raster plot
            %             spikeRaster = spikeRaster .* repmat((1:nTraces)', 1, nFrames);
            %             app.imgT.SpikeRaster{imgIdx} = spikeRaster;
            delete(hWait)
            app.newChange = true;
            updatePlot(app);
            toggleInteractions(app, 'Quantification');
        end
        
        function QuantifySpikes(app)
            warning('off', 'all');
            % Get where to detect the events
            switch app.DetectionButtonGroup.SelectedObject.Text
                case 'All FOVs'
                    imgIdx = find(~cellfun(@isempty, app.imgT.FF0Intensity));
                case 'Current List'
                    expID = app.dicT{contains(app.dicT.CellID, app.DropDownDIC.Value), 'ExperimentID'};
                    imgIdx = find(~cellfun(@isempty, app.imgT.FF0Intensity) & contains(app.imgT.ExperimentID, expID));
                otherwise
                    imgIdx = find(contains(app.imgT.CellID, app.DropDownTimelapse.Value));
            end
            hWait = waitbar(0, 'Detecting spike in data');
            for idx = imgIdx'
                waitbar(idx/numel(imgIdx), hWait, sprintf('Detecting spike in data %0.2f%%', idx/numel(imgIdx)*100));
                % Gather the important data
                Fs = app.imgT.ImgProperties(idx,4);
                tempData = app.imgT.DetrendData{idx};
                [nCell, nFrames] = size(tempData);
                tempLoc = cellfun(@(x) round(x * Fs), app.imgT.SpikeLocations{idx}, 'UniformOutput', false);
                tempInt = cell2mat(app.imgT.SpikeIntensities{idx}');
                tempWid = cell2mat(app.imgT.SpikeWidths{idx}');
                qcd = @(x) (quantile(x, .75) - quantile(x, .25)) / (quantile(x, .75) + quantile(x, .25));
                % Calculate the spike frequency for single cell, and the proportion of silent cells
                totTime = (nFrames-1) / Fs;
                cellFreq = cellfun(@(x) numel(x) / totTime * 60, tempLoc);
                silentCells = sum(cellFreq==0) / nCell * 100;
                % Create a raster plot
                tempRast = nan(nCell, nFrames);
                for c = 1:nCell
                    sStart = tempLoc{c};
                    for s = 1:numel(sStart)
                        tempRast(c,sStart(s):sStart(s)+app.options.PeakMinDuration) = c;
                    end
                end
                % Calculate the network event with gaussian smoothing of the sum of the raster (similar to EvA)
                networkRaster = tempRast;
                networkRaster(~isnan(networkRaster)) = 1;
                networkRaster(isnan(networkRaster)) = 0;
                networkRaster = sum(networkRaster);
                %smoothWindow = gausswin(10);
                %smoothWindow = smoothWindow / sum(smoothWindow);
                %networkRaster = filter(smoothWindow, 1, networkRaster);
                [networkPeaks, networkLocs, networkFWHM] = findpeaks(networkRaster, Fs, 'WidthReference', 'halfheight');
                % Calculate the network frequency as the number of spikes that have > 80% of neurons firing
                netThreshold = floor(sum(cellFreq>0) * 0.8);
                networkFreq = sum(networkPeaks >= netThreshold) / totTime * 60;
                % Calculate the average synchronicity
                syncMean = mean(networkPeaks) / sum(cellFreq>0) * 100;
                syncMedian = median(networkPeaks) / sum(cellFreq>0) * 100;
                % Add the data according to where it needed to be detected
                app.imgT.SpikeRaster{idx} = tempRast;
                app.imgT.NetworkRaster{idx} = networkRaster;
                app.imgT.CellFrequency{idx} = cellFreq;
                app.imgT.MeanFrequency(idx) = mean(cellFreq(cellFreq>0));
                app.imgT.MedianFrequency(idx) = median(cellFreq(cellFreq>0));
                app.imgT.CoVFrequency(idx) = std(cellFreq(cellFreq>0)) / mean(cellFreq(cellFreq>0));
                app.imgT.QCDFrequency(idx) = qcd(cellFreq(cellFreq>0));
                app.imgT.SilentCells(idx) = silentCells;
                app.imgT.NetworkFrequency(idx) = networkFreq;
                app.imgT.Synchronicity(idx) = syncMean;
                app.imgT.Synchronicity2(idx) = syncMedian;
                app.imgT.CoVSynchronicity(idx) = std(networkPeaks) / mean(networkPeaks);
                app.imgT.QCDSynchronicity(idx) = qcd(networkPeaks);
                % Calculate the average intensity and duration of the events (not yet taking into account manually added events)
                app.imgT.MeanIntensity(idx) = mean(tempInt);
                app.imgT.MedianIntensity(idx) = median(tempInt);
                app.imgT.CoVIntensity(idx) = std(tempInt) / mean(tempInt);
                app.imgT.QCDIntensity(idx) = qcd(tempInt);
                app.imgT.MeanDuration(idx) = mean(tempWid);
                app.imgT.MedianDuration(idx) = median(tempWid);
                app.imgT.CoVDuration(idx) = std(tempWid) / mean(tempWid);
                app.imgT.QCDDuration(idx) = qcd(tempWid);
            end
            delete(hWait);
        end
    end
    
    % Plotting methods
    methods
        function changePlotType(app, event)
            switch event.NewValue.Text
                case 'Single Trace'
                    toggleInteractions(app, 'SinglePlot')
                otherwise
                    toggleInteractions(app, 'MeanPlot')
            end
            updatePlot(app)
        end
        
        function changePlotTrace(app, event)
            % First identify in which FOV we are and get the number of ROIs
            tempCell = contains(app.imgT.CellID, app.DropDownTimelapse.Value);
            nRoi = size(app.imgT.DetrendData{tempCell}, 1);
            if strcmp(event.EventName, 'ButtonPushed')
                
                % if + or - were pressed, make sure to stay in the range of available ROIs
                if strcmp(event.Source.Text, '+')
                    app.CellNumberEditField.Value = min(app.CellNumberEditField.Value + 1, nRoi);
                else
                    app.CellNumberEditField.Value = max(app.CellNumberEditField.Value - 1, 1);
                end
            else
                % double check that the entered value is between the number of ROIs
                if app.CellNumberEditField.Value > nRoi
                    warndlg(sprintf('Please, enter a number between 1 and %d', nRoi), 'Index excideed number of ROIs');
                    app.CellNumberEditField.Value = nRoi;
                end
            end
            updatePlot(app);
        end
        
        function updatePlot(app)
            % simple function for now
            tempCell = contains(app.imgT.CellID, app.DropDownTimelapse.Value);
            if ~isempty(app.imgT.DetrendData{tempCell})
                tempData = app.imgT.DetrendData{tempCell};
                Fs = app.imgT.ImgProperties(tempCell,4);
                time = (0:size(tempData, 2)-1) / Fs;
                cla(app.UIAxesPlot);
                switch app.PlotTypeButtonGroup.SelectedObject.Text
                    case 'All And Mean'
                        hold(app.UIAxesPlot, 'on')
                        % Before plotting anything, try to plot the spikes
                        hLeg(1) = plot(app.UIAxesPlot, time, tempData(1,:), 'Color', [.7 .7 .7], 'HitTest', 'off', 'ButtonDownFcn', '');
                        plot(app.UIAxesPlot, time, tempData(2:end,:), 'Color', [.7 .7 .7], 'HitTest', 'off', 'ButtonDownFcn', '');
                        hLeg(2) = plot(app.UIAxesPlot, time, mean(tempData), 'Color', 'r', 'HitTest', 'off', 'ButtonDownFcn', '');
                        app.UIAxesPlot.XLim = [time(1) time(end)];
                        if ~isempty(app.imgT.SpikeLocations{tempCell})
                            spikeLoc = app.imgT.SpikeLocations{tempCell};
                            for c = 1:numel(spikeLoc)
                                tempSpike = spikeLoc{c};
                                xPatch = [];
                                xPatch([1 4],:) = ones(2,1) * (tempSpike - 0.1);
                                xPatch([2 3],:) = ones(2,1) * (tempSpike + 0.1);
                                yPatch = repmat(repelem(app.UIAxesPlot.YLim,2)', 1, numel(tempSpike));
                                patch(app.UIAxesPlot, xPatch, yPatch, [.0 .8 .8], 'EdgeColor', 'none', 'FaceAlpha', .1, 'HitTest', 'off', 'ButtonDownFcn', '');
                            end
                        end
                        legend(app.UIAxesPlot, hLeg, {'All' 'Mean'}, 'Location', 'best', 'box', 'off')
                    otherwise
                        % plot one trace and the identified spikes
                        cellN = app.CellNumberEditField.Value;
                        hold(app.UIAxesPlot, 'off')
                        plot(app.UIAxesPlot, time, tempData(cellN,:), 'Color', 'k', 'HitTest', 'off', 'ButtonDownFcn', '');
                        legend(app.UIAxesPlot, 'off');
                        hold(app.UIAxesPlot, 'on')
                        if ~isempty(app.imgT.SpikeLocations{tempCell})
                            spikeLoc = app.imgT.SpikeLocations{tempCell}{cellN};
                            spikeInt = tempData(cellN, round(spikeLoc*Fs)+1);
                            % spikeInt = app.imgT.SpikeIntensities{imgID}{cellN};
                            plot(app.UIAxesPlot, spikeLoc, spikeInt, 'or', 'HitTest', 'off', 'ButtonDownFcn', '')
                        end
                        % Add the level of the threshold
                        switch app.options.PeakMinHeight
                            case 'MAD'
                                spikeThr = median(tempData(cellN,:)) + mad(tempData(cellN,:)) * app.options.SigmaThr;
                                plot(app.UIAxesPlot, app.UIAxesPlot.XLim, [spikeThr spikeThr], ':b', 'HitTest', 'off', 'ButtonDownFcn', '')
                            case 'Normalized MAD'
                                spikeThr = median(tempData(cellN,:)) + mad(tempData(cellN,:)) * app.options.SigmaThr * (-1 / (sqrt(2) * erfcinv(3/2)));
                                plot(app.UIAxesPlot, app.UIAxesPlot.XLim, [spikeThr spikeThr], ':b', 'HitTest', 'off', 'ButtonDownFcn', '')
                            case 'Rolling StDev'
                                winSize = (app.options.PeakMaxDuration / Fs) + (app.options.PeakMinDistance / Fs);
                                tempMean = movmean(tempData(cellN,:), winSize, 2);
                                tempStDev = std(diff(tempData(cellN,:),[],2),[],2);
                                spikeThr = tempMean + (app.options.SigmaThr*tempStDev);
                                plot(app.UIAxesPlot, time, spikeThr, ':b', 'HitTest', 'off', 'ButtonDownFcn', '')
                        end
                end
            end
        end
    end
    
    
    % Housekeeping methods
    methods
        function togglePointer(app)
            if strcmp(app.UIFigure.Pointer, 'arrow')
                app.UIFigure.Pointer = 'watch';
            else
                app.UIFigure.Pointer = 'arrow';
            end
            drawnow();
        end
        
        function toggleInteractions(app, toggleCase)
            switch toggleCase
                case 'Startup'
                    app.StillConditionEditField.Enable = 'on';
                    app.MicroscopeDropDown.Enable = 'on';
                    app.FrequencyEditField.Enable = 'on';
                    app.SaveButton.Enable = 'on';
                    app.CancelButton.Enable = 'on';
                    app.DefaultButton.Enable = 'on';
                case 'Loaded'
                    app.DropDownDIC.Enable = 'on';
                    app.ButtonNextRecording.Enable = 'on';
                    app.ButtonPreviousRecording.Enable = 'on';
                    app.DetectROIsButton.Enable = 'on';
                    app.ImportROIsButton.Enable = 'on';
                    app.AddROIsButton.Enable = 'on';
                    app.DeleteROIsButton.Enable = 'on';
                    app.DropDownTimelapse.Enable = 'on';
                    app.ShowFrameButton.Enable = 'on';
                    app.ShowStDevButton.Enable = 'on';
                    app.ShowMovieButton.Enable = 'on';
                    app.ROIShapeDropDown.Enable = 'on';
                    app.ROISizepxsEditField.Enable = 'on';
                    app.RegistrationCheckBox.Enable = 'on';
                    app.ReferenceConditionEditField.Enable = 'on';
                    app.ZoomXButton.Enable = 'on';
                    app.ZoomXMin.Enable = 'on';
                    app.ZoomXMax.Enable = 'on';
                    app.FixYAxisButton.Enable = 'on';
                    if app.nChannel > 1
                        app.DICChannels.Visible = 'on';
                    end
                case 'ROIs'
                    app.AllAndMeanButton.Enable = 'on';
                    app.SingleTraceButton.Enable = 'on';
                    app.ButtonNextCell.Enable = 'on';
                    app.CellNumberEditField.Enable = 'on';
                    app.ButtonPreviousCell.Enable = 'on';
                    app.ShowRawButton.Enable = 'on';
                case 'Detection'
                    app.MethodDropDown.Enable = 'on';
                    app.ThresholdEditField.Enable = 'on';
                    app.MinProminanceEditField.Enable = 'on';
                    app.MinDistanceframesEditField.Enable = 'on';
                    app.MinDurationframesEditField.Enable = 'on';
                    app.MaxDurationframesEditField.Enable = 'on';
                    app.TraceToUseDropDown.Enable = 'on';
                    app.DetrendingMethodDropDown.Enable = 'on';
                    app.DetrendWindowfrEditField.Enable = 'on';
                    app.AllFOVsButton.Enable = 'on';
                    app.CurrentListButton.Enable = 'on';
                    app.SelectedFOVButton.Enable = 'on';
                    app.SelectedTraceButton.Enable = 'on';
                    app.DetectButton.Enable = 'on';
                    app.AllAndMeanButton.Enable = 'on';
                    app.SingleTraceButton.Enable = 'on';
                case 'SinglePlot'
                    app.ButtonNextCell.Enable = 'on';
                    app.CellNumberEditField.Enable = 'on';
                    app.ButtonPreviousCell.Enable = 'on';
                case 'MeanPlot'
                    app.ButtonNextCell.Enable = 'off';
                    app.CellNumberEditField.Enable = 'off';
                    app.ButtonPreviousCell.Enable = 'off';
                case 'Quantification'
                    app.QuantifyButton.Enable = 'on';
                    app.AddPeakButton.Enable = 'on';
                    app.RemovePeakButton.Enable = 'on';
                    app.LabelPeakButton.Enable = 'on';
                    app.LabelFeatButton.Enable = 'on';
                    app.ExporttraceButton.Enable = 'on';
            end
        end
        
        function updateDropDownDIC(app)
            % Get the list of unique DIC IDs
            dicIDs = unique(app.dicT.CellID);
            app.DropDownDIC.Items = dicIDs;
            app.DropDownDIC.Value = app.DropDownDIC.Items(contains(app.DropDownDIC.Items, app.currDIC));
        end
        
        function updateDropDownTimelapse(app)
            % Get the list of unique DIC IDs
            expID = app.dicT{contains(app.dicT.CellID, app.DropDownDIC.Value), 'ExperimentID'};
            timelapseID = unique(app.imgT{contains(app.imgT.ExperimentID, expID), 'CellID'});
            app.DropDownTimelapse.Items = timelapseID;
            app.DropDownTimelapse.Value = app.DropDownTimelapse.Items(1);
        end
        
        function updateDIC(app)
            togglePointer(app)
            cla(app.UIAxesDIC);
            app.UIAxesDIC.Visible = 'on';
            % Check which image we need to show
            whatDIC = contains(app.dicT.CellID, app.currDIC);
            cellRoi = [];
            showC = str2double(app.DICChannels.SelectedObject.Text(end));
            if sum(whatDIC) == 1
                dicImg = app.dicT.RawImage{whatDIC};
                image(dicImg(:,:,showC), 'Parent', app.UIAxesDIC, 'HitTest', 'off');
                colormap(app.UIAxesDIC, gray)
            else
                dicFile = app.dicT.Filename(contains(app.dicT.Filename, app.currDIC));
                dicImg = imread(dicFile{:});
            end
            app.UIAxesDIC.XLim = [0 size(dicImg, 1)]; app.UIAxesDIC.XTick = [];
            app.UIAxesDIC.YLim = [0 size(dicImg, 2)]; app.UIAxesDIC.YTick = [];
            if ~isempty(app.dicT.RoiSet{whatDIC})
                modifyROIs(app, 'Modify');
                updatePlot(app);
                %cla(app.UIAxesPlot);
            else
                app.patchMask = [];
                cla(app.UIAxesPlot);
            end
            togglePointer(app)
        end
        
        function updateTimelapse(app, imgType, imgShow)
            app.UIAxesMovie.Visible = 'on';
            % check what we need to plot
            switch imgType
                case 'Frame'
                    image(imgShow, 'Parent', app.UIAxesMovie);
                    colormap(app.UIAxesMovie, gray)
                    app.UIAxesMovie.XLim = [0 size(imgShow, 1)];app.UIAxesMovie.XTick = [];
                    app.UIAxesMovie.YLim = [0 size(imgShow, 2)];app.UIAxesMovie.YTick = [];
                case 'StDev'
                    imshow(imgShow, [min(imgShow,[],'all') max(imgShow,[],'all')], 'Parent', app.UIAxesMovie);
                    colormap(app.UIAxesMovie, hot)
                    app.UIAxesMovie.Title = [];
                    app.UIAxesMovie.XLim = [0 size(imgShow, 1)];app.UIAxesMovie.XTick = [];
                    app.UIAxesMovie.YLim = [0 size(imgShow, 2)];app.UIAxesMovie.YTick = [];
                case 'Movie'
            end
        end
        
        function imgStack = loadTiff(app, imgIdx, addWait)
            imgFile = app.imgT.Filename{imgIdx};
            imgInfo = app.imgT.ImgProperties(imgIdx,:);
            imgWidth = imgInfo(1);
            imgHeight = imgInfo(2);
            imgNumber = imgInfo(3);
            imgStack = zeros(imgHeight, imgWidth, imgNumber, 'uint16');
            imgStackID = fopen(imgFile, 'r');
            tstack = Tiff(imgFile);
            imgStack(:,:,1) = tstack.read();
            if addWait
                hWait = helpdlg('Loading image without progress. It''s faster!');
            end
            imgStack(:,:,1) = tstack.read();
            for n = 2:imgNumber
                nextDirectory(tstack);
                imgStack(:,:,n) = tstack.read();
            end
            fclose(imgStackID);
            if addWait
                delete(hWait)
            end
        end
        
        function getIntensity(app)
            % First get the image where to run the analysis
            warning('off', 'all');
            togglePointer(app);
            tempDIC = contains(app.dicT.CellID, app.DropDownDIC.Value);
            tempExp = app.dicT.ExperimentID{tempDIC};
            tempRoi = app.dicT.RoiSet{tempDIC};
            % Then load the each stack from this DIC
            imgFltr = find(contains(app.imgT.ExperimentID, tempExp));
            nImages = numel(imgFltr);
            hWait = waitbar(0, 'Loading image...');
            loadTime = 100;
            for i = 1:nImages
                waitbar(i/nImages, hWait, sprintf('Loading data (Remaining time ~%0.2f s)', (nImages-i+1)*loadTime));
                tic
                imgData = loadTiff(app, imgFltr(i), 0);
                nFrames = size(imgData, 3);
                % Get the Z profile of the ROIs
                nRoi = size(tempRoi,1);
                roiIntensities = zeros(nRoi, nFrames);
                for roi = 1:nRoi
                    currRoi = [tempRoi(roi,:) - app.options.RoiSize tempRoi(roi,:) + app.options.RoiSize];
                    % Check the ROI is inside the image
                    currRoi(1) = max(currRoi(1), 1);
                    currRoi(2) = max(currRoi(2), 1);
                    currRoi(3) = min(currRoi(3), size(imgData,1));
                    currRoi(4) = min(currRoi(4), size(imgData,1));
                    % For the image to be correct in ImageJ, column 1 = Y column 2 = X, then consider that ImageJ starts at 0
                    roiIntensities(roi,:) = mean(imgData(currRoi(2):currRoi(4), currRoi(1):currRoi(3), :), [1 2]);
                end
                % Detect the minimum intensity in 10 region of the recordings to calculate the deltaF/F0
                frameDividers = [1:round(nFrames / 10):nFrames, nFrames];
                minVals = zeros(nRoi, 10);
                minIdxs = zeros(nRoi, 10);
                for idx = 1:10
                    [minVals(:,idx), minIdxs(:,idx)] = min(roiIntensities(:,frameDividers(idx):frameDividers(idx+1)), [], 2);
                end
                baseInts = mean(minVals,2);
                deltaff0Ints = (roiIntensities - repmat(baseInts, 1, nFrames)) ./ repmat(baseInts, 1, nFrames);
                app.imgT(imgFltr(i), 'RawIntensity') = {roiIntensities};
                app.imgT(imgFltr(i), 'FF0Intensity') = {deltaff0Ints};
                app.imgT(imgFltr(i), 'DetrendData') = {deltaff0Ints};
                loadTime = toc;
            end
%             detrendData(app)
            delete(hWait);
            togglePointer(app);
            warning('on', 'all');
        end
        
        function detrendData(app)
            imgFltr = find(~cellfun(@isempty, app.imgT.FF0Intensity));
            nImages = numel(imgFltr);
            tempDetrend = cell(nImages,1);
            for i = 1:nImages
                tempData = app.imgT{imgFltr(i), 'FF0Intensity'}{:};
                switch app.options.Detrending
                    case 'None'
                        tempDetrend{i,1} = tempData;
                    case 'Mov Median'
                        fitData = movmedian(tempData, [0.2*app.options.DetrendSize 0.8*app.options.DetrendSize], 2);
                        tempDetrend{i,1} = tempData - fitData;
                    case 'Mov Mean'
                        fitData = movmean(tempData, [0.2*app.options.DetrendSize 0.8*app.options.DetrendSize], 2);
                        tempDetrend{i,1} = tempData - fitData;
                    case 'Gaussian'
                        Fs = app.imgT{imgFltr(i), 'ImgProperties'}(4);
                        nRoi = size(tempData,1);
                        gaussData = zeros(size(tempData));
                        for r=1:nRoi
                            lowPass = gaussianFilter(app, tempData(r,:), Fs, (Fs / 2)); % due to Nyquist the max frequency is 1/2 of Fs
                            highPass = gaussianFilter(app, lowPass, Fs, app.options.DetrendSize); % high pass filter
                            gaussData(r,:) = lowPass - highPass;
                        end
                        tempDetrend{i,1} = gaussData;
                end
            end
            app.imgT{imgFltr, 'DetrendData'} = tempDetrend;
        end
        
        function filteredData = gaussianFilter(app, rawData, sampfreq, cornerfreq)
            fc = cornerfreq/sampfreq;
            sigma = 0.132505/fc;
            nc = round(4*sigma);
            coeffs = -nc:nc;
            coeffs = exp((-coeffs.^2)/(2*sigma^2))/(sqrt(2*pi)*sigma);
            filteredData = conv(rawData,coeffs);
            filteredData = filteredData(nc+1:end-nc);
        end
    end
    
    % Component initialization
    methods (Access = private)
        function createComponents(app)
            
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 1485 1000], 'Name', 'sCaSpA: Spontaneous Calcium Spikes Analysis');
            % Create the file menu
            app.FileMenu = uimenu(app.UIFigure, 'Text', 'File');
            app.FileMenuOpen = uimenu(app.FileMenu, 'Text', 'Load new data',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileMenuOpenSelected, false));
            app.FileMenuLoad = uimenu(app.FileMenu, 'Text', 'Open saved data',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileMenuLoadSelected, false));
            app.FileMenuSave = uimenu(app.FileMenu, 'Text', 'Save',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileMenuSaveSelected, false));
            app.FileMenuLabelCondition = uimenu(app.FileMenu, 'Text', 'Label condition', 'Separator', 'on',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileLabelConditionSelected, false));
            app.FileMenuExport = uimenu(app.FileMenu, 'Text', 'Export',...
                'MenuSelectedFcn', createCallbackFcn(app, @FileMenuExportSelected, false),...
                'Enable', 'off');
            app.FileMenuDebug = uimenu(app.FileMenu, 'Text', 'Debug', 'Separator', 'on',...
                'MenuSelectedFcn', createCallbackFcn(app, @OptionMenuDebugSelected, false));
            % Create image interaction panels
            app.DropDownDIC = uidropdown(app.UIFigure, 'Items', {}, 'Placeholder', 'Recording_ID', 'Position', [15 964 200 22], 'Value',  {}, 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @SelectedDIC, false));
            app.ButtonNextRecording = uibutton(app.UIFigure, 'push', 'Position', [245 964 25 22], 'Text', '>', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @ChangeRecordingPressed, true));
            app.ButtonPreviousRecording = uibutton(app.UIFigure, 'push', 'Position', [224 964 22 22], 'Text', '<', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @ChangeRecordingPressed, true));
            app.DetectROIsButton = uibutton(app.UIFigure, 'push', 'Text', 'Detect ROIs', 'Position', [283 964 100 22], 'Enable', 'off');
            app.ImportROIsButton = uibutton(app.UIFigure, 'push', 'Text', 'Import ROIs', 'Position', [384 964 100 22], 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @ImportROIs, false));
            app.AddROIsButton = uibutton(app.UIFigure, 'state', 'Text', 'Add ROIs', 'Position', [485 964 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @crosshairDIC, true));
            app.DeleteROIsButton = uibutton(app.UIFigure, 'state', 'Text', 'Delete ROIs', 'Position', [586 964 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @crosshairDIC, true));
            app.DropDownTimelapse = uidropdown(app.UIFigure, 'Items', {}, 'Placeholder', 'Timelapse_ID', 'Position', [704 964 200 22], 'Value',  {}, 'Enable', 'off');
            app.ShowFrameButton = uibutton(app.UIFigure, 'state', 'Text', 'Show Frame', 'Position', [913 964 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @ShowTimelapseChanged, true));
            app.ShowStDevButton = uibutton(app.UIFigure, 'state', 'Text', 'Show StDev', 'Position', [1015 964 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @ShowTimelapseChanged, true));
            app.ShowMovieButton = uibutton(app.UIFigure, 'state', 'Text', 'Show Movie', 'Position', [1115 964 100 22], 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @ShowTimelapseChanged, true));
            % Create the axis to keep the images
            app.UIAxesDIC = uiaxes(app.UIFigure, 'Position', [16 451 500 500], 'ButtonDownFcn', createCallbackFcn(app, @DetectClickDIC, true));
            title(app.UIAxesDIC, 'DIC title', 'Visible', 'off')
            app.UIAxesDIC.Toolbar.Visible = 'off';
            app.DICChannels = uibuttongroup(app.UIFigure, 'Position', [50 435 170 15], 'Visible', 'off', 'SelectionChangedFcn', createCallbackFcn(app, @updateDIC, false));
            app.DICCh1 = uitogglebutton(app.DICChannels, 'Text', 'Ch1', 'Position', [2 2 50 10]);
            app.DICCh2 = uitogglebutton(app.DICChannels, 'Text', 'Ch2', 'Position', [60 2 50 10]);
            app.DICCh3 = uitogglebutton(app.DICChannels, 'Text', 'Ch3', 'Position', [118 2 50 10]);
            app.UIAxesMovie = uiaxes(app.UIFigure, 'Position', [517 451 500 500]); title(app.UIAxesMovie, 'Movie title', 'Visible', 'off')
            app.UIAxesMovie.Toolbar.Visible = 'off';
            app.SliderMovie = uislider(app.UIFigure, 'MajorTicks', [], 'MinorTicks', [], 'Position', [553 453 460 3], 'Visible', 'off');
            % Create the axis for the plots
            app.UIAxesPlot = uiaxes(app.UIFigure, 'Position', [15 10 1008 424]);
            title(app.UIAxesPlot, 'Ca^{2+} Trace'); xlabel(app.UIAxesPlot, 'Time (s)'); ylabel(app.UIAxesPlot, '\DeltaF/F_0'); app.UIAxesPlot.TickDir = 'out';
            app.UIAxesPlot.Toolbar.Visible = 'off';
            % Create Network Activity Options Panel
            app.NetworkActivityOptionsPanel = uipanel(app.UIFigure, 'Title', 'Network Activity Options', 'Position', [1022 505 453 423]);
            app.LoadOptionsPanel = uipanel(app.NetworkActivityOptionsPanel, 'Title', 'Load Options', 'Position', [8 274 184 123]);
            app.StillConditionEditFieldLabel = uilabel(app.LoadOptionsPanel, 'Position', [7 73 80 22], 'Text', 'Still Condition');
            app.StillConditionEditField = uieditfield(app.LoadOptionsPanel, 'text', 'Placeholder', app.options.StillCondition, 'Position', [87 73 90 22]);
            app.MicroscopeDropDownLabel = uilabel(app.LoadOptionsPanel, 'Position', [7 42 80 22], 'Text', 'Microscope');
            app.MicroscopeDropDown = uidropdown(app.LoadOptionsPanel, 'Items', {'Nikon A1', 'Nikon Ti2', 'Other'}, 'Position', [87 42 90 22], 'Value',  app.options.Microscope, 'Enable', 'off');
            app.FrequencyEditFieldLabel = uilabel(app.LoadOptionsPanel, 'Position', [6 11 80 22], 'Text', 'Frequency');
            app.FrequencyEditField = uieditfield(app.LoadOptionsPanel, 'numeric', 'Position', [87 11 90 22], 'Value', app.options.Frequency, 'Enable', 'off');
            app.DetectionOptionsPanel = uipanel(app.NetworkActivityOptionsPanel, 'Title', 'Detection Options', 'Position', [203 153 240 244]);
            app.MethodDropDownLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 195 80 22], 'Text', 'Method');
            app.MethodDropDown = uidropdown(app.DetectionOptionsPanel, 'Items', {'MAD', 'Normalized MAD', 'Rolling St. Dev.'}, 'Position', [142 195 90 22], 'Value',  app.options.PeakMinHeight, 'Enable', 'off');
            app.ThresholdEditFieldLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 164 80 22], 'Text', 'Threshold');
            app.ThresholdEditField = uieditfield(app.DetectionOptionsPanel, 'numeric', 'Position', [142 164 90 22], 'Enable', 'off', 'Value', app.options.SigmaThr);
            app.MinProminanceEditFieldLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 132 92 22], 'Text', 'Min Prominance');
            app.MinProminanceEditField = uieditfield(app.DetectionOptionsPanel, 'numeric', 'Position', [142 132 90 22], 'Enable', 'off', 'Value', app.options.PeakMinProminance);
            app.MinDistanceframesEditFieldLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 100 123 22], 'Text', 'Min Distance (frames)');
            app.MinDistanceframesEditField = uieditfield(app.DetectionOptionsPanel, 'numeric', 'Position', [142 100 90 22], 'Enable', 'off', 'Value', app.options.PeakMinDistance);
            app.MinDurationframesEditFieldLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 68 118 22], 'Text', 'Min Duration (frames)');
            app.MinDurationframesEditField = uieditfield(app.DetectionOptionsPanel, 'numeric', 'Position', [142 68 90 22], 'Enable', 'off', 'Value', app.options.PeakMinDuration);
            app.MaxDurationframesEditFieldLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 35 125 22], 'Text', 'Max Duration (frames)');
            app.MaxDurationframesEditField = uieditfield(app.DetectionOptionsPanel, 'numeric', 'Position', [142 35 90 22], 'Enable', 'off', 'Value', app.options.PeakMaxDuration);
            app.TracetouseDropDownLabel = uilabel(app.DetectionOptionsPanel, 'Position', [8 6 80 22], 'Text', 'Trace to use');
            app.TraceToUseDropDown = uidropdown(app.DetectionOptionsPanel, 'Items', {'Raw', 'Smooth', 'Gradient', ''}, 'Position', [142 6 90 22], 'Value',  app.options.DetectTrace, 'Enable', 'off');
            app.ROIsOptionsPanel = uipanel(app.NetworkActivityOptionsPanel, 'Title', 'ROIs Options', 'Position', [9 153 184 115]);
            app.ROIShapeDropDownLabel = uilabel(app.ROIsOptionsPanel, 'Position', [8 34 80 22], 'Text', 'ROI Shape');
            app.ROIShapeDropDown = uidropdown(app.ROIsOptionsPanel, 'Items', {'Square', 'Circle'}, 'Position', [87 34 90 22], 'Value',  app.options.RoiShape, 'Enable', 'off', ...
                'ValueChangedFcn', createCallbackFcn(app, @ChangedROI, false));
            app.ROISizepxsEditFieldLabel = uilabel(app.ROIsOptionsPanel, 'Position', [8 64 84 22], 'Text', 'ROI Size (pxs)');
            app.ROISizepxsEditField = uieditfield(app.ROIsOptionsPanel, 'numeric', 'Position', [89 64 90 22], 'Value',  app.options.RoiSize, 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @ChangedROI, false));
            app.RegistrationOptionsPanel = uipanel(app.NetworkActivityOptionsPanel, 'Title', 'Registration Options', 'Position', [10 40 184 104]);
            app.RegistrationCheckBox = uicheckbox(app.RegistrationOptionsPanel, 'Text', 'Registration', 'Position', [9 54 86 22], 'Enable', 'off', 'Value', app.options.Registration);
            app.ReferenceConditionLabel = uilabel(app.RegistrationOptionsPanel, 'Position', [8 29 118 22], 'Text', 'Reference Condition:');
            app.ReferenceConditionEditField = uieditfield(app.RegistrationOptionsPanel, 'text', 'Value', app.options.Reference, 'Position', [9 8 118 22], 'Enable', 'off');
            app.DetrendingOptionsPanel = uipanel(app.NetworkActivityOptionsPanel, 'Title', 'Detrending Options', 'Position', [204 40 239 104]);
            app.DetrendingMethodDropDownLabel = uilabel(app.DetrendingOptionsPanel, 'Position', [8 53 108 22], 'Text', 'Detrending Method');
            app.DetrendingMethodDropDown = uidropdown(app.DetrendingOptionsPanel, 'Items', {'None', 'Mov Median', 'Mov Mean', 'Gaussian'}, 'Position', [138 53 90 22], 'Value', app.options.Detrending, 'Enable', 'off');
            app.DetrendWindowfrEditFieldLabel = uilabel(app.DetrendingOptionsPanel, 'Position', [8 25 113 22], 'Text', 'Detrend Window (fr)');
            app.DetrendWindowfrEditField = uieditfield(app.DetrendingOptionsPanel, 'numeric', 'Position', [138 25 90 22], 'Value',  app.options.DetrendSize, 'Enable', 'off');
            app.SaveButton = uibutton(app.NetworkActivityOptionsPanel, 'push', 'Position', [65 8 100 22], 'Text', 'Save', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @SaveOptions, false));
            app.CancelButton = uibutton(app.NetworkActivityOptionsPanel, 'push', 'Position', [175 8 100 22], 'Text', 'Cancel', 'Enable', 'off');
            app.DefaultButton = uibutton(app.NetworkActivityOptionsPanel, 'push', 'Position', [285 8 100 22], 'Text', 'Default', 'Enable', 'off');
            % Create Spike Detection Panel
            app.SpikeDetectionPanel = uipanel(app.UIFigure, 'Title', 'Spike Detection', 'Position', [1022 411 453 83]);
            app.DetectionButtonGroup = uibuttongroup(app.SpikeDetectionPanel, 'Position', [6 6 207 53]);
            app.AllFOVsButton = uitogglebutton(app.DetectionButtonGroup', 'Text', 'All FOVs', 'Position', [3 26 100 22], 'Value', true, 'Enable', 'off');
            app.CurrentListButton = uitogglebutton(app.DetectionButtonGroup, 'Text', 'Current List', 'Position', [104 26 100 22], 'Enable', 'off');
            app.SelectedFOVButton = uitogglebutton(app.DetectionButtonGroup, 'Text', 'Selected FOV', 'Position', [3 2 100 22], 'Enable', 'off');
            app.SelectedTraceButton = uitogglebutton(app.DetectionButtonGroup, 'Text', 'Selected Trace', 'Position', [104 2 100 22], 'Enable', 'off');
            app.DetectButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [223 31 100 22], 'Text', 'Detect', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @detectSpikes, true));
            app.QuantifyButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [333 31 100 22], 'Text', 'Quantify', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @QuantifySpikes, false));
            app.AddPeakButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [223 8 100 22], 'Text', 'Add Peak', 'Enable', 'off');
            app.RemovePeakButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [332 8 100 22], 'Text', 'Remove Peak', 'Enable', 'off');
            % Create Plot Interaction Panel
            app.PlotInteractionPanel = uipanel(app.UIFigure, 'Title', 'Plot Interaction', 'Position', [1022 280 453 118]);
            app.PlotTypeButtonGroup = uibuttongroup(app.PlotInteractionPanel, 'Title', 'Plot Type', 'Position', [7 8 123 86],...
                'SelectionChangedFcn', createCallbackFcn(app, @changePlotType, true));
            app.AllAndMeanButton = uitogglebutton(app.PlotTypeButtonGroup, 'Text', 'All And Mean', 'Position', [11 33 100 22], 'Value',  true, 'Enable', 'off');
            app.SingleTraceButton = uitogglebutton(app.PlotTypeButtonGroup, 'Text', 'Single Trace', 'Position', [11 12 100 22], 'Enable', 'off');
            app.ZoomXButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [136 72 100 22], 'Text', 'Zoom X', 'Enable', 'off');
            app.ZoomXMin = uieditfield(app.PlotInteractionPanel, 'numeric', 'Position', [236 72 50 22], 'Enable', 'off');
            app.ZoomXMax = uieditfield(app.PlotInteractionPanel, 'numeric', 'Position', [286 72 50 22], 'Enable', 'off');
            app.FixYAxisButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [348 72 100 22], 'Text', 'Fix Y Axis', 'Enable', 'off');
            app.CellNumberLabel = uilabel(app.PlotInteractionPanel, 'Position', [138 40 72 22], 'Text', 'Cell Number');
            app.ButtonNextCell = uibutton(app.PlotInteractionPanel, 'push', 'Position', [288 40 25 22], 'Text', '+', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @changePlotTrace, true));
            app.CellNumberEditField = uieditfield(app.PlotInteractionPanel, 'numeric', 'Limits', [1 Inf], 'Position', [237 40 50 22], 'Value',  1, 'Enable', 'off',...
                'ValueChangedFcn', createCallbackFcn(app, @changePlotTrace, true));
            app.ButtonPreviousCell = uibutton(app.PlotInteractionPanel, 'push', 'Position', [213 40 25 22], 'Text', '-', 'Enable', 'off',...
                'ButtonPushedFcn', createCallbackFcn(app, @changePlotTrace, true));
            app.ShowRawButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [348 40 100 22], 'Text', 'Show raw', 'Enable', 'off');
            app.LabelPeakButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [136 8 100 22], 'Text', 'Label Peak', 'Enable', 'off');
            app.LabelFeatButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [243 8 100 22], 'Text', 'Label Feat.', 'Enable', 'off');
            app.ExporttraceButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [348 8 100 22], 'Text', 'Export trace', 'Enable', 'off');
            % Show the figure after all components are created
            movegui(app.UIFigure, 'center');
            app.UIFigure.Visible = 'on';
        end
        
        function startSettings(app)
            s = settings;
            if ~hasGroup(s, 'sCaSpA')
                % save the settings
                addGroup(s, 'sCaSpA');
                addSetting(s.sCaSpA, 'LastPath', 'PersonalValue', pwd);
                addSetting(s.sCaSpA, 'StillCondition', 'PersonalValue', 'DIC');
                addSetting(s.sCaSpA, 'Microscope', 'PersonalValue', 'Nikon Ti2');
                addSetting(s.sCaSpA, 'Frequency', 'PersonalValue', 8);
                addSetting(s.sCaSpA, 'RoiSize', 'PersonalValue', 5);
                addSetting(s.sCaSpA, 'RoiShape', 'PersonalValue', 'Square');
                addSetting(s.sCaSpA, 'PeakMinHeight', 'PersonalValue', 'MAD');
                addSetting(s.sCaSpA, 'SigmaThr', 'PersonalValue', 2);
                addSetting(s.sCaSpA, 'PeakMinProminance', 'PersonalValue', 0.1);
                addSetting(s.sCaSpA, 'PeakMinDistance', 'PersonalValue', 1);
                addSetting(s.sCaSpA, 'PeakMinDuration', 'PersonalValue', 2);
                addSetting(s.sCaSpA, 'PeakMaxDuration', 'PersonalValue', 5);
                addSetting(s.sCaSpA, 'DetectTrace', 'PersonalValue', 'Raw');
                addSetting(s.sCaSpA, 'Registration', 'PersonalValue', false);
                addSetting(s.sCaSpA, 'Reference', 'PersonalValue', 'Tyrode');
                addSetting(s.sCaSpA, 'Detrending', 'PersonalValue', 'None');
                addSetting(s.sCaSpA, 'DetrendSize', 'PersonalValue', 0);
            end
            app.options.LastPath = s.sCaSpA.LastPath.ActiveValue;
            app.options.StillCondition = s.sCaSpA.StillCondition.ActiveValue;
            app.options.Microscope = s.sCaSpA.Microscope.ActiveValue;
            app.options.Frequency = s.sCaSpA.Frequency.ActiveValue;
            app.options.RoiSize = s.sCaSpA.RoiSize.ActiveValue;
            app.options.RoiShape = s.sCaSpA.RoiShape.ActiveValue;
            app.options.PeakMinHeight = s.sCaSpA.PeakMinHeight.ActiveValue;
            app.options.SigmaThr = s.sCaSpA.SigmaThr.ActiveValue;
            app.options.PeakMinProminance = s.sCaSpA.PeakMinProminance.ActiveValue;
            app.options.PeakMinDistance = s.sCaSpA.PeakMinDistance.ActiveValue;
            app.options.PeakMinDuration = s.sCaSpA.PeakMinDuration.ActiveValue;
            app.options.PeakMaxDuration = s.sCaSpA.PeakMaxDuration.ActiveValue;
            app.options.DetectTrace = s.sCaSpA.DetectTrace.ActiveValue;
            app.options.Registration = s.sCaSpA.Registration.ActiveValue;
            app.options.Reference = s.sCaSpA.Reference.ActiveValue;
            app.options.Detrending = s.sCaSpA.Detrending.ActiveValue;
            app.options.DetrendSize = s.sCaSpA.DetrendSize.ActiveValue;
        end
        
        function saveSettings(app)
            % Before closing save the settings
            s = settings;
            s.sCaSpA.LastPath.PersonalValue = app.options.LastPath;
            s.sCaSpA.StillCondition.PersonalValue = app.options.StillCondition;
            s.sCaSpA.Microscope.PersonalValue = app.options.Microscope;
            s.sCaSpA.Frequency.PersonalValue = app.options.Frequency;
            s.sCaSpA.RoiSize.PersonalValue = app.options.RoiSize;
            s.sCaSpA.RoiShape.PersonalValue = app.options.RoiShape;
            s.sCaSpA.PeakMinHeight.PersonalValue = app.options.PeakMinHeight;
            s.sCaSpA.SigmaThr.PersonalValue = app.options.SigmaThr;
            s.sCaSpA.PeakMinProminance.PersonalValue = app.options.PeakMinProminance;
            s.sCaSpA.PeakMinDistance.PersonalValue = app.options.PeakMinDistance;
            s.sCaSpA.PeakMaxDuration.PersonalValue = app.options.PeakMaxDuration;
            s.sCaSpA.DetectTrace.PersonalValue = app.options.DetectTrace;
            s.sCaSpA.Registration.PersonalValue = app.options.Registration;
            s.sCaSpA.Reference.PersonalValue = app.options.Reference;
            s.sCaSpA.Detrending.PersonalValue = app.options.Detrending;
            s.sCaSpA.DetrendSize.PersonalValue = app.options.DetrendSize;
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = sCaSpA
            startSettings(app);
            % Create UIFigure and components
            createComponents(app)
            toggleInteractions(app, 'Startup');
            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            saveSettings(app);
            if app.newChange
                % If the data is not saved, ask if it needs to be saved
                answer = questdlg('Do you want to save the data?', 'Save before closing');
                switch answer
                    case 'Yes'
                        FileMenuSaveSelected(app);
                    case 'No'
                        % Nothing to add
                    case 'Cancel'
                        return
                end
            end
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end