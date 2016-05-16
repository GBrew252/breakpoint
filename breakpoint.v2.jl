#=
    breakpoint.v2.jl
    By: Connor Riddell
    Find word frequency in each year from pre-processed word files
    Usage: julia breakpoint.v2.jl word-folder
=#

using UnicodePlots
word_folder = ARGS[1]

#=
    Function to tell whether word is present in library
    Argument(s): String of word querried for
    Return: Boolean
=#
function has_word(querry::String)
    # read in directory and check if word in directory
    word_files = readdir(word_folder)
    if (querry * ".tsv") in word_files
        return true
    else
        return false
    end # if/else
end # has_word

function get_word(querry::String, ordered_years::Array, ordered_freqs::Array)
    f = open(word_folder * querry * ".tsv") 
    date_freqs = readlines(f)
    for line in date_freqs
        split_line = split(line, "\t")
        push!(ordered_years, int(split_line[1]))
        push!(ordered_freqs, float(chomp(split_line[2])))
    end # end for
end # get_word

#=
    Main function for crunching data
=#
function main()
     
    while true
        # print message to user for word to be searched for
        print("Type word you would like frequency for: ")

        # get user input and remove newline at end
        queried_word = chomp(readline(STDIN))
        if queried_word == "exit()"
            break
        end # if statement
        # user pressed enter
        if queried_word == ""
            continue
        end # if statement

        if !has_word(queried_word) 
            println("No results found for querry \"$queried_word\"...")
            continue
        end # if statement

        # sort the keys by chronology and save the key and value to seperate arrays
        ordered_year = Array(Int64, 0)
        ordered_freq = Array(Float64, 0)
        get_word(queried_word, ordered_year, ordered_freq)


        # create line plot
        print(lineplot(ordered_year, ordered_freq, title = "\""*queried_word*"\"" * " frequency in parts per million", color = :blue))
        print(barplot(ordered_year, ordered_freq, title = "\""*queried_word*"\"" * " frequency in parts per million", color = :blue))

    end # while loop

end # main function

main()
