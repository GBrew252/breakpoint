#=
    create_data_files.jl
    By: Connor Riddell
    Creates directory of files with name being each unique word
        and the frequency for each year it appears.
=#

#=
    Main function to process each txt file into words associated with each year
=#
function main()
    # Error checking user input
    # check number of args and that args are the correct type
    if length(ARGS) != 2
        println("Need 2 agruments. $(length(ARGS)) given.")
        exit()
    end
    if !isfile(ARGS[1])
        println("First argument must be metadata file.")
        exit()
    end
    if !isdir(ARGS[2])
        println("Second argument must be frequency files folder.")
        exit()
    end
    
    # set meta_file and freq_folder from args
    meta_file_name = ARGS[1]
    freq_file_folder = ARGS[2]
    
    # get metadata for the files
    meta_file = open(meta_file_name)
    texts_years = readlines(meta_file)

    # dictionary for file and year
    text_year_dict = Dict()

    # loop over file and map file to year in dictionary
    for line in texts_years
        split_line = split(line, "\t")
        text_year_dict[split_line[1]] = int(chomp(split_line[2]))
    end # for

#-------------------------------- Data Loading ------------------------------------

    # Make array of all file names
    freq_files = readdir(freq_file_folder)
    
    # array of tuples for word and its dictionary
    word_tup_arr = Array(Tuple,0)
    # array of words to easily test if words have already been processed
    processed_words = Array(Any, 0)

    count = 1
    # loop over all files in directory
    for file in freq_files
        println("$count:  Working on file: $file.")
        count += 1

        # open file and readlines into array
        f = open(freq_file_folder * file)
        lines = readlines(f)

        # get filename w/o extension and get year for file
        file_name = split(file, ".txt")[1]
        file_year = text_year_dict[file_name]
        
        # loop over lines in files to get word and frequency
        for line in lines
            # split line by tab index 1 = word, index 2 = freq
            split_line = split(line, "\t")
            word = split_line[1]
            freq = chomp(split_line[2])
            
            # check if word has already been processed
            if word in processed_words
                # find index of word in array
                index = find(word .== processed_words)[1]
                # check if year already exists, if it does, add to the frequency already saved
                if file_year in word_tup_arr[index][2]
                    word_tup_arr[index][2][file_year] = word_tup_arr[index][2][file_year] + freq
                else
                    # create new year, frequency entry
                    word_tup_arr[index][2][file_year] = freq
                end # inner if/else
            else
                # new words are added to the array and array of tups with freq in dictionary
                push!(processed_words, split_line[1])
                push!(word_tup_arr, (split_line[1], Dict()))
                word_tup_arr[length(word_tup_arr)][2][file_year] = freq
            end # if/else
        end # inner for
        close(f)
    end # outter for

#------------------------------------ File Creation ------------------------------------------

    println("Creating files...")
    
    # check if new directory already exist so no error
    if !isdir("word_date_freqs/")
        mkdir("word_date_freqs/")
    end # if

    # loop over previous array 
    for tup in word_tup_arr
        # get word and open file for that word
        word = tup[1]
        word_f = open("word_date_freqs/" * word * ".tsv", "w+")

        println("Creating $word file...")

        # write each year and frequency to the file
        for key in sort(collect(keys(tup[2])))
            write(word_f, "$key\t$(tup[2][key])\n")
        end # inner for
        close(word_f)
    end # outter for

end # main

main()
