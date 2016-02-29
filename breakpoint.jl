#=
    breakpoint.jl
    Breakpoint analysis to find word frequency in texts
    By: Connor Riddell
=#

using JLD
using UnicodePlots

#=
    Function to read in lines for tsv file of words and their frequencies
    then add them to an array of tuples.
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
    Returns dictionary of key = file name and value = year(int)
=#
function crunch_metadata()
    metadata_path = "/Users/connor/Desktop/breakpoint/freq_sample_years.tsv"

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
    Function to calculate home many words were in each given year for the sample size
    Arguments: N/A for now 
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
    # print starting statement and begin looking at data in files
    println("Starting data crunch...")
    word_files = readdir(ARGS[1]) # get directory where all files are
   
    # crunch data from each file
    crunched_data = Array((Any,Any), 0)
    counter = 1
    for file in word_files
        file_path = string(ARGS[1], file) # get file path

        # print how many files are left every thousand processed
        if counter % 100 == 0
            println("Crunched ", counter, " files. ", (length(word_files)-counter), " files to go...")
        end

        push!(crunched_data, crunch_word_freq(file_path, file)) # add data to array in form of tuple
        counter += 1
    end

    # get metadata
    println("Crunching metadata...")
    txt_year_dict = crunch_metadata() # crunch basic metadata
    
    words_per_year = crunch_wpy(crunched_data, txt_year_dict)
    println(words_per_year)
    println(length(collect(keys(words_per_year))))
    

    #save("crunched_data.jld","crunched_data",crunched_data)
    while true
        # print message to user for word to be searched for
        print("Type word you would like frequency for: ")

        # get user input and remove newline at end
        queried_word = chomp(readline(STDIN))
        if queried_word == "exit()"
            break
        end

        println("Printing all frequencies for word, \"" * queried_word * "\" for given years:")
        
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
                    end
                end
             end
        end
        
        # sort the keys by chronology and save the key and value to seperate arrays
        ordered_year = Array(Int64, 0)
        ordered_freq = Array(Float64, 0)
        for key in sort(collect(keys(year_with_freq)))
            # print each year with the frequency of the word
            println("$key => $(year_with_freq[key])")

            # push the data to each respective sorted arrays
            push!(ordered_freq, (year_with_freq[key] / words_per_year[key]))
            push!(ordered_year, key)
        end
        
       # create line plot
       print(lineplot(ordered_year, ordered_freq, title = "\""*queried_word*"\"" * " frequency"))
       print(barplot(ordered_year, ordered_freq, title = "\""*queried_word*"\"" * " frequency"))


    end

end

main()
