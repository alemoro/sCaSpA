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
                tempDicImage = cell(size(tempT,1), 1);
                for i = 1:size(tempT,1)
                    waitbar(i/sum(dicFltr), hWait, sprintf('Loading DIC data %0.2f%%', i/sum(dicFltr)*100));
                    dicFile = tempT.Filename{i};
                    tempDicImage{i,1} = imread(dicFile);
                end
                tempT.RawImage = tempDicImage;
                tempT.RoiSet = repmat({[]}, size(tempT,1), 1);
                app.dicT = tempT;
                % Populate the imgT
                imgFltr = ~dicFltr;
                tempT = cell(sum(imgFltr)+1, 14);
                tempT(1,:) = {'Filename', 'CellID', 'Week', 'CoverslipID', 'RecID', 'Condition', 'ExperimentID', 'ImgProperties', 'ImgByteStrip', 'RawIntensity', 'FF0Intensity', 'SpikeLocations', 'SpikeIntensities', 'SpikeWidths'};
                tempT(2:end,1) = fullfile({imgFiles(imgFltr).folder}, {imgFiles(imgFltr).name});
                tempT(2:end,2) = cellfun(@(x) x(1:end-4), {imgFiles(imgFltr).name}, 'UniformOutput', false);
                imgIDs = nameParts(imgFltr);
                % Check the informations on the name. In case there is something wrong, ask the user
                if numel(imgIDs{1}) ~= 4
                    warndlg('name missmatch, but I don''t know what to do');
                end
                for i = 1:sum(imgFltr)
                    waitbar(i/sum(imgFltr), hWait, sprintf('Loading movie data %0.2f%%', i/sum(imgFltr)*100));
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
                
            else
                togglePointer(app)
                return
            end
            togglePointer(app)
        end
        
        function FileMenuLoadSelected(app)
        end
        
        function FileMenuSaveSelected(app)
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
            app.options.Detrending = app.DetrendingMethodDropDown.Value;
            app.options.DetrendSize = app.DetrendWindowfrEditField.Value;
            if app.changeROI
                modifyROIs(app, 'Modify');
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
                if app.UIAxesDIC.XLim(2) == size(app.dicT.RawImage{1},1)
                    % Zoom in
                    zoomPoint = round(event.IntersectionPoint);
                    xMin = max(0, zoomPoint(1) - 50);
                    xMax = min(size(app.dicT.RawImage{1},1), zoomPoint(1) + 50);
                    yMin = max(0, zoomPoint(2) - 50);
                    yMax = min(size(app.dicT.RawImage{1},1), zoomPoint(2) + 50);
                    app.UIAxesDIC.XLim = [xMin xMax];
                    app.UIAxesDIC.YLim = [yMin yMax];
                else
                    % Zoom out
                    app.UIAxesDIC.XLim = [0 size(app.dicT.RawImage{1},1)];
                    app.UIAxesDIC.YLim = [0 size(app.dicT.RawImage{1},1)];
                end
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
                    copyobj(app.patchMask, app.UIAxesMovie)
                    app.patchMask = hPatch';
                    % Load the new data
                    % Store that we are done
                    app.changeROI = false;
            end
        end
    end
    
    % Plotting methods
    methods
        function updatePlot(app)
            % simple function for now
            tempCell = contains(app.imgT.CellID, app.DropDownTimelapse.Value);
            tempData = app.imgT.FF0Intensity{tempCell};
            Fs = app.imgT.ImgProperties(tempCell,4);
            time = (0:size(tempData, 2)-1) / Fs;
            cla(app.UIAxesPlot);
            hLeg(1) = plot(app.UIAxesPlot, time, tempData(1,:), 'Color', [.7 .7 .7]);
            hold(app.UIAxesPlot, 'on')
            plot(app.UIAxesPlot, time, tempData(2:end,:), 'Color', [.7 .7 .7]);
            hLeg(2) = plot(app.UIAxesPlot, time, mean(tempData), 'Color', 'r');
            legend(app.UIAxesPlot, hLeg, {'All' 'Mean'}, 'Location', 'best', 'box', 'off')
            app.UIAxesPlot.XLim = [time(1) time(end)];
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
            app.UIAxesDIC.Visible = 'on';
            % Check which image we need to show
            whatDIC = contains(app.dicT.CellID, app.currDIC);
            cellRoi = [];
            if sum(whatDIC) == 1
                dicImg = app.dicT.RawImage{whatDIC};
                image(dicImg, 'Parent', app.UIAxesDIC, 'HitTest', 'off');
                colormap(app.UIAxesDIC, gray)
                if ~isempty(app.dicT.RoiSet{whatDIC})
                    getCellMask(app, whatDIC, size(dicImg))
                    cellRoi = app.cellsMask;
                end
            else
                dicFile = app.dicT.Filename(contains(app.dicT.Filename, app.currDIC));
                dicImg = imread(dicFile{:});
            end
            app.UIAxesDIC.XLim = [0 size(dicImg, 1)]; app.UIAxesDIC.XTick = [];
            app.UIAxesDIC.YLim = [0 size(dicImg, 2)]; app.UIAxesDIC.YTick = [];
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
                    image(imgShow, [min(imgShow,[],'all') max(imgShow,[],'all')], 'Parent', app.UIAxesMovie);
                    colormap(app.UIAxesMovie, hot)
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
                loadTime = toc;
            end
%             detrendData(app)
            delete(hWait);
            togglePointer(app);
            warning('on', 'all');
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
            app.ImportROIsButton = uibutton(app.UIFigure, 'push', 'Text', 'Import ROIs', 'Position', [384 964 100 22], 'Enable', 'off');
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
            app.StillConditionEditField = uieditfield(app.LoadOptionsPanel, 'text', 'Placeholder', app.options.StillCondition, 'Position', [87 73 90 22], 'Enable', 'off');
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
            app.DetectButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [223 31 100 22], 'Text', 'Detect', 'Enable', 'off');
            app.QuantifyButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [333 31 100 22], 'Text', 'Quantify', 'Enable', 'off');
            app.AddPeakButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [223 8 100 22], 'Text', 'Add Peak', 'Enable', 'off');
            app.RemovePeakButton = uibutton(app.SpikeDetectionPanel, 'push', 'Position', [332 8 100 22], 'Text', 'Remove Peak', 'Enable', 'off');
            % Create Plot Interaction Panel
            app.PlotInteractionPanel = uipanel(app.UIFigure, 'Title', 'Plot Interaction', 'Position', [1022 280 453 118]);
            app.PlotTypeButtonGroup = uibuttongroup(app.PlotInteractionPanel, 'Title', 'Plot Type', 'Position', [7 8 123 86]);
            app.AllAndMeanButton = uitogglebutton(app.PlotTypeButtonGroup, 'Text', 'All And Mean', 'Position', [11 33 100 22], 'Value',  true, 'Enable', 'off');
            app.SingleTraceButton = uitogglebutton(app.PlotTypeButtonGroup, 'Text', 'Single Trace', 'Position', [11 12 100 22], 'Enable', 'off');
            app.ZoomXButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [136 72 100 22], 'Text', 'Zoom X', 'Enable', 'off');
            app.ZoomXMin = uieditfield(app.PlotInteractionPanel, 'numeric', 'Position', [236 72 50 22], 'Enable', 'off');
            app.ZoomXMax = uieditfield(app.PlotInteractionPanel, 'numeric', 'Position', [286 72 50 22], 'Enable', 'off');
            app.FixYAxisButton = uibutton(app.PlotInteractionPanel, 'push', 'Position', [348 72 100 22], 'Text', 'Fix Y Axis', 'Enable', 'off');
            app.CellNumberLabel = uilabel(app.PlotInteractionPanel, 'Position', [138 40 72 22], 'Text', 'Cell Number');
            app.ButtonNextCell = uibutton(app.PlotInteractionPanel, 'push', 'Position', [288 40 25 22], 'Text', '+', 'Enable', 'off');
            app.CellNumberEditField = uieditfield(app.PlotInteractionPanel, 'numeric', 'Limits', [1 Inf], 'Position', [237 40 50 22], 'Value',  1, 'Enable', 'off');
            app.ButtonPreviousCell = uibutton(app.PlotInteractionPanel, 'push', 'Position', [213 40 25 22], 'Text', '-', 'Enable', 'off');
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
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end