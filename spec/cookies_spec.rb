require 'spec_helper'

describe Padrino::Cookies do
  let :cookies do
    route('foo=bar', 'bar=foo') { cookies }
  end

  context :secret do
    it 'should use :cookie_secret when set' do
      app.set :cookie_secret, 'cookie_secret'
      secret = cookies.instance_variable_get(:@secret)
      secret.should == 'cookie_secret'
    end

    it 'should fall back to :session_secret when :cookie_secret is not set' do
      app.set :session_secret, 'session_secret'
      secret = cookies.instance_variable_get(:@secret)
      secret.should == 'session_secret'
    end
  end

  context :[] do
    it 'can retrieve existing cookies' do
      cookies['foo'].should == 'bar'
      cookies['bar'].should == 'foo'
    end

    it 'should allow symbols to be used as keys' do
      cookies[:foo].should == 'bar'
      cookies['foo'].should == 'bar'
    end

    it 'should return nil when the cookie is not found' do
      cookies[:nom_nom].should be_nil
    end
  end

  context :[]= do
    it 'should add the cookie to the jar' do
      cookies['test'] = 'test'
      cookies['test'].should == 'test'
    end

    it 'should allow symbols to be used as keys' do
      cookies[:test] = 'test'
      cookies[:test].should == 'test'
      cookies['test'].should == 'test'
    end

    it 'should raise Overflow when more then 4096 bytes are used' do
      cookies['test'] = 'C' * 4096
      cookies['test'].should_not be_nil

      expect { cookies['test'] = 'C' * 4097 }.to raise_error(Padrino::Cookies::Overflow)
    end

    it 'should accept a hash of options' do
      cookies['test'] = { :value => 'test', :path => '/' }
      cookies['test'].should == 'test'
    end

    it 'should set the response headers when setting a cookie' do
      result = route do
        cookies['foo'] = 'bar'
        response['Set-Cookie']
      end
      result.should == 'foo=bar; path=/; HttpOnly'
    end

    it 'should set the path to / by default' do
      result = route do
        cookies['foo'] = 'bar'
        response['Set-Cookie']
      end

      result.should include('path=/')
    end

    it 'should set HttpOnly by default' do
      result = route do
        cookies['foo'] = 'bar'
        response['Set-Cookie']
      end

      result.should include('HttpOnly')
    end
  end

  context :delete do
    it 'should remove the cookie from the jar' do
      cookies['foo'].should == 'bar'
      cookies.delete 'foo'
      cookies['foo'].should be_nil
    end

    it 'should allow symbols to be used as keys' do
      cookies.delete :foo
      cookies['foo'].should be_nil
    end

    it 'should set the response headers when deleting a cookie' do
      result = route('foo=bar') do
        cookies.delete 'foo'
        response['Set-Cookie']
      end

      result.should == 'foo=; expires=Thu, 01-Jan-1970 00:00:00 GMT'
    end

    it 'should return the cookie value when deleting a cookie' do
      cookies.delete('foo').should == 'bar'
    end
  end

  context :clear do
    it 'can delete all cookies that are set' do
      cookies['foo'].should == 'bar'
      cookies['bar'].should == 'foo'
      cookies.clear
      cookies['foo'].should be_nil
      cookies['bar'].should be_nil
    end
  end

  context :length do
    it 'can tell you how many cookies are set' do
      cookies.length.should == 2
      cookies['baz'] = 'foo'
      cookies.length.should == 3
    end

    it 'should return 0 when no cookies are set' do
      cookies.length.should == 2
      cookies.clear
      cookies.length.should == 0
    end
  end

  context :keys do
    it 'can give you a list of cookies that are set' do
      cookies.keys.should == ['bar', 'foo']
    end
  end

  context :key? do
    it 'should return true when a cookie is set' do
      cookies.key?('foo').should be_true
    end

    it 'should return false when a cookie is not set' do
      cookies.key?('nom_nom').should be_false
    end

    it 'should allow symbols to be used as keys' do
      cookies.key?(:foo).should be_true
    end
  end

  context :empty? do
    it 'should return true when no cookies are set' do
      cookies.clear
      cookies.empty?.should be_true
    end

    it 'should return false when cookies are set' do
      cookies.empty?.should be_false
    end
  end

  context :each do
    it 'can iterate through cookies' do
      result = []
      cookies.each do |key, value|
        result << [key, value]
      end
      result[0].should == ['bar', 'foo']
      result[1].should == ['foo', 'bar']
    end

    it 'should allow enumeration' do
      result = cookies.collect do |key, value|
        [key, value]
      end
      result[0].should == ['bar', 'foo']
      result[1].should == ['foo', 'bar']
    end
  end

  context :permanent do
    before { app.set :cookie_secret, ('test' * 16) }
    let :verifier do
      ActiveSupport::MessageVerifier.new('test' * 16)
    end

    it 'should add cookies to the parent jar' do
      cookies.permanent['baz'] = 'foo'
      cookies['baz'].should == 'foo'
    end

    it 'should accept a hash of options' do
      cookies.permanent['foo'] = { :value => 'baz', :path => '/' }
      cookies['foo'].should == 'baz'
    end

    it 'should set a cookie that expires in the distant future' do
      result = route do
        cookies.permanent['baz'] = 'foo'
        response['Set-Cookie']
      end

      result.should =~ /#{1.year.from_now.year}/
    end

    it 'should allow you to chain signed cookies' do
      result = route do
        cookies.permanent.signed['foo'] = 'baz'
        response['Set-Cookie']
      end

      result.should =~ /#{1.year.from_now.year}/
      result.should =~ Regexp.new(verifier.generate('baz').gsub('=', '%3D'))
    end
  end

  context :signed do
    before { app.set :cookie_secret, ('test' * 16) }
    let :verifier do
      ActiveSupport::MessageVerifier.new('test' * 16)
    end

    it 'should read signed values' do
      cookies['foo'] = verifier.generate('baz')
      cookies.signed['foo'].should == 'baz'
    end

    it 'should write signed values' do
      cookies.signed['foo'] = 'baz'
      cookies['foo'].should == verifier.generate('baz')
    end

    it 'should accept a hash of options' do
      cookies.signed['foo'] = { :value => 'baz', :path => '/' }
      cookies.signed['foo'].should == 'baz'
    end

    it 'should require a 64 character secret' do
      app.set :cookie_secret, ('C' * 63)
      expect { cookies.signed['foo'] = 'baz' }.to raise_error(ArgumentError)
    end

    it 'should allow you to chain permanent cookies' do
      result = route do
        cookies.signed.permanent['foo'] = 'baz'
        response['Set-Cookie']
      end

      result.should =~ /#{1.year.from_now.year}/
      result.should =~ Regexp.new(verifier.generate('baz').gsub('=', '%3D'))
    end
  end
end
