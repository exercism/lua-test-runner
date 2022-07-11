#!/usr/bin/env lua

local json = require('dkjson')
local tablex = require('pl.tablex')
local pretty = require('pl.pretty')

local function load_json(file)
    local fd <close> = io.open(file)
    return json.decode(fd:read('a'))
end

local result = load_json(arg[1])
local expected = load_json(arg[2])

if not tablex.deepcompare(result, expected) then
    print('\n========[  RESULT  ]========\n')
    print(pretty.write(result))

    print('\n========[ EXPECTED ]========\n')
    print(pretty.write(expected))

    os.exit(1)
end

os.exit(0)
