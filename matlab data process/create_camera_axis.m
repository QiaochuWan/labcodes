

function [output_axis,output_units] = create_camera_axis(lambda_spec,bay_string,camera,direction,sweep_mode,optics_string,axis_length)
%this function takes in information about the specific setup of the
%camera/spectrometer/lenses, and outputs a vector giving the axis on either
%the horizontal or vertical side of the camera.  It also outputs the units
%of the axis it gives you.  Possible units: microns (real space), degrees
%(k space), nanometers (spectrometer), picoseconds (streak camera).  
%
%inputs:
%lambda_spec 0 corresponds to 0'th order imaging (real space typically), all other numbers are
%spectrometer setting in 1st order imaging (spectral resolved)
%
%bay_string:  tells us which computer (and thus which bay) we are in.
%bay_1,bay_2,bay_2laptop,bay_3,bay_4,bay_4microscope
%
%camera: which camera, roper,streak,davis,thorlabs,zeiss,logitech
%
%direction: horizontal (wavelength axis or real space or k space) or vertical (time axis or real space or k space).  
%
%sweep mode: Sweep mode for hamamatsu camera.  0 is no sweeping, 1-4 are
%various modes with various calibrations.  
%
%optics_string: this string tells us what optics are being used, and allows
%us to select a calibration accordingly.  For example,
%'bay1.short.50x.rs' is the bay 1, short path (jonny's path) setup with the 50x
%objective and the 100mm and 150 mm lenses in place.  Real space imaging in
%microns.  Typically, this will be a drop down menu in main_gui.  
%
%axis length is the number of pixels the camera has in that direction.  


%get the possible optics_string and make sure we have something valid.  
possible_strings = get_possible_optics_configurations;
if max(contains(possible_strings,optics_string))>0
   %we are good 
else
    error(['invalid optics string:',optics_string])
end

%if the spectrometer is operating in 1st order mode, we are producing a wavelength axis, we have a specific function that
%does that for all setups by loading fits to calibration data. 
if lambda_spec~= 0 && strcmp(direction,'horizontal')  
    output_axis = spectrapro_2500i_getwavelengthaxis(bay_string,camera,lambda_spec,axis_length);
    output_units = 'nanometers';
     
else
    
    %We are not producing a spectral axis, so call the bay specific
    %functions:
    if strcmp(bay_string,'bay_1')
        [output_axis,output_units] = create_non_spectral_camera_axis_bay1(camera,direction,sweep_mode,optics_string,axis_length);
        
    elseif strcmp(bay_string,'bay_4')
        [output_axis,output_units] = create_non_spectral_camera_axis_bay4(camera,direction,optics_string,axis_length);
        
    elseif strcmp(bay_string,'bay_2')
       [output_axis,output_units] = create_non_spectral_camera_axis_bay2(camera,direction,optics_string,axis_length); 
        
    end
end


%{
%possible optics configurations:
%{



bay4.50x.rs
bay4.20x.rs
%}

%bay 1, roper or streak camera
if strcmp(bay_string,'bay_1')
    
    %Jonny's beam path
    if contains(optics_string,'short')
        
    end
    
    %Shouvik's beam path
    if contains(optics_string,'long')
        
    end
    
end

%bay 4, 1k roper camera or zeiss camera (color), secondary camera. 
if strcmp(bay_string,'bay_4')
    
    %roper camera
    if strcmp(camera,'roper')
        %horizontal axis
        if strcmp(direction,'horizontal')
            if lambda_spec ~= 0
                %spectral imaging.
                output_axis = spectrapro_2500i_getwavelengthaxis(1004);
                
            else
                
                %real space 50x
                if strcmp(optics_string,'bay4.50x.rs')
                    output_axis = ((1:1004)-503) * .2609; %from dec 23, 2019, bay 4 (bay 2 computer moved)
                    output_units = 'microns';
                end
                
                %real space 20x
                if strcmp(optics_string,'bay4.20x.rs')
                    output_axis = ((1:1004)-503) * .6495; %from dec 23, 2019, bay 4 (bay 2 computer moved)
                    output_units = 'microns';
                end
                
            end
        end
        
        %vertical axis
        if strcmp(direction,'vertical')
            %real space 50x
            if strcmp(optics_string,'bay4.50x.rs')
                output_axis = ((1:1002)-502) * .2477;  %from dec 23, 2019, bay 4 (bay 2 computer moved)
                output_units = 'microns';
            end
            
            %real space 20x
            if strcmp(optics_string,'bay4.20x.rs')
                output_axis = ((1:1002)-502) * 0.6108;  %from dec 23, 2019, bay 4 (bay 2 computer moved)
                output_units = 'microns';
            end
            
            
        end
        
    end
    
    %zeiss camera stuff
    if strcmp(camera,'zeiss')
        
        %horizontal axis.
        if strcmp(direction,'horizontal')
            
        end
        
        %vertical axis.
        if strcmp(direction,'horizontal')
            
        end
        
        
        
    end
    
    
end
%}

end

%an early idea, and a bad one.  this is obsolete.  
%{
%this function is where I have recorded how many pixels each camera has. It
%does some checks and outputs that number
function axis_length = get_axis_length(bay_string,camera,direction)

%bay 1 roper
if strcmp(bay_string,'bay_1') && strcmp(camera,'roper') && strcmp(direction,'horizontal')
    axis_length = 512;
end
if strcmp(bay_string,'bay_1') && strcmp(camera,'roper') && strcmp(direction,'vertical')
    axis_length = 512;
end

%bay 1 streak
if strcmp(bay_string,'bay_1') && strcmp(camera,'streak') && strcmp(direction,'horizontal')
    axis_length = 1000;
end
if strcmp(bay_string,'bay_1') && strcmp(camera,'streak') && strcmp(direction,'vertical')
    axis_length = 1000;
end

%bay 4 roper
if strcmp(bay_string,'bay_4') && strcmp(camera,'roper') && strcmp(direction,'horizontal')
    axis_length = 1004;
end
if strcmp(bay_string,'bay_4') && strcmp(camera,'roper') && strcmp(direction,'vertical')
    axis_length = 1002;
end

%bay 4 zeiss.  Although it says thorlabs, taht is just left over from the
%fact that logitech and thorlabs 
if strcmp(bay_string,'bay_4') && strcmp(camera,'logitech') && strcmp(direction,'horizontal')
    axis_length = 2560;
end
if strcmp(bay_string,'bay_4') && strcmp(camera,'logitech') && strcmp(direction,'vertical')
    axis_length = 1920;
end



end
%}


%this function is only for creating spectral axis, horizontal axis from a
%grating in a spectrometer.  This function should not be called if
%spectrometer is operating at lambda = 0, this is only for lambda ~=0.
function wavelength_axis = spectrapro_2500i_getwavelengthaxis(bay_string,camera,lambda_spec,axis_length)
%this uses the calibration data created with main_gui->laser_scan function
%along with data_analyzer-> create spectrometer calibration function's
%output (speccal file) to output wavelength axis (a vector) as a function
%of pixels.
%
%note, this library also works for spectrapro 2300i,  it is all the same,
%just different path lengths.

%based on the current settings of the spectrometer, we must load a
%calibration file.  The following if strcmp(bay_string,'').... statements are the only thing other grad students
%should have to change based on moving main gui to a new spectrometer set
%up.  You will have to create new calibrations, and put their names in
%below.
if strcmp(bay_string,'bay_1')
    
    %roper camera calibrations
    if strcmp(camera,'roper')

        %get the current grating setting
        current_grating_setting = spectrapro_2500i_getgrating;
        
        %based on grating, select calibration file.  
        if current_grating_setting == 1
            file = 'bay1_1200g_roper_cal';
            %file = 'real_space_imaging_cal';
        elseif current_grating_setting == 2
            file = 'bay1_1800g_roper_cal';
            %file = 'real_space_imaging_cal';
        elseif current_grating_setting == 3
            file = 'bay1_50g_roper_cal';
            %file = 'real_space_imaging_cal';
        end
        
    end
    
    %streak camera calibrations
    if strcmp(camera,'streak')
        
        %get the current grating setting
        current_grating_setting = spectrapro_2500i_getgrating;
        
        %based on grating, select calibration file.
        if current_grating_setting == 1
            file = 'bay1_1200g_streak_cal';
            %file = 'real_space_imaging_cal';
        elseif current_grating_setting == 2
            file = 'bay1_1800g_streak_cal';
            %file = 'real_space_imaging_cal';
        elseif current_grating_setting == 3
            file = 'bay1_50g_streak_cal';
            %file = 'real_space_imaging_cal';
        end
    end
    
end

%what use to be bay 2 calibration (David M and Qi Y use to use.  1k roper +
%2500i spectrometer
%
if strcmp(bay_string,'bay_2')
    if spectrapro_2500i_getwavelength == 0
        %if we are set to 0, we use a special file, which just outputs pixel
        %axis rather than spectral axis.
        file = 'real_space_imaging_cal';
    else
        if spectrapro_2500i_getgrating == 1
            file = 'bay2_1200g_davis_cal';
            %file = 'real_space_imaging_cal';  %comment these out when first
            %making calibration files if you want
        elseif spectrapro_2500i_getgrating == 2
            file = 'real_space_imaging_cal';  %its just a mirror
            %making calibration files if you want
        elseif spectrapro_2500i_getgrating == 3
            %file = 'bay2_50g_roper_cal';
            file = 'real_space_imaging_cal';
            %making calibration files if you want
        end
    end
    
end

%}

%what use to be bay 3 calibration (Jonny B and Zheng room temp setup).
%Davis camera + 2300i spectrometer
%{
if strcmp(bay_string,'bay_3')
    if spectrapro_2500i_getwavelength == 0
        %if we are set to 0, we use a special file, which just outputs pixel
        %axis rather than spectral axis.
        file = 'real_space_imaging_cal';
    else
        if spectrapro_2500i_getgrating == 1
            file = 'bay3_300g_davis_cal';
            %file = 'real_space_imaging_cal';
            
        elseif spectrapro_2500i_getgrating == 2
            file = 'bay3_1200g_davis_cal';
            %file = 'real_space_imaging_cal';
            
        elseif spectrapro_2500i_getgrating == 3
            %file = 'bay3_1200g_davis_cal';
            file = 'real_space_imaging_cal';
            
        end
    end
end
%}

if strcmp(bay_string,'bay_4')
    
    %roper camera calibrations
    if strcmp(camera,'roper')
        
        %get the current grating setting
        current_grating_setting = spectrapro_2500i_getgrating;
        
        %based on grating, select calibration file.
        if current_grating_setting == 1
            file = 'bay4_300g_roper_cal';
            %file = 'real_space_imaging_cal';
        elseif current_grating_setting == 2
            file = 'bay4_1200g_roper_cal';
            %                 file = 'real_space_imaging_cal';
        elseif current_grating_setting == 3
            %file = 'bay4_50g_roper_cal';
            file = 'real_space_imaging_cal';
        end
        
    end
    
end


if strcmp(bay_string,'bay_4_microscope')
    error('no calibration for bay 4 spectrapro spectrometer; did you mean oriel?')
end


%we now have the file to load
datafile = load(file);
fit_structure = datafile.fit_structure;

%This ia a little convoluted.  The wavelength as a function of pixels is
%fit to quadratic order.  However, the coeffecients for those fits, depend
%on the spectrometer wavelength setting.  So, the coeffecients are fit to
%quardatic order in specwavelength. Hence the strange names below.
constant_coef_coefs = fit_structure.constant_coef_coefs;
linear_coef_coefs = fit_structure.linear_coef_coefs;
quad_coef_coefs = fit_structure.quad_coef_coefs;

%now, use the fitting coeffecients to find the coeffecients we will use:
constant_coef = polyval(constant_coef_coefs,lambda_spec);
linear_coef = polyval(linear_coef_coefs,lambda_spec);
quad_coef = polyval(quad_coef_coefs,lambda_spec);

%now use these 3 coeffecients to determine the wavelength axis.
wavelength_axis = polyval([quad_coef linear_coef constant_coef+lambda_spec],1:axis_length);
end



%the bay 1 function for axis that are not spectral axis.  This first function
%creates a time axis, or calls the next function in the chain. The second function handles real space or k space axis.   
function [output_axis,output_units] = create_non_spectral_camera_axis_bay1(camera,direction,sweep_mode,optics_string,axis_length)

%bay 1 has a lot of different possibilities. 2 different optical paths, the
%short path (Jonny) and long path (Shouvik).  Then 2 cameras, roper or
%streak).  And the stream camera can either be time resolving (streaking),
%or it can be off and just in regular mode.  However, both optical paths,
%if they are in time resolved mode, get the same vertical axis (time axis).

%so, this function checks whether or not we are making a time axis, if we
%are, it makes it.  If we are not, it goes to the next function.  

%check if we are makign time axis. 
if strcmp(camera,'streak') && strcmp(direction,'vertical') && sweep_mode>0
    %get the minimum and maximum values of the time axis (David Myers gave
    %me these, I did not calibrate them myself - Jonny).
    if sweep_mode == 4
        t_max = 2168.739;
    elseif sweep_mode ==3
        t_max = 1508.962;
    elseif sweep_mode ==2
        t_max = 790.6;
    elseif sweep_mode ==1
        t_max = 176.7173;
    end
    
    %make a vector going from 0 to 1, with the correct number of pixels.
    %Then multiply by time value to make time axis.
    output_axis = 1:axis_length - 1;
    output_axis = t_max * output_axis / max(output_axis);
    output_units = 'picoseconds';
else
    
  [output_axis,output_units] = create_non_spectral_non_temporal_camera_axis_bay1(camera,direction,optics_string,axis_length);
end


end  
function [output_axis,output_units] = create_non_spectral_non_temporal_camera_axis_bay1(camera,direction,optics_string,axis_length)
%by the time we reach this function, we know we are not making a spectral
%axis, and we are not making a temporal axis.  That just leaves real space
%and k space and pixels. Pixels are for uncalibrated situations.  

%predefine 
output_axis = [];
output_units = [];

%Jonny's setup, 50x
if strcmp(optics_string,'bay_1.short.50x.rs') && strcmp(camera,'roper')
output_axis = 1:axis_length;
output_axis = output_axis - floor(max(output_axis)/2);
output_axis = output_axis * .6936; %thats microns/pixel;
output_units = 'micrometers';

if strcmp(direction,'vertical')
    output_axis = flip(output_axis);
end

end
if strcmp(optics_string,'bay_1.short.50x.ks') && strcmp(camera,'roper')
    
    %{
    %This will give the vertically calibrated angle axis for the Roper camera
    %in Bay1 for the setup of 2018-10-12, using the 0.75 NA lens and 300 gr/mm
    %grating.
    
    %the information specific to the setup (for other setups, only change these
    %lines:
    known_pixels = [116 166 214  263 313 366 422];
    known_orders = [-3   -2   -1    0   1   2   3  ];
    laser_wavelength = 632.8e-9; %untis of m
    grating_density = 300e3; %groves per meter.
    number_of_vertical_pixels = 512;
    
    %shift the known pixels so that zero'th order is center of screen;
    known_pixels = known_pixels - (known_pixels((known_orders == 0)) - floor(number_of_vertical_pixels/2));
    
    %calculated known angles in degrees
    known_angles = asind(known_orders*laser_wavelength*grating_density);
    
    %fit it
    p = polyfit(known_pixels,known_angles,3)
    save('p.mat','p')
    %}
    
    %from the fit given by the above code
    p(1) = 3.105844034241813e-07;
    p(2) = -3.015585665805714e-04;
    p(3) = 0.313706602263406;
    p(4) = -65.753981172379910;
    
    %create output
    output_axis = polyval(p,1:axis_length);
    output_units = 'degrees';
    
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
    
end

%Jonny's setup, 20x. 

%Shouvik's setup, 50x
%Hassan and Qi's setup, 50x. 
if strcmp(optics_string,'bay_1.long.50x_highmag.rs') && strcmp(camera,'roper')
output_axis = 1:axis_length;
output_axis = output_axis - floor(max(output_axis)/2);
output_axis = output_axis * 0.2210; %thats microns/pixel;
output_units = 'micrometers';

if strcmp(direction,'vertical')
    output_axis = flip(output_axis);
end



end
if strcmp(optics_string,'bay_1.long.50x.ks')
output_axis = 1:axis_length;
output_axis = output_axis - floor(max(output_axis)/2);
output_axis = output_axis / 3.6481;
output_units = 'degrees';


if strcmp(direction,'vertical')
    output_axis = flip(output_axis);
end
end
if strcmp(optics_string,'bay_1.long.20x.ks')
output_axis = 1:axis_length;
output_axis = output_axis - floor(max(output_axis)/2);
output_axis = output_axis / 9.7033;
output_units = 'degrees';


if strcmp(direction,'vertical')
    output_axis = flip(output_axis);
end
end






%if we havn't assigned it yet, just use pixels.  
if isempty(output_axis)
    output_axis = 1:axis_length;
    output_units = 'pixels';
end
end



%bay 4.  By the time we reach this function, it is either real space, k
%space, or pixels.  
function [output_axis,output_units] = create_non_spectral_camera_axis_bay4(camera,direction,optics_string,axis_length)

%predefine 
output_axis = [];
output_units = [];

%roper camera 20x setups
if strcmp(optics_string,'bay_4.roper.20x_lowmag.rs') && strcmp(camera,'roper')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = 0.6108;  %from dec 23, 2019, bay 4 (bay 2 computer moved)
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .6495; %from dec 23, 2019, bay 4 (bay 2 computer moved)
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.roper.20x_highmag.rs') && strcmp(camera,'roper')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .2818; %from feb 19 2020
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .2523; %from feb 19 2020
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.roper.20x_ultrahighmag.rs') && strcmp(camera,'roper')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = 0.1456;  %from dec 23, 2019, bay 4 (bay 2 computer moved)
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = 0.1333; %from dec 23, 2019, bay 4 (bay 2 computer moved)
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end

%roper camera 50x setups
if strcmp(optics_string,'bay_4.roper.50x_lowmag.rs') && strcmp(camera,'roper')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .2477;  %from dec 23, 2019, bay 4 (bay 2 computer moved)
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .2609; %from dec 23, 2019, bay 4 (bay 2 computer moved)
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.roper.50x_highmag.rs') && strcmp(camera,'roper')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .1214; %from feb 19, 2020
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .1071; %from feb 19, 2020
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.roper.50x_lowmag.ks') && strcmp(camera,'roper')  
    output_axis = 1:axis_length;
    %output_axis = output_axis - floor(max(output_axis)/2);
    
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %fit using the arc_sin_degrees function in spec_fit_gui
        magnitude = .9936;
        shift = 500.5979;
        scaler = -582.9;
        output_axis = magnitude * asind((output_axis-shift)/scaler); 
        
        %scale the axis
    output_units = 'degrees';
        
    elseif strcmp(direction,'horizontal')
        %fit using the arc_sin_degrees function in spec_fit_gui
        magnitude = .9936;
        shift = 500.5979;
        scaler = -582.9;
        output_axis = magnitude * asind((output_axis-shift)/scaler);
        
        %scale the axis
    output_units = 'degrees';
    end
    
    %flip if its vertical.
    if strcmp(direction,'horizontal')
        output_axis = flip(output_axis);
    end
end

%zeiss camera 20x
if strcmp(optics_string,'bay_4.zeiss.20x_lowmag.rs')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .4954;
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .5461;
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.zeiss.20x_highmag.rs')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .0781; %from feb 19, 2020
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .0803; %from feb 19, 2020
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.zeiss.20x_ultrahighmag.rs')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .0291;
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .0482;
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.  
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
    
end
if strcmp(optics_string,'bay_4.roper.20x_lowmag.ks') && strcmp(camera,'roper')  
    output_axis = 1:axis_length;
    %output_axis = output_axis - floor(max(output_axis)/2);
    
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %fit using the linear fit in spec_fit_gui
        constant = 19.2428;
        linear = -0.0387;
        output_axis = output_axis*linear + constant;
        
        %scale the axis
        output_units = 'degrees';
        
    elseif strcmp(direction,'horizontal')
        %fit using the linear fit in spec_fit_gui
        constant = 19.2428;
        linear = -0.0387;
        output_axis = output_axis*linear + constant;
        
        %scale the axis
        output_units = 'degrees';
    end
    
    %flip if its vertical.
    if strcmp(direction,'horizontal')
        output_axis = flip(output_axis);
    end
end

%zeiss camera 50x
if strcmp(optics_string,'bay_4.zeiss.50x_lowmag.rs')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .2110;
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .2160;
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
end
if strcmp(optics_string,'bay_4.zeiss.50x_highmag.rs')
    output_axis = 1:axis_length;
    output_axis = output_axis - floor(max(output_axis)/2);
    
    %get the appropriate microns per pixel scaler
    if strcmp(direction,'vertical')
        %vertical
        microns_per_pixel = .0426; %from feb 19, 2020
    elseif strcmp(direction,'horizontal')
        %horizontal
        microns_per_pixel = .0354; %from feb 19, 2020
    end
    
    %scale the axis
    output_axis = output_axis * microns_per_pixel;
    output_units = 'micrometers';
    
    %flip if its vertical.
    if strcmp(direction,'vertical')
        output_axis = flip(output_axis);
    end
end


%if we havn't assigned it yet, just use pixels.  
if isempty(output_axis)
    output_axis = 1:axis_length;
    output_units = 'pixels';
end
end




%bay 2. By the time we reach this function, it is either real space, k
%space of pixels. 
function [output_axis,output_units] = create_non_spectral_camera_axis_bay2(camera,direction,optics_string,axis_length)

%predefine 
output_axis = [];
output_units = [];


%if we havn't assigned it yet, just use pixels.  
if isempty(output_axis)
    output_axis = 1:axis_length;
    output_units = 'pixels';
end

end











