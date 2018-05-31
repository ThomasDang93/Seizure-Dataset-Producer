txt=dir('*summary.txt*'); % extract tet files that have "summary.txt" as a substring in the filename
seizurePoint = 0; % representation of the end point in a seizure
endOfFile = []; %   the remaining ending portion of a seizure file after it has been extracted
newRecord = []; %   file that contains data from endOfFile and the record of a seizure file concatenated together
seizureExists = []; %   flag that displays whether or not seizure exists
seizureCounter = 0;
totalSeizures = 0;

%   Loop that converts all edf files to mat files by grabbing text data from files that are indicated as 
%   "summary.txt". All edf files must be in same directory as dataRetriever.m in order to be converted to 
%   mat files.
for k=1:length(txt)
    textgrab(txt(k).name)
    string_txt = strcat(txt(k).name, '.mat');
    text = ans;
    %save(string_txt, 'text')
    %movefile(string_txt, 'matfiles')
end

%   List of regular expression rules that are needed to parse the summary.txt
%   file for extraction of each seizure file.
exp_start = regexp(text,'Start');
exp_end = regexp(text,'End');
exp_sec = regexp(text,'seconds');
exp_time = regexp(text,'Time:');
exp_filename = regexp(text,'\<chb\w*');
exp_file = regexp(text,'File');
exp_name = regexp(text, 'Name:');
exp_num = regexp(text, 'Number');
exp_of = regexp(text, 'of');
exp_seiz = regexp(text, 'Seizures');
exp_zero = regexp(text, '0');
exp_positive_int = regexp(text, '^[0-9]*[1-9][0-9]*$');

[matRows,matColumns] = size(exp_filename); %sets the index traversal limits for the loops below

% calculates the total number of seizures before performing data extraction
for q=1:matRows
    for m=1:matColumns
        if isequal(exp_num{q,m},1) == 1 && isequal(exp_of{q,m+1},1) == 1 && isequal(exp_seiz{q,m+2},1) == 1 && isequal(exp_positive_int{q,m+5},1) == 1
            totalSeizures = totalSeizures + str2double(text(q,m+5));
        end
    end
end


% Main loop that performs all operations of extracting data from files with
% "summary.txt"
for i=1:matRows
    for j=1:matColumns  
        
        %   When a seizure file name is found, the file is loaded in and
        %   preparation for extraction begins.
        
        if exp_filename{i,j} == 1
            
            %IMPORTANT: this must be reinitialized to 0 at every interation to main consistency of seizure point value
            seizurePoint = 0;  
            
            seizureExists = [];
            filename = strcat(text(i,j),'.mat');
            
            %file is loaded in workspace
            load(filename); 
            disp(filename)
            
            %concatenates record at the end of endOfFile
            newRecord = [endOfFile record]; 
            disp('newRecord generated')
            
            %the total number of columns at endOfFile must be saved and used to scale up seizure start and end times.
            [~,endOfFileColumns] = size(endOfFile);
            
            %Sometimes seizure files can have multiple seizures. Which
            %means that it is necessary to use numeric values within
            %preictal/interictal file names. These values are used to avoid file
            %name duplications.
            preictalNum = 1;
            interictalNum = 1;
        end
        
        %determines a flag value for the existance of a seizure.
        
        if isequal(exp_num{i,j},1) == 1 && isequal(exp_of{i,j+1},1) == 1 && isequal(exp_seiz{i,j+2},1) == 1 && isequal(exp_zero{i,j+5},1) == 1
            seizureExists = 0;
        elseif isequal(exp_num{i,j},1) == 1 && isequal(exp_of{i,j+1},1) == 1 && isequal(exp_seiz{i,j+2},1) == 1 && isequal(exp_positive_int{i,j+5},1) == 1
            seizureExists = 1;
        end
        
        %The seizure start time is processed to a compatible format for
        %classifying seizure states.
        
        if  isequal(exp_start{i,j},1) == 1 && isequal(exp_time{i,j+1},1) == 1 && isequal(exp_sec{i,j+3},1) == 1
            seizStartStr = text{i,j+2};
            seizStartNum = str2double(seizStartStr);
            
            %256 is used because it translates to one second
            seizStartSec = seizStartNum * 256; 
            
            %seizure start time is scaled up with the total column number from endOfFile
            seizStart = seizStartSec + endOfFileColumns;    
        end
        
        %The seizure end time is processed to a compatible format for
        %classifying seizure states. Then the seizureClassifier method is
        %called to determine preictal and interictal segments of the
        %seizure file.
        
        if  isequal(exp_end{i,j},1) == 1 && isequal(exp_time{i,j+1},1) == 1 && isequal(exp_sec{i,j+3},1) == 1
            seizEndStr = text{i,j+2};
            seizEndNum = str2double(seizEndStr);
            
            %256 is used because it translates to one second
            seizEndSec = seizEndNum * 256;  
            seizEnd = seizEndSec + endOfFileColumns;
            
            %Seizure classifier is called to divide and classify interictal
            %and preictal states. this method will return seizurePoint so
            %that a new endOfFile can be calculated.
            
            %The variables preictalNum and interictalNum are returned to avoid file name duplications
            %when multiple seizures are detected in a file.
            [seizurePoint,preictalNum,interictalNum] = seizureClassifier(newRecord, seizStart, seizEnd, seizurePoint,filename, preictalNum,interictalNum);
            seizureCounter = seizureCounter + 1;
        end
        
        if seizureCounter == totalSeizures
            break
        end
        
        %The last remaining columns of a seizure file that were not classified into
        %preictal and interictal are saved into endOfFile so that it can be
        %concatenated with the next seizure file.
        
        if (isequal(exp_file{i,j},1) == 1) && (isequal(exp_name{i,j+1},1) == 1) && (isequal(exp_filename{i,j+2},1) == 1)
            
            %when a seizure does not exist in a file, then that entire file
            %is saved to endOfFile.
            if seizureExists == 0
                [rows,~] = size(newRecord);
                endOfFile = zeros(rows, length(newRecord)); %initialize endOfFile into matrix of zero for better computation time
                p=1;
                for t=(seizurePoint+1):length(newRecord)
                    endOfFile(:,p) = newRecord(:,t);
                    p=p+1;
                end
            %when seizures do exist in a file, then the remaining portion of the file that were not classified 
            %into preictal and interictal states are saved to endOfFile
            elseif seizureExists == 1
                [rows,~] = size(newRecord);
                endOfFile = zeros(rows, length(newRecord)-seizurePoint);    %initialize endOfFile into matrix of zero for better computation time
                p=1;
                for t=(seizurePoint+1):length(newRecord)
                    endOfFile(:,p) = newRecord(:,t);
                    p=p+1;
                end
            end
        end  
    end
    if seizureCounter == totalSeizures
        break
    end
end

