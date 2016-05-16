#=
    create_word_list.jl
    By: Connor Riddell
    Gets all words present in files
    Usage: julia create_word_list.jl txt-word-frequency-files-folder
=#

# sent input argument as txt file directory
txt_file_dir = ARGS[1]

#=
    Main funciton to open all files and write words to text file
=#
function main()
    # get all files in directory
    txt_files = readdir(txt_file_dir)
    
    # open word list file to write to
    word_list_f = open("word_list_current.txt", "w")

    # loop over all files in directory
    for file in txt_files
        println("Processing $file file...")
        
        # open file and read lines
        f = open(txt_file_dir * file)
        lines = readlines(f)
        close(f)
        
        # get word from line and write to new file
        for line in lines
            line_arr = split(line)
            word = utf8(line_arr[1])

            write(word_list_f, "$word\n")
        end # inner for
    end # outter for
    
    # close new file
    close(word_list_f)
end # main

main()
