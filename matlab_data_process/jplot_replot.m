%this function plots to an existing axes (jplot_axes).
function [jplot_figure,jplot_axes,jplot_image] = jplot_replot(x,y,z,jplot_axes)
%this function is a substitute for imagesc.  It stops imagesc from doing
%its weird orientation.  It gives you control over x and y axis, and
%preserves order.  So x = 1 2 3 4 and x = 4 3 2 1 will have the same image
%on screen but x axis direction reversed.
%
%this function also handles the slightly non-linear x/y axis we get from
%our wavelengthaxis calibration and angle axis calibration (output by main_gui).
%
%unlike jplot, this function plots to an existing axis.
%
%if the size of z is the same as the prior image on this axis, all data
%cursors will be preserved.
%
%This function requires all 4 inputs to be specified.  For typical user
%application in a command prompt, jplot is easier than jplot_replot.  jplot_replot is
%more so intended for use inside gui's such as main_gui and data_analyzer
%algorithms.
%
%this program works best when size(z,2) = numel(y) and size(z,1) =
%numel(x), this is inline with its usage in main_gui and other software I
%(Jonny) have written.

%we need the x and y axis to have the same length as the corresponding side
%of z.  So scale as needed using a interpolation scheme.
%x dimension scaling:
if numel(x) ~= size(z(:,:,1),2)
    x = scale_axis_to_size(size(z(:,:,1),2),x);
end
%y dimension scaling:
if numel(y) ~= size(z(:,:,1),1)
    y = scale_axis_to_size(size(z(:,:,1),1),y);
end

%monochrome should have depth of 1, color is 3, more than that is a
%statistical image. But we can not plot that

%get the figure handle (which we will use to find the data tooltips).
jplot_figure = get(jplot_axes,'parent');

%get the handle to the image.  Here, I am assuming an axes can only have a
%single image child.  I really hope this is true.  If you turn hold off, is
%it possible to do so?  Lets just hope no one ever finds that problem.  
jplot_children = get(jplot_axes,'children');
for i = 1:numel(jplot_children)
       if strcmp(jplot_children(i).Type,'image')
            jplot_image = jplot_children(i);
       end
end

%we want to preserve data cursors while replotting, so we need to record
%what we had before we wipe them out with the replotting.
%get the data cursor handle
prior_datacursor_handle = datacursormode(jplot_figure);

%we want to preserve the colormap mode.
original_CLim = jplot_axes.CLim;
original_CLimMode = jplot_axes.CLimMode;

%get the original x and y labels
original_xlabel = get(get(jplot_axes,'xlabel'),'string');
original_ylabel = get(get(jplot_axes,'ylabel'),'string');
original_title = get(get(jplot_axes,'title'),'string');

%if there was a colorbar we want to keep that too
if isgraphics(jplot_axes.Colorbar,'colorbar')
    prior_colorbar = 'yes';
    prior_colorbar_location = jplot_axes.Colorbar.Location;
else
    prior_colorbar = 'no';
end

%get the array describing the data cursors if any exist.  This line gets
%all cursors on the FIGURE
prior_datacursor_array_full = getCursorInfo(prior_datacursor_handle);

%determine how many cursors are on our image.  Note, we only care about the single image we are updating, not all images (subplots)
%on the figure.  
cursors_on_images = 0;
for i = 1:numel(prior_datacursor_array_full)
   if strcmp(prior_datacursor_array_full(i).Target.Type,'image')
       if jplot_image == prior_datacursor_array_full(i).Target
       cursors_on_images = cursors_on_images + 1;
       prior_datacursor_array(cursors_on_images) = prior_datacursor_array_full(i);
       end
   end
end

%if prior data cursors did exist, then we need to record the original size
%of the z matrix.
if cursors_on_images>0
    % we have cursors
    pre_existing_cursors = 'yes';
    prior_z_size = size(jplot_axes.UserData.z(:,:,1));
else
    % we have no cursors
    pre_existing_cursors = 'no';
    prior_z_size = [0 0];
end

%if the user zoomed in, we want to preserve that, so get the original axis
%limits
if isfield(jplot_axes.UserData,'z')
    if size(jplot_axes.UserData.z(:,:,1)) == size(z(:,:,1))
        prior_zoom = 'yes';
        original_XLim = jplot_axes.XLim;
        original_YLim = jplot_axes.YLim;
    else
        prior_zoom = 'no';
    end
else
    prior_zoom = 'no';
end

%set the hold state
hold(jplot_axes,'off')

%creat the figure and get the handles we wish to output.  Define the directions of everything.
jplot_image = imagesc(flipud(z),'parent',jplot_axes);  %the flip here is because we want to keep x and y orientation normal.
if size(z,3) == 1
    %standard monochrome
    set(jplot_image,'CDataMapping','scaled')
elseif size(z,3) == 3
    %RGB mode
    set(jplot_image,'CDataMapping','direct')
end
jplot_axes = get(jplot_image,'parent');
jplot_figure = get(jplot_axes,'parent');
set(jplot_axes,'Xdir','normal');
set(jplot_axes,'Ydir','normal');

%we need to store the information inside the figure for our custom data
%cursor function to access it.
jplot_axes.UserData.x = x;
jplot_axes.UserData.y = y;
jplot_axes.UserData.z = z;

%jan 2020.  Tried to change jplot to give nice looking tick labels.  The
%cursor is acurate, which is important. Tick label accuracy is not as
%important, and we are still reasonably accurate.  Now we have pretty ticks that are not spaced uniformly, but have accurate numbers displayed. 
%the user probably can't notice the non-uniform spacing.  
%{
%at this point the x/y direction is correct,  the matrix z is plotted, and
%there are ticks on the x/y axis.  However, these ticks have a label
%corresponding to m/n in the matrix index z(m,n), and nothing to do with
%x/y.  We take matlab's native ticks, round them to integers, and
%then add correct labels to them to represent the possibly non-linear x/y
%axis.
%x ticks:
xticks_index = jplot_axes.XTick;
xticks_index = round(xticks_index);
xticks_index(xticks_index < 1) = [];
xticks_index(xticks_index > size(z,2)) = [];
xticks_index = unique(xticks_index);
jplot_axes.XTick = xticks_index;
xticks_label = x(xticks_index);
jplot_axes.XTickLabel = num2str(xticks_label',4);
%y ticks:
yticks_index = jplot_axes.YTick;
yticks_index = round(yticks_index);
yticks_index(yticks_index < 1) = [];
yticks_index(yticks_index > size(z,1)) = [];
yticks_index = unique(yticks_index);
jplot_axes.YTick = yticks_index;
yticks_label = y(yticks_index);
jplot_axes.YTickLabel = num2str(yticks_label',4);
%}
%
[xticks,xlabels,yticks,ylabels] = make_x_y_ticks_and_labels(x,y);
jplot_axes.XTick = xticks;
jplot_axes.XTickLabel = xlabels;
jplot_axes.YTick = yticks;
jplot_axes.YTickLabel = ylabels;
%}
%set the tic direction to both, David requested this feature
set(jplot_axes,'TickDir','both');

%we now have a completed image, matrix is plotted with correct x/y labels.
%However, if the user uses a data tip, they will be confused, so we need to
%create a custom update function.  First get the object for data cursor
%management
dcm_object = datacursormode(jplot_figure);

%we want to enable snape to vertex so that the user can always know they
%are looking at actual values.
set(dcm_object,'SnapToDataVertex','on')

%now set the text update function
dcm_object.UpdateFcn = @jplot_cursor_function;

%now that we have defined the data tip update function, lets add back in
%the data tips we had before we wiped out the previous image.  Note, we
%only keep data tips if the size of z is the same as the prior image.
if prior_z_size == size(z(:,:,1))
    if strcmp(pre_existing_cursors,'yes')
        %if there were pre existing cursors and the size of z was
        %preserved, we will now replot the cursors.
        for i = 1:numel(prior_datacursor_array)
            datacursor_handle(i) = dcm_object.createDatatip(jplot_image);
            set(datacursor_handle(i),'Position',prior_datacursor_array(i).Position)
        end
        
    else
        %do nothing, there were no pre_existing_cursors to plot
    end
else
    %do nothing, if the size of z changed we do not try to replot the data tips.
end

%we want to return the color limits to their original functionality.
set(jplot_axes,'CLimMode',original_CLimMode)

%put the x and y labels back
xlabel(jplot_axes,original_xlabel);
ylabel(jplot_axes,original_ylabel);
title(jplot_axes,original_title);

%if the user had manually put in values for Clim, put them back.
if strcmp(original_CLimMode,'manual')
    set(jplot_axes,'CLim',original_CLim)
end

%if there was originally a colorbar put it back
%if there was a colorbar we want to keep that too
if strcmp(prior_colorbar,'yes')
    colorbar(jplot_axes,'location',prior_colorbar_location)
    jplot_fixcolorbarticks(jplot_axes.Colorbar)
end

%put the zoom back to its original value
if strcmp(prior_zoom,'yes')
    jplot_axes.XLim = original_XLim;
    jplot_axes.YLim = original_YLim;
end

%make sure the figure has the buttons I'm use to (in 2018a this was moved
%to axis toolbar)
%this function was introduced in 2018a
try
    addToolbarExplorationButtons(jplot_figure)
catch
end

%i prefer not to see axis toolbar so turn it off, only needed in 2018a and
%later 
try
    set(jplot_axes.Toolbar,'Visible','off')
catch
end

end


%this function scales the vector x to have the length of desired_length
%we do this scaling the input index to x as a value from 0 to 1, we then
%use a linear interpolation scheme.
function output_x = scale_axis_to_size(desired_length,x)

%first pre-allocate x to size:
output_x = 1:desired_length;

%The index vector we want to use, scaled to 0 to 1
desired_index_vec = ((1:desired_length)-1)./(desired_length-1);

%the index vector we are currently using, scaled to 0 to 1
actual_index_vec = ((1:length(x))-1)/(length(x)-1);

output_x = interp1(actual_index_vec,x,desired_index_vec);
end


%this function is used when the user places a datatip on the plot.
function output_txt =jplot_cursor_function(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).
%
%This is a custom data cursor output function to match figures made with
%jplot and jplot_replot.

%get the position of the cursor the user placed. Note, the output here will
%be integers, but it is not m and n for z(m,n) due to the figure
%orientation.
pos = get(event_obj,'Position');
if strcmp(event_obj.Target.Type,'image')
    %first get the x,y and z values original entered by the user:
    jplot_image = event_obj.Target;
    jplot_axes = get(jplot_image,'parent');
    x = jplot_axes.UserData.x;
    y = jplot_axes.UserData.y;
    z = jplot_axes.UserData.z;
    
    %now get the x and y index
    x_index = pos(1);
    y_index = length(y) - pos(2) + 1;
    
    %start creating the output text.  First display the index values m and n
    %that describe z(m,n)
    output_txt = {['matrix index: ',num2str(y_index,4),' ,',num2str(x_index,4)]};
    
    %get the values of the matrix, and display the current value.
    if size(z,3) == 1
        output_txt{end+1} = ['matrix value: ',num2str(z(y_index,x_index))];
    else
        output_txt{end+1} = ['Red value: ',num2str(z(y_index,x_index,1))];
        output_txt{end+1} = ['Green value: ',num2str(z(y_index,x_index,2))];
        output_txt{end+1} = ['Blue value: ',num2str(z(y_index,x_index,3))];
    end
    
    % now give the x value in terms of the ticks on the graph.
    output_txt{end+1} = ['x value: ',num2str(x(x_index),6)];
    
    % now give the y value in terms of the ticks on the graph.
    output_txt{end+1} = ['y value: ',num2str(y(end-y_index+1),5)];
else
    %this is not an image, so it should be a line plot.  
    line_handle = event_obj.Target;
    
    %if it is a predefined type of plot, we can make a special cursor
    if isfield(line_handle.UserData,'type')
        %it is a cross plot, either horizontal or vertical intensity
        %through an image

        if strcmp(line_handle.UserData.type,'horizontal plot')
            x_data = line_handle.UserData.x;
            x_value = x_data(pos(1));
            
            y_data = line_handle.UserData.y;
            y_value = y_data(pos(1));
            
            output_txt{1} = ['x pixel: ',num2str(pos(1),5)];
            output_txt{2} = ['x value: ',num2str(x_value,5)];
            output_txt{3} = ['y value: ',num2str(y_value,5)];
            
        else
            %for now, we don't have anything special for vertical plots, so
            %use the general algorithm.
            
            output_txt = {['X: ',num2str(pos(1),4)],...
                ['Y: ',num2str(pos(2),4)]};
            
            % If there is a Z-coordinate in the position, display it as well
            if length(pos) > 2
                output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
            end
        end
    else
        %it isn't a horizontal or vertical cross plot, so use the generic
        %algorithm.
        
        output_txt = {['X: ',num2str(pos(1),4)],...
            ['Y: ',num2str(pos(2),4)]};
        
        % If there is a Z-coordinate in the position, display it as well
        if length(pos) > 2
            output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
        end
    end
end
end


%this function makes labels and tick values that actually look good
function [xticks,xlabels,yticks,ylabels] = make_x_y_ticks_and_labels(xaxis,yaxis)

%{
persistent a
persistent f

if isempty(f)
    f = figure('visible','off');
    a = axes(f);
else
    if ~isgraphics(f)
        f = figure;
        a = axes(f);
    end
end
%}
f = figure('visible','off');
a = axes(f);

if numel(xaxis) == [1]
    xticks = 1;
    xlabels{1} = num2str(xaxis);
else
    plot(1:numel(xaxis),xaxis,'parent',a)
    if min(xaxis) ~= max(xaxis)
        axis(a,[1,numel(xaxis),min(xaxis),max(xaxis)])
    end
    xlabels = get(a,'YTickLabel');
    xticks = (1:numel(xlabels))*0;
    for i = 1:numel(xlabels)
        xvalue = str2double(xlabels{i});
        [~,index] = min(abs(xaxis - xvalue));
        xticks(i) = index;
    end
    [xticks,sorting_index] = sort(xticks);
    xlabels = xlabels(sorting_index);
    
    %its possible in weird cases that we have repeat ticks.  For example
    %jplot(1:10,1:10,magic(7)) will triger this.  Because we have more ticks
    %than we have rows/columns of the matrix.
    [~,unique_x_index] = unique(xticks);
    xticks = xticks(unique_x_index);
    xlabels = xlabels(unique_x_index);
    
end


if numel(yaxis) == 1
    yticks = 1;
    ylabels{1} = num2str(yaxis);
    
else
    
    plot(1:numel(yaxis),yaxis,'parent',a)
    if min(yaxis) ~= max(yaxis)
        axis(a,[1,numel(yaxis),min(yaxis),max(yaxis)])
    end
    ylabels = get(a,'YTickLabel');
    yticks = (1:numel(ylabels))*0;
    for i = 1:numel(ylabels)
        yvalue = str2double(ylabels{i});
        [~,index] = min(abs(yaxis - yvalue));
        yticks(i) = index;
    end
    [yticks,sorting_index] = sort(yticks);
    ylabels = ylabels(sorting_index);
    
    %its possible in weird cases that we have repeat ticks.  For example
    %jplot(1:10,1:10,magic(7)) will triger this.  Because we have more ticks
    %than we have rows/columns of the matrix.
    [~,unique_y_index] = unique(yticks);
    yticks = yticks(unique_y_index);
    ylabels = ylabels(unique_y_index);
end


delete(f);





end


%backup
%{
    %find the pixels of the cursor location
    x_pixel = pos(1)
    y_pixel = pos(2)
    
    %get the handle to the user data
    line_handle = get(event_obj.Target);
    UserData = line_handle.UserData
    
    %get the x/y data that was used to creat ethe line.
    if isfield(UserData,'x')
        x_data = UserData.x;
    else
        x_data = get(event_obj.Target,'XData');
    end
    if isfield(UserData,'y')
        y_data = UserData.y;
    else
        y_data = get(event_obj.Target,'YData');
    end
    %get the x/y value at the location of the cursor
    x_value = x_data(x_pixel);
    y_value = y_data(x_pixel);
    
    %create the output cell
    output_txt{1} = ['x pixel: ',num2str(x_pixel)];
    output_txt{end+1} = ['y pixel: ',num2str(y_pixel)];
    output_txt{end+1} = ['x value: ',num2str(x_value)];
    output_txt{end+1} = ['y value: ',num2str(y_value)];
    
    % If there is a Z-coordinate in the position, display it as well
    if length(pos) > 2
        output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
    end
%}








%backup before making large changes
%{
function [jplot_figure,jplot_axes,jplot_image] = jplot_replot(x,y,z,jplot_axes)
%this function is a substitute for imagesc.  It stops imagesc from doing
%its weird orientation.  It gives you control over x and y axis, and
%preserves order.  So x = 1 2 3 4 and x = 4 3 2 1 will have the same image
%on screen but x axis direction reversed.
%
%this function also handles the slightly non-linear x/y axis we get from
%our wavelengthaxis calibration and angle axis calibration (output by main_gui).
%
%unlike jplot, this function plots to an existing axis.
%
%if the size of z is the same as the prior image on this axis, all data
%cursors will be preserved.
%
%This function requires all 4 inputs to be specified.  For typical user
%application in a command prompt, jplot is easier than jplot_replot.  jplot_replot is
%more so intended for use inside gui's such as main_gui and data_analyzer
%algorithms.
%
%this program works best when size(z,2) = numel(y) and size(z,1) =
%numel(x), this is inline with its usage in main_gui and other software I
%(Jonny) have written.

%we need the x and y axis to have the same length as the corresponding side
%of z.  So scale as needed using a interpolation scheme.
%x dimension scaling:
if numel(x) ~= size(z,2)
    x = scale_axis_to_size(size(z,2),x);
end
%y dimension scaling:
if numel(y) ~= size(z,1)
    y = scale_axis_to_size(size(z,1),y);
end

%get the figure handle (which we will use to find the data tooltips).
jplot_figure = get(jplot_axes,'parent');

%we want to preserve data cursors while replotting, so we need to record
%what we had before we wipe them out with the replotting.
%get the data cursor handle
prior_datacursor_handle = datacursormode(jplot_figure);

%we want to preserve the colormap mode.
original_CLim = jplot_axes.CLim;
original_CLimMode = jplot_axes.CLimMode;

%if there was a colorbar we want to keep that too
if isgraphics(jplot_axes.Colorbar,'colorbar')
    prior_colorbar = 'yes';
    prior_colorbar_location = jplot_axes.Colorbar.Location;
else
    prior_colorbar = 'no';
end

%get the array describing the data cursors if any exist.
prior_datacursor_array = getCursorInfo(prior_datacursor_handle);

%if prior data cursors did exist, then we need to record the original size
%of the z matrix.
if numel(prior_datacursor_array)>0
    % we have cursors
    pre_existing_cursors = 'yes';
    prior_z_size = size(jplot_axes.UserData.z);
else
    % we have no cursors
    pre_existing_cursors = 'no';
    prior_z_size = [0 0];
end

%set the hold state
hold(jplot_axes,'off')

%creat the figure and get the handles we wish to output.  Define the directions of everything.
jplot_image = imagesc(flipud(z),'parent',jplot_axes);  %the flip here is because we want to keep x and y orientation normal.
jplot_axes = get(jplot_image,'parent');
jplot_figure = get(jplot_axes,'parent');
set(jplot_axes,'Xdir','normal');
set(jplot_axes,'Ydir','normal');

%we need to store the information inside the figure for our custom data
%cursor function to access it.
jplot_axes.UserData.x = x;
jplot_axes.UserData.y = y;
jplot_axes.UserData.z = z;

%at this point the x/y direction is correct,  the matrix z is plotted, and
%there are ticks on the x/y axis.  However, these ticks have a label
%corresponding to m/n in the matrix index z(m,n), and nothing to do with
%x/y.  We take matlab's native ticks, round them to integers, and
%then add correct labels to them to represent the possibly non-linear x/y
%axis.
%x ticks:
xticks_index = jplot_axes.XTick;
xticks_index = round(xticks_index);
xticks_index(xticks_index < 1) = [];
xticks_index(xticks_index > size(z,2)) = [];
xticks_index = unique(xticks_index);
jplot_axes.XTick = xticks_index;
xticks_label = x(xticks_index);
jplot_axes.XTickLabel = num2str(xticks_label',4);
%y ticks:
yticks_index = jplot_axes.YTick;
yticks_index = round(yticks_index);
yticks_index(yticks_index < 1) = [];
yticks_index(yticks_index > size(z,1)) = [];
yticks_index = unique(yticks_index);
jplot_axes.YTick = yticks_index;
yticks_label = y(yticks_index);
jplot_axes.YTickLabel = num2str(yticks_label',4);

%set the tic direction to both, David requested this feature
set(jplot_axes,'TickDir','both');


%we now have a completed image, matrix is plotted with correct x/y labels.
%However, if the user uses a data tip, they will be confused, so we need to
%create a custom update function.  First get the object for data cursor
%management
dcm_object = datacursormode(jplot_figure);

%we want to enable snape to vertex so that the user can always know they
%are looking at actual values.
set(dcm_object,'SnapToDataVertex','on')

%now set the text update function
dcm_object.UpdateFcn = @jplot_cursor_function;

%now that we have defined the data tip update function, lets add back in
%the data tips we had before we wiped out the previous image.  Note, we
%only keep data tips if the size of z is the same as the prior image.
if prior_z_size == size(z)
    if strcmp(pre_existing_cursors,'yes')
        %if there were pre existing cursors and the size of z was
        %preserved, we will now replot the cursors.
        for i = 1:numel(prior_datacursor_array)
            datacursor_handle(i) = dcm_object.createDatatip(jplot_image);
            set(datacursor_handle(i),'Position',prior_datacursor_array(i).Position)
        end
        
    else
        %do nothing, there were no pre_existing_cursors to plot
    end
else
    %do nothing, if the size of z changed we do not try to replot the data tips.
end

%we want to return the color limits to their original functionality.
set(jplot_axes,'CLimMode',original_CLimMode)

%if the user had manually put in values for Clim, put them back.
if strcmp(original_CLimMode,'manual')
    set(jplot_axes,'CLim',original_CLim)
end

%if there was originally a colorbar put it back
%if there was a colorbar we want to keep that too
if strcmp(prior_colorbar,'yes')
    colorbar(jplot_axes,'location',prior_colorbar_location)
    jplot_fixcolorbarticks(jplot_axes.Colorbar)
end

end


%this function scales the vector x to have the length of desired_length
%we do this scaling the input index to x as a value from 0 to 1, we then
%use a linear interpolation scheme.
function output_x = scale_axis_to_size(desired_length,x)

%first pre-allocate x to size:
output_x = 1:desired_length;

%The index vector we want to use, scaled to 0 to 1
desired_index_vec = ((1:desired_length)-1)./(desired_length-1);

%the index vector we are currently using, scaled to 0 to 1
actual_index_vec = ((1:length(x))-1)/(length(x)-1);

output_x = interp1(actual_index_vec,x,desired_index_vec);
end


%this function is used when the user places a datatip on the plot.
function output_txt =jplot_cursor_function(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).
%
%This is a custom data cursor output function to match figures made with
%jplot and jplot_replot.

%first get the x,y and z values original entered by the user:
jplot_image = event_obj.Target;
jplot_axes = get(jplot_image,'parent');
x = jplot_axes.UserData.x;
y = jplot_axes.UserData.y;
z = jplot_axes.UserData.z;

%get the position of the cursor the user placed. Note, the output here will
%be integers, but it is not m and n for z(m,n) due to the figure
%orientation.
pos = get(event_obj,'Position');

%now get the x and y index
x_index = pos(1);
y_index = length(y) - pos(2) + 1;

%start creating the output text.  First display the index values m and n
%that describe z(m,n)
output_txt = {['matrix index: ',num2str(y_index,4),' ,',num2str(x_index,4)]};

%get the values of the matrix, and display the current value.
output_txt{end+1} = ['matrix value: ',num2str(z(y_index,x_index))];

% now give the x value in terms of the ticks on the graph.
output_txt{end+1} = ['x value: ',num2str(x(x_index),5)];

% now give the y value in terms of the ticks on the graph.
output_txt{end+1} = ['y value: ',num2str(y(end-y_index+1),5)];
end


%}










