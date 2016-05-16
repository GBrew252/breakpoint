#=
    roman_decimal.jl
    By: Connor Riddell
    Two functions: r2d2 converts the Roman numeral to the decimal year
        and is_rn checks to see if the string given is a roman numeral
=#

#=
    Function to convert roman numerals to decimal numbers
    Takes string as agrument (Roman Numerals)
    Returns string of decimal date
=#
function r2d2(roman_date::String)
    # convert to uppercase
    roman_date = Base.uppercase(roman_date)

    # check if input argument is a roman numeral
    if is_rn(roman_date)
        roman_date_rev = reverse(roman_date) # reverse the date
        date_nums = Array(Int64, 0) # array of converted numbers

        # loop to figure out the number and conver it to decimal
        for letter in roman_date_rev
            num = 0
            if letter == 'I'
                num = 1
            elseif letter == 'V'
                num = 5
            elseif letter == 'X'
                num = 10
            elseif letter == 'L'
                num = 50
            elseif letter == 'C'
                num = 100
            elseif letter == 'D'
                num = 500
            elseif letter == 'M'
                num = 1000
            end # if/else statements
                                    
            push!(date_nums, num) # add to array
        end # for loop

        decimal_num = 0 # Decimal year to be returned at end
        while length(date_nums) != 0
            # if number is greater than the next, subtract amount
            if (length(date_nums) >= 2) && (date_nums[1] > date_nums[2])
                decimal_num = (decimal_num + (date_nums[1] - date_nums[2]))
                shift!(date_nums)
                shift!(date_nums)
            else
                # else add first index to total decimal_num and shift
                decimal_num = decimal_num + date_nums[1]
                shift!(date_nums)
            end # if/else statement
        end # while loop
        
        # return decimal year in string 
        return string(decimal_num)

    else
        throw(ArgumentError("Not a Roman Numeral"))
    end # if/else statement

end # r2d2 function

#=
    Function to tell whether string is a roman numeral
    Takes one string argument
    Returns boolean
=#
function is_rn(input::String)
    input = Base.uppercase(input) # make uppercase
    numerals = ['I','V','X','L','C','D','M'] # all roman numerals
    is_numeral = true # boolean to be returned
    
    # loop over each char in input and check if it's a numeral
    for letter in input
        if letter in numerals
            continue # do nothing
        else
            is_numeral = false # non-roman numeral present
            break
        end # if/else statement
    end # for loop

    return is_numeral
end # is_rn function
