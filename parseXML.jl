#=
    parseXML.jl
    Scan over xml file
    By; Connor Riddell
=#

using LightXML
include("/Users/connor/workspace/breakpoint/RomanDecimal.jl")

# lowercase letters of alphabet
alpha_letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n',
'o','p','q','r','s','t','u','v','w','x','y','z']

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
    Arguments: Array of files to be analyzed
    Return: N/A 
=#
function create_year_text_file(raw_files::Array, output_name::String, file_folder::String)
    # open file by name in argument
    year_f = open("/Users/connor/workspace/breakpoint/$output_name", "w+")

    # loop over files to get assigned dates
    for file in raw_files
        println("Getting date for file: $file")

        # get name of file without extension
        file_name = split(file, '.')[1]

        # get line from metadata for year
        year_line = get_metadata(file_folder * file)[3]
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


function main()
    raw_files = readdir("/Users/connor/workspace/breakpoint/Sample_All")
    
    while ismatch(r"^\..*", raw_files[1])
        shift!(raw_files)
    end
    
    create_year_text_file(raw_files, "test.tsv", "Sample_All/")
    #=

    #mkdir("/Users/connor/Desktop/breakpoint/freq_samples_rev") 

    for file in raw_files
        println("Parsing file...")
        parsed_file = parse_xml("Sample_All/" * file)
        println("Cleaning text...")
        clean_text = sort(clean(parsed_file))
        
        println("Creating frequencies...")
        freq_dict = Dict()
        for word in clean_text
            if haskey(freq_dict, word)
                freq_dict[word] += 1
            else
                freq_dict[word] = 1
            end
        end

        file_name = split(file, '.')[1] * ".txt"
        #f = open("freq_samples/" * file_name, "w+")
        f = open("freq_samples_rev/" * file_name, "w+")
        for key in sort(collect(keys(freq_dict)))
            write(f, "$key\t$(freq_dict[key])\n")
            #write(f, "$(freq_dict[key])\t$key\n")
        end
        close(f)
        println("Made file: " * file_name)
     end   
    =#
end


main()
