-- Unfortunately there is no documentation on how to write an output handler
-- for busted, except the code of already existing output handlers. The base
-- output handler [1] is probably the most interesting codebase.
--
-- [1] https://github.com/lunarmodules/busted/blob/master/busted/outputHandlers/base.lua
local json = require('dkjson')
local path = require('pl.path')

local test_file_format = './%s_spec.lua'
-- Returns the content of the test file if it exists
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


    local test_file_handle <close> = assert(io.open(test_file, 'r'))
    return test_file_handle:read('a')
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

    local test_file_content = read_test_file(cli_args['slug'])
    local result = {
        version = 2,
        tests = {}
    }
    local index = 1

    -- This handler is called before each test is executed. We use the debug
    -- library to find out in which line the test function starts and ends, so
    -- that we can extract the test code from the test_file_content string. The
    -- test name and code is then added to the results.tests table at the
    -- current index.
    handler.exercism_test_start = function(element)
        local func_info = debug.getinfo(element.run, 'S')

        local fn_start = 1
        for _ = 1, func_info.linedefined do
            fn_start = test_file_content:find('\n', fn_start) + 1
        end

        local fn_end = 1
        for _ = 1, func_info.lastlinedefined - 1 do
            fn_end = test_file_content:find('\n', fn_end) + 1
        end

        local test_code = test_file_content:sub(fn_start, fn_end)
        local indent = test_code:match('^%s+')
        test_code = test_code:gsub('^' .. indent, ''):gsub('\n' .. indent, '\n'):gsub('%s+$', '')

        result.tests[index] = {
            name = element.name,
            test_code = test_code
        }

        return nil, true
    end

    -- After a test has been executed, this handler is called, regardless of
    -- whether it was successful or not. If a test has passed we add the status
    -- to the current result.tests table. Failed or errored tests are handled
    -- in seperate handlers below, which are called before this one.
    handler.exercism_test_end = function(element, parent, status, debug)
        if status == 'success' then
            result.tests[index].status = 'pass'
        end

        index = index + 1

        return nil, true
    end

    -- If a test failed, this handler is called before the test_end handler.
    -- We add the status and the failed message to the result.tests table.
    local test_message_patt = '^.-%.lua:%d+:%s(.*)$'
    handler.exercism_test_failure = function(element, parent, msg, debug)
        result.tests[index].status = 'fail'
        result.tests[index].message = msg:match(test_message_patt)

        return nil, true
    end

    -- If a test errors, this handler is called before the test_end handler.
    -- We add the status and the error message to the result.tests table.
    handler.exercism_test_error = function(element, parent, msg, debug)
        result.tests[index].status = 'error'
        result.tests[index].message = msg

        return nil, true
    end

    -- After a test suite ended, this handler is called. We evalute the
    -- counters to set the overall status and then the result is written to
    -- stdout as JSON.
    handler.exercism_suite_end = function()
        if handler.errorsCount > 0 and handler.successesCount == 0 and handler.failuresCount == 0 then
            result.status = 'error'
            result.message = handler.errors[1].message
            result.tests = nil
        else
            result.status = handler.failuresCount == 0 and handler.errorsCount == 0 and 'pass' or 'fail'
        end

        io.write(json.encode(result))
    end

    -- Subscribing the handler functions to the different busted contexts.
    busted.subscribe({'test', 'start'}, handler.exercism_test_start)
    busted.subscribe({'test', 'end'}, handler.exercism_test_end)
    busted.subscribe({'error', 'it'}, handler.exercism_test_error)
    busted.subscribe({'failure', 'it'}, handler.exercism_test_failure)
    busted.subscribe({'suite', 'end'}, handler.exercism_suite_end)

    return handler
end

return exercism_output_handler
