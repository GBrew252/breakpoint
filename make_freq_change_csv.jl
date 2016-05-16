#=
    make_freq_change_csv.jl
    By: Connor Riddell
    Loop over the word files and create a comma seperated file of
        the change over each year
=#

#=
    Main function to create csv file
=#
function main()
    # create/open csv file
    f = open("word_freq_diffs.csv", "w") 

    # write comma first. This will make the first cell empty when
    # imported to excel.
    write(f, ",")

    # write the year ranges as the top row
    for i = 1400:1699
        write(f, "$i-$(i+1),")
    end
    write(f, "\n") # new line
    
    count = 1 # processed file count
    word_files = readdir("word_date_freqs") # read in files

    # loop over files
    for file in word_files
        # for every 1000 files processed amount of files processed
        if count%1000 == 0
            print("$count files processed\n")
        end

        # create dictionary with keys from 1400 to 1700
        # set all values to 0
        year_freqs = Dict()
        for i in 1400:1700
            year_freqs[i] = 0
        end
        
        # open file and readlines
        word_f = open("word_date_freqs/" * file)
        lines = readlines(word_f)
        close(word_f)

        # loop over lines and add frequency for each year
        # in file
        for line in lines
            split_line = split(line, "\t")
            year = int(split_line[1])
            freq = int(chomp(split_line[2]))
            
            year_freqs[year] = freq
        end 
        
        # loop over years and calculate absolute changes
        # add changes to array
        freq_changes = Array(Int,0)
        for year in 1400:1699
            freq_diff = abs(year_freqs[year] - year_freqs[year+1])
            push!(freq_changes, freq_diff)
        end
        
        # write each of the differences to the file 
        write(f, "$(split(file, ".tsv")[1]),")
        for freq_diff in freq_changes
            write(f, "$freq_diff,")
        end

        # write new line for next word
        write(f, "\n")
        count += 1
    end
    
    # close file
    close(f)
end

main()
