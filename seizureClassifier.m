%This function implements an algorithm that classifies interictal and
%preictal seizure states.
function [seizurePoint,preictalNum,interictalNum] = seizureClassifier(newRecord, seizStart, seizEnd, seizurePoint, filename,preictalNum,interictalNum)

%pre represents the value of the preictal used for classification.
pre = 921600; %256 = 1 second

%This loop will parse through the raw seizure file and produces interictal
%and preictal states.
for f=1:length(newRecord)
    
    %This if statement will allow access when the index is within a seizure
    %timeframe.
    if((seizStart <= f) && (f <= seizEnd))
        
        %If the previous index of the seizure file column is within a seizure timeframe, then it is
        %implied that preictal and interictal were already classified.
        %Therefore we can skip any remaining operations and continue the
        %loop iteration.
        if((seizStart <= (f-1)) && ((f-1) <= seizEnd))
            continue
        end
        
        %This will classify preictal segments if the time between the
        %seizurePoint and seizure start time is less than  or equal to the value of our
        %preictal variable. Remember that seizurePoint is the
        %representation of the end point of the previous seizure. And preictal
        %always comes before the start of a new seizure.
        if (((f-1) > seizurePoint) && ((f-pre) <= seizurePoint))
            disp('Classifying preictal segments...')
            [rows,~] = size(newRecord); %   the number of rows in the seizure file are defined
            data = zeros(rows, f-(seizurePoint+1)); %preictal is initalized to matrix of zero for computation efficiency
            v=1;
            
            %preictal segments of the seizure file are transferred to a new
            %preictal matrix.
            for b=(seizurePoint+1):(f-1)
                data(:,v) = newRecord(:,b);
                v=v+1;
            end
            disp('Preictal generation complete.')
            
            %preictal file is generated and saved to a directory
            preictalStr = num2str(preictalNum);
            stringPreictal = strcat('Preictal_', preictalStr, '_', filename);
            save(stringPreictal, 'data');
            disp('Preictal saved..')
            
            %preictal file number must be incremented to avoid file name duplications
            preictalNum = preictalNum + 1;
            
        %this will classify a preictal segment when the timeframe between
        %seizurePoint and seizureStartTime is less than the value of
        %preictal.
        elseif ((f-pre) > seizurePoint)  
            disp('Classifying preictal segments...')
            [rows,~] = size(newRecord); %row of seizure file is defined
            data = zeros(rows, f-(f-pre));%preictal must be initialized to a matrix of zeros for computer efficiency.
            v=1;
            
            %preictal segments are transferred to a new preictal matrix
            for b=(f-pre):(f-1)
                data(:,v) = newRecord(:,b);
                v=v+1;
            end
            disp('Preictal generation complete.')
            
            %preictal file is generated and saved to a directory
            preictalStr = num2str(preictalNum);
            stringPreictal = strcat('Preictal_', preictalStr, '_', filename);
            save(stringPreictal, 'data');
            disp('Preictal saved..')
            
            
            %preictal file name number must be incremented to avoid file
            %name duplications
            preictalNum = preictalNum + 1;
        end
        
        %This will classify an interictal state if there are any seizure
        %segments that are between seizurePoint and the start of the
        %preictal segments. Remember, interictal always comes before
        %preictal.
        if (((f-pre)-1) > seizurePoint)
            disp('Classifying interictal')
            [rows,~] = size(newRecord); 
            data = zeros(rows, (f-pre)-(seizurePoint+1));
            v=1;
            for b=(seizurePoint+1):((f-pre)-1)
                data(:,v) = newRecord(:,b);
                v=v+1;
            end
            disp('Interictal generation complete')
            interictalStr = num2str(interictalNum);
            stringInterictal = strcat('Interictal_', interictalStr, '_', filename);
            save(stringInterictal, 'data');
            disp('Interictal saved..')
            interictalNum = interictalNum + 1;
            
        end
    else
        continue
    end
end
%the seizurePoint must be returned so that its value can be used for the
%next seizure file. This is vital for the calculation of
%preictal/interictal states when we are dealing with multiple seizure file
%recordings of the same patient.
seizurePoint = seizEnd;


