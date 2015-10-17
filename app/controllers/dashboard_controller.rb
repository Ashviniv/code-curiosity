class DashboardController < ApplicationController
  before_action :authenticate_user!, only: [:repositories]

  def index
    if current_user
      @category =  params[:category] || "Team"
      @start_date =  params[:start_date] || (Time.now - 1.month).strftime("%d/%m/%Y")
      @end_date =  params[:end_date] || Time.now.strftime("%d/%m/%Y")
      @inverted = @category == "Team" ? false : true
      @data, @title = Commit.get_data(@category, @start_date, @end_date)
    else
      @round_periods = Snapshot.order("from_date desc")
      @category =  params[:category] || "Team commits"
      @round = params[:round] || (@round_periods.first ? @round_periods.first.round_period : nil)
      @data, @teams = Snapshot.get_graphdata(@category, @round)
    end
  end

  def repositories
    @repos = Repository.all.order("name asc")
  end

  def team
    @start_date = (Time.now - 1.month).strftime("%d/%m/%Y")
    @end_date = Time.now.strftime("%d/%m/%Y")
    @data, @title = Commit.get_data("Team", @start_date, @end_date)
    render layout: 'widget'
  end

  def individual
    @start_date = (Time.now - 1.month).strftime("%d/%m/%Y")
    @end_date = Time.now.strftime("%d/%m/%Y")
    @data, @title = Commit.get_data("Individual", @start_date, @end_date)
    render layout: 'widget'
  end
end
