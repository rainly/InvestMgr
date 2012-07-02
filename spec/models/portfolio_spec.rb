require 'spec_helper'

describe Portfolio do
  before(:each) do
    @user = Factory(:user)
    @attr = { :name => "A Share", :classification => "TRADING" }
  end
  
  describe "classification" do
  	it "should allow 'TRADING' classification" do
  		@user.portfolios.create!( { :name => "A Share", :classification => "TRADING" })
  	end
  	
  	it "should allow 'AFS' classification" do
  		@user.portfolios.create!( { :name => "A Share", :classification => "AFS" })
  	end
  	
  	it "should allow 'HTM' classification" do
  		@user.portfolios.create!( { :name => "A Share", :classification => "HTM" })
  	end
  	
  	it "should NOT allow classificaition other than 'TRADING' 'AFS' or 'HTM'" do
  		 @user.portfolios.build(:name => "A share", :classification => "aaa").should_not be_valid
  	end
  end
  describe "user associations" do

    before(:each) do
      @portfolio = @user.portfolios.create(@attr)
    end

    it "should have a user attribute" do
      @portfolio.should respond_to(:user)
    end

    it "should have the right associated user" do
      @portfolio.user_id.should == @user.id
      @portfolio.user.should == @user
    end
  end
  
  describe "trade associations" do
  	before(:each) do
  		@portfolio = Factory(:portfolio, :user => @user)
  		@t1 = Factory(:trade, :portfolio => @portfolio)
  		@t2 = Factory(:trade, :portfolio => @portfolio)
  	end
  	it "should have a trades attribute" do
  		@portfolio.should respond_to(:trades)
  	end
  	it "should destroy associated trades" do
  		@portfolio.destroy
  		[@t1,@t2].each do |trade|
  			Trade.find_by_id(trade.id).should be_nil
  		end
  	end
  end
  
  describe "validations" do

    it "should require a user id" do
      Portfolio.new(@attr).should_not be_valid
    end

    it "should require nonblank name" do
      @user.portfolios.build(:name => "  ").should_not be_valid
    end
    
    it "should not have two same names within every User" do
      @user.portfolios.create!(@attr)
      @user.portfolios.build(@attr.merge(:classification => "AFS")).should_not be_valid
    end
    
    it "can have two same names for different Users" do
      @user.portfolios.create!(@attr)
      @user2 = Factory(:user)
      @user2.portfolios.build(@attr.merge(:classification => "AFS")).should be_valid
    end
  end
  
  describe "balance sheet" do
    before(:each) do
      @portfolio = @user.portfolios.create!(@attr)    
    end

    it "should have 0 cash at the begining" do
      @portfolio.cash.should == 0
    end

    it "should have correct cash at specific moments" do
     early_date = DateTime.parse("2011-7-29")
     late_date = DateTime.parse("2011-7-30")
     @portfolio.change_cash(10, early_date)
     @portfolio.cash(early_date).should == 10
     @portfolio.change_cash(-9, late_date)
     @portfolio.cash(late_date).should == 1
   end
  end

  #The following tests are based on sample data generated by sample_data.rake
  describe "positions and cost for MAINLAND Portfolio" do
    before(:each) do
      @user = User.where(:name => "Example User", :email => "example@railstutorial.org").first
      @portfolio = @user.portfolios.where(:name => "Mainland Shares").first
    end
    it "should have nothing between two identical DateTime" do
      position = @portfolio.position(:from => DateTime.parse("2012-3-6"), :till => DateTime.parse("2012-3-6"))
      position.size.should == 0
    end
    it "should have 100 CMB with 20.2150 cost/share, 100 Gree with 19.00 cost/share before the end of 2012-3-5" do 
      position1 = @portfolio.position(:till => DateTime.parse("2012-3-5 24:00:00"))
      position2 = @portfolio.position(:from => DateTime.parse("2012-3-5 00:00:00"), :till => DateTime.parse("2012-3-5 24:00:00"))
      cmb = Stock.where(:sid => "600036", :market => "sh").first
      gree = Stock.where(:sid => "000651", :market => "sz").first
      position1[cmb]["position"].should == 100
      position1[cmb]["cost"].round(4).should == 20.2150
      position1[gree]["position"].should == 100
      position1[gree]["cost"].round(4).should == 19.0000
      position1.size.should == 2
      position1.should == position2
    end
    it "should have correct positions and costs of CMB , and no positions other than CMB, at the end of 2012-3-7" do
      position1 = @portfolio.position(:till => DateTime.parse("2012-3-7 24:00:00"))
      position2 = @portfolio.position(:from => DateTime.parse("2012-3-4"), :till => DateTime.parse("2012-3-7 24:00:00"))
      cmb = Stock.where(:sid => "600036", :market => "sh").first
      position1[cmb]["position"].should == 300
      position1[cmb]["cost"].round(4).should == 20.5083

      position1.size.should == 1
      position1.should == position2
    end
  end

  describe "positions and cost for HONGKONG Portfolio" do
    before(:each) do
      @user = User.where(:name => "Example User", :email => "example@railstutorial.org").first
      @portfolio = @user.portfolios.where(:name => "Hongkong Shares").first
    end    
    it "should have 100 CMBs with 20.2150 cost/share, 100 CNOOCs with 25.2650 cost/share before the end of 2012-3-5" do 
      position1 = @portfolio.position(:till => DateTime.parse("2012-3-5 24:00:00"))
      position2 = @portfolio.position(:from => DateTime.parse("2012-3-5 00:00:00"), :till => DateTime.parse("2012-3-5 24:00:00"))
      cnooc = Stock.where(:sid => "00883", :market => "hk").first
      position1[cnooc]["position"].should == 100
      position1[cnooc]["cost"].round(4).should == 25.2650
      
      position1.should == position2
    end
    it "should have correct positions and costs of CMB and CNOOC respectively, and no positions other than these two securities, at the end of 2012-3-7" do
      position1 = @portfolio.position(:till => DateTime.parse("2012-3-7 24:00:00"))
      position2 = @portfolio.position(:from => DateTime.parse("2012-3-4"), :till => DateTime.parse("2012-3-7 24:00:00"))
      cnooc = Stock.where(:sid => "00883", :market => "hk").first
      position1[cnooc]["position"].should == 300
      position1[cnooc]["cost"].round(4).should == 25.6317

      position1.size.should == 1
      position1.should == position2
    end
  end
  describe "gain/loss for a range of time" do
    it "should return correct gain/loss on specific dates" do
      
    end
  end
end

# == Schema Information
#
# Table name: portfolios
#
#  id             :integer(4)      not null, primary key
#  name           :string(255)
#  classification :string(255)
#  user_id        :integer(4)
#  created_at     :datetime
#  updated_at     :datetime
#

