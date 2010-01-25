class Backend::UsersController < Backend::BackendController

  before_filter :pre_load
  before_filter :authorized_admin_user_unless_current_inventory_pool # OPTIMIZE

  def index
    # OPTIMIZE 0501 
    params[:sort] ||= 'login'
    params[:sort_mode] ||= 'ASC'
    params[:sort_mode] = params[:sort_mode].downcase.to_sym

# working here #
    with = {}
    without = {}

    case params[:filter]
      when "admins"
        users = User.admins
      when "managers"
        users = current_inventory_pool.managers
      when "customers"
        users = current_inventory_pool.customers
      when "unknown"
##        users = User.all - current_inventory_pool.users
        without.merge!(:inventory_pool_id => current_inventory_pool.id)
      when "suspended_users"
# FIXME 0501
        users = current_inventory_pool.suspended_users
#        with.merge!(:suspended_inventory_pool_id => current_inventory_pool.id)
      else
##        users = (current_inventory_pool ? current_inventory_pool.users : User)
        with.merge!(:inventory_pool_id => current_inventory_pool.id) if current_inventory_pool
    end

    # TODO 0501
    @users = (users ? users : User).search params[:query], { :star => true, :page => params[:page], :per_page => $per_page,
                                           :with => with, :without => without,
                                           :order => params[:sort], :sort_mode => params[:sort_mode] }
  end

  def show
  end

  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    @user.login = @user.email
    if @user.save
      @user.access_rights.create(:inventory_pool => current_inventory_pool,
                                 :role => Role.first(:conditions => {:name => "customer"}), 
                                 :level => 1) if current_inventory_pool
      redirect_to :action => 'show', :id => @user.id
    else
      flash[:error] = @user.errors.full_messages
    end
  end

#################################################################

  # OPTIMIZE
  def things_to_return
    @user_things_to_return = @user.things_to_return.select { |t| t.returned_date.nil? }
  end

  def extended_info
  end
  
  def remind
    flash[:notice] = _("User %s has been reminded ") % @user.remind(current_user)
    respond_to do |format|
      format.js { render :update do |page|
                    page << "if($('remind_resume')){"
                      page.replace 'remind_resume', remind_user(@user)
                    page << "}"
                    page.replace_html 'flash', flash_content
                    flash.discard
                  end }
    end
  end
  
  def new_contract
    redirect_to [:backend, current_inventory_pool, @user, :hand_over]
  end

#################################################################

  def access_rights
  end
  
  def add_access_right
    inventory_pool_id = if current_inventory_pool
                          current_inventory_pool.id
                        else
                          params[:access_right][:inventory_pool_id]
                        end
    
    r = Role.find(params[:access_right][:role_id]) if params[:access_right]
    r ||= Role.find_by_name("customer") # OPTIMIZE
  
    ar = @user.all_access_rights.first(:conditions => {:inventory_pool_id => inventory_pool_id })
   
    if ar
      ar.update_attributes(:role => r, :level => params[:level], :access_level => params[:access_level])
      ar.update_attributes(:deleted_at => nil) if ar.deleted_at
      flash[:notice] = _("Access Right successfully updated")
    else
      ar = @user.access_rights.create(:role => r, :inventory_pool_id => inventory_pool_id, :level => params[:level], :access_level => params[:access_level])
      flash[:notice] = _("Access Right successfully created")
    end

    unless ar.valid?
      flash[:notice] = nil
      flash[:error] = ar.errors.full_messages
    end
    redirect_to url_for([:access_rights, :backend, current_inventory_pool, @user].compact)
  end

  def remove_access_right
    ar = @user.access_rights.find(params[:access_right_id])
    ar.deactivate
    redirect_to url_for([:access_rights, :backend, current_inventory_pool, @user].compact)
  end

  def suspend_access_right
    a = @user.access_rights.find(params[:access_right_id])
    a.update_attributes(:suspended_at => DateTime.now)
    redirect_to url_for([:access_rights, :backend, current_inventory_pool, @user].compact)
  end

  def reinstate_access_right
    a = @user.access_rights.find(params[:access_right_id])
    a.update_attributes(:suspended_at => nil)
    redirect_to url_for([:access_rights, :backend, current_inventory_pool, @user].compact)
  end

  def update_badge_id
    @user.update_attributes(:badge_id => params[:badge_id])
    
    # OPTIMIZE rebuild index for related orders and contracts
    @user.documents.each {|d| d.save }
    flash[:notice] = _("Badge ID was updated")

    render :update do |page|
                    page.replace "badge_id_form", :partial => "badge_id_form", :locals => { :user => @user }
                    page.replace_html 'flash', flash_content
                    flash.discard
                  end
  end

#################################################################

  private
  
  def authorized_admin_user_unless_current_inventory_pool
    authorized_admin_user? unless current_inventory_pool  
  end
  
  def pre_load
    params[:id] ||= params[:user_id] if params[:user_id]
#    @user = current_inventory_pool.users.find(params[:id]) if params[:id]
    @user = User.find(params[:id]) if params[:id]

    @tabs = []
    @tabs << :user_backend if @user
  end

end
