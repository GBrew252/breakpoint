#=
    make_freq_change_csv.v2.jl
    By: Connor Riddell
    Crunch word frequency by file and match it to a year through the metadata file.
        It's all wrapped up in a structure that is an array of tuples where the first index is the year
        and the second index is a dictionary of words and frequencies. Then write to csv file with the change
        over each year. Change is regularized by number of words per year and multiplied by one million to read
        easier.

    Usage: julia make_freq_change_csv.v2.jl  metadata_file(ARG 1) text_frequency_file_directory(ARG 2) 
=#

using UnicodePlots

# set argument values
metadata_path   = ARGS[1]
txt_dir         = ARGS[2]

#=
    Function to read in lines for tsv file of words and their frequencies
    then add them to an array of tuples.
    Arguments: file path (String), file name (String)
    Returns tuple of file name and array of sorted word frequencies
=#
function crunch_word_freq(file_path::String, file_name::String)
    # open text file, word and frequency, tab seperated
    f = open(file_path)
    lines = readlines(f) # read all the lines in
    close(f)

    # loop over lines and add them to array of tuples
    word_freq_arr = Array((Int64, SubString{UTF8String}), 0)
    for l in lines
        # split lines by words (words and frequency number)
        if ismatch(r"^\t.*", l)
            continue
        else
            l_array = split(l)
            
            # cast each part into needed types
            word_freq = parseint(l_array[2])
            word = utf8(l_array[1])

            # push them onto array as tuple of (frequency(num), word)
            push!(word_freq_arr, (word_freq,word)) 
        end
    end

    # sort word_freq from lowest to highest frequency
    sorted_word_freq = sort(word_freq_arr)

    #= print word in frequency order
    for freq in sorted_word_freq
        println(freq)
    end
    =#

    # create tuple with name and sorted array
    tup_freq = (file_name, sorted_word_freq)

    # Return array
    return tup_freq
end

#=
    Function to read in metadata for word frequency files
    Saves file name and year to dictionary
    Arguments: N/A
    Returns dictionary of key = file name and value = year(int)
=#
function crunch_metadata()
    # open text file for metadata on text
    f = open(metadata_path)
    lines = readlines(f)
    
    # split each line into arrays and only take file name and year to dictionary 
    txt_year_dict = Dict()
    for l in lines
        # split by words
        l_array = split(l)

        # try/catch to get rid of file names that have no date associated (90 files)
        try
            # cast to needed types
            year = parseint(l_array[2])
            file = utf8(l_array[1] * ".txt") # add .txt so it can be found later

            # push to array of tuples
            txt_year_dict[file] = year
        catch
            #println("Caught error")
        end
    end
    
    # Return dictionary 
    return txt_year_dict
end

#=
    Find words per Year - Function to calculate home many words were in each given year for the sample size
    Arguments: crunched_data(array), (dictionary) of text names and frequencies 
    Returns: Dictionary of words as key and word amount as value
=#
function crunch_wpy(crunched_data::Array, txt_year_dict::Dict)    
    # dictonary with key = year and value = amount of words
    wpy_dict = Dict()

    # for tupple in array of tupples
    for tup in crunched_data
        # get year from dictionary
        year = txt_year_dict[tup[1]]

        # loop over all frequencies and add them for total words
        total_words = 0
        for pair in tup[2]
            total_words += pair[1]
        end
        
        # check if key already exists
        if haskey(wpy_dict, year)
            # add to value if key already exists
            wpy_dict[year] += total_words
        else
            # create new key value pair
            wpy_dict[year] = total_words
        end # if/else statement
        
    end # for loop
    
    return wpy_dict
end

#=
    Main function for crunching data
=#
function main()
    # error check input arguments
    if length(ARGS) != 2
        println("Need 2 agruments. $(length(ARGS)) given.")
        exit()
    end # if
    if !isfile(metadata_path)
        println("First argument must be metadata file.")
        exit()
    end # if
    if !isdir(txt_dir)
        println("Second argument must be frequency files folder.")
        exit()
    end # if

    # print starting statement and begin looking at data in files
    println("Starting data crunch...")
    word_files = readdir(txt_dir) # get directory where all files are
    word_list = Array(Any,0)

    # import word list
    word_list_f = open("word_list_current_uniq.txt")
    raw_lines = readlines(word_list_f)
    close(word_list_f)
    
    # get rid of new line at end of words
    for line in raw_lines
        push!(word_list, chomp(line))
    end # for 

    # crunch data from each file
    crunched_data = Array((Any,Any), 0)
    counter = 1
    for file in word_files
        file_path = string(txt_dir, file) # get file path

        # print how many files are left every thousand processed
        if counter % 100 == 0
            println("Crunched ", counter, " files. ", (length(word_files)-counter), " files to go...")
        end # if statement

        push!(crunched_data, crunch_word_freq(file_path, file)) # add data to array in form of tuple
        counter += 1
    end # for loop

    # get metadata
    println("Crunching metadata...")
    txt_year_dict = crunch_metadata() # crunch basic metadata
    
    words_per_year = crunch_wpy(crunched_data, txt_year_dict)
    
    # to be used for frequencies later
    year_freqs = Dict()

    # open csv file
    csv_f = open("word_freq_diffs.csv", "w")
    # write comma first. This will make the first cell empty when
    # imported to excel.
    write(csv_f, ",")

    # write the year ranges as the top row
    for i = 1400:1699
        write(csv_f, "$i-$(i+1),")
    end #for
    write(csv_f, "\n") # new line
    
    counter = 0
    for queried_word in word_list 
        # dictionary for year with frequency as value
        year_with_freq = Dict()
        # unwrap this massive structure to get to the words and frequencies
        for file in crunched_data
            for tup in file[2]
                if queried_word in tup # if word in tuple get the year for the text
                    file_year = txt_year_dict[file[1]]
                    
                    # check dictionary to see if year already exists
                    dict_keys = collect(keys(year_with_freq)) 
                    if file_year in dict_keys
                        # if year already exists, add frequency to saved frequency
                        year_with_freq[file_year] += tup[1]
                    else
                        # else make a new key value pair
                        year_with_freq[file_year] = tup[1]
                    end # if/else statement
                end # if statement
             end # inner for loop
        end # outter for loop

        # write word to file
        write(csv_f, "$queried_word,")
        
        # set all values to 0
        for i in 1400:1700
            year_freqs[i] = 0
        end # for
        
        for key in collect(keys(year_with_freq))
            year_freqs[key] = (year_with_freq[key] / words_per_year[key] * 1000000)
        end # for

        # loop over years and calculate absolute changes
        # add changes to array
        freq_changes = Array(Float64,0)
        for year in 1400:1699
            freq_diff = abs(year_freqs[year] - year_freqs[year+1])
            push!(freq_changes, freq_diff)
        end
                
        # write each of the differences to the file 
        for freq_diff in freq_changes
            write(csv_f, "$freq_diff,")
        end
                    
        # write new line for next word
        write(csv_f, "\n")

        counter += 1
        println("$counter word diffs written...")
        if counter % 1000 == 0
            println("$counter word diffs written...")
        end # if
    end # for loop

end # main function

main()

