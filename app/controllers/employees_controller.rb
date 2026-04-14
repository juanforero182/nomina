class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company, if: -> { params[:company_id].present? }
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    @employees = if @company
      @company.employees.includes(:contracts).order(:first_surname, :first_name)
    else
      Employee.includes(:company, :contracts).order(:first_surname, :first_name)
    end
  end

  def show; end

  def new
    @employee = @company.employees.build
  end

  def create
    @employee = @company.employees.build(employee_params)

    if @employee.save
      redirect_to [@company, @employee], notice: t("employees.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @employee.update(employee_params)
      if @company
        redirect_to [@company, @employee], notice: t("employees.updated")
      else
        redirect_to @employee, notice: t("employees.updated")
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    if @company
      redirect_to company_employees_path(@company), notice: t("employees.deleted")
    else
      redirect_to employees_path, notice: t("employees.deleted")
    end
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def set_employee
    @employee = if @company
      @company.employees.find(params[:id])
    else
      Employee.find(params[:id])
    end
  end

  def employee_params
    params.require(:employee).permit(
      :document_number, :document_type, :first_surname, :second_surname,
      :first_name, :other_names, :department, :municipality, :address,
      :phone, :mobile, :gender, :email
    )
  end
end
