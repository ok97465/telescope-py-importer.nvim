local function get_no_line_of_docstring()
    local no_lines_buf = vim.api.nvim_buf_line_count(0)
    local no_lines_max = math.min(no_lines_buf, 30)
    lines = vim.api.nvim_buf_get_lines(0, 0, no_lines_max, false)

    local found_start = false
    for idx_line, line in pairs(lines) do
        if found_start == false 
            and (
                 line:find('"""', 1, true) 
              or line:find("'''", 1, true) 
              or line:find('r"""', 1, true) 
              or line:find("r'''", 1, true)
            ) then
            found_start = true
        end

        if found_start == true and #line > 2 then
            local suffix = line:sub(-3, -1)
            if suffix == '"""' or suffix == "'''" then
                return idx_line - 1
            end
        end
    end

    return nil
end

local function get_no_line_of_import()
    local ret = nil
    local no_lines_buf = vim.api.nvim_buf_line_count(0)
    local no_lines_max = math.min(no_lines_buf, 80)
    lines = vim.api.nvim_buf_get_lines(0, 0, no_lines_max, false)

    for idx_line, line in pairs(lines) do
        if line == "# %% Import"
            or line == "# Standard library imports"
            or line == "# Local imports"
            or line == "# Third party imports"
        then
            ret = idx_line 
        elseif line:find('import', 1, true) or line:find("from", 1, true) then
            return idx_line - 1
        end
    end

    return ret
end

local function insert_import(info_import)
    -- info_import : table ==> {name_callable = relative path}
    local no_lines_buf = vim.api.nvim_buf_line_count(0)
    local no_line_docstring = get_no_line_of_docstring()
    local no_line_import = get_no_line_of_import()
    local no_line = 0

    if no_line_docstring == nil and no_line_import == nil then
        no_line = 0
    elseif no_line_docstring ~= nil and no_line_import == nil then
        no_line = no_line_docstring + 1
    else
        no_line = no_line_import
    end

    for name, path in pairs(info_import) do
        local str_import = 'from ' .. path .. ' import ' .. name
        vim.api.nvim_buf_set_text(0, no_line, 0, no_line, 0, {str_import, ''})
    end
    vim.api.nvim_command("Isort")
end

return {
  insert_import = insert_import
}
