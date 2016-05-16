Breakpoint Project

Collaboration with the SLU English Department

Goal: Process raw XML texts from the EEBO corpus and process the word frequency. From there, find change between years to see what years have significant changes in word frequency.

Progression:

    parse_XML.jl - Take raw XML EEBO texts and create file of text name corresponding to year. Also  create folder of files with the text name as the file name and the contents being the unique words with their frequencies.

    |
    V

    create_data_files.jl - Parse through all text files and create folder of files with the names being the unique words and the contents being the year and frequency for that year.

    |
    V

    make_freq_change_csv.jl - Open all the word data files and calculate the differences between the years for each word. Create csv file and write the change from year 1400 to year 1700.

    |
    V

    csv file can be imported into excel or another spreadsheet editor to manipulate the data.
