local json = require('dkjson')
local path = require('pl.path')
local strip = require('pl.stringx').strip
local readlines = require('pl.utils').readlines

local test_file_format = './%s_spec.lua'
local function read_test_file(slug)
    local test_file
    for _, s in ipairs({slug, slug:gsub('-', '_')}) do
        local file = test_file_format:format(s)
        if path.exists(file) and path.isfile(file) then
            test_file = file
            break
        end
    end

    assert(test_file, 'No test file was found')


end

local function exercism_output_handler(options)
    local busted = require('busted')
    local handler = require('busted.outputHandlers.base')()
    local cli = require('cliargs')
    local args = options.arguments

    cli:set_name('Exercism.io Lua track output handler')
    cli:option('--slug=SLUG', 'The slug of the exercise (e.g. two-fer)')

    local cli_args, err = cli:parse(args)

    if not cli_args and err then
        io.stderr:write(string.format('%s: %s\n\n', cli.name, err))
        io.stderr:write(cli.printer.generate_help_and_usage().. '\n')
        os.exit(1)
    end

    local test_file = read_test_file(cli_args['slug'])
    local result = {
        version = 2,
        tests = {}
    }
    local index = 1

    handler.suite_end = function()
        if handler.errorsCount > 0 and handler.successesCount == 0 and handler.failuresCount == 0 then
            result.status = 'error'
            result.message = handler.errors[1].message
            result.tests = nil
        else
            result.status = handler.failuresCount == 0 and handler.errorsCount == 0 and 'pass' or 'fail'
        end

        io.write(json.encode(result))
    end

    handler.exercism_test_start = function(element)
        local func_info = debug.getinfo(element.run, 'S')
        local body_start = func_info.linedefined + 1
        local body_end  = func_info.lastlinedefined - 1

        local test_code = {}
        for i = body_start, body_end do
            table.insert(test_code, strip(test_file[i]))
        end

        result.tests[index] = {
            name = element.name,
            test_code = table.concat(test_code, '\n')
        }

        return nil, true
    end

    handler.exercism_test_end = function(element, parent, status, debug)
        if status == 'success' then
            result.tests[index].status = 'pass'
        end

        index = index + 1

        return nil, true
    end

    local test_message_patt = '^.-%.lua:%d+:%s(.*)$'
    handler.exercism_test_failure = function(element, parent, msg, debug)
        result.tests[index].status = 'fail'
        result.tests[index].message = msg:match(test_message_patt)

        return nil, true
    end

    handler.exercism_test_error = function(element, parent, msg, debug)
        result.tests[index].status = 'error'
        result.tests[index].message = msg

        return nil, true
    end

    busted.subscribe({'test', 'start'}, handler.exercism_test_start)
    busted.subscribe({'test', 'end'}, handler.exercism_test_end)
    busted.subscribe({'error', 'it'}, handler.exercism_test_error)
    busted.subscribe({'failure', 'it'}, handler.exercism_test_failure)
    busted.subscribe({'suite', 'end'}, handler.suite_end)

    return handler
end

return exercism_output_handler
