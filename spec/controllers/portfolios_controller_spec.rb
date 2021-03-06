require 'spec_helper'

describe PortfoliosController do
  render_views	
  before{request.env["HTTP_REFERER"] ||= "where i came from"}
  
  describe "GET 'index'" do
  	before(:each) do
  		@portfolio = FactoryGirl.create(:portfolio)
  		second = FactoryGirl.create(:portfolio, :name => "HK Shares", :classification => "HTM")
  		third = FactoryGirl.create(:portfolio, :name => "US Shares", :classification => "AFS")
  		30.times do FactoryGirl.create(:portfolio)	end
      visit portfolios_path  
  	end
    
    it "should have an element for each portfolio" do
    	Portfolio.page(1).each { |portfolio| 
    		page.should have_selector("li", content: portfolio.name )
	    }
    end
  end

  describe "POST 'create'" do
    describe "failure" do
      before(:each) do
        @attr = { :name => "", :classification => "" }
      end

      it "should not create a portfolio" do
        lambda do
          post :create, :portfolio => @attr
        end.should_not change(Portfolio, :count)
      end

      it "should render the 'new' page after failure" do
        post :create, :portfolio => @attr
        response.should render_template('new')
      end
    end
    describe "success" do
    	before(:each) do
    		@attr = {:name => "CMB", :classification => "TRADING"}
    	end
    	it "should create a portfolio" do
    		lambda do
    			post :create, :portfolio => @attr
    		end.should change(Portfolio, :count).by(1)
    	end
    	it "should redirect to the portfolio index page" do
    		post :create, :portfolio => @attr
    		response.should redirect_to(portfolios_path)
    	end
    end
  end
  
  describe "GET 'edit'" do
  	before(:each) do
  		@portfolio = FactoryGirl.create(:portfolio)
  	end
  	it "should be successful" do
  		get :edit, :id => @portfolio
  		response.should be_success
  	end
  end
  describe "PUT 'update'" do
  	before(:each) do
  		@portfolio = FactoryGirl.create(:portfolio)
  	end
  	describe "failure" do
  		before(:each) do
  			@attr = {:name => "", :classification => ""}
  		end
  		it "should render the 'edit' page after failure" do
  			put :update, :id => @portfolio, :portfolio => @attr
  			response.should render_template('edit')
  		end
  	end
  	describe "success" do
  		before(:each) do
  			@attr = {:name => "Mainland A Shares", :classification => "AFS"}
  		end
  		it "should change the portfolio's attributes" do
  			put :update, :id => @portfolio, :portfolio => @attr
  			@portfolio.reload
  			@portfolio.name.should == @attr[:name]
  			@portfolio.classification.should == @attr[:classification]
  		end
  		
  		it "should redirect to the portfolio show page" do
  			put :update, :id => @portfolio, :portfolio => @attr
  			response.should redirect_to(portfolio_path(@portfolio))
  		end
  	end
  end
  describe "DELETE 'destroy'" do
  	before(:each) do
  		@portfolio = FactoryGirl.create(:portfolio)
  	end
  	it "should destroy the portfolio" do
  		lambda do
  			delete :destroy, :id => @portfolio
  		end.should change(Portfolio, :count).by(-1)
  	end
  	it "should redirect to the previous page" do
  		delete :destroy, :id => @portfolio
  		response.should redirect_to ("where i came from")
  	end
  end

end
