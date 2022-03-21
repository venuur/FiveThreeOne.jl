module TextTable

export TextCell, hmerge, vmerge, interleave, align_left, align_right, align_top, align_bottom, set_width!, set_height!, format_lines, format_text

@enum HorizontalAlignment left right 
@enum VerticalAlignment top bottom
const align_left = left
const align_right = right
const align_top = top
const align_bottom = bottom

mutable struct Line
    content::AbstractString
    padding_char::AbstractChar
    left_pad::Int
    right_pad::Int
end

Base.length(line::Line) = length(line.content)

function Base.show(io::IO, line::Line)
    for _ in 1:line.left_pad
        print(io, line.padding_char)
    end
    print(io, line.content)
    for _ in 1:line.right_pad
        print(io, line.padding_char)
    end
end

function left_pad(content, horizontal_alignment, max_width)
    if horizontal_alignment == left
        return 0
    elseif horizontal_alignment == right
        return max_width - length(content)
    end
end

function right_pad(content, horizontal_alignment, max_width)
    if horizontal_alignment == left
        return max_width - length(content)
    elseif horizontal_alignment == right
        return 0
    end
end


mutable struct TextCell
    lines::Vector{Line}
    horizontal_alignment::HorizontalAlignment
    vertical_alignment::VerticalAlignment
    height::Int
    width::Int
    top_pad::Int
    bottom_pad::Int

    
    function TextCell(
        lines::Vector{<:AbstractString}; 
        horizontal_alignment::HorizontalAlignment = left,
        vertical_alignment::VerticalAlignment = top,
        )
        max_width = maximum(length.(lines))
        height = length(lines)
        
        padded_lines = [
            Line(
                content, 
                ' ', 
                left_pad(content, horizontal_alignment, max_width), 
                right_pad(content, horizontal_alignment, max_width),
                ) 
            for content in lines]
        return new(padded_lines, horizontal_alignment, vertical_alignment, height, max_width, 0, 0)
    end

end

function set_height!(cell::TextCell, new_height)
    min_height = length(cell.lines)
    if new_height < min_height
        throw(ArgumentError("New height for cell must be at least $min_height, the height of the contents."))
    end

    if cell.vertical_alignment == top
        cell.bottom_pad = new_height - min_height
    elseif cell.vertical_alignment == bottom
        cell.top_pad = new_height - min_height
    end
    cell.height = new_height
    return cell
end

function set_width!(cell::TextCell, new_width)
    min_width = maximum([length(line.content) for line in cell.lines])
    if new_width < min_width
        throw(ArgumentError("New width for cell must be at least $min_width, the width of the contents."))
    end

    for line in cell.lines
        if cell.horizontal_alignment == left
            line.left_pad = 0
            line.right_pad = new_width - length(line.content)
        elseif cell.horizontal_alignment == right
            line.left_pad = new_width - length(line.content)
            line.right_pad = 0
        end
    end
    cell.width = new_width
end

function format_lines(cell::TextCell)
    output_lines::Vector{AbstractString} = []
    for _ in 1:cell.top_pad
        push!(output_lines, repeat(" ", cell.width))
    end
    for line in cell.lines
        push!(output_lines, join([repeat(line.padding_char, line.left_pad), line.content, repeat(" ", line.right_pad)]))
    end
    for _ in 1:cell.bottom_pad
        push!(output_lines, repeat(" ", cell.width))
    end
    return output_lines
end

function format_text(cell::TextCell)
    return join(format_lines(cell), "\n")
end

make_blank_line(cell) = Line(
    "",
    ' ',
    left_pad("", cell.horizontal_alignment, cell.width),
    right_pad("", cell.horizontal_alignment, cell.width),
    )

function cell_lines_to_merge(cell::TextCell)
    return vcat(
        [make_blank_line(cell) for _ in 1:cell.top_pad],
        cell.lines, 
        [make_blank_line(cell) for _ in 1:cell.bottom_pad],
        )
end

function hmerge(
    cell1::TextCell,
    cell2::TextCell;
    horizontal_alignment::HorizontalAlignment=left,
    vertical_alignment::VerticalAlignment=top,
    sep="",
    )
    max_height = max(cell1.height, cell2.height)
    for cell in [cell1, cell2]
        set_height!(cell, max_height)
    end
    cell_lines = Array{Line}(undef, max_height, 2)
    for (j, cell) in zip([1, 2], [cell1, cell2])
        lines = cell_lines_to_merge(cell)
        for i in 1:max_height
            cell_lines[i, j] = lines[i]
        end
    end
    new_content = Vector{AbstractString}(undef, max_height)
    for i in 1:max_height
        left_line, right_line = cell_lines[i, 1], cell_lines[i, 2]
        content = join([
            repeat(left_line.padding_char, left_line.left_pad),
            left_line.content,
            repeat(left_line.padding_char, left_line.right_pad),
            sep,
            repeat(right_line.padding_char, right_line.left_pad),
            right_line.content,
            repeat(right_line.padding_char, right_line.right_pad),
        ])
        new_content[i] = content
    end
    return TextCell(new_content; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment)
end

function vmerge(
    cell1::TextCell,
    cell2::TextCell;
    horizontal_alignment::HorizontalAlignment=left,
    vertical_alignment::VerticalAlignment=top,
    sep="",
    )
    max_width = max(cell1.width, cell2.width)
    set_width!(cell1, max_width)
    set_width!(cell2, max_width)
    if length(sep) > 0 
        sep_lines = [repeat(s, max_width) for s in sep]
    else
        sep_lines = AbstractString[]
    end
    new_content = vcat(format_lines(cell1), sep_lines, format_lines(cell2))
    return TextCell(new_content; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment)
end

function _repeated_merge(
    merge_func,
    cells::Vector{TextCell};
    horizontal_alignment::HorizontalAlignment=left,
    vertical_alignment::VerticalAlignment=top,
    sep="",
    )
    if length(cells) == 1
        return cells[1]
    elseif length(cells) == 0
        throw(ArgumentError("No cells to merge."))
    end
    _merge(c1, c2) = merge_func(c1, c2; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment, sep=sep)
    new_cell = _merge(cells[1], cells[2])
    for i in 3:length(cells)
        new_cell = _merge(new_cell, cells[i])
    end
    return new_cell
end

function hmerge(
    cells::Vector{TextCell};
    horizontal_alignment::HorizontalAlignment=left,
    vertical_alignment::VerticalAlignment=top,
    sep="",
    )
    return _repeated_merge(hmerge, cells; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment, sep=sep)
end

function vmerge(
    cells::Vector{TextCell};
    horizontal_alignment::HorizontalAlignment=left,
    vertical_alignment::VerticalAlignment=top,
    sep="",
    )
    return _repeated_merge(vmerge, cells; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment, sep=sep)
end

function interleave(cell1::TextCell, cell2::TextCell; horizontal_alignment::HorizontalAlignment=left, vertical_alignment::VerticalAlignment=top, sep=nothing)
    max_width = max(cell1.width, cell2.width)
    set_width!(cell1, max_width)
    set_width!(cell2, max_width)
    max_height = max(length(cell1.lines), length(cell2.lines))
    new_height = length(cell1.lines) + length(cell2.lines)
    new_content = Vector{AbstractString}(undef, new_height)
    cell1_lines = format_lines(cell1)
    cell2_lines = format_lines(cell2)
    i = 1
    j = 1
    while i <= max_height
        if i <= length(cell1.lines)
            new_content[j] = cell1_lines[i]
            j += 1
        end
        if i <= length(cell2.lines)
            new_content[j] = cell2_lines[i]
            j += 1
        end
        i += 1
    end
    return TextCell(new_content; horizontal_alignment=horizontal_alignment, vertical_alignment=vertical_alignment)
end

end # module TextTable