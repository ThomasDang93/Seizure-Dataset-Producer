%this simple for loop script will convert all edf files to mat files. the
%edf files must be in the same directory as this program.
edf=dir('*.edf');
mkdir('matfiles')
for k=1:length(edf)
    [header, record] = edfread(edf(k).name); 
    string_edf = strcat(edf(k).name, '.mat');
    save(string_edf, 'record');
    movefile(string_edf, 'matfiles')
end

