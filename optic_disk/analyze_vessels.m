function analyze_vessels(rebuild_classifier)
    addpath('vessel_draw');
    
    results_file = 'analyze_results.txt';
    
    if(rebuild_classifier == 1)
        %Build training set
        build_dataset_vessels(1,0);
        build_dataset_vessels(0,1);

        %Train the classifier
        train_vessels();
    end
    
    %Open the file to test all of this against
    test_file = 'vessel_draw_test.dataset';
    fid = fopen(test_file);
        
    %Get the first line of the file
    tline = fgetl(fid);
    if(isnumeric(tline) == 1 && tline == -1)
        disp(['Check the contents of ', test_file, ' it appears to be empty!']);
        return;
    else
        disp(['Reading: ', test_file]);
    end
    disp('-----------------------------');
    
    %Close the file
    fclose(fid);
    
    %Open the file to determine which images to use for testing 
    fid = fopen(test_file, 'r');
    paths = textscan(fid,'%q %d %q %*[^\n]');
    fclose(fid);
    
    %Run through the images and make sure that they exist
    for k=1:size(paths, 2)
        pid = char(paths{1}{k});
        time = num2str((paths{2}(k)));
        vessel_image = char(paths{3}{k});
    
        %See if original image exists
        img_path_exists = get_path(pid, time);
        
        %Get the image traced by hand
        super_img = imread(vessel_image);
    end
    
    output_results = zeros(size(paths, 1), 6);
        
    
    %Iterate over all images to use for training 
    for k=1:size(paths, 2)
        pid = char(paths{1}{k});
        time = num2str((paths{2}(k)));
        vessel_image = char(paths{3}{k});
       
        %Get the image run by the algorithm
        calced_img = find_vessels(pid, time, 0);
        
        %Get the image traced by hand
        super_img = imread(vessel_image);
        total_positive_count = 0;
        total_negative_count = 0;
        for y=1:size(super_img,1)
            for x=1:size(super_img,2)
                if(super_img(y,x) == 1)
                    total_positive_count = total_positive_count + 1;
                else
                    total_negative_count = total_negative_count + 1;
                end
            end
        end
        
        %Check the sizing of the images compared to each other
        if(size(calced_img, 1) ~= size(super_img, 1) || size(calced_img, 2) ~= size(super_img, 2))
            disp(['Images Not Same Size: ', pid, ' - ', time]);
            continue;
        end

        %Get some statistics about the quality of the pixel classification
        total_count = 0;
        true_positive = 0;
        true_negative = 0;
        false_positive = 0;
        false_negative = 0;
        for y=1:size(calced_img,1)
            for x=1:size(calced_img,2)
                if(super_img(y,x) == 1 && calced_img(y,x) == 1)
                    true_positive = true_positive + 1;
                elseif(super_img(y,x) == 0 && calced_img(y,x) == 0)
                    true_negative = true_negative + 1;
                elseif(super_img(y,x) == 0 && calced_img(y,x) == 1)
                    false_positive = false_positive + 1;
                elseif(super_img(y,x) == 1 && calced_img(y,x) == 0)
                    false_negative = false_negative + 1;
                end
                total_count = total_count + 1;
            end
        end
        
        if(total_count ~= (total_negative_count + total_positive_count))
            disp(['total_count (', num2str(total_count),') and total_negative + total_positive_count (', num2str(total_negative_count + total_positive_count),') Do not match']);
            continue;
        end
        
        output_results(k,1) = true_positive;
        output_results(k,2) = true_negative;
        output_results(k,3) = false_positive;
        output_results(k,4) = false_negative;
        output_results(k,5) = total_positive_count;
        output_results(k,6) = total_negative_count;
        disp('--------------------------------------');
    end

    fout = fopen(results_file, 'w');
    
    disp('----------Results----------');
    line = 'Img, True Positive, True Negative, False Positive, False Negative, Total Positive Count, Total Negative Count';
    disp(line);
    fprintf(fout, '%s', line);
    %Disp to user the results from this badboy
    for k=1:size(paths, 2)
        pid = char(paths{1}{k});
        time = num2str((paths{2}(k)));
        
        numline = num2str(output_results(k,1));
        for l=2:size(output_results,2)
            numline = [numline, ', ', num2str(output_results(k,l));];
        end
        
        line = [pid, '(', time, '), ', numline];
        disp(line);
        fprintf(fout, '%s\n', line);
    end
    
    fclose(fout);
end