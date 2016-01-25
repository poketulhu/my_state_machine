require 'test/unit'
require_relative 'article'

class MyStateMachineTest < Test::Unit::TestCase
  setup do
    @article = Article.new
  end

  test 'should change state manually' do
    @article.created
    assert_equal :created, @article.inst_state
    assert_not_equal :init, @article.inst_state

    assert @article.created?
    assert !@article.init?
  end

  test 'should change state' do
    @article.create
    assert_equal :created, @article.inst_state
  end

  test 'may change state?' do
    assert @article.may_create?

    @article.created
    assert @article.may_check?
  end

  test 'after callback' do
    assert_equal "Article is published", @article.create
  end
end