require 'test/unit'
require 'jar/cities.jar'

class PoolAllocatorTest < Test::Unit::TestCase
  java_import 'cities.PoolAllocator'
  
  def assert_free(pa, range)
    range.each do |i|
      assert pa.at(i)
    end
  end
  
  def assert_used(pa, range)
    range.each do |i|
      assert !pa.at(i)
    end
  end
  
  def test_emptiness
    pa = PoolAllocator.new(20)
    assert_free(pa, 0..19)
  end
  
  def test_allocate_first
    pa = PoolAllocator.new(20)
    assert_equal 0, pa.alloc(5)
    assert_used(pa, 0..4)
    assert_free(pa, 5..19)
  end
  
  def test_free
    pa = PoolAllocator.new(20)
    pa.alloc(15)
    assert_used(pa, 0..14)
    assert_free(pa, 15..19)
    pa.free(5, 5)
    assert_used(pa, 0..4)
    assert_free(pa, 5..9)
    assert_used(pa, 10..14)
    assert_free(pa, 15..19)
  end
  
  def test_allocate_middle
    pa = PoolAllocator.new(20)
    pa.alloc(15)
    pa.free(5, 5)
    assert_equal 15, pa.alloc(3)
    assert_equal 18, pa.cursor
    assert_equal 5, pa.alloc(5)
  end
  
  def test_max_used
    pa = PoolAllocator.new(20)
    pa.alloc(15)
    assert_equal 14, pa.maxUsed
    
    pa = PoolAllocator.new(1)
    pa.alloc(1)
    assert_equal 0, pa.maxUsed
  end
end