module Availability
  module Model
    
    def availability_changes_in(inventory_pool)
      Availability::Main.new(:model_id => id, :inventory_pool_id => inventory_pool.id)
    end

    def delete_availability_changes_in(inventory_pool)
      #1402
      partitions.in(inventory_pool).by_group(Group::GENERAL_GROUP_ID)
    end

    #def total_available_in_period_for_user(user, start_date = Date.today, end_date = Date.today)
    #  inventory_pools.collect do |ip|
    #    availability_changes_in(ip).maximum_available_in_period_for_user(user, start_date, end_date)
    #  end.sum
    #end

    def total_borrowable_items_for_user(user)
      inventory_pools.collect do |ip|
        partitions.in(ip).by_groups(user.groups).sum(:quantity).to_i +
          partitions.in(ip).by_group(Group::GENERAL_GROUP_ID, false)
      end.sum
    end

    def availability_periods_for_user(user, with_total_borrowable = false) #, start_date = Date.today, end_date = Availability::Change::ETERNITY)
      (inventory_pools & user.inventory_pools).collect do |inventory_pool|
        groups = user.groups.scoped_by_inventory_pool_id(inventory_pool)
        h = {:inventory_pool => inventory_pool.as_json,
             :availability => availability_changes_in(inventory_pool).changes.available_quantities_for_groups(groups) }
        if with_total_borrowable
          h[:total_borrowable] = partitions.in(inventory_pool).by_groups(groups.collect(&:id)).sum(:quantity).to_i +
                                 partitions.in(inventory_pool).by_group(Group::GENERAL_GROUP_ID)
        end
        h
      end
    end

    def availability_periods_for_inventory_pool(inventory_pool)
      {:inventory_pool => inventory_pool.as_json,
       :partitions => partitions.in(inventory_pool).current_partition(true),
       :availability => availability_changes_in(inventory_pool).changes.available_total_quantities }
    end


  end
end
