local is_leap_year = require('example_all_fail')

describe('leap', function()
  it('a known leap year', function()
    assert.is_true(is_leap_year(1996))
  end)

  it('any old year', function()
    assert.is_false(is_leap_year(1997))
  end)
end)
