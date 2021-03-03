class GroupsController < ApplicationController
  before_action :set_group, except: [:index,:upload_group_file,:create,:root,:build_country_city_state_groups]
  before_action :check_authenticated_admin_or_manager, except: [:get_path,:get_children,:show,:root,:get_twitter]
  before_action :validate_invalid_group_name, only: [:create,:update]
  before_action :authenticate_admin!, only: [:build_country_city_state_groups]

  # GET /groups
  def index
    @group_manager = GroupManager.find(current_group_manager.id)
    @groups = Group.where(
        group_manager_id: current_group_manager.id, 
        description: @group_manager.group_name
      )
    
    render json: @groups
  end

  # GET /groups/1
  def show
    render json: @group
  end

  # POST /groups
  def create
    @group = Group.new(group_params)
    if (current_group_manager)
      ManagerGroupPermission::permit(current_group_manager, @group)
      @group.group_manager_id = current_group_manager.id
    elsif (group_params[:group_manager_id])
      group_manager = GroupManager.find(group_params[:group_manager_id])
      ManagerGroupPermission::permit(group_manager, @group)
      @group.group_manager_id = group_params[:group_manager_id]
    end
    
    return render json: 'Not enough permissions' if !validate_manager_group_permissions

    if @group.save
      render json: @group, status: :created, location: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /groups/1
  def update
    return render json: 'Not enough permissions', status: :unprocessable_entity if !validate_manager_group_permissions
    if @group.update(group_params)
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end
  
  # DELETE /groups/1
  def destroy
    @group.delete_subtree
  end

  # GET /groups/root
  def root
    return render json: Group::get_root
  end

  # GET /groups/1/get_path
  def get_path
    path = []
    path = @group.get_path(false)
    path = { "groups": [] } if path.empty?
    render json: path, status: :ok, each_serializer: GroupSimpleSerializer
  end

  # GET /groups/1/get_children
  def get_children
    is_child = @group.children_label == nil
    children = @group.children.each.map {|x| GroupSimpleSerializer.new(x) }
    render json: { label: @group.children_label, is_child: is_child, require_id: @group.require_id || false, children: children }, status: :ok
  end

  # POST /groups/upload_group_file/
  def upload_group_file(build_country_city_state_model = false)
    if !build_country_city_state_model && current_group_manager.nil?
      return render json: 'You must be a group manager to create new groups'
    end
    data = Roo::Spreadsheet.open(params[:file], extension: :xls) # Open spreadsheet data

    # Mandatory columns for .xls document to register new institutions
    @mandatory_columns = ["CODIGO","UNIDADE","ENDEREÇO","CEP","TELEFONE","EMAIL","PAIS","ESTADO","MUNICIPIO"]

    headers = data.row(1) # First row containing headers for table
    
    # If rows are not found, return error alongside missing rows
    not_found_columns = validate_mandatory_columns headers
    if not_found_columns.any?
      return render json: {message: 'Mandatory table rows not found', not_found_columns: not_found_columns, error: true}, status: :unprocessable_entity
    end
    
    filter_columns = filter_columns headers

    # 3 from the 'country, state, city' filting model + the size of custom filters
    filter_size = 3 + filter_columns.length

    rows_to_create = []

    data.each_with_pagename do |name, sheet|
      sheet_data = sheet.as_json
      sheet_data.each_with_index do |line, i|
        line.each_with_index do |text, j|
          if text.is_a? String
            sheet_data[i][j] = text.strip
          end
        end
      end

      sheet.each_with_index(
        code: 'CODIGO', 
        description: 'UNIDADE',
        address: 'ENDEREÇO', 
        cep: 'CEP', 
        phone: 'TELEFONE',
        email: 'EMAIL',
      ) do |group_data, idx|
          # Jump table header
          next if idx == 0

          # Get row from sheet
          row_data = sheet_data[idx]

          # List of path filters (country, state, municipality, filter_1, filter_2, ...)
          path_filter_list = (6..6+filter_size-1)

          # Check if any filter data is empty and returns error if so
          path_filter_list.each do |i|
            if !build_country_city_state_model && (row_data[i].nil? || row_data[i].empty?)
              return render json: {
                message: 'Filter data is empty',
                row: idx,
                column: headers[i],
                error: true
              }, status: :unprocessable_entity
            elif build_country_city_state_model && (!row_data[i].nil? || !row_data[i].empty?)
              return render json: {
                message: 'Filter data is filled',
                row: idx,
                column: headers[i],
                error: true
              }, status: :unprocessable_entity
            end
          end

          path = []
          path_filter_list.each do |i|
            # If some group is called root_node, a forbidden name, return failure
            if row_data[i] == 'root_node'
              return render json: {message: 'You cannot name a group \'root_node\'', error: true}, status: :unprocessable_entity
            end
            # index 8 is 'municipality'
            if i == 8 && !build_country_city_state_model
              path << {
                label: headers[i],
                description: row_data[i],
                children_label: 'GRUPO'
              }
              path << {
                label: 'GRUPO',
                description: current_group_manager.group_name,
                children_label: headers[i + 1] || nil
              }
            else
              path << {
                label: headers[i],
                description: row_data[i],
                children_label: headers[i + 1] || nil
              }
            end
          end

          row = {
            metadata: group_data,
            path: path
          }

          rows_to_create << row
        end
    end

    groups_not_created = []

    rows_to_create.each do |r|
      current_group = Group::get_root
      was_created = false
      is_valid_manager = true
      r[:path].each_with_index do |p, i|
        # Create or add child to the path leading to the child group
        child = current_group.children.find_by_description(p[:description])
        if child.nil?
          # 0: Country, 1: State, 2: Municipality. Managers may not create these, only use them.
          if i <= 2 && !build_country_city_state_model
            current_group = nil
            is_valid_manager = false
            r[:reason] = 'Creating a new group for \'' + p[:label] + '\' (' + p[:description] + ') is not allowed'
            groups_not_created << r
            break
          end
          new_group = Group.new()
          new_group.description = p[:description]
          new_group.children_label = p[:children_label]
          new_group.parent = current_group

          # If child group, add child group metadata
          if !build_country_city_state_model && p[:children_label] == nil
            new_group.code = r[:metadata][:code]
            new_group.address = r[:metadata][:address]
            new_group.cep = r[:metadata][:cep]
            new_group.phone = r[:metadata][:phone]
            new_group.email = r[:metadata][:email]
          end

          # Add group manager to group
          if !build_country_city_state_model
            new_group.group_manager = current_group_manager
          end

          # Children label for municipality is 'GRUPO' 
          if build_country_city_state_model && i == 2
            new_group.children_label = 'GRUPO'
          end
          
          #if !validate_manager_group_permissions(new_group)
          #  current_group = nil
          #  is_valid_manager = false
          #  r[:reason] = 'Not enough permissions'
          #  groups_not_created << r
          #  break
          #end

          was_created = true
          new_group.save()
          current_group = new_group
        else
          current_group = child
        end
      end
      if !was_created && is_valid_manager
        r[:reason] = 'Already exists'
        groups_not_created << r
      end
    end

    if groups_not_created.any?
      return render json: {
        message: 'Some or all groups were not created',
        error: true,
        groups: groups_not_created
      }, status: :created
    end

    render json: {message: 'All groups created', error: false}, status: :created
  end

  # POST /groups/build_country_city_state_groups/
  # This is used only by admins to build countries, states and municipalities
  # into database with an .xls file
  def build_country_city_state_groups
    self.upload_group_file(true)
  end

  # GET /groups/:id/get_twitter
  def get_twitter
    render json: { twitter: @group.get_twitter }
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def group_params
      params.require(:group).permit(
        :description, 
        :children_label,
        :parent_id,
        :code,
        :address,
        :cep,
        :phone,
        :email,
        :group_manager_id,
        :location_name_godata,
        :location_id_godata
      )
    end

    # Check if all required columns are present and returns the one that aren't
    def validate_mandatory_columns(headers)
      not_found_columns = []
      @mandatory_columns.each do |label|
        if !headers.include? label
          not_found_columns << label
        end
      end
      not_found_columns
    end

    # Check if all required columns are present and returns the one that aren't
    def filter_columns(headers)
      filter_columns = []
      headers.each do |header|
        if !@mandatory_columns.include? header
          filter_columns << header
        end
      end
      filter_columns
    end

    def check_authenticated_admin_or_manager
      if current_admin.nil? && current_group_manager.nil?
        return render json: {}, status: :ok
      end
    end
  
    def validate_manager_group_permissions(group = @group)
      if current_group_manager != nil && !current_group_manager.is_permitted?(group)
        return false
      end
      return true
    end
    
    def validate_invalid_group_name
      if group_params[:description] == 'root_node'
        return render json: 'You cannot name a group \'root_node\'', status: :unprocessable_entity
      end
    end
end
