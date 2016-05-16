#=
    parse_XML.jl
    By; Connor Riddell
    Scan over xml file and create word txt-year file and a directory
        of the txts with words and their frequencies
    Usage: julia parse_XML.jl raw-XML-directory
=#

using LightXML
include("roman_decimal.jl")

# lowercase letters of alphabet
alpha_letters = ['a','b','c','d','e','f','g','h','i','j',
'k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']

# punctuation array
punctuation = ['!','"','#','$','%','&','\'','(',')','*','+',',',
'-','.','/',':',';','<','=','>','?','@','[','\\',']','^','_','`',
'{','|','}','~','—','▪','•']

#=
    Function to clean unwanted character off string
    Argument: String
    Return: String (cleaned)
    Code pulled from TextMining.jl/src/text_processing.jl
=#
function clean(string)
    string = Base.lowercase(string)
    sarray = convert(Array{typeof(string)}, Base.split(string))
    x = 1
    
    # added to strip vertical bars left in strings
    for x in 1:length(sarray)
        word = join(split(sarray[x], char(0x2223)))
        sarray[x] = word
    end # for loop
    i = 1
    
    add_words = Array(String, 0) # array of word broken apart to be added back in

    # loop to strip all punctuation out of string
    while i <= length(sarray)
        sarray[i] = Base.strip(sarray[i], punctuation)
        
        # added code to break apart hyphen from xml formatting
        if !ismatch(r".*-.*", sarray[i])
            for punct in punctuation
                if punct in sarray[i]
                    i_split = split(sarray[i], punct)
                    sarray[i] = i_split[1]
                    push!(add_words, i_split[2]) # add new words to array
                 end # if statement
             end # for loop
        end # if statement

        i += 1
    end # while loop
    
    # add all words in add_words to total array
    for word in add_words
       push!(sarray, word)
    end # for loop
    
    return sarray
end # clean function

#=
    function to parse through the xml file structure
    Arguments: String of document path
    Return: string of text
    Code pulled from TextMining.jl/src/text_processing.jl
=#
function parse_xml(doc_path)
    xdoc = parse_file(doc_path)
    xroot = root(xdoc)
    ces = get_elements_by_tagname(xroot, "EEBO")
    children = collect(child_elements(ces[1]))

    if(name(children[2]) == "GROUP")
        ces = get_elements_by_tagname(ces[1], "GROUP")
    else
        ces = get_elements_by_tagname(ces[1], "TEXT")
    end

    body = content(ces[1])
    text = string(body)

    free(xdoc)

    return text
end # function parse_xml

#=
    Function to get the meta data for the texts
    Arguments: string of document path
    Return: Array of strings
    Code pulled from TextMining.jl/src/text_processing.jl
=#
function get_metadata(doc_path)
    metadata = Array(String,4)
    xdoc = parse_file(doc_path)
    xroot = root(xdoc)
    ces = get_elements_by_tagname(xroot, "HEADER")
    filedesc = get_elements_by_tagname(ces[1], "FILEDESC")
    source = get_elements_by_tagname(filedesc[1], "SOURCEDESC")
    bib = get_elements_by_tagname(source[1], "BIBLFULL")
    titlestmt = get_elements_by_tagname(bib[1], "TITLESTMT")
    author = get_elements_by_tagname(titlestmt[1], "AUTHOR")

    if length(author) == 0
        metadata[1] = "NA"
    else
        author = content(author[1])
        author = string(author)
        metadata[1] = author
    end

    title = get_elements_by_tagname(titlestmt[1], "TITLE")
    if length(title) == 0
        metadata[2] = "NA"
    else
        title = content(title[1])
        title = string(title)
        metadata[2]  = title
    end

    date = get_elements_by_tagname(bib[1], "PUBLICATIONSTMT")
    date = get_elements_by_tagname(date[1], "DATE")
    if length(date) == 0
        metadata[3] = "NA"
    else
        date = content(date[1])
        date = string(date)
        metadata[3] = date
    end

    profile = get_elements_by_tagname(ces[1], "PROFILEDESC")
    langusage = get_elements_by_tagname(profile[1], "LANGUSAGE")
    lang = get_elements_by_tagname(langusage[1], "LANGUAGE")
    if length(lang) == 0
        metadata[4] = "NA"
    else
        lang = content(lang[1])
        lang = string(lang)
        metadata[4] = lang
    end

    free(xdoc)

    return metadata
end # function get-metadata

#=
    Function to create a file with the file name and the year the text was created
    Arguments: Array of file names to be analyzed;
               String of input folder where original files are;
               String of output file name
    Return: N/A 
=#
function create_year_text_file(raw_files::Array, input_file_folder::String, output_name::String)
    # open file by name in argument
    if !isfile(output_name)
        year_f = open("$output_name", "w+")
    else
        println("Caution: File already exists.")
        print("Overwrite? (y/n) ")

        # all valid answers
        answers = ["y","yes","n","no"]

        # get user input in lowercase
        answer = Base.lowercase(chomp(readline(STDIN)))

        # check if answer valid
        while !in(answer, answers)
            println("Invalid answer.")
            print("Overwrite? (y/n) ")
            answer = Base.lowercase(chomp(readline(STDIN)))
        end # while loop
        
        # if they answer yes to overwrite, continue
        if (answer == "y") || (answer == "yes")
            progress = true
        # if user answers no to overwrite, ask for new directory
        elseif (answer == "n") || (answer == "no")
            print("Create new output folder: ")
            year_f = open(chomp(readline(STDIN)) * ".tsv", "w+")
        end #if/elseif

    end # if/else

    # loop over files to get assigned dates
    for file in raw_files
        println("Getting date for file: $file")

        # get name of file without extension
        file_name = split(file, '.')[1]

        # get line from metadata for year
        year_line = get_metadata(input_file_folder * file)[3]
        year = Int64

        # loop to get year from text in metadata
        for index in split(year_line, " ")
            stripped_yl = strip(Base.lowercase(index), punctuation)
            
            # Check if date in roman numeral form 
            if is_rn(stripped_yl)
                dec_year = r2d2(uppercase(stripped_yl))
                year = parseint(dec_year)
            
            # else check if date 4 digits and make it year for file
            else
                stripped_yl = strip(stripped_yl, alpha_letters)
                if length(stripped_yl) == 4
                    try 
                        year = parseint(stripped_yl)
                    catch
                    end # try/catch 
                end # if statement
            end # if/else statement
        end # inner for loop
        
        # if year set to anything but integer, make year = 0
        if typeof(year) != Int64
            year = 0 
        end # if statement
        
        # write to file
        write(year_f, "$file_name\t$year\n")
    end # outter for loop

    close(year_f)
end # function create_year_text_file

#=
    Function to create folder with word frequency files for each text
    Arguments: Array of the raw file names; 
               String of the folder where input files are; 
               String of output folder name where new files will go
    Return: N/A
=#
function create_freq_files(raw_files::Array, input_file_folder::String, output_folder::String)
    # try and create new directory for files
    output_folder = pwd() * "/" * output_folder * "/"
    progress = false
    
    # loop to make sure user inputs valid folder
    while progress == false
        try
            mkdir(output_folder)
            progress = true
        catch
            println("Caution: Folder already exists.")
            print("Overwrite? (y/n) ")

            # all valid answers
            answers = ["y","yes","n","no"]

            # get user input in lowercase
            answer = Base.lowercase(chomp(readline(STDIN)))

            # check if answer valid
            while !in(answer, answers)
                println("Invalid answer.")
                print("Overwrite? (y/n) ")
                answer = Base.lowercase(chomp(readline(STDIN)))
            end # while loop
            
            # if they answer yes to overwrite, continue
            if (answer == "y") || (answer == "yes")
                progress = true
            # if user answers no to overwrite, ask for new directory
            elseif (answer == "n") || (answer == "no")
                print("Create new output folder: ")
                output_folder = pwd() * "/" * chomp(readline(STDIN)) * "/"
            end # if/elseif statement

        end # try/catch

    end # while loop

    # loop over files in raw_files and calculate word freqency
    for file in raw_files
        println("Parsing file...")

        # initial parsing of xml
        parsed_file = parse_xml(input_file_folder * file)
        println("Cleaning text...")

        # get rid of unwanted characters
        clean_text = sort(clean(parsed_file))
        
        println("Creating frequencies...")

        # create a dictionary of word frequencies
        freq_dict = Dict()
        for word in clean_text
            # if word already exists, add to its frequency
            if haskey(freq_dict, word)
                freq_dict[word] += 1
            # else create new dictionary key with frequency as value
            else
                freq_dict[word] = 1
            end
        end # inner for loop

        # Add extention to file name
        file_name = split(file, '.')[1] * ".txt"

        # open file where frequency then word is printed
        #f = open("freq_samples/" * file_name, "w+")
        # open file where word then frequency is printed
        f = open(output_folder * file_name, "w+")

        # loop over sorted words in dictionary
        for key in sort(collect(keys(freq_dict)))
            write(f, "$key\t$(freq_dict[key])\n") # write word then freq
            #write(f, "$(freq_dict[key])\t$key\n") # write freq then word
        end # inner for loop

        # close file and print it's done.
        close(f)
        println("Made file: " * file_name)

     end # outter for loop
 
end # function create_freq_file

#= 
    Main function to run the functions to create a text with date file and a folder of files
        that have word frequency for each text
    Arguments: String of directory to get original xml files
    Return: N/A
=#
function main()
    # error check argument
    if length(ARGS) != 1
        println("ERROR: Wrong amount of arguments. $(length(ARGS)) given, 1 needed.")
        exit()
    end # if statement
    if !ispath(ARGS[1])
        println("ERROR: Not a valid directory path.")
        exit()
    end # if statement

    # get all the file names in directory
    raw_files = readdir(ARGS[1])

    # check directory actually has contents
    if length(raw_files) == 0
        println("ERROR: Directory empty.")
        exit()
    end # if statement

    # get rid of any hidden files that start with "."
    while ismatch(r"^\..*", raw_files[1])
        shift!(raw_files)
    end # while loop
    
    # get directory name for full file path
    path_split = split(ARGS[1], "/")
    orig_dir_name = path_split[length(path_split)] * "/"
    
    # make text year file and frequency file folder
    create_year_text_file(raw_files, orig_dir_name, "text_years.tsv")
    create_freq_files(raw_files, orig_dir_name, "text_word_freq_files") 

end # function main

main()
