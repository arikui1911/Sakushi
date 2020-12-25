require 'test/unit'
require 'sakushi/tokenizer'

class TestTokenizer < Test::Unit::TestCase
  test 'bar ident' do
    tr = Sakushi::Tokenizer.for_string(%Q`|several word ident|`)
    assert_token tr.next_token, :IDENT_BEGIN, '|', 1, 1
    assert_token tr.next_token, :IDENT_CONTENT, 'several word ident', 1, 2
    assert_token tr.next_token, :IDENT_END, '|', 1, 20
    assert_token tr.next_token, :EOF, nil, 2, 1
  end

  def assert_token(actual, *expecteds)
    expected = actual.class.new(*expecteds)
    assert_equal actual, expected
  end
end

