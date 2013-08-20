
UsersIndexCtrl = ($scope, User, $routeParams) ->
  $scope.current_inventory_pool_id = $routeParams.inventory_pool_id

  $scope.tabs =  [ [null, _jed("All")],
                   ["customers", _jed("Customer")],
                   ["lending_managers", _jed("Lending manager")],
                   ["inventory_managers", _jed("Inventory manager")] ]

  # TODO reimplement with angular tabs
  $scope.setRole = (r)->
    $scope.role = r
    $scope.fetch()

  $scope.$watch 'suspended', (newValue, oldValue)->
    $scope.fetch()

  $scope.$watch 'search', (newValue, oldValue)->
    $scope.fetch()

  $scope.fetch = (nextPage)->
    return if $scope.isLoading
    return if nextPage and $scope.pagination.current_page >= $scope.pagination.total_pages
    $scope.isLoading = true
    params =
      inventory_pool_id: $scope.current_inventory_pool_id
      search: $scope.search
      role: $scope.role
      suspended: $scope.suspended
      page: nextPage
    # TODO this should be done directly by angular
    for k of params
      delete params[k] if angular.isUndefined(params[k])
    User.query(
      params
      , (response) ->
        new_users = (new User(entry) for entry in response.entries)
        $scope.users = if nextPage then $scope.users.concat new_users else new_users
        $scope.pagination = response.pagination
        $(".inlinetabs .tab:first").addClass("active") unless $scope.role?
        $scope.isLoading = false
    )

UsersIndexCtrl.$inject = ['$scope', 'User', '$routeParams'];

UsersEditCtrl = ($scope, $location, $routeParams, User) ->
  $scope.current_inventory_pool_id = $routeParams.inventory_pool_id
  $scope.possible_roles = [ {"name": "no_access", "text": _jed("No access")},
                            {"name": "customer", "text": _jed("Customer")} ]
  if current_user.access_level >= 2 or current_user.admin
    $scope.possible_roles.push {"name": "lending_manager", "text": _jed("Lending manager")}
  if current_user.access_level >= 3 or current_user.admin
    $scope.possible_roles.push {"name": "inventory_manager", "text": _jed("Inventory manager")}
  self = this
  User.get
    inventory_pool_id: $scope.current_inventory_pool_id
    id: $routeParams.id
  , (response) ->
    response.access_right.suspended_until = new Date(Date.parse(response.access_right.suspended_until)) if response.access_right?.suspended_until?
    $scope.user = new User(response)
    $scope.user.is_editable = true
    unless $scope.user.access_right?
      $scope.user.access_right = {role_name: "no_access"}
    if $scope.user.db_auth?
      $scope.user.db_auth.password = "_password_"
      $scope.user.db_auth.password_confirmation = "_password_"

  $scope.submit = ->
    params =
      inventory_pool_id: $scope.current_inventory_pool_id
      id: $scope.user.id
      user:
        firstname: $scope.user.firstname
        lastname: $scope.user.lastname
        address: $scope.user.address
        zip: $scope.user.zip
        city: $scope.user.city
        country: $scope.user.country
        phone: $scope.user.phone
        email: $scope.user.email
        groups: $scope.user.groups
        badge_id: $scope.user.badge_id
      access_right:
        role_name: $scope.user.access_right.role_name
        suspended_until: if $scope.user.access_right.suspended_until? then moment($scope.user.access_right.suspended_until).format("YYYY-MM-DD") else undefined
        suspended_reason: $scope.user.access_right.suspended_reason

    if $scope.user.db_auth?
      params.db_auth =
        login: $scope.user.db_auth.login
        password: $scope.user.db_auth.password
        password_confirmation: $scope.user.db_auth.password_confirmation

    User.update params
    , (response) ->
      #$location.path "/backend/inventory_pools/#{$scope.current_inventory_pool_id}/users/#{$scope.user.id}"
      window.location = "/backend/inventory_pools/#{$scope.current_inventory_pool_id}/users"
    , (response) ->
      Notification.add_headline
        title: _jed("Error")
        text: response.data
        type: "error"

  $scope.addGroup = (element)-> 
    return true if _.find $scope.user.groups, (g)-> g.id == element.item.id
    $scope.$apply ($scope) ->
      $scope.user.groups.push element.item

  $scope.removeGroup = (element)-> 
    console.log element
    console.log $scope.user.groups
    $scope.user.groups = _.reject $scope.user.groups, (g)-> g.id == element.group.id

UsersEditCtrl.$inject = ['$scope', '$location', '$routeParams', 'User'];

# exports
root = global ? window
root.UsersIndexCtrl  = UsersIndexCtrl
root.UsersEditCtrl   = UsersEditCtrl
