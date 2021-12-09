#=
day8:
- Julia version: 1.7.0
- Author: Paul.Mealor
- Date: 2021-12-08
=#

using AoC, Test
using StructEquality # https://docs.juliahub.com/StructEquality/TwsrV/1.0.0/
using Base.Iterators: flatten
using Memoize

DIGITS = Dict('0'=>"abcefg",'1'=>"cf",'2'=>"ecdeg",'3'=>"acdfg",'4'=>"bcdf",'5'=>"abdfg",'6'=>"abdefg",'7'=>"acf",'8'=>"abcdefg",'9'=>"abcdfg")
DIGIT_DECODER = Dict((v=>k) for (k,v) in DIGITS)
LENGTHS = Dict((k=>length(v)) for (k,v) in DIGITS)
UNIQUE_LENGTHS = Dict((v=>k) for (k,v) in filter((pair)->count(l->l==pair[2],values(LENGTHS))==1, LENGTHS))
SEGMENT_NAMES = ['a','b','c','d','e','f','g']

@memoize Dict allpermutations(n::Number) = allpermutations([1:n...])
function allpermutations(n::Vector)
    if length(n) == 1
        return [n]
    end
    result = zeros(Int, length(n),0)
    for i in n
        remainder = setdiff(n, [i])

        for p in eachcol(allpermutations(remainder))
            p = [i;p...]
            result = hcat(result, p)
        end
    end
    return result
end

@test allpermutations(2) == [[1,2] [2,1]]
@test allpermutations(3) == [[1,2,3] [1,3,2] [2,1,3] [2,3,1] [3,1,2] [3,2,1]]
@test size(allpermutations(3),2) == 3*2*1
@test size(allpermutations(4),2) == 4*3*2*1
@test size(allpermutations(5),2) == 5*4*3*2*1

struct Display
    combos :: Vector{String}
    display :: Vector{String}
end
@def_structequal Display

function parseDisplay(line)
    (left,right) = split(line, " | ")
    return Display(split(left," "), split(right, " "))
end

@test parseDisplay("be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe") ==
    Display(["be","cfbegad","cbdgef","fgaecd","cgeb","fdcge","agebfd","fecdb","fabcd","edb"],["fdgacbe","cefdb","cefbgd","gcbe"])

function evaluateCipher(combos)
    # keys are the displayed segments, values are the actual values
    segmentMappings = Dict(c => Set(SEGMENT_NAMES) for c in SEGMENT_NAMES)
    return evaluateCipher(combos, segmentMappings)
end

function evaluateCipherCandidate(displayedCombos, displayedCombo, segmentMappings, expectedCombos)
    displayedCombos, displayedCombo, segmentMappings

    if isempty(displayedCombos)
        return displayedCombos
    end

    actualDisplay = [c for c in displayedCombo]
    for expectedDisplay in filter(d -> length(d) == length(displayedCombo), expectedCombos)
        candidateMappingTo = [c for c in expectedDisplay]

        for candidateMappingFrom in eachcol(allpermutations(actualDisplay))
            candidateMappings = copy(segmentMappings)
            okMapping = true
            for c in eachindex(candidateMappingFrom)
                candidateMappings[candidateMappingFrom[c]] = intersect(candidateMappings[candidateMappingFrom[c]], candidateMappingTo[c])
                if isempty(candidateMappings[candidateMappingFrom[c]])
                    #if segmentMappings == Dict('d' => Set('a'), 'e' => Set('b'), 'a' => Set('c'), 'f' => Set('d'), 'g' => Set('e'), 'b' => Set('f'), 'c' => Set('g'))
                    #    @show candidateMappingFrom, candidateMappingTo, candidateMappings
                    #end
                    okMapping = false
                    break
                end
            end
            if okMapping
                result = evaluateCipher(setdiff(displayedCombos,[displayedCombo]), candidateMappings, setdiff(expectedCombos, [expectedDisplay]))
                if !isnothing(result)
                    return @show result
                end
            end
        end
    end
    return nothing
end

function evaluateCipher(displayedCombos, segmentMappings, expectedCombos=[values(DIGITS)...])

    if isempty(displayedCombos)
        return displayedCombos
    end

    fixedLengthCombos = filter(c -> length(c) ∈ keys(UNIQUE_LENGTHS), displayedCombos); lt=(x,y)->length(x)<length(y)

    if !isempty(fixedLengthCombos)
        displayedCombo = argmin(c->length(c), fixedLengthCombos)
        return evaluateCipherCandidate(displayedCombos, displayedCombo, segmentMappings, expectedCombos)
    end

    @show displayedCombos
    for displayedCombo in displayedCombos
        result = evaluateCipherCandidate(displayedCombos, displayedCombo, segmentMappings, expectedCombos)
        if !isnothing(result)
            return result
        end
    end
    return nothing



    #for (actualLength,actualDisplay) in UNIQUE_LENGTHS
    #    @show displayedCombo = filter(c -> length(c) == actualLength, combos)[1]
    #    @show possibilities = Set(c for c in DIGITS[actualDisplay])
    #    for c in displayedCombo
    #        segmentMappings[c] = intersect(segmentMappings[c], possibilities)
    #    end
    #end

    #while any(m->length(m) > 1, values(segmentMappings))
    #    segmentMapping = argmin(mapping->length(mapping[2]), filter(mapping->length(mapping[2])>1, segmentMappings))
    #    for possibleActual in segmentMapping[2]
    #        candidateSegmentMappings = Dict((k=>setdiff(v,Set(possibleActual))) for (k,v) in segmentMappings)
    #        candidateSegmentMappings[segmentMapping[1]] = Set(possibleActual)
    #        if !any(mapping->isempty(mapping[2]), candidateSegmentMappings)
    #            finalMapping = evaluateCipher(combos, candidateSegmentMappings)
    #            if all(mapping->length(mapping[2])==1, finalMapping)
    #                return Dict(k=>[v...][1] for (k,v) in finalMapping)
    #            end
    #        end
    #    end
    #end

    @show segmentMappings
end
@test evaluateCipher(["acedgfb","cdfbe","gcdfa","fbcad","dab","cefabd","cdfgeb","eafb","cagedb","ab"]) == Dict('d'=>'a','e'=>'b','a'=>'c','f'=>'d','g'=>'e','b'=>'f','c'=>'g')

function evaluateDisplay(display::Display)
    cipher = evaluateCipher(display.combos)
end

@test evaluateDisplay(Display(["acedgfb","cdfbe","gcdfa","fbcad","dab","cefabd","cdfgeb","eafb","cagedb","ab"],["cdfeb","fcadb","cdfeb","cdbaf"])) == "5353"


part1(lines) = part1([parseDisplay(line) for line in lines])
function part1(displays :: Array{Display})
    allDigits = [flatten(displays .|> d->d.display)...]
    uniqueLengthDigits = filter(allDigits) do digit
        length(digit) ∈ keys(UNIQUE_LENGTHS)
    end
    return length(uniqueLengthDigits)
end

@test part1(exampleLines(8,2)) == 26

part2(lines) = part2([parseDisplay(line) for line in lines])
function part2(displays :: Array{Display})
    displays = [evaluateDisplay(d) for d in displays]
    return sum(parse.(Int, displays))
end

@test part2(exampleLines(8,2)) == 61229

lines(8) |> ll -> @time part1(ll) |> show
#lines(8) |> ll -> @time part2(ll) |> show
