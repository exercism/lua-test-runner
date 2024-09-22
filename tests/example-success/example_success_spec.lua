local is_leap_year = require('example_success')

describe('leap', function()
  it('a known leap year', function()
    assert.is_true(is_leap_year(1996))
  end)

  it('any old year', function()
    assert.is_false(is_leap_year(1997))
  end)

  it('turn of the 20th century', function()
    assert.is_false(is_leap_year(1900))
  end)

  it('turn of the 21st century', function()
    assert.is_true(is_leap_year(2400))
  end)

  it("handles test names with 'apostrophes'", function()
    assert.is_true(true)
  end)

  it('handles tests with multiple lines in the body', function()
    assert.is_false(false)

    assert.is_true(true)
  end)

  it(
    'handles really long test names that get wrapped by the lua formatter',
    function()
      assert.is_true(true)
    end)

  it('handles tests with a space after function and before () in the function definition', function ()
    assert.is_true(true)
  end)
end)
