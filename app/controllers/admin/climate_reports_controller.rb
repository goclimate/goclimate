# frozen_string_literal: true

module Admin
  class ClimateReportsController < AdminController
    before_action :set_report, only: [:show, :edit, :update, :destroy]
    before_action :set_organizations, only: [:new, :create, :update, :edit]
    before_action :set_calculators, only: [:new, :create, :update, :edit]

    def index
      @reports = ClimateReports::Report.all.order(title: :asc)
    end

    def show
    end

    def new
      @report = ClimateReports::Report.new
    end

    def edit
    end

    def create
      @report = ClimateReports::Report.new(report_params)

      unless @report.save
        render :new
        return
      end

      redirect_to [:admin, @report], notice: 'Report was successfully created.'
    end

    def update
      unless @report.update(report_params)
        render :edit
        return
      end

      redirect_to [:admin, @report], notice: 'Report was successfully updated.'
    end

    def destroy
      @report.destroy

      redirect_to admin_climate_reports_url, notice: 'Report was successfully destroyed.'
    end

    private

    def set_report
      @report = ClimateReports::Report.find(params[:id])
    end

    def set_organizations
      @organizations = Organization.all.order(name: :asc).map { |o| [o.name, o.id] }
    end

    def set_calculators
      @calculators = BusinessCalculators::Calculator.all.order(name: :asc)
    end

    def report_params
      params.require(:climate_report).permit(
        :title,
        :start_date,
        :end_date,
        :organization_id,
        {
          areas_attributes: [
            :id,
            :title,
            :_destroy,
            :calculator_id
          ]
        }
      ).tap do |p|
        p[:reporting_period] = p[:start_date]..p[:end_date]
      end.except(:start_date, :end_date, :organization)
    end
  end
end
