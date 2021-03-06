require 'helper'

class TestSoulmate < Test::Unit::TestCase
  def test_integration_can_load_values_and_query
    items = []
    venues = File.open(File.expand_path(File.dirname(__FILE__)) + '/samples/venues.json', "r")
    venues.each_line do |venue|
      items << MultiJson.decode(venue)
    end
    
    items_loaded = Soulmate::Loader.new('venues').load(items)
    
    assert_equal 6, items_loaded.size
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('stad', :limit => 5)
    
    assert_equal 5, results.size
    assert_equal 'Citi Field', results[0]['term']
  end
  
  def test_integration_can_load_values_and_query_via_aliases
    items = []
    venues = File.open(File.expand_path(File.dirname(__FILE__)) + '/samples/venues.json', "r")
    venues.each_line do |venue|
      items << MultiJson.decode(venue)
    end
    
    items_loaded = Soulmate::Loader.new('venues').load(items)
    
    assert_equal 6, items_loaded.size
    
    matcher = Soulmate::Matcher.new('venues')
    results = matcher.matches_for_term('land shark stadium', :limit => 5)
    
    assert_equal 1, results.size
    assert_equal 'Sun Life Stadium', results[0]['term']
    
    # Make sure we don't get dupes between aliases and the original term
    # this shouldn't happen due to Redis doing an intersect, but just in case!
    
    results = matcher.matches_for_term('stadium', :limit => 5)    
    assert_equal 5, results.size
  end
  
  def test_can_remove_items
    
    loader = Soulmate::Loader.new('venues')
    matcher = Soulmate::Matcher.new('venues')
    
    # empty the collection
    loader.load([])
    results = matcher.matches_for_term("te", :cache => false)
    assert_equal 0, results.size
    
    loader.add("id" => 1, "term" => "Testing this", "score" => 10)
    results = matcher.matches_for_term("te", :cache => false)
    assert_equal 1, results.size
    
    loader.remove("id" => 1)
    results = matcher.matches_for_term("te", :cache => false)
    assert_equal 0, results.size
    
  end
  
  def test_can_update_items
    
    loader = Soulmate::Loader.new('venues')
    matcher = Soulmate::Matcher.new('venues')
    
    # empty the collection
    loader.load([])
    
    # initial data
    loader.add("id" => 1, "term" => "Testing this", "score" => 10)
    loader.add("id" => 2, "term" => "Another Term", "score" => 9)
    loader.add("id" => 3, "term" => "Something different", "score" => 5)
    
    results = matcher.matches_for_term("te", :cache => false)
    assert_equal 2, results.size
    assert_equal "Testing this", results.first["term"]
    assert_equal 10, results.first["score"]
    
    # update id:1
    loader.add("id" => 1, "term" => "Updated", "score" => 5)
    
    results = matcher.matches_for_term("te", :cache => false)
    assert_equal 1, results.size
    assert_equal "Another Term", results.first["term"]
    assert_equal 9, results.first["score"]
    
  end
  
  def test_prefixes_for_phrase
    loader = Soulmate::Loader.new('venues')
    
    assert_equal ["te", "tes", "test", "testi", "testin", "th", "thi", "this"], loader.prefixes_for_phrase("testin' this")
    assert_equal ["te", "tes", "test"], loader.prefixes_for_phrase("test test")
    assert_equal ["so", "sou", "soul", "soulm", "soulma", "soulmat", "soulmate"], loader.prefixes_for_phrase("SoUlmATE")
  end
end
