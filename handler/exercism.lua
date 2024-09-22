local json = require('dkjson')
local lfs = require('lfs')

local function exists(path)
    return lfs.attributes(path, 'mode') ~= nil
end

local test_file_format = './%s_spec.lua'

local function parse_test_file(slug)
    local test_file
    for _, s in ipairs({slug, slug:gsub('-', '_')}) do
        local file = test_file_format:format(s)
        if exists(file) then
            test_file = file
            break
        end
    end

    assert(test_file, 'No test file was found')

    local test_file_handle = assert(io.open(test_file, 'r'))
    local test_file_contents = test_file_handle:read('*a')
    test_file_handle:close()

    local parsed = {}
    local idx = 1

    for test in test_file_contents:gmatch('%sit(%b())') do
        local name = test:match("^%(%s*(%b'')") or test:match('^%(%s*(%b"")')
        name = name:sub(2, -2)

        local code = test:match(',%s*function%s*%(%)(.+)end%)$')
        code = code:gsub('^%s*\n', '')
        local indent = code:match('^%s+')
        code = code:gsub('^' .. indent, ''):gsub('\n' .. indent, '\n'):gsub('%s+$', '')

        parsed[name] = { idx = idx, code = code }
        idx = idx + 1
    end

    return parsed
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

    local parsed_spec = parse_test_file(cli_args['slug'])
    local result = {
        version = 2,
        tests = {}
    }

    local test_message_patt = '^.-%.lua:%d+:%s(.*)$'
    local function add_to_tests(tests, status)
        for _, test in ipairs(tests) do
            local name = test.element.name
            local message

            if status == 'error' then
                message = test.message
            elseif status == 'fail' then
                message = test.message:match(test_message_patt)
            end

            result.tests[parsed_spec[name].idx] = {
                name = name,
                status = status,
                message = message,
                test_code = parsed_spec[name].code
            }
        end
    end

    handler.suite_end = function()
        if handler.errorsCount > 0 and handler.successesCount == 0 and handler.failuresCount == 0 then
            result.status = 'error'
            result.message = handler.errors[1].message
            result.tests = nil
        else
            result.status = handler.failuresCount == 0 and handler.errorsCount == 0 and 'pass' or 'fail'

            add_to_tests(handler.successes, 'pass')
            add_to_tests(handler.failures, 'fail')
            add_to_tests(handler.errors, 'error')
        end

        io.write(json.encode(result))
    end

    busted.subscribe({'suite', 'end'}, handler.suite_end)

    return handler
end

return exercism_output_handler
