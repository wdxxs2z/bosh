module Bosh::Director
  class VmDeleter
    def initialize(logger, force = false, enable_virtual_delete_vm = false)
      @logger = logger
      @error_ignorer = ErrorIgnorer.new(force, @logger)
      @enable_virtual_delete_vm = enable_virtual_delete_vm
      @force = force
    end

    def delete_for_instance(instance_model, store_event = true)
      return unless instance_model.active_vm

      DeploymentPlan::Steps::DeleteVmStep.new(
        store_event,
        @force,
        @enable_virtual_delete_vm,
      ).perform(DeploymentPlan::Stages::Report.new.tap { |r| r.vm = instance_model.active_vm })
    end

    def delete_vm_by_cid(cid)
      @logger.info('Deleting VM')
      @error_ignorer.with_force_check do
        # if there are multiple cpis, it's too dangerous to try and delete just vm cid on every cloud.
        cloud_factory = CloudFactory.create
        unless cloud_factory.uses_cpi_config?
          cloud_factory.get(nil).delete_vm(cid) unless @enable_virtual_delete_vm
        end
      end
    end
  end
end
