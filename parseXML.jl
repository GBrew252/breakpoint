#=
    Scan over xml file
=#

using LightXML
include("/Users/connor/Desktop/breakpoint/RomanDecimal.jl")

alpha_letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n',
'o','p','q','r','s','t','u','v','w','x','y','z']

punctuation = ['!','"','#','$','%','&','\'','(',')','*','+',',',
'-','.','/',':',';','<','=','>','?','@','[','\\',']','^','_','`',
'{','|','}','~','—','▪','•']

function clean(string)
    string = Base.lowercase(string)
    sarray = convert(Array{typeof(string)}, Base.split(string))
    x = 1

    for x in 1:length(sarray)
        word = join(split(sarray[x], char(0x2223)))
        sarray[x] = word
    end
    i = 1
    
    add_words = Array(String, 0)
    while i <= length(sarray)
        sarray[i] = Base.strip(sarray[i], punctuation)
        
        if !ismatch(r".*-.*", sarray[i])
            for punct in punctuation
                if punct in sarray[i]
                    i_split = split(sarray[i], punct)
                    sarray[i] = i_split[1]
                    push!(add_words, i_split[2])
                 end
             end
        end 

        i += 1
    end
    
    for word in add_words
       push!(sarray, word)
    end
    
    return sarray
end

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
end

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
end

function main()
    raw_files = readdir("/Users/connor/Desktop/breakpoint/Sample_All")
    
    while ismatch(r"^\..*", raw_files[1])
        shift!(raw_files)
    end
    count = 1
    
    year_f = open("/Users/connor/Desktop/breakpoint/freq_sample_years.tsv", "w+")
    for file in raw_files
        println("Write from file: $file")
        file_name = split(file, '.')[1]
        year_line = get_metadata("Sample_All/" * file)[3]
        year = Int64
        for index in split(year_line, " ")
            stripped_yl = strip(Base.lowercase(index), punctuation)
            if is_rn(uppercase(stripped_yl))
                dec_year = r2d2(uppercase(stripped_yl))
                year = parseint(dec_year)
            else
                stripped_yl = strip(stripped_yl, alpha_letters)
                if length(stripped_yl) == 4
                    try
                        year = parseint(stripped_yl)
                    catch
                    end
                end
            end
        end

        if typeof(year) != Int64
            year = 0
        end

        #println("$count: $year")
        count += 1
        write(year_f, "$file_name\t$year\n")
    end
    #close(year_f)
    
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
