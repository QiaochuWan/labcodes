function power_series
clc;
close all;
%add new 
%%load invidual files
% files=dir(fullfile(pwd,'*.mat'));
% sortName=sort_nat({files.name});
% %load the background file
% bg_file = load(files(1).name);
% bg = bg_file.data;
% bg_image = bg(1).imagedata .*0;% / (bg(1).image_count * bg(1).integration_time);

%%load consolidated data
 files=load('consolidated_data.mat');
 files=files.data;
 bg_file = files(1);
 bg_image = bg_file.imagedata .*0;

%temperature (for graphing titles)
temp = 4;

%get the calibrated vertical axis (microns)
[vertical_axis,~] = create_camera_axis(0,'bay_4','roper','vertical',0,'bay_4.roper.50x_highmag.rs',size(bg_image,2));
hc = 1239.84197;

%create the figure
f = figure;
a1 = subplot(2,2,1,'parent',f);
title(a1,'press any key to continue after you position figure where you want it')
a3 = subplot(2,2,2);
a2 = subplot(2,2,3);
a4 = subplot(2,2,4);
pause

%go through each file, fit spectrum with lorentzians, then fit each
%location with a lorentzian vertically to give a y value (in microns). To
%get position as a function of voltage.
runs = 0;
y_center =470;
heat=[];
for file_index = 1:1:numel(files)
    %y_center
    %load the data file, and get the spectrum (energy eV)
    %file =fullfile(pwd,sortName{file_index});
    %data = load(file);
    %data = data.data;
    data=files(file_index);
    wavelength=data.wavelengthaxis(1:size(bg_image,2));
  %  [~,x_min] = min(abs(wavelength-596));
%     [~,x_max] = min(abs(wavelength-647));
     [~,T_min] = min(abs(wavelength-610));
    [~,T_max] = min(abs(wavelength-625));
    x_min = 1;
    x_max = size(bg_image,2);
    image = data.imagedata / (data.image_count * data.integration_time);
    image = image - bg_image;
    Tot=sum(image(235:265,T_min:T_max),'all');
    image = image(:,x_min:x_max);
    image = fliplr(image);

    Energy = flip(hc ./ data.wavelengthaxis(x_min:x_max));
   
    %get the voltage
    power = data.keithley.voltage;
    
   
    box_height = 10;
    
    %plot the image in a1
    jplot_replot(Energy,vertical_axis,image,a1);
    colormap(a1,jet_plus_white);
    
    scaled_y=1.11.* y_center;
    
    yline(a1,scaled_y-box_height,'m');
    yline(a1,scaled_y+box_height,'r');
    yline(a1,scaled_y,'k');
    title(a1,['Temperature: ',num2str(temp),' k.  Backgate = ',num2str(power),'V']);
    
    % make a box and integrate it to get the spectrum
    
    if box_height == 0
        Intensity = image(y_center-box_height:y_center+box_height,:);
    else
       Intensity = sum(image(y_center-box_height:y_center+box_height,:)); 
    end
  %  Intensity = Intensity / max(Intensity(:));
    runs = runs + 1;
    %plot that spectrum
    plot(Energy,Intensity,'parent',a2);
    heat(file_index,:)=Intensity;
    %create initial parameters.  
   % if file_index == 1
        %centers = [1.74,1.7,1.719,1.684];
        %{
        centers = [1.683,1.718,1.73];
        widths = [.06,.01,.01];
        heights = [300,600,200];
        %}
        %centers = [1.749,1.733,1.685,1.695,1.68,1.67,1.656,1.633,1.623,1.609,1.601];
        %widths = centers.*0 + .02;
        %heights = [29,43,65,65,160,181,161,93,65,60,52];
        
       centers = [1.6071,1.6206,1.6431];
       widths = [.0227,.0165,.0111];
       heights = [3662,4527,9377];
       
      %   centers = [1.5731,1.6220];
      %   widths = [0.0140,0.0259];
      %   heights = [6.9351e+04,9.3240e+03];
      %   cs=[200,200];
%         centers = [1.6146,1.6255];
%          widths = [0.0455,0.0518];
%          heights = [3.1599e+03,1.3916e+04];
         cs=[40,40,40];
      
      
        
         centers_lb = centers - 0.007;
         centers_ub = centers + 0.007;
        
        widths_lb = widths.*0;
        widths_ub = widths.*0 + 100;
        
        heights_lb = heights.*0;
        heights_ub = heights.*0 + max(Intensity);
        
        cs_lb = cs.*0;
        cs_ub = cs.*0 + max(Intensity);
        
        params = [centers,widths,heights,cs];
        lb = [centers_lb,widths_lb,heights_lb,cs_lb];
        ub = [centers_ub,widths_ub,heights_ub,cs_ub];
  %  else
      
   %     params = [centers,widths,heights,cs];
        
   % end
    
    %find optimal parameters.
    myoptions = optimset('MaxFunEvals',10000,'MaxIter',10000,'TolFun',1e-18,'TolX',1e-18);
    params = lsqcurvefit(@lorentzians,params,Energy,Intensity,lb,ub,myoptions);
    num=size(params);
    %num(2)
    %breakdown the results.
    num_peaks = num(2)/4;
    %reshape into matrix
    params_matrix = reshape(params,[num_peaks,4]);
    
    %pull out the lorentzian parameters
    centers = params_matrix(:,1);
    widths = params_matrix(:,2);
    heights = params_matrix(:,3);
    cs = params_matrix(:,4);
    
    %sort it and make sure its all correct. 
    [~,sort_index] = sort(centers);
    centers = centers(sort_index);
    widths = widths(sort_index);
    heights = heights(sort_index);
    cs = cs(sort_index);
    %for the first one, we want to show the lorentzians and how they fit
    %into the data
    if file_index == 1
        %make a new figure
        f_subpeaks = figure;
        a_subpeaks = axes(f_subpeaks);
        
        %plot the experimental data
        plot(Energy,Intensity,'parent',a_subpeaks);
        hold(a_subpeaks,'on')
        
        %get the full fit
        full_fit = lorentzians([centers,widths,heights,cs],Energy);
        plot(Energy,full_fit,'parent',a_subpeaks);
        
        
        for sub_index = 1:numel(centers)
            sub_fit = lorentzians([centers(sub_index),widths(sub_index),heights(sub_index),cs(sub_index)],Energy);
            
            %scale things to look good.  
            [max_sub,max_sub_index] = max(sub_fit);
            sub_fit = sub_fit*Intensity(max_sub_index)/max_sub;
            
            plot(Energy,sub_fit,'parent',a_subpeaks,'color','green');
        end
        
        xlabel(a_subpeaks,'Energy (eV)')
        ylabel(a_subpeaks,'Intensity (A.U.)')
        %axis(a_subpeaks,[1.62 1.8 a_subpeaks.YLim])
        legend({'Data','Best Fit','Subpeaks'})
        
    end
    
    %now add the fit onto the data
    hold(a2,'on');
    fit = lorentzians(params,Energy);
    
    plot(Energy,fit,'parent',a2);
    hold(a2,'off');
    legend(a2,{'data','fit'});
    title(a2,['Energies: ',num2str(flip(centers'))]);
    
    %now go through each peak and show its value on a2, and then get the
    %intensity to assign a y value.
    for peak_index = 1:numel(centers)
        hold(a2,'on')
        plot([centers(peak_index) centers(peak_index)],a2.YLim,'parent',a2);
        hold(a2,'off')
        
        %get the index 
        [~,E_index] = min(abs(Energy - centers(peak_index)));
        
        %get the vertical intensity, fit it with a lorentzian
        box_width = 0;
        if box_width == 0
            vertical_intensity = image(:,E_index-box_width:E_index+box_width)';
        else
            vertical_intensity = sum(image(:,E_index-box_width:E_index+box_width),2)';
        end
        vertical_intensity = vertical_intensity / max(vertical_intensity(:));
        [max_height,max_location] = max(vertical_intensity);
        vmyoptions = optimset('MaxFunEvals',10000,'MaxIter',1000,'TolFun',1e-15,'TolX',1e-8);
        vparams = [max_location,20,max_height,20];
        vparams = lsqcurvefit(@lorentzians,vparams,1:size(image,1),vertical_intensity,vparams*0,vparams*0+1000,vmyoptions);
        
        % the fit, which we will plot
        vfit = lorentzians(vparams,1:size(image,1));
        
        %plot the data and the fit.
        plot(1:size(image,1),vertical_intensity,'parent',a4);
        hold(a4,'on')
        plot(1:size(image,1),vfit,'parent',a4);
        hold(a4,'off')
        
        %store the y pixel where we are saying the particles are.
        if peak_index == 1
            y = (1:numel(centers)).*0;
            E_index_vec = (1:numel(centers)).*0;
        end
        y(peak_index) = vparams(1);
        E_index_vec(peak_index) = E_index;
       
        pause(.01)
    end
    y_center =y(1);
    %save the results
    %y_center
    output(file_index).centers = centers;
    output(file_index).widths = widths;
    output(file_index).heights = heights;
    output(file_index).power = power;
    output(file_index).y = y;
    output(file_index).E_index = E_index_vec;
    output(runs).cs = cs;
    output(file_index).Tot=Tot;
end

global data
data = output;
% save data.mat
%load data.mat
num_peaks = numel(data(1).centers);
power = [data(:).power];
%sort it
[~,sorting_vector] = sort(power);
power = power(sorting_vector);
%pre-allocate the y matrix
y_matrix(numel(data),num_peaks) = 0;
w_matrix=y_matrix;
c_matrix=y_matrix;
for i = 1:numel(data)
   w_matrix(i,:) = data(i).widths;
   y_matrix(i,:) = data(i).heights+data(i).cs;
   c_matrix(i,:) = data(i).centers;
end
for i = 1:size(y_matrix,2)
   current_y = y_matrix(:,i);
   current_y = current_y(sorting_vector);
   y_matrix(:,i) = current_y;
   current_w = w_matrix(:,i);
   current_w = current_w(sorting_vector);
   w_matrix(:,i) = current_w;
   current_c = c_matrix(:,i);
   current_c = current_c(sorting_vector);
   c_matrix(:,i) = current_c;
end
 %save_matrix=[mag' y_matrix];
 %csvwrite('Bfield-peak centres.csv', save_matrix); 
%plot it
figure;
for i = num_peaks:-1:1
 
    
    plot(power,y_matrix(:,i),'LineStyle','-','Marker','o','DisplayName',['Energy = ',num2str(data(1).centers(i)),' eV'])
   % title(a,['Energy = ',num2str(data(1).centers(i)),' eV'])
   hold on
end
hold off
legend;
title('intensity');
%save the fitting results
%save('fitting_results.mat','data')
figure;
for i = num_peaks:-1:1
 
    
    plot(power,w_matrix(:,i),'LineStyle','-','Marker','o','DisplayName',['Energy = ',num2str(data(1).centers(i)),' eV'])
   % title(a,['Energy = ',num2str(data(1).centers(i)),' eV'])
   hold on
end
hold off
legend;
title('width');
figure;
for i = num_peaks:-1:1
 
    
    plot(power,c_matrix(:,i),'LineStyle','-','Marker','o','DisplayName',['Energy = ',num2str(data(1).centers(i)),' eV'])
   % title(a,['Energy = ',num2str(data(1).centers(i)),' eV'])
   hold on
end
hold off
legend;
title('centres');
f = figure;
aa = subplot(1,1,1,'parent',f);

jplot_replot(Energy,power,heat,aa);
colormap(aa,jet_plus_white);
colorbar;
ylabel('Gate Voltage');
xlabel('energy(eV)')
title("PL with diferent doping level")
end




%multi lorenzian function. 
function output = lorentzians(params,x)

%first determine how many lorentzians we are using, and make sure we were
%given reasonable inputs
if floor(numel(params)/4) ~= numel(params)/4
    error('wrong number of inputs, must be number of 4')
else
   num_peaks = numel(params)/4;
end

%reshape into matrix
params_matrix = reshape(params,[num_peaks,4]);

%break into lorentzian parameters
centers = params_matrix(:,1);
widths = params_matrix(:,2);
heights = params_matrix(:,3);
cs=params_matrix(:,4);
%go through and calculate the contribution from each lorentzian.  
for i = 1:numel(centers)
   contribution = lorentzian(centers(i),widths(i),heights(i),cs(i),x);
    
    if i == 1
        output = contribution;
    else
       output = output + contribution; 
    end
end

end
%single lorentzian function
function output = lorentzian(center,width,height,c,x)

numerator = height*((width/2)^2);
denominator = (x - center).^2 + (width/2)^2;

output = numerator ./ denominator;
output=output+c;

end

