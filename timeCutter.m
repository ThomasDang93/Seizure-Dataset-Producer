mkdir('data')
file=dir('*_*_*_*.edf.mat');
timeLength=7680;
filenumber=1;
for k=1:length(file)
    load(file(k).name)
    [row,~]=size(data);
    dataRecord = zeros(row, timeLength); 
    z=1;
    for j=1:length(data)
        dataRecord(:,z) = data(:,j);
        z=z+1;
        if (z-1)==timeLength
            fileNumberString = num2str(filenumber);
            string = strcat(fileNumberString,'_', file(k).name);
            save(string, 'dataRecord');
            filenumber = filenumber + 1;
            z=1;
            movefile(string, 'data')
            clear dataRecord
        elseif j == length(data) 
            [r,~]=size(data);
            lastDataRecord = zeros(r, z-1);
            y=1;
            for i=1:(z-1)
                lastDataRecord(:,y) = dataRecord(:,i);
                y=y+1;
            end
            fileNumberString = num2str(filenumber);
            string = strcat(fileNumberString,'_',file(k).name);
            save(string,'lastDataRecord')
            movefile(string,'data')
            clear lastDataRecord
        end      
    end
end
